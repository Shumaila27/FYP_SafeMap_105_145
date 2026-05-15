-- STEP 1: Create report_categories first
CREATE TABLE report_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50),
  color VARCHAR(7),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 2: Insert default categories
INSERT INTO report_categories (name, description, icon, color) VALUES
  ('harassment', 'Street harassment incidents', 'shield', '#FF6B6B'),
  ('theft', 'Theft or snatching incidents', 'package', '#F59E0B'),
  ('crime', 'Criminal activity', 'alert-triangle', '#DC2626'),
  ('stalking', 'Stalking or following', 'eye', '#F97316'),
  ('other', 'Other safety concerns', 'info', '#6B7280');

-- STEP 3: Now create reports (which references report_categories)
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  category_id UUID REFERENCES report_categories(id),
  severity TEXT CHECK (severity IN ('low', 'medium', 'high')) DEFAULT 'medium',
  description TEXT NOT NULL,
  location_address TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  incident_time TIMESTAMPTZ DEFAULT NOW(),
  image_url TEXT,
  status TEXT CHECK (
    status IN ('pending', 'under_review', 'resolved', 'rejected')
  ) DEFAULT 'pending',
  is_anonymous BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 4: Indexes
CREATE INDEX idx_reports_status ON reports(status);
CREATE INDEX idx_reports_category ON reports(category_id);
CREATE INDEX idx_reports_incident_time ON reports(incident_time);

-- STEP 5: RLS
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can insert reports" ON reports
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can view reports" ON reports
  FOR SELECT USING (true);

CREATE POLICY "Anyone can view categories" ON report_categories
  FOR SELECT USING (is_active = true);