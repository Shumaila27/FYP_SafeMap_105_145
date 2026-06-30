-- =============================================================================
-- SafeMap — User Stats Triggers & Backfill
-- Run this script in your Supabase SQL Editor
-- =============================================================================

-- ── STEP 1: Create Trigger Function for Reports ──────────────────────────────
-- Automatically awards +1 report count and +5 safety points when a user files a report.
CREATE OR REPLACE FUNCTION public.increment_stats_on_report()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.user_id IS NOT NULL THEN
    INSERT INTO public.user_stats (user_id, reports, safety_points)
    VALUES (NEW.user_id, 1, 5)
    ON CONFLICT (user_id) DO UPDATE SET
      reports = public.user_stats.reports + 1,
      safety_points = public.user_stats.safety_points + 5,
      updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_increment_stats_on_report ON public.reports;
CREATE TRIGGER trg_increment_stats_on_report
  AFTER INSERT ON public.reports
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_stats_on_report();


-- ── STEP 2: Create Trigger Function for Safe Walks ───────────────────────────
-- Automatically awards +1 safe walk count and +10 safety points when a walk status transitions to 'completed'.
CREATE OR REPLACE FUNCTION public.increment_stats_on_completed_walk()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    INSERT INTO public.user_stats (user_id, safe_walks, safety_points)
    VALUES (NEW.user_id, 1, 10)
    ON CONFLICT (user_id) DO UPDATE SET
      safe_walks = public.user_stats.safe_walks + 1,
      safety_points = public.user_stats.safety_points + 10,
      updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_increment_stats_on_completed_walk ON public.safe_walks;
CREATE TRIGGER trg_increment_stats_on_completed_walk
  AFTER UPDATE ON public.safe_walks
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_stats_on_completed_walk();


-- ── STEP 3: Backfill Query (Sync existing user walks/reports data) ───────────
-- This ensures all your previously completed walks and filed reports are counted immediately.

-- 1. Ensure stats rows exist for all profiles first
INSERT INTO public.user_stats (user_id)
SELECT id FROM public.profiles
ON CONFLICT DO NOTHING;

-- 2. Sync report counts
UPDATE public.user_stats us
SET reports = (
  SELECT COALESCE(COUNT(*), 0)
  FROM public.reports r
  WHERE r.user_id = us.user_id
);

-- 3. Sync safe walk counts (only completed ones count as safe walks)
UPDATE public.user_stats us
SET safe_walks = (
  SELECT COALESCE(COUNT(*), 0)
  FROM public.safe_walks sw
  WHERE sw.user_id = us.user_id AND sw.status = 'completed'
);

-- 4. Calculate total safety points (+10 per completed walk, +5 per report)
UPDATE public.user_stats us
SET safety_points = (safe_walks * 10) + (reports * 5),
    updated_at = NOW();
