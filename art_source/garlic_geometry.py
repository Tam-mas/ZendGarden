"""Allium sativum: flat alternate leaves, pale sheaths and a papery ribbed bulb.

Pure geometry in metres, Z-up. The upper bulb is exposed for garden readability.
"""
import math
from mathutils import Vector
from botanical_geometry import Geometry
from plant_full_low import ribbon, ellipse
from fruit_tree_geometry import mark_anchor

ID=298
HEIGHT=.62


def palette(_idx):
    leaves=[('garlic leaf blue green','62865d','grass',True),
            ('garlic leaf sunlit','81a16a','grass',True),
            ('garlic pale sheath','bdc9a0','smooth',False)]
    bulb=[('garlic papery ivory','e9dfcb','smooth',False),
          ('garlic clove blush','c5a6b6','smooth',False),
          ('garlic root plate','b5a17f','smooth',False),
          ('garlic fine roots','d7c7a6','smooth',False)]
    return {'foliage':leaves,'bloom':bulb}


def foliage(stage='mature'):
    g=Geometry()
    factor,count={'seedling':(.18,2),'juvenile':(.48,5),'mature':(1.,9)}[stage]
    g.tube([(0,0,.018*factor),(0,0,.115*factor),(.004*factor,0,.26*factor)],
           [.014*factor,.011*factor,.004*factor],2,12)
    for i in range(count):
        a=i*2.399963+.25
        height=(.39+.17*math.sin((i+1)*.67)**2)*factor
        reach=(.23 if i<3 else .13)*factor
        base=Vector((math.cos(a)*.005*factor,math.sin(a)*.005*factor,(.045+i*.016)*factor))
        ribbon(g,base,a,height,reach,(.012 if i<4 else .009)*factor,mat=1 if i%3 else 0,steps=18)
        d=Vector((math.cos(a),math.sin(a),0))
        g.tube([base,base+Vector((0,0,height*.17)),base+d*reach*.10+Vector((0,0,height*.36))],
               [.0028*factor,.0020*factor,.0005*factor],2,6)
    return g


def bulb(size=1.):
    g=Geometry();rings,sides=18,64
    profile=[(0.,.014),(.06,.035),(.20,.064),(.38,.075),(.56,.072),(.73,.055),(.86,.027),(1.,.012)]
    def radius(t):
        for (ta,ra),(tb,rb) in zip(profile,profile[1:]):
            if t<=tb:return ra+(rb-ra)*(t-ta)/(tb-ta)
        return profile[-1][1]
    for j in range(rings+1):
        t=j/rings
        for k in range(sides):
            a=k*math.tau/sides;r=radius(t)*(1+.065*math.cos(8*a+.3))*size
            g.v.append((r*math.cos(a),r*math.sin(a),(.002+t*.114)*size));g.uv[len(g.v)-1]=(k/sides,t)
    for j in range(rings):
        for k in range(sides):
            p=j*sides+k;q=j*sides+(k+1)%sides
            g.face((p,q,q+sides,p+sides),1 if j<7 and k%8 in (0,1) else 0)
    g.face(tuple(reversed(range(sides))),2);g.face(tuple(rings*sides+k for k in range(sides)),0)
    g.tube([(0,0,.10*size),(0,0,.17*size)],[.013*size,.010*size],0,16)
    ellipse(g,(0,0,.002*size),(.023*size,.023*size,.005*size),2,4,16)
    for i in range(20):
        a=i*2.399963;r=(.008+.010*(i%4)/3)*size;p=Vector((r*math.cos(a),r*math.sin(a),.001*size))
        g.tube([p,p+Vector((math.cos(a)*.012,math.sin(a)*.012,-.012))*size,
                p+Vector((math.cos(a+.4)*.022,math.sin(a+.4)*.022,-.020))*size],
               [.0012*size,.0008*size,.00025*size],3,5)
    mark_anchor(g,0,(0,0,0))
    return g


def geometry():
    g,b=foliage(),bulb();scale=HEIGHT/max(p[2] for p in g.v+b.v)
    parts=[g,b,bulb(.62),foliage('seedling'),foliage('juvenile')]
    for geo in parts:
        geo.v=[tuple(v*scale for v in p) for p in geo.v]
        if hasattr(geo,'fruit_anchors'):geo.fruit_anchors={i:tuple(v*scale for v in p) for i,p in geo.fruit_anchors.items()}
    return parts
