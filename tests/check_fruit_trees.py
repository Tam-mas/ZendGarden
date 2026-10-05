"""Check exported fruit attachment precision, outward lighting and variation."""
import collections
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IDS = [31, 34, 35, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91]


def read(path):
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    return json.loads(raw[20:20 + length]), raw[28 + length:]


def array(doc, blob, index):
    accessor = doc['accessors'][index]
    view = doc['bufferViews'][accessor['bufferView']]
    size = {'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[accessor['type']]
    fmt = {5126: 'f', 5123: 'H', 5121: 'B'}[accessor['componentType']]
    stride = view.get('byteStride', size * struct.calcsize(fmt))
    start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
    values = [struct.unpack_from('<' + fmt * size, blob, start + i * stride)
              for i in range(accessor['count'])]
    if accessor.get('normalized'):
        scale = {5123: 65535, 5121: 255}[accessor['componentType']]
        values = [tuple(v / scale for v in point) for point in values]
    return values


def inspect(path, prefix):
    doc, blob = read(path)
    meshes = [doc['meshes'][node['mesh']] for node in doc['nodes']
              if 'mesh' in node and node.get('name', '').startswith(prefix)]
    assert len(meshes) == 1, (path, 'Missing grouped anchored organ')
    sites = set()
    fruit_sizes = []
    for primitive in meshes[0]['primitives']:
        attrs = primitive['attributes']
        assert 'TEXCOORD_1' in attrs and 'COLOR_0' in attrs, (path, 'Missing attachment channels')
        positions = array(doc, blob, attrs['POSITION'])
        normals = array(doc, blob, attrs['NORMAL'])
        uv = array(doc, blob, attrs['TEXCOORD_1'])
        colors = array(doc, blob, attrs['COLOR_0'])
        groups = collections.defaultdict(list)
        for i, (xy, color) in enumerate(zip(uv, colors)):
            depth = (round(color[0] * 255) * 256 + round(color[1] * 255)) / 65535 * 16 - 8
            anchor = (xy[0], 1 - xy[1], depth)
            assert all(math.isfinite(v) for v in anchor)
            assert 1 < anchor[1] < 6, (path, 'Attachment outside the tree canopy')
            sites.add(tuple(round(v, 3) for v in anchor))
            groups[anchor].append(i)
        material = doc['materials'][primitive['material']]['name'].lower()
        if prefix == 'BloomFruit' and 'fruit' in material:
            dots = []
            for indices in groups.values():
                center = [sum(positions[i][j] for i in indices) / len(indices) for j in range(3)]
                radius = max(math.dist(positions[i], center) for i in indices)
                fruit_sizes.append(radius)
                dots.extend(sum(normals[i][j] * (positions[i][j] - center[j]) for j in range(3))
                            for i in indices)
            assert sum(dot > 0 for dot in dots) > len(dots) * .95, (path, material, 'Fruit normals face inward')
    if fruit_sizes:
        assert max(fruit_sizes) > min(fruit_sizes) * 1.2, (path, 'Uniform fruit sizes')
    return sites


total = 0
for plant_id in IDS:
    ripe = inspect(ROOT / 'assets/plants' / f'plant_{plant_id:02d}.glb', 'BloomFruit')
    young = inspect(ROOT / 'assets/plants/growth' / f'growth_{plant_id:02d}.glb', 'BudsFruit')
    assert len(ripe) >= 15 and len(ripe) == len(young), (plant_id, 'Fruit site coverage')
    assert all(min(math.dist(site, bud) for bud in young) < .002 for site in ripe), (plant_id, 'Buds use different branches')
    total += len(ripe)
print('FRUIT_TREE_ASSETS: PASS', len(IDS), 'trees,', total, 'matching attachments and outward fruit normals')
