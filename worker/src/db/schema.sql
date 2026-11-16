CREATE TABLE IF NOT EXISTS gallery_items (
  submission_id   TEXT PRIMARY KEY,
  academic_year   INTEGER NOT NULL,
  assignment_id   TEXT NOT NULL,
  student_id      TEXT NOT NULL,
  first_name      TEXT,
  state           TEXT NOT NULL,
  district        TEXT NOT NULL,
  school          TEXT NOT NULL,
  grade           INTEGER NOT NULL,
  media_type      TEXT NOT NULL DEFAULT 'image',
  score           REAL,
  promoted_at     INTEGER NOT NULL,
  visible         INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_gallery_school_grade ON gallery_items(school, grade, visible, promoted_at);
CREATE INDEX IF NOT EXISTS idx_gallery_district_grade ON gallery_items(district, grade, visible, promoted_at);
CREATE INDEX IF NOT EXISTS idx_gallery_state_grade ON gallery_items(state, grade, visible, promoted_at);
CREATE INDEX IF NOT EXISTS idx_gallery_assignment ON gallery_items(assignment_id, visible, promoted_at);

CREATE TABLE IF NOT EXISTS app_config (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);