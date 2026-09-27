"""Detailed articulated tabby and collie with embedded coat PBR textures."""
import sys, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent/'detail'))
from common import *
scene_new('ZendGarden_DetailedCompanions')
cream=mat('Cream short fur',(.65,.58,.44),'fur')
ginger=mat('Mackerel tabby fur',(.34,.17,.055),'tabby')
dark=mat('Collie sable fur',(.045,.030,.023),'fur')
nose=mat('Nose leather',(.048,.026,.024),'stone',.38)
pink=mat('Ear velvet',(.42,.22,.20),'fur')
brown=mat('Collie brown iris',(.14,.070,.018),rough=.24)
green=mat('Amber green iris',(.25,.36,.12),'scales',.3)
black=mat('Glossy pupils',(.004,.006,.005),rough=.12)
collar=mat('Woven sage collar',(.11,.22,.18),'feather')
metal=mat('Collar brass',(.42,.30,.09),rough=.3,metal=.75)
segment=rod
roots=[]
for cat in [True,False]:
    kind='cat' if cat else 'dog'; root=pivot(kind,(0,0,0)); coat=ginger if cat else dark
    body=pivot('Body',(0,.39 if cat else .52,0),root)
    torso=ell('Torso',(0,0,.03),(.32,.36,.65) if cat else (.43,.49,.85),coat,body)
    ell('Chest',(0,.015,-.22),(.28,.32,.24) if cat else (.38,.46,.32),cream,body)
    ell('Haunch',(0,-.025,.23),(.34,.35,.30) if cat else (.43,.46,.39),coat,body)
    fuse_surface([o for o in body.children if o.type=='MESH' and o.data.materials[0]==coat],.009 if cat else .012)
    head=pivot('Head',(0,.13,-.31) if cat else (0,.24,-.40),body)
    ell('Skull',(0,.03,0),(.30,.28,.27) if cat else (.34,.36,.38),coat,head)
    ell('Muzzle',(0,-.035,-.14),(.18,.11,.13) if cat else (.20,.18,.28),cream,head)
    ell('Nose',(0,-.012,-.208 if cat else -.29),(.054,.035,.038) if cat else (.095,.065,.06),nose,head)
    for side in [-1,1]:
        x=side*(.088 if cat else .099)
        ell('Eye',(x,.066,-.099 if cat else -.147),(.042,.039,.022),green if cat else brown,head)
        ell('Pupil',(x,.066,-.111 if cat else -.159),(.012,.029,.010) if cat else (.024,.029,.010),black,head)
        ell('Eye glint',(x-.008,.078,-.117 if cat else -.165),(.006,.006,.004),cream,head)
        ear=pivot('EarL' if side<0 else 'EarR',(side*.11,.135,.015),head)
        if cat:
            mesh('Sculpted triangular pinna',[(-.066,-.018,.018),(.066,-.018,.018),(side*.026,.155,-.012),(0,.024,-.054)],[(0,1,2),(0,3,1),(1,3,2),(2,3,0)],coat,ear,False)
            mesh('Recessed ear velvet',[(-.040,.012,-.032),(.040,.012,-.032),(side*.024,.125,-.024)],[(0,1,2)],pink,ear,False)
            for k in range(3): segment('Whisker',(side*.045,-.015,-.18),(side*.22,-.03+k*.025,-.17-k*.012),.0018,cream,head,.0006)
        else:
            mesh('Folded collie pinna',[(-.055,-.055,.035),(.055,-.055,.035),(.045,.07,.02),(0,.16,-.005),(-.045,.07,.02),(0,.11,-.075),(0,.025,-.045)],[(0,1,6),(1,2,6),(2,5,6),(2,3,5),(3,4,5),(4,6,5),(4,0,6),(0,4,3,2,1)],coat,ear,False)
            mesh('Inner collie ear',[(-.031,-.025,-.022),(.031,-.025,-.022),(0,.089,-.051)],[(0,1,2)],pink,ear,False)
    for side in [-1,1]:
        for front in [True,False]:
            z=-.21 if front else .24
            leg=pivot(('Front' if front else 'Back')+('L' if side<0 else 'R'),(side*(.115 if cat else .16),-.08,z),body)
            length=.28 if cat else .40
            ell('Upper leg',(0,-length*.2,0),(.10,length*.75,.12) if cat else (.14,length*.75,.17),coat,leg)
            segment('Lower leg',(0,-length*.3,0),(0,-length+.035,-.02),.037 if cat else .048,cream,leg,.027 if cat else .039)
            ell('Paw',(0,-length+.025,-.043),(.095,.07,.14) if cat else (.13,.095,.19),cream,leg)
    tail=pivot('Tail',(0,.03,.30 if cat else .40),body)
    if not cat:
        ell('White blaze',(0,.06,-.173),(.065,.22,.021),cream,head)
        ell('Neck ruff',(0,.10,-.27),(.42,.42,.22),cream,body)
    ell('Collar',(0,.035,-.26),(.32 if cat else .39,.055,.26),collar,body)
    # Split muzzle pads, defined lower jaw, toes and fine whisker follicles.
    for side in [-1,1]:
        ell('Muzzle pad',(side*(.043 if cat else .060),-.028,-.157 if cat else -.223),(.09,.078,.095) if cat else (.12,.095,.14),cream,head)
        for k in range(3):
            ell('Whisker follicle',(side*(.041+k*.011),-.018+k*.013,-.201 if cat else -.274),(.004,.004,.004),nose,head,12,8)
        ell('Brow',(side*(.093 if cat else .11),.094,-.080 if cat else -.129),(.068,.023,.027),coat,head)
    ell('Lower jaw',(0,-.071,-.135 if cat else -.20),(.13,.046,.10) if cat else (.16,.065,.20),cream,head)
    for leg in [o for o in body.children if o.name.startswith(('Front','Back'))]:
        length=.28 if cat else .40
        for t in [-1,0,1]:
            ell('Individual toe',(t*(.024 if cat else .031),-length+.024,-.088 if cat else -.112),(.035,.045,.054) if cat else (.044,.06,.070),cream,leg,16,10)
    # A tapered swept tail avoids the old visible cylinder joints.
    vs=[]; fs=[]
    for k in range(17):
        t=k/16; center=Vector((.035*math.sin(t*2.7),t*.33,t*.40));rad=(.034 if cat else .072)*(1-.85*t)
        for j in range(12):
            a=j*math.tau/12;vs.append(center+Vector((math.cos(a)*rad,math.sin(a)*rad,0)))
    for k in range(16):
        for j in range(12):a=k*12+j;b=k*12+(j+1)%12;fs.append((a,a+12,b+12,b))
    fs.extend([tuple(range(11,-1,-1)),tuple(range(192,204))])
    mesh('Continuous tapered tail',vs,fs,coat,tail,False)
    if not cat:
        # Tapered feathering around the collie's ruff and tail silhouette.
        for k in range(18):
            a=k*math.tau/18
            segment('Ruff feathering',(math.cos(a)*.16,.07+math.sin(a)*.16,-.28),(math.cos(a)*.22,.02+math.sin(a)*.20,-.24),.028,cream,body,.003)
    ell('Brass ID tag',(0,-.015,-.397 if not cat else -.391),(.047,.055,.010),metal,body)
    export(root,'companions',kind); roots.append(root)
for i,r in enumerate(roots):r.location=vec((i*1.8,0,0));r.hide_set(False)
save('companions.blend')
