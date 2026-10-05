"""Branch-attached fruit with repeatable variation and compact growth anchors.
UV2 stores game X/Y; two colour bytes store game Z to sub-millimetre accuracy.
The extra channels are data, never albedo, and survive grouped GLB rendering.
"""
import math, random
from mathutils import Vector

FRUIT_TREES = {'Apple', 'Lemon', 'Olive', 'Fig', 'Pear', 'Peach', 'Plum',
               'Apricot', 'Nectarine', 'Orange', 'Mandarin', 'Lime', 'Avocado'}


def fruit_palette(name, palette, maps):
    import bpy
    from botanical_geometry import material
    from botanical_detail import texture_material
    shades = {'Apple': ['b94f39', 'd28c48'], 'Lemon': ['cebc48', 'dccd66'],
              'Olive': ['586338', '333e2c'], 'Fig': ['69566f'], 'Pear': ['a6ad51'],
              'Peach': ['dda45f'], 'Plum': ['57436e'], 'Apricot': ['df9450'],
              'Nectarine': ['c96b41'], 'Orange': ['d98335'], 'Mandarin': ['df9134'],
              'Lime': ['68963e'], 'Avocado': ['3b512f']}
    palette = list(palette[:4])
    for i, color in enumerate(shades[name]):
        label = name + ' varied fruit ' + str(i)
        pigment = bpy.data.materials.get(label)
        if pigment is None:
            pigment = material(label, color, .55)
            texture_material(pigment, 'fruit', maps)
        palette.append(pigment)
    return palette


def fruit_rng(name):
    return random.Random(92617 + sum((i + 1) * ord(c) for i, c in enumerate(name)))


def mark_anchor(geometry, start, anchor):
    if not hasattr(geometry, 'fruit_anchors'):
        geometry.fruit_anchors = {}
    geometry.fruit_anchors.update({i: tuple(anchor) for i in range(start, len(geometry.v))})


def hanging_fruit(b, anchor, name, radius, rng, mat=0):
    anchor = Vector(anchor)
    r = radius * rng.uniform(.76, 1.13)
    tilt = Vector((rng.uniform(-.24, .24), rng.uniform(-.24, .24), 1)).normalized()
    rotation = Vector((0, 0, 1)).rotation_difference(tilt)
    stretch = {'Pear': 1.2, 'Avocado': 1.34, 'Fig': 1.08, 'Lemon': 1.24,
               'Olive': 1.3, 'Mandarin': .77}.get(name, .94 if name == 'Apple' else 1)
    pole = stretch * (.90 if name == 'Apple' else 1)
    stalk = r * rng.uniform(.28, .65)
    center = anchor - tilt * (r * pole + stalk)
    start = len(b.v)
    b.tube([anchor, anchor.lerp(center + tilt * r * pole, .5),
            center + tilt * r * pole], [.0024, .0018, .0014], 3, 5)
    rings, sides = 12, 20
    base = len(b.v)
    phase = rng.uniform(0, math.tau)
    for i in range(rings + 1):
        t = i / rings
        z, profile = math.cos(math.pi * t), math.sin(math.pi * t)
        if name in ['Pear', 'Avocado', 'Fig']:
            profile *= .78 - .28 * z
        if name == 'Apple':
            profile = profile ** .82 * .90
            z *= 1 - .10 * abs(z) ** 8
        elif name in ['Lemon', 'Olive']:
            profile *= .80 if name == 'Lemon' else .72
        for j in range(sides):
            angle = j * math.tau / sides
            rr = profile * (1 + .025 * math.cos(3 * angle + phase))
            if name in ['Peach', 'Apricot', 'Nectarine', 'Plum']:
                rr *= 1 - .055 * math.exp(-(math.sin(angle / 2) / .13) ** 2)
            local = Vector((math.cos(angle) * rr * r, math.sin(angle) * rr * r, z * stretch * r))
            b.v.append(tuple(center + rotation @ local))
            b.uv[len(b.v) - 1] = (j / sides, t)
    for i in range(rings):
        for j in range(sides):
            a = base + i * sides + j
            c = base + i * sides + (j + 1) % sides
            b.face((a, a + sides, c + sides, c), mat)
    if name in ['Apple', 'Pear', 'Fig']:
        end = center - tilt * r * stretch * (.90 if name == 'Apple' else 1)
        b.ellipsoid(end, (r * .065, r * .065, r * .02), 3, 3, 6)
    mark_anchor(b, start, anchor)


def add_anchor_channels(mesh, geometry):
    """Keep attachment precision even when Godot packs vertex colours to RGBA8."""
    anchors = getattr(geometry, 'fruit_anchors', None)
    if not anchors:
        return
    uv = mesh.uv_layers.new(name='Fruit anchors')
    colors = mesh.color_attributes.new(name='Fruit anchor depth', type='FLOAT_COLOR', domain='CORNER')
    for loop in mesh.loops:
        x, y, z = anchors[loop.vertex_index]
        uv.data[loop.index].uv = (x, z)  # Blender Z-up -> game Y-up.
        depth = round((-y + 8) / 16 * 65535)
        assert 0 <= depth <= 65535, 'Fruit attachment exceeds encoding range'
        colors.data[loop.index].color = (depth // 256 / 255, depth % 256 / 255, 1, 1)
    mesh.color_attributes.active_color = colors


def attached_buds(mesh, geometry, height):
    """Use exactly the mature attachment sites, without spatial clustering."""
    uv = mesh.uv_layers.get('Fruit anchors')
    colors = mesh.color_attributes.get('Fruit anchor depth')
    assert uv and colors, 'Rebuild mature fruit trees before their growth stages'
    anchors = set()
    for loop in mesh.loops:
        x, z = uv.data[loop.index].uv
        r, g, *_ = colors.data[loop.index].color
        game_z = (round(r * 255) * 256 + round(g * 255)) / 65535 * 16 - 8
        anchors.add((round(x, 5), round(-game_z, 5), round(z, 5)))
    fruit_buds(anchors, geometry, height)


def fruit_buds(anchors, geometry, height):
    for point in sorted(anchors):
        anchor = Vector(point)
        r = max(.012, min(.032, height * .008))
        c = anchor - Vector((0, 0, r * 1.4))
        start = len(geometry.v)
        geometry.tube([anchor, c + Vector((0, 0, r))], [.0018, .0012], 0, 5)
        geometry.ellipsoid(c, (r * .68, r * .68, r), 1, 5, 8)
        mark_anchor(geometry, start, anchor)
