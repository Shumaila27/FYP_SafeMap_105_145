-- =============================================================================
-- SafeMap — Panic Mode (SOS) Database Migration
-- Run this in Supabase SQL Editor
-- =============================================================================

-- ── STEP 1: Add last location columns to profiles table ──────────────────────
DO $$
BEGIN
  -- Add last_lat to profiles if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'last_lat'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN last_lat DOUBLE PRECISION;
  END IF;

  -- Add last_lng to profiles if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'last_lng'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN last_lng DOUBLE PRECISION;
  END IF;

  -- Add last_located_at to profiles if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'last_located_at'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN last_located_at TIMESTAMPTZ;
  END IF;
END;
$$;


-- ── STEP 2: Create panic_alerts table ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.panic_alerts (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  latitude    DOUBLE PRECISION NOT NULL,
  longitude   DOUBLE PRECISION NOT NULL,
  status      TEXT        NOT NULL CHECK (status IN ('active', 'resolved')) DEFAULT 'active',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ── STEP 3: Enable RLS Policies ──────────────────────────────────────────────
ALTER TABLE public.panic_alerts ENABLE ROW LEVEL SECURITY;

-- SELECT policy: Any authenticated user can see panic alerts (active or resolved)
DROP POLICY IF EXISTS "Anyone can view active panic alerts" ON public.panic_alerts;
CREATE POLICY "Anyone can view active panic alerts" ON public.panic_alerts
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- INSERT policy: Any authenticated user can insert their own panic alerts
DROP POLICY IF EXISTS "Users can insert their own panic alerts" ON public.panic_alerts;
CREATE POLICY "Users can insert their own panic alerts" ON public.panic_alerts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE policy: Users can update (resolve) their own panic alerts
DROP POLICY IF EXISTS "Users can update their own panic alerts" ON public.panic_alerts;
CREATE POLICY "Users can update their own panic alerts" ON public.panic_alerts
  FOR UPDATE USING (auth.uid() = user_id);


-- ── STEP 4: Attach updated_at trigger ────────────────────────────────────────
DROP TRIGGER IF EXISTS panic_alerts_updated_at ON public.panic_alerts;
CREATE TRIGGER panic_alerts_updated_at
  BEFORE UPDATE ON public.panic_alerts
  FOR EACH ROW
  EXECUTE FUNCTION set_updated_at();


-- ── STEP 5: Create PostGIS RPC to find nearby users' FCM tokens ──────────────
-- Calls ST_DWithin on temporary geogs constructed from profiles coordinates.
CREATE OR REPLACE FUNCTION get_nearby_users_fcm_tokens(
  p_user_lat DOUBLE PRECISION,
  p_user_lng DOUBLE PRECISION,
  p_radius_m DOUBLE PRECISION,
  p_exclude_user_id UUID
)
RETURNS TABLE (fcm_token TEXT)
LANGUAGE sql
SECURITY DEFINER -- bypasses RLS to query profiles table location & tokens
AS $$
  SELECT fcm_token
  FROM public.profiles
  WHERE id != p_exclude_user_id
    AND fcm_token IS NOT NULL
    AND fcm_token <> ''
    AND last_lat IS NOT NULL
    AND last_lng IS NOT NULL
    AND ST_DWithin(
          ST_SetSRID(ST_MakePoint(last_lng, last_lat), 4326)::geography,
          ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
          p_radius_m
        );
$$;

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION get_nearby_users_fcm_tokens TO anon, authenticated;
