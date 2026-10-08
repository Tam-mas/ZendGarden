"""Reference-led organ meshes for the flower collection, in metres and Z-up.

All early foliage is built independently: orchid plantlets have roots and fans,
bulbs have basal blades, herbs have their characteristic leaves, and shrubs
develop a progressively branched framework. Mature flowers retain their own
attachments so bud meshes appear where flowers subsequently open.
"""
import math, random
from functools import partial
from mathutils import Vector
from botanical_geometry import Geometry

TAU=math.tau
UP=Vector((0,0,1))

def frame(axis):
    n=Vector(axis).normalized()
    u=UP.cross(n).normalized() if abs(n.z)<.95 else Vector((1,0,0))
    return u,n.cross(u).normalized(),n

def petal(g,c,direction,length,width,mat=0,cup=.12,ruffle=.04,notch=0,low_detail=False,tiny=False):
    """Curved tapered blade with an explicit UV midrib and scalloped rim."""
    c=Vector(c);d=Vector(direction).normalized()
    side=d.cross(UP).normalized()
    if side.length<.01:side=Vector((1,0,0))
    normal=side.cross(d).normalized()
    if normal.z<0:normal=-normal
    rows=[];segments=3 if tiny and length<.012 else 8 if length>.025 and not low_detail else 4;columns=5 if length>.025 and not low_detail else 3
    for j in range(segments+1):
        t=j/segments
        w=width*math.sin(math.pi*t)**.65
        row=[]
        for k in range(columns):
            q=k/(columns-1)*2-1
            forward=length*t-notch*length*(1-abs(q))**4*t**12
            bend=length*cup*math.sin(math.pi*t)-abs(q)**1.7*w*.14
            bend+=ruffle*w*abs(q)**3*math.sin(t*25+q*12)
            p=c+d*forward+side*q*w+normal*bend
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=((q+1)/2,t)
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for k in range(columns-1):g.face((a[k],b[k],b[k+1],a[k+1]),mat)

def petal_in_plane(g,c,d,n,length,width,mat=0,cup=.12,ruffle=.04,notch=0,tiny=False):
    """Rotate the organ rather than making every bloom face the sky."""
    tmp=Geometry();petal(tmp,(0,0,0),(1,0,0),length,width,mat,cup,ruffle,notch,tiny=tiny)
    x=Vector(d).normalized();z=Vector(n).normalized();y=z.cross(x).normalized()
    if y.length<.01:y=UP.cross(x).normalized()
    z=x.cross(y).normalized();c=Vector(c);offset=len(g.v)
    g.v.extend(tuple(c+x*p[0]+y*p[1]+z*p[2]) for p in tmp.v)
    for face,mi in zip(tmp.f,tmp.mi):g.face(tuple(i+offset for i in face),mi)
    g.uv.update({i+offset:uv for i,uv in tmp.uv.items()})

def rays(g,c,axis,r,count,width=.32,mat=0,droop=0,ruffle=.04,notch=0,start=0,tiny=False):
    u,v,n=frame(axis)
    for k in range(count):
        a=start+k*TAU/count
        direction=u*math.cos(a)+v*math.sin(a)-n*droop
        petal_in_plane(g,c,direction,n,r,r*width,mat,.12,ruffle,notch,tiny=tiny)

def funnel(g,c,axis,r,length,mat=0,lobes=5,flare=.65,ruffle=.04,base_radius=.14,curve=0):
    c=Vector(c);u,v,n=frame(axis);offset=len(g.v);rings=9 if r>=.012 else 5;sides=30 if r>=.012 else 12
    for j in range(rings+1):
        t=j/rings
        for k in range(sides):
            a=k*TAU/sides
            radius=r*(base_radius+(1-base_radius)*((1-flare)*t+flare*t**3))*(1+.10*math.cos(a*lobes)*t**5)
            edge=length*t+ruffle*r*math.cos(a*lobes)*t**7
            p=c+n*edge+u*(curve*r*math.sin(math.pi*t))+(u*math.cos(a)+v*math.sin(a))*radius
            g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
    for j in range(rings):
        for k in range(sides):
            a=offset+j*sides+k;b=offset+j*sides+(k+1)%sides
            g.face((a,b,b+sides,a+sides),mat)

def stamens(g,c,axis,r,count=7,mat=2,low_detail=False):
    c=Vector(c);u,v,n=frame(axis)
    for k in range(count):
        a=k*2.39996;end=c+n*r*.35+(u*math.cos(a)+v*math.sin(a))*r*.15
        g.tube([c,end],[max(.00035,r*.015),max(.00025,r*.009)],mat,4 if low_detail else 5)
        g.ellipsoid(end,(r*.035,r*.035,r*.055),mat,2 if low_detail else 3 if r>=.012 else 2,5 if low_detail else 6 if r>=.012 else 5)

def orchid(g,c,axis,r,kind):
    c=Vector(c);u,v,n=frame(axis)
    narrow=kind=='spider'
    # Three sepals and two lateral petals, plus a separately shaped labellum.
    for a in [math.pi/2,7*math.pi/6,11*math.pi/6]:
        d=u*math.cos(a)+v*math.sin(a)
        petal_in_plane(g,c,d,n,r*(1.45 if narrow else .60 if kind=='oncidium' else 1),r*(.065 if narrow else .52 if kind=='slipper' and a==math.pi/2 else .25),4 if kind in ['zygo','slipper','spider'] else 0,.16,.08)
    for a in [.15,math.pi-.15]:
        d=u*math.cos(a)+v*math.sin(a)
        petal_in_plane(g,c,d,n,r*(1.4 if narrow or kind=='slipper' else .30 if kind=='bee' else .55 if kind=='oncidium' else .95),r*(.045 if narrow else .07 if kind=='bee' else .40 if kind in ['cattleya','pansy','vanda'] else .20),0,.18,.18 if kind=='cattleya' else .04)
    lip=c-v*r*.13+n*r*.08
    if kind=='slipper':
        # Hollow pouch with an open rim and hanging rounded lower bag.
        offset=len(g.v);rings=9;sides=24
        for j in range(rings+1):
            t=j/rings;rad=math.sin((t*.83+.13)*math.pi)*r*.43
            for k in range(sides):
                a=k*TAU/sides;p=lip-v*r*(.05+t*.8)+u*math.cos(a)*rad+n*(r*.23+math.sin(a)*rad*.65)
                g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
        for j in range(rings):
            for k in range(sides):
                a=offset+j*sides+k;b=offset+j*sides+(k+1)%sides;g.face((a,b,b+sides,a+sides),5)
    elif kind=='cattleya':funnel(g,lip,n-v*.35,r*.62,r*.53,5,6,.8,.22)
    elif kind=='bee':
        g.ellipsoid(lip-v*r*.35,(r*.25,r*.15,r*.32),5,8,12)
        for sign in [-1,1]:petal_in_plane(g,lip-v*r*.20,u*sign-v*.25,n,r*.35,r*.13,2,.12)
    elif kind in ['oncidium','spike']:
        for a,length in [(4.0,.7),(5.4,.7),(4.7,.9)]:
            petal_in_plane(g,lip,u*math.cos(a)+v*math.sin(a),n,r*length,r*.23,5,.1,.07)
    else:petal_in_plane(g,lip,-v+n*.15,n,r*(.85 if kind=='zygo' else .7),r*(.50 if kind in ['pansy','zygo'] else .33),5,.20,.12)
    g.ellipsoid(c+n*r*.15,(r*.08,r*.08,r*.16),1,5,8)
    # Orchid anthers and stigma are integrated into the central column.

def heart(g,c,r):
    c=Vector(c);offset=len(g.v);rings=16;sides=24
    for j in range(rings+1):
        t=j/rings;theta=math.pi*t
        for k in range(sides):
            a=k*TAU/sides
            outline_x=math.sin(a)**3
            outline_z=(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/17
            x=outline_x*math.sin(theta)*r*.80
            y=math.cos(theta)*r*.35
            z=outline_z*math.sin(theta)*r
            g.v.append(tuple(c+Vector((x,y,z))));g.uv[len(g.v)-1]=(k/sides,t)
    for j in range(rings):
        for k in range(sides):
            a=offset+j*sides+k;b=offset+j*sides+(k+1)%sides;g.face((a,b,b+sides,a+sides),0)
    petal(g,c-Vector((0,0,r*.7)),(0,0,-1),r*.55,r*.13,1,.2)

def flower(row,g,c,axis=(0,0,1),radius=None):
    idx=row['id'];r=radius or row['bloom_radius'];c=Vector(c);u,v,n=frame(axis)
    flower_stamens=partial(stamens,low_detail=idx>=198)
    flower_rays=partial(rays,tiny=idx>=198)
    if idx<158:
        kind=['cattleya','slipper','oncidium','pansy','vanda','zygo','spider','rock','bee','spike'][idx-148]
        orchid(g,c,axis,r,kind);return
    if idx==158:
        for ring in range(2):
            flower_rays(g,c+n*r*ring*.08,axis,r*(1-ring*.20),10,.10,0,-.05,.08,.20,start=ring*.28)
        flower_stamens(g,c,n,r,14);return
    if idx==172:
        flower_rays(g,c,axis,r*.90,3,.08,0,0,.01,start=math.pi/3)
        flower_rays(g,c,axis,r,3,.30,0,0,.10)
        for k in range(3):
            a=k*TAU/3;d=u*math.cos(a)+v*math.sin(a);side=n.cross(d)
            for step in range(9):
                t=.25+step*.065
                for sign in [-1,1]:
                    start=c+d*r*t+side*sign*r*.25*math.sin(math.pi*t)
                    end=start+side*sign*r*.15+d*r*.045
                    g.tube([start,end],[r*.010,r*.003],0,4)
        flower_stamens(g,c,n,r,6);return
    if idx==196:
        for a in [.5,2.64,3.45,5.97,4.71]:
            petal_in_plane(g,c,u*math.cos(a)+v*math.sin(a),n,r,r*.30,1 if a==4.71 else 0,.08,.03)
        flower_stamens(g,c,n,r,3);return
    if idx==191:
        # The astilbe head is an airy branching plume, not a compact pom-pom.
        for branch in range(12):
            t=branch/12;a=branch*2.39996
            start=c+n*(t-.3)*r*1.9
            tip=start+(u*math.cos(a)+v*math.sin(a))*r*(1-t)*.65+n*r*.20
            g.tube([start,tip],[r*.012,r*.004],3,5)
            for k in range(5):
                p=start.lerp(tip,(k+.4)/5)
                flower_rays(g,p,axis,r*.07,5,.32,0,.02)
        return
    if idx==189:heart(g,c,r);return
    if idx==182: # Snapdragon: a compressed tube and distinct upper/lower lips.
        funnel(g,c,axis,r*.50,r*.70,0,5,.45,.03)
        mouth=c+n*r*.70
        for a in [.85,2.29]:
            petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a)+n*.30,n,r*.70,r*.32,0,.25,.02)
        for a in [3.70,4.71,5.72]:
            petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a)+n*.15,n,r*.62,r*.31,0,.36,.02)
        g.ellipsoid(mouth-v*r*.20+n*r*.05,(r*.30,r*.20,r*.16),1,5,8)
        return
    if idx==214: # Correa: long pendent four-lobed tube, green-yellow mouth.
        funnel(g,c,axis,r*.72,r*2.7,0,4,.90,.04,.70)
        flower_rays(g,c+n*r*2.7,axis,r*.72,4,.20,4,-.05,.02)
        flower_stamens(g,c+n*r*2.55,n,r,4);return
    if idx==217: # Eremophila: curved tube and asymmetric two/three-lobed mouth.
        funnel(g,c,axis,r*.64,r*2.3,0,5,.80,.03,.55,.35)
        mouth=c+n*r*2.3
        for a in [.9,2.24,3.65,4.71,5.78]:
            petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a),n,r*.65,r*.18,0,.12,.02)
        flower_stamens(g,c+n*r*2.3,n,r,4);return
    if idx==200:
        offset=len(g.v);sides=10
        for j in range(7):
            t=j/6;radius=r*(.25+.70*math.sin(math.pi*t)**.7)
            for k in range(sides):
                a=k*TAU/sides;p=c+n*r*t*1.45+(u*math.cos(a)+v*math.sin(a))*radius
                g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
        for j in range(6):
            for k in range(sides):
                a=offset+j*sides+k;b=offset+j*sides+(k+1)%sides
                g.face((a,b,b+sides,a+sides),1)
        flower_rays(g,c+n*r*1.45,axis,r*.3,5,.23,1);return
    if idx==210:
        # A complete short raceme: many tiny four-lobed corollas around an upright axis.
        base=c-n*r*1.7;tip=c+n*r*1.7
        g.tube([base,tip],[r*.08,r*.025],3,5)
        for k in range(22):
            t=(k+.5)/22;a=k*2.39996
            out=u*math.cos(a)+v*math.sin(a)
            pos=base.lerp(tip,t)+out*r*.37
            flower_rays(g,pos,out,r*.20,4,.28,0)
            flower_stamens(g,pos,out,r*.25,2,1)
        return
    if idx==205:
        funnel(g,c-n*r*.1,axis,r*.24,r*.32,0,4,.3)
        flower_rays(g,c,axis,r,4,.17,0,-.22,.02);return
    if idx==208:
        flower_rays(g,c,axis,r*.75,5,.22,5,.08,.01)
        funnel(g,c,axis,r,r*1.6,1,5,.8,.02);return
    if idx==216:
        flower_rays(g,c,axis,r,5,.34,0,.03,.02)
        g.ellipsoid(c+n*r*.10,(r*.25,r*.25,r*.12),5,3,8)
        flower_stamens(g,c,n,r,8);return
    if idx in [176,177,192,199,203,209]:
        lobes=6 if idx in [176,177] else 4 if idx in [199,210] else 5
        funnel(g,c,axis,r,r*(1.75 if idx==192 else 1.05),0,lobes,.6,.04)
        flower_stamens(g,c+n*r*.7,n,r,lobes);return
    if idx==174: # Snowdrop: three long outer petals and three green-tipped inner ones.
        flower_rays(g,c,axis,r,3,.22,1,-.65,.02)
        flower_rays(g,c,axis,r*.55,3,.28,4,-.3,.02,start=math.pi/3);return
    if idx==173:
        flower_rays(g,c,axis,r,6,.38,0,.08);funnel(g,c,axis,r*.48,r*.65,2,6,.3,.14);return
    if idx==175:flower_rays(g,c,axis,r,6,.40,0,-.5,.03);flower_stamens(g,c,n,r,3);return
    if idx==179: # Lily of the valley bells have rolled, distinctly lobed mouths.
        funnel(g,c,axis,r,r*1.2,1,6,.20,.07);return
    if idx==188: # Columbine: outer sepals and five spurred petals.
        flower_rays(g,c,axis,r,5,.24,0,.08)
        flower_rays(g,c+n*r*.15,axis,r*.65,5,.26,1,-.30,start=math.pi/5)
        for k in range(5):
            a=k*TAU/5;start=c+(u*math.cos(a)+v*math.sin(a))*r*.45
            end=start-n*r*.8;g.tube([start,start-n*r*.6,end+u*r*.1],[r*.055,r*.035,r*.004],0,6)
        flower_stamens(g,c,n,r,8);return
    if idx==161: # Ragged robin: five deeply cut petals, each with four narrow fingers.
        for k in range(5):
            a=k*TAU/5
            for cut in range(4):
                turn=a+(cut-1.5)*.105
                petal_in_plane(g,c,u*math.cos(turn)+v*math.sin(turn),n,r,r*.065,0,.08,.02)
        flower_stamens(g,c,n,r,5);return
    if idx==193: # Tall garden phlox: five rounded lobes on a narrow throat.
        funnel(g,c-n*r*.2,n,r*.15,r*.3,0,5,.25)
        flower_rays(g,c,axis,r,5,.36,0,0,.04);return
    if idx==194:funnel(g,c,axis,r,r*1.3,0,5,.55,.06);return
    if idx==195:
        for k in range(6):
            a=k*TAU/6
            petal_in_plane(g,c,u*math.cos(a)+v*math.sin(a)+n*.18,n,r,r*.27,0,.35,.08)
        flower_stamens(g,c,n,r,6);return
    if idx==169: # Strawflower: overlapping, pointed papery bracts.
        for ring in range(4):flower_rays(g,c+n*r*ring*.07,axis,r*(1-ring*.16),16+ring*2,.12,0,-ring*.08,.02,start=ring*.2)
        g.ellipsoid(c+n*r*.2,(r*.20,r*.20,r*.13),2,6,12);return
    if idx==180: # Ranunculus: many concentric cupped petals rather than a daisy.
        for ring in range(6):flower_rays(g,c+n*r*ring*.08,axis,r*(1-ring*.12),9+ring,.32,0,-ring*.11,.08,start=ring*.4)
        return
    if idx in [165,166,167,186,187]:
        count={165:15,166:13,167:12,186:14,187:16}[idx]
        flower_rays(g,c,axis,r,count,.15,0,.32 if idx==165 else .05,.04)
        if idx==187:
            for ring in range(2):flower_rays(g,c+n*r*(.08+ring*.08),axis,r*(.8-ring*.2),count,.18,0,-.13,.06,start=.15+ring*.2)
        if idx==167:
            for k in range(count):
                a=k*TAU/count;d=u*math.cos(a)+v*math.sin(a)
                petal_in_plane(g,c+d*r*.56,d,n,r*.42,r*.105,2,.06,.03)
        g.ellipsoid(c+n*r*.10,(r*.32,r*.32,r*(.44 if idx==165 else .15)),5 if idx==166 else 2,8,14)
        for k in range(25):
            a=k*2.39996;distance=r*.27*math.sqrt((k+.5)/25)
            g.ellipsoid(c+n*r*.22+u*math.cos(a)*distance+v*math.sin(a)*distance,(r*.026,)*3,2,3,5)
        return
    if idx in [163,164,170,178,183,197,201,207,211]:
        # Individual florets, not an opaque ball substituting for a flower head.
        count=18 if idx not in [178,201] else 48 if idx==201 else 30
        for k in range(count):
            a=k*2.39996;distance=r*.80*math.sqrt((k+.3)/count)
            if idx in [178,201]:
                z=1-2*(k+.5)/count;s=math.sqrt(1-z*z)
                outward=(u*math.cos(a)*s+v*math.sin(a)*s+n*z).normalized()
                p=c+outward*r*.76
                flower_rays(g,p,outward,r*.23,6 if idx==178 else 5,.38 if idx==201 else .26,0,.03)
                if idx!=201:flower_stamens(g,p,outward,r*.23,3)
                continue
            lift=0 if idx==164 else math.sqrt(max(0,r*r-distance*distance))*.55
            p=c+u*math.cos(a)*distance+v*math.sin(a)*distance+n*lift
            flower_rays(g,p,axis,r*.18,4 if idx in [163,197] else 5,.27,0,.02)
            g.ellipsoid(p+n*r*.025,(r*.03,)*3,2,3,5)
        return
    if idx==212: # Fuchsia has reflexed sepals, a separate corolla and long stamens.
        funnel(g,c,axis,r*.24,r*.95,0,4,.85,.03,.85)
        tier=c+n*r*.95
        flower_rays(g,tier,axis,r,4,.17,0,.5,.04)
        funnel(g,tier,n,r*.5,r*.7,5,4,.50,.04)
        for k in range(8):
            a=k*TAU/8;end=c+n*r*2.10+(u*math.cos(a)+v*math.sin(a))*r*.13
            g.tube([c,end],[r*.012,r*.008],1,5);g.ellipsoid(end,(r*.025,)*3,2,3,5)
        return
    if idx==198: # Hibiscus staminal column projects conspicuously beyond five petals.
        flower_rays(g,c,axis,r,5,.44,0,-.1,.12)
        g.tube([c,c+n*r*1.05],[r*.05,r*.028],2,8)
        flower_stamens(g,c+n*r*.70,n,r,12);return
    count=max(3,min(12,int(row['petals'])))
    flower_rays(g,c,axis,r,count,.25 if idx in [171,172] else .34,0,.03,.05,.10 if idx in [158,159,160] else 0)
    flower_stamens(g,c,n,r,8 if idx in [168,213,216] else 6)

def foliage(row,phase='mature'):
    g=Geometry();h=row['height'];idx=row['id'];kind=row['foliage']
    juvenile=phase!='mature';scale=.17 if phase=='seedling' else .48 if phase=='juvenile' else 1
    h*=scale
    woody=idx>=198
    points=[];g.attachment_paths=[]
    blade=partial(petal,low_detail=woody)
    green=1;young=2
    def leaf(base,angle,length,style=kind,material=green):
        if idx>=198:
            style={198:'lobed',201:'lobed',213:'compound',214:'round',215:'compound',216:'linear',217:'linear'}.get(idx,'opposite')
        base=Vector(base);d=Vector((math.cos(angle),math.sin(angle),.18))
        if idx==179:style='round' # Broad elliptical Lily-of-the-valley leaves.
        if idx==197:
            g.leaf(base,base+d*length,length*.40,material,.18,8,True)
            return
        if idx==188:
            junction=base+d*length*.2
            g.tube([base,junction],[max(.0005,length*.009),.0003],0,5)
            for turn in [-.70,0,.70]:
                direction=Vector((math.cos(angle+turn),math.sin(angle+turn),.15))
                g.leaf(junction,junction+direction*length*.70,length*.19,material,.13,7,True)
            return
        if idx in [190,213]:
            # Palmate hellebore leaves and ternate Choisya leaves share a junction.
            junction=base+d*length*.25
            g.tube([base,junction],[max(.0005,length*.009),.0003],0,5)
            angles=[-.68,0,.68] if idx==213 else [(-3+k)*.32 for k in range(7)]
            for turn in angles:
                blade(g,junction,(math.cos(angle+turn),math.sin(angle+turn),.15),length*(.68 if idx==213 else .78-abs(turn)*.15),length*(.14 if idx==213 else .09),material,.13,.035)
            return
        if style in ['strap','bulb','linear']:

            blade(g,base,(d.x*.35,d.y*.35,.95),length,length*.05,material,.20,.01)
        elif style in ['compound','fern','pinnate']:
            tip=base+d*length;g.tube([base,tip],[max(.0005,length*.008),.0003],0,5)
            for k in range(5):
                p=base.lerp(tip,.2+k*.15)
                for sign in [-1,1]:blade(g,p,(math.cos(angle+sign*.95),math.sin(angle+sign*.95),.14),length*.32,length*.065,material,.12)
        elif style in ['lobed','palmate']:
            for k in range(5):
                a=angle+(k-2)*.35;blade(g,base,(math.cos(a),math.sin(a),.2),length*(1-abs(k-2)*.14),length*.13,material,.18)
        elif style in ['heart','round']:
            blade(g,base,d,length,length*.38,material,.13,.04)
        else:blade(g,base,d,length,length*.18,material,.14,.035)
    if idx<158:
        count=3 if phase=='seedling' else 6 if phase=='juvenile' else 10
        monopodial=idx==152;no_bulb=idx in [149,156,157]
        clusters=1 if juvenile else 3 if idx not in [152,149,156,157] else 1
        for cluster in range(clusters):
            a=cluster*2.39996;base=Vector((math.cos(a)*h*.13,math.sin(a)*h*.13,0))
            if idx==155:
                g.tube([base,base+UP*h*.18,base+UP*h*.38],[h*.065,h*.072,h*.040],1,10)
            elif not monopodial and not no_bulb:g.ellipsoid(base+UP*h*.09,(h*.065,h*.055,h*.09),1,6,10)
            if monopodial:g.tube([base,base+UP*h*.70],[h*.035,h*.018],0,8)
            leaf_count=1 if idx==148 else 3 if idx==155 else count
            for k in range(leaf_count):
                a=k*math.pi+(k%3-1)*.12 if idx in [149,151,153] else k*math.pi if idx==152 else k*2.39996+cluster
                z=h*.38 if idx==155 else h*(.11+(k%3)*.022) if not monopodial else h*(.12+k*.055)
                baseleaf=base+UP*z
                direction=(math.cos(a)*.65,math.sin(a)*.65,.40 if k%2 else .70)
                blade(g,baseleaf,direction,h*(.42 if idx in [156,157] else .64)*random.uniform(.78,1.08),h*(.045 if idx in [156,157] else .07),1 if k<count-2 else 2,.12,.015)
            # Exposed orchid roots have pale velamen with live green tips.
            for k in range(3 if juvenile else 7):
                a=k*2.39996;end=base+Vector((math.cos(a)*h*.2,math.sin(a)*h*.2,.008))
                root_start=base+UP*h*(.38 if monopodial else .08)
                root_mid=(root_start+end)*.5+Vector((math.cos(a)*h*.045,math.sin(a)*h*.045,0))
                g.tube([root_start,root_mid,end],[h*.013,h*.009,h*.003],3,6)
        return g,points
    if woody:
        from flower_bush_geometry import bush_foliage
        return bush_foliage(row,phase)
    bulb=idx in [173,174,175,176,177,178,179,180,181]
    basal=bulb or kind in ['strap','rosette','heart'] or idx in [170,171,172,190,196,197]
    if basal:
        count=3 if phase=='seedling' else 6 if phase=='juvenile' else 10
        for k in range(count):
            a=k*2.39996;ll=h*(.68 if bulb else .48)*random.uniform(.8,1.1)
            leaf((math.cos(a)*.015,math.sin(a)*.015,.01),a,ll,'strap' if bulb and idx not in [179,180,181] else kind,2 if k>count-3 else 1)
    if phase=='seedling' and basal:return g,points
    stems=1 if phase=='seedling' else 2 if phase=='juvenile' else row['flower_count'] if idx in [173,174,175] else 3 if basal else 5
    for k in range(stems):
        a=k*2.39996;tip=Vector((math.cos(a)*h*.16,math.sin(a)*h*.16,h*(.74+k*.035)))
        g.tube([(0,0,0),tip*.4+Vector((h*.035,0,0)),tip],[max(.001,h*.011),max(.0006,h*.007),max(.0003,h*.003)],0,7)
        if not basal:
            nodes=2 if phase=='seedling' else 3 if phase=='juvenile' else 5
            for j in range(nodes):
                p=tip*(.20+j*.12)
                for sign in [-1,1]:leaf(p,a+j*1.7+sign*math.pi,h*(.18-j*.018),material=2 if j==nodes-1 else 1)
        points.append((tip,Vector((math.cos(a)*.2,math.sin(a)*.2,1)).normalized()))
    return g,points

def mature(row):
    g,anchors=foliage(row);b=Geometry();buds=Geometry();h=row['height'];idx=row['id']
    count=row['flower_count'];r=row['bloom_radius'];centres=[]
    hanging=idx in [174,177,179,189,194,200,212,214]
    spikes=idx in [155,157,176,177,182,184,192,194,200,210]
    if idx<158:
        branches=1 if idx in [149,156] else 2 if idx in [148,151,152,153,154] else 3
        for branch in range(branches):
            angle=branch*2.39996
            base=Vector((math.cos(angle)*h*.09,math.sin(angle)*h*.09,h*(.38 if idx==155 else .26 if idx==150 else .15)))
            tip=base+Vector((math.cos(angle)*h*.18,math.sin(angle)*h*.18,h*(.78 if idx==150 else .68)))
            g.tube([base,base.lerp(tip,.5)+Vector((h*.025,0,0)),tip],[h*.011,h*.007,h*.002],0,8)
            per=max(1,math.ceil(count/branches))
            for k in range(per):
                a=angle+k*1.6
                mid=base.lerp(tip,.5)+Vector((h*.025,0,0))
                p=mid.lerp(tip,.86*(k+.5)/per)
                offset=Vector((math.cos(a)*r*.9,math.sin(a)*r*.9,.015))
                if idx==150:offset*=1.5
                c=p+offset;g.tube([p,c],[max(.0005,h*.004),.0004],0,6)
                centres.append((c,Vector((math.cos(a),math.sin(a),.20))))
    elif idx>=198:
        from flower_bush_geometry import bush_blooms
        centres=bush_blooms(row,g,anchors)
    else:
        for k in range(count):
            tip,axis=anchors[k%len(anchors)];a=(k%len(anchors))*2.39996 if idx==177 else k*2.39996
            if spikes:
                level=.44+.50*((k//len(anchors)+.5)/math.ceil(count/len(anchors)))
                # Follow the exact bent stem path used by foliage(), avoiding gaps.
                midpoint=tip*.4+Vector((h*.035,0,0))
                start=midpoint.lerp(tip,(level-.4)/.6)
                c=start+Vector((math.cos(a)*r*.75,math.sin(a)*r*.75,0))
                axis=-UP if hanging else Vector((math.cos(a),math.sin(a),.4))
            elif hanging:
                start=tip;layer=k//len(anchors)
                if idx==189:
                    heading=(k%len(anchors))*2.39996
                    reach=(layer+1)*r*2.5
                    c=tip+Vector((math.cos(heading)*reach,math.sin(heading)*reach,-r*.30*layer*layer))
                else:c=tip+Vector((math.cos(a)*r*1.4,math.sin(a)*r*1.4,-layer*r*1.7))
                axis=-UP
            else:
                start=tip;layer=k//len(anchors)
                spread=r*(.7+math.sqrt(layer)*1.2)
                c=tip+Vector((math.cos(a)*spread,math.sin(a)*spread,-layer*r*.30))
            g.tube([start,(start+c)*.5+UP*r*.13,c],[max(.0004,h*.004),max(.0003,h*.002),.00035],0,5)
            centres.append((c,axis))
    b.fruit_anchors={};buds.fruit_anchors={}
    for placement in centres:
        c,axis=placement[:2]
        r=placement[2] if len(placement)==3 else row['bloom_radius']
        first=len(b.v);first_bud=len(buds.v)
        flower(row,b,c,axis,r)
        b.fruit_anchors.update({i:tuple(c) for i in range(first,len(b.v))})
        n=Vector(axis).normalized()
        # Compound flower heads retain their silhouettes while their florets are closed.
        if idx in [201,210]:
            if idx==201:
                for k in range(18):
                    z=1-2*(k+.5)/18;a=k*2.39996;reach=math.sqrt(1-z*z)
                    place=c+Vector((math.cos(a)*reach,math.sin(a)*reach,z))*r*.68
                    buds.ellipsoid(place,(r*.10,)*3,1,2,5)
            else:
                buds.tube([c-n*r*1.7,c+n*r*1.7],[r*.07,r*.03],1,4)
                u,v,_=frame(axis)
                for k in range(14):
                    a=k*2.39996;place=c+n*r*(-1.5+3*(k+.5)/14)+(u*math.cos(a)+v*math.sin(a))*r*.28
                    buds.ellipsoid(place,(r*.13,r*.13,r*.21),0,2,5)
        else:
            centre=c+n*r*.13
            buds.ellipsoid(centre,(r*.18,r*.18,r*.32),0,3 if idx>=198 else 4,6 if idx>=198 else 8)
            for k in range(2 if idx>=198 else 4):
                a=k*TAU/(2 if idx>=198 else 4);u,v,_=frame(axis)
                buds.leaf(c,c+(u*math.cos(a)+v*math.sin(a)+n*1.8)*r*.22,r*.06,1,.10,3 if idx>=198 else 4)
        buds.fruit_anchors.update({i:tuple(c) for i in range(first_bud,len(buds.v))})
    assert g.v and b.v and buds.v,row['name']
    # One metre-based envelope shared by full foliage, flowers and closed buds.
    actual=max(p[2] for p in g.v+b.v)
    factor=h/actual
    for mesh in [g,b,buds]:
        mesh.v=[tuple(Vector(p)*factor) for p in mesh.v]
        if hasattr(mesh,'fruit_anchors'):mesh.fruit_anchors={i:tuple(Vector(p)*factor) for i,p in mesh.fruit_anchors.items()}
    return g,b,buds
