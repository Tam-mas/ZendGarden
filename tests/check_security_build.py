#!/usr/bin/env python3
"""Prevent security policy and immutable build dependencies from silently regressing."""
from pathlib import Path
import json
import re
import sys
root = Path(__file__).resolve().parents[1]
site = Path(sys.argv[1]).resolve() if len(sys.argv)>1 else root / 'build/web'
html = (site / 'index.html').read_text()
assert not re.search(r'<script(?![^>]*\bsrc=)[^>]*>', html), 'Inline executable script bypasses strict CSP'
assert (site / 'godot-config.js').is_file()
export_config = (root / 'export_presets.cfg').read_text()
assert '.stats-access.txt,.dev.vars*' in export_config, 'Private local credentials must be excluded from game packs'
assert not any(path.name.startswith(('.stats-access', '.dev.vars')) for path in site.rglob('*'))
headers = (site / '_headers').read_text()
for directive in ("script-src 'self' 'wasm-unsafe-eval'", "connect-src 'self'", "frame-ancestors 'none'", "object-src 'none'", 'X-Frame-Options: DENY', 'Strict-Transport-Security:'):
    assert directive in headers, f'Missing policy: {directive}'
script_policy = headers.split('script-src ', 1)[1].split(';', 1)[0]
assert "'unsafe-inline'" not in script_policy and "'unsafe-eval'" not in script_policy
workflow = (root / '.github/workflows/web-build.yml').read_text()
for ref in re.findall(r'uses:\s+([^\s]+)', workflow):
    assert re.fullmatch(r'[^@]+@[0-9a-f]{40}', ref), f'Unpinned action: {ref}'
assert 'persist-credentials: false' in workflow
for name, entry in json.loads((root / 'tools/build_checksums.json').read_text()).items():
    assert re.fullmatch('[0-9a-f]{%d}' % (128 if entry['algorithm']=='sha512' else 64), entry['digest']), name
print('SECURITY_BUILD_CHECK: PASS — external scripts, browser policy, immutable actions, tool checksums')
