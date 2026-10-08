"""Cascading Hakonechloa and thick-leaved Echeveria, in garden metres.

References: RHS Hakonechloa macra 'Aureola' and Echeveria elegans profiles,
recorded alongside the sample's texture provenance. No scene/file side effects.
"""
import math
import random
from mathutils import Vector
from botanical_geometry import Geometry
from flower_additions_geometry import funnel
from fruit_tree_geometry import mark_anchor

TAU = math.tau
UP = Vector((0, 0, 1))


def blade(g, base, heading, length, width, rise, drop, mat):
    """A continuous folded ribbon with a drooping tip; no crossed alpha planes."""
    base = Vector(base)
    direction = Vector((math.cos(heading), math.sin(heading), 0))
    side = Vector((-direction.y, direction.x, 0))
    rows = []
    for j in range(11):
        t = j / 10
        c = base + direction * length * t + UP * (rise * math.sin(t * math.pi * .85) - drop * t * t)
        w = width * math.sin(math.pi * t) ** .72
        row = []
        for k in range(3):
            q = k - 1
            p = c + side * w * q + UP * (-abs(q) * w * .22 + q * w * .10 * t)
            row.append(len(g.v)); g.v.append(tuple(p)); g.uv[len(g.v)-1] = (k / 2, t)
        rows.append(row)
    for a, b in zip(rows, rows[1:]):
        for k in range(2):g.face((a[k], b[k], b[k+1], a[k+1]), mat)


def forest_grass(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    rng = random.Random(10973)
    scale, count = {'mature': (1.0, 28), 'juvenile': (.46, 9), 'seedling': (.19, 3)}[phase]
    for j in range(count):
        angle = j * 2.399963 + .18 * math.sin(j)
        # Culms lean out from separate crown nodes rather than a single pinched point.
        r = (.025 + .105 * math.sqrt((j+.5)/count)) * scale
        d = Vector((math.cos(angle), math.sin(angle), 0))
        base = d * r
        h = (.26 + rng.random() * .16) * scale
        reach = (.11 + rng.random() * .11) * scale
        points = [base + d * reach * (t/6)**1.65 + UP * (h * math.sin(t/6*math.pi*.55)) for t in range(7)]
        g.tube(points, [.0032*scale*(1-t/8) for t in range(7)], 0, 4)
        for k in range(1, 6):
            base_leaf = points[k]
            heading = angle + (.50 if k % 2 else -.72) + rng.uniform(-.16, .16)
            length = (.21 + rng.random()*.10) * scale * (1-.075*k)
            blade(g, base_leaf, heading, length, .0125*scale*(1-k*.035), .055*scale, (.085+.01*k)*scale, 1 if (j+k)%4 else 2)
        if phase == 'mature' and j % 5 == 0:
            anchor = points[-1]; start = len(b.v)
            tip = anchor + d*.05 + UP*.07
            b.tube([anchor, tip], [.0015, .0005], 3, 3)
            for k in range(4):
                p = anchor.lerp(tip, (k+.5)/4)
                q = p + Vector((math.cos(angle+k*2.4)*.026, math.sin(angle+k*2.4)*.026, .018))
                b.tube([p, q], [.0006, .0003], 3, 3)
                b.ellipsoid(q, (.0028, .0028, .009), 2, 3, 5)
            mark_anchor(b, start, anchor)
            start = len(buds.v); buds.ellipsoid(anchor, (.0035, .0035, .016), 3, 4, 6); mark_anchor(buds, start, anchor)
    return g, b, buds


def spoon(g, center, angle, length, width, rise, mat):
    """Closed, succulent spoon leaf: broad rounded end, narrow heel, convex flesh."""
    center = Vector(center)
    direction = Vector((math.cos(angle), math.sin(angle), 0))
    side = Vector((-direction.y, direction.x, 0))
    start = len(g.v); rings = 10; sides = 10
    for j in range(rings+1):
        t = j/rings
        profile = math.sin(math.pi*t) ** .52 * (.36 + .92*t)
        p = center + direction * length*t + UP * (rise*t + length*.15*math.sin(math.pi*t))
        for k in range(sides):
            a = TAU*k/sides
            thick = width*.32*math.sin(math.pi*t)**.7
            v = p + side * (math.cos(a)*width*profile) + UP * (math.sin(a)*thick)
            g.v.append(tuple(v)); g.uv[len(g.v)-1] = ((math.cos(a)+1)/2, t)
    for j in range(rings):
        for k in range(sides):
            a = start+j*sides+k; c = start+j*sides+(k+1)%sides
            g.face((a,c,c+sides,a+sides),mat)


def rosette(g, center, radius, age=1):
    rings = [(11, 1.0, .18), (9, .80, .52), (7, .56, .90), (5, .34, 1.18)] if age > .4 else [(7,.8,.45),(5,.5,.85)]
    for ring, (count, extent, lift) in enumerate(rings):
        for k in range(count):
            a = TAU*k/count + ring*.58
            p = Vector(center) + UP*radius*ring*.12
            spoon(g,p,a,radius*extent,radius*extent*.35,radius*extent*lift,2 if ring==len(rings)-1 else 1)


def snowball(phase):
    g, b, buds = Geometry(), Geometry(), Geometry()
    scale = {'mature':1.0,'juvenile':.52,'seedling':.24}[phase]
    rosette(g,(0,0,.02*scale),.175*scale,scale)
    if phase=='mature':
        for j,a in enumerate([.7,2.7,4.65]):
            c=Vector((math.cos(a)*.185,math.sin(a)*.185,.016))
            rosette(g,c,.064+j*.005,.6)
        for j,a in enumerate([.35,2.55]):
            d=Vector((math.cos(a),math.sin(a),0));base=d*.067+UP*.026
            points=[base+d*(.06*t+.07*t*t)+UP*(.30*math.sin(t*math.pi*.52)) for t in [0,.2,.4,.6,.8,1]]
            g.tube(points,[.0034,.0032,.0028,.0024,.0019,.0013],0,6)
            for k in [1,2,3]:spoon(g,points[k],a+1.4,.023,.007,.015,2)
            for k in range(5):
                anchor=points[3].lerp(points[-1],k/4)
                c=anchor+d*(.024+.005*k)-UP*.016
                g.tube([anchor,c],[.0017,.0008],0,4)
                start=len(b.v)
                # Corollas remain pendant with five small yellow terminal lobes.
                funnel(b,c,(0,0,-1),.007,.022,0,5,.25,.03,.44)
                funnel(b,c-UP*.019,(0,0,-1),.0073,.004,1,5,.18,.04,.80)
                mark_anchor(b,start,c)
                start=len(buds.v);buds.ellipsoid(c-UP*.009,(.004,.004,.012),0,5,8);mark_anchor(buds,start,c)
    return g,b,buds


def build(idx,phase='mature'):
    return forest_grass(phase) if idx==109 else snowball(phase)
