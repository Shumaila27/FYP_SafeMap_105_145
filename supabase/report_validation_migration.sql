-- =============================================================================
-- SafeMap — Report Validation Migration
-- Run this entire script in Supabase → SQL Editor
--
-- What this does:
--  1. Adds AI + community validation columns to the reports table
--  2. Creates the report_votes table (community Yes/No voting)
--  3. Adds RLS policies for report_votes
--  4. Creates the finalize_report_validation() RPC function
--     (called by Flutter after the 30-minute community vote window closes)
-- =============================================================================


-- ── STEP 1: Add validation columns to reports ─────────────────────────────

DO $$
BEGIN
  -- AI analysis columns (written at submission time)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'ai_score') THEN
    ALTER TABLE public.reports ADD COLUMN ai_score INTEGER;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'ai_verdict') THEN
    ALTER TABLE public.reports ADD COLUMN ai_verdict TEXT;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'ai_reason') THEN
    ALTER TABLE public.reports ADD COLUMN ai_reason TEXT;
  END IF;

  -- Community vote columns (written by finalize_report_validation after 30 min)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'community_score') THEN
    ALTER TABLE public.reports ADD COLUMN community_score INTEGER;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'final_score') THEN
    ALTER TABLE public.reports ADD COLUMN final_score INTEGER;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'reports' AND column_name = 'validation_status') THEN
    ALTER TABLE public.reports
      ADD COLUMN validation_status TEXT NOT NULL DEFAULT 'unvalidated'
      CHECK (validation_status IN ('unvalidated', 'pending_review', 'verified', 'flagged_fake'));
  END IF;
END $$;


-- ── STEP 2: Create report_votes table ─────────────────────────────────────
-- Stores one vote per user per report.
-- vote = TRUE  → "Yes, I witnessed this incident"
-- vote = FALSE → "No, I did not witness this"

CREATE TABLE IF NOT EXISTS public.report_votes (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id   UUID        NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  voter_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  vote        BOOLEAN     NOT NULL,
  voted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One vote per user per report — enforced at DB level
  CONSTRAINT uq_report_voter UNIQUE (report_id, voter_id)
);


-- ── STEP 3: Indexes ───────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_report_votes_report_id
  ON public.report_votes (report_id);

CREATE INDEX IF NOT EXISTS idx_report_votes_voter_id
  ON public.report_votes (voter_id);


-- ── STEP 4: RLS Policies ──────────────────────────────────────────────────

ALTER TABLE public.report_votes ENABLE ROW LEVEL SECURITY;

-- Any authenticated user can read vote counts (for UI display)
DROP POLICY IF EXISTS "votes_select" ON public.report_votes;
CREATE POLICY "votes_select" ON public.report_votes
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Users can only insert their own vote
DROP POLICY IF EXISTS "votes_insert" ON public.report_votes;
CREATE POLICY "votes_insert" ON public.report_votes
  FOR INSERT WITH CHECK (auth.uid() = voter_id);

-- No UPDATE / DELETE — votes are immutable once cast.


-- ── STEP 5: finalize_report_validation() RPC ──────────────────────────────
-- Called by Flutter's CommunityVoteService after the 30-minute window.
-- Computes:
--   community_score = (yes_votes / total_votes) × 100   (50 if no votes)
--   final_score     = (ai_score × 0.6) + (community_score × 0.4)
--   validation_status based on final_score thresholds:
--     80–100 → verified
--     50–79  → pending_review
--     0–49   → flagged_fake
-- Returns a JSON summary so Flutter can reflect the status immediately.

CREATE OR REPLACE FUNCTION public.finalize_report_validation(p_report_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_yes_count        INTEGER;
  v_total_count      INTEGER;
  v_community_score  INTEGER;
  v_ai_score         INTEGER;
  v_final_score      INTEGER;
  v_validation_status TEXT;
BEGIN
  -- 1. Count community votes
  SELECT
    COUNT(*) FILTER (WHERE vote = TRUE),
    COUNT(*)
  INTO v_yes_count, v_total_count
  FROM public.report_votes
  WHERE report_id = p_report_id;

  -- 2. Community score: percentage who witnessed it (neutral 50 if no votes)
  IF v_total_count = 0 THEN
    v_community_score := 50;
  ELSE
    v_community_score := ROUND((v_yes_count::FLOAT / v_total_count) * 100);
  END IF;

  -- 3. Fetch AI score set at submission time (default 50 if missing)
  SELECT COALESCE(ai_score, 50)
  INTO   v_ai_score
  FROM   public.reports
  WHERE  id = p_report_id;

  -- 4. Final score = (ai_score × 60%) + (community_score × 40%)
  v_final_score := ROUND((v_ai_score * 0.6) + (v_community_score * 0.4));

  -- 5. Classify
  IF v_final_score >= 80 THEN
    v_validation_status := 'verified';
  ELSIF v_final_score >= 50 THEN
    v_validation_status := 'pending_review';
  ELSE
    v_validation_status := 'flagged_fake';
  END IF;

  -- 6. Write back to reports table
  UPDATE public.reports SET
    community_score   = v_community_score,
    final_score       = v_final_score,
    validation_status = v_validation_status,
    updated_at        = NOW()
  WHERE id = p_report_id;

  -- 7. Return summary for the Flutter caller
  RETURN json_build_object(
    'community_score',   v_community_score,
    'final_score',       v_final_score,
    'validation_status', v_validation_status,
    'yes_votes',         v_yes_count,
    'total_votes',       v_total_count
  );
END;
$$;

-- Allow any authenticated user to call this (CommunityVoteService uses the
-- authenticated client, so the caller's JWT is always present).
GRANT EXECUTE ON FUNCTION public.finalize_report_validation TO authenticated;


-- ── STEP 6: Verify ────────────────────────────────────────────────────────

-- Should show the 6 new columns on reports
SELECT column_name, data_type, column_default
FROM   information_schema.columns
WHERE  table_schema = 'public'
  AND  table_name   = 'reports'
  AND  column_name  IN ('ai_score','ai_verdict','ai_reason',
                        'community_score','final_score','validation_status');

-- Should return an empty table (no votes yet)
SELECT COUNT(*) FROM public.report_votes;
