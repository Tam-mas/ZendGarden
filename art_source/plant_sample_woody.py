"""Reference-led sample meshes for four woody plants, with no Blender side effects.

All dimensions are relative to each species' mature height. The sample exporter
normalizes every stage with one scale, retaining existing saved plant sizes.
Flowers and matching buds carry their own attachment anchors. Material indices
follow build_plant_art_sample's shared palettes; no runtime shader is changed.
"""
import math
import random
from mathutils import Vector
from botanical_geometry import Geometry
from fruit_tree_geometry import mark_anchor

UP = Vector((0, 0, 1))
TAU = math.tau
IDS = (20, 30, 198, 212)


def point(path, t):
    q = max(0, min(.999999, t)) * (len(path) - 1)
    i = int(q)
    return Vector(path[i]).lerp(Vector(path[i + 1]), q - i)


def direction(angle, lift=0):
    return Vector((math.cos(angle), math.sin(angle), lift)).normalized()


def frame(axis):
    n = Vector(axis).normalized()
    u = n.cross(UP).normalized() if abs(n.z) < .92 else Vector((1, 0, 0))
    return u, n.cross(u).normalized(), n


def blade(g, base, heading, length, half_width, mat=1, tilt=.15,
          teeth=.06, rows=8, fold=.18):
    """A keeled, gently curled leaf with an actual serrated blade outline."""
    base = Vector(base)
    d = direction(heading, tilt)
    side = d.cross(UP).normalized()
    normal = side.cross(d).normalized()
    if normal.z < 0:
        normal = -normal
    first = len(g.v)
    for j in range(rows + 1):
        t = j / rows
        w = max(0, math.sin(math.pi * t)) ** .78 * half_width
        w *= 1 + (teeth if j % 2 else -teeth)
        mid = base + d * (length * t) + normal * length * (.11 * math.sin(math.pi * t) - .075 * t ** 3)
        for k in range(3):
            q = k - 1
            pos = mid + side * (q * w) - normal * (abs(q) * w * fold)
            g.v.append(tuple(pos))
            g.uv[len(g.v) - 1] = (k / 2, t)
    for j in range(rows):
        a = first + j * 3
        g.face((a, a + 3, a + 4, a + 1), mat)
        g.face((a + 1, a + 4, a + 5, a + 2), mat)


def petal(g, center, radial, normal, length, width, mat=0, cup=.20,
          ruffle=.045, rows=8, cols=5):
    """Overlapping, cupped petal surface with tissue-aligned UVs."""
    c = Vector(center)
    d = Vector(radial).normalized()
    n = Vector(normal).normalized()
    s = n.cross(d).normalized()
    n = d.cross(s).normalized()
    first = len(g.v)
    for j in range(rows + 1):
        t = j / rows
        w = max(0, math.sin(math.pi * t)) ** .50 * width
        for k in range(cols):
            q = k / (cols - 1) * 2 - 1
            bend = length * cup * t * t - .17 * w * q * q
            bend += ruffle * width * abs(q) ** 3 * math.sin(t * 22 + q * 9)
            pos = c + d * (length * t) + s * (w * q) + n * bend
            g.v.append(tuple(pos))
            g.uv[len(g.v) - 1] = ((q + 1) / 2, t)
    for j in range(rows):
        for k in range(cols - 1):
            a = first + j * cols + k
            g.face((a, a + cols, a + cols + 1, a + 1), mat)


def rose_leaf(g, attach, angle, length, young=False, early=False):
    """Five leaflets on one pinnate rachis, rather than a five-blade fan."""
    attach = Vector(attach)
    d = direction(angle, .17)
    end = attach + d * length
    g.tube([attach, attach.lerp(end, .5) + UP * length * .04, end],
           [length * .014, length * .009, length * .003], 0, 4)
    mat = 2 if young else 1
    for j, t in enumerate((.31, .61)):
        base = attach.lerp(end, t)
        for sign in (-1, 1):
            turn = angle + sign * (1.14 - j * .17)
            leaf_len = length * (.48 if j else .39)
            petiole = base + direction(turn, .12) * length * .065
            g.tube([base, petiole], [length * .005, length * .0025], 0, 3)
            blade(g, petiole, turn, leaf_len, leaf_len * .34,
                  mat, .22, .085, 6 if early else 10)
    blade(g, end - d * length * .045, angle, length * .51,
          length * .18, mat, .21, .085, 6 if early else 10)


def rose_bloom(b, buds, anchor, axis, radius, seed):
    rng = random.Random(seed)
    u, v, n = frame(axis)
    anchor = Vector(anchor)
    c = anchor + n * radius * .23
    start = len(b.v)
    b.tube([anchor, c], [radius * .10, radius * .08], 3, 6)
    b.ellipsoid(c - n * radius * .12, (radius * .16,) * 3, 3, 4, 8)
    for k in range(5):
        a = k * TAU / 5
        d = u * math.cos(a) + v * math.sin(a)
        petal(b, c - n * radius * .05, d - n * .20, n,
              radius * .56, radius * .075, 4, -.12, 0, 4, 3)
    # Concentric staggered whorls close into a tall spiral heart.
    for ring, (count, scale, rise, cup) in enumerate(((8, 1, -.04, .30),
                                                    (7, .80, .05, .40),
                                                    (6, .59, .15, .61),
                                                    (5, .36, .25, .86))):
        for k in range(count):
            a = k * TAU / count + ring * .83 + rng.uniform(-.065, .065)
            d = u * math.cos(a) + v * math.sin(a)
            center = c + n * (radius * rise) + d * radius * .025
            petal(b, center, d, n, radius * scale,
                  radius * scale * .61, 6 if ring == 0 and k % 3 == 0 else 0,
                  cup, .06, 8, 5)
    mark_anchor(b, start, anchor)
    start = len(buds.v)
    buds.tube([anchor, c], [radius * .075, radius * .045], 3, 5)
    # A closed teardrop and green clasping sepals at precisely the flower site.
    buds.ellipsoid(c + n * radius * .22,
                   (radius * .19, radius * .19, radius * .36), 0, 5, 8)
    for k in range(5):
        a = k * TAU / 5
        d = u * math.cos(a) + v * math.sin(a)
        petal(buds, c - n * radius * .03, n + d * .35, d,
              radius * .47, radius * .09, 3, .1, 0, 4, 3)
    mark_anchor(buds, start, anchor)


def rose(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    rng = random.Random(208814 + {'mature': 0, 'seedling': 1, 'juvenile': 2}[phase])
    if phase == 'seedling':
        path = [Vector((0, 0, 0)), Vector((.012, 0, .065)), Vector((.007, .005, .18))]
        g.tube(path, [.008, .006, .002], 0, 5)
        # Seedling cotyledons precede the first compound leaves.
        for sign in (-1, 1):
            blade(g, path[1], sign * 1.45, .046, .019, 1, .1, 0, 5)
        for j in range(2):
            rose_leaf(g, point(path, .55 + j * .24), j * 2.4, .090 - j * .014, j == 1, True)
        return g, b, buds
    early = phase == 'juvenile'
    scale = .48 if early else 1
    tips = []
    for i in range(3 if early else 7):
        a = i * 2.39996 + rng.uniform(-.19, .19)
        d = direction(a)
        height = scale * (1 if i == 0 else rng.uniform(.72, .94))
        lean = scale * rng.uniform(.14, .29)
        base = d * scale * .026
        path = [base, base + d * lean * .22 + UP * height * .26,
                base + d * lean * .70 + UP * height * .59,
                base + d * lean + UP * height * .91]
        g.tube(path, [scale * .011, scale * .008, scale * .004, scale * .0018], 0, 7)
        for node in range(3 if early else 5):
            t = .25 + node * (.22 if early else .15)
            attach = point(path, t)
            turn = a + node * 2.4
            rose_leaf(g, attach, turn, scale * rng.uniform(.18, .23), node == 4, early)
            if not early and node % 2 == 0:
                thorn = attach + direction(a + 1.1) * scale * .021 - UP * .006
                g.tube([attach, thorn], [scale * .004, .0001], 0, 4)
        tips.append((path[-1], direction(a, .80)))
        for j in range(1 if early else 3):
            attach = point(path, .35 + j * .18)
            turn = a + (-.82 if j % 2 else .90)
            reach = scale * rng.uniform(.16, .23)
            end = attach + direction(turn) * reach + UP * scale * rng.uniform(.14, .24)
            shoot = [attach, attach.lerp(end, .58) + UP * scale * .03, end]
            g.tube(shoot, [scale * .004, scale * .0024, scale * .0007], 0, 5)
            for node in range(2 if early else 3):
                rose_leaf(g, point(shoot, .24 + node * .26), turn + (-1 if node % 2 else 1) * .95,
                          scale * rng.uniform(.16, .20), node == 2, early)
            if not early:
                tips.append((end, direction(turn, .65)))
    if not early:
        for j, (anchor, axis) in enumerate(tips):
            rose_bloom(b, buds, anchor, axis, rng.uniform(.064, .083), j + 812)
    return g, b, buds


def maple_leaf(g, attach, angle, length, mat=1, tilt=-.10):
    """A single connected seven-lobed palmate blade with deep sinuses."""
    attach = Vector(attach)
    f = direction(angle, tilt)
    side = f.cross(UP).normalized()
    normal = side.cross(f).normalized()
    if normal.z < 0:
        normal = -normal
    hub = attach + f * length * .31
    g.tube([attach, hub], [length * .012, length * .005], 0, 3)
    first = len(g.v)
    g.v.append(tuple(hub))
    g.uv[first] = (.5, .38)
    outline = []
    # Lobe lengths taper toward the petiole; all seven share the central lamina.
    for degrees, power in ((-140, .48), (-94, .75), (-47, .94), (0, 1),
                           (47, .94), (94, .75), (140, .48)):
        for delta, extent in ((-20, .23), (-12, .60), (-8, .57), (0, 1),
                              (8, .57), (12, .60), (20, .23)):
            a = math.radians(degrees + delta)
            r = length * power * extent
            local_x, local_y = math.cos(a) * r, math.sin(a) * r
            fold = length * (.07 * extent - .075 * abs(math.sin(a)) * extent)
            p = hub + f * local_x + side * local_y + normal * fold
            outline.append(len(g.v)); g.v.append(tuple(p))
            g.uv[len(g.v) - 1] = (.5 + local_y / (length * 1.8), .38 + local_x / (length * 1.7))
    for k in range(len(outline)):
        g.face((first, outline[k], outline[(k + 1) % len(outline)]), mat)


def maple(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    rng = random.Random(307913 + {'mature': 0, 'seedling': 1, 'juvenile': 2}[phase])
    if phase == 'seedling':
        path = [Vector((0, 0, 0)), Vector((.006, 0, .08)), Vector((0, .007, .18))]
        g.tube(path, [.008, .005, .0018], 0, 6)
        for sign in (-1, 1):
            blade(g, path[1], sign * 1.4, .065, .010, 1, .15, 0, 4)
        for j in range(4):
            maple_leaf(g, point(path, .50 + (j // 2) * .27), j * math.pi + .8 * (j // 2), .040 + j * .004, 2 if j > 1 else 1, .12)
        return g, b, buds
    early = phase == 'juvenile'
    scale = .47 if early else 1
    trunk = [Vector((0, 0, 0)), Vector((-.024, .008, .18)) * scale,
             Vector((.012, -.013, .40)) * scale, Vector((-.017, .008, .70)) * scale,
             Vector((.025, .008, .93)) * scale]
    g.tube(trunk, [scale * .034, scale * .026, scale * .018, scale * .007, scale * .002], 0, 10)
    # A slightly irregular layered canopy with visible branch windows.
    tip_sites = []
    levels = 3 if early else 5
    for layer in range(levels):
        z = (.27 + layer * (.20 if early else .135))
        for arm in range(2 if early else 3):
            angle = layer * 1.42 + arm * TAU / (2 if early else 3) + rng.uniform(-.17, .17)
            base = point(trunk, z)
            reach = scale * ((.37 - layer * .065) if early else (.49 - layer * .067)) * rng.uniform(.92, 1.1)
            d = direction(angle)
            end = base + d * reach + UP * scale * (.18 - layer * .014)
            branch = [base, base + d * reach * .35 + UP * scale * .10,
                      base.lerp(end, .70) + UP * scale * .042, end]
            g.tube(branch, [scale * .011, scale * .007, scale * .0038, scale * .0012], 0, 7)
            for fork in range(2 if early else 5):
                root = point(branch, .26 + fork * (.34 if early else .16))
                turn = angle + (-1 if fork % 2 else 1) * rng.uniform(.49, 1.00)
                span = scale * rng.uniform(.13, .22) * (1 - layer * .045)
                end2 = root + direction(turn) * span + UP * scale * rng.uniform(.015, .063)
                shoot = [root, root.lerp(end2, .55) + UP * scale * .026, end2]
                g.tube(shoot, [scale * .0034, scale * .0015, scale * .00045], 0, 4)
                for node in range(2 if early else 5):
                    loc = point(shoot, .22 + node * (.60 if early else .18))
                    for side in (-1, 1):
                        heading = turn + side * (1.04 if node % 2 else 1.44)
                        leaf_len = scale * rng.uniform(.046, .069)
                        if node == (1 if early else 4):
                            leaf_len *= .83
                        maple_leaf(g, loc, heading, leaf_len,
                                   2 if node == 4 and rng.random() < .45 else 1,
                                   rng.uniform(-.28, .12))
                tip_sites.append(end2)
            # Foliage also on the branch tips, preventing bare skeletal spokes.
            for node in range(2 if early else 4):
                loc = point(branch, .58 + node * (.25 if early else .12))
                for side in (-1, 1):
                    maple_leaf(g, loc, angle + side * 1.15, scale * rng.uniform(.05, .075), 1, -.05)
    if not early:
        for j, anchor in enumerate(tip_sites):
            start = len(buds.v)
            # Maple's growth display is a small unfurling shoot, not a showy flower.
            for side in (-1, 1):
                blade(buds, anchor, j * 2.4 + side * .42, .023, .0055, 3, 1.1, .08, 4)
            mark_anchor(buds, start, anchor)
    return g, b, buds


def shrub_leaf(g, base, angle, length, idx, mat=1, early=False):
    d = direction(angle, .12)
    junction = Vector(base) + d * length * .13
    g.tube([base, junction], [length * .011, length * .005], 0, 3)
    blade(g, junction, angle, length, length * (.36 if idx == 198 else .26),
          mat, .10 if idx == 198 else -.04, .075,
          6 if early else 10 if idx == 198 else 8,
          .13 if idx == 198 else .24)


def hibiscus_bloom(b, buds, anchor, axis, r, seed):
    u, v, n = frame(axis)
    anchor = Vector(anchor)
    c = anchor + n * r * .22
    start = len(b.v)
    b.tube([anchor, c], [r * .053, r * .035], 3, 5)
    for k in range(5):
        a = k * TAU / 5 + seed * .37
        d = u * math.cos(a) + v * math.sin(a)
        petal(b, c - n * r * .08, d - n * .10, n, r * .37, r * .071, 4, .06, 0, 4, 3)
        # Wide overlapping petals form a real five-petal funnel with a raised rim.
        petal(b, c + n * r * .01, d, n, r, r * .72,
              0 if k != seed % 5 else 6, .25, .10, 8, 5)
    # Long staminal column with clustered anthers and a five-lobed stigma.
    column = [c, c + n * r * .56, c + n * r * 1.03]
    b.tube(column, [r * .060, r * .038, r * .024], 5, 7)
    for k in range(15):
        a = k * 2.4
        t = .41 + .39 * (k % 5) / 4
        origin = c + n * r * t
        tip = origin + (u * math.cos(a) + v * math.sin(a)) * r * .075
        b.tube([origin, tip], [r * .009, r * .005], 2, 3)
        b.ellipsoid(tip, (r * .023, r * .023, r * .019), 2, 2, 5)
    for k in range(5):
        a = k * TAU / 5
        tip = c + n * r * 1.12 + (u * math.cos(a) + v * math.sin(a)) * r * .065
        b.tube([column[-1], tip], [r * .011, r * .006], 5, 3)
        b.ellipsoid(tip, (r * .025,) * 3, 5, 2, 5)
    mark_anchor(b, start, anchor)
    start = len(buds.v)
    buds.tube([anchor, c], [r * .041, r * .025], 3, 4)
    for k in range(5):
        a = k * TAU / 5
        d = u * math.cos(a) + v * math.sin(a)
        petal(buds, c, n + d * .22, d, r * .61, r * .080, 3, .09, 0, 5, 3)
    mark_anchor(buds, start, anchor)


def fuchsia_bloom(b, buds, anchor, r, seed):
    anchor = Vector(anchor)
    angle = seed * 2.39996
    out = direction(angle)
    c = anchor + out * r * .23 - UP * r * .35
    n = Vector((.07 * math.cos(angle), .07 * math.sin(angle), -1)).normalized()
    u, v, _ = frame(n)
    start = len(b.v)
    # Fine bent pedicel, green ovary, then the conspicuous scarlet calyx tube.
    b.tube([anchor, anchor + out * r * .18 - UP * r * .12, c],
           [r * .028, r * .018, r * .014], 3, 4)
    b.ellipsoid(c, (r * .095, r * .095, r * .15), 3, 4, 6)
    lip = c + n * r * .65
    b.tube([c, c + n * r * .23, c + n * r * .48, lip],
           [r * .073, r * .105, r * .12, r * .17], 0, 10)
    for k in range(4):
        a = k * TAU / 4 + .2
        d = u * math.cos(a) + v * math.sin(a)
        # Four reflexed pointed sepals surround four short purple petals.
        petal(b, lip, d + n * .42, -n, r * .66, r * .11,
              0, .32, .01, 6, 3)
        petal(b, lip + d * r * .04, n + d * .27, d,
              r * .47, r * .23, 5, .15, .035, 6, 5)
    for k in range(8):
        a = k * TAU / 8
        d = u * math.cos(a) + v * math.sin(a)
        tip = lip + n * r * (.88 + .10 * (k % 2)) + d * r * .14
        b.tube([lip + d * r * .04, tip], [r * .010, r * .006], 1, 3)
        b.ellipsoid(tip, (r * .019, r * .019, r * .028), 2, 2, 4)
    b.tube([lip, lip + n * r * 1.11], [r * .014, r * .007], 1, 4)
    mark_anchor(b, start, anchor)
    start = len(buds.v)
    buds.tube([anchor, c, c + n * r * .46], [r * .027, r * .026, r * .017], 3, 4)
    buds.ellipsoid(c + n * r * .60, (r * .115, r * .115, r * .37), 0, 5, 8)
    mark_anchor(buds, start, anchor)


def fuchsia_pendant_site(g, sites, attach, heading, reach=.050, drop=.030):
    """Present the flower below an outer leaf axil on a fine arching stalk.

    The support is part of the woody framework so growth scales the corolla
    around its real attachment, without pulling a long pedicel off the shoot.
    """
    attach = Vector(attach)
    out = direction(heading)
    anchor = attach + out * reach - UP * drop
    g.tube([attach, attach + out * reach * .56 + UP * .004, anchor],
           [.00090, .00057, .00025], 0, 4)
    sites.append((anchor, direction(heading, -.6)))


def shrub(idx, phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    rng = random.Random(idx * 9011 + {'mature': 0, 'seedling': 7, 'juvenile': 18}[phase])
    if phase == 'seedling':
        path = [Vector((0, 0, 0)), Vector((.008, -.004, .09)), Vector((0, .008, .19))]
        g.tube(path, [.007, .004, .0014], 0, 5)
        for node in range(3):
            loc = point(path, .25 + node * .31)
            for sign in ((1,) if idx == 198 else (-1, 1)):
                shrub_leaf(g, loc, node * 2.4 + (math.pi if sign < 0 else 0),
                           .062 if idx == 198 else .046, idx, 2 if node == 2 else 1, True)
        return g, b, buds
    early = phase == 'juvenile'
    scale = .47 if early else 1
    canes = 3 if early else (6 if idx == 198 else 8)
    leaf_scale = .84 if idx == 212 and not early else 1.0
    tips = []
    for i in range(canes):
        angle = i * 2.39996 + rng.uniform(-.13, .13)
        d = direction(angle)
        amplitude = rng.uniform(.83, 1)
        reach = scale * ((.12 if idx == 198 else .46) + rng.uniform(0, .065))
        if idx == 198:
            path = [d * scale * .03, d * reach * .24 + UP * scale * .24,
                    d * reach * .72 + UP * scale * .61 * amplitude,
                    d * reach + UP * scale * .88 * amplitude]
        else:
            path = [d * scale * .025, d * reach * .16 + UP * scale * .35,
                    d * reach * .54 + UP * scale * .85 * amplitude,
                    d * reach + UP * scale * .70 * amplitude]
        g.tube(path, [scale * .010, scale * .0072, scale * .0038, scale * .0012], 0, 7)
        for node in range(3 if early else 6):
            loc = point(path, .23 + node * (.23 if early else .135))
            for side in ((1,) if idx == 198 else (-1, 1)):
                shrub_leaf(g, loc, angle + node * 2.4 + (math.pi if side < 0 else 0),
                           scale * (.135 if idx == 198 else .091) * leaf_scale * rng.uniform(.85, 1.12),
                           idx, 1, early)
        for j in range(2 if early else 4):
            root = point(path, .30 + j * (.33 if early else .17))
            turn = angle + (-.89 if j % 2 else .86) + rng.uniform(-.12, .12)
            span = scale * (.23 if idx == 198 else .20) * rng.uniform(.76, 1.15)
            end = root + direction(turn) * span + UP * scale * (.11 if idx == 198 else -.025)
            shoot = [root, root.lerp(end, .55) + UP * scale * .04, end]
            g.tube(shoot, [scale * .004, scale * .0022, scale * .00055], 0, 5)
            for node in range(3 if early else 5):
                loc = point(shoot, .15 + node * (.34 if early else .19))
                for side in ((1,) if idx == 198 else (-1, 1)):
                    shrub_leaf(g, loc, turn + node * 2.4 + (math.pi if side < 0 else 0),
                               scale * (.135 if idx == 198 else .090) * leaf_scale * rng.uniform(.83, 1.13),
                               idx, 2 if node == 4 and rng.random() < .25 else 1, early)
                if not early and idx == 212 and node in (3, 4):
                    # Alternating outer axils avoid the densely overlapping
                    # foliage at the base of each lateral shoot.
                    fuchsia_pendant_site(g, tips, loc,
                                         turn + (-.48 if node == 3 else .48),
                                         .053 if node == 3 else .061,
                                         .032 if node == 3 else .039)
            if not early:
                if idx == 198:
                    tips.append((end, direction(turn, .33)))
                else:
                    # A slender arching terminal continuation carries the
                    # final pendant into the open rim beneath the leaf tips.
                    fuchsia_pendant_site(g, tips, end, turn, .079, .047)
                # Leafy tertiary twigs fill the middle crown while leaving gaps.
                for fork in range(2):
                    origin = point(shoot, .38 + fork * .37)
                    heading = turn + (-1 if fork else 1) * .95
                    tip = origin + direction(heading) * scale * (.14 if idx == 198 else .13) + UP * scale * .032
                    twig = [origin, origin.lerp(tip, .6) + UP * scale * .014, tip]
                    g.tube(twig, [scale * .0017, scale * .0010, scale * .0003], 0, 4)
                    for node in range(3):
                        loc = point(twig, .19 + node * .35)
                        for side in ((1,) if idx == 198 else (-1, 1)):
                            shrub_leaf(g, loc, heading + node * 2.4 + (math.pi if side < 0 else 0),
                                       scale * (.112 if idx == 198 else .077) * leaf_scale * rng.uniform(.86, 1.12),
                                       idx, 2 if node == 2 and rng.random() < .20 else 1)
    if not early:
        for j, (anchor, axis) in enumerate(tips):
            if idx == 198:
                hibiscus_bloom(b, buds, anchor, axis, rng.uniform(.043, .055), j)
            else:
                fuchsia_bloom(b, buds, anchor, rng.uniform(.0150, .0174), j)
    return g, b, buds


def build(idx, phase='mature'):
    """Return separate foliage, bloom and matching bud Geometry objects."""
    if idx not in IDS:
        raise ValueError('Unsupported woody sample plant: %r' % idx)
    if phase not in ('mature', 'seedling', 'juvenile'):
        raise ValueError('Unknown growth phase: %r' % phase)
    if idx == 20:
        return rose(phase)
    if idx == 30:
        return maple(phase)
    return shrub(idx, phase)
