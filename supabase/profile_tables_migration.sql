-- ============================================================
--  SafeMap – COMPLETE FIX: RLS Policies + Missing Setup
--  Run this ENTIRE script in Supabase → SQL Editor
--
--  This script:
--  1. Ensures all required columns exist
--  2. Drops ALL existing RLS policies and recreates them correctly
--  3. Fixes the handle_new_user trigger
--  4. Creates user_stats / user_settings rows for existing users
--     who may be missing them
-- ============================================================


-- ── STEP 1: Ensure columns exist (safe to re-run) ────────────

DO $$
BEGIN
  -- Add phone to profiles if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'phone'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN phone TEXT;
  END IF;

  -- Add guardian_profile_id to emergency_contacts if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'emergency_contacts' AND column_name = 'guardian_profile_id'
  ) THEN
    ALTER TABLE public.emergency_contacts
      ADD COLUMN guardian_profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END;
$$;


-- ── STEP 2: Enable RLS on all tables ─────────────────────────

ALTER TABLE public.profiles           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements  ENABLE ROW LEVEL SECURITY;


-- ── STEP 3: DROP all existing policies to start fresh ────────

-- profiles
DROP POLICY IF EXISTS "profiles_select"     ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_any" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert"     ON public.profiles;
DROP POLICY IF EXISTS "profiles_update"     ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete"     ON public.profiles;

-- user_stats
DROP POLICY IF EXISTS "stats_select" ON public.user_stats;
DROP POLICY IF EXISTS "stats_insert" ON public.user_stats;
DROP POLICY IF EXISTS "stats_update" ON public.user_stats;

-- emergency_contacts
DROP POLICY IF EXISTS "contacts_select" ON public.emergency_contacts;
DROP POLICY IF EXISTS "contacts_insert" ON public.emergency_contacts;
DROP POLICY IF EXISTS "contacts_update" ON public.emergency_contacts;
DROP POLICY IF EXISTS "contacts_delete" ON public.emergency_contacts;

-- user_settings
DROP POLICY IF EXISTS "settings_select" ON public.user_settings;
DROP POLICY IF EXISTS "settings_insert" ON public.user_settings;
DROP POLICY IF EXISTS "settings_update" ON public.user_settings;
DROP POLICY IF EXISTS "settings_upsert" ON public.user_settings;

-- user_achievements
DROP POLICY IF EXISTS "achievements_select" ON public.user_achievements;
DROP POLICY IF EXISTS "achievements_insert" ON public.user_achievements;


-- ── STEP 4: Recreate all RLS policies correctly ───────────────

-- ── profiles ──
-- SELECT: Any authenticated user can read any profile
--         (needed for guardian search by phone/email)
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- INSERT: Users can only insert their own profile row
CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- UPDATE: Users can only update their own profile
CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

-- ── user_stats ──
-- SELECT: user can read own stats
CREATE POLICY "stats_select" ON public.user_stats
  FOR SELECT USING (auth.uid() = user_id);

-- INSERT: Allow system/trigger to insert (SECURITY DEFINER triggers bypass RLS,
--         but we also allow direct inserts for fallback)
CREATE POLICY "stats_insert" ON public.user_stats
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE: user can update own stats
CREATE POLICY "stats_update" ON public.user_stats
  FOR UPDATE USING (auth.uid() = user_id);

-- ── emergency_contacts ──
CREATE POLICY "contacts_select" ON public.emergency_contacts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "contacts_insert" ON public.emergency_contacts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "contacts_update" ON public.emergency_contacts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "contacts_delete" ON public.emergency_contacts
  FOR DELETE USING (auth.uid() = user_id);

-- ── user_settings ──
CREATE POLICY "settings_select" ON public.user_settings
  FOR SELECT USING (auth.uid() = user_id);

-- ALL covers SELECT + INSERT + UPDATE + DELETE
CREATE POLICY "settings_all" ON public.user_settings
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── user_achievements ──
-- Read-only from client; written by DB trigger
CREATE POLICY "achievements_select" ON public.user_achievements
  FOR SELECT USING (auth.uid() = user_id);


-- ── STEP 5: Fix handle_new_user trigger ──────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Create profile row
  INSERT INTO public.profiles (id, name, email, phone)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(COALESCE(NEW.email, ''), '@', 1)
    ),
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', NULL)
  )
  ON CONFLICT (id) DO NOTHING;

  -- Create stats row
  INSERT INTO public.user_stats (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  -- Create settings row
  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Re-attach trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();


-- ── STEP 6: Backfill missing user_stats / user_settings rows ──
-- For users who signed up before the trigger was created

INSERT INTO public.user_stats (user_id)
SELECT id FROM public.profiles
WHERE id NOT IN (SELECT user_id FROM public.user_stats)
ON CONFLICT DO NOTHING;

INSERT INTO public.user_settings (user_id)
SELECT id FROM public.profiles
WHERE id NOT IN (SELECT user_id FROM public.user_settings)
ON CONFLICT DO NOTHING;


-- ── STEP 7: Storage bucket policies ──────────────────────────

-- Ensure avatars bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', TRUE)
ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "avatar_upload" ON storage.objects;
DROP POLICY IF EXISTS "avatar_update" ON storage.objects;
DROP POLICY IF EXISTS "avatar_select" ON storage.objects;
DROP POLICY IF EXISTS "avatar_delete" ON storage.objects;

CREATE POLICY "avatar_select" ON storage.objects
  FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatar_upload" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatar_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "avatar_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );


-- ── DONE ─────────────────────────────────────────────────────
-- Summary of what was fixed:
-- 1. profiles: SELECT now allows ANY authenticated user to read any profile
--              (fixes guardian phone/email search + profile loading)
-- 2. user_stats: Added INSERT policy (allows backfill & new user creation)
-- 3. user_settings: Fixed "FOR ALL" policy with proper WITH CHECK clause
-- 4. Trigger: Improved name extraction (full_name, name, or email prefix)
-- 5. Backfilled missing stats/settings rows for existing users
-- 6. Storage: Added DELETE policy for avatar removal
