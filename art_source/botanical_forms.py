"""Species morphology for the original procedural meshes; see botanical_references.md.
Units are garden-scale metres. Shared primitives express distinct botanical organs,
not interchangeable generic spikes. All randomness is seeded by the caller.
"""
import math, random
from math import sin, cos, pi, sqrt
from mathutils import Vector


def radial(a, r, z=0): return Vector((cos(a)*r,sin(a)*r,z))

def palmate(g, p, length, angle, mat=1, lobes=5):
    p=Vector(p); start=len(g.v)
    g.v.append(tuple(p+Vector((0,0,.015))))
    # A connected blade with deep sinuses, rather than separate compound leaflets.
    rim=[p-radial(angle,length*.12)]
    for j in range(lobes*2-1):
        t=j/(lobes*2-2); a=angle+(t-.5)*2.6
        r=length*(.7+.3*sin(pi*t))*(1.0 if j%2==0 else .38)
        rim.append(p+radial(a,r,.025*sin(pi*t)))
    rim.append(rim[0])
    g.v.extend(tuple(v) for v in rim)
    for j in range(len(rim)-1): g.face((start,start+j+1,start+j+2),mat)

def compound(g,p,end,mat=1,fine=False):
    p=Vector(p); end=Vector(end); d=end-p
    g.tube([p,end],[.003,.001],0,3)
    side=Vector((-d.y,d.x,.03)).normalized()
    for k in range(1,4 if fine else 5):
        loc=p.lerp(end,k/(4 if fine else 5)); ll=d.length*(.38 if fine else .32)*(1-k*.09)
        for sign in [-1,1]:
            tip=loc+side*sign*ll+d*.12
            if fine:
                g.tube([loc,tip],[.0018,.0006],0,3)
                for m in range(1,4):
                    q=loc.lerp(tip,m/4)
                    for s in [-1,1]: g.leaf(q,q+d.normalized()*s*ll*.28,.004,mat,.1,2)
            else: g.leaf(loc,tip,ll*.35,mat,.1,4,True)
    g.leaf(end-d*.17,end+d*.14,d.length*.07,mat,.1,4)

def round_leaf(g,p,r,mat=1,kidney=False):
    p=Vector(p); start=len(g.v); g.v.append(tuple(p+Vector((0,0,r*.12))))
    for j in range(17):
        a=j*2*pi/16; rr=r*(.65+.35*(1-cos(a))*.5) if kidney else r
        g.v.append(tuple(p+radial(a,rr,sin(a)*r*.15)))
    for j in range(16): g.face((start,start+j+1,start+j+2),mat)

def tendril(g,p,a):
    pts=[Vector(p)+radial(a+t*.55,.018+t*.002,t*.008) for t in range(15)]
    g.tube(pts,[.002]*15,0,3)

def strap_clump(g,count,height,width,mat=1,spread=.38):
    for j in range(count):
        a=j*2.39996; h=height*random.uniform(.55,1.0)
        base=radial(a,random.uniform(.01,.12))
        g.leaf(base,radial(a,spread*random.uniform(.5,1.1),h*.6),width,mat,.65,8)

def brush(g,p,length,radius,mat=0,curved=False):
    p=Vector(p)
    for k in range(9):
        for j in range(10):
            a=j*2*pi/10+k*.37; base=p+Vector((0,0,k*length/9))
            end=base+radial(a,radius,length*.12)
            pts=[base,base+radial(a,radius*.7,length*.24),end] if curved else [base,end]
            g.tube(pts,[.0035]*len(pts),mat,3)
            g.ellipsoid(end,(.005,)*3,1,2,4)

def floret(g,p,size,petals=5,mat=0):
    p=Vector(p)
    for j in range(petals):
        a=j*2*pi/petals
        g.leaf(p,p+radial(a,size,.007),size*.43,mat,.3,3)
    g.ellipsoid(p,(size*.2,)*3,1,3,5)

def pea_flower(g,p,size):
    p=Vector(p)
    g.leaf(p,p+Vector((0,.03,size)),size*.7,0,.5,5)
    for sign in [-1,1]: g.leaf(p,p+Vector((sign*size*.8,-size*.2,0)),size*.32,0,.4,4)
    g.ellipsoid(p+Vector((0,-size*.4,-size*.15)),(size*.23,size*.5,size*.22),0,4,7)

def bell(g,p,size):
    # Open trumpet: rings rather than petals masquerading as a bell.
    p=Vector(p); start=len(g.v)
    for k,(r,z) in enumerate([(size*.18,size*.8),(size*.48,size*.45),(size*.55,0),(size*.7,-size*.15)]):
        for j in range(10):
            a=j*2*pi/10; g.v.append(tuple(p+radial(a,r,z+(.012*cos(a*5) if k==3 else 0))))
    for k in range(3):
        for j in range(10): g.face((start+k*10+j,start+k*10+(j+1)%10,start+(k+1)*10+(j+1)%10,start+(k+1)*10+j),0)

def iris(g,p):
    p=Vector(p)
    for j in range(3):
        a=j*2*pi/3
        g.leaf(p,p+radial(a,.14,.16),.065,0,.55,6)
        g.leaf(p,p+radial(a+pi/3,.21,-.09),.08,0,.55,6)
        g.leaf(p+radial(a+pi/3,.055,.018),p+radial(a+pi/3,.14,-.025),.016,1,.2,4)

def flower_head(g,p,size,style):
    p=Vector(p)
    if style=='iris': iris(g,p); return
    if style=='pea': pea_flower(g,p,size); return
    if style=='bell': bell(g,p,size); return
    count={'cosmos':8,'daisy':20,'sunflower':28,'poppy':4,'clematis':6,'magnolia':9,'cherry':5}.get(style,5)
    for j in range(count):
        a=j*2*pi/count
        width=size*(.70 if style=='poppy' else .3 if count<10 else .11)
        z=size*(.4 if style in ['poppy','magnolia'] else .05)
        g.leaf(p+radial(a,size*.15),p+radial(a,size,z),width,0,.45 if style=='poppy' else .18,6)
    g.ellipsoid(p+Vector((0,0,.012)),(size*.35,size*.35,size*.15),1,4,10)

def tree(name,g,b,flower):
    H={'Cherry blossom':4.5,'Silver birch':6.4,'Japanese maple':3.6,'Olive':4.2,'Willow':5.3,'Magnolia':4.3,'Lemon':3.5,'Apple':4.1,'Eucalyptus':7.5}[name]
    eucalyptus=name=='Eucalyptus'; willow=name=='Willow'; maple=name=='Japanese maple'
    trunkmat=6 if name in ['Eucalyptus','Silver birch'] else 5
    g.tube([(0,0,0),(.12,-.06,H*.25),(-.10,.12,H*.55),(.20,.05,H*.83)], [.16,.12,.08,.018],trunkmat,9)
    if name=='Silver birch':
        for k in range(22):
            z=.18+k*H*.033; a=k*2.4
            g.tube([radial(a-.5,.151-k*.0028,z),radial(a,.156-k*.0028,z+.015),radial(a+.5,.15-k*.0028,z+.004)],[.009]*3,5,3)
    if eucalyptus:
        # Pale irregular patches on a smooth trunk, not a chestnut bark texture.
        for j in range(12):
            a=j*2.4; z=.12+j*.33
            g.leaf(radial(a,.15-j*.006,z),radial(a,.16-j*.006,z+.42),.05,7,.02,4)
    branches=15 if eucalyptus else 20
    for j in range(branches):
        a=j*2.39996+random.uniform(-.25,.25)
        t=j/(branches-1)
        z=H*random.uniform(.42,.78) if eucalyptus else H*(.25+t*.39)
        length=H*(.34 if maple or willow else .22 if name=='Silver birch' else .28)*(1-t*.35)*random.uniform(.8,1.15)
        start=Vector((0,0,z))
        if eucalyptus: length*=random.uniform(.75,1.3)
        end=start+radial(a,length,H*(.05 if maple else random.uniform(.08,.22) if eucalyptus else .13))
        mid=start.lerp(end,.45)+Vector((0,0,H*.08))
        g.tube([start,mid,end],[.055,.035,.009],trunkmat,6)
        for k in range(6):
            joint=mid.lerp(end,k/6); aa=a+(k%3-1)*.65
            tip=joint+radial(aa,.4+random.random()*.25,.25)
            if willow:
                tip=joint+radial(aa,.28,-random.uniform(1.0,2.2))
                curve=joint+radial(aa,.35,-.12)
                g.tube([joint,curve,tip],[.013,.009,.002],5,4)
            else: g.tube([joint,tip],[.014,.003],trunkmat,4)
            for l in range(15 if not willow else 21):
                p=joint.lerp(tip,l/(15 if not willow else 21)); angle=aa+l*2.4
                ll=.36 if eucalyptus else .25 if willow else .14 if name=='Silver birch' else .19 if name=='Olive' else .27 if name=='Magnolia' else .20
                leafmat=4 if name in ['Eucalyptus','Olive'] else 8 if maple else 1+l%3
                if maple: palmate(g,p,ll,angle,leafmat,5); continue
                droop=-ll*.72 if eucalyptus or willow else random.uniform(-.07,.1)
                g.leaf(p,p+radial(angle,ll*.8,droop),ll*(.10 if willow else .13 if eucalyptus or name=='Olive' else .36),leafmat,.2,4)
            if name in ['Cherry blossom','Magnolia']:
                for l in range(3 if name=='Cherry blossom' else 1): flower_head(b,tip+radial(l*2.4,.10),.105 if name=='Cherry blossom' else .22,'cherry' if name=='Cherry blossom' else 'magnolia')
            if name in ['Apple','Lemon','Olive'] and k%3==0:
                size=.09 if name!='Olive' else .035
                b.ellipsoid(tip-Vector((0,0,size)),(size*.85,size*.85,size*(1.3 if name=='Lemon' else 1)),0,6,10)

def shrub(name,g,b,flower):
    settings={
      'Rose':(1.15,.60,19,.19,.06),'Azalea':(.85,.60,24,.12,.045),
      'Rosemary':(1.0,.48,27,.10,.012),'Camellia':(1.4,.62,23,.21,.08),
      'Lilac':(1.55,.65,20,.23,.10),'Boxwood':(.85,.55,34,.085,.036),
      'Gardenia':(1.0,.55,24,.19,.08),'Blueberry':(1.25,.60,22,.15,.052),
      'Wattle':(1.75,.8,22,.20,.025),'Bottlebrush':(1.55,.68,23,.21,.025),
      'Grevillea':(1.25,.72,20,.26,.022),'Banksia':(1.6,.65,19,.29,.067),
      'Lilly pilly':(1.5,.65,26,.18,.052),'Waxflower':(1.05,.52,23,.085,.009),
      'Hydrangea':(1.1,.7,17,.26,.12)}
    height,spread,count,ll,width=settings[name]
    for j in range(count):
        a=j*2.39996; r=spread*sqrt((j+.5)/count)
        tip=radial(a,r,height*(.40+.60*sqrt(max(0,1-(r/spread)**2))))
        base=radial(a,.08)
        middle=tip*.5+radial(a,.06,.06)
        g.tube([base,middle,tip],[.018,.010,.003],5,5)
        for k in range(13):
            p=base.lerp(tip,.12+k*.067); aa=a+k*2.4
            leafmat=4 if name=='Rosemary' else 1+k%3
            if name=='Rose': compound(g,p,p+radial(aa,ll*1.3,.04),leafmat); continue
            if name in ['Grevillea','Wattle']:
                compound(g,p,p+radial(aa,ll,.04),leafmat,name=='Wattle'); continue
            for sign in [-1,1] if name in ['Rosemary','Hydrangea','Lilac','Boxwood','Lilly pilly','Waxflower'] else [1]:
                g.leaf(p,p+radial(aa+(pi if sign<0 else 0),ll,.04),width,leafmat,.18,8,name=='Banksia')
        if name=='Boxwood': continue
        if name=='Bottlebrush': brush(b,tip,.25,.095); continue
        if name=='Grevillea': brush(b,tip,.14,.13,curved=True); continue
        if name=='Banksia':
            b.ellipsoid(tip+Vector((0,0,.12)),(.08,.08,.20),0,8,12)
            brush(b,tip-Vector((0,0,.06)),.35,.105,curved=True); continue
        if name=='Wattle':
            for k in range(12):
                p=tip+radial(k*2.4,.12,(k%4)*.045)
                b.ellipsoid(p,(.026,)*3,0,4,7)
            continue
        if name=='Lilac':
            for k in range(45):
                t=k/45; floret(b,tip+radial(k*2.4,.14*(1-t),t*.32),.025,4)
            continue
        if name=='Hydrangea':
            for k in range(40):
                t=(k+.5)/40; a=k*2.4
                floret(b,tip+radial(a,.23*sqrt(1-t*t),t*.21),.046,4)
            continue
        if name in ['Blueberry','Lilly pilly']:
            for k in range(6): b.ellipsoid(tip+radial(k*2.4,.07,-.04-k*.018),(.038,)*3,0,4,7)
            continue
        if name=='Rosemary':
            for k in range(5): pea_flower(b,tip-Vector((0,0,k*.048)),.025)
        elif name=='Waxflower':
            for k in range(5): floret(b,tip+radial(k*2.4,.07,k*.018),.035)
        elif name=='Azalea':
            for k in range(3): flower_head(b,tip+radial(k*2.4,.07),.10,'azalea')
        else: flower(b,tip,.13 if name=='Rose' else .14,'rose')

def ground(name,g,b,flower):
    if name in ['Blue fescue','Feather grass','Sedge','Fountain grass','Lomandra']:
        h={'Blue fescue':.35,'Feather grass':.7,'Sedge':.65,'Fountain grass':.85,'Lomandra':.75}[name]
        width={'Blue fescue':.003,'Feather grass':.002,'Sedge':.015,'Fountain grass':.008,'Lomandra':.022}[name]
        strap_clump(g,85,h,width,8 if name=='Blue fescue' else 1,.28 if name=='Blue fescue' else .43)
        for j in range(9):
            a=j*2.4; tip=radial(a,.32,h*1.15)
            g.tube([(0,0,.03),tip*.65+Vector((0,0,.16)),tip],[.003,.002,.001],0,3)
            if name=='Fountain grass':
                b.ellipsoid(tip,(.029,.029,.15),0,6,8)
                for k in range(16):
                    p=tip+Vector((0,0,(k/16-.5)*.28)); b.tube([p,p+radial(k*2.4,.045,.03)],[.0015,.0005],0,3)
            else:
                for k in range(6):
                    p=tip-Vector((0,0,k*.024)); end=p+radial(k*2.4,.065,.03)
                    b.tube([p,end],[.0015,.0005],0,3)
                    b.ellipsoid(end,(.008,.008,.025),0,3,5)
        return
    for j in range(65 if name=='Moss carpet' else 42):
        a=j*2.4; r=sqrt(j/65 if name=='Moss carpet' else j/42)*.46; p=radial(a,r,.018)
        if name=='Moss carpet':
            for k in range(5): g.leaf(p,p+radial(k*2.4,.035,.05),.013,1+j%3,.1,3)
        elif name=='Dichondra':
            end=p+Vector((0,0,.035)); g.tube([p,end],[.002,.001],0,3); round_leaf(g,end,.065,1+j%3,True)
        elif name=='Chamomile':
            tip=p+Vector((0,0,random.uniform(.16,.30)))
            g.tube([p,tip],[.003,.001],0,3)
            compound(g,p+Vector((0,0,.08)),p+radial(a,.13,.1),1,True)
            if j%2==0: flower_head(b,tip,.044,'daisy')
        else:
            end=p+radial(a,.08,.065); g.tube([p,end],[.002,.001],0,3)
            for k in range(4):
                loc=p.lerp(end,k/4)
                for sign in [-1,1]: g.leaf(loc,loc+radial(a+sign*pi/2,.026,.01),.012,1+j%3,.1,3)
            if j%2==0:
                for k in range(3): floret(b,end+radial(k*2.4,.018,.008),.014)

def herb_flower(name,g,b,flower):
    if name=='Lavender':
        # Woody cushion below long, largely bare, vertical flowering stalks.
        for j in range(40):
            a=j*2.4; r=.34*sqrt(j/40); h=.25+random.random()*.12
            end=radial(a,r,h); g.tube([radial(a,.05),end],[.006,.002],5,4)
            for k in range(11):
                p=end*(.10+k*.085)
                for sign in [-1,1]: g.leaf(p,p+radial(a+sign*pi/2,.12,.04),.015,4,.1,3)
            tip=end+radial(a,.045,random.uniform(.27,.44)); g.tube([end,tip],[.003,.001],0,4)
            for k in range(6):
                for l in range(5):
                    loc=tip+radial(l*2*pi/5+k*.3,.016,k*.021)
                    b.ellipsoid(loc,(.013,.011,.016),0,3,5)
        return
    if name in ['Sweet pea','Clematis']:
        for j in range(4):
            a=j*pi/2; points=[radial(a+k*.6,.13+k*.012,k*.15) for k in range(10)]
            g.tube(points,[.005-k*.00035 for k in range(10)],0,4)
            for k in range(2,10):
                p=points[k]; aa=a+k*.7
                if name=='Sweet pea':
                    for sign in [-1,1]: g.leaf(p,p+radial(aa+sign*.7,.15,.03),.055,1,.1,4)
                    tendril(g,p,aa)
                else:
                    for sign in [-1,0,1]: g.leaf(p,p+radial(aa+sign*.8,.18,.04),.06,1,.15,4)
                if k%2: flower_head(b,p+radial(aa,.12),.10 if name=='Sweet pea' else .17,'pea' if name=='Sweet pea' else 'clematis')
        return
    if name=='Nasturtium':
        for j in range(6):
            a=j*2.4; tip=radial(a,.55,.035); g.tube([(0,0,.03),tip],[.006,.002],0,4)
            for k in range(1,5):
                p=tip*k/5; end=p+Vector((0,0,.12)); g.tube([p,end],[.003,.002],0,3); round_leaf(g,end,.095,1+k%3)
                if k%2: flower_head(b,end+radial(a,.12,.055),.065,'nasturtium')
        return
    if name in ['Iris','Kangaroo paw']: strap_clump(g,22,.70,.027 if name=='Iris' else .018,1,.28)
    if name in ['Foxglove','Poppy','Daisy','Billy buttons']:
        for j in range(15):
            a=j*2.4; ll=.33 if name=='Foxglove' else .18
            g.leaf((0,0,.018),radial(a,ll,.075),ll*.23,1+j%3,.32,6,name=='Poppy')
    count=3 if name in ['Sunflower','Foxglove'] else 6 if name in ['Iris','Kangaroo paw'] else 9
    heights={'Sunflower':1.75,'Foxglove':1.5,'Iris':.83,'Kangaroo paw':1.15,'Billy buttons':.62,'Peony':.72,'Poppy':.72,'Daisy':.48,'Cosmos':1.0}
    for j in range(count):
        a=j*2.4; base=radial(a,.12); tip=radial(a,.20,heights[name]*random.uniform(.8,1.1))
        g.tube([base,tip],[.012 if name=='Sunflower' else .005,.003],0,5)
        if name not in ['Iris','Kangaroo paw','Billy buttons','Daisy']:
            for k in range(5):
                p=base.lerp(tip,.2+k*.13); aa=a+k*2.4
                if name in ['Cosmos','Peony']:
                    compound(g,p,p+radial(aa,.25,.06),1+k%3,name=='Cosmos')
                else:
                    ll=.29 if name=='Sunflower' else .16
                    g.leaf(p,p+radial(aa,ll,.06),ll*.4,1+k%3,.3,5,name=='Poppy')
        if name=='Foxglove':
            for k in range(13):
                p=tip-Vector((0,0,k*.048)); end=p+Vector((.055,0,-.025))
                g.tube([p,end],[.003,.001],0,3); bell(b,end,.035+k*.002)
        elif name=='Kangaroo paw':
            for k in range(3):
                end=tip+radial(a+k*.6,.10,k*.095)
                g.tube([tip,end],[.006,.003],0,4)
                for l in range(3):
                    loc=end+Vector((0,0,l*.03)); mouth=loc+radial(a,.10,.055)
                    b.tube([loc,loc.lerp(mouth,.6),mouth],[.012,.014,.01],0,6)
                    for t in range(6):
                        aa=t*pi/3; b.leaf(mouth,mouth+radial(aa,.022,.016),.006,0,.1,3)
        elif name=='Billy buttons': b.ellipsoid(tip,(.045,)*3,0,7,12)
        elif name=='Peony': flower(b,tip,.16,'rose')
        else:
            start=len(b.v)
            flower_head(b,tip,.26 if name=='Sunflower' else .11 if name=='Cosmos' else .13 if name=='Poppy' else .065 if name=='Daisy' else .15,name.lower())
            if name=='Sunflower':
                for n in range(start,len(b.v)):
                    v=Vector(b.v[n])-tip
                    b.v[n]=tuple(tip+Vector((v.x,v.y*cos(1.15)-v.z*sin(1.15),v.y*sin(1.15)+v.z*cos(1.15))))

def produce(name,g,b,flower):
    if name=='Corn':
        for j in range(2):
            base=radial(j*pi,.14); h=1.85+j*.12
            g.tube([base,base+Vector((0,0,h))],[.027,.009],0,7)
            for k in range(9):
                p=base+Vector((0,0,.2+k*.16)); a=j+k*pi
                g.leaf(p,p+radial(a,.65,.07),.06,1+k%3,.8,8)
            for k in range(7):
                p=base+Vector((0,0,h-.13)); end=p+radial(k*2.4,.14,.30)
                b.tube([p,end],[.004,.001],1,3)
            for k in range(2):
                p=base+Vector((.08*(-1 if k else 1),0,.8+k*.3))
                b.ellipsoid(p,(.05,.05,.17),0,8,10)
                for l in range(3): g.leaf(p-Vector((0,0,.17)),p+radial(l*2.4,.055,.21),.035,1,.3,6)
        return
    if name in ['Pumpkin','Melon','Cucumber']:
        for j in range(4):
            a=j*2.4; tip=radial(a,.72,.05); g.tube([(0,0,.02),tip],[.01,.004],0,5)
            for k in range(1,5):
                p=tip*k/5; end=p+Vector((0,0,.18)); g.tube([p,end],[.006,.003],0,4)
                palmate(g,end,.27 if name=='Pumpkin' else .21,a+k,1+k%3,5)
                if k%2: tendril(g,p,a)
            loc=tip*.8+Vector((0,0,.12))
            b.ellipsoid(loc,(.19,.19,.15) if name=='Pumpkin' else (.16,.19,.15) if name=='Melon' else (.05,.05,.20),0,9,20,.12 if name=='Pumpkin' else 0)
            b.tube([loc+Vector((0,0,.12)),loc+Vector((.03,0,.20))],[.018,.012],2,5)
        return
    if name=='Lettuce':
        for j in range(30):
            a=j*2.4; t=j/30
            g.leaf((0,0,.015+t*.13),radial(a,.30*(1-t*.65),.12+t*.2),.12*(1-t*.5),8,.8,9,True)
        return
    if name in ['Carrot','Radish','Beetroot','Strawberry']:
        for j in range(10):
            a=j*2.4; end=radial(a,.16,.22+random.random()*.12)
            g.tube([(0,0,.015),end],[.004,.002],8 if name=='Beetroot' else 0,4)
            if name=='Carrot': compound(g,end*.3,end+radial(a,.08,.1),1,True)
            elif name=='Strawberry':
                for k in [-1,0,1]: g.leaf(end,end+radial(a+k*.8,.13,.015),.06,1,.2,7,True)
                if j%3==0:
                    p=end-Vector((0,0,.13)); b.ellipsoid(p,(.037,.037,.05),0,6,9)
                    for k in range(8): b.ellipsoid(p+radial(k*2.4,.034,(k%3-1)*.02),(.003,)*3,1,2,4)
            else: g.leaf(end*.35,end+radial(a,.11,.025),.085,1+j%3,.4,7,name=='Radish')
        if name in ['Radish','Beetroot']: b.ellipsoid((0,0,.015),(.055,.055,.035),0,5,9)
        return
    if name=='Pea':
        for j in range(4):
            a=j*2.4; tip=radial(a,.22,1.0); g.tube([(0,0,0),tip],[.006,.002],0,4)
            for k in range(6):
                p=tip*(.2+k*.13)
                for sign in [-1,1]: g.leaf(p,p+radial(a+sign,.15,.03),.06,1,.2,4)
                tendril(g,p,a)
                if k%2: b.ellipsoid(p+radial(a,.09,-.08),(.025,.025,.115),0,6,8)
        return
    height={'Basil':.40,'Tomato':1.15,'Aubergine':.85,'Chilli':.72}[name]
    for j in range(7):
        a=j*2.4; tip=radial(a,.30,height*random.uniform(.7,1.0)); g.tube([(0,0,0),tip],[.014,.003],0,5)
        for k in range(6):
            p=tip*(.22+k*.12); aa=a+k*2.4
            if name=='Tomato': compound(g,p,p+radial(aa,.28,.03),1+k%3)
            else:
                ll=.28 if name=='Aubergine' else .12
                for sign in [-1,1] if name=='Basil' else [1]: g.leaf(p,p+radial(aa+sign*1.2,ll,.025),ll*(.40 if name!='Chilli' else .22),1+k%3,.3,6)
        if name=='Basil': continue
        p=tip*.8-Vector((0,0,.06))
        if name=='Chilli': b.tube([p,p+Vector((.02,0,-.07)),p+Vector((.045,0,-.17))],[.024,.017,.001],0,8)
        elif name=='Aubergine': b.ellipsoid(p,(.065,.065,.14),0,7,10)
        else:
            for k in range(3): b.ellipsoid(p+radial(k*2.4,.07,-k*.035),(.065,)*3,0,6,10)


def build(name,category,layer,g,b,flower):
    if layer==3: tree(name,g,b,flower)
    elif layer==2 or name in ['Hydrangea','Waxflower']: shrub(name,g,b,flower)
    elif category=='Grasses' or name=='Lomandra': ground(name,g,b,flower)
    elif category=='Produce': produce(name,g,b,flower)
    else: herb_flower(name,g,b,flower)
