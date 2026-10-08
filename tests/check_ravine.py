"""Audit the shipped stream model, including clear bridge lanes and bank trails."""
import json
import math
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'art_source'))
import ravine_profile as profile

path = ROOT / 'assets/environment/alpine_ravine.glb'
raw = path.read_bytes()
assert raw[:4] == b'glTF'
size = struct.unpack_from('<I', raw, 12)[0]
doc = json.loads(raw[20:20 + size])
binary = raw[28 + size:]
parents = {child: index for index, node in enumerate(doc['nodes']) for child in node.get('children', [])}


def accessor(index):
    entry = doc['accessors'][index]
    view = doc['bufferViews'][entry['bufferView']]
    width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[entry['type']]
    fmt = '<' + {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[entry['componentType']] * width
    stride = view.get('byteStride', struct.calcsize(fmt))
    offset = view.get('byteOffset', 0) + entry.get('byteOffset', 0)
    return [struct.unpack_from(fmt, binary, offset + j * stride) for j in range(entry['count'])]


def world(index, point):
    node = doc['nodes'][index]
    if 'matrix' in node:
        m = node['matrix']
        point = tuple(sum(m[c * 4 + row] * point[c] for c in range(3)) + m[12 + row] for row in range(3))
    else:
        x, y, z = [v * s for v, s in zip(point, node.get('scale', [1, 1, 1]))]
        a, b, c, w = node.get('rotation', [0, 0, 0, 1])
        point = ((1 - 2 * (b * b + c * c)) * x + 2 * (a * b - c * w) * y + 2 * (a * c + b * w) * z,
                 2 * (a * b + c * w) * x + (1 - 2 * (a * a + c * c)) * y + 2 * (b * c - a * w) * z,
                 2 * (a * c - b * w) * x + 2 * (b * c + a * w) * y + (1 - 2 * (a * a + b * b)) * z)
        point = tuple(v + t for v, t in zip(point, node.get('translation', [0, 0, 0])))
    return world(parents[index], point) if index in parents else point


triangles = 0
lane_vertices = 0
bank_vertices = 0
anchors = 0
assert doc.get('images') and all('bufferView' in image and 'uri' not in image for image in doc['images'])
for index, node in enumerate(doc['nodes']):
    name = node.get('name', '')
    if 'area_species' in node.get('extras', {}):
        x, y, z = world(index, (0, 0, 0))
        assert 29.05 < x < 40.8, ('botanical blocks bank trail', name, x, z)
        assert all(abs(z - crossing) >= 2.3 for crossing in profile.BRIDGES), ('botanical blocks bridge view', name, x, z)
        anchors += 1
    if 'mesh' not in node:
        continue
    for primitive in doc['meshes'][node['mesh']]['primitives']:
        attrs = primitive['attributes']
        assert {'POSITION', 'NORMAL', 'TEXCOORD_0'} <= attrs.keys(), name
        triangles += doc['accessors'][primitive['indices']]['count'] // 3
        for channel in ['POSITION', 'NORMAL', 'TEXCOORD_0']:
            assert all(math.isfinite(v) for row in accessor(attrs[channel]) for v in row), (name, channel)
        points = [world(index, point) for point in accessor(attrs['POSITION'])]
        if name.startswith('StoneBridge'):
            crossing = profile.BRIDGES[int(name[len('StoneBridge')])]
            for x, y, z in points:
                if y > profile.deck(x, crossing) + .035:
                    assert abs(z - crossing) >= 1.22, ('masonry obstructs bridge walking lane', name, x, y, z)
                    lane_vertices += 1
        if name.startswith('Boulder granite reach'):
            assert all(28.35 < x < 41.65 for x, _, _ in points), ('stone obstructs protected bank trail', name)
            bank_vertices += len(points)

assert 0 < triangles < 120000, ('ravine detail budget', triangles)
assert lane_vertices > 0 and bank_vertices > 0 and 100 < anchors < 650
assert all(any(node.get('name', '').startswith('StoneBridge%d' % j) for node in doc['nodes']) for j in range(3))
assert all(any(node.get('name', '').startswith('Cascade granite shelves%d' % j) for node in doc['nodes']) for j in range(4))
manifest = json.loads((ROOT / 'art_source/areas/ravine_manifest.json').read_text())
assert manifest['triangles'] == triangles and manifest['bytes'] == len(raw), 'ravine manifest is stale'
print(f'RAVINE_ASSET_RESULT: PASS — {triangles:,} triangles, {anchors} botanical anchors, three clear bridges, four cascade shelves and clear bank trails')
