"""Authored low-plant collection: 50 grasses, groundcovers and succulents.

Pure geometry entry points; importing does not modify a Blender scene or files.
Coordinates are metres, Z up. The exporter preserves existing plant envelopes.
Every growth stage is generated with its own organ counts and juvenile anatomy.
All reproductive geometry has an attachment shared by its matching closed bud.
"""
import math
import random
from mathutils import Vector
from botanical_geometry import Geometry
from botanical_additions_data import ADDITIONS
from low_grasses_data import LOW_GRASSES
from fruit_tree_geometry import mark_anchor

IDS = tuple(list(range(12, 20)) + [44, 96] + [i for i in range(106, 148) if i not in (109, 124)])
TAU = math.tau
Z = Vector((0, 0, 1))


def radial(a, r, z=0):
    return Vector((math.cos(a) * r, math.sin(a) * r, z))


def joins(g, rows, mat=0, reverse=False):
    """Join rings including unique poles, avoiding zero-area pole triangles."""
    for n, (left, right) in enumerate(zip(rows, rows[1:])):
        count = max(len(left), len(right))
        for k in range(count):
            m = mat(n, k, count) if callable(mat) else mat
            q = (k + 1) % count
            if len(left) == 1:
                face = (left[0], right[k], right[q])
            elif len(right) == 1:
                face = (left[k], right[0], left[q])
            else:
                face = (left[k], right[k], right[q], left[q])
            g.face(tuple(reversed(face)) if reverse else face, m)


def ellipse(g, center, scale, mat=1, rings=5, sides=8):
    center = Vector(center)
    rows = []
    for j in range(rings + 1):
        t = j / rings
        row = []
        for k in range(1 if j in (0, rings) else sides):
            a = TAU * k / sides
            p = center + Vector((math.sin(math.pi*t)*math.cos(a)*scale[0],
                                 math.sin(math.pi*t)*math.sin(a)*scale[1],
                                 -math.cos(math.pi*t)*scale[2]))
            row.append(len(g.v)); g.v.append(tuple(p)); g.uv[len(g.v)-1] = (k/sides, t)
        rows.append(row)
    joins(g, rows, mat, reverse=True)


def petal(g, base, direction, side, normal, length, width, mat=0, cup=.18, steps=6):
    base, direction, side, normal = map(Vector, (base, direction, side, normal))
    reverse = direction.cross(side).dot(normal) < 0
    rows = []
    for j in range(steps+1):
        t = j/steps
        row = []
        for q in ([0] if j in (0, steps) else [-1, 0, 1]):
            w = width*math.sin(math.pi*t)**.7
            p = base+direction*length*t+side*q*w+normal*(length*cup*math.sin(math.pi*t)+w*q*q*.15)
            row.append(len(g.v)); g.v.append(tuple(p)); g.uv[len(g.v)-1] = ((q+1)/2, t)
        rows.append(row)
    for left, right in zip(rows, rows[1:]):
        for k in range(2):
            if len(left)==1: face = (left[0], right[k], right[k+1])
            elif len(right)==1: face = (left[k], right[0], left[k+1])
            else: face = (left[k], right[k], right[k+1], left[k+1])
            g.face(tuple(reversed(face)) if reverse else face, mat)


def rays(g, center, radius, petals=12, mat=0, disk=1, tiers=1, normal=Z):
    center, normal = Vector(center), Vector(normal).normalized()
    side = normal.cross(Vector((1,0,0)) if abs(normal.x)<.8 else Z).normalized()
    up = side.cross(normal).normalized()
    for ring in range(tiers):
        for k in range(petals):
            a = k*TAU/petals + ring*.22
            direction = side*math.cos(a)+up*math.sin(a)
            tangent = -side*math.sin(a)+up*math.cos(a)
            petal(g, center+normal*radius*ring*.08, direction, tangent, normal,
                  radius*(1-ring*.2), radius*(.18 if petals>8 else .38), mat, .18+ring*.12)
    ellipse(g, center+normal*radius*.12, (radius*.23, radius*.23, radius*.18), disk, 4, 8)


def closed_bud(buds, anchor, radius, length, mat=0, direction=Z):
    anchor, direction = Vector(anchor), Vector(direction).normalized()
    start = len(buds.v)
    # All buds are attached at exactly the mature organ's origin.
    endpoint = anchor+direction*length*.5
    buds.tube([anchor, endpoint], [radius*.35, radius*.28], 2, 4)
    ellipse(buds, endpoint, (radius, radius, length*.56), mat, 4, 7)
    mark_anchor(buds, start, anchor)


def growing_tip(b, buds, anchor, radius, length):
    start = len(b.v)
    ellipse(b, Vector(anchor)+Z*length*.3, (radius, radius, length*.5), 2, 4, 6)
    mark_anchor(b, start, anchor)
    closed_bud(buds, anchor, radius*.75, length*.7, 2)


def ribbon(g, base, angle, height, reach, width, mat=1, style='', steps=10):
    """Folded blades with a bending apex and continuous taper to one tip."""
    base = Vector(base); d = radial(angle, 1); side = radial(angle+math.pi/2, 1)
    striped = style in ('evergold', 'snowline')
    columns = [-1, -.7, .7, 1] if striped else [-1, 0, 1]
    rows = []
    for j in range(steps+1):
        t = j/steps
        c = base + d*(reach*t*t) + Z*(height*(1.18*t-.38*t**3))
        c += side*(math.sin(math.pi*t)*reach*.06)
        w = width*math.sin(math.pi*(.035+.965*t))**.65*(1-.2*t)
        row = []
        for q in ([0] if j==steps else columns):
            p = c+side*w*q+Z*(-abs(q)*w*.28+q*w*t*.08)
            row.append(len(g.v)); g.v.append(tuple(p)); g.uv[len(g.v)-1] = ((q+1)/2,t)
        rows.append(row)
    for j, (left, right) in enumerate(zip(rows, rows[1:])):
        for k in range(len(left)-1):
            m = mat
            if style=='banded' and j in (3,6,9): m=4
            if style=='blood' and j>=steps*.48: m=4
            if striped: m=2 if ((k==1) == (style=='evergold')) else 1
            if len(right)==1: g.face((left[k], right[0], left[k+1]), m)
            else: g.face((left[k], right[k], right[k+1], left[k+1]), m)
    return Vector(g.v[rows[-1][0]])


# height, half blade width, mature blades, reach/height, inflorescence
GRASS_PROFILES = {
    14:(.36,.0040,76,.48,'fescue'), 15:(.68,.0023,100,.72,'feather'),
    16:(.62,.016,66,.86,'sedge'), 17:(.80,.009,82,.83,'fountain'),
    44:(.73,.024,62,.95,'lomandra'),
    106:(1.38,.025,72,.72,'banded'), 107:(1.28,.010,70,.32,'reed'),
    108:(1.04,.011,76,.43,'switch'), 110:(.53,.012,60,.40,'blood'),
    111:(.68,.004,80,.70,'moor'), 112:(.60,.003,92,.75,'hair'),
    113:(.49,.004,72,.58,'quaking'), 114:(.37,.0065,80,.58,'sesleria'),
    115:(.65,.003,92,.75,'muhly'),
}


def panicle(b, anchor, angle, length, style):
    """Species' branch topology, with compact ears separated from airy panicles."""
    anchor=Vector(anchor); start=len(b.v)
    d=radial(angle,1); top=anchor+Z*length+d*length*.13
    b.tube([anchor,anchor.lerp(top,.52),top],[length*.018,length*.011,length*.004],2,4)
    if style in ('fountain','reed','sesleria','sedge','lomandra','acorus','buffalo'):
        for j in range(8 if style=='fountain' else 6):
            t=(j+.4)/8 if style=='fountain' else (j+.5)/6
            c=anchor.lerp(top,t)
            count=7 if style=='fountain' else 4
            for k in range(count):
                a=k*TAU/count+j*.72
                r=length*(.20 if style=='fountain' else .13 if style=='lomandra' else .065)*math.sin(math.pi*t)**.55
                q=c+radial(a,r,length*.045)
                b.tube([c,q],[length*.009,length*.002],0,3)
                if style=='fountain':
                    b.tube([q,q+radial(a,length*.075,length*.09)],[length*.0025,length*.0005],0,3)
                else: ellipse(b,q,(length*.023,length*.023,length*.050),0,3,5)
    else:
        levels=5 if style in ('muhly','hair','moor','switch') else 4
        for j in range(levels):
            c=anchor.lerp(top,(j+.1)/(levels+.2))
            for k in range(3 if style=='muhly' else 2):
                a=angle+k*2.45+j*1.18
                extent=length*(.95 if style=='muhly' else .68 if style in ('hair','switch','banded') else .47)*(1-j/(levels+.7))
                tip=c+radial(a,extent,length*.14)
                b.tube([c,c.lerp(tip,.68)+Z*length*.055,tip],[length*.009,length*.005,length*.0018],0,3)
                for n in range(3 if style in ('muhly','hair','banded') else 2):
                    q=c.lerp(tip,(n+1)/3)
                    end=q+radial(a+.70,length*.15,length*(-.10 if style=='quaking' else .095))
                    b.tube([q,end],[length*.004,length*.0015],0,3)
                    if style=='quaking':
                        ellipse(b,end-Z*.012,(.010,.0035,.015),0,5,8)
                        for z in range(3):
                            c2=end+Vector((0,0,-.021+z*.006))
                            b.tube([c2+Vector((-.007,0,0)),c2+Vector((0,.003,.004)),c2+Vector((.007,0,0))],[.00055]*3,1,3)
                    else:
                        ellipse(b,end,(length*.012,length*.010,length*.030),0,3,5)
                        if style in ('feather','fescue'):
                            b.tube([end,end+radial(a,length*.13,length*.28)],[length*.002,length*.0004],1,3)
    mark_anchor(b,start,anchor)


def grass(idx, phase):
    g,b,buds=Geometry(),Geometry(),Geometry(); rng=random.Random(41817+idx)
    if idx>=136:
        _,_,_,_,h,style=LOW_GRASSES[idx-136]
        width={'mondo':.005,'black':.007,'zoysia':.0018,'buffalo':.0035,'bent':.0023,
               'red_fescue':.002,'sheep':.0022,'bearskin':.0025,'sesleria':.005,
               'evergold':.008,'snowline':.005,'acorus':.006}[style]
        count=150 if style in ('zoysia','buffalo','bent','red_fescue') else 104
        reach=.48 if style in ('zoysia','sheep','bearskin') else .70 if style=='acorus' else .98
    else: h,width,count,reach,style=GRASS_PROFILES[idx]
    age={'mature':1,'juvenile':.48,'seedling':.18}[phase]
    count=count if phase=='mature' else 18 if phase=='juvenile' else 5
    carpet=style in ('zoysia','buffalo','bent','red_fescue')
    crowns=13 if carpet and phase=='mature' else 5 if phase=='mature' else 3 if phase=='juvenile' else 1
    bases=[]
    radius=(.33 if carpet else .08 if idx<136 else .065)*age
    for j in range(crowns):
        a=j*2.39996; base=radial(a,radius*math.sqrt((j+.25)/crowns),.002*age)
        bases.append(base)
        if j and carpet:
            prev=bases[(j-1)//2]
            g.tube([prev,prev.lerp(base,.5)+Z*.003*age,base],[.0018*age,.0015*age,.001*age],0,4)
            for k in (.35,.7):
                node=prev.lerp(base,k);ellipse(g,node,(.0028*age,)*3,0,3,5)
    tips=[]
    for j in range(count):
        c=j%crowns; a=j*2.39996+c*.34+rng.uniform(-.13,.13)
        base=bases[c]+radial(a,.019*age*rng.random())
        # Flat, overlapping fans distinguish sweet flag from round grass tussocks.
        if style=='acorus':a=c*1.1+(0 if j%2 else math.pi)+rng.uniform(-.10,.10)
        hh=h*age*rng.uniform(.60,1.13)
        if phase!='mature':hh*=1.20 # juvenile blades proportionally broader/upright
        tips.append(ribbon(g,base,a,hh,hh*reach*rng.uniform(.70,1.05),width*age*(1.28 if phase!='mature' else 1),
                           1 if j%4 else 2,style,10 if phase=='mature' else 7))
    if phase!='mature':return g,b,buds
    if style=='blood':
        # This cultivar is grown for red foliage, not invented flower plumes.
        for p in sorted(tips,key=lambda p:p.z,reverse=True)[:3]:growing_tip(b,buds,p,.0018,.012)
        return g,b,buds
    stems=7 if idx<136 else 4 if carpet else 5
    for j in range(stems):
        a=j*2.39996+.40; base=bases[j%crowns]
        target=h*(2.0 if style=='moor' else 1.18 if style in ('hair','muhly') else .97 if idx<136 else .82)
        if style in ('mondo','black'):target=h*.65
        anchor=base+radial(a,h*reach*.48,target*rng.uniform(.86,1.02))
        mid=base.lerp(anchor,.5)+Z*h*.09
        g.tube([base,mid,anchor],[max(.0008,h*.006),max(.0006,h*.004),max(.0004,h*.002)],0,4)
        if idx<136:
            for k in (.30,.56):ribbon(g,base.lerp(anchor,k),a+1.8,h*.21,h*.14,width*.68,1,'',7)
        length=h*(.28 if style in ('muhly','hair','switch','banded','feather') else .20 if style=='moor' else .24 if style=='fountain' else .12)
        if style in ('mondo','black'):
            start=len(b.v)
            for k in range(4):
                p=anchor+Z*(k*.012)
                q=p+radial(a+k*2.4,.013,-.003)
                b.tube([anchor,p,q],[.0007,.0006,.0004],2,3) if k else b.tube([p,q],[.0007,.0004],2,3)
                rays(b,q,.009,6,normal=radial(a+k*2.4,.5,.8))
            mark_anchor(b,start,anchor)
        else:panicle(b,anchor,a,max(.020,length),style)
        closed_bud(buds,anchor,max(.0015,width*.4),max(.009,length*.26),0)
    return g,b,buds


def kidney(g, center, angle, r, mat=1):
    center=Vector(center); start=len(g.v);g.v.append(tuple(center+Z*r*.15));g.uv[start]=(.5,.5)
    d=radial(angle,1);side=radial(angle+math.pi/2,1);rows=[]
    for fraction in (.50,1):
        row=[]
        for k in range(20):
            a=TAU*k/20
            # The basal cleft is an actual silhouette notch, not a painted circle.
            rr=r*(1-.62*math.exp(-((a-math.pi)/.48)**2))
            p=center+(d*math.cos(a)+side*math.sin(a))*rr*fraction+Z*r*(.16*math.sin(a)-.12*fraction*fraction)
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=(.5+math.cos(a)*fraction*.49,.5+math.sin(a)*fraction*.49)
        rows.append(row)
    for k in range(20):
        n=(k+1)%20;g.face((start,rows[0][k],rows[0][n]),mat);g.face((rows[0][k],rows[1][k],rows[1][n],rows[0][n]),mat)


def ground(idx,phase):
    g,b,buds=Geometry(),Geometry(),Geometry();rng=random.Random(57917+idx)
    age={'mature':1,'juvenile':.50,'seedling':.20}[phase]
    if idx==13:
        count={'mature':86,'juvenile':16,'seedling':4}[phase]
        for j in range(count):
            a=j*2.39996; base=radial(a,.39*age*math.sqrt((j+.1)/count),.001)
            top=base+radial(a,.009*age,age*rng.uniform(.025,.060))
            g.tube([base,top],[.0009*age,.00035*age],0,3)
            for k in range(7 if phase=='mature' else 4):
                p=base.lerp(top,.18+k*.11);aa=a+k*2.4
                g.leaf(p,p+radial(aa,age*.025,age*.014),.007*age,1+k%2,.27,3)
            if phase=='mature' and j%14==0:
                anchor=top;end=top+radial(a,.013,.022)
                g.tube([top,end],[.00065,.00035],0,3)
                start=len(b.v);ellipse(b,end,(.0019,.0019,.004),0,4,6);mark_anchor(b,start,end)
                closed_bud(buds,end,.0015,.0035,0)
        return g,b,buds
    arms={'mature':10 if idx==12 else 7,'juvenile':3,'seedling':1}[phase]
    for j in range(arms):
        a=j*2.39996; tip=radial(a,.40*age,.005*age)
        points=[radial(a+.15*math.sin(k),.40*age*k/5,.004*age+math.sin(k)*.002*age) for k in range(6)]
        g.tube(points,[.0025*age*(1-k*.13) for k in range(6)],0,4)
        for k in range(1,6):
            node=points[k];aa=a+k*1.1
            if idx==18:
                end=node+radial(aa,.013*age,age*rng.uniform(.024,.046))
                g.tube([node,end],[.0017*age,.00085*age],0,4)
                kidney(g,end,aa,.055*age,1 if k%3 else 2)
                if phase=='mature' and k==2:
                    start=len(b.v);rays(b,node+Z*.005,.004,5,normal=Z);mark_anchor(b,start,node)
                    closed_bud(buds,node,.0018,.005,0)
            elif idx==12:
                end=node+radial(aa,.025*age,.040*age)
                g.tube([node,end],[.0014*age,.0005*age],0,4)
                for n in range(3):
                    p=node.lerp(end,.14+n*.27)
                    for sign in (-1,1):
                        g.leaf(p,p+radial(aa+sign*math.pi/2,.023*age,.005*age),.009*age,1+n%2,.20,4)
                if phase=='mature' and (j+k)%2==0:
                    start=len(b.v)
                    for n in range(3):
                        q=end+radial(n*2.4,.008,.004)
                        b.tube([end,q],[.0007,.00035],2,3);rays(b,q,.008,5)
                    mark_anchor(b,start,end);closed_bud(buds,end,.004,.007,0)
            else:
                # Upright branched daisies above fine bipinnate chamomile foliage.
                end=node+radial(aa,.065*age,.21*age*rng.uniform(.70,1.10))
                g.tube([node,node.lerp(end,.55),end],[.0020*age,.0013*age,.0006*age],0,4)
                for n in range(2 if phase=='seedling' else 3):
                    p=node.lerp(end,.20+n*.18)
                    for sign in (-1,1):
                        q=p+radial(aa+sign*1.0,.07*age,.032*age)
                        g.tube([p,q],[.0008*age,.00025*age],0,3)
                        for s in range(3):
                            t=p.lerp(q,.28+s*.22)
                            for z in (-1,1):g.leaf(t,t+radial(aa+sign*1.0+z*.65,.024*age,.010*age),.0016*age,1,.15,3)
                if phase=='mature' and k%2:
                    start=len(b.v);rays(b,end,.036,14)
                    ellipse(b,end+Z*.009,(.010,.010,.012),1,5,9)
                    mark_anchor(b,start,end);closed_bud(buds,end,.007,.013,2)
    return g,b,buds


def gymea(phase):
    g,b,buds=Geometry(),Geometry(),Geometry();rng=random.Random(96961)
    age={'mature':1,'juvenile':.48,'seedling':.19}[phase]
    for j in range({'mature':34,'juvenile':12,'seedling':4}[phase]):
        a=j*2.39996;length=age*rng.uniform(.95,1.42)
        ribbon(g,radial(a,.10*age),a,length*.78,length*.95,.064*age,1+j%2,'',14 if phase=='mature' else 9)
    if phase!='mature':return g,b,buds
    path=[Vector((0,0,.08)),Vector((.025,-.02,1.25)),Vector((.055,.01,2.30)),Vector((.10,.03,2.96))]
    g.tube(path,[.060,.049,.036,.025],0,10)
    for j in range(12):
        t=(j+.5)/13;z=.30+2.45*t;p=Vector((.10*z/2.96,.03*z/2.96,z))
        g.leaf(p,p+radial(j*2.4,.19*(1-t*.5),.22),.042,1,.14,6)
    top=path[-1]
    for j in range(24):
        t=(j+.5)/24;a=j*2.39996;p=top+radial(a,.18*math.sqrt(t),.13*math.sqrt(1-t))
        g.tube([top,p],[.006,.003],0,5)
        g.leaf(p,p+radial(a,.07,-.02),.025,5,.3,4)
        normal=radial(a,.38,.94).normalized();right=normal.cross(radial(a+1,1)).normalized();up=right.cross(normal).normalized()
        start=len(b.v)
        for k in range(6):
            turn=k*TAU/6;direction=normal*.68+(right*math.cos(turn)+up*math.sin(turn))*.67
            petal(b,p,direction,right*-math.sin(turn)+up*math.cos(turn),normal,.115,.029,0,.35,8)
            tip=p+normal*.12+(right*math.cos(turn)+up*math.sin(turn))*.025
            b.tube([p,tip],[.0013,.0007],1,3);ellipse(b,tip,(.002,.002,.005),1,3,5)
        mark_anchor(b,start,p);closed_bud(buds,p,.012,.068,0,normal)
    return g,b,buds


def flesh(g, base, tip, width, thick, mat=1, pointed=False, red=False, channel=0, steps=8, sides=8, side_override=None, curl=.10):
    """Watertight fleshy organ with unique end poles and an optional upper channel."""
    base,tip=Vector(base),Vector(tip);delta=tip-base;d=delta.normalized()
    side=Vector(side_override).normalized() if side_override is not None else d.cross(Z).normalized()
    if side.length<.01:side=Vector((1,0,0))
    up=side.cross(d).normalized()
    if side_override is None and up.z<0:up=-up
    rows=[]
    for j in range(steps+1):
        t=j/steps;profile=math.sin(math.pi*t)**(.85 if pointed else .43)
        center=base+delta*t+up*delta.length*curl*math.sin(math.pi*t)
        row=[]
        for k in range(1 if j in (0,steps) else sides):
            a=TAU*k/sides
            p=center+side*math.cos(a)*width*profile+up*math.sin(a)*thick*profile
            p+=up*(max(0,math.sin(a))*channel*width*(math.cos(a)**2-.25)*profile)
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
        rows.append(row)
    joins(g,rows,lambda j,k,n:4 if red and (j>=steps-2 or j>=2 and abs(math.cos((k+.5)*TAU/n))>.85) else mat)


def ribbed(g,base,radius,height,ribs,form,young=False):
    base=Vector(base);sides=ribs*5;rings=10 if young else 18;rows=[]
    power=.65 if form in ('barrel','star') else .17
    for j in range(rings+1):
        t=j/rings;row=[];f=math.sin(math.pi*t)**power
        for k in range(1 if j in (0,rings) else sides):
            a=k*TAU/sides;r=radius*f*(1+.18*math.cos(ribs*a))
            p=base+radial(a,r,height*t)
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
        rows.append(row)
    joins(g,rows,1,reverse=True)
    for j in range(2,rings-1,3 if young else 2):
        t=j/rings;f=math.sin(math.pi*t)**power
        for k in range(ribs):
            a=k*TAU/ribs;p=base+radial(a,radius*f*1.185,height*t)
            s=radius*(.040 if form=='star' else .044)
            ellipse(g,p,(s,s,s*1.22),3,3,5)
            if form=='star':continue
            for n in range(3 if young else 5):
                turn=TAU*n/(3 if young else 5);d=radial(a,.5)+radial(a+math.pi/2,math.cos(turn)*.6,math.sin(turn)*.7)
                length=radius*(.30 if form=='barrel' else .13)
                g.tube([p,p+d.normalized()*length],[max(.0005,radius*.009),max(.0001,radius*.0015)],3,3)
    if form=='star':
        for j in range(20 if young else 95):
            t=.13+.72*((j*.61803)%1);a=j*2.39996;r=radius*math.sin(math.pi*t)**power*(1+.18*math.cos(ribs*a))
            ellipse(g,base+radial(a,r*1.009,height*t),(radius*.012,)*3,3,2,4)
    if form=='wool':
        for j in range(50 if young else 440):
            t=.10+.83*((j*.61803)%1);a=j*2.39996;r=radius*math.sin(math.pi*t)**power*(1+.18*math.cos(ribs*a))
            p=base+radial(a,r*1.01,height*t)
            g.tube([p,p+radial(a,radius*.10,-height*.015),p+radial(a+.05,radius*.17,-height*.08)],
                   [radius*.014,radius*.010,radius*.002],3,3)


def cactus(idx,phase):
    g,b,buds=Geometry(),Geometry(),Geometry();form=ADDITIONS[idx-106][-1];h=ADDITIONS[idx-106][-2]
    age={'mature':1,'juvenile':.46,'seedling':.20}[phase];h*=age;young=phase!='mature'
    if form in ('bunny','pear'):
        pads=[(Vector((0,0,0)),Vector((0,0,h*.43)),h*.19)]
        if phase!='seedling':
            for sign in (-1,1):
                base=Vector((sign*h*.065,0,h*.34))
                tip=Vector((sign*h*.20,sign*h*.026,h*(.91 if form=='bunny' else .82)))
                pads.append((base,tip,h*.145))
                if phase=='mature':
                    end=tip+Vector((sign*h*.10,-sign*h*.024,h*(.22 if form=='bunny' else .35)))
                    pads.append((tip-Z*h*.06,end,h*(.088 if form=='bunny' else .14)))
        for no,(base,tip,w) in enumerate(pads):
            d=tip-base
            pad_side=Vector((d.z,0,-d.x)).normalized()
            flesh(g,base,tip,w,h*.035,1,False,steps=12,sides=12,side_override=pad_side,curl=0)
            for side in (-1,1):
                for j in range(14 if young else 33):
                    t=.11+.78*((j*.61803)%1);profile=math.sin(math.pi*t)**.43
                    fraction=math.cos(j*2.39996)*.85;x=fraction*w*profile
                    c=base+d*t+pad_side*x+Vector((0,side*h*.035*profile*math.sqrt(1-fraction*fraction),0))
                    ellipse(g,c,(h*.008,h*.004,h*.008),3,3,5)
                    if form=='pear' and j%2==0:
                        for n in range(2):g.tube([c,c+Vector((h*.015*(n*2-1),side*h*.026,h*.014))],[h*.0014,h*.0002],3,3)
            if not young and no in (2,4):
                anchor=tip-Z*h*.025;start=len(b.v);rays(b,anchor,h*.056,14,tiers=2);mark_anchor(b,start,anchor)
                closed_bud(buds,anchor,h*.012,h*.040,2)
    elif form=='finger':
        count=7 if not young else 2 if phase=='juvenile' else 1
        for j in range(count):
            a=j*2.4;hh=h*(1-j*.065);base=radial(a,.078*age*math.sqrt(j/max(1,count-1)))
            radius=.031*age
            ellipse(g,base+Z*hh*.48,(radius,radius,hh*.48),1,10,12)
            for k in range(20 if young else 50):
                t=.10+.82*k/(20 if young else 50);aa=k*2.39996
                p=base+radial(aa,radius*math.sqrt(max(0,1-((t-.48)/.48)**2)),hh*t)
                ellipse(g,p,(radius*.19,)*3,2,3,5)
                for n in range(4):
                    turn=n*TAU/4;end=p+radial(aa,radius*.30)+radial(aa+math.pi/2,math.cos(turn)*radius*.33,math.sin(turn)*radius*.34)
                    g.tube([p,end],[radius*.025,radius*.004],3,3)
            if not young and j in (0,2,4):
                anchor=base+Z*hh*.92;start=len(b.v);rays(b,anchor,.018,12,tiers=2);mark_anchor(b,start,anchor)
                closed_bud(buds,anchor,.005,.015,0)
    else:
        count=3 if form=='column' and not young else 1
        for j in range(count):
            hh=h*(1-.21*j);base=radial(j*2.4,h*.13 if j else 0)
            radius=h*(.56 if form=='star' else .43 if form=='barrel' else .12)
            ribbed(g,base,radius,hh,8 if form=='star' else 24 if form=='barrel' else 6 if form=='column' else 18,form,young)
            if young:continue
            if form in ('barrel','star'):
                flowers=5 if form=='barrel' else 1
                for k in range(flowers):
                    a=k*TAU/flowers;anchor=base+radial(a,radius*.26 if flowers>1 else 0,hh*.975)
                    start=len(b.v);rays(b,anchor,h*(.060 if form=='barrel' else .24),16,tiers=2);mark_anchor(b,start,anchor)
                    closed_bud(buds,anchor,h*.014,h*.044,2)
            else:growing_tip(b,buds,base+Z*hh,radius*.12,hh*.025)
    return g,b,buds


def rosette(g,center,r,form,age=1):
    center=Vector(center)
    count=(34 if form in ('hens','aeonium') else 23 if form=='lipstick' else 19) if age>.6 else 12 if age>.3 else 6
    for j in range(count):
        t=j/max(1,count-1);a=j*2.39996;extent=r*(1-.73*t)
        rise=r*(.17+.62*t)
        if form in ('aloe','agave','zebra'):rise=r*(.52+.60*t);extent*=.77
        width=extent*(.17 if form=='aloe' else .22 if form=='agave' else .16 if form=='zebra' else .29 if form=='lipstick' else .37)
        thick=extent*(.085 if form=='aloe' else .085 if form=='lipstick' else .063 if form=='agave' else .033 if form=='aeonium' else .065)
        p=center+Z*r*t*.13;tip=p+radial(a,extent,rise)
        leaf_d=(tip-p).normalized();leaf_side=leaf_d.cross(Z).normalized();leaf_up=leaf_side.cross(leaf_d).normalized()
        if leaf_up.z<0:leaf_up=-leaf_up
        mat=2 if t>.79 else 1
        flesh(g,p,tip,width,thick,mat,form!='aeonium',form in ('hens','lipstick'),.45 if form in ('aloe','agave') else .08,
              steps=10 if age>.6 else 7)
        if form in ('aloe','agave'):
            for k in range(2,9 if age>.6 else 7):
                s=k/10;loc=p.lerp(tip,s)+leaf_up*math.sin(math.pi*s)*(tip-p).length*.10
                ww=width*math.sin(math.pi*s)**.85
                for sign in (-1,1):
                    q=loc+radial(a+sign*math.pi/2,ww)
                    g.tube([q,q+radial(a+sign*math.pi/2,r*.020,r*.010)], [r*.005,r*.0007],3 if form=='aloe' else 4,3)
            if form=='agave':g.tube([tip,tip+radial(a,r*.032,r*.020)],[r*.005,r*.0004],4,4)
        if form=='zebra':
            for k in range(2,8 if age>.6 else 6):
                s=k/9;loc=p.lerp(tip,s)+leaf_up*math.sin(math.pi*s)*(tip-p).length*.10
                ww=width*math.sin(math.pi*s)**.85
                for n in (-.8,-.4,0,.4,.8) if age>.6 else (-.65,0,.65):
                    q=loc+leaf_side*ww*n+leaf_up*thick*math.sin(math.pi*s)**.85*math.sqrt(1-n*n)
                    ellipse(g,q,(r*.012,r*.010,r*.008),3,2,4)


def bell_flower(b,anchor,r,length,normal=-Z):
    normal=Vector(normal).normalized();anchor=Vector(anchor)
    side=normal.cross(Vector((1,0,0)) if abs(normal.x)<.8 else Z).normalized();up=side.cross(normal).normalized()
    rows=[]
    for j,(t,rr) in enumerate([(0,.20),(.25,.65),(.70,1),(1,.80)]):
        row=[]
        for k in range(10):
            a=k*TAU/10;p=anchor+normal*length*t+(side*math.cos(a)+up*math.sin(a))*r*rr
            row.append(len(b.v));b.v.append(tuple(p));b.uv[len(b.v)-1]=(k/10,t)
        rows.append(row)
    joins(b,rows,0)
    for k in range(5):
        a=k*TAU/5;direction=(side*math.cos(a)+up*math.sin(a))*.30+normal*.90
        petal(b,anchor+normal*length*.86+(side*math.cos(a)+up*math.sin(a))*r*.75,
              direction,-side*math.sin(a)+up*math.cos(a),normal,r*.65,r*.28,1,.18,4)


def flower_stalk(g,b,buds,base,h,form):
    base=Vector(base);top=base+Vector((h*.08,0,h))
    path=[base,base.lerp(top,.60),top+Vector((h*.08,0,-h*.03))]
    g.tube(path,[h*.012,h*.008,h*.004],0,5)
    total=12 if form=='aloe' else 7 if form=='hens' else 5
    for j in range(total):
        t=.57+j*.39/max(1,total-1);p=base.lerp(top,t);a=j*2.39996
        anchor=p+radial(a,h*(.12 if form=='aloe' else .09),-.015*h)
        g.tube([p,anchor],[h*.004,h*.002],0,4)
        start=len(b.v)
        if form=='hens':rays(b,anchor,h*.050,11,normal=radial(a,.4,1))
        else:bell_flower(b,anchor,h*(.014 if form in ('zebra','window') else .025),h*(.048 if form in ('zebra','window') else .08),radial(a,.25,-1))
        mark_anchor(b,start,anchor);closed_bud(buds,anchor,h*.015,h*.045,0,-Z)


def cup_leaf(g,base,tip,r):
    base,tip=Vector(base),Vector(tip);d=(tip-base).normalized();side=d.cross(Z).normalized()
    if side.length<.01:side=Vector((1,0,0))
    up=side.cross(d).normalized();rows=[]
    for j,(t,rr) in enumerate([(0,0),(.25,.55),(.70,.63),(1,1),(.98,.68),(.85,.36),(.82,0)]):
        row=[]
        for k in range(1 if rr==0 else 10):
            a=TAU*k/10;p=base.lerp(tip,t)+(side*math.cos(a)+up*math.sin(a))*r*rr
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/10,t)
        rows.append(row)
    joins(g,rows,lambda j,k,n:4 if j==3 else 1)


def woody_flesh(idx,phase):
    g,b,buds=Geometry(),Geometry(),Geometry();form=ADDITIONS[idx-106][-1];h=ADDITIONS[idx-106][-2]
    age={'mature':1,'juvenile':.44,'seedling':.18}[phase];h*=age
    trunk=[Vector((0,0,0)),Vector((h*.045,0,h*.27)),Vector((-h*.025,h*.03,h*.52))]
    g.tube(trunk,[h*.048,h*.033,h*.018],0,8)
    branches=6 if phase=='mature' else 3 if phase=='juvenile' else 1
    for j in range(branches):
        a=j*2.39996;root=trunk[1].lerp(trunk[-1],.10+.8*j/max(1,branches-1))
        tip=root+radial(a,h*(.30 if form!='aeonium' else .28),h*(.22+.08*(j%2)))
        bend=root.lerp(tip,.5)+Z*h*.04
        g.tube([root,bend,tip],[h*.020,h*.012,h*.006],0,6)
        if form=='aeonium':
            rosette(g,tip,h*(.23 if phase=='mature' else .34),form,age)
            if phase=='mature':growing_tip(b,buds,tip,h*.010,h*.025)
            continue
        for k in range(3 if phase!='seedling' else 2):
            p=bend.lerp(tip,.1+k*.38)
            for sign in (-1,1):
                q=p+radial(a+sign*math.pi/2,h*.145,h*.075)
                if form=='jade':flesh(g,p,q,h*.057,h*.018,2 if k==2 else 1,False,steps=8)
                else:cup_leaf(g,p,q,h*.023)
        if phase=='mature':
            # Connected branching cymes, above actual opposite leaf pairs.
            for k in range(4):
                q=tip+radial(k*2.4,h*.037,h*.035)
                g.tube([tip,q],[h*.0025,h*.0011],0,4)
                start=len(b.v);rays(b,q,h*.024,5);mark_anchor(b,start,q)
                closed_bud(buds,q,h*.006,h*.016,0)
    return g,b,buds


def holiday(phase):
    g,b,buds=Geometry(),Geometry(),Geometry();age={'mature':1,'juvenile':.45,'seedling':.20}[phase]
    chains=8 if phase=='mature' else 3 if phase=='juvenile' else 1
    for j in range(chains):
        a=j*2.39996;p=radial(a,.025*age,.035*age)
        for k in range(5 if phase=='mature' else 3 if phase=='juvenile' else 2):
            q=p+radial(a+.12*math.sin(k+j),.075*age,age*(.080-.027*k))
            # Flattened, thick-edged stem segments with actual pointed marginal teeth.
            d=q-p;side=radial(a+math.pi/2,1);normal=side.cross(d.normalized()).normalized();rows=[]
            for n in range(9):
                t=n/8;w=.031*age*(.32+.68*math.sin(math.pi*t)**.55)
                if n in (3,6):w*=1.30
                row=[]
                for m in range(8):
                    turn=TAU*m/8;pt=p+d*t+side*math.cos(turn)*w+normal*math.sin(turn)*.0045*age
                    row.append(len(g.v));g.v.append(tuple(pt));g.uv[len(g.v)-1]=(m/8,t)
                rows.append(row)
            joins(g,rows,2 if k==4 else 1);g.face(tuple(rows[0]),1);g.face(tuple(reversed(rows[-1])),1)
            p=q
        if phase!='mature':continue
        normal=radial(a,1,-.15).normalized();side=radial(a+math.pi/2,1);up=side.cross(normal).normalized()
        start=len(b.v)
        for ring in range(3):
            origin=p+normal*ring*.026
            for k in range(6):
                turn=k*TAU/6;out=up*math.cos(turn)+side*math.sin(turn)
                direction=normal*(.5 if ring==0 else .95)+out*(.88 if ring==0 else .55)
                petal(b,origin,direction,-up*math.sin(turn)+side*math.cos(turn),normal,
                      .070*(1+.15*math.cos(turn)),.023,0 if ring<2 else 3,.23,7)
        for k in range(6):
            q=p+normal*.128+side*(k-2.5)*.002+up*.005
            b.tube([p+normal*.05,q],[.0008,.0004],1,3);ellipse(b,q,(.0018,)*3,1,2,4)
        mark_anchor(b,start,p);closed_bud(buds,p,.013,.058,0,normal)
    return g,b,buds


def lithops(phase):
    g,b,buds=Geometry(),Geometry(),Geometry();age={'mature':1,'juvenile':.52,'seedling':.23}[phase]
    count=5 if phase=='mature' else 2 if phase=='juvenile' else 1
    for j in range(count):
        c=radial(j*2.39996,.059*age*math.sqrt(j/max(1,count-1)))
        for sign in (-1,1):
            p=c+Vector((sign*.016*age,0,0));rows=[]
            for n,(z,r) in enumerate([(0,.18),(.008,.72),(.025,1),(.039,.99),(.045,.85),(.046,0)]):
                row=[]
                for k in range(1 if r==0 else 14):
                    a=k*TAU/14;pt=p+Vector((math.cos(a)*.014*r*age,math.sin(a)*.024*r*age,z*age))
                    row.append(len(g.v));g.v.append(tuple(pt));g.uv[len(g.v)-1]=(k/14,z/.046)
                rows.append(row)
            joins(g,rows,lambda n,k,num:2 if n>=3 else 1,reverse=True);g.face(tuple(reversed(rows[0])),1)
            for k in range(13 if phase=='mature' else 5):
                a=k*2.4;r=.7*math.sqrt((k+.1)/13)
                q=p+Vector((math.cos(a)*.011*r*age,math.sin(a)*.020*r*age,.0459*age))
                ellipse(g,q,(.0019*age,.0027*age,.00045*age),4,2,5)
        if phase=='mature' and j in (0,3):
            anchor=c+Z*.035;start=len(b.v);b.tube([anchor,anchor+Z*.016],[.0025,.0017],2,4)
            rays(b,anchor+Z*.016,.030,24,tiers=2);mark_anchor(b,start,anchor)
            closed_bud(buds,anchor,.0045,.018,2)
    return g,b,buds


def succulent(idx,phase):
    if idx<=122:return cactus(idx,phase)
    if idx==123:return holiday(phase)
    if idx in (131,132,133):return woody_flesh(idx,phase)
    if idx==135:return lithops(phase)
    g,b,buds=Geometry(),Geometry(),Geometry();form=ADDITIONS[idx-106][-1];h=ADDITIONS[idx-106][-2]
    age={'mature':1,'juvenile':.48,'seedling':.19}[phase]
    if form=='beans':
        count=7 if phase=='mature' else 3 if phase=='juvenile' else 1
        for j in range(count):
            a=j*2.39996;base=radial(a,.035*age);top=base+radial(a,h*.35*age,h*age*(.72+.10*(j%2)))
            g.tube([base,base.lerp(top,.45),top],[.006*age,.0038*age,.0019*age],0,5)
            for k in range(12 if phase=='mature' else 6):
                t=.20+.75*k/(12 if phase=='mature' else 6);p=base.lerp(top,t);aa=a+k*2.39996
                tip=p+radial(aa,.027*age,.026*age)
                flesh(g,p,tip,.0105*age,.008*age,1,False,True,steps=8)
            if phase=='mature':
                start=len(b.v);rays(b,top,.019,5);mark_anchor(b,start,top);closed_bud(buds,top,.004,.008,0)
        return g,b,buds
    if form=='window':
        count=24 if phase=='mature' else 10 if phase=='juvenile' else 5
        for j in range(count):
            t=j/count;a=j*2.39996;base=radial(a,.009*age,.002*age)
            tip=radial(a,.075*age*(1-.68*t),.040*age+(.026*t)*age)
            flesh(g,base,tip,.019*age*(1-.42*t),.020*age,1,False,steps=8)
            q=base.lerp(tip,.79)+Z*.007*age
            ellipse(g,q,(.013*age,.013*age,.008*age),2,4,8)
            # Restrained opaque window stripes, not transparent layered cards.
            for k in (-1,0,1):
                p=q+radial(a+math.pi/2,.005*k*age)+Z*.0075*age
                g.tube([p-radial(a,.006*age),p+radial(a,.004*age)],[.00045*age]*2,5,3)
        if phase=='mature':flower_stalk(g,b,buds,(0,0,.035),.22,form)
        return g,b,buds
    r=h*age/(1.25 if form in ('aloe','agave','zebra') else .70)
    rosette(g,(0,0,.012*age),r,form,age)
    if phase=='mature':
        if form=='hens':
            for j in range(4):
                a=j*2.39996;q=radial(a,r*1.06,.008)
                g.tube([(0,0,.012),q],[.004,.0015],0,4);rosette(g,q,r*(.28+j*.025),form,.48)
            flower_stalk(g,b,buds,radial(.8,r*.50,.010),h*1.7,form)
        elif form=='agave':
            anchor=Vector((0,0,r*.29));g.tube([(0,0,.012),anchor],[r*.028,r*.019],1,6)
            growing_tip(b,buds,anchor,r*.019,r*.060)
        else:flower_stalk(g,b,buds,(0,0,h*.30),h*(1.35 if form=='aloe' else 1.6),form)
    return g,b,buds


def palette(idx):
    if idx not in IDS:raise ValueError(idx)
    succulent_plant=116<=idx<136
    colors={12:'78965b',13:'718e50',14:'88b9b0',15:'8f9f6b',16:'819854',17:'7d9160',18:'9aba8d',19:'79955d',44:'829b55',96:'669157'}
    flowercolors={12:'c58ccb',13:'9b7850',14:'cfbd91',15:'d5c9a3',16:'aeab7b',17:'c4a1ac',18:'c4c890',19:'fff4d9',44:'e0c589',96:'c33343'}
    if 106<=idx<136:
        color=ADDITIONS[idx-106][2];form=ADDITIONS[idx-106][-1]
        colors[idx]={'banded':'789153','reed':'789367','switch':'6f9caa','blood':'709653','moor':'7b9167','hair':'64845c','quaking':'819563','sesleria':'9dad64','muhly':'719064',
                     'barrel':'71904f','bunny':'8da966','pear':'719462','column':'678960','wool':'709267','finger':'849152','star':'82977c','holiday':'508f62','lipstick':'93ac73','hens':'809663','aloe':'7b9d86','agave':'87a6a3','zebra':'416f48','window':'86aa86','jade':'5c965e','gollum':'76a058','aeonium':'51323d','beans':'8ba35e','lithops':'b28b70'}[form]
        flowercolors[idx]={'barrel':'e0cd68','bunny':'ecda82','pear':'e7b55e','column':'698b62','wool':'bac3aa','finger':'f0dcb0','star':'ead166','holiday':'d65e88','lipstick':'e88777','hens':'d793b0','aloe':'e0a151','agave':'87a6a3','zebra':'e6dfd2','window':'e9e4d9','jade':'ead6d9','gollum':'eddbda','aeonium':'819954','beans':'e5cf67','lithops':'ead26e'}.get(form,color)
    if idx>=136:
        color=LOW_GRASSES[idx-136][2];form=LOW_GRASSES[idx-136][-1]
        colors[idx]='3d7049' if form in ('evergold','snowline') else color
        flowercolors[idx]='cbb5d7' if form in ('mondo','black') else 'bfb283'
    body=colors[idx];flower=flowercolors[idx]
    def shifted(color,factor):return ''.join('%02x'%min(255,round(int(color[n:n+2],16)*factor)) for n in (0,2,4))
    young=shifted(body,1.15);accent='ad4e47'
    if idx==106:accent='d3c27c'
    if idx==110:accent='b44351'
    if idx==145:young='e5d794'
    if idx==146:young='e8e5d5'
    if idx==133:young='799052'
    if idx==130:young='b3c9ab'
    if idx==135:young='c2a48a';accent='78594f'
    wind=not succulent_plant
    foliage=[('stems','806d50' if idx in (131,132,133) else shifted(body,.80),'bark' if idx in (131,132,133) else 'smooth',False),
             ('flesh' if succulent_plant else 'blades',body,'smooth' if succulent_plant else 'grass' if idx in GRASS_PROFILES or idx>=136 else 'leaf',wind),
             ('youngflesh' if succulent_plant else 'new blades',young,'smooth' if succulent_plant else 'leaf',wind),
             ('areoles and spines','e1d6b2','smooth',False),('pigment margins',accent,'smooth' if succulent_plant else 'grass',wind),
             ('bracts and veins',shifted(body,.63),'smooth',False)]
    bloom=[('petals',flower,'petal',False),('pollen','e6cf83','pollen',False),('calyx',body,'smooth',False),('inner petals',shifted(flower,1.12),'petal',False)]
    return {'foliage':foliage,'bloom':bloom}


def build(idx,phase='mature'):
    if idx not in IDS:raise ValueError('Plant ID is outside the low collection: %s'%idx)
    if phase not in ('mature','juvenile','seedling'):raise ValueError('Unknown growth phase: '+phase)
    if idx in (12,13,18,19):return ground(idx,phase)
    if idx==96:return gymea(phase)
    if 116<=idx<136:return succulent(idx,phase)
    return grass(idx,phase)
