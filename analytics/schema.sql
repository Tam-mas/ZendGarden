-- Anonymous session summaries only. Never store garden data or visitor identities.
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  started INTEGER NOT NULL,
  last_seen INTEGER NOT NULL,
  version INTEGER NOT NULL,
  device TEXT NOT NULL CHECK(device IN ('desktop', 'touch')),
  running INTEGER NOT NULL DEFAULT 0,
  advancing INTEGER NOT NULL DEFAULT 0,
  ended INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS sessions_started ON sessions(started);
