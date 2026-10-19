"""Run the production SQL against real SQLite, including retries and medians."""
import json
from pathlib import Path
import sqlite3
import subprocess

root = Path(__file__).resolve().parents[1]
queries = json.loads(subprocess.check_output(['node', '--input-type=module', '-e', """
import {UPDATE_SQL, PURGE_SQL} from './server/analytics.js';
import {TOTALS_SQL, PUBLIC_TOTALS_SQL, MEDIAN_SQL, DAILY_SQL, GROUP_SQL} from './functions/api/stats.js';
import {SNAPSHOT_SQL,SNAPSHOT_READ_SQL,ADMISSION_SQL} from './server/public_activity.js';
console.log(JSON.stringify({UPDATE_SQL,PURGE_SQL,TOTALS_SQL,PUBLIC_TOTALS_SQL,MEDIAN_SQL,DAILY_SQL,DEVICE_SQL:GROUP_SQL('device'),SNAPSHOT_SQL,SNAPSHOT_READ_SQL,ADMISSION_SQL}));
"""], cwd=root, text=True))
db = sqlite3.connect(':memory:')
db.row_factory = sqlite3.Row
db.executescript((root / 'analytics/schema.sql').read_text())
since = 1791504000
def row(name, params):
    return dict(db.execute(queries[name], params).fetchone())
assert row('MEDIAN_SQL', (since,))['median'] == 0
insert = 'INSERT INTO sessions(id,started,last_seen,version,device,running,advancing) VALUES (?,?,?,?,?,?,?)'
for i, duration in enumerate([60, 300, 900, 1800]):
    db.execute(insert, (str(i), since + i, since + 1800, 63, 'desktop' if i % 2 else 'touch', duration, duration // 2))
assert row('MEDIAN_SQL', (since,))['median'] == 600
assert row('TOTALS_SQL', (since, since))['running'] == 3060
assert row('TOTALS_SQL', (since, since))['over15'] == 2
public_totals = row('PUBLIC_TOTALS_SQL', (since,))
assert public_totals['running'] == 3060 and 'recent' not in public_totals
db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0', None))
for _ in range(3):
    db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0', None))
db.execute(queries['UPDATE_SQL'], (60, 30, 1, since + 1990, '0', None))
current = dict(db.execute('SELECT * FROM sessions WHERE id=?', ('0',)).fetchone())
assert current['running'] == 120 and current['advancing'] == 80 and current['ended'] == 0
assert current['last_seen'] == since + 2000
db.execute(insert, ('4', since + 4, since + 2000, 63, 'touch', 600, 500))
assert row('MEDIAN_SQL', (since,))['median'] == 600
assert row('TOTALS_SQL', (since, since))['running'] == 3720
assert row('PUBLIC_TOTALS_SQL', (since,))['longest'] == 1800
assert len(db.execute(queries['DAILY_SQL'], (since,)).fetchall()) == 1
assert len(db.execute(queries['DEVICE_SQL'], (since,)).fetchall()) == 2
db.execute(insert, ('old', since - 91 * 86400, since, 63, 'touch', 999, 999))
db.execute(queries['PURGE_SQL'], (since - 90 * 86400,))
assert db.execute('SELECT COUNT(*) FROM sessions').fetchone()[0] == 5

# Today's visits are absent; yesterday's published payload cannot change even
# when sessions change or several collectors attempt publication on the same day.
day = since + 86400
db.execute(insert, ('today', day + 1, day + 20, 74, 'touch', 9999, 1000))
db.execute(queries['SNAPSHOT_SQL'], (day,))
published = row('SNAPSHOT_READ_SQL', (day,))['payload']
public = json.loads(published)
assert public['totals']['sessions'] == 5 and public['totals']['longest'] == 1800
assert public['totals']['median'] == 600
assert set(public) == {'days', 'totals', 'devices'}
assert set(public['devices'][0]) == {'name', 'sessions'}
db.execute('UPDATE sessions SET running=999999')
db.execute(queries['SNAPSHOT_SQL'], (day,))
assert row('SNAPSHOT_READ_SQL', (day,))['payload'] == published
db.execute(queries['SNAPSHOT_SQL'], (day + 86400,))
assert row('SNAPSHOT_READ_SQL', (day + 86400,))['payload'] != published
assert json.loads(row('SNAPSHOT_READ_SQL', (day + 86400,))['payload'])['totals']['longest'] <= 2 * 86400

# Atomic shared budgets cannot be reset by an out-of-order older request.
for _ in range(120):
    assert db.execute(queries['ADMISSION_SQL'], ('starts', 500, 120)).fetchone()
assert db.execute(queries['ADMISSION_SQL'], ('starts', 500, 120)).fetchone() is None
assert db.execute(queries['ADMISSION_SQL'], ('starts', 499, 120)).fetchone() is None
assert db.execute(queries['ADMISSION_SQL'], ('starts', 501, 120)).fetchone()['hits'] == 1
assert db.execute('SELECT COUNT(*) FROM analytics_limits').fetchone()[0] == 1

# New clock counters can include skips larger than elapsed wall time; retries
# cannot inflate them and old clients cannot erase measured clock progress.
db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0', 1632))
db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0', 1632))
db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0', 1200))
db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0', None))
assert db.execute('SELECT game_minutes FROM sessions WHERE id=?', ('0',)).fetchone()[0] == 1632
assert row('TOTALS_SQL', (since, since))['game_minutes_legacy_sessions'] == 5
print('ANALYTICS_SQL_RESULT: PASS — empty/odd/even medians, thresholds, monotonic cumulative totals, duplicates, stale reports, daily/device groups and expiry')
