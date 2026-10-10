"""Run the production SQL against real SQLite, including retries and medians."""
import json
from pathlib import Path
import sqlite3
import subprocess

root = Path(__file__).resolve().parents[1]
queries = json.loads(subprocess.check_output(['node', '--input-type=module', '-e', """
import {UPDATE_SQL, PURGE_SQL} from './server/analytics.js';
import {TOTALS_SQL, MEDIAN_SQL, DAILY_SQL, GROUP_SQL} from './functions/api/stats.js';
console.log(JSON.stringify({UPDATE_SQL,PURGE_SQL,TOTALS_SQL,MEDIAN_SQL,DAILY_SQL,DEVICE_SQL:GROUP_SQL('device')}));
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
db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0'))
for _ in range(3):
    db.execute(queries['UPDATE_SQL'], (120, 80, 0, since + 2000, '0'))
db.execute(queries['UPDATE_SQL'], (60, 30, 1, since + 1990, '0'))
current = dict(db.execute('SELECT * FROM sessions WHERE id=?', ('0',)).fetchone())
assert current['running'] == 120 and current['advancing'] == 80 and current['ended'] == 0
assert current['last_seen'] == since + 2000
db.execute(insert, ('4', since + 4, since + 2000, 63, 'touch', 600, 500))
assert row('MEDIAN_SQL', (since,))['median'] == 600
assert row('TOTALS_SQL', (since, since))['running'] == 3720
assert len(db.execute(queries['DAILY_SQL'], (since,)).fetchall()) == 1
assert len(db.execute(queries['DEVICE_SQL'], (since,)).fetchall()) == 2
db.execute(insert, ('old', since - 91 * 86400, since, 63, 'touch', 999, 999))
db.execute(queries['PURGE_SQL'], (since - 90 * 86400,))
assert db.execute('SELECT COUNT(*) FROM sessions').fetchone()[0] == 5
print('ANALYTICS_SQL_RESULT: PASS — empty/odd/even medians, thresholds, monotonic cumulative totals, duplicates, stale reports, daily/device groups and expiry')
