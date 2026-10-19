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

-- No session identifiers, dates or secrets are included inside published payloads.
CREATE TABLE IF NOT EXISTS public_activity (
  day INTEGER PRIMARY KEY,
  payload TEXT NOT NULL CHECK(json_valid(payload))
);
-- Aggregate admission counters only; no visitor information is stored.
CREATE TABLE IF NOT EXISTS analytics_limits (
  name TEXT PRIMARY KEY CHECK(name IN ('starts', 'reports')),
  window INTEGER NOT NULL,
  hits INTEGER NOT NULL
);
