-- Apply once to an existing installation before deploying clock-progress reports.
-- NULL preserves the distinction between old, incomplete data and measured zero.
ALTER TABLE sessions ADD COLUMN game_minutes INTEGER CHECK(game_minutes >= 0);
