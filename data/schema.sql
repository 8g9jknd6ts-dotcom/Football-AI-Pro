PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id TEXT PRIMARY KEY,
  recorded_at TEXT NOT NULL,
  category TEXT NOT NULL,
  preference_text TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'user',
  status TEXT NOT NULL DEFAULT 'active',
  applied_to_version TEXT,
  notes TEXT
);

CREATE TABLE IF NOT EXISTS matches (
  match_id TEXT PRIMARY KEY,
  kickoff_utc TEXT,
  league_code TEXT,
  league_name TEXT,
  home_team TEXT NOT NULL,
  away_team TEXT NOT NULL,
  source_name TEXT,
  source_match_ref TEXT,
  source_snapshot_path TEXT,
  source_reliability TEXT,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS analyses (
  analysis_id INTEGER PRIMARY KEY AUTOINCREMENT,
  match_id TEXT NOT NULL REFERENCES matches(match_id),
  analyzed_at TEXT NOT NULL,
  model_version TEXT NOT NULL,
  standard_pick TEXT,
  handicap_line REAL,
  handicap_pick TEXT,
  score_pick TEXT,
  goals_pick TEXT,
  ai_score REAL,
  confidence REAL,
  upset_index REAL,
  recommended_odds REAL,
  treatment TEXT,
  risk_note TEXT,
  evidence_json TEXT NOT NULL,
  UNIQUE(match_id, analyzed_at, model_version)
);

CREATE TABLE IF NOT EXISTS odds_snapshots (
  odds_id INTEGER PRIMARY KEY AUTOINCREMENT,
  match_id TEXT NOT NULL REFERENCES matches(match_id),
  company_name TEXT NOT NULL,
  market_type TEXT NOT NULL CHECK(market_type IN ('1X2','HANDICAP','TOTALS')),
  captured_at TEXT NOT NULL,
  phase TEXT NOT NULL CHECK(phase IN ('OPEN','IN_PLAY','CLOSING','UNKNOWN')),
  home_value REAL,
  draw_value REAL,
  away_value REAL,
  line TEXT,
  source_name TEXT NOT NULL,
  source_snapshot_path TEXT,
  reliability TEXT,
  UNIQUE(match_id, company_name, market_type, captured_at, phase, line)
);

CREATE TABLE IF NOT EXISTS outcomes (
  match_id TEXT PRIMARY KEY REFERENCES matches(match_id),
  recorded_at TEXT NOT NULL,
  actual_home_goals INTEGER,
  actual_away_goals INTEGER,
  actual_1x2 TEXT,
  actual_handicap TEXT,
  actual_total_goals INTEGER,
  result_source TEXT NOT NULL,
  result_source_ref TEXT,
  verified INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS settlement (
  settlement_id INTEGER PRIMARY KEY AUTOINCREMENT,
  analysis_id INTEGER NOT NULL REFERENCES analyses(analysis_id),
  stake REAL NOT NULL DEFAULT 0,
  odds REAL,
  selection TEXT,
  hit INTEGER,
  gross_return REAL,
  profit_loss REAL,
  settled_at TEXT,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_analyses_match ON analyses(match_id);
CREATE INDEX IF NOT EXISTS idx_odds_match_time ON odds_snapshots(match_id, captured_at);
CREATE INDEX IF NOT EXISTS idx_outcomes_verified ON outcomes(verified);
