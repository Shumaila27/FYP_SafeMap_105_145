-- =============================================================================
-- SafeMap — Complete Map Database Migration
-- Run this entire block in Supabase SQL Editor as one migration.
-- =============================================================================


-- ── STEP 1: Realtime ──────────────────────────────────────────────────────
-- Without this, MapController._subscribeRealtime() silently receives nothing.

ALTER PUBLICATION supabase_realtime ADD TABLE reports;


-- ── STEP 2: PostGIS Extension (Enterprise Refinement #3) ─────────────────
-- Enables ST_DWithin for true circle-radius queries instead of a bounding box.
-- Supabase includes PostGIS by default — this just activates it.

CREATE EXTENSION IF NOT EXISTS postgis;


-- ── STEP 3: Map-Optimised View (Gap 2) ────────────────────────────────────
-- Joins category name + color at DB level so Dart never needs to do it.
-- Filters out rejected reports and rows with no coordinates — the map
-- should never render those anyway.

CREATE OR REPLACE VIEW reports_map_view AS
SELECT
  r.id,
  r.user_id,
  r.category_id,
  c.name          AS category_name,   -- human-readable: "harassment", "theft"
  c.color         AS category_color,  -- hex color from categories table
  r.severity,
  r.description,
  r.location_address,
  r.latitude,
  r.longitude,
  r.incident_time,
  r.image_url,
  r.status,
  r.is_anonymous,
  r.created_at,
  r.updated_at
FROM  reports r
LEFT  JOIN report_categories c ON r.category_id = c.id
WHERE r.status    != 'rejected'
  AND r.latitude   IS NOT NULL
  AND r.longitude  IS NOT NULL;

-- Allow anon + authenticated users to SELECT from the view
GRANT SELECT ON reports_map_view TO anon, authenticated;

-- Use security_invoker so the view respects the caller's RLS context
ALTER VIEW reports_map_view SET (security_invoker = true);


-- ── STEP 4: Spatial Indexes (Gap 3) ──────────────────────────────────────
-- Without these every map load does a full sequential scan.

-- Compound lat/lng index — only for mappable rows (partial index = smaller)
CREATE INDEX IF NOT EXISTS idx_reports_lat_lng
  ON reports (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Index for the realtime + recent-report queries (time DESC is intentional)
CREATE INDEX IF NOT EXISTS idx_reports_time_status
  ON reports (incident_time DESC, status)
  WHERE status != 'rejected';

-- PostGIS geography index — used by ST_DWithin in the RPC below
-- Computed column approach: stores the point as a geography once, index it
ALTER TABLE reports
  ADD COLUMN IF NOT EXISTS geog geography(Point, 4326)
  GENERATED ALWAYS AS (
    CASE
      WHEN latitude IS NOT NULL AND longitude IS NOT NULL
      THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
      ELSE NULL
    END
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_reports_geog
  ON reports USING GIST (geog)
  WHERE geog IS NOT NULL;


-- ── STEP 5: RLS Policies (Gap 4) ─────────────────────────────────────────
-- Drop the old broad SELECT policy (created in the initial schema) and
-- replace it with one that mirrors the view's WHERE clause so rejected /
-- coordinate-less rows are never served even via direct table access.

DROP POLICY IF EXISTS "Anyone can view reports" ON reports;

CREATE POLICY "Anyone can view map reports"
  ON reports
  FOR SELECT
  USING (
    status    != 'rejected'
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
  );

-- Keep the insert policy from the original schema
-- "Anyone can insert reports" — already exists, no change needed.


-- ── STEP 6: PostGIS RPC Function (Enterprise Refinement #3) ──────────────
-- Called from Dart via _client.rpc('get_nearby_reports', params: {...})
-- Returns the same columns as reports_map_view.
-- Uses ST_DWithin on the pre-computed geography column — O(log n) lookup.
-- Includes LIMIT + OFFSET for pagination (Enterprise Refinement #2).

CREATE OR REPLACE FUNCTION get_nearby_reports(
  user_lat   DOUBLE PRECISION,
  user_lng   DOUBLE PRECISION,
  radius_m   DOUBLE PRECISION DEFAULT 5000,  -- metres, default 5 km
  page_limit INT              DEFAULT 50,
  page_offset INT             DEFAULT 0
)
RETURNS TABLE (
  id               UUID,
  user_id          UUID,
  category_id      UUID,
  category_name    VARCHAR,
  category_color   VARCHAR,
  severity         TEXT,
  description      TEXT,
  location_address TEXT,
  latitude         DOUBLE PRECISION,
  longitude        DOUBLE PRECISION,
  incident_time    TIMESTAMPTZ,
  image_url        TEXT,
  status           TEXT,
  is_anonymous     BOOLEAN,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
)
LANGUAGE sql
STABLE        -- tells Postgres this function won't modify data (query planner hint)
SECURITY INVOKER  -- respects the caller's RLS context
AS $$
  SELECT
    r.id,
    r.user_id,
    r.category_id,
    c.name          AS category_name,
    c.color         AS category_color,
    r.severity,
    r.description,
    r.location_address,
    r.latitude,
    r.longitude,
    r.incident_time,
    r.image_url,
    r.status,
    r.is_anonymous,
    r.created_at,
    r.updated_at
  FROM  reports r
  LEFT  JOIN report_categories c ON r.category_id = c.id
  WHERE r.status != 'rejected'
    AND ST_DWithin(
          r.geog,
          ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
          radius_m   -- true circle radius in metres, not a bounding box square
        )
  ORDER BY r.incident_time DESC
  LIMIT  page_limit
  OFFSET page_offset;
$$;

-- Grant execute to anon + authenticated so Dart's rpc() call works
GRANT EXECUTE ON FUNCTION get_nearby_reports TO anon, authenticated;


-- ── STEP 7: Verify ────────────────────────────────────────────────────────
-- Run these SELECTs to confirm everything looks right before connecting Dart.

-- Should return your 5 seed categories
SELECT * FROM report_categories;

-- Should return 0 rows (no reports yet) but not throw an error
SELECT * FROM reports_map_view LIMIT 5;

-- Should show the new geog column
SELECT id, latitude, longitude, geog FROM reports LIMIT 3;


-- ── STEP 1: Realtime (Safe version) ───────────────────────────────────────
-- Only adds the table if it isn't already a member — no error either way.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'reports'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE reports;
  END IF;
END $$;
-- ── STEP 2: PostGIS Extension ─────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS postgis;


-- ── STEP 3: Map-Optimised View ────────────────────────────────────────────

CREATE OR REPLACE VIEW reports_map_view AS
SELECT
  r.id,
  r.user_id,
  r.category_id,
  c.name          AS category_name,
  c.color         AS category_color,
  r.severity,
  r.description,
  r.location_address,
  r.latitude,
  r.longitude,
  r.incident_time,
  r.image_url,
  r.status,
  r.is_anonymous,
  r.created_at,
  r.updated_at
FROM  reports r
LEFT  JOIN report_categories c ON r.category_id = c.id
WHERE r.status    != 'rejected'
  AND r.latitude   IS NOT NULL
  AND r.longitude  IS NOT NULL;

GRANT SELECT ON reports_map_view TO anon, authenticated;

ALTER VIEW reports_map_view SET (security_invoker = true);


-- ── STEP 4: Spatial Indexes ───────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_reports_lat_lng
  ON reports (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reports_time_status
  ON reports (incident_time DESC, status)
  WHERE status != 'rejected';

-- Pre-computed geography column for ST_DWithin
ALTER TABLE reports
  ADD COLUMN IF NOT EXISTS geog geography(Point, 4326)
  GENERATED ALWAYS AS (
    CASE
      WHEN latitude IS NOT NULL AND longitude IS NOT NULL
      THEN ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
      ELSE NULL
    END
  ) STORED;

CREATE INDEX IF NOT EXISTS idx_reports_geog
  ON reports USING GIST (geog)
  WHERE geog IS NOT NULL;


--- ── STEP 5: RLS Policies ──────────────────────────────────────────────────

DROP POLICY IF EXISTS "Anyone can view reports"      ON reports;
DROP POLICY IF EXISTS "Anyone can view map reports"  ON reports; -- safe drop if exists

CREATE POLICY "Anyone can view map reports"
  ON reports
  FOR SELECT
  USING (
    status    != 'rejected'
    AND latitude  IS NOT NULL
    AND longitude IS NOT NULL
  );

-- ── STEP 6: PostGIS RPC Function ──────────────────────────────────────────
-- FIX (Reviewer Point 2 — Stale Data / Race Condition):
-- Changed ORDER BY from (incident_time DESC) to (incident_time DESC, id ASC).
-- With only incident_time, two reports inserted at the same millisecond can
-- appear in arbitrary order, causing the same row to show on both page N and
-- page N+1. Adding id ASC makes the sort fully deterministic — every row has
-- a unique UUID so there is no ambiguity, and LIMIT/OFFSET pages are stable.

CREATE OR REPLACE FUNCTION get_nearby_reports(
  user_lat    DOUBLE PRECISION,
  user_lng    DOUBLE PRECISION,
  radius_m    DOUBLE PRECISION DEFAULT 5000,
  page_limit  INT              DEFAULT 50,
  page_offset INT              DEFAULT 0
)
RETURNS TABLE (
  id               UUID,
  user_id          UUID,
  category_id      UUID,
  category_name    VARCHAR,
  category_color   VARCHAR,
  severity         TEXT,
  description      TEXT,
  location_address TEXT,
  latitude         DOUBLE PRECISION,
  longitude        DOUBLE PRECISION,
  incident_time    TIMESTAMPTZ,
  image_url        TEXT,
  status           TEXT,
  is_anonymous     BOOLEAN,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT
    r.id,
    r.user_id,
    r.category_id,
    c.name          AS category_name,
    c.color         AS category_color,
    r.severity,
    r.description,
    r.location_address,
    r.latitude,
    r.longitude,
    r.incident_time,
    r.image_url,
    r.status,
    r.is_anonymous,
    r.created_at,
    r.updated_at
  FROM  reports r
  LEFT  JOIN report_categories c ON r.category_id = c.id
  WHERE r.status != 'rejected'
    AND ST_DWithin(
          r.geog,
          ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
          radius_m
        )
  ORDER BY r.incident_time DESC, r.id ASC  -- FIX: deterministic, no duplicate rows across pages
  LIMIT  page_limit
  OFFSET page_offset;
$$;

GRANT EXECUTE ON FUNCTION get_nearby_reports TO anon, authenticated;



-- ── STEP 7: Verify ────────────────────────────────────────────────────────

SELECT * FROM report_categories;
SELECT * FROM reports_map_view LIMIT 5;
SELECT id, latitude, longitude, geog FROM reports LIMIT 3;

-- Test the RPC function directly (replace coords with your test location)
SELECT * FROM get_nearby_reports(30.1575, 71.5249, 5000, 50, 0);


---run this in another editor:
VACUUM ANALYZE reports;