"""Pond life and ten insect designs; anatomically distinct wings/legs and motion."""
import math,numpy as np
from common_hq import *

def frog():
    m=palette();r=pivot('frog');body=pivot('Body',(0,.075,0),r)
    skin=material('HQ olive frog skin',(.18,.28,.095),'stone',.48)
    throat=material('HQ pale frog throat',(.56,.58,.34),'stone',.63)
    volumes=[ell('Frog torso',(0,0,.032),(.19,.13,.27),skin,body,36,24),ell('Broad frog snout',(0,.017,-.073),(.20,.089,.15),skin,body,36,24)]
    fuse_surface(volumes,.0045)
    ell('Pale throat',(0,-.037,-.067),(.15,.028,.11),throat,body,32,16)
    legs=[]
    for side in [-1,1]:
        leg=pivot('BackL' if side<0 else 'BackR',(side*.080,-.025,.073),body)
        ell('Folded frog thigh',(side*.02,0,0),(.098,.071,.15),skin,leg,28,16)
        curve('Folded frog calf',[(side*.031,-.018,.052),(side*.056,-.026,-.002),(side*.044,-.038,-.069)],[.020,.014,.009],skin,leg,14)
        for j in range(4):curve('Long hind toe',[(side*.044,-.039,-.071),(side*(.032+j*.015),-.042,-.107),(side*(.033+j*.021),-.045,-.139)],[.0037,.0026,.0007],skin,leg,8)
        front=pivot('FrontL' if side<0 else 'FrontR',(side*.070,-.013,-.049),body)
        curve('Bent forelimb',[(0,0,0),(side*.035,-.026,.007),(side*.041,-.050,-.038)],[.010,.008,.0045],skin,front,12)
        for j in range(3):curve('Splayed front finger',[(side*.041,-.051,-.038),(side*(.038+j*.013),-.052,-.068)],[.003,.0005],skin,front,8)
        ell('Eye mound',(side*.063,.048,-.071),(.063,.054,.062),skin,body,28,18)
        ell('Golden frog iris',(side*.064,.063,-.091),(.034,.031,.019),m['metal'],body,24,16)
        ell('Horizontal frog pupil',(side*.064,.064,-.102),(.028,.010,.008),m['black'],body,20,12)
        legs.append(leg)
    spots=material('HQ frog dorsal spots',(.065,.115,.035),'stone',.53)
    for x,z in [(-.045,.04),(.030,.056),(-.017,.098),(.051,.012),(-.048,-.005)]:
        ell('Flush dorsal mottling',(x,.056,z),(.022,.003,.016),spots,body,16,10)
    def idle(t,rest):body.scale.z=1+.015*math.sin(t*math.tau)
    def hop(t,rest):
        a=math.sin(t*math.pi)**2;body.location.z=rest[body][0].z+.045*a
        for leg in legs:leg.rotation_euler.x=-.65*math.sin(t*math.tau)
    animate(r,[('idle',4,idle),('hop',.8,hop)])
    return r

def fish():
    m=palette();r=pivot('fish');body=pivot('Body',(0,0,0),r)
    copper=material('HQ koi copper scales',(.53,.25,.088),'scale',.43)
    cream=material('HQ koi cream scales',(.70,.66,.53),'scale',.44)
    finmat=material('HQ translucent fish fin',(.53,.48,.36),'feather',.40,alpha=.85)
    loft('Sculpted koi body',[(-.24,0,.005,.007),(-.205,.005,.041,.049),(-.15,.006,.063,.075),(-.04,.004,.070,.085),(.07,0,.047,.059),(.16,0,.018,.031),(.19,0,.010,.020)],copper,body,40)
    for side in [-1,1]:
        ell('Cream koi shoulder patch',(side*.054,.013,-.13),(.022,.091,.070),cream,body,28,16)
        ell('Fish eye socket',(side*.033,.021,-.182),(.018,.018,.010),m['black'],body,20,12)
        ell('Fish eye glint',(side*.035,.026,-.185),(.003,.003,.003),m['ivory'],body,10,6)
        for j in range(7):feather('Pectoral fin ray',(side*.036,-.019,-.095),(side*(.10+j*.005),-.020,-.071+j*.014),.005,finmat,body,.004)
        curve('Koi barbel',[(side*.017,-.020,-.212),(side*.022,-.028,-.240)],[.0018,.0005],cream,body,6)
    tail=pivot('Tail',(0,0,.177),body)
    mesh('Forked caudal fin',[(0,0,0),(-.077,.010,.092),(-.068,-.003,.133),(0,0,.103),(.068,-.003,.133),(.077,.01,.092)],[(0,1,2),(0,2,3),(0,3,4),(0,4,5)],finmat,tail,False)
    for j in range(-5,6):curve('Tail fin ray',[(0,.001,0),(j*.012,.001,.118-abs(j)*.003)],[.0007,.0002],cream,tail,6)
    mesh('Dorsal fin',[(0,.065,-.08),(0,.117,-.033),(0,.107,.070),(0,.044,.12)],[(0,1,2),(0,2,3)],finmat,body,False)
    body.rotation_euler.z=-math.pi/2
    def swim(t,rest):
        phase=t*math.tau;tail.rotation_euler.z=.22*math.sin(phase)
        body.rotation_euler.z=-math.pi/2+.025*math.sin(phase-.6)
    animate(r,[('swim',1.3,swim)])
    return r

def wing_membrane(name,parent,end,width,mat,veinmat):
    a=Vector((0,0,0));b=Vector(end);d=b-a;cross=d.cross(Vector((0,1,0))).normalized()
    vs=[d*.50+Vector((0,.001,0))]
    for j in range(33):
        t=j*math.tau/32;p=d*.50+d*.50*math.cos(t)+cross*width*math.sin(t)
        vs.append(p)
    mesh(name,vs,[(0,j+1,j+2) for j in range(32)],mat,parent,False)
    for j in range(8):
        t=(j+1)/9;p=d*t
        curve('Fine wing venation',[(0,.001,0),p*.65+Vector((0,.002,0)),p+cross*width*math.sin(t*math.pi)*.87],[.00055,.00033,.00012],veinmat,parent,5)

def flying_insect(kind):
    m=palette();r=pivot(kind);body=pivot('Body',(0,0,0),r)
    bee=kind in ['bee','blue_banded_bee'];hover=kind=='hoverfly';dragon=kind=='dragonfly';fire=kind=='firefly';butter=kind=='butterfly';moth=kind=='emperor_gum_moth'
    coat=material('HQ insect tawny fuzz',(.51,.32,.10),'fur',size=512) if bee else material('HQ moth thorax fuzz',(.37,.26,.15),'fur',size=512) if moth else material('HQ teal dragonfly chitin',(.035,.28,.25),'scale',.35,.18,size=512) if dragon else material('HQ brown insect cuticle',(.14,.08,.038),'scale',.60,size=512)
    black=material('HQ insect dark cuticle',(.016,.020,.018),'stone',.36,size=512)
    thorax=ell('Thorax',(0,0,-.016),(.034,.032,.039) if bee else (.026,.027,.037),coat,body,28,18)
    length=.11 if dragon else .061 if moth else .042 if bee else .034
    loft('Segmented abdomen',[(-.004,0,.006,.006),(.011,-.001,.016 if bee else .010,.016 if bee else .011),(.032,-.002,.015 if bee else .008,.015 if bee else .008),(length,-.004,.002,.003)],coat,body,24)
    head=pivot('Head',(0,.001,-.038),body)
    ell('Insect head',(0,0,0),(.025,.025,.022),black,head,24,16)
    for side in [-1,1]:
        ell('Compound eye',(side*.008,.003,-.003),(.015,.019,.013),coat if dragon else m['black'],head,24,16)
        if not dragon:
            ant=.0035 if hover else .020
            if moth:
                curve('Feathery antenna shaft',[(side*.005,.008,-.005),(side*.012,.026,-.020)],[.0008,.0004],coat,head,6)
                for j in range(8):
                    p=Vector((side*(.006+j*.0008),.010+j*.002,-.006-j*.0017))
                    for flank in [-1,1]:curve('Antenna comb',[p,p+Vector((side*.007*math.sin((j+1)*math.pi/9),0,flank*.003))],[.0004,.0001],coat,head,5)
            else:curve('Short fly antenna' if hover else 'Jointed antenna',[(side*.005,.008,-.005),(side*.007,.008+ant*.65,-.010),(side*.011,.008+ant,-.013)],[.0007,.0005,.0002],black,head,6)
    if bee or hover:
        band=material('HQ turquoise bee hair bands',(.07,.35,.43),'fur') if kind=='blue_banded_bee' else black if bee else material('HQ hoverfly yellow bands',(.57,.40,.055),'stone',.43,size=512)
        for j in range(4):
            z=.005+j*.009
            ell('Abdominal colour band',(0,-.001,z),(.029-j*.001,.030-j*.001,.0043),band,body,24,12)
    if dragon:
        for j in range(7):ell('Dragonfly abdominal ring',(0,-.003,.014+j*.013),(.015-j*.001,.015-j*.001,.003),black,body,18,10)
    legs=[]
    for side in [-1,1]:
        for j in range(3):
            p=(side*.009,-.007,-.029+j*.013);leg=pivot(('LegL' if side<0 else 'LegR')+str(j),p,body)
            curve('Jointed insect leg',[(0,0,0),(side*.014,-.011,-.006+j*.004),(side*.020,-.027,.001+j*.003),(side*.025,-.028,-.005+j*.003)],[.0015,.0012,.0007,.0002],black,leg,8)
            legs.append(leg)
    wings=[]
    clear=material('HQ delicate insect membrane',(.72,.81,.78),None,.30,alpha=.35)
    vein=material('HQ insect wing veins',(.28,.33,.28),None,.62)
    ochre=material('HQ butterfly ochre scales',(.61,.27,.073),'scale')
    mothcoat=material('HQ emperor moth buff scales',(.37,.26,.15),'scale')
    for side in [-1,1]:
        w=pivot('WingL' if side<0 else 'WingR',(side*.009,.009,-.019),r);w['side']=side
        for j in range(1 if hover else 2):
            span=.103 if moth else .077 if butter else .10 if dragon else .049
            end=(side*span,0,-.040+j*.065)
            width=.035 if moth else .027 if butter else .009 if dragon else .011
            wingmat=mothcoat if moth else ochre if butter else clear
            wing_membrane('Forewing' if j==0 else 'Hindwing',w,end,width,wingmat,vein)
            if butter or moth:
                c=Vector(end)*.67+Vector((0,.002,0));rad=.016 if moth else .013
                ell('Flush dark wing eyespot',c,(rad*2,.0015,rad*2),black,w,24,12)
                ell('Amber eyespot ring',c+Vector((0,.001,0)),(rad*1.70,.001,rad*1.70),ochre,w,24,12)
                ell('Eye spot centre',c+Vector((0,.0015,0)),(rad*1.12,.001,rad*1.12),black,w,24,12)
            if butter:
                for k in range(5):
                    p=Vector(end)*(.61+k*.075)+Vector((0,.001,(k-2)*.004))
                    ell('Pale border marking',p,(.005,.001,.005),m['ivory'],w,12,6)
        wings.append(w)
    if fire:
        glow=material('HQ firefly abdominal light',(.49,.68,.072),None,.42)
        bs=glow.node_tree.nodes['Principled BSDF'];bs.inputs['Emission Color'].default_value=(.5,.75,.08,1);bs.inputs['Emission Strength'].default_value=2.5
        ell('Localized luminous abdomen',(0,-.003,.033),(.014,.014,.016),glow,body,24,16)
    def flight(t,rest):
        phase=t*math.tau
        for side,w in zip([-1,1],wings):
            w.rotation_euler.y=side*(.49 if moth else .65 if butter else .34)*math.sin(phase)
            w.rotation_euler.z=side*.025*math.sin(phase-.35)
        body.rotation_euler.x=.025*math.sin(phase-.8)
    def perch(t,rest):
        body.scale.z=1+.009*math.sin(t*math.tau)
        for side,w in zip([-1,1],wings):w.rotation_euler.y=side*(1.0 if butter else .17)*(.99+.01*math.sin(t*math.tau))
    def pollinate(t,rest):
        body.rotation_euler.x=.17+.025*math.sin(t*math.tau*4)
        for side,w in zip([-1,1],wings):w.rotation_euler.y=side*.12
    clips=[('flight',.90 if moth else .60 if butter else .14 if dragon else .10,flight),('perch',3,perch)]
    if not moth and not dragon:clips.append(('pollinate',1.4,pollinate))
    animate(r,clips)
    return r

def mantis():
    m=palette();r=pivot('mantis');body=pivot('Body',(0,.039,0),r)
    green=material('HQ mantis leaf-green cuticle',(.16,.33,.078),'stone',.62,size=512)
    loft('Mantis abdomen',[(-.006,0,.004,.004),(.022,0,.012,.010),(.055,0,.014,.011),(.091,-.003,.008,.006),(.106,-.004,.001,.002)],green,body,24)
    curve('Long mantis prothorax',[(0,0,0),(0,.014,-.032),(0,.020,-.052)],[.008,.005,.004],green,body,14)
    head=pivot('Head',(0,.023,-.056),body)
    mesh('Triangular mantis head',[(-.013,.005,0),(.013,.005,0),(0,-.010,-.004),(-.011,.006,.007),(.011,.006,.007),(0,-.008,.007)],[(0,1,2),(3,5,4),(0,3,4,1),(1,4,5,2),(2,5,3,0)],green,head,False)
    for side in [-1,1]:
        ell('Mantis compound eye',(side*.010,.006,-.003),(.012,.012,.012),green,head,24,16)
        curve('Mantis antenna',[(side*.004,.004,-.003),(side*.006,.013,-.024),(side*.013,.018,-.039)],[.0007,.0005,.00015],m['darkwood'],head,6)
    legs=[]
    for side in [-1,1]:
        front=pivot('ForeL' if side<0 else 'ForeR',(side*.006,.012,-.039),body)
        curve('Grasping foreleg',[(0,0,0),(side*.007,-.005,-.020),(side*.006,.010,-.029),(side*.003,.006,-.008)],[.0037,.004,.0027,.0007],green,front,12)
        for k in range(6):curve('Foreleg grasping spine',[(side*.004,.006,-.010-k*.003),(side*.001,.009,-.010-k*.003)],[.00065,.0001],m['darkwood'],front,5)
        for j in range(2):
            leg=pivot(('LegL' if side<0 else 'LegR')+str(j),(side*.006,0,.007+j*.026),body)
            curve('Mantis walking leg',[(0,0,0),(side*.024,.005,.015),(side*.041,-.031,.019),(side*.042,-.038,.010)],[.0023,.0017,.0012,.0002],green,leg,10)
            legs.append(leg)
    for side in [-1,1]:feather('Folded mantis wing',(side*.006,.009,.012),(side*.010,.004,.101),.011,green,body,.003)
    def idle(t,rest):head.rotation_euler.z=.18*math.sin(t*math.tau);body.rotation_euler.x=.02*math.sin(t*math.tau)
    def crawl(t,rest):
        for j,l in enumerate(legs):l.rotation_euler.z=.13*math.sin(t*math.tau+j*math.pi)
        head.rotation_euler.z=.05*math.sin(t*math.tau)
    animate(r,[('idle',5,idle),('crawl',3,crawl)])
    return r

def leaf_insect():
    m=palette();r=pivot('leaf_insect');body=pivot('Body',(0,.035,0),r)
    tan=material('HQ spiny leaf insect cuticle',(.35,.245,.13),'stone',.80,size=512)
    curve('Curled leaf-insect abdomen',[(0,0,-.014),(0,-.003,.021),(0,.001,.050),(0,.021,.074),(0,.048,.060)],[.011,.018,.016,.012,.002],tan,body,18)
    head=pivot('Head',(0,0,-.038),body)
    ell('Leaf insect head',(0,0,0),(.023,.018,.023),tan,head,24,16)
    for side in [-1,1]:
        ell('Leaf insect eye',(side*.009,.002,-.005),(.006,.006,.006),m['black'],head,16,10)
        curve('Leaf insect antenna',[(side*.005,.006,-.009),(side*.014,.009,-.037)],[.0008,.0003],tan,head,8)
    legs=[]
    for side in [-1,1]:
        for j in range(3):
            leg=pivot(('LegL' if side<0 else 'LegR')+str(j),(side*.008,-.003,-.021+j*.025),body)
            curve('Leaf insect climbing leg',[(0,0,0),(side*.022,.011,-.004),(side*.038,-.016,-.012),(side*.043,-.033,-.004)],[.0028,.0023,.0014,.0003],tan,leg,10)
            feather('Dried leaf leg lobe',(side*.012,.006,-.002),(side*.031,-.008,-.008),.008,tan,leg,.003)
            legs.append(leg)
    for j in range(12):
        side=-1 if j%2 else 1;z=-.003+j*.005
        curve('Body thorn',[(side*.012,.009,z),(side*.020,.015,z+.004)],[.0016,.0002],tan,body,6)
    def sway(t,rest):body.rotation_euler.x=.06*math.sin(t*math.tau);body.rotation_euler.y=.035*math.sin(t*math.tau+.8)
    def crawl(t,rest):
        sway(t,rest)
        for j,l in enumerate(legs):l.rotation_euler.z=.12*math.sin(t*math.tau+(math.pi if j%2 else 0))
    animate(r,[('idle',6,sway),('crawl',4,crawl)])
    return r

def lady_beetle():
    # The shipped shell has flush spots and six separate articulated legs.
    import ast
    tree=ast.parse((ROOT/'art_source/build_wildlife.py').read_text())
    functions=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['lady_beetle','shell_spot']],type_ignores=[])
    namespace=dict(globals(),p=palette(),black=palette()['black'],mat=material)
    exec(compile(functions,'preserved_lady_beetle_shell','exec'),namespace)
    r=namespace['lady_beetle']();legs=[o for o in r.children_recursive if o.type=='EMPTY' and o.name.startswith(('LegL','LegR'))]
    def crawl(t,rest):
        for j,l in enumerate(legs):l.rotation_euler.z=.17*math.sin(t*math.tau+(math.pi if j%2 else 0))
    def idle(t,rest):
        for j,l in enumerate(legs):l.rotation_euler.z=.015*math.sin(t*math.tau+j*.6)
    animate(r,[('crawl',1.4,crawl),('idle',3,idle)])
    return r

INSECTS=['bee','butterfly','dragonfly','firefly','lady_beetle','blue_banded_bee','hoverfly','mantis','leaf_insect','emperor_gum_moth']
def make(kind):
    if kind=='frog':return frog()
    if kind=='fish':return fish()
    if kind=='mantis':return mantis()
    if kind=='leaf_insect':return leaf_insect()
    if kind=='lady_beetle':return lady_beetle()
    if kind in INSECTS:return flying_insect(kind)
    raise ValueError(kind)
