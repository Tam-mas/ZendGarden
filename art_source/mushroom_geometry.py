"""Detailed fungi meshes using the garden's shared Blender primitives.

No scene/file side effects on import. Caps/spines use the existing local organ
attachment channels; rigid tissue receives no leaf wind. Each stage is authored.
"""
import math
import random
from mathutils import Vector
from botanical_geometry import Geometry
from mushroom_data import BY_ID
TAU = math.tau


def palette(idx):
    _, name, _, color, _, _, form = BY_ID[idx]
    stem = 'ad90bb' if form == 'amethyst' else 'e7bb6b' if form == 'funnel' else 'e4dcc7'
    underside = 'c4a4d0' if form == 'amethyst' else 'f2c36b' if form == 'funnel' else 'eac2bc' if form == 'pink_oyster' else 'd8cca9'
    colors = [stem, color, underside, 'c9ad75' if form=='morel' else 'f1e8d2', '514233' if form != 'inkcap' else '342e36', '80634b']
    entries = [(name+' '+label, col, 'smooth', False) for label, col in zip(
        ['stem tissue', 'cap cuticle', 'underside ridges', 'raised scales', 'recesses', 'wood'], colors)]
    return {'foliage': entries, 'bloom': entries}


def anchor(geo, start, point):
    if not hasattr(geo, 'fruit_anchors'): geo.fruit_anchors = {}
    geo.fruit_anchors.update({i: tuple(point) for i in range(start, len(geo.v))})


def cap(g, center, radius, rise, form, rng, detail=True):
    """Closed radial cap, with a domed/funnel/elongate profile and real gill ridges."""
    c = Vector(center); start = len(g.v); n = 64 if detail else 32
    if form == 'funnel':
        profile = [(.03, -.08), (.18, -.04), (.38, .0), (.62, .16), (.84, .36), (1., .54), (1.01, .46), (.82, .25), (.50, -.02), (.12, -.16)]
    elif form == 'inkcap':
        profile = [(.02, 1.6), (.26, 1.55), (.54, 1.32), (.76, .96), (.87, .45), (1., -.25), (.97, -.28), (.72, .26), (.30, .58), (.05, .52)]
    else:
        profile = [(.01, 1.), (.18, .99), (.40, .91), (.65, .72), (.84, .45), (.97, .12), (1., 0.), (.94, -.10), (.65, -.15), (.12, -.20)]
    phase = rng.uniform(0, TAU)
    for row, (r, z) in enumerate(profile):
        for j in range(n):
            a = j*TAU/n
            wave = math.sin(a*5+phase)*.035+math.sin(a*9-phase)*.018
            rr = radius*r*(1+wave)
            zz = rise*z+(wave*radius*r if form in ['funnel', 'amethyst'] else wave*radius*.25)
            g.v.append(tuple(c+Vector((rr*math.cos(a), rr*math.sin(a), zz))))
            g.uv[len(g.v)-1] = (j/n, row/(len(profile)-1))
    for row in range(len(profile)-1):
        for j in range(n):
            material = 1 if row < 6 else 2
            if form == 'inkcap' and row in [5, 6]: material = 4
            g.face((start+(row+1)*n+j, start+(row+1)*n+(j+1)%n, start+row*n+(j+1)%n, start+row*n+j), material)
    g.face(tuple(start+j for j in range(n)), 1)
    g.face(tuple(start+(len(profile)-1)*n+j for j in reversed(range(n))), 2)
    if detail:
        if form == 'bolete':
            # Bolete pores, rather than the radial gills of agarics.
            for k in range(150):
                a=k*2.39996; r=radius*math.sqrt((k+1)/155)*.88
                g.ellipsoid(c+Vector((r*math.cos(a),r*math.sin(a),-rise*.14)), (radius*.012, radius*.012, radius*.008), 4, 3, 5)
        else:
            count = 24 if form in ['funnel', 'amethyst'] else 52
            for j in range(count):
                a=j*TAU/count
                if form == 'funnel':
                    rr=[.13,.40,.70,.97]; zz=[-.16,-.08,.10,.41]
                else: rr=[.14,.45,.72,.95]; zz=[-.20,-.19,-.15,-.08]
                pts=[c+Vector((radius*r*math.cos(a),radius*r*math.sin(a),rise*z-.001)) for r,z in zip(rr,zz)]
                g.tube(pts,[radius*.009]*4,2,4)
                if form=='funnel' and j%3==0:
                    g.tube([pts[2],c+Vector((radius*.97*math.cos(a+.07),radius*.97*math.sin(a+.07),rise*.41))],[radius*.009,radius*.004],2,4)
    if detail and form in ['agaric','shiitake','inkcap']:
        count=60 if form=='agaric' else 95
        for k in range(count):
            a=k*2.39996; r=math.sqrt((k+.5)/count)*.94
            if form=='inkcap':
                zz=rise*(1.56-1.75*r*r); rr=radius*(.22+.76*r)
                p=c+Vector((rr*math.cos(a),rr*math.sin(a),zz))
                # Small overlapping downward flakes give the lawyer's-wig silhouette.
                tip=p+Vector((radius*.1*math.cos(a),radius*.1*math.sin(a),-rise*.22))
                g.leaf(p,tip,radius*.09,3,.22,3)
            else:
                z=rise*max(0,1-r*r)**.65
                p=c+Vector((radius*r*math.cos(a),radius*r*math.sin(a),z+.001))
                size=radius*rng.uniform(.026,.068)
                g.ellipsoid(p,(size,size*.8,size*.22),3,3,6)
    anchor(g,start,c)


def fan(g, base, radius, angle, pink, detail=True):
    c=Vector(base); start=len(g.v); n=48 if detail else 24; rows=10
    direction=Vector((math.cos(angle),math.sin(angle),0)); side=Vector((-direction.y,direction.x,0))
    # Both surfaces meet at a thin rolled edge; fan narrows into the side stem.
    for underside in [False,True]:
        for k in range(rows+1):
            r=max(.005,k/rows)
            for j in range(n+1):
                a=-1.38+2.76*j/n
                extent=radius*r*(1+.035*math.sin(a*8+angle))
                z=radius*(.20*r+.20*math.sin(math.pi*r))-(radius*.045 if underside else 0)
                g.v.append(tuple(c+direction*(extent*math.cos(a))+side*(extent*math.sin(a)*.87)+Vector((0,0,z))))
                g.uv[len(g.v)-1]=(j/n,r)
        offset=start+(rows+1)*(n+1)*int(underside)
        for k in range(rows):
            for j in range(n):
                q=offset+k*(n+1)+j; f=(q,q+1,q+n+2,q+n+1)
                g.face(f if underside else tuple(reversed(f)),2 if underside else 1)
    span=(rows+1)*(n+1)
    for j in range(n):
        q=start+rows*(n+1)+j;g.face((q,q+span,q+span+1,q+1),2)
    for j in [0,n]:
        for k in range(rows):
            q=start+k*(n+1)+j;g.face((q,q+n+1,q+n+1+span,q+span),2)
    if detail:
        for j in range(34):
            a=-1.32+2.64*j/33
            pts=[c+direction*(radius*r*math.cos(a))+side*(radius*r*math.sin(a)*.87)+Vector((0,0,radius*(.2*r+.2*math.sin(math.pi*r)-.052))) for r in [.08,.3,.6,.96]]
            g.tube(pts,[radius*.006]*4,2,4)
    anchor(g,start,c)


def morel(g, base, radius, height, detail=True):
    c=Vector(base);start=len(g.v)
    g.ellipsoid(c+Vector((0,0,height*.48)),(radius*.60,radius*.60,height*.48),4,12,24)
    rows=9 if detail else 3; columns=16 if detail else 8
    def point(t,a):
        r=radius*math.sin(math.pi*t)**.62*(1-.25*t)
        return c+Vector((r*math.cos(a),r*math.sin(a),t*height))
    for row in range(rows):
        t=(row+.5)/rows
        for col in range(columns):
            a=(col+(row%2)*.5)*TAU/columns
            ring=[point(max(.015,min(.985,t+math.sin(k*TAU/6)*.48/rows)),a+math.cos(k*TAU/6)*math.pi/columns*.94) for k in range(6)]
            # A recessed cell floor and thick rims produce visible honeycomb relief.
            mid=point(t,a);mid.x*=.79;mid.y*=.79
            si=len(g.v);g.v.extend([tuple(mid),*[tuple(p) for p in ring]])
            for k in range(6):g.face((si,si+1+k,si+1+(k+1)%6),1 if (col+row)%4 else 4)
            g.tube(ring+[ring[0]],[radius*.028]*7,3,4)
    anchor(g,start,c)


def mane(g, base, size, rng, detail=True):
    c=Vector(base);start=len(g.v)
    for lobe in range(5 if detail else 3):
        a=lobe*2.39996
        p=c+Vector((math.cos(a)*size*.30,math.sin(a)*size*.30,size*(.30+.15*(lobe%2))))
        g.ellipsoid(p,(size*.55,size*.50,size*.47),1,8,16)
        count=125 if detail else 30
        for k in range(count):
            theta=k*2.39996;z=1-2*(k+.5)/count;r=math.sqrt(max(0,1-z*z))
            q=p+Vector((math.cos(theta)*r*size*.52,math.sin(theta)*r*size*.48,z*size*.42))
            length=size*rng.uniform(.17,.40)*(1.0-.2*z)
            g.tube([q,q+Vector((math.cos(theta)*.008,math.sin(theta)*.008,-length*.55)),q+Vector((math.cos(theta)*.009,math.sin(theta)*.009,-length))],[size*.014,size*.010,.0002],3,4)
    anchor(g,start,c)


def build(idx, stage='mature', detail=True):
    form=BY_ID[idx][-1];rng=random.Random(idx*7919)
    g,b=Geometry(),Geometry()
    young=stage!='mature';factor=.24 if stage=='seedling' else .48 if young else 1.
    count=2 if young else 5 if form in ['funnel','amethyst','inkcap'] else 3
    if form in ['oyster','pink_oyster','shiitake','mane']:
        # Grounded, weathered hardwood substrate belongs to the model, so these
        # species also make sense when planted away from a scenery tree.
        g.tube([(-.15,0,.035),(0,0,.035),(.15,.015,.03)],[.032,.038,.028],5,16)
        for k in range(7):
            a=k*TAU/7
            g.tube([(-.13,math.sin(a)*.032,.035+math.cos(a)*.032),(.13,math.sin(a+.1)*.028,.03+math.cos(a+.1)*.028)],[.002,.001],4,4)
    if form=='mane':
        mane(b,(0,0,.095),.16*factor,rng,detail and not young)
        g.ellipsoid((0,0,.08),(.045,.04,.04),0,5,10)
    elif form in ['oyster','pink_oyster']:
        for k in range(3 if young else 8):
            angle=k*2.39996+.3;z=.075+k*.019*factor
            p=Vector((math.cos(angle)*.032,math.sin(angle)*.032,z))
            g.tube([(0,0,.04),p],[.013*factor,.008*factor],0,8)
            fan(b,p,(.095+(k%3)*.013)*factor,angle,form=='pink_oyster',detail and not young)
    else:
        for k in range(count):
            a=k*2.39996+.7;spread=.095 if count>3 else .09
            base=Vector((math.cos(a)*spread*math.sqrt(k/count),math.sin(a)*spread*math.sqrt(k/count),.0))
            if form=='shiitake':base.z=.045
            scale=(1.0 if k==0 else rng.uniform(.52,.83))*factor
            stem_h={'agaric':.21,'bolete':.14,'funnel':.16,'shiitake':.17,'morel':.10,'amethyst':.18,'inkcap':.22}[form]*scale
            radius={'agaric':.105,'bolete':.11,'funnel':.085,'shiitake':.10,'morel':.053,'amethyst':.055,'inkcap':.055}[form]*scale
            thick={'bolete':.035,'funnel':.013,'morel':.019,'agaric':.014}.get(form,.008)*scale
            tip=base+Vector((math.cos(a)*.015*scale,math.sin(a)*.015*scale,stem_h))
            g.tube([base,base.lerp(tip,.25),base.lerp(tip,.68),tip],[thick*.9,thick*1.12,thick*.8,thick*.7],0,14 if not young else 10)
            if form=='agaric':
                g.ellipsoid(base+Vector((0,0,thick*.7)),(thick*1.6,thick*1.6,thick*1.3),3,5,12)
                g.ellipsoid(base.lerp(tip,.72),(thick*1.9,thick*1.9,thick*.3),3,4,16)
            if form=='morel':morel(b,tip,radius,.16*scale,detail and not young)
            else:
                rise=radius*(.53 if form in ['agaric','bolete','shiitake'] else .5 if form=='funnel' else 1.45 if form=='inkcap' else .25)
                cap(b,tip,radius*(.67 if young and form!='inkcap' else 1),rise,form,random.Random(idx*7919+k*149),detail and not young)
    return g,b


def geometry(idx):
    g,b=build(idx);seed,sb=build(idx,'seedling');juv,jb=build(idx,'juvenile')
    # Early meshes contain stems plus closed small caps; runtime swaps them as one.
    def merge(a,b):
        offset=len(a.v);a.v+=b.v;a.f += [tuple(i+offset for i in f) for f in b.f];a.mi+=b.mi
        a.uv.update({i+offset:uv for i,uv in b.uv.items()})
    merge(seed,sb);merge(juv,jb)
    # Bud caps are independently closed around the same mature attachment sites.
    buds=build(idx,detail=False)[1]
    buds.v=[tuple(Vector(buds.fruit_anchors[i])+(Vector(v)-Vector(buds.fruit_anchors[i]))*.57) for i,v in enumerate(buds.v)]
    result=[g,b,buds,seed,juv]
    scale=BY_ID[idx][4]/max(p[2] for p in g.v+b.v)
    for geo in result:
        geo.v=[tuple(v*scale for v in p) for p in geo.v]
        if hasattr(geo,'fruit_anchors'):geo.fruit_anchors={i:tuple(v*scale for v in p) for i,p in geo.fruit_anchors.items()}
    return result
