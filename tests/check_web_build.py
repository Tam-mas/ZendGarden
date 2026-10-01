#!/usr/bin/env python3
"""Check the actual exported site, including compressed payload integrity."""
import gzip
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'build/web'
for name in ('index.html', 'index.js', 'index.wasm', 'loader.js', 'pack.json', '_headers', '404.html',
             '_routes.json', 'moving.html', 'migration.css', 'migration.js', 'migration-storage.js', 'save-format.js'):
    assert (root / name).is_file(), f'Missing {name}'
assert not (root / 'index.pck').exists(), 'Oversized unsplit pack remains'
assert gzip.decompress((root / 'index.wasm').read_bytes()).startswith(b'\x00asm'), 'Invalid WASM'
manifest = json.loads((root / 'pack.json').read_text())
total = 0
for index, chunk in enumerate(manifest['chunks']):
    path = root / chunk['url']
    assert path.resolve().is_relative_to(root.resolve()), 'Chunk escaped build output'
    block = gzip.decompress(path.read_bytes())
    assert len(block) == chunk['size'], f'Wrong chunk size: {path}'
    assert hashlib.sha256(block).hexdigest() == chunk['sha256'], f'Corrupt chunk: {path}'
    if index == 0:
        assert block.startswith(b'GDPC'), 'Invalid Godot pack'
    total += len(block)
assert total == manifest['size'], 'Incomplete game pack'
for path in root.rglob('*'):
    if path.is_file():
        assert path.stat().st_size <= 25 * 1024 * 1024, f'Pages limit exceeded: {path}'
html = (root / 'index.html').read_text()
assert '$GODOT_' not in html, 'Unexpanded Godot template'
assert 'loader.js' in html
routes = json.loads((root / '_routes.json').read_text())
assert '/api/garden-transfer/*' in routes['include']
assert '/pack/*' not in routes['include'], 'Game downloads must bypass functions'
moving = (root / 'moving.html').read_text()
assert 'index.js' not in moving and 'loader.js' not in moving, 'Old-origin reader must not start the game'
print(f'PASS: browser site, WASM, {len(manifest["chunks"])} pack pieces, and Pages file limits')
