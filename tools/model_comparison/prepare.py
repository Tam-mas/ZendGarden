#!/usr/bin/env python3
"""Freeze main and working GLBs for a local, repeatable visual comparison."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path
from scenery_baseline import extract

ROOT = Path(__file__).resolve().parents[2]
CACHE = ROOT / 'captures' / 'model_comparison'
CATEGORIES = {'companions': 'Companions', 'wildlife': 'Wildlife', 'shop': 'Structures',
              'scenery': 'Scenery', 'tools': 'Held tools'}


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def from_git(revision, path):
    data = git('show', f'{revision}:{path}')
    if data.startswith(b'version https://git-lfs.github.com/spec/v1'):
        lines = data.decode().splitlines()
        oid = next(line.split(':', 1)[1] for line in lines if line.startswith('oid sha256:'))
        base = Path(git('rev-parse', '--git-common-dir').decode().strip())
        if not base.is_absolute():
            base = ROOT / base
        stored = base / 'lfs' / 'objects' / oid[:2] / oid[2:4] / oid
        if not stored.is_file():
            raise RuntimeError(f'Missing local LFS object for {path}. Run git lfs fetch origin {revision}.')
        data = stored.read_bytes()
        if hashlib.sha256(data).hexdigest() != oid:
            raise RuntimeError(f'LFS integrity check failed for {path}')
    return data


def prepare(revision=None, refresh=False):
    previous = CACHE / 'manifest.json'
    if previous.is_file() and not refresh and revision is None:
        saved = json.loads(previous.read_text())
        if all(Path(entry['new']).is_file() and
               (not entry['old'] or entry['old'].startswith('procedural:') or Path(entry['old']).is_file())
               for entry in saved['entries']):
            print(f'Resuming frozen comparison: {len(saved["entries"])} models.')
            return saved
    if revision is None:
        decisions = ROOT / 'art_source' / 'overhaul' / 'model_choices.json'
        source = previous if previous.is_file() else decisions
        revision = json.loads(source.read_text()).get('baseline') if source.is_file() else None
        revision = revision or 'origin/main'
    sha = git('rev-parse', revision).decode().strip()
    tracked = set(git('ls-tree', '-r', '--name-only', sha, 'assets').decode().splitlines())
    CACHE.mkdir(parents=True, exist_ok=True)
    # Runtime GLTF loading keeps these snapshots out of Godot's import/export pipeline.
    (CACHE / '.gdignore').write_text('')
    entries = []
    scenery_data = None
    for category, label in CATEGORIES.items():
        for current in sorted((ROOT / 'assets' / category).glob('*.glb')):
            relative = current.relative_to(ROOT).as_posix()
            new_data = current.read_bytes()
            digest = hashlib.sha256(new_data).hexdigest()
            new_file = CACHE / 'snapshots' / digest / current.name
            new_file.parent.mkdir(parents=True, exist_ok=True)
            if not new_file.exists():
                new_file.write_bytes(new_data)
            old_file = None
            if relative in tracked:
                old_file = CACHE / 'main' / sha / category / current.name
                old_file.parent.mkdir(parents=True, exist_ok=True)
                if not old_file.exists():
                    old_file.write_bytes(from_git(sha, relative))
            elif category == 'scenery' and current.stem != 'footbridge':
                if scenery_data is None:
                    scenery_data = from_git(sha, 'assets/environment/lake_garden.glb')
                old_file = CACHE / 'main' / sha / category / current.name
                old_file.parent.mkdir(parents=True, exist_ok=True)
                names = (['DistantLakesideHamlets'] if current.stem == 'lakeside_cottage'
                         else ['GardenPavilion', 'PavilionShingleRoof', 'PavilionWindows'])
                old_file.write_bytes(extract(scenery_data, names, current.stem == 'lakeside_cottage'))
            entries.append({'id': f'{category}/{current.stem}', 'category': label,
                            'name': current.stem.replace('_', ' ').capitalize(),
                            'asset': relative, 'old': str(old_file) if old_file else '',
                            'new': str(new_file), 'new_sha256': digest})
            if category == 'scenery' and current.stem == 'footbridge' and old_file is None:
                if sha != 'ca52914172ed22ada94bda93e95f063e1fb69b0c':
                    raise RuntimeError('The procedural footbridge baseline needs updating for this main commit.')
                entries[-1]['old'] = 'procedural:main_footbridge'
            if category == 'scenery' and current.stem == 'lakeside_cottage':
                entries[-1]['old_note'] = 'Representative cottage extracted from main’s distant hamlets'
    manifest = {'schema': 1, 'baseline': sha, 'baseline_name': 'GitHub main', 'entries': entries}
    (CACHE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Prepared {len(entries)} models; {sum(bool(e["old"]) for e in entries)} have main counterparts.')
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline', help='Override the frozen main baseline commit or ref.')
    parser.add_argument('--refresh', action='store_true', help='Refresh candidates from current working assets.')
    args = parser.parse_args()
    prepare(args.baseline, args.refresh)
