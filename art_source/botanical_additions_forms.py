"""Botanical organs for ten grasses, twenty succulents and two revised climbers.
Opaque closed fleshy leaves, true cactus ribs/areoles and curved petal surfaces.
All coordinates are metres, Z up. Seeded randomness is supplied by the builder.
"""
import math, random
from math import sin, cos, pi, sqrt
from mathutils import Vector
from botanical_geometry import Geometry
from botanical_forms import radial, tendril

def flesh(g,base,tip,width,thickness,mat=1,pointed=True,red_tip=False):
    """Closed, tapered succulent leaf; shared smooth normals, no intersecting sheets."""
    base,tip=Vector(base),Vector(tip);d=tip-base
    side=d.cross(Vector((0,0,1))).normalized()
    if side.length<.01:side=Vector((1,0,0))
    up=side.cross(d.normalized()).normalized()
    if up.z<0:up=-up
    rows=[];segments=12;sides=10
    samples=[j/segments for j in range(segments+1)]
    if not pointed:samples=sorted(samples+[.96,.99])
    for j,t in enumerate(samples):
        center=base+d*t+up*(sin(pi*t)*d.length*.10)
        row=[]
        count=1 if t in [0,1] else sides
        for k in range(count):
            a=k*2*pi/sides
            profile=sin(pi*t)**(.90 if pointed else .46)
            p=center+side*(cos(a)*width*profile)+up*(sin(a)*thickness*profile)
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
        rows.append(row)
    for j,(left,right) in enumerate(zip(rows,rows[1:])):
        for k in range(sides):
            n=(k+1)%sides
            t=samples[j]
            m=4 if red_tip and (t>=.91 or t>.20 and abs(cos((k+.5)*2*pi/sides))>.83) else mat
            if len(left)==1:g.face((left[0],right[k],right[n]),m)
            elif len(right)==1:g.face((left[k],right[0],left[n]),m)
            else:g.face((left[k],right[k],right[n],left[n]),m)

def petal(g,center,forward,side,normal,length,width,mat=0,rounded=False):
    """Non-degenerate triangulated petal with a rounded cup in a chosen flower plane."""
    center=Vector(center);forward=Vector(forward);side=Vector(side);normal=Vector(normal)
    rows=[];segments=14;cols=7
    for j in range(segments+1):
        t=j/segments;row=[];count=1 if j in [0,segments] else cols
        profile=sin(pi*t)**(.48 if rounded else .85)
        for k in range(count):
            q=0 if count==1 else k/(cols-1)*2-1
            p=center+forward*(length*t)+side*(q*width*profile)
            p+=normal*(length*.13*sin(pi*t)+width*.16*q*q*profile)
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=((q+1)*.5,t)
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for k in range(cols-1):
            if len(a)==1:g.face((a[0],b[k],b[k+1]),mat)
            elif len(b)==1:g.face((a[k],b[0],a[k+1]),mat)
            else:
                g.face((a[k],b[k],b[k+1]),mat)
                g.face((a[k],b[k+1],a[k+1]),mat)

def flower_plane(p):
    normal=Vector((p.x,p.y,.28)).normalized()
    right=normal.cross(Vector((0,0,1))).normalized()
    up=right.cross(normal).normalized()
    return normal,right,up

def clematis_flower(g,p,size):
    p=Vector(p);normal,right,up=flower_plane(p)
    for j in range(6):
        a=j*2*pi/6;direction=right*cos(a)+up*sin(a)
        tangent=-right*sin(a)+up*cos(a)
        petal(g,p+direction*size*.07,direction,tangent,normal,size*.95,size*.29)
    # Cream stamens are a tuft of fine filaments, not a large flat disk.
    for j in range(36):
        a=j*2.39996;r=size*.18*sqrt((j+.5)/36)
        base=p+right*(cos(a)*r)+up*(sin(a)*r)
        end=base+normal*size*(.19+.10*(1-r/(size*.18)))
        g.tube([base,end],[.0012,.0007],1,4)
        g.ellipsoid(end,(.002,.002,.004),1,3,5)

def sweet_pea_flower(g,p,size):
    p=Vector(p);normal,right,up=flower_plane(p)
    # Banner, two wings and folded paired keel: the five papilionaceous petals.
    petal(g,p+up*size*.03,up,right,normal,size*1.05,size*.70,0,True)
    for sign in [-1,1]:
        direction=(right*sign*.80-up*.45).normalized()
        tangent=(up*.80+right*sign*.45).normalized()
        petal(g,p+normal*size*.09,direction,tangent,normal,size*.77,size*.28,0,True)
        petal(g,p+normal*size*.20-up*size*.02,-up,right*sign,normal,size*.53,size*.14,0,True)

def climber(name,g,b):
    for j in range(4):
        a=j*pi/2;points=[radial(a+k*.6,.13+k*.012,k*.15) for k in range(10)]
        g.tube(points,[.005-k*.00035 for k in range(10)],0,4)
        for k in range(2,10):
            p=points[k];aa=a+k*.7
            if name=='Sweet pea':
                for sign in [-1,1]:g.leaf(p,p+radial(aa+sign*.7,.15,.03),.055,1,.1,4)
                tendril(g,p,aa)
            else:
                for sign in [-1,0,1]:g.leaf(p,p+radial(aa+sign*.8,.18,.04),.06,1,.15,4)
            if k%2:
                end=p+radial(aa,.14,.03)
                g.tube([p,end],[.0025,.0014],0,5)
                if name=='Sweet pea':sweet_pea_flower(b,end,.10)
                else:clematis_flower(b,end,.17)

def grass_blade(g,base,a,height,spread,width,mat=1,banded=False,blood=False):
    base=Vector(base);side=radial(a+pi/2,1);rows=[];segments=20
    for j in range(segments+1):
        t=j/segments;center=base+radial(a,spread*t*t,height*(sin(t*pi*.65)/sin(pi*.65)))
        # The last third droops on arching forms rather than ending in straight spikes.
        if spread>height*.55:center.z-=height*.24*t**4
        w=width*(sin(pi*(t*.96+.02))**.70)*(1-.30*t)
        count=1 if j in [0,segments] else 3;row=[]
        for k in range(count):
            q=0 if count==1 else k-1
            p=center+side*q*w+Vector((0,0,-abs(q)*w*.22))
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=((q+1)*.5,t)
        rows.append(row)
    for j,(left,right) in enumerate(zip(rows,rows[1:])):
        m=4 if banded and (j+2)%5==0 or blood and j>9 else mat
        for k in range(2):
            if len(left)==1:g.face((left[0],right[k+1],right[k]),m)
            elif len(right)==1:g.face((left[k],left[k+1],right[0]),m)
            else:g.face((left[k],left[k+1],right[k+1],right[k]),m)

def grasses(form,height,g,b,juvenile=False):
    arch=form in ['banded','forest'];fine=form in ['moor','hair','muhly']
    spread=height*(1.20 if form=='forest' else .46 if arch else .22)
    width=.022 if form=='banded' else .014 if form=='forest' else .0035 if fine else .010
    count=30 if juvenile else 90 if fine else 66
    for j in range(count):
        a=j*2.39996;h=height*random.uniform(.40,.78 if arch else .92)
        base=radial(a,random.uniform(.005,.10 if height>.8 else .055))
        grass_blade(g,base,a,h,spread*random.uniform(.5,1.1),width,1+j%2,form=='banded',form=='blood')
    if juvenile:return
    stems=10 if form in ['forest','blood','sesleria','quaking'] else 20
    for j in range(stems):
        a=j*2.39996;base=radial(a,.07);h=height*random.uniform(.84,1.04)
        top=radial(a,spread*.75,h)
        if form=='blood':continue # Red Baron rarely flowers in cultivation.
        g.tube([base,top],[.003,.0016],0,5)
        if form in ['reed','sesleria']:
            length=.30 if form=='reed' else .08
            for k in range(14):
                p=top+Vector((0,0,k*length/14))
                for q in range(2):
                    tip=p+radial(q*2*pi/3+k*.4,.012,.017)
                    b.ellipsoid(tip,(.004,.004,.017),0,3,5)
        else:
            levels=6 if form in ['muhly','hair','switch','moor'] else 5
            for k in range(levels):
                p=top+Vector((0,0,(k/levels-.55)*height*.24))
                for q in range(3 if form=='muhly' else 2):
                    turn=a+q*2*pi/3+k*.62
                    spread_ratio={'muhly':.22,'hair':.16,'switch':.13,'moor':.065}.get(form,.10)
                    extent=height*spread_ratio*(1-k/(levels+1))
                    tip=p+radial(turn,extent,height*.06)
                    b.tube([p,tip],[.0008,.00045],0,3)
                    if form=='quaking':
                        tip.z-=.020
                        # Pendulous flattened oval/heart-shaped spikelets with overlapping scales.
                        b.ellipsoid(tip,(.008,.003,.012),0,6,8)
                        for n in range(4):b.tube([tip+Vector((-.006,0,(n-2)*.004)),tip+Vector((.006,0,(n-2)*.004+.001))],[.0005]*2,1,3)
                    else:
                        for n in range(3):
                            end=p.lerp(tip,(n+1)/6)+radial(turn+1,.013,height*.017)
                            b.tube([p.lerp(tip,(n+1)/6),end],[.00065,.00035],0,3)
                            b.ellipsoid(end,(.002,.002,.005 if fine else .012),0,2,4)
    if not b.v:b.ellipsoid((0,0,height*.55),(.007,.007,.022),0,3,5)

def rib_body(g,center,radius,height,ribs,mat=1,barrel=True,young=False):
    """True variable-count ribs, with unique poles and UVs."""
    c=Vector(center);rows=[];sides=ribs*(4 if young else 10);rings=10 if young else 20
    for i in range(rings+1):
        t=i/rings;row=[];count=1 if i in [0,rings] else sides
        factor=sin(pi*t)**(.65 if barrel else .16)
        for j in range(count):
            a=j*2*pi/sides;r=radius*factor*(1+.13*cos(a*ribs))
            p=c+radial(a,r,height*t)
            row.append(len(g.v));g.v.append(tuple(p));g.uv[len(g.v)-1]=(j/sides,t)
        rows.append(row)
    for a,b in zip(rows,rows[1:]):
        for j in range(sides):
            k=(j+1)%sides
            if len(a)==1:g.face((a[0],b[k],b[j]),mat)
            elif len(b)==1:g.face((a[j],a[k],b[0]),mat)
            else:g.face((a[j],a[k],b[k],b[j]),mat)
    for i in range(2,rings-1,4 if young else 2):
        t=i/rings;factor=sin(pi*t)**(.65 if barrel else .16)
        for j in range(ribs):
            a=j*2*pi/ribs;p=c+radial(a,radius*factor*1.135,height*t)
            g.ellipsoid(p,(.003,.003,.004) if ribs==8 and barrel else (.007,.007,.010),3,3,6)
            if ribs==8 and barrel:continue # Astrophytum asterias is spineless.
            for n in range(3 if young else 5):
                direction=(radial(a,.65)+radial(a+pi/2,cos(n*2*pi/5)*.50,sin(n*2*pi/5)*.65)).normalized()
                length=.035 if barrel else .018
                g.tube([p,p+direction*length],[.0015,.0003],3,4)

def daisy(b,p,r,petals=18):
    for j in range(petals):
        a=j*2*pi/petals
        petal(b,p,radial(a,1),radial(a+pi/2,1),Vector((0,0,1)),r,r*.17)
    b.ellipsoid(Vector(p)+Vector((0,0,.004)),(r*.20,r*.20,.007),1,5,10)

def rosette(g,p,r,form,small=False):
    p=Vector(p);count=8 if small else 32 if form in ['snowball','hens','aeonium'] else 20
    for j in range(count):
        a=j*2.39996;t=j/max(1,count-1)
        length=r*(1-.72*t);rise=r*(.18+.75*t)
        if form in ['aloe','agave','zebra']:rise=r*(.65+.70*t)
        pointed=form not in ['snowball','aeonium','window']
        width=length*(.15 if form in ['aloe','agave','zebra'] else .28 if form=='lipstick' else .38)
        thickness=length*(.13 if form=='window' else .075 if form=='aloe' else .065)
        tip=p+radial(a,length,rise)
        flesh(g,p+Vector((0,0,r*t*.12)),tip,width,thickness,1 if form!='aeonium' or t<.70 else 2,pointed,form in ['lipstick','hens'])
        if form in ['aloe','agave']:
            for k in range(2,9):
                s=k/10;loc=p.lerp(tip,s);w=width*sin(pi*s)**.90
                for sign in [-1,1]:
                    edge=loc+radial(a+sign*pi/2,w,sin(pi*s)*length*.10)
                    g.tube([edge,edge+radial(a+sign*pi/2,length*.028,.002)],[length*.007,.0004],3 if form=='aloe' else 4,4)
            if form=='agave':g.tube([tip,tip+radial(a,.025,.014)],[.004,.0004],4,5)
        if form=='zebra':
            for k in ([3,6,9] if small else range(2,10)):
                s=k/11;loc=p.lerp(tip,s)+Vector((0,0,sin(pi*s)*length*.10))
                w=width*sin(pi*s)**.9
                for n in ([-.65,0,.65] if small else [-1,-.5,0,.5,1]):
                    # Raised white tubercles rather than smooth painted stripes.
                    g.ellipsoid(loc+radial(a+pi/2,w*n)+Vector((0,0,thickness*sin(pi*s))),(.0027,.0027,.0017),3,3,5)

def succulents(form,h,g,b,young=False):
    if form in ['barrel','star','column','wool','finger']:
        if form=='finger':
            for j in range(1 if young else 9):
                a=j*2.4;c=radial(a,0 if young else .065*sqrt(j/8))
                height=h*(.65+.35*(1-j/9));radius=.028
                # Mammillaria has tubercles in spirals rather than continuous ribs.
                g.ellipsoid(c+Vector((0,0,height*.5)),(radius,radius,height*.5),1,14,16)
                count=24 if young else 70
                for k in range(count):
                    z=height*(.08+.84*k/count);aa=k*2.39996
                    p=c+radial(aa,radius,z)
                    g.ellipsoid(p,(.005,.005,.006),2,3,5)
                    for n in range(5):g.tube([p,p+radial(aa,.012,cos(n*2*pi/5)*.008)+radial(aa+pi/2,sin(n*2*pi/5)*.009)],[.001,.00025],3,3)
        else:
            columns=3 if form=='column' and not young else 1
            for j in range(columns):
                c=radial(j*2.4,.18 if j else 0);height=h*(1-j*.21)
                radius=h*(.54 if form=='star' else .47 if form=='barrel' else .12)
                rib_body(g,c,radius,height,8 if form=='star' else 24 if form=='barrel' else 6 if form=='column' else 18,1,form in ['star','barrel'],young)
                if form=='wool':
                    for k in range(1400 if not young else 80):
                        a=k*2.39996;z=height*random.uniform(.08,.98)
                        r=radius*sin(pi*z/height)**.16*(1+.13*cos(a*18))+.002
                        p=c+radial(a,r,z)
                        g.tube([p,p+radial(a,.016,-.017),p+radial(a+.10,.024,-.090)],[.0017,.0012,.0004],3,3)
                if form=='star':
                    for k in range(150):
                        a=k*2.39996;t=.16+.64*((k*.618)%1)
                        r=radius*sin(pi*t)**.65*(1+.13*cos(a*8))
                        g.ellipsoid(c+radial(a,r*1.01,height*t),(.0010,.0010,.0008),3,2,4)
        if not young:
            if form in ['barrel','star','finger']:daisy(b,(0,0,h*.95),.028 if form=='finger' else .047,18)
            else:b.ellipsoid((0,0,h*.82),(.015,.015,.024),0,5,8) # restrained closed tip on immature nonflowering columns
    elif form in ['bunny','pear']:
        pads=[((0,0,h*.25),h*.22,h*.25)]
        if not young:pads += [((s*h*.14,0,h*.64),h*.17,h*.28) for s in [-1,1]]
        if form=='pear' and not young:pads += [((s*h*.31,.025,h*.92),h*.14,h*.22) for s in [-1,1]]
        for center,r,zr in pads:
            g.ellipsoid(center,(r,h*.043,zr),1,16,24)
            for side in [-1,1]:
                for k in range(55):
                    a=k*2.4;rr=sqrt((k+.5)/55)*.91;x=cos(a)*rr*r;z=sin(a)*rr*zr
                    y=side*h*.043*sqrt(1-rr*rr);p=Vector(center)+Vector((x,y,z))
                    g.ellipsoid(p,(.004,.003,.004),3,3,5)
                    for n in range(3):g.tube([p,p+Vector((cos(n*2.4)*.007,side*.009,sin(n*2.4)*.007))],[.0008,.00025],3,3)
        if not young:
            for s in [-1,1]:daisy(b,(s*h*.22,0,h*.90),.045,14)
    elif form=='holiday':
        for j in range(3 if young else 9):
            a=j*2.39996;p=Vector((0,0,h*.18))
            for k in range(2 if young else 5):
                q=p+radial(a,h*.23,h*(.23-k*.085))
                flesh(g,p,q,h*.058,h*.009,1,False)
                for t in [.25,.65]:
                    loc=p.lerp(q,t)
                    for s in [-1,1]:g.tube([loc+radial(a+s*pi/2,h*.050),loc+radial(a+s*pi/2,h*.066,.013)],[.006,.0005],1,4)
                p=q
            if not young:
                normal=radial(a,1,.15).normalized();right=radial(a+pi/2,1);up=right.cross(normal).normalized()
                for k in range(3):
                    origin=p+normal*k*.030
                    for n in range(5):
                        turn=n*2*pi/5
                        petal(b,origin,normal*.55+(up*cos(turn)+right*sin(turn))*.7,right*cos(turn)-up*sin(turn),normal,.070,.022)
    elif form in ['snowball','lipstick','hens','aloe','agave','zebra','window','aeonium']:
        if form=='window':
            for j in range(9 if young else 26):
                a=j*2.4;r=h*.55*sqrt(j/26);p=radial(a,r,h*(.28+.10*(1-j/26)))
                g.ellipsoid(p,(h*.16,h*.16,h*.23),1,10,14)
                # Opaque pale windows give the optical impression without depth-sorting artefacts.
                g.ellipsoid(p+Vector((0,0,h*.19)),(h*.14,h*.14,h*.07),2,8,12)
        else:
            r=h/(1.4 if form in ['aloe','agave','zebra'] else .70)
            if form=='aeonium':
                g.tube([(0,0,0),(0,0,h*.48)],[.025,.016],0,10)
                for j in range(1 if young else 3):
                    p=radial(j*2.4,h*.22 if j else 0,h*(.55 if j else .72))
                    g.tube([(0,0,h*.32),p],[.018,.008],0,8);rosette(g,p,h*.25,form,young)
            else:
                rosette(g,(0,0,.014),r,form,young)
                if form in ['hens','snowball'] and not young:
                    for j in range(3):rosette(g,radial(j*2.4,r*1.05,.008),r*.33,form,True)
        if not young:
            if form in ['snowball','lipstick','aloe','zebra','window']:
                stalk=h*(1.8 if h<.3 else 1.45)
                tiny=form in ['zebra','window']
                b.tube([(0,0,h*.4),(.04,0,stalk)],[.0015,.0008] if tiny else [.004,.002],2,6)
                for j in range(5):
                    p=Vector((.04+j*(.005 if tiny else .012),0,stalk-j*(.018 if tiny else .035)))
                    b.ellipsoid(p,(.0025,.0025,.007) if tiny else (.007,.007,.015),0,6,10)
            elif form=='hens':daisy(b,(0,0,h*.70),.028,12)
            else:b.ellipsoid((0,0,h*.72),(.006,.006,.013),2,4,6) # growing tip, no implausible giant agave inflorescence
    elif form=='beans':
        for j in range(3 if young else 7):
            a=j*2.39996;base=radial(a,.035,.005);end=radial(a,h*.40,h*random.uniform(.62,.90))
            g.tube([base,base.lerp(end,.5),end],[.004,.003,.0018],0,6)
            for k in range(8):
                p=base.lerp(end,.25+k*.09);turn=a+k*2.4
                tip=p+radial(turn,.021,.030)
                flesh(g,p,tip,.010,.008,1,False,True)
            if not young:daisy(b,end+Vector((0,0,.018)),.012,5)
    elif form in ['jade','gollum']:
        branches=3 if young else 8;stem=h*.65
        g.tube([(0,0,0),(0,0,stem)],[h*.050,h*.018],0,10)
        for j in range(branches):
            a=j*2.4;p=Vector((0,0,stem*(.3+.6*j/branches)));tip=p+radial(a,h*.28,h*.14)
            g.tube([p,tip],[h*.021,h*.007],0,7)
            for k in range(3):
                q=p.lerp(tip,.45+k*.24)
                for sign in [-1,1]:
                    end=q+radial(a+sign*pi/2,h*.15,h*.10)
                    if form=='jade':flesh(g,q,end,h*.065,h*.020,1,False,False)
                    else:
                        # Tube narrows to a real recessed cup rather than a solid round cap.
                        d=(end-q).normalized();side=d.cross(Vector((0,0,1))).normalized();up=d.cross(side)
                        rings=[]
                        for t,r in [(0,.003),(.55,.010),(1,.016),(.98,.010),(.83,.006)]:
                            row=[]
                            for n in range(12):
                                pt=q.lerp(end,t)+side*cos(n*pi/6)*r+up*sin(n*pi/6)*r
                                row.append(len(g.v));g.v.append(tuple(pt));g.uv[len(g.v)-1]=(n/12,t)
                            rings.append(row)
                        for z,(l,r) in enumerate(zip(rings,rings[1:])):
                            for n in range(12):g.face((l[n],l[(n+1)%12],r[(n+1)%12],r[n]),4 if z==2 else 1)
                        g.face(tuple(reversed(rings[-1])),1)
            if not young:daisy(b,tip+Vector((0,0,.055)),.015,5)
    elif form=='lithops':
        for j in range(1 if young else 5):
            c=radial(j*2.4,0 if j==0 else .045,.0)
            for sign in [-1,1]:
                # Rounded sides below a flattened marked window, with a narrow central cleft.
                p=c+Vector((sign*.014,0,0));rows=[];sides=20
                for z,r in [(0,.32),(.008,.72),(.022,1),(.035,1),(.042,.92)]:
                    row=[]
                    for n in range(sides):
                        a=n*2*pi/sides;pt=p+Vector((cos(a)*.012*r,sin(a)*.021*r,z))
                        row.append(len(g.v));g.v.append(tuple(pt));g.uv[len(g.v)-1]=(n/sides,z/.042)
                    rows.append(row)
                for l,r in zip(rows,rows[1:]):
                    for n in range(sides):g.face((l[n],l[(n+1)%sides],r[(n+1)%sides],r[n]),1)
                g.face(tuple(rows[-1]),1);g.face(tuple(reversed(rows[0])),1)
                for k in range(18):
                    a=k*2.4;rr=.70*sqrt(k/18);loc=p+Vector((cos(a)*.010*rr,sin(a)*.019*rr,.0424))
                    g.ellipsoid(loc,(.0018,.0022,.0005),4,2,5)
        if not young:daisy(b,(0,0,.050),.029,24)
