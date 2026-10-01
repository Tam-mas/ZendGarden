"""Validate actual exported roof glazing, including mesh-node transforms."""
import argparse
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--model', type=Path, default=ROOT/'assets/shop/greenhouse.glb')
args = parser.parse_args()
raw = args.model.read_bytes()
length = struct.unpack_from('<I', raw, 12)[0]
doc = json.loads(raw[20:20+length])
binary = raw[28+length:]


def accessor(index):
    item = doc['accessors'][index]
    view = doc['bufferViews'][item['bufferView']]
    component = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[item['componentType']]
    count = {'SCALAR': 1, 'VEC3': 3}[item['type']]
    fmt = '<' + component*count
    stride = view.get('byteStride', struct.calcsize(fmt))
    start = view.get('byteOffset', 0) + item.get('byteOffset', 0)
    return [struct.unpack_from(fmt, binary, start+i*stride) for i in range(item['count'])]


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


parents = {child: i for i, node in enumerate(doc['nodes']) for child in node.get('children', [])}


def transformed(point, index):
    node = doc['nodes'][index]
    assert 'matrix' not in node, 'Expected exported TRS transforms'
    point = tuple(a*b for a, b in zip(point, node.get('scale', [1, 1, 1])))
    qx, qy, qz, qw = node.get('rotation', [0, 0, 0, 1])
    vector = (qx, qy, qz)
    tangent = tuple(2*x for x in cross(vector, point))
    turn = cross(vector, tangent)
    point = tuple(p+qw*t+c+d for p,t,c,d in zip(point, tangent, turn, node.get('translation',[0,0,0])))
    return transformed(point, parents[index]) if index in parents else point


roof_faces = 0
regions = set()
for index, node in enumerate(doc['nodes']):
    if 'mesh' not in node:
        continue
    for primitive in doc['meshes'][node['mesh']]['primitives']:
        material = doc['materials'][primitive['material']]
        if not material.get('name', '').startswith('Greenhouse glass'):
            continue
        points = [transformed(p, index) for p in accessor(primitive['attributes']['POSITION'])]
        indices = [p[0] for p in accessor(primitive['indices'])]
        for i in range(0, len(indices), 3):
            triangle = [points[k] for k in indices[i:i+3]]
            x, y, z = (sum(p[a] for p in triangle)/3 for a in range(3))
            if y < 2.35 or abs(z) > 1.30:
                continue  # Side walls and the intentionally vertical end gables.
            ab = tuple(b-a for a,b in zip(triangle[0],triangle[1]))
            ac = tuple(b-a for a,b in zip(triangle[0],triangle[2]))
            normal = cross(ab, ac)
            area = math.sqrt(sum(v*v for v in normal))/2
            if area < .1:
                continue  # Thin edges and bevel faces.
            assert abs(y-(3.05-.75*abs(x)/1.6)) < .018, f'Roof glass out of roof plane at {(x,y,z)}'
            assert abs(normal[2]) < .001*math.sqrt(sum(v*v for v in normal)), 'Glass width is not parallel to ridge'
            roof_faces += 1
            regions.add((x > 0, min(range(4),key=lambda j: abs(z-[-1.05,-.35,.35,1.05][j]))))
assert roof_faces >= 32 and len(regions) == 8, f'Missing roof panes: {roof_faces} faces, {len(regions)} bays'
print(f'GREENHOUSE_CHECK: PASS — eight correctly sloped panes, {roof_faces} large glass faces')
