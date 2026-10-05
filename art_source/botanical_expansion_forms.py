"""Reference-led organs for catalogue IDs 60–105, in garden-scale metres.
Shared construction expresses related botany; leaf outlines, inflorescences,
branching habits and fruit profiles are selected independently per species.
"""
import math, random
from math import sin, cos, pi, sqrt
from mathutils import Vector
from botanical_geometry import Geometry
from botanical_forms import radial, compound, palmate, round_leaf, pea_flower, bell
Z=Vector((0,0,1))

def blade(g,p,q,w,mat=1,serrate=False,broad=False,lobes=0):
    """Curved leaf with explicit toothed/lobed margin and midrib-aligned UVs."""
    p,q=Vector(p),Vector(q);d=q-p;side=d.cross(Z).normalized()
    if side.length<.01:side=Vector((1,0,0))
    up=side.cross(d.normalized()).normalized()
    if up.z<0:up=-up
    seg=18 if serrate or lobes else 6 if w/d.length<.15 else 10;cols=3 if w/d.length<.15 else 5;start=len(g.v)
    for i in range(seg+1):
        t=i/seg;profile=sin(pi*t)**(.5 if broad else .85)
        if serrate:profile*=1 if i%2 else .79
        if lobes:profile*=.48+.52*(.5+.5*cos(t*pi*lobes*2))
        for k in range(cols):
            s=k/(cols-1)*2-1
            point=p+d*t+side*(s*w*profile)+up*(d.length*.24*sin(pi*t)-abs(s)**1.5*w*.19+abs(s)**3*w*.08*sin(t*20))
            g.v.append(tuple(point));g.uv[len(g.v)-1]=(k/(cols-1),t)
    for i in range(seg):
        for k in range(cols-1):
            a=start+i*cols+k;g.face((a,a+1,a+cols+1,a+cols),mat)

def orient(g,start,p,normal):
    rotation=Z.rotation_difference(Vector(normal).normalized());p=Vector(p)
    for i in range(start,len(g.v)):g.v[i]=tuple(p+rotation@(Vector(g.v[i])-p))

def fan(g,p,a,length,mat=1):
    """Ginkgo's notched fan with radially aligned, dichotomous-looking ribs."""
    p=Vector(p);start=len(g.v);n=20
    for j in range(5):
        t=j/4
        for k in range(n+1):
            u=k/n;angle=a+(u-.5)*2.0
            notch=1-.23*math.exp(-((u-.5)/.065)**2)
            q=p+radial(angle,length*t*notch,length*(.14*sin(pi*t)+.018*cos(k*pi)*t))
            g.v.append(tuple(q));g.uv[len(g.v)-1]=(u,t)
    for j in range(4):
        for k in range(n):
            i=start+j*(n+1)+k;g.face((i,i+1,i+n+2,i+n+1),mat)

def fruit(b,p,r,kind,mat=0):
    """Revolved fruit profiles: necked pears, flattened mandarins, stone-fruit seam."""
    p=Vector(p);rings=16;sides=24;start=len(b.v)
    for i in range(rings+1):
        t=i/rings;z=cos(pi*t);shape=sin(pi*t)
        if kind in ['Pear','Avocado','Fig']:shape*=.75-.28*z
        if kind=='Capsicum':shape=sin(pi*t)**.40*(.92+.10*z)
        for j in range(sides):
            a=j*2*pi/sides;rr=shape
            if kind=='Capsicum':rr*=1+.12*cos(4*a)
            if kind in ['Peach','Apricot','Nectarine','Plum']:rr*=1-.055*math.exp(-(sin(a/2)/.13)**2)
            zz=z*(1.18 if kind in ['Pear','Avocado'] else .78 if kind=='Mandarin' else 1)
            q=p+Vector((cos(a)*rr*r,sin(a)*rr*r,zz*r))
            b.v.append(tuple(q));b.uv[len(b.v)-1]=(j/sides,t)
    for i in range(rings):
        for j in range(sides):
            a=start+i*sides+j;c=start+i*sides+(j+1)%sides;b.face((a,c,c+sides,a+sides),mat)
    stemtop=p+Z*r*(1.18 if kind in ['Pear','Avocado'] else 1)
    b.tube([stemtop,stemtop+Vector((.018,0,r*.36))],[r*.085,r*.05],3,5)
    if kind in ['Fig','Pear','Capsicum']:
        center=p-Z*r if kind=='Fig' else stemtop
        for j in range(5):b.leaf(center,center+radial(j*2*pi/5,r*.28,.008),r*.08,3,.1,3)

def star(b,p,r,petals=5,mat=0,rise=0):
    p=Vector(p)
    for j in range(petals):
        a=j*2*pi/petals
        b.leaf(p,p+radial(a,r,rise),r*.30,mat,.16,5)
    b.ellipsoid(p+Z*.008,(r*.12,r*.12,r*.10),2,3,8)

def bamboo(name,g,b):
    giant=name=='Giant bamboo';red='Red bamboo' in name;slender='weaver' in name
    height=8.4 if giant else 3.7 if slender else 2.7 if red else 3.5
    count=7 if giant else 15 if red else 11
    for j in range(count):
        a=j*2.39996;base=radial(a,sqrt((j+.3)/count)*(.65 if giant else .43))
        h=height*random.uniform(.65,1);lean=radial(a,.35 if slender else .75)
        radius=.095 if giant else .012 if red else .025
        points=[base+Z*h*((k/14)**1.15 if name=='Golden bamboo' else k/14)+lean*(k/14)**2 for k in range(15)]
        g.tube(points,[radius*(1-.60*k/14) for k in range(15)],8 if j%4 else 0,12)
        for k in range(1,14):
            p=points[k];rr=radius*(1-.6*k/14)
            # Raised node collars and sheath scars, independently modelled.
            g.tube([p-Z*.009,p,p+Z*.009],[rr*1.04,rr*1.21,rr*1.04],6,12)
            if k<5 and j%3==0:
                g.leaf(p-Z*.035,p+radial(a,.05,.20),radius*.9,7,.1,6)
            if k<5:continue
            for branch in range(2 if not red else 1):
                angle=a+k*1.35+branch*2.1
                length=(1-k/16)*(2.0 if giant else .85)
                end=p+radial(angle,length,.11)
                g.tube([p,p.lerp(end,.55)+Z*.055,end],[radius*.28,.004,.0015],0,5)
                for m in range(2,8):
                    q=p.lerp(end,m/8)
                    for sign in [-1,1]:
                        ll=(.38 if giant else .22)*random.uniform(.8,1.3)
                        tip=q+radial(angle+sign*.72,ll,-.035-m*.006)
                        blade(g,q,tip,ll*.075,1 if m%3 else 2)
    # Unopened shoot with imbricate sheaths, harvest-stage group for game growth.
    p=radial(.7,.4)
    b.tube([p,p+Z*.25,p+Z*.52],[.07,.05,.004],3,12)
    for k in range(6):
        q=p+Z*(.045+k*.065)
        b.leaf(q,q+radial(k*2.4,.045,.16),.044,1,.1,6)

def rose(name,g,b):
    iceberg='Iceberg' in name;joey='Joey' in name;gold='Golden' in name;lincoln='Lincoln' in name
    branches=11 if iceberg else 8
    for j in range(branches):
        a=j*2.39996;h=random.uniform(.55,.90) if joey else random.uniform(.8,1.45);p=radial(a,random.uniform(.23,.62),h)
        points=[radial(a,.025),radial(a,.17,h*.45),p]
        g.tube(points,[.021,.012,.0045],0,7)
        for k in range(2,7):
            q=points[1].lerp(p,(k-2)/5);angle=a+k*2.3
            # Five/seven toothed leaflets on a pinnate rachis.
            end=q+radial(angle,.30,.065);g.tube([q,end],[.003,.001],0,4)
            side=radial(angle+pi/2,1)
            for m in range(1,4):
                loc=q.lerp(end,m/4)
                for s in [-1,1]:blade(g,loc,loc+side*s*.10+(end-q)*.13,.035,1 if k%3 else 2,True)
            blade(g,end-(end-q)*.12,end+(end-q)*.3,.042,3,True)
            thorn=q+radial(angle+.5,.032,-.012);g.tube([q,thorn],[.009,.0002],7,4)
        flowercount=3 if iceberg else 1
        for f in range(flowercount):
            c=p+radial(a+f*2.1,.095 if iceberg else 0,.05*f)
            if f:g.tube([p,c],[.003,.001],0,4)
            size=.105 if iceberg else .165 if gold or joey else .145
            rings=3 if iceberg or joey else 5
            for ring in range(rings):
                petals=(8 if gold else 6 if iceberg else 7)-ring//2
                for k in range(petals):
                    ang=k*2*pi/petals+ring*2.39996
                    ll=size*(1-ring*.17)
                    base=c+radial(ang,size*.07,-size*.13)
                    b.cupped_blade(base,ang,ll,size*(.47-ring*.06),size*(.12+ring*(.22 if lincoln else .12)),0 if (k+ring)%3 else 4,.38 if joey else .12)
            if iceberg:
                for k in range(12):
                    q=c+radial(k*2.4,.025,.015);b.tube([q,q+Z*.025],[.0018,.001],2,4)
            for k in range(5):b.leaf(c-Z*.028,c+radial(k*2*pi/5,.095,-.025),.013,3,.1,4)
        if j%3==0:
            bud=p+radial(a,.15,-.15);g.tube([p-Z*.22,bud],[.003,.002],0,4)
            b.ellipsoid(bud,(.027,.027,.047),0,8,12)
            for k in range(4):b.leaf(bud-Z*.045,bud+radial(k*pi/2,.024,.03),.012,3,.1,5)

def conifer(name,g,b):
    sequoia=name=='Giant redwood';h=10 if sequoia else 11.5;radius=.69 if sequoia else .36
    points=[Vector((sin(k*.7)*.065,cos(k*.6)*.05,h*k/12)) for k in range(13)]
    g.tube(points,[radius*(1-k/13)**1.1+.01 for k in range(13)],5,20)
    for j in range(9):
        a=j*2*pi/9;g.tube([radial(a,radius*1.65,.025),radial(a,radius*.85,.45),Z*1.5],[radius*.23,radius*.25,.08],5,9)
    for tier in range(3,17):
        t=tier/18;length=(1-t)**.72*(2.7 if sequoia else 2.35)
        for j in range(5):
            a=j*2*pi/5+tier*2.4;p=Z*(h*t);q=p+radial(a,length,.2 if sequoia else -.1);end=q+Z*.22
            g.tube([p,p.lerp(q,.65)-Z*.10,end],[.06*(1-t)+.008,.018,.003],5,6)
            for k in range(2,8):
                base=p.lerp(q,k/8)
                for sign in [-1,1]:
                    angle=a+sign*.8;twig_end=base+radial(angle,.80*(1-t)+.25,random.uniform(.05,.30))
                    g.tube([base,twig_end],[.005,.001],0,4)
                    for m in range(8):
                        loc=base.lerp(twig_end,m/8)
                        for s in [-1,1]:
                            la=angle+s*(1.15 if not sequoia else .55)
                            ll=(.25 if not sequoia else .19)*(1-m*.045)
                            Geometry.leaf(g,loc,loc+radial(la,ll,.012 if not sequoia else .045),.022 if not sequoia else .031,3 if tier%3 else 1,.05,2)
                    if sequoia:
                        for m in range(6):
                            loc=base.lerp(twig_end,m/6)
                            Geometry.leaf(g,loc,loc+radial(angle,.07,.16),.034,1,.05,2)
        if tier in [5,8,11]:
            c=q-Z*.09;b.ellipsoid(c,(.046,.046,.065) if sequoia else (.032,.032,.043),1,8,12,ribs=.08)
            for k in range(14):
                pos=c+radial(k*2.4,.04,(k/14-.5)*.085);b.leaf(pos,pos+Z*.025,.016,1,.2,3)

def tree_leaf(name,g,p,a,ll,mat):
    if name=='Ginkgo':fan(g,p,a,ll,mat)
    elif name=='Fig':palmate(g,p,ll,a,mat,5)
    elif name in ['Peach','Nectarine'] or 'gum' in name:blade(g,p,p+radial(a,ll,random.uniform(-.15,.035)),ll*.13,mat,serrate=name in ['Peach','Nectarine'])
    else:blade(g,p,p+radial(a,ll,random.uniform(-.08,.09)),ll*(.43 if name=='Apricot' else .33 if name in ['Pear','Plum'] else .27),mat,serrate=name in ['Pear','Plum','Apricot'],broad=name=='Apricot')

def gum_bloom(b,p):
    for j in range(5):
        c=Vector(p)+radial(j*2.4,.065,(j%2)*.035)
        b.ellipsoid(c,(.022,.022,.031),3,6,10)
        for k in range(22):
            a=k*2.39996;r=.033+.024*(k%4)/3
            end=c+radial(a,r,.055+random.random()*.035)
            b.tube([c,c.lerp(end,.6)+Z*.012,end],[.0015,.0012,.0008],0,4)
            b.ellipsoid(end,(.0027,)*3,2,3,5)

def tree(name,g,b):
    from fruit_tree_geometry import fruit_rng, hanging_fruit
    fruit_random=fruit_rng(name)
    gum='gum' in name;alpine=name=='Alpine snow gum';snow='snow gum' in name.lower()
    h=3.6 if alpine else 4.5 if gum else 4.0 if name=='Ginkgo' else 3.0 if name=='Mandarin' else 3.7
    spread=1.8 if gum else 1.35 if name=='Ginkgo' else 1.5
    trunks=4 if alpine else 3 if snow else 1
    terminals=[]
    for t in range(trunks):
        angle=t*2.4
        points=[radial(angle,.06),radial(angle+.5,.18,h*.25),radial(angle,.58 if snow else .10,h*.55),radial(angle+.5,1.0 if snow else .12,h*.93)]
        g.tube(points,[.16 if trunks==1 else .105,.10,.065,.014],6 if snow else 5,14)
        for j in range(14 if trunks==1 else 7):
            frac=.38+j/(27 if trunks==1 else 17)+random.uniform(-.055,.055);a=j*2.39996+t*1.1+random.uniform(-.35,.35)
            p=points[1].lerp(points[-1],(frac-.25)/.68)
            radius=spread*sqrt(max(.15,1-((frac-.6)/.6)**2))*random.uniform(.7,1)
            q=p+radial(a,radius,random.uniform(.12,.7));mid=p.lerp(q,.55)-Z*.15
            g.tube([p,mid,q],[.046,.026,.006],6 if snow else 5,7)
            for k in range(7):
                loc=mid.lerp(q,k/7);a2=a+(1 if k%2 else -1)*random.uniform(.4,1.4)
                end=loc+radial(a2,random.uniform(.35,.65),random.uniform(.05,.4))
                g.tube([loc,end],[.008,.0015],6 if snow else 0,5)
                for m in range(9):
                    base=loc.lerp(end,(m+1)/10);la=a2+(1 if m%2 else -1)*random.uniform(.65,1.4)
                    ll=(.31 if name=='Fig' else .36 if name=='Avocado' else .34 if gum else .26)*random.uniform(.8,1.25)
                    tree_leaf(name,g,base,la,ll,4 if snow else 1 if m%3 else 2)
                terminals.append(end)
                if k in [2,5] and name not in ['Ginkgo','Snow gum','Alpine snow gum','Red flowering gum']:
                    if fruit_random.random()<.86:
                        anchor=loc.lerp(end,fruit_random.uniform(.48,.88))
                        hanging_fruit(b,anchor,name,.085 if name in ['Fig','Plum','Apricot','Lime'] else .12 if name=='Avocado' else .105,fruit_random,fruit_random.choice([0,0,4]))
    if name=='Red flowering gum':
        for p in terminals[::4]:gum_bloom(b,p)
        for p in terminals[2::13]:
            b.tube([p-Z*.065,p-Z*.02,p],[.018,.028,.024],1,10)
            b.ellipsoid(p,(.017,.017,.005),4,4,10)
    elif snow:
        for p in terminals[::18]:
            for k in range(5):
                c=p+radial(k*2.4,.04,.01);b.ellipsoid(c,(.012,.012,.025),1,6,8)
    elif name=='Ginkgo':
        # Keep a separate growing tip group without inventing conspicuous flowers.
        for p in terminals[::8]:fan(b,p,random.random()*6,.10,3)

def jasmine(name,g,b):
    winter=name=='Winter jasmine';pink=name=='Pink jasmine'
    for j in range(16):
        a=j*2.4;r=random.uniform(.3,.85);h=random.uniform(.5,1.3)
        points=[radial(a,.04),radial(a+.3,r*.3,h*.72),radial(a,r*.7,h),radial(a+.15,r,h*.70 if winter else h*1.2)]
        g.tube(points,[.012,.008,.004,.0015],0,6)
        for k in range(3,12):
            t=(k-3)/9
            p=points[1].lerp(points[2],t*2) if t<.5 else points[2].lerp(points[3],(t-.5)*2)
            ang=a+k*2.1
            if winter:
                if k%3==0:
                    for m in range(3):blade(g,p,p+radial(ang+(m-1)*.5,.10,.02),.024,1)
            else:compound(g,p,p+radial(ang,.24,.03),1)
            if k%2==0 or winter:
                count=1 if winter else 4
                for m in range(count):
                    c=p+radial(ang+m*2.4,.065,.035*m/count)
                    b.tube([p,c],[.002,.001],3,4)
                    star(b,c,.052 if winter else .043,6 if winter else 5)
                if pink:
                    c=p+radial(ang,.08,.06);b.ellipsoid(c,(.009,.009,.03),1,8,10)

def flowers(name,g,b):
    if 'jasmine' in name:return jasmine(name,g,b)
    tulip='Tulip' in name;dahlia='Dahlia' in name;lupin='lupin' in name;holly='hollyhock' in name
    count=5 if tulip or dahlia else 6 if lupin else 4
    for j in range(count):
        a=j*2.4;base=radial(a,.20*sqrt(j/count));h=random.uniform(.55,.85) if tulip else random.uniform(.9,1.4) if dahlia else random.uniform(1.15,1.9)
        top=base+radial(a,.07,h);g.tube([base,base+Z*h*.55,top],[.012,.008,.003],0,6)
        for k in range(2 if tulip else 6):
            p=base+Z*h*(.08+k*(.18 if tulip else .11));angle=a+k*2.39996
            if tulip:blade(g,p,p+radial(angle,.3,.38),.08,4)
            elif lupin:
                end=p+radial(angle,.30,.08);g.tube([p,end],[.004,.002],0,4)
                for m in range(9):blade(g,end,end+radial(angle+m*2*pi/9,.17,.03),.026,1)
            elif holly:
                end=p+radial(angle,.18,.07);g.tube([p,end],[.004,.002],0,4);round_leaf(g,end,.19,1)
            elif dahlia:compound(g,p,p+radial(angle,.36,.09),1)
            else:palmate(g,p+radial(angle,.1),.20,angle,1,7)
        if tulip:
            for ring in range(2):
                for m in range(3):
                    angle=m*2*pi/3+ring*pi/3
                    b.cupped_blade(top-Z*.07,angle,.12,.077,.21-ring*.015,ring*4,.04)
            for m in range(6):
                p=top+radial(m*pi/3,.025,.03);b.tube([p,p+Z*.04],[.002,.002],2,4)
        elif dahlia:
            for ring in range(7):
                size=.22*(1-ring*.12);n=16-ring
                for m in range(n):
                    b.cupped_blade(top+Z*(.07*(ring/6)**.7-.02),m*2*pi/n+ring*2.4,size,size*.30,.028+ring*.009,0 if ring<4 else 4,.18)
        else:
            for k in range(16 if lupin else 11 if not holly else 7):
                p=top-Z*(k*(.038 if lupin else .057 if not holly else .095))
                n=5 if lupin else 3 if not holly else 1
                for m in range(n):
                    angle=m*2*pi/n+k*2.4;c=p+radial(angle,.03 if lupin else .065,.01)
                    b.tube([p,c],[.002,.001],3,4)
                    if lupin:pea_flower(b,c,.045)
                    elif holly:
                        start=len(b.v)
                        for pet in range(5):b.cupped_blade(c,pet*2*pi/5,.105,.072,.045,0,.25)
                        b.tube([c,c+Z*.085],[.009,.004],2,8)
                        orient(b,start,c,radial(angle,1,.28))
                    else:
                        start=len(b.v)
                        star(b,c,.055,5,0,.018)
                        b.tube([c,c-radial(angle,.055,.015)],[.008,.0005],4,6)
                        star(b,c+Z*.025,.017,4,1)
                        orient(b,start,c,radial(angle,1,.4))
            b.ellipsoid(top+Z*.06,(.014,.014,.03),4,6,8)

def waratah(g,b):
    for j in range(7):
        a=j*2.4;top=radial(a,.42,random.uniform(1.05,1.7))
        g.tube([radial(a,.05),top*.5,top],[.023,.013,.005],5,7)
        for k in range(9):
            p=top*(.2+k*.08);blade(g,p,p+radial(a+k*2.4,.25,.06),.055,3,True)
        for ring in range(3):
            for k in range(10):b.cupped_blade(top-Z*.06,k*pi/5+ring*.4,.14-ring*.025,.042,.12+ring*.03,4,.03)
        for k in range(85):
            a=k*2.39996;t=k/85;r=.115*sqrt(t);p=top+radial(a,r,.15*sqrt(1-t))
            end=p+radial(a,.035,.023)
            b.tube([p,p+Z*.048,end],[.0045,.005,.0025],0,5)
            b.ellipsoid(end,(.004,.004,.007),0,4,6)

def gymea(g,b):
    for j in range(34):
        a=j*2.4;length=random.uniform(.7,1.3)
        blade(g,radial(a,.07),radial(a,length,.3+random.random()*.5),.064,1 if j%3 else 2)
    g.tube([Z*.1,Vector((.04,0,1.5)),Vector((.10,0,3.1))],[.055,.045,.025],0,12)
    for k in range(12):g.leaf(Z*(.4+k*.21),Z*(.55+k*.21)+radial(k*2.4,.12),.04,1,.12,8)
    for k in range(30):
        a=k*2.4;r=.19*sqrt(k/30);p=Vector((.1,0,3.1))+radial(a,r,.1*sqrt(1-k/30))
        for m in range(6):b.cupped_blade(p,m*pi/3,.08,.023,.12,0,.04)
        for m in range(6):
            q=p+radial(m*pi/3,.025,.14);b.tube([p,q],[.0018,.001],2,4)

def brassica(name,g,b):
    sprouts=name=='Brussels sprouts';h=1.1 if sprouts else .43
    g.tube([Z*.02,Z*h],[.038,.025],0,12)
    for j in range(14 if sprouts else 11):
        a=j*2.39996;z=.12+j*.062 if sprouts else .09+j*.022;p=Z*z
        length=.25 if sprouts else .43;tip=p+radial(a,length,.12 if j>7 else -.015)
        petiole=p.lerp(tip,.35);g.tube([p,petiole],[.009,.006],0,6)
        blade(g,petiole,tip,.16 if sprouts else .20,4,broad=True,lobes=0 if name=='Cauliflower' else 3)
        if sprouts and j<12:
            c=p+radial(a,.046);b.ellipsoid(c,(.042,.042,.049),3,10,14)
            for k in range(5):b.cupped_blade(c-Z*.026,k*2.4,.04,.024,.06,3,.08)
    if not sprouts:
        c=Z*(h+.04);r=.19 if name=='Broccoli' else .22
        for j in range(28):
            a=j*2.39996;rr=r*sqrt(j/28);p=c+radial(a,rr,.09*sqrt(1-j/28));size=random.uniform(.032,.055)
            b.ellipsoid(p,(size,size,size*.7),0 if j%3 else 4,8,12)
            for k in range(11):
                q=p+radial(k*2.4,size*sqrt(k/11),size*.6*sqrt(1-k/11));b.ellipsoid(q,(.009,)*3,0,4,6)
        if name=='Cauliflower':
            for j in range(5):
                a=j*2.4;blade(g,radial(a,.12,.12),radial(a,.20,.58),.13,2,broad=True)
    else:
        for j in range(7):
            a=j*2.4;blade(g,Z*h,Z*h+radial(a,.23,.17),.10,2,broad=True)

def produce(name,g,b):
    if name in ['Broccoli','Cauliflower','Brussels sprouts']:return brassica(name,g,b)
    if name=='Leek':
        for j in range(5):
            p=radial(j*2.4,.10);g.tube([p,p+Z*.25,p+Z*.37],[.022,.027,.021],6,12)
            for k in range(8):
                a=(k%2)*pi+j*.45;blade(g,p+Z*(.18+k*.025),p+radial(a,.19+.035*k,.60+random.random()*.15),.025,4)
        b.tube([Z*.015,Z*.18],[.027,.027],0,12)
    elif name=='Hemp':
        h=1.85;g.tube([Z*.01,Z*h],[.014,.003],0,10)
        for j in range(11):
            a=j*2.4;p=Z*(.22+j*.13);ll=.38*(1-j*.045);end=p+radial(a,ll,.18)
            g.tube([p,end],[.005,.0015],0,5)
            for m in [0,1,2]:
                q=p.lerp(end,[.40,.72,1.0][m]);length=.34*(1-j*.035)
                # Seven distinctly separate, long, serrated palmate leaflets.
                for k in range(7):
                    angle=a+(k-3)*.39;l=length*(1-abs(k-3)*.18)
                    blade(g,q,q+radial(angle,l,.016),l*.115,1 if j%3 else 2,True)
            for k in range(4):
                c=end+Z*k*.019;b.ellipsoid(c,(.012,.012,.018),3,5,8)
                b.leaf(c,c+radial(a+k,.045,.018),.009,3,.1,4)
        for k in range(6):b.ellipsoid(Z*(h-.015*k),(.014,.014,.018),3,5,8)
    elif name=='Capsicum':
        for j in range(6):
            a=j*2.4;p=radial(a,.25,random.uniform(.55,.8));g.tube([Z*.02,Z*.3,p],[.016,.009,.003],0,6)
            for k in range(6):
                q=Z*.25+(p-Z*.25)*(k+1)/7;blade(g,q,q+radial(a+k*2.4,.21,.035),.065,3)
            c=p-Z*.11;fruit(b,c,.085,name,0 if j%3 else 4)
            star(b,p+radial(a,.07,.01),.025,5,1)
    elif name=='Rhubarb':
        for j in range(12):
            a=j*2.4;q=radial(a,random.uniform(.26,.50),random.uniform(.32,.57));g.tube([radial(a,.04),q*.5+Z*.12,q],[.022,.019,.012],8,9)
            blade(g,q,q+radial(a,.38,-.08),.29,1,broad=True)
            b.tube([radial(a,.06),q*.85],[.018,.014],0,8)
    elif name=='Globe artichoke':
        for j in range(18):
            a=j*2.4;p=radial(a,.05,.08);end=radial(a,random.uniform(.48,.75),random.uniform(.14,.33));blade(g,p,end,.16,4,True,False,5)
        for j in range(4):
            a=j*2.4;p=radial(a,.22,random.uniform(.65,.95));g.tube([Z*.05,p],[.025,.009],0,8)
            for ring in range(6):
                z=ring*.029;r=.105*sin((ring/7+.25)*pi)
                for k in range(9):
                    angle=k*2*pi/9+ring*.36;base=p+radial(angle,r*.70,z-.02)
                    b.cupped_blade(base,angle,r*.48,.038,.068,0 if ring%2 else 4,.03)
    elif name=='Asparagus':
        for j in range(9):
            a=j*2.4;p=radial(a,.22*sqrt(j/9));h=random.uniform(.28,.60)
            b.tube([p,p+Z*(h-.05),p+Z*h],[.018,.014,.002],3,10)
            for k in range(12):
                q=p+Z*(h-.15+k*.012);b.leaf(q,q+radial(k*2.4,.012,.028),.010,0,.1,4)
        for j in range(3):
            a=j*2.4;top=radial(a,.16,1.1+random.random()*.25);g.tube([radial(a,.08),top],[.008,.001],0,6)
            for k in range(9):
                p=top*(.25+k*.075);end=p+radial(a+k*2.4,.24,.12);g.tube([p,end],[.002,.0005],0,4)
                for m in range(7):
                    q=p.lerp(end,m/7)
                    for s in [-1,1]:g.leaf(q,q+radial(a+k*2.4+s,.09,.02),.0025,2,.1,3)

def build(name,category,g,b):
    if 'bamboo' in name.lower():bamboo(name,g,b)
    elif name.startswith('Rose '):rose(name,g,b)
    elif name in ['Giant redwood','Coast redwood']:conifer(name,g,b)
    elif category=='Trees' or 'gum' in name:tree(name,g,b)
    elif category=='Flowers':flowers(name,g,b)
    elif name=='Waratah':waratah(g,b)
    elif name=='Gymea lily':gymea(g,b)
    elif category=='Produce':produce(name,g,b)
    else:raise ValueError('Missing morphology: '+name)
