"""Keep reviewed originals and approved supplied sculpts in runtime exports."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'art_source' / 'overhaul'
RETAINED = SOURCE / 'retained_models'


def selected_old(key):
    choices = SOURCE / 'model_choices.json'
    return choices.is_file() and json.loads(choices.read_text()).get('choices', {}).get(key) == 'old'


def record_for(data, folder, kind):
    size = struct.unpack_from('<I', data, 12)[0]
    doc = json.loads(data[20:20+size])
    return {'kind': kind, 'folder': folder, 'bytes': len(data),
            'triangles': sum(doc['accessors'][p['indices']]['count']//3
                             for mesh in doc['meshes'] for p in mesh['primitives']),
            'meshes': len(doc['meshes']), 'clips': [a.get('name', '') for a in doc.get('animations', [])],
            'sha256': hashlib.sha256(data).hexdigest()}


def retained_record(key):
    manifest = json.loads((RETAINED / 'manifest.json').read_text())
    return manifest[key]


def preserve_selection(path, record):
    """Called after individual Blender exports, including interactive MCP rebuilds."""
    key = record['folder'] + '/' + record['kind']
    choices = json.loads((SOURCE/'model_choices.json').read_text())
    supplied = choices.get('supplied_models', {}).get(record['kind'], {})
    if supplied.get('production_asset') == 'assets/'+key+'.glb':
        canonical = ROOT/supplied['canonical_export']
        data = canonical.read_bytes()
        if hashlib.sha256(data).hexdigest() != supplied['sha256']:
            raise ValueError('Approved supplied sculpt integrity check failed: '+key)
        if path.read_bytes() != data:
            candidate = path.read_bytes()
            digest = hashlib.sha256(candidate).hexdigest()
            cache = ROOT/'captures/model_comparison/snapshots'/digest/path.name
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_bytes(candidate)
            path.write_bytes(data)
        return dict(record_for(data,record['folder'],record['kind']),variant='supplied-stl')
    if not selected_old(key):
        record['variant'] = 'new'
        return record
    original = RETAINED / (key + '.glb')
    saved = retained_record(key)
    data = original.read_bytes()
    if hashlib.sha256(data).hexdigest() != saved['sha256']:
        raise ValueError('Retained model integrity check failed: ' + key)
    # Keep the freshly authored candidate available for another review, while
    # editable Blender source galleries continue to contain the new anatomy.
    candidate = path.read_bytes()
    digest = hashlib.sha256(candidate).hexdigest()
    cache = ROOT / 'captures' / 'model_comparison' / 'snapshots' / digest / path.name
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_bytes(candidate)
    path.write_bytes(data)
    return dict(saved)
