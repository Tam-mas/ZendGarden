"""Ten-plant art study: reference-led flower geometry, no scene side effects.

The public build() returns foliage, open flowers and closed flower buds. Early
stages have their own growth architecture, rather than scaled mature bouquets.
Coordinates are Z-up metres. The sample exporter preserves the catalogue's
final height and stores the flower attachment channels used by existing growth.
"""
import math
import random

from mathutils import Vector
from botanical_geometry import Geometry
from flower_additions_geometry import frame, petal_in_plane, funnel
from fruit_tree_geometry import mark_anchor

UP = Vector((0, 0, 1))
TAU = math.tau
IDS = (148, 149, 158, 174)


def _path(points, t):
    """Quadratic or cubic Bezier; author stem and leaf poses without modifiers."""
    p = [Vector(v) for v in points]
    while len(p) > 1:
        p = [a.lerp(b, t) for a, b in zip(p, p[1:])]
    return p[0]


def _stem(g, points, radius, mat=0, segments=7, sides=7):
    curve = [_path(points, i / segments) for i in range(segments + 1)]
    g.tube(curve, [radius * (1 - .70 * i / segments)
                   for i in range(segments + 1)], mat, sides)


def _leaf(g, points, width, mat=1, *, segments=10, blunt=False,
          fold=.14, twist=.08, lobed=False):
    """A curved, folded blade. UVs follow the tissue from base to tip."""
    points = [Vector(p) for p in points]
    direction = points[-1] - points[0]
    sideways = direction.cross(UP).normalized()
    if sideways.length < .001:
        sideways = Vector((1, 0, 0))
    start = len(g.v)
    for row in range(segments + 1):
        t = row / segments
        # Blunt strap leaves keep most of their width before the rounded tip.
        profile = math.sin(math.pi * t) ** (.38 if blunt else .80)
        if lobed:
            profile *= .75 + .25 * math.cos(6 * math.pi * t)
        w = width * profile
        centre = _path(points, t)
        for col in range(5):
            q = col * .5 - 1
            ridge = (1 - abs(q)) * w * fold
            curl = q * w * math.sin(t * math.pi) * twist
            point = centre + sideways * (q * w) + UP * (ridge + curl)
            g.v.append(tuple(point))
            g.uv[len(g.v) - 1] = (col / 4, t)
    for row in range(segments):
        for col in range(4):
            a = start + row * 5 + col
            g.face((a, a + 5, a + 6, a + 1), mat)


def _local_ellipsoid(g, centre, scale, basis, mat, rings=8, sides=12):
    """Orient a closed organ in the flower's plane, with continuous tissue UVs."""
    centre = Vector(centre)
    u, v, n = basis
    start = len(g.v)
    for row in range(rings + 1):
        theta = math.pi * row / rings
        for col in range(sides):
            angle = TAU * col / sides
            p = centre + u * (math.sin(theta) * math.cos(angle) * scale[0])
            p += v * (math.cos(theta) * scale[1])
            p += n * (math.sin(theta) * math.sin(angle) * scale[2])
            g.v.append(tuple(p))
            g.uv[len(g.v) - 1] = (col / sides, row / rings)
    for row in range(rings):
        for col in range(sides):
            a = start + row * sides + col
            b = start + row * sides + (col + 1) % sides
            g.face((a, a + sides, b + sides, b), mat)


def _bud(g, attachment, direction, length, width, mat=3):
    attachment = Vector(attachment)
    u, v, n = frame(direction)
    # The ellipsoid's long axis is its second basis vector.
    basis = (u, n, -v)
    first = len(g.v)
    _local_ellipsoid(g, attachment + n * length * .43,
                     (width, length * .48, width * .83), basis, mat, 7, 10)
    mark_anchor(g, first, attachment)


def _orchid_roots(g, base, scale, rng, count=5):
    base = Vector(base)
    for k in range(count):
        a = k * 2.39996 + rng.uniform(-.30, .30)
        outward = Vector((math.cos(a), math.sin(a), 0))
        end = base + outward * scale * rng.uniform(.7, 1.3)
        end.z = .003
        _stem(g, [base + UP * .018, base + outward * scale * .55 + UP * .025,
                  end], scale * .08, 3, 5, 6)
        g.tube([end - outward * scale * .10, end],
               [scale * .025, scale * .012], 2, 5)


def _cattleya_flower(g, c, axis, size):
    """Three narrow sepals, two ruffled petals and a rolled, flared labellum."""
    c = Vector(c)
    u, v, n = frame(axis)
    first = len(g.v)
    for a in (math.pi / 2, 7 * math.pi / 6, 11 * math.pi / 6):
        d = u * math.cos(a) + v * math.sin(a)
        petal_in_plane(g, c - n * size * .07, d, n, size, size * .24,
                       0, .19, .08)
    for sign in (-1, 1):
        d = u * sign + v * .24
        petal_in_plane(g, c, d, n, size * 1.04, size * .48,
                       0, .16, .27)
    # Rolled side lobes surround the column, opening to a broad frilled skirt.
    lip = c - v * size * .15 + n * size * .05
    lip_axis = (n - v * .48).normalized()
    funnel(g, lip, lip_axis, size * .46, size * .48,
           5, 7, .82, .20, .20)
    mouth = lip + lip_axis * size * .45
    petal_in_plane(g, mouth, -v + n * .30, n, size * .58,
                   size * .44, 5, .28, .30)
    for sign in (-1, 1):
        petal_in_plane(g, lip + n * size * .08,
                       u * sign * .6 - v * .15 + n * .6,
                       n, size * .43, size * .16, 1, .20, .05)
    petal_in_plane(g, lip + n * size * .025,
                   lip_axis - v * .12, v, size * .37, size * .125,
                   2, .20, .02)
    _local_ellipsoid(g, c + n * size * .18,
                     (size * .075, size * .15, size * .08),
                     (u, v, n), 1, 6, 10)
    mark_anchor(g, first, c)


def _cattleya(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    rng = random.Random(148061)
    mature = phase == 'mature'
    scale = 1 if mature else .60 if phase == 'juvenile' else .30
    count = 5 if mature else 3 if phase == 'juvenile' else 1
    for k in range(count):
        angle = k * 2.39996 + .2
        out = Vector((math.cos(angle), math.sin(angle), 0))
        base = out * (.037 * scale * (k / max(count - 1, 1)))
        h = (.17 + .016 * k) * scale
        top = base + out * .022 * scale + UP * h
        # Upright elongated club pseudobulbs, one firm leaf on each.
        points = [base + UP * .007 * scale, base + UP * h * .35,
                  top - UP * h * .22, top]
        g.tube(points, [r * scale for r in (.009, .017, .014, .006)], 1, 10)
        for side in (-1, 1):
            sheath = base + Vector((side * .006 * scale, 0, .005 * scale))
            _leaf(g, [sheath, sheath + UP * h * .35,
                      top - UP * h * .24], .010 * scale, 2,
                  segments=6, fold=.10)
        leaf_out = out + Vector((.10, -.18, 0))
        _leaf(g, [top, top + UP * .16 * scale + leaf_out * .025 * scale,
                  top + UP * .12 * scale + leaf_out * .115 * scale],
              .028 * scale, 2 if k == count - 1 else 1,
              segments=12, blunt=True, fold=.17, twist=.12)
        _orchid_roots(g, base, .053 * scale, rng, 4 if mature else 3)
        if not mature or k not in (2, 4):
            continue
        # Flowers grow from a sheath at the apex of a new pseudobulb.
        spike_top = top + out * .027 + UP * (.16 + .010 * (k == 4))
        _stem(g, [top, top + UP * .090, spike_top], .0040, segments=7)
        _leaf(g, [top, top + out * .020 + UP * .048,
                  top + UP * .105], .012, 2, segments=8, fold=.30)
        for j in range(2):
            turn = angle + (.72 if j == 0 else -.82)
            facing = Vector((math.cos(turn), math.sin(turn), .06 + j * .08))
            attach = spike_top - UP * (.043 * j)
            centre = attach + facing * .031 + UP * .016
            _stem(g, [attach, (attach + centre) * .5 + UP * .008, centre],
                  .0023, segments=4, sides=6)
            radius = .078 if j == 0 else .072
            _cattleya_flower(b, centre, facing, radius)
            _bud(buds, centre, facing + UP * .15, radius * .84, radius * .19)
    return g, b, buds


def _slipper_flower(g, c, axis, size):
    """Paphiopedilum insigne: tall hood, undulate arms, open inflated pouch."""
    c = Vector(c)
    u, v, n = frame(axis)
    first = len(g.v)
    # The white-edged dorsal sepal is a single gridded surface; the inner face
    # changes material, so its margin cannot detach or z-fight at a distance.
    start = len(g.v)
    rows, cols = 12, 9
    for row in range(rows + 1):
        t = row / rows
        w = size * .55 * math.sin(math.pi * t) ** .60
        for col in range(cols):
            q = 2 * col / (cols - 1) - 1
            p = c + v * (size * 1.21 * t) + u * (w * q)
            p += n * (size * (.04 + .20 * t * t - .16 * q * q))
            g.v.append(tuple(p)); g.uv[len(g.v) - 1] = ((q + 1) / 2, t)
    for row in range(rows):
        for col in range(cols - 1):
            a = start + row * cols + col
            white_edge = col in (0, cols - 2) or row >= rows - 2
            g.face((a, a + cols, a + cols + 1, a + 1), 1 if white_edge else 4)
    # Hidden paired lower sepals form a synsepal behind the pouch.
    petal_in_plane(g, c - n * size * .12, -v, n, size * .86,
                   size * .32, 4, .18, .025)
    for sign in (-1, 1):
        petal_in_plane(g, c + u * sign * size * .10,
                       u * sign - v * .17 + n * .05, n,
                       size * 1.14, size * .19, 0, .21, .18)
    # Open upper rim followed by the rounded, hanging bag. The bottom closes
    # at the final ring; no opaque sphere seals the visible mouth.
    start = len(g.v)
    rings, sides = 13, 24
    lip = c - v * size * .13 + n * size * .23
    for row in range(rings + 1):
        t = row / rings
        width = size * (.34 + .16 * math.sin(math.pi * t)) * (1 - t ** 5)
        depth = width * .62
        for col in range(sides):
            a = TAU * col / sides
            p = lip - v * size * .85 * t + n * size * .13 * math.sin(math.pi * t)
            p += u * math.cos(a) * width + n * math.sin(a) * depth
            g.v.append(tuple(p)); g.uv[len(g.v) - 1] = (col / sides, t)
    for row in range(rings):
        for col in range(sides):
            a = start + row * sides + col
            nxt = start + row * sides + (col + 1) % sides
            g.face((a, a + sides, nxt + sides, nxt), 5)
    rim = [Vector(g.v[start + k]) for k in range(sides)]
    rim.append(rim[0])
    g.tube(rim, [size * .022] * len(rim), 0, 5)
    _local_ellipsoid(g, c + n * size * .30 - v * size * .06,
                     (size * .17, size * .13, size * .055),
                     (u, v, n), 2, 6, 10)
    mark_anchor(g, first, c)


def _slipper(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    mature = phase == 'mature'
    scale = 1 if mature else .62 if phase == 'juvenile' else .32
    fans = 2 if mature else 1
    for fan in range(fans):
        # Neighbouring fans share the rhizome's general leaf plane, preserving
        # this small species' broad but shallow planting envelope.
        angle = .18 + fan * .20
        axis = Vector((math.cos(angle), math.sin(angle), 0))
        across = Vector((-axis.y, axis.x, 0))
        base = across * (.022 if fan else -.014) * scale
        leaves = 6 if mature else 5 if phase == 'juvenile' else 3
        for k in range(leaves):
            sign = -1 if k % 2 else 1
            length = (.17 - .017 * (k // 2)) * scale
            out = axis * sign + across * ((k % 3 - 1) * .10)
            start = base + UP * (.007 + k * .004) * scale
            _leaf(g, [start, start + UP * length * .64 + out * length * .36,
                      start + out * length * .93 + UP * length * .18],
                  (.018 - k * .0007) * scale, 2 if k > leaves - 3 else 1,
                  segments=11, blunt=True, fold=.22, twist=sign * .08)
        if mature:
            tip = base + across * .020 + UP * (.235 - fan * .024)
            _stem(g, [base + UP * .014, base - across * .011 + UP * .15, tip],
                  .0032, segments=10, sides=8)
            _leaf(g, [tip - UP * .024, tip + across * .012 - UP * .012,
                      tip + UP * .014], .009, 2, segments=7, fold=.20)
            facing = Vector((-.26 + fan * .82, -.94 + fan * .12, .08))
            centre = tip + facing * .012
            _stem(g, [tip, centre], .0020, segments=2, sides=6)
            _slipper_flower(b, centre, facing, .047)
            _bud(buds, centre, facing + UP * .45, .043, .015)
    return g, b, buds


def _cornflower_floret(g, base, axis, radius, length, mat, lobes=5, segments=4):
    """Fringed tubular floret, using large readable folds instead of hair meshes."""
    base = Vector(base)
    u, v, n = frame(axis)
    rows, sides = segments, lobes * 2
    start = len(g.v)
    for row in range(rows + 1):
        t = row / rows
        for col in range(sides):
            a = TAU * col / sides
            tip = 1.0 if col % 2 == 0 else .56
            reach = length * t * (1 - (1 - tip) * t ** 6)
            rad = radius * (.16 + .84 * t * t)
            p = base + n * reach + (u * math.cos(a) + v * math.sin(a)) * rad
            g.v.append(tuple(p)); g.uv[len(g.v) - 1] = (col / sides, t)
    for row in range(rows):
        for col in range(sides):
            a = start + row * sides + col
            nxt = start + row * sides + (col + 1) % sides
            g.face((a, nxt, nxt + sides, a + sides), mat)


def _cornflower_head(g, buds, c, axis, radius):
    c = Vector(c)
    u, v, n = frame(axis)
    first = len(g.v)
    bud_first = len(buds.v)
    # The involucre's overlapping bracts remain visible under the blue florets.
    for target in (g, buds):
        _local_ellipsoid(target, c - n * radius * .24,
                         (radius * .38, radius * .42, radius * .38),
                         (u, n, -v), 3, 5, 10)
        for ring in range(2):
            for k in range(9):
                angle = (k + ring * .5) * TAU / 9
                out = u * math.cos(angle) + v * math.sin(angle)
                p = c - n * radius * (.57 - ring * .16) + out * radius * .22
                petal_in_plane(target, p, out * .35 + n, out,
                               radius * .47, radius * .12,
                               4, .12, .05, tiny=True)
    for k in range(13):
        a = (k + .15) * TAU / 13
        out = u * math.cos(a) + v * math.sin(a)
        _cornflower_floret(g, c + out * radius * .28,
                          n * .67 + out * .88, radius * .17,
                          radius * .85, 0)
    for k in range(14):
        a = k * 2.39996
        distance = radius * .30 * math.sqrt((k + .5) / 14)
        place = c + (u * math.cos(a) + v * math.sin(a)) * distance
        _cornflower_floret(g, place, n, radius * .082,
                          radius * (.48 + .08 * math.cos(a)), 6, segments=2)
    _local_ellipsoid(buds, c + n * radius * .11,
                     (radius * .29, radius * .48, radius * .29),
                     (u, n, -v), 3, 6, 10)
    mark_anchor(g, first, c)
    mark_anchor(buds, bud_first, c)


def _cornflower(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    mature = phase == 'mature'
    rng = random.Random(158061)
    # Basal leaves are broader and lightly lobed; stem leaves become narrower.
    scale = 1 if mature else .70 if phase == 'juvenile' else .30
    for k in range(7 if mature else 6 if phase == 'juvenile' else 4):
        a = k * 2.39996
        d = Vector((math.cos(a), math.sin(a), 0))
        length = rng.uniform(.085, .12) * scale
        start = d * .006 + UP * .006
        _leaf(g, [start, start + d * length * .45 + UP * length * .8,
                  start + d * length + UP * length * .16],
              length * .13, 1, segments=9, lobed=True)
    if phase == 'seedling':
        return g, b, buds
    stems = 3 if mature else 2
    for k in range(stems):
        a = k * 2.12 + .25
        outward = Vector((math.cos(a), math.sin(a), 0))
        side = Vector((-outward.y, outward.x, 0))
        height = (.71 - k * .061) if mature else (.29 - k * .035)
        base = outward * .012
        tip = outward * (.065 + .018 * k) + side * .014 + UP * height
        points = [base, -outward * .040 + UP * height * .36,
                  tip - outward * .036 - UP * height * .19, tip]
        _stem(g, points, .0031 if mature else .0024, segments=11)
        for node in range(7 if mature else 5):
            t = .12 + node * .115
            p = _path(points, t)
            angle = a + node * 2.39996
            leaf_dir = Vector((math.cos(angle), math.sin(angle), .30))
            length = (.108 - node * .009) * (1 if mature else .75)
            _leaf(g, [p, p + leaf_dir * length * .44 + UP * length * .22,
                      p + leaf_dir * length],
                  length * (.075 if node > 2 else .12),
                  2 if node > 4 else 1, segments=7, twist=.12,
                  lobed=node < 2)
        if not mature:
            continue
        heads = [(tip, (outward * .22 + UP).normalized(), .024)]
        for branch in range(2):
            t = .46 + branch * .22
            attach = _path(points, t)
            sign = -1 if branch % 2 else 1
            end = tip + side * sign * (.085 + k * .012)
            end += outward * .021 - UP * (.068 + branch * .062)
            curve = [attach, attach + side * sign * .10 + UP * .030,
                     end - UP * .12, end]
            _stem(g, curve, .0020, segments=8, sides=6)
            for j in range(2):
                p = _path(curve, .27 + j * .32)
                direction = side * sign + outward * (j * .6 - .3)
                _leaf(g, [p, p + direction * .026 + UP * .020,
                          p + direction * .058 + UP * .026],
                      .0055, 1, segments=6)
            heads.append((end, (UP + side * sign * .28).normalized(), .0225))
        for point, normal, radius in heads:
            _cornflower_head(b, buds, point, normal, radius)
    return g, b, buds


def _snowdrop_flower(g, c, down, radius, turn):
    c = Vector(c)
    u, v, n = frame(down)
    first = len(g.v)
    _local_ellipsoid(g, c, (radius * .20, radius * .24, radius * .20),
                     (u, n, -v), 3, 6, 10)
    throat = c + n * radius * .19
    # Three long, bowed outer tepals hang around three short inner segments.
    for k in range(3):
        a = turn + k * TAU / 3
        outward = u * math.cos(a) + v * math.sin(a)
        start = len(g.v)
        rows, cols = 10, 5
        for row in range(rows + 1):
            t = row / rows
            width = radius * .26 * math.sin(math.pi * t) ** .52
            centre = throat + n * radius * 1.12 * t
            centre += outward * radius * (.18 * math.sin(math.pi * t) + .67 * t ** 2)
            sideways = n.cross(outward)
            for col in range(cols):
                q = col * .5 - 1
                p = centre + sideways * width * q - outward * width * .20 * q * q
                g.v.append(tuple(p)); g.uv[len(g.v) - 1] = (col / 4, t)
        for row in range(rows):
            for col in range(cols - 1):
                a0 = start + row * cols + col
                g.face((a0, a0 + cols, a0 + cols + 1, a0 + 1), 1)
    for k in range(3):
        angle = turn + math.pi / 3 + k * TAU / 3
        outward = u * math.cos(angle) + v * math.sin(angle)
        sideways = n.cross(outward)
        start = len(g.v)
        rows, cols = 7, 5
        for row in range(rows + 1):
            t = row / rows
            width = radius * .15 * math.sin(math.pi * t) ** .28
            for col in range(cols):
                q = col * .5 - 1
                notch = .06 * (1 - abs(q)) ** 2 * t ** 12
                p = throat + n * radius * (.64 * t - notch)
                p += outward * radius * (.15 + .02 * t) + sideways * q * width
                g.v.append(tuple(p)); g.uv[len(g.v) - 1] = (col / 4, t)
        for row in range(rows):
            for col in range(cols - 1):
                a0 = start + row * cols + col
                # The arched green mark sits just above the notched inner tip.
                green = row in ((4, 5) if col in (1, 2) else (3, 4))
                g.face((a0, a0 + cols, a0 + cols + 1, a0 + 1), 3 if green else 1)
    mark_anchor(g, first, c)


def _snowdrop(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    mature = phase == 'mature'
    scale = 1 if mature else .67 if phase == 'juvenile' else .36
    bulbs = 5 if mature else 3 if phase == 'juvenile' else 1
    for k in range(bulbs):
        a = k * 2.39996 + .30
        outward = Vector((math.cos(a), math.sin(a), 0))
        side = Vector((-outward.y, outward.x, 0))
        base = outward * (.006 + k * .0028) * scale
        for sign in (-1, 1):
            length = (.125 + .014 * ((k + sign) % 3)) * scale
            direction = side * sign + outward * .24
            _leaf(g, [base + side * sign * .0015,
                      base + direction * length * .13 + UP * length * .79,
                      base + direction * length * .28 + UP * length * .82],
                  .0043 * scale, 2 if phase == 'seedling' else 1,
                  segments=10, blunt=True, fold=.08, twist=.03)
        if not mature:
            continue
        height = .17 - .011 * (k % 3)
        top = base + UP * height + outward * .007
        end = top + outward * .014 - UP * .018
        # Leafless scape, papery spathe, and recurved pedicel form the hanging neck.
        _stem(g, [base, base - outward * .012 + UP * height * .62, top],
              .0016, segments=8, sides=7)
        _stem(g, [top, top + outward * .020 + UP * .008, end],
              .0011, segments=7, sides=6)
        _leaf(g, [top - UP * .014, top + side * .006 + UP * .005,
                  top + outward * .024 + UP * .007],
              .0031, 2, segments=7, fold=.13)
        down = Vector((outward.x * .20, outward.y * .20, -1))
        _snowdrop_flower(b, end, down, .023, a)
        _bud(buds, end, down, .028, .0055, 1)
    return g, b, buds


def build(idx, phase='mature'):
    """Build one sampled species; use the existing shared seven-slot bloom palette."""
    if phase not in ('seedling', 'juvenile', 'mature'):
        raise ValueError('Unknown growth phase: ' + str(phase))
    builders = {148: _cattleya, 149: _slipper, 158: _cornflower, 174: _snowdrop}
    if idx not in builders:
        raise ValueError('Not a sampled flower: ' + str(idx))
    result = builders[idx](phase)
    for mesh in result:
        assert all(0 <= vertex < len(mesh.v) for face in mesh.f for vertex in face)
        assert all(math.isfinite(component) for vertex in mesh.v for component in vertex)
    if phase == 'mature':
        for mesh in result[1:]:
            assert len(mesh.fruit_anchors) == len(mesh.v), (idx, 'missing flower attachment')
    return result
