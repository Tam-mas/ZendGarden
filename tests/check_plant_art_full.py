"""Full collection provenance, preserved samples, envelopes and local growth.

Run alongside check_plants.py and check_plant_growth.py, which own the general
UV/PBR, per-asset triangle limits and catalogue contracts. All comparison data
here lives in the tracked baseline; an old checkout or Blender is unnecessary.
"""
import argparse
import hashlib
import json
import math
import re
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SAMPLES = {20, 30, 109, 124, 148, 149, 158, 174, 198, 212}
FRUIT = {31, 34, 35, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91}
ALL_IDS = set(range(218))
UPDATED_IDS = ALL_IDS - SAMPLES


def records(path, expected):
    rows = json.loads((ROOT / path).read_text())
    result = {row['id']: row for row in rows}
    assert len(result) == len(rows), (path, 'Duplicate catalogue IDs')
    assert set(result) == expected, (path, 'Wrong coverage', sorted(expected - set(result)),
                                     sorted(set(result) - expected))
    return result


def read_glb(path):
    raw = path.read_bytes()
    assert raw[:4] == b'glTF', (path, 'Not a hydrated GLB; check Git LFS')
    magic, version, size = struct.unpack_from('<4sII', raw)
    assert version == 2 and size == len(raw), (path, 'Invalid GLB header')
    cursor, document, binary = 12, None, None
    while cursor < size:
        length, kind = struct.unpack_from('<I4s', raw, cursor)
        cursor += 8
        chunk = raw[cursor:cursor + length]
        assert len(chunk) == length, (path, 'Truncated GLB chunk')
        if kind == b'JSON':
            document = json.loads(chunk)
        elif kind == b'BIN\x00':
            binary = chunk
        cursor += length
    assert cursor == size and document is not None and binary is not None, (path, 'Missing GLB chunks')
    return document, binary


def accessor(doc, blob, index):
    value = doc['accessors'][index]
    view = doc['bufferViews'][value['bufferView']]
    assert 'sparse' not in value and view.get('buffer', 0) == 0, 'Unexpected external/sparse plant data'
    count = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[value['type']]
    fmt = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[value['componentType']]
    unpack = struct.Struct('<' + fmt * count)
    stride = view.get('byteStride', unpack.size)
    offset = view.get('byteOffset', 0) + value.get('byteOffset', 0)
    values = [unpack.unpack_from(blob, offset + i * stride) for i in range(value['count'])]
    if value.get('normalized'):
        divisor = {5121: 255, 5123: 65535}[value['componentType']]
        values = [tuple(component / divisor for component in point) for point in values]
    return values


def inspect(path, plant_id, growth=False):
    doc, blob = read_glb(path)
    organ = ('Buds' if growth else 'Bloom') + ('Fruit' if plant_id in FRUIT else 'Flower')
    allowed = {'Seedling', 'Juvenile', organ} if growth else {'Foliage', organ}
    names, sites = set(), set()
    lower, upper = [math.inf] * 3, [-math.inf] * 3
    triangles, anchored_vertices = 0, 0
    for node in doc['nodes']:
        # Exported attachment coordinates and positions use the same baked space.
        assert node.get('translation', [0, 0, 0]) == [0, 0, 0], (path, 'Unbaked translation')
        assert node.get('scale', [1, 1, 1]) == [1, 1, 1], (path, 'Unbaked scale')
        assert node.get('rotation', [0, 0, 0, 1]) == [0, 0, 0, 1], (path, 'Unbaked rotation')
        assert 'matrix' not in node, (path, 'Unbaked matrix')
        if 'mesh' not in node:
            continue
        exported_name = node.get('name', '')
        # Blender adds numeric suffixes when several source plants share a
        # library. Godot deliberately routes the canonical prefix in either case.
        name = re.sub(r'\.\d+$', '', exported_name)
        assert name in allowed, (path, 'Organ is not routed to its growth stage', exported_name)
        assert name not in names, (path, 'Duplicate grouped organ', name)
        names.add(name)
        for primitive in doc['meshes'][node['mesh']]['primitives']:
            assert primitive.get('mode', 4) == 4, (path, 'Non-triangle plant primitive')
            attrs = primitive['attributes']
            positions = accessor(doc, blob, attrs['POSITION'])
            assert positions, (path, name, 'Empty surface')
            index_count = doc['accessors'][primitive['indices']]['count']
            assert index_count > 0 and index_count % 3 == 0, (path, name, 'Incomplete triangles')
            triangles += index_count // 3
            for point in positions:
                assert all(math.isfinite(v) for v in point), (path, name, 'Non-finite position')
                for axis in range(3):
                    lower[axis] = min(lower[axis], point[axis])
                    upper[axis] = max(upper[axis], point[axis])
            if name != organ:
                continue
            assert 'TEXCOORD_1' in attrs and 'COLOR_0' in attrs, (path, 'Missing local attachment channels')
            uv = accessor(doc, blob, attrs['TEXCOORD_1'])
            colors = accessor(doc, blob, attrs['COLOR_0'])
            assert len(uv) == len(colors) == len(positions), (path, 'Incomplete vertex attachments')
            for xy, color in zip(uv, colors):
                assert all(math.isfinite(v) for v in (*xy, *color)), (path, 'Non-finite attachment')
                assert 0 <= color[0] <= 1 and 0 <= color[1] <= 1, (path, 'Invalid encoded attachment depth')
                depth = (round(color[0] * 255) * 256 + round(color[1] * 255)) / 65535 * 16 - 8
                anchor = (xy[0], 1 - xy[1], depth)
                sites.add(tuple(round(v, 6) for v in anchor))
                anchored_vertices += 1
    required = allowed if growth else {'Foliage'}
    assert required <= names, (path, 'Missing authored organ', sorted(required - names))
    if organ in names:
        assert sites and anchored_vertices, (path, 'No local attachments')
    return {'bounds': {'min': lower, 'max': upper}, 'sites': sites,
            'triangles': triangles, 'attachment_vertices': anchored_vertices}


def verify_envelope(plant_id, actual, baseline):
    old, new = baseline['bounds'], actual['bounds']
    assert math.isclose(new['max'][1], old['max'][1], rel_tol=.0001, abs_tol=.0001), (
        plant_id, 'Mature height changed', old['max'][1], new['max'][1])
    for axis in [0, 2]:
        old_width = old['max'][axis] - old['min'][axis]
        new_width = new['max'][axis] - new['min'][axis]
        ratio = new_width / old_width
        assert .70 <= ratio <= 1.301, (plant_id, 'Footprint exceeds the approved envelope', axis, ratio)


def verify_sites(plant_id, mature, growth):
    ripe, buds = mature['sites'], growth['sites']
    assert buds, (plant_id, 'No anchored buds or growing tips')
    if not ripe:  # Foliage-only species still need their authored growing tips.
        return
    # A plant can also carry vegetative growing tips. Every mature flower or
    # fruit must have its own preceding bud; extra bud-only tips are legitimate.
    assert len(buds) >= len(ripe), (plant_id, 'Some mature organs have no preceding bud', len(ripe), len(buds))
    assert all(min(math.dist(site, bud) for bud in buds) < .002 for site in ripe), (
        plant_id, 'A flower/fruit grows from a different attachment than its bud')
    for anchor in ripe:
        assert all(mature['bounds']['min'][axis] - .025 <= anchor[axis] <=
                   mature['bounds']['max'][axis] + .025 for axis in range(3)), (
            plant_id, 'Local attachment lies outside the plant', anchor)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--enforce-baseline-budget', action='store_true',
                        help='also require aggregate mature triangles not to exceed the pre-pass baseline')
    args = parser.parse_args()
    baseline = records('art_source/plant_full_baseline.json', ALL_IDS)
    updated = records('art_source/plant_full_art_manifest.json', UPDATED_IDS)
    mature_records = records('art_source/botanical_manifest.json', ALL_IDS)
    growth_records = records('art_source/plant_growth_manifest.json', ALL_IDS)
    sources = set()
    for plant_id, row in updated.items():
        source = row['source']
        assert re.fullmatch(r'art_source/plant_full_\d{2}\.blend', source), (plant_id, 'Unexpected source', source)
        assert (ROOT / source).is_file(), (plant_id, 'Missing editable Blender source', source)
        sources.add(source)
        assert row['name'] == baseline[plant_id]['name'], (plant_id, 'Plant identity changed')
        assert math.isclose(row['height'], baseline[plant_id]['bounds']['max'][1], abs_tol=.0001), (
            plant_id, 'Audit height differs from tracked baseline')
        assert len(row['normalization']) == 3 and all(math.isfinite(v) and v > 0 for v in row['normalization']), (
            plant_id, 'Invalid source normalization')
        for record in [mature_records[plant_id], growth_records[plant_id]]:
            assert record['source'] == source and record.get('full_art_revision') == 1, (
                plant_id, 'Asset manifest does not point to its full-pass source')
    totals = {'mature_triangles': 0, 'growth_triangles': 0, 'attachment_vertices': 0, 'flowering_species': 0}
    for plant_id in sorted(ALL_IDS):
        mature_path = ROOT / f'assets/plants/plant_{plant_id:02d}.glb'
        growth_path = ROOT / f'assets/plants/growth/growth_{plant_id:02d}.glb'
        if plant_id in SAMPLES:
            for path, key in [(mature_path, 'mature_sha256'), (growth_path, 'growth_sha256')]:
                assert hashlib.sha256(path.read_bytes()).hexdigest() == baseline[plant_id][key], (
                    plant_id, 'An approved sample asset was overwritten', path.name)
        mature = inspect(mature_path, plant_id)
        growth = inspect(growth_path, plant_id, growth=True)
        verify_envelope(plant_id, mature, baseline[plant_id])
        verify_sites(plant_id, mature, growth)
        assert mature['triangles'] == mature_records[plant_id]['triangles'], (plant_id, 'Stale mature triangle record')
        assert growth['triangles'] == growth_records[plant_id]['triangles'], (plant_id, 'Stale growth triangle record')
        if plant_id in updated:
            assert mature['triangles'] == updated[plant_id]['mature_triangles'], (plant_id, 'Stale full-pass mature audit')
            assert growth['triangles'] == updated[plant_id]['growth_triangles'], (plant_id, 'Stale full-pass growth audit')
        totals['mature_triangles'] += mature['triangles']
        totals['growth_triangles'] += growth['triangles']
        totals['attachment_vertices'] += mature['attachment_vertices'] + growth['attachment_vertices']
        totals['flowering_species'] += bool(mature['sites'])
    old_total = sum(row['triangles'] for row in baseline.values())
    if args.enforce_baseline_budget:
        assert totals['mature_triangles'] <= old_total, ('Aggregate mature geometry exceeds the baseline', totals, old_total)
    print('PLANT_ART_FULL_ASSETS: PASS', json.dumps({
        'species': len(ALL_IDS), 'updated': len(updated), 'preserved_samples': len(SAMPLES),
        'source_libraries': len(sources), 'baseline_mature_triangles': old_total,
        'mature_triangle_ratio': round(totals['mature_triangles'] / old_total, 4), **totals}, sort_keys=True))


if __name__ == '__main__':
    main()
