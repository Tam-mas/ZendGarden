"""Exercise authored rock footings on both sampled banks without starting Blender."""
import ast
import math
from pathlib import Path
import random
import sys
import types

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'art_source'))
import ravine_profile

# The geometry emitters are pure Python. Load the actual production functions
# and their small mesh accumulator without importing Blender or generating assets.
definitions = []
source = ast.parse((ROOT / 'art_source/build_ravine.py').read_text())
definitions.extend(node for node in source.body if isinstance(node, ast.FunctionDef) and node.name in ['ledge', 'outlet_boulder'])
source = ast.parse((ROOT / 'art_source/build_distinct_areas.py').read_text())
geometry = next(node for node in source.body if isinstance(node, ast.ClassDef) and node.name == 'Geometry')
geometry.body = [node for node in geometry.body if isinstance(node, ast.FunctionDef) and node.name in ['__init__', 'poly', 'ell']]
definitions.append(geometry)
scope = {'math': math, 'random': random, 'r': ravine_profile}
exec(compile(ast.Module(body=definitions, type_ignores=[]), '<ravine geometry>', 'exec'), scope)
scope['b'] = types.SimpleNamespace(Geometry=scope['Geometry'], MATS={'granite': 'stone'})


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def normal(points):
    return cross(tuple(a - b for a, b in zip(points[1], points[0])), tuple(a - b for a, b in zip(points[2], points[0])))


count = 0
for z in range(-106, 11, 3):
    for side in [-1, 1]:
        for distance in [2., 3., 4.5]:
            x = ravine_profile.center(z) + side * distance
            position = (x, ravine_profile.ground(x, z) - .1, z)
            geometry = scope['Geometry']()
            scope['ledge'](geometry, 'ledge', position, (2., 1., 2.9), count, angle=side * .22)
            vertices, faces = geometry.groups[('ledge', 'stone')]
            assert all(y <= ravine_profile.ground(x, z) - .1399 for x, y, z in vertices[:9]), ('hovering ledge footing', position)
            for face in faces[2:]:
                points = [vertices[i] for i in face]
                axis = normal(points)
                center = tuple(sum(p[i] for p in points) / len(points) for i in range(3))
                assert axis[0] * (center[0] - position[0]) + axis[2] * (center[2] - position[2]) > 0, ('inverted side', position)
            assert normal([vertices[i] for i in faces[0]])[1] < 0
            assert normal([vertices[i] for i in faces[1]])[1] > 0
            count += 1

outlets = 0
for side in [-1, 1]:
    for distance in [2.2, 2.6, 3., 3.4, 3.8, 4.4]:
        x = ravine_profile.center(12.) + side * distance
        position = (x, ravine_profile.ground(x, 11.6), 11.6)
        geometry = scope['Geometry']()
        scope['outlet_boulder'](geometry, 'outlet', position, (1.5, 2.1, 2.), 260 + outlets)
        vertices, faces = geometry.groups[('outlet', 'stone')]
        assert all(y <= ravine_profile.ground(x, z) - .1399 for x, y, z in vertices[64:]), ('hovering outlet footing', position)
        original = scope['Geometry']()
        original.ell('outlet', 'stone', position, (1.5, 2.1, 2.), seed=260 + outlets, rough=.3)
        old_vertices, old_faces = original.groups[('outlet', 'stone')]
        assert vertices[:64] == old_vertices[:64] and faces == old_faces, 'rounded outlet crown or winding changed'
        assert all(math.isfinite(value) for vertex in vertices for value in vertex)
        outlets += 1

print(f'RAVINE_GROUNDING_RESULT: PASS — {count} ledge footings and {outlets} outlet positions, buried lower edges and retained crowns/winding')
