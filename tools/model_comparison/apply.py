#!/usr/bin/env python3
"""Apply exactly the reviewed snapshots and archive selected originals."""
import hashlib
import json
import sys
from pathlib import Path

from prepare import ROOT, CACHE, from_git
sys.path.insert(0, str(ROOT / 'art_source' / 'overhaul'))
from selection_policy import RETAINED, SOURCE, record_for


def apply():
    decisions = json.loads((SOURCE / 'model_choices.json').read_text())
    if not decisions.get('finished'):
        raise ValueError('The review has not been marked finished.')
    snapshot = json.loads((CACHE / 'manifest.json').read_text())
    if snapshot['baseline'] != decisions['baseline']:
        raise ValueError('The saved review and frozen baseline disagree.')
    frozen = {entry['id']: entry for entry in snapshot['entries']}
    expected = {f'{p.parent.name}/{p.stem}' for folder in ['companions', 'wildlife', 'shop', 'scenery', 'tools']
                for p in (ROOT / 'assets' / folder).glob('*.glb')}
    if set(decisions['choices']) != expected:
        raise ValueError('Selections do not cover exactly the current model inventory.')
    plan = []
    retained = {}
    # Verify every source before replacing any runtime file.
    for model in decisions['models']:
        key = model['id']
        if model['asset'] != 'assets/' + key + '.glb':
            raise ValueError('Unexpected model destination: ' + key)
        variant = decisions['choices'][key]
        if variant not in ['new', 'old']:
            raise ValueError('Invalid variant: ' + key)
        if variant == 'old':
            if key.startswith('scenery/'):
                raise ValueError('Old scenery requires an environment integration, not a direct sample replacement.')
            data = from_git(decisions['baseline'], model['asset'])
            if data != Path(frozen[key]['old']).read_bytes():
                raise ValueError('Original differs from the reviewed main model: ' + key)
        else:
            data = Path(frozen[key]['new']).read_bytes()
            if hashlib.sha256(data).hexdigest() != model['new_sha256']:
                raise ValueError('Candidate differs from the reviewed model: ' + key)
        folder, kind = key.split('/')
        record = record_for(data, folder, kind)
        record['variant'] = variant
        if variant == 'old':
            record['baseline'] = decisions['baseline']
            record['source'] = 'art_source/overhaul/retained_models/' + key + '.glb'
            retained[key] = record
        plan.append((key, model['asset'], data, record))
    if {item[0] for item in plan} != expected or len(plan) != len(expected):
        raise ValueError('Duplicate or incomplete reviewed model metadata.')
    manifest_path = SOURCE / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    for key, relative, data, record in plan:
        if key in retained:
            archive = RETAINED / (key + '.glb')
            archive.parent.mkdir(parents=True, exist_ok=True)
            archive.write_bytes(data)
        target = ROOT / relative
        if target.read_bytes() != data:
            temporary = target.with_suffix('.glb.tmp')
            temporary.write_bytes(data)
            temporary.replace(target)
        if record['variant'] == 'old':
            manifest[key] = record
        else:
            manifest[key].update(record)
    RETAINED.mkdir(parents=True, exist_ok=True)
    (RETAINED / 'manifest.json').write_text(json.dumps(retained, indent=2, sort_keys=True) + '\n')
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    print(f'APPLIED_MODEL_CHOICES: {len(retained)} old, {len(plan)-len(retained)} new')
    print('Retained originals: ' + ', '.join(retained))


if __name__ == '__main__':
    apply()
