"""Second mushroom collection: cups, brackets, stars, spore bodies and coral.

Side-effect-free geometry for append-only IDs 288–297. All colour bands and
species relief are actual mesh surfaces, using the established rigid PBR maps.
"""
import math
import random
from mathutils import Vector
from botanical_geometry import Geometry
from mushroom_geometry import anchor, cap
from mushroom_data import BY_ID
TAU=math.tau


def palette(idx):
    _,name,_,color,_,_,form=BY_ID[idx]
    stem={'milkcap':'d79b58','verdigris':'9abbb2','blewit':'b8a3c4','trumpet':'746e67','coral':'c9a45d'}.get(form,'ddd0b9')
    underside={'elf_cup':'d43a29','milkcap':'d98539','verdigris':'80788a','blewit':'b6a3c0','trumpet':'413c3b','coral':'efd483'}.get(form,'e9dfcb')
    colors=[stem,color,underside,'e8ddc7','5a4939','84654d','b79669','6b6663','b4a99a','dbcbb1']
    if form=='parasol':colors[3]='8d6847';colors[1]='e4d9c5'
    if form=='milkcap':colors[3]='ad6a35';colors[4]='71927b'
    if form=='earthstar':colors[1]='b59d79';colors[3]='90765b'
    if form=='turkey_tail':colors[3]='e9e1d1';colors[4]='61524c'
    if form=='trumpet':colors[3]='91877d';colors[4]='282625'
    if form=='coral':colors[3]='f0ce73'
    labels=['stem tissue','cap surface','inner surface','surface detail','recesses','wood','ochre band','slate band','grey band','buff band']
    return {key:[(name+' '+label,col,'smooth',False) for label,col in zip(labels,colors)] for key in ['foliage','bloom']}


def lathe(g, center, profile, radius, height, materials, phase=0, detail=True):
    """Closed wall following (radius,height) points, including cup interiors."""
    c=Vector(center);start=len(g.v);n=64 if detail else 24
    for row,(r,z) in enumerate(profile):
        for j in range(n):
            a=j*TAU/n;w=1+.025*math.sin(a*5+phase)+.012*math.sin(a*11-phase)
            p=c+Vector((radius*r*w*math.cos(a),radius*r*w*math.sin(a),height*z+.012*radius*r*math.sin(a*7+phase)))
            g.v.append(tuple(p));g.uv[len(g.v)-1]=(j/n,row/(len(profile)-1))
    for row in range(len(profile)-1):
        for j in range(n):
            g.face((start+row*n+j,start+row*n+(j+1)%n,start+(row+1)*n+(j+1)%n,start+(row+1)*n+j),materials[row])
    g.face(tuple(start+j for j in reversed(range(n))),materials[0])
    g.face(tuple(start+(len(profile)-1)*n+j for j in range(n)),materials[-1])
    anchor(g,start,c)


def cup(g,c,r,h,trumpet=False,detail=True,phase=0):
    if trumpet:
        profile=[(.08,0),(.16,.23),(.29,.50),(.51,.77),(.76,.92),(1.,1.),(.97,.94),(.72,.85),(.48,.69),(.26,.40),(.07,.12)]
        mats=[1]*5+[3]+[4]*4
    else:
        profile=[(.05,0),(.33,.04),(.64,.21),(.88,.50),(1.,.85),(1.01,1.),(.94,.98),(.84,.56),(.59,.29),(.25,.18),(.02,.18)]
        mats=[0]*5+[3]+[1]*4
    lathe(g,c,profile,r,h,mats,phase,detail)


def bracket(g,center,radius,angle,detail=True):
    c=Vector(center);start=len(g.v);n=48 if detail else 20;rows=16 if detail else 8
    forward=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-forward.y,forward.x,0))
    for lower in [False,True]:
        for row in range(rows+1):
            r=max(.005,row/rows)
            for j in range(n+1):
                a=-1.53+3.06*j/n;wave=.035*math.sin(a*7+angle)+.018*math.sin(a*13-angle)
                length=radius*r*(1+wave)
                z=radius*(.06*math.sin(r*math.pi)+wave*r*.3-.025*int(lower))
                g.v.append(tuple(c+forward*length*math.cos(a)+side*length*math.sin(a)+Vector((0,0,z))))
                g.uv[len(g.v)-1]=(j/n,r)
        offset=start+int(lower)*(rows+1)*(n+1)
        bands=[4,7,8,6,1,9,7,6,8,4,1,6,9,7,9,3]
        for row in range(rows):
            mi=2 if lower else bands[min(15,int(row/rows*16))]
            for j in range(n):
                q=offset+row*(n+1)+j;f=(q,q+1,q+n+2,q+n+1)
                g.face(f if lower else tuple(reversed(f)),mi)
    span=(rows+1)*(n+1)
    for j in range(n):
        q=start+rows*(n+1)+j;g.face((q,q+span,q+span+1,q+1),3)
    for j in [0,n]:
        for row in range(rows):
            q=start+row*(n+1)+j;g.face((q,q+n+1,q+n+1+span,q+span),2)
    anchor(g,start,c)


def spore_body(g,center,radius,height,form,detail=True):
    c=Vector(center);start=len(g.v)
    if form=='puffball':
        profile=[(.12,0),(.29,.15),(.37,.32),(.78,.43),(1.,.65),(.94,.83),(.61,.97),(.12,1.),(.035,.97)]
        lathe(g,c,profile,radius,height,[1]*7+[4],detail=detail)
        if detail:
            for k in range(240):
                a=k*2.39996;z=.38+.59*(k+.5)/240
                row=next(i for i in range(7) if profile[i][1]<=z<=profile[i+1][1])
                lo,hi=profile[row],profile[row+1];t=(z-lo[1])/(hi[1]-lo[1])
                r=(lo[0]+(hi[0]-lo[0])*t)*radius*(1+.025*math.sin(a*5)+.012*math.sin(a*11))
                p=c+Vector((r*math.cos(a),r*math.sin(a),height*z))
                normal=Vector((math.cos(a),math.sin(a),(z-.62)*2)).normalized()
                g.tube([p,p+normal*radius*.075],[radius*.018,.0001],3,5)
    else:
        g.ellipsoid(c+Vector((0,0,height*.59)),(radius*.50,radius*.50,height*.43),1,14 if detail else 7,32 if detail else 16)
        # A dark apical pore and its raised collar, visible in the portrait.
        g.ellipsoid(c+Vector((0,0,height*1.01)),(radius*.07,radius*.07,height*.015),4,4,12)
        for ray in range(7):
            a=ray*TAU/7;forward=Vector((math.cos(a),math.sin(a),0));side=Vector((-forward.y,forward.x,0))
            s=len(g.v);rows=12 if detail else 6
            for lower in [False,True]:
                for j in range(rows+1):
                    t=j/rows;rr=radius*(.16+1.30*t)
                    z=height*(.17+.25*math.sin(math.pi*t)-.13*t)
                    width=radius*.32*math.sin(math.pi*(t*.95+.025))**.65
                    for q in [-1,0,1]:
                        g.v.append(tuple(c+forward*rr+side*width*q+Vector((0,0,z+(height*.035*(1-abs(q)) if not lower else -height*.05)))))
                        g.uv[len(g.v)-1]=((q+1)/2,t)
                off=s+int(lower)*(rows+1)*3
                for j in range(rows):
                    for band in range(2):
                        q=off+j*3+band;f=(q,q+1,q+4,q+3)
                        g.face(tuple(reversed(f)) if lower else f,3 if lower else 0 if band else 9)
            span=(rows+1)*3
            for j in range(rows):
                for edge in [0,2]:
                    q=s+j*3+edge;g.face((q,q+3,q+3+span,q+span),3)
            if detail:
                for j in range(3):
                    t=.3+j*.18;p=c+forward*radius*(.16+1.30*t)+Vector((0,0,height*(.17+.25*math.sin(math.pi*t)-.13*t)+height*.035))
                    g.tube([p-side*radius*.06,p+side*radius*.04+forward*.008],[.0012,.0008],3,4)
    anchor(g,start,c)


def coral(g,center,rng,detail=True):
    c=Vector(center);start=len(g.v)
    def branch(p,angle,length,width,depth):
        end=p+Vector((math.cos(angle)*length*.55,math.sin(angle)*length*.55,length))
        mid=p.lerp(end,.5)+Vector((math.cos(angle+.7)*length*.08,math.sin(angle+.7)*length*.08,0))
        g.tube([p,mid,end],[width,width*.83,width*.55],1 if depth else 3,8 if detail else 5)
        if depth:
            splits=3 if depth==3 else 2
            for split in range(splits):branch(end,angle+(split-(splits-1)/2)*1.25+rng.uniform(-.25,.25),length*rng.uniform(.55,.70),width*.62,depth-1)
        else:
            for fork in [-1,1]:
                tip=end+Vector((math.cos(angle+fork)*.009,math.sin(angle+fork)*.009,.014))
                g.tube([end,tip],[width*.55,.0004],3,5)
    for k in range(9 if detail else 5):
        a=k*2.39996;p=c+Vector((math.cos(a)*.055,math.sin(a)*.055,0))
        branch(p,a,.045+(.012*(k%3)),.009,3 if detail else 2)
    anchor(g,start,c)


def build(idx,stage='mature',detail=True):
    form=BY_ID[idx][-1];g,b=Geometry(),Geometry();rng=random.Random(idx*829)
    young=stage!='mature';count=2 if young else 3
    if form in ['turkey_tail','elf_cup']:
        g.tube([(-.14,0,.028),(0,0,.032),(.14,.012,.025)],[.026,.031,.023],5,14)
        for k in range(5):
            a=k*TAU/5
            g.tube([(-.13,math.sin(a)*.025,.028+math.cos(a)*.025),(.13,math.sin(a)*.023,.025+math.cos(a)*.023)],[.0018,.001],4,4)
    elif form in ['puffball','earthstar','coral']:g.ellipsoid((0,0,.009),(.012,.010,.009),0,5,12)
    if form=='turkey_tail':
        for k in range(3 if young else 9):
            a=k*2.39996
            p=Vector((math.cos(a)*.028,math.sin(a)*.028,.035+k*.009))
            bracket(b,p,.10+(k%3)*.012,a,detail and not young)
    elif form=='coral':coral(b,(0,0,.018),rng,detail and not young)
    else:
        for k in range(count if form!='earthstar' else 1 if young else 2):
            a=k*2.39996+.4;size=1. if k==0 else rng.uniform(.60,.77)
            base=Vector((math.cos(a)*.08*math.sqrt(k/3),math.sin(a)*.08*math.sqrt(k/3),.0))
            if form=='elf_cup':
                base.z=.04;g.tube([base,base+Vector((0,0,.014))],[.009,.007],0,8)
                cup(b,base+Vector((0,0,.014)),.064*size*(.7 if young else 1),.060*size,detail=detail and not young,phase=k)
            elif form in ['puffball','earthstar']:
                spore_body(b,base+Vector((0,0,.014)),(.060 if form=='puffball' else .074)*size,(.135 if form=='puffball' else .09)*size,form,detail and not young)
            elif form=='trumpet':
                g.tube([base,base+Vector((0,0,.025*size))],[.012*size,.010*size],0,9)
                cup(b,base+Vector((0,0,.025*size)),.065*size,.155*size,True,detail and not young,k)
            else:
                h={'parasol':.28,'milkcap':.12,'verdigris':.19,'blewit':.13}[form]*size
                r={'parasol':.12,'milkcap':.105,'verdigris':.075,'blewit':.105}[form]*size
                width={'parasol':.012,'milkcap':.021,'verdigris':.011,'blewit':.025}[form]*size
                tip=base+Vector((math.cos(a)*.011,math.sin(a)*.011,h))
                g.tube([base,base.lerp(tip,.25),base.lerp(tip,.72),tip],[width*1.1,width,width*.80,width*.73],0,14)
                if form in ['parasol','verdigris']:
                    g.ellipsoid(base.lerp(tip,.70),(width*1.9,width*1.9,width*.27),0,4,18)
                start=len(b.v)
                capform='shiitake' if form=='parasol' else 'agaric' if form=='verdigris' else 'funnel' if form=='milkcap' else 'blewit'
                cap(b,tip,r*(.7 if young else 1),r*(.28 if form=='parasol' else .42 if form=='verdigris' else .33),capform,random.Random(idx*401+k),detail and not young)
                if detail and not young and form=='milkcap':
                    # Concentric orange zoning follows the funnel surface.
                    for ring in [.35,.52,.70,.88]:
                        pts=[]
                        for j in range(65):
                            angle=j*TAU/64
                            z=r*.33*(max(0,ring-.38)*.89)
                            pts.append(tip+Vector((r*ring*math.cos(angle),r*ring*math.sin(angle),z+.001)))
                        b.tube(pts,[r*.007]*len(pts),3,4)
                    anchor(b,start,tip)
    factor=.16 if stage=='seedling' else .30 if young else 1.
    if young:
        for geo in [g,b]:
            geo.v=[tuple(v*factor for v in p) for p in geo.v]
            if hasattr(geo,'fruit_anchors'):geo.fruit_anchors={i:tuple(v*factor for v in p) for i,p in geo.fruit_anchors.items()}
    return g,b


def geometry(idx):
    g,b=build(idx);seed,sb=build(idx,'seedling');juv,jb=build(idx,'juvenile')
    for a,part in [(seed,sb),(juv,jb)]:
        offset=len(a.v);a.v+=part.v;a.f += [tuple(i+offset for i in f) for f in part.f];a.mi+=part.mi
        a.uv.update({i+offset:uv for i,uv in part.uv.items()})
    buds=build(idx,detail=False)[1]
    result=[g,b,buds,seed,juv];scale=BY_ID[idx][4]/max(p[2] for p in g.v+b.v)
    for geo in result:
        geo.v=[tuple(v*scale for v in p) for p in geo.v]
        if hasattr(geo,'fruit_anchors'):geo.fruit_anchors={i:tuple(v*scale for v in p) for i,p in geo.fruit_anchors.items()}
    return result
