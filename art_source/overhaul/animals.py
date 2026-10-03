"""Twenty-six articulated garden species, sculpted profiles and authored poses."""
import math, numpy as np
from common_hq import *

def joint(name,p,parent):return pivot(name,p,parent)

def eye(parent,side,p,size,iris,cat=False,coat=None):
    x,y,z=p;m=palette()
    anchor=joint('Eye socket',(side*x,y,z),parent)
    anchor.rotation_euler.z=-side*.9
    ell('Recessed almond eye',(0,0,0),(size*2.15,size*1.25,size*.30),m['black'],anchor,24,16)
    ell('Living iris',(0,0,-size*.14),(size*1.25,size*1.20,size*.22),iris,anchor,24,16)
    ell('Pupil',(0,0,-size*.26),(size*.28 if cat else size*.70,size*.94 if cat else size*.70,size*.09),m['black'],anchor,20,12)
    ell('Eye catchlight',(-size*.16,size*.23,-size*.32),(size*.09,size*.09,size*.05),m['ivory'],anchor,10,6)
    if coat:
        for upper in [True,False]:
            points=[(math.cos(a)*size*1.07,math.sin(a)*size*(.64 if upper else .53),-size*.10) for a in np.linspace(0,math.pi,13)]
            if not upper:points=[(x,-y,z) for x,y,z in points]
            curve('Anatomical eyelid',points,[size*.13]*13,coat,anchor,6)

def pinna(name,parent,p,width,height,coat,inner,fold=False,round_ear=False):
    e=joint(name,p,parent)
    if round_ear:
        ell('Rounded ear rim',(0,height*.38,0),(width,height,.035),coat,e,24,16)
        ell('Recessed ear velvet',(0,height*.38,-.012),(width*.70,height*.65,.008),inner,e,20,12)
    else:
        w=width*.5;h=height
        vs=[(-w,0,.012),(w,0,.012),(w*.62,h*.67,.005),(0,h,-.018 if not fold else -.060),(-w*.62,h*.67,.005),
            (0,h*.40,-.030),(0,h*.35,.025)]
        fs=[(0,1,5),(1,2,5),(2,3,5),(3,4,5),(4,0,5),(1,0,6),(2,1,6),(3,2,6),(4,3,6),(0,4,6)]
        o=mesh('Sculpted pinna',vs,fs,coat,e,False)
        mod=o.modifiers.new('Pinna smoothing','SUBSURF');mod.levels=1;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name)
        mesh('Ear recess',[(-w*.55,h*.12,-.017),(w*.55,h*.12,-.017),(0,h*.78,-.030),(0,h*.34,-.033)],[(0,1,3),(1,2,3),(2,0,3)],inner,e,False)
    return e

def quadruped(kind):
    m=palette();r=joint(kind,(0,0,0),None)
    cat=kind=='cat';dog=kind=='dog';fox=kind=='fox';wombat=kind=='wombat';rabbit=kind=='rabbit';echidna=kind=='echidna'
    width,height,length= {'cat':(.30,.34,.63),'dog':(.43,.63,.91),'fox':(.32,.54,.80),'wombat':(.54,.30,.85),'rabbit':(.31,.23,.42),'echidna':(.34,.17,.43)}[kind]
    colors={'cat':(.42,.22,.073),'dog':(.26,.13,.056),'fox':(.47,.18,.053),'wombat':(.245,.21,.17),'rabbit':(.28,.225,.15),'echidna':(.12,.10,.066)}
    coat=material('HQ '+kind+' coat',colors[kind],'tabby' if cat else 'fur')
    cream=material('HQ cream animal fur',(.66,.60,.48),'fur')
    skin=material('HQ ear velvet',(.40,.22,.18),'fur')
    nose=material('HQ nose leather',(.025,.019,.017),'stone',.34)
    iris=material('HQ amber green iris',(.22,.28,.063),None,.22) if cat else material('HQ amber brown iris',(.18,.079,.016),None,.22)
    body=joint('Body',(0,height,0),r)
    profiles=[(-length*.48,.004,width*.18,width*.26),(-length*.39,.005,width*.36,width*.46),
        (-length*.27,.015,width*.46,width*.51),(-length*.12,.008,width*.45,width*.46),
        (length*.08,.022,width*.38,width*.39),(length*.26,.002,width*.49,width*.52),
        (length*.40,-.006,width*.37,width*.42),(length*.48,0,width*.09,width*.16)]
    if wombat:
        profiles=[(z,y,width*.49 if abs(z)<length*.33 else w,h*1.12) for z,y,w,h in profiles]
    if rabbit:
        profiles=[(z,y+(0.035 if z>0 else 0),w*(1.18 if z>0 else .90),h*(1.20 if z>0 else .85)) for z,y,w,h in profiles]
    torso=loft('Continuous shaped torso',profiles,coat,body,40)
    if cat or fox:torso.scale.z=.83
    if wombat:
        torso.scale.z=.78
    if rabbit:
        chest=ell('Cream chest',(0,-width*.10,-length*.31),(width*.76,width*.80,length*.24),cream,body,32,20)
    # The neck flows into the shoulders; articulated head meets it at a real joint.
    head_y=height+(.12 if cat else .16 if dog else .13 if fox else .035 if wombat else .07 if rabbit else -.015)
    head_z=-length*.43
    neck=ell('Shoulder and neck',(0,head_y-height-.035,head_z+.07),(width*.65,width*.77,length*.29),coat,body,32,20)
    torso=fuse_surface([torso,neck],.009 if kind in ['cat','rabbit','echidna'] else .012)
    from realism import coat_uv
    coat_uv(torso)
    if dog or cat or fox:
        torso.data.materials.append(cream)
        for face in torso.data.polygons:
            c=face.center
            if c.y>length*.23 and c.z<width*.17 and (dog or fox or abs(c.x)<width*.20):face.material_index=len(torso.data.materials)-1
    head=joint('Head',(0,head_y,head_z),r)
    hw=width*(.28 if wombat else .28 if rabbit else .36 if cat else .27 if fox else .26)
    hl=.18 if cat else .28 if dog else .25 if fox else .24 if wombat else .16 if rabbit else .13
    hheight=hw*.80
    headprofiles=[(-hl*.72,-.035,hw*.15,hheight*.16),(-hl*.59,-.025,hw*.38,hheight*.28),
        (-hl*.40,-.005,hw*.57,hheight*.43),(-hl*.20,.013,hw*.87,hheight*.70),
        (hl*.02,.025,hw,hheight*.91),(hl*.23,.018,hw*.81,hheight*.84),(hl*.41,0,hw*.26,hheight*.42)]
    sculpt=loft('Sculpted skull and muzzle',headprofiles,coat,head,40)
    # A feline jaw has a flatter underside; an ellipsoidal skull otherwise
    # reads as a toy even after applying a detailed coat map.
    if cat or fox:
        for v in sculpt.data.vertices:
            if v.co.z<-.035:v.co.z=-.035+(v.co.z+.035)*.42
        sculpt.data.update()
    if dog:
        sculpt.data.materials.append(cream)
        for face in sculpt.data.polygons:
            if abs(face.center.x)<hw*.17 and face.center.y>-hl*.16:face.material_index=len(sculpt.data.materials)-1
    if fox:
        sculpt.data.materials.append(cream)
        for face in sculpt.data.polygons:
            if face.center.z<-.012:face.material_index=len(sculpt.data.materials)-1
    boot=material('HQ fox soot boots',(.022,.019,.017),'fur') if fox else coat
    if echidna:
        curve('Tubular echidna snout',[(0,-.018,-.035),(0,-.025,-.09),(0,-.045,-.165),(0,-.053,-.205)],[.026,.024,.015,.009],coat,head,16)
        ell('Nostril tip',(0,-.053,-.209),(.018,.014,.012),nose,head,16,10)
    else:
        for side in [-1,1]:
            ell('Muzzle pad',(side*hw*.22,-.038,-hl*.56),(hw*.47,hheight*.36,hl*.28),cream if not wombat else coat,head,24,16)
        nsize=(hw*(.40 if cat else .63),hheight*(.28 if cat else .44),.040 if wombat else .020 if cat else .029)
        ell('Nose pad',(0,-.025,-hl*.70),nsize,nose,head,24,16)
        curve('Mouth line',[(-hw*.30,-.070,-hl*.48),(0,-.078,-hl*.65),(hw*.30,-.070,-hl*.48)],[.0018]*3,nose,head,6)
    for side in [-1,1]:
        eye(head,side,(hw*.89,.018,-hl*.21),.013 if cat or rabbit else .010 if echidna or wombat else .012 if fox else .014,iris,cat,coat)
        if not echidna:
            ear_h=.115 if cat else .16 if dog else .155 if fox else .075 if wombat else .225
            pinna('EarL' if side<0 else 'EarR',head,(side*hw*.68,hheight*.62,hl*.12),hw*(.45 if wombat else .77),ear_h,coat,skin,dog,wombat or rabbit)
        if kind in ['cat','dog','fox','rabbit']:
            for j in range(4):
                curve('Fine facial whisker',[(side*hw*.25,-.035+j*.007,-hl*.61),(side*hw*.83,-.043+j*.016,-hl*.65),(side*hw*(1.55+j*.10),-.052+j*.020,-hl*.57)],[.0010,.0006,.00015],cream,head,5)
    legs=[];lowers=[];paws=[]
    hip=height-.055
    for front in [True,False]:
        for side in [-1,1]:
            z=length*(-.30 if front else .30);x=side*width*(.33 if wombat else .34)
            top=joint(('Front' if front else 'Back')+('L' if side<0 else 'R'),(x,-.055,z),body)
            upperlen=hip*.50;lowerlen=hip*.50
            radius=width*(.19 if wombat else .15 if rabbit else .12 if echidna else .135 if dog else .13)
            if not front and kind in ['cat','dog','fox','rabbit']:radius*=1.30
            curve('Contoured upper limb',[(0,0,0),(0,-upperlen*.32,-.030 if not front else -.010),(0,-upperlen*.68,-.012 if not front else -.007),(0,-upperlen,.025 if not front else .005)],[radius,radius*.92,radius*.68,radius*.52],coat,top,16)
            low=joint('Lower'+('Front' if front else 'Back')+('L' if side<0 else 'R'),(0,-upperlen,.025 if not front else .005),top)
            curve('Tapered shin',[(0,.016,0),(0,-lowerlen*.45,.023 if not front else -.007),(0,-lowerlen+.035,-.018)],[radius*.55,radius*.37,radius*.30],cream if dog or cat else boot,low,14)
            foot=joint('Paw'+('Front' if front else 'Back')+('L' if side<0 else 'R'),(0,-lowerlen,0),low)
            paw=(width*.27,.062 if wombat else .043,length*.18 if rabbit else .085)
            ell('Grounded shaped paw',(0,.025,-.040),paw,cream if dog or cat else boot,foot,24,12)
            for j in range(3 if not echidna else 4):
                dx=(j-1)*width*.051
                ell('Toe pad',(dx,.028,-.064),(width*.071,.039,.055),cream if cat or dog else boot,foot,16,10)
                if kind in ['wombat','echidna','rabbit']:
                    curve('Flattened claw',[(dx,.022,-.075),(dx,.005,-.095),(dx,.002,-.111)],[.006,.004,.0008],nose,foot,6)
            legs.append(top);lowers.append(low);paws.append(foot)
    tail=joint('Tail',(0,-.035,length*.43),body)
    if cat or dog or fox:
        ts=.37 if cat else .51 if dog else .54
        points=[(math.sin(t*2)*.018,t*.09,ts*t) for t in np.linspace(0,1,17)]
        radii=[(.027*(1-.16*t) if cat else .036+.040*math.sin(math.pi*t)**.8 if fox else .037+.028*math.sin(math.pi*t))*(1 if t<.82 else max(.02,math.sqrt((1-t)/.18))) for t in np.linspace(0,1,17)]
        curve('Flowing tapered tail',points[:13] if fox or dog else points,radii[:13] if fox or dog else radii,coat,tail,16)
        if fox or dog:
            curve('Cream tail tip',points[12:],radii[12:],cream,tail,16)
    elif rabbit:ell('Cotton tail',(0,.025,.025),(.13,.13,.13),cream,tail,24,16)
    if dog:
        ell('Collie facial blaze',(0,.024,-hl*.29),(.045,.17,.024),cream,head,24,16)
        # The chest is now covered by laid fur cards rather than solid spikes.
    if cat or dog:
        collar=material('HQ sage woven collar',(.12,.24,.19),'fabric')
        # Thin fitted collar follows the neck rather than covering the whole chest.
        for j in range(40):
            a=j*math.tau/40;b=(j+1)*math.tau/40
            rod('Collar weave',(math.cos(a)*width*.305,.03+math.sin(a)*width*.30,-length*.33),(math.cos(b)*width*.305,.03+math.sin(b)*width*.30,-length*.33),.011,collar,body,vertices=8)
        ell('Brass name tag',(0,-width*.26,-length*.35),(.035,.044,.008),m['metal'],body,20,12)
    if echidna:
        spine=material('HQ echidna cream spines',(.61,.52,.34),'fur')
        rng=np.random.default_rng(42)
        for j in range(420):
            a=rng.uniform(.10,math.pi-.10);z=rng.uniform(-length*.39,length*.40)
            envelope=math.sqrt(max(.10,1-(z/(length*.52))**2))
            p=Vector((math.cos(a)*width*.48*envelope,math.sin(a)*width*.52*envelope,z))
            normal=Vector((math.cos(a),math.sin(a),z/length*.35)).normalized();long=rng.uniform(.035,.075)
            tip=p+normal*long
            curve('Cream-tipped spine',[p,p+normal*long*.60,tip],[.005,.0033,.0002],spine,body,6)
    def idle(t,rest):
        body.scale.z=1+.011*math.sin(t*math.tau)
        head.rotation_euler.z=.045*math.sin(t*math.tau)*math.sin(t*math.pi)**2
        tail.rotation_euler.z=(.22 if dog else .07)*math.sin(t*math.tau)
    def walk(t,rest):
        phase=t*math.tau
        drop=.022 if wombat else .030
        body.location.z=rest[body][0].z-drop+.003*math.cos(phase*2)
        head.location.z=rest[head][0].z-drop+.003*math.cos(phase*2)
        body.rotation_euler.y=(.028 if wombat else .010)*math.sin(phase)
        stride=hip*.31
        for j,(top,low) in enumerate(zip(legs,lowers)):
            offset=[0,.5,.75,.25][j] if wombat else (.5 if j in [1,2] else 0)
            cycle=(t+offset)%1
            # Half a cycle has a planted foot travelling backwards at a constant
            # rate. The recovery foot lifts along a smooth arc, with knee flexion.
            if cycle<.5:
                z=-stride+4*stride*cycle;lift=0
            else:
                u=(cycle-.5)*2
                z=stride*(1-2*(u*u*(3-2*u)));lift=.035*math.sin(math.pi*u)**2
            down=hip-.027-lift
            distance=min(hip-.0001,math.hypot(z,down))
            knee=math.acos(max(-1,min(1,(distance*distance-2*(hip*.5)**2)/(2*(hip*.5)**2))))
            top.rotation_euler.x=math.atan2(-z,down)+knee*.5
            low.rotation_euler.x=-knee
            paws[j].rotation_euler.x=-(top.rotation_euler.x+low.rotation_euler.x)
        head.rotation_euler.x=.022*math.cos(phase*2)
        tail.rotation_euler.z=(.13 if dog else .06)*math.sin(phase)
    def graze(t,rest):
        ramp=math.sin(math.pi*t)**2
        head.rotation_euler.x=-.50*ramp
        head.location.z=rest[head][0].z-.025*ramp
        body.rotation_euler.x=.025*ramp
    def settle(t,rest):
        body.location.z=rest[body][0].z-height*.35
        head.location.z=rest[head][0].z-height*.35
        for j,(top,low) in enumerate(zip(legs,lowers)):
            top.rotation_euler.x=.75 if j>=2 else -.16
            low.rotation_euler.x=-1.05 if j>=2 else .55
        head.rotation_euler.x=.12
        body.scale.z=1+.009*math.sin(t*math.tau)
    def alert(t,rest):
        head.rotation_euler.z=.16*math.sin(t*math.tau)
        if echidna:head.rotation_euler.x=.55;body.scale.z=.88
    def stretch(t,rest):
        a=math.sin(math.pi*t)**2;body.rotation_euler.x=-.12*a
        body.scale.y=1+.13*a;body.location.z=rest[body][0].z-.06*a
        for j,top in enumerate(legs):top.rotation_euler.x=(-.52 if j<2 else .27)*a
        head.rotation_euler.x=-.20*a
    def pet(t,rest):
        head.rotation_euler.z=.10*math.sin(t*math.tau);head.rotation_euler.x=-.10
        tail.rotation_euler.z=(.42 if dog else .10)*math.sin(t*math.tau*2)
    clips=[('idle',4,idle),('walk',1.8 if wombat else 1.25 if echidna else 1.0,walk),('graze',3,graze),('settle',4,settle),('alert',2,alert),('pet',2,pet)]
    if cat:clips.append(('stretch',5,stretch))
    if dog:clips.append(('sniff',3,graze))
    if rabbit:
        def hop(t,rest):
            s=math.sin(math.pi*t)**2
            body.location.z=rest[body][0].z+.075*s;head.location.z=rest[head][0].z+.075*s
            for j,(top,low) in enumerate(zip(legs,lowers)):
                top.rotation_euler.x=(.38 if j<2 else -.52)*math.sin(t*math.tau)
                low.rotation_euler.x=-.40*s
        clips.append(('hop',.65,hop))
    animate(r,clips)
    return r

def kangaroo(joey=False):
    kind='kangaroo_joey' if joey else 'kangaroo';m=palette();r=joint(kind,(0,0,0),None)
    coat=material('HQ kangaroo tawny coat',(.37,.24,.13),'fur');cream=material('HQ cream animal fur',(.66,.60,.48),'fur')
    body=joint('Body',(0,.82,0),r)
    volumes=[ell('Haunch',(0,-.10,.10),(.50,.65,.50),coat,body,40,24),ell('Upright trunk',(0,.22,0),(.38,.82,.39),coat,body,40,24),ell('Neck',(0,.56,-.10),(.20,.41,.22),coat,body,32,20)]
    fuse_surface(volumes,.011)
    ell('Cream breast',(0,.30,-.18),(.24,.60,.06),cream,body,32,20)
    head=joint('Head',(0,1.47,-.19),r)
    loft('Kangaroo skull and tapered muzzle',[(-.25,-.026,.024,.035),(-.18,-.012,.055,.051),(-.08,.02,.082,.094),(.02,.015,.10,.13),(.10,.008,.055,.07)],coat,head,36)
    ell('Kangaroo nose',(0,-.015,-.247),(.058,.040,.025),m['black'],head,24,16)
    iris=material('HQ amber brown iris',(.18,.079,.016),None,.22)
    for side in [-1,1]:
        eye(head,side,(.071,.035,-.063),.018,iris)
        pinna('EarL' if side<0 else 'EarR',head,(side*.07,.08,.025),.065,.26,coat,cream,round_ear=True)
    thighs=[];shins=[];arms=[]
    for side in [-1,1]:
        top=joint('BackL' if side<0 else 'BackR',(side*.19,-.19,.09),body)
        ell('Powerful hind thigh',(0,-.16,.015),(.28,.42,.37),coat,top,36,20)
        low=joint('LowerBackL' if side<0 else 'LowerBackR',(0,-.32,.09),top)
        curve('Kangaroo shin',[(0,0,0),(0,-.17,-.015),(0,-.23,-.10)],[.055,.034,.026],coat,low,16)
        ell('Long weight-bearing foot',(0,-.26,-.10),(.13,.10,.49),coat,low,32,16)
        topa=joint('FrontL' if side<0 else 'FrontR',(side*.13,.30,-.12),body)
        curve('Tucked forearm',[(0,0,0),(side*.017,-.15,-.06),(side*.005,-.27,-.095)],[.036,.028,.015],coat,topa,14)
        ell('Forepaw',(side*.005,-.29,-.095),(.05,.07,.09),coat,topa,20,12)
        for j in range(3):curve('Toe claw',[(j*.014-.014,-.265,-.31),(j*.014-.014,-.282,-.345)],[.004,.0004],m['black'],low,6)
        thighs.append(top);shins.append(low);arms.append(topa)
    tail=joint('Tail',(0,-.32,.21),body)
    curve('Heavy balancing tail',[(0,0,0),(0,-.19,.30),(0,-.36,.63),(0,-.43,.94),(0,-.42,1.13)],[.115,.10,.060,.032,.003],coat,tail,20)
    if joey:
        ell('Soft pouch',(0,.055,-.22),(.32,.39,.12),cream,body,32,20)
        ell('Pouch opening',(0,.22,-.255),(.22,.033,.065),coat,body,32,16)
        baby=joint('JoeyHead',(0,.27,-.27),body)
        loft('Joey head',[(-.09,-.012,.020,.022),(-.04,.005,.043,.055),(.012,.01,.057,.065),(.055,.004,.025,.037)],coat,baby,28)
        for side in [-1,1]:
            eye(baby,side,(.039,.025,-.027),.008,iris)
            pinna('JoeyEar',baby,(side*.035,.05,.019),.030,.115,coat,cream,round_ear=True)
    def idle(t,rest):
        body.scale.z=1+.012*math.sin(t*math.tau);head.rotation_euler.z=.045*math.sin(t*math.tau)
        if joey:baby.rotation_euler.z=.04*math.sin(t*math.tau)
    def hop(t,rest):
        air=math.sin(math.pi*t)**2;compression=max(0,math.cos(t*math.tau))*.035
        body.location.z=rest[body][0].z+.14*air-compression;head.location.z=rest[head][0].z+.14*air-compression
        body.rotation_euler.x=-.10*math.sin(t*math.tau);tail.rotation_euler.x=.12*math.sin(t*math.tau+.7)
        for top,low in zip(thighs,shins):top.rotation_euler.x=-.36*math.sin(t*math.tau);low.rotation_euler.x=.47*air
        for arm in arms:arm.rotation_euler.x=.12*math.sin(t*math.tau+.5)
    def graze(t,rest):
        a=math.sin(math.pi*t)**2;body.rotation_euler.x=-.15*a;head.rotation_euler.x=-.35*a
    animate(r,[('idle',4,idle),('hop',.9,hop),('graze',3,graze)])
    return r

def bird(kind):
    m=palette();r=joint(kind,(0,0,0),None)
    specs={
        'songbird':(.23,.075,(.30,.21,.12),(.57,.43,.26),.10),
        'native_bird':(.26,.076,(.22,.27,.18),(.50,.43,.22),.12),
        'fairy_wren':(.16,.052,(.25,.23,.20),(.56,.51,.42),.19),
        'kookaburra':(.40,.12,(.27,.20,.13),(.69,.65,.54),.22),
        'lorikeet':(.34,.085,(.085,.34,.062),(.69,.15,.032),.22),
        'magpie':(.38,.103,(.012,.016,.018),(.70,.72,.68),.21)}
    length,width,color,breastcolor,tail_length=specs[kind]
    plumage=material('HQ '+kind+' plumage',color,'feather')
    flight_feathers=material('HQ '+kind+' flight feathers',color,'feather')
    breast=material('HQ '+kind+' breast',breastcolor,'feather')
    body=joint('Body',(0,width*.65,0),r)
    loft('Streamlined feathered body',[(-length*.42,0,width*.10,width*.14),(-length*.27,.012,width*.80,width*.82),
        (-length*.03,0,width,width*.96),(length*.22,-.014,width*.70,width*.65),(length*.37,-.018,width*.16,width*.20)],plumage,body,36)
    breast_mesh=ell('Soft breast',(0,-width*.30,-length*.08),(width*1.65,width*1.20,length*.57),breast,body,32,20)
    ell('Feathered neck transition',(0,width*.76,-length*.26),(width*.93,width*.91,length*.29),breast,body,32,20)
    head=joint('Head',(0,width*(1.56 if kind=='kookaburra' else 1.38),-length*.28),r)
    headcoat=material('HQ lorikeet cobalt head',(.034,.11,.37),'feather') if kind=='lorikeet' else material('HQ fairy-wren cobalt plumage',(.03,.21,.56),'feather') if kind=='fairy_wren' else breast if kind=='kookaburra' else plumage
    skull=loft('Anatomical bird skull',[(-width*.76,-width*.04,width*.19,width*.24),
        (-width*.57,width*.06,width*.44,width*.42),(-width*.28,width*.12,width*.60,width*.60),
        (width*.05,width*.12,width*.65,width*.66),(width*.36,width*.06,width*.56,width*.57),
        (width*.64,-width*.03,width*.28,width*.34),(width*.73,-width*.08,width*.06,width*.12)],headcoat,head,36)
    if kind=='kookaburra':
        mask=material('HQ kookaburra eye stripe',(.12,.075,.041),'feather')
        skull.data.materials.append(mask)
        for face in skull.data.polygons:
            c=skull.matrix_basis@face.center
            if abs(c.x)>width*.42 and abs(c.z-width*.11)<width*.06 and -width*.55<c.y<width*.48:face.material_index=len(skull.data.materials)-1
    beakmat=material('HQ parrot orange beak',(.62,.15,.026),'stone',.37) if kind=='lorikeet' else material('HQ pale bird beak',(.34,.36,.30),'stone',.39) if kind=='magpie' else material('HQ dark keratin beak',(.055,.049,.042),'stone',.40,size=512)
    beaklength=width*1.05 if kind=='kookaburra' else width*.68 if kind=='magpie' else width*.48
    if kind=='lorikeet':
        curve('Hooked upper beak',[(0,-.005,-width*.57),(0,-.012,-width*.89),(0,-.037,-width*.90)],[width*.28,width*.18,.001],beakmat,head,18)
        ell('Lower parrot beak',(0,-.035,-width*.70),(width*.36,width*.29,width*.30),beakmat,head,24,16)
    else:
        loft('Tapered bird bill',[(-width*.65-beaklength,-.019,.002,.002),(-width*.65-beaklength*.70,-.012,width*.10,width*.06),(-width*.65-beaklength*.35,-.009,width*(.22 if kind=='kookaburra' else .15),width*(.18 if kind=='kookaburra' else .10)),(-width*.58,-.006,width*.25,width*(.22 if kind=='kookaburra' else .13))],beakmat,head,24)
        if kind=='kookaburra':
            lowerbill=material('HQ kookaburra pale lower bill',(.33,.30,.24),'stone',.46,size=512)
            loft('Separate lower mandible',[(-width*.65-beaklength,-.021,.002,.001),(-width*.65-beaklength*.42,-.020,width*.20,width*.05),(-width*.59,-.016,width*.24,width*.085)],lowerbill,head,24)
        curve('Bill seam',[(-width*.15,-.012,-width*.61),(0,-.018,-width*.65-beaklength),(.0001,-.018,-width*.65-beaklength)],[.001,.0005,.0002],m['black'],head,6)
    iris=material('HQ bird chestnut iris',(.22,.065,.025),None,.24)
    for side in [-1,1]:
        if kind=='fairy_wren':
            ell('Species facial mask',(side*width*.48,.012,-width*.34),(width*.62,width*.28,width*.51),m['darkwood'] if kind=='kookaburra' else m['black'],head,24,16)
        eye(head,side,(width*.63,width*.11,-width*.33),width*.070,iris,coat=headcoat)
    wings=[];wrists=[]
    for side in [-1,1]:
        w=joint('WingL' if side<0 else 'WingR',(side*width*.59,width*.56,-length*.08),r);w['side']=side
        wingmat=breast if kind=='magpie' else plumage
        ell('Shoulder coverts',(side*width*.46,0,length*.025),(width*1.10,width*.34,length*.49),wingmat,w,28,16)
        wrist=joint('WristL' if side<0 else 'WristR',(side*length*.31,0,length*.04),w)
        for j in range(9):
            feather('Layered primary',(side*length*.005,0,j*length*.010),(side*(length*.36+j*length*.012),-.01,length*(.02+j*.039)),length*.033,flight_feathers,wrist,bend=width*.05)
        for j in range(7):
            feather('Overlapping covert',(side*(j*.012),.006,-length*.075),(side*(length*.30+j*.007),.010,length*.08),length*.036,wingmat,w,bend=.004)
        if kind=='kookaburra':
            blue=material('HQ kookaburra blue shoulder',(.12,.25,.32),'feather')
            for j in range(5):feather('Blue shoulder fleck',(side*(.018+j*.019),.012,-.023),(side*(.035+j*.019),.014,.015),.007,blue,w)
        w.rotation_euler.z=-side*1.13
        wrist.rotation_euler.z=-side*.50
        wings.append(w);wrists.append(wrist)
    tail=joint('Tail',(0,width*.45,length*.27),r)
    for j in range(7):
        x=(j-3)*width*.12
        feather('Separate tail feather',(x,0,0),(x*1.6,.10 if kind=='fairy_wren' else -.009,tail_length),width*.13,headcoat if kind=='fairy_wren' else flight_feathers,tail,.008)
    legs=[]
    for side in [-1,1]:
        leg=joint('LegL' if side<0 else 'LegR',(side*width*.37,width*.07,length*.03),r)
        curve('Bird tarsus',[(0,0,0),(0,-width*.51,.016),(0,-width*.82,.008)],[width*.045,width*.035,width*.032],m['darkwood'],leg,10)
        for j in ([-1,1] if kind=='lorikeet' else [-1,0,1]):curve('Gripping front toe',[(0,-width*.82,.008),(j*width*.15,-width*.84,-width*.17),(j*width*.17,-width*.88,-width*.25)],[width*.021,width*.014,.0003],m['darkwood'],leg,8)
        curve('Rear gripping toe',[(0,-width*.82,.008),(0,-width*.84,width*.16),(0,-width*.88,width*.19)],[width*.018,width*.013,.0003],m['darkwood'],leg,8)
        if kind=='lorikeet':curve('Second rear parrot toe',[(0,-width*.82,.008),(-width*.12,-width*.84,width*.14),(-width*.16,-width*.88,width*.20)],[width*.018,width*.013,.0003],m['darkwood'],leg,8)
        legs.append(leg)
    if kind=='magpie':
        ell('White nape',(0,width*.45,.024),(width*1.30,width*.54,width*.55),breast,head,28,16)
        ell('White saddle',(0,width*.82,length*.08),(width*1.28,.02,length*.26),breast,body,28,16)
    if kind=='lorikeet':
        yellow=material('HQ lorikeet golden collar',(.57,.40,.033),'feather')
        ell('Golden neck collar',(0,width*.96,-length*.20),(width*1.6,width*.30,.025),yellow,r,28,16)
        breast_mesh.data.materials.append(headcoat)
        for face in breast_mesh.data.polygons:
            c=breast_mesh.matrix_basis@face.center
            if -c.y>length*.012:face.material_index=len(breast_mesh.data.materials)-1
    if kind=='fairy_wren':
        ell('Black fairy-wren throat',(0,-width*.45,-width*.25),(width*1.20,width*.74,.025),m['black'],head,28,16)
    def flight(t,rest):
        phase=t*math.tau
        for side,w,wrist in zip([-1,1],wings,wrists):
            w.rotation_euler.z=side*.08
            # Fast downstroke and a softer recovery; wrist lags the shoulder.
            w.rotation_euler.y=side*(.50*math.sin(phase)+.09*math.sin(phase*2))
            wrist.rotation_euler.z=0
            wrist.rotation_euler.y=side*.20*math.sin(phase-.65)
        for leg in legs:leg.rotation_euler.x=-.85
        tail.rotation_euler.x=.08*math.sin(phase-.4)
        body.location.z=rest[body][0].z+.007*math.cos(phase)
    def perch(t,rest):
        body.scale.z=1+.016*math.sin(t*math.tau)
        head.rotation_euler.z=.22*math.sin(t*math.tau)*math.sin(t*math.pi)**2
        tail.rotation_euler.x=.10*math.sin(t*math.tau)
    def drink(t,rest):
        a=math.sin(t*math.pi)**2;head.rotation_euler.x=-.64*a;body.rotation_euler.x=-.12*a
    def bathe(t,rest):
        for side,w in zip([-1,1],wings):w.rotation_euler.y=side*.25*math.sin(t*math.tau*3)
        body.rotation_euler.y=.06*math.sin(t*math.tau*3);head.rotation_euler.x=.16*math.sin(t*math.tau*3)
    def forage(t,rest):
        for j,leg in enumerate(legs):leg.rotation_euler.x=.22*math.sin(t*math.tau+j*math.pi)
        head.rotation_euler.x=-.25*max(0,math.sin(t*math.tau))
    animate(r,[('flight',.42 if kind=='fairy_wren' else .65,flight),('perch',4,perch),('drink',2,drink),('bathe',1.4,bathe),('forage',1.2,forage)])
    return r

MAMMALS=['cat','dog','rabbit','kangaroo','kangaroo_joey','echidna','wombat','fox']
BIRDS=['songbird','native_bird','fairy_wren','kookaburra','lorikeet','magpie']

def regroom(kind):
    """Refine coats without rebuilding tested weights and bone actions."""
    s=scene('animals');folder='companions' if kind in ['cat','dog'] else 'wildlife'
    r=next(o for o in s.objects if o.get('export_path')==f'assets/{folder}/{kind}.glb')
    position=r.location.copy();r.location=(0,0,0);r.hide_set(False)
    try:
        for o in list(r.children_recursive):
            if o.type=='MESH' and o.data.materials[0].name.startswith('Fur cards '):bpy.data.objects.remove(o,do_unlink=True)
        from realism import groom
        groom(r,kind)
        return export(r,folder,kind)
    finally:
        r.location=position;r.hide_set(False);save('animals')

def reexport(kinds):
    """Export tested gallery rigs after material/export changes; save once."""
    s=scene('animals');records=[]
    try:
        for kind in kinds:
            folder='companions' if kind in ['cat','dog'] else 'wildlife'
            r=next(o for o in s.objects if o.get('export_path')==f'assets/{folder}/{kind}.glb')
            position=r.location.copy();r.location=(0,0,0);r.hide_set(False)
            try:records.append(export(r,folder,kind))
            finally:r.location=position;r.hide_set(False)
    finally:save('animals')
    return records

def build(kind):
    scene('animals')
    folder='companions' if kind in ['cat','dog'] else 'wildlife'
    replace_authored('animals',folder,kind)
    if kind in ['kangaroo','kangaroo_joey']:r=kangaroo(kind=='kangaroo_joey')
    elif kind in MAMMALS:r=quadruped(kind)
    elif kind in BIRDS:r=bird(kind)
    else:
        from small_animals import make
        r=make(kind)
    if kind in MAMMALS+BIRDS:
        from skin_rig import connect
        connect(r,kind)
    from realism import groom
    groom(r,kind)
    record=export(r,folder,kind)
    i=len([o for o in bpy.context.scene.objects if o.parent is None and o.get('export_path')])-1
    r.location=vec(((i%6)*2.6,0,(i//6)*2.6));r.hide_set(False)
    save('animals')
    return record
