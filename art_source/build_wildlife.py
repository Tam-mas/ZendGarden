"""All garden wildlife; local -Z forward, except the swimming fish (+X)."""
import sys, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent/'detail'))
from common import *
scene_new('ZendGarden_DetailedWildlife'); p=palette()
fur=mat('Agouti rabbit fur',(.34,.29,.22),'fur');cream=mat('Wildlife cream',(.64,.58,.45),'fur');pink=mat('Rabbit ear skin',(.43,.23,.20),'fur');black=p['black']

def eyes(parent,x,y,z,r=.018):
    for side in [-1,1]:
        ell('Eye surround',(side*x,y,z),(r*2.4,r*2.5,r*1.8),cream,parent,16,10)
        ell('Glass eye',(side*x,y,z-r*.5),(r*1.9,r*2,r*1.4),black,parent,20,12)
        ell('Catchlight',(side*x-r*.2,y+r*.32,z-r*1.1),(r*.28,r*.28,r*.16),p['ivory'],parent,12,8)

def mammal(kind,joey=False):
    roo=kind=='kangaroo';r=pivot('kangaroo_joey' if joey else kind);coat=mat('Kangaroo tawny fur',(.34,.23,.135),'fur') if roo else fur
    ell('Tapered trunk',(0,.87 if roo else .26,0),(.45,1.02,.51) if roo else (.32,.34,.51),coat,r)
    ell('Breast',(0,1.02 if roo else .28,-.15),(.30,.58,.30) if roo else (.25,.29,.28),cream,r)
    h=pivot('Head',(0,1.46,-.28) if roo else (0,.42,-.245),r)
    ell('Skull',(0,0,0),(.26,.31,.32) if roo else (.24,.235,.25),coat,h)
    ell('Tapered muzzle',(0,-.056,-.16 if roo else -.115),(.17,.14,.27) if roo else (.14,.10,.13),cream,h)
    ell('Nose',(0,-.045,-.292 if roo else -.175),(.058,.038,.027),black if roo else pink,h)
    eyes(h,.103 if roo else .094,.025,-.087 if roo else -.066,.015 if roo else .014)
    for side in [-1,1]:
        e=pivot('EarL' if side<0 else 'EarR',(side*.088,.08,.025),h);e.rotation_euler.y=side*.16
        ell('Long ear',(0,.16,0),(.084,.39,.067) if roo else (.073,.34,.057),coat,e)
        ell('Ear recess',(0,.165,-.027),(.048,.28,.017),pink,e)
        ell('Powerful hind thigh',(side*.17,.36 if roo else .17,.15),(.26,.57,.35) if roo else (.19,.25,.26),coat,r)
        ell('Hind foot',(side*.17,.075,-.09),(.14,.14,.51) if roo else (.105,.10,.235),coat,r)
        rod('Forearm',(side*.16,1.12 if roo else .28,-.12),(side*.14,.76 if roo else .07,-.27),.045 if roo else .029,coat,r,.026 if roo else .022)
        ell('Front paw',(side*.14,.74 if roo else .05,-.285),(.075,.11,.11) if roo else (.063,.07,.105),coat,r)
        for k in [-1,0,1]:rod('Toe claw',(side*.17+k*.025,.069,-.30 if roo else -.18),(side*.17+k*.025,.045,-.35 if roo else -.21),.005,black,r,.001)
        for k in range(4):rod('Whisker',(side*.04,-.028,-.16),(side*(.19+k*.007),-.04+k*.018,-.14-k*.013),.0008,cream,h,.0002,8)
    if roo:
        for a,b,rr in [((0,.49,.17),(0,.16,.83),.12),((0,.16,.83),(0,.055,1.32),.054)]:rod('Tapered balancing tail',a,b,rr,coat,r,rr*.32)
        if joey:
            ell('Pouch',(0,.87,-.26),(.31,.38,.16),cream,r)
            ell('Pouch opening',(0,1.015,-.29),(.20,.045,.09),coat,r)
            ell('Joey head',(0,1.09,-.32),(.16,.19,.18),coat,r)
            for side in [-1,1]:ell('Joey ear',(side*.052,1.22,-.30),(.04,.17,.042),coat,r)
            eyes(r,.059,1.10,-.379,.008)
    else:ell('Cotton tail',(0,.28,.265),(.14,.14,.14),cream,r)
    return r

def bird(kind):
    r=pivot(kind);native=kind=='native_bird'
    feather=mat('Blue grey flight feather' if native else 'Sparrow flight feather',(.17,.24,.29) if native else (.29,.19,.10),'feather')
    breast=mat('Bird breast',(.48,.37,.22),'feather')
    ell('Streamlined body',(0,0,0),(.12,.13,.23),feather,r)
    ell('Breast',(0,-.025,-.035),(.10,.10,.16),breast,r)
    ell('Head',(0,.055,-.10),(.093,.09,.095),feather,r)
    eyes(r,.037,.067,-.127,.0065)
    rod('Upper beak',(0,.047,-.139),(0,.04,-.196),.014,p['darkwood'],r,.001,12)
    rod('Lower beak',(0,.040,-.14),(0,.039,-.192),.009,p['darkwood'],r,.001,12)
    for side in [-1,1]:
        w=pivot('WingL' if side<0 else 'WingR',(side*.035,.018,0),r);w['side']=side
        for k in range(9):
            a=(side*(.015+k*.017),0,-.028+k*.009);b=(side*(.105+k*.02),-.006,.05+k*.011)
            leaf('Overlapping primary feather',a,b,.015,feather,w)
            rod('Feather shaft',a,b,.0011,breast,w,vertices=6)
        for k in range(5):leaf('Wing covert',(side*(.014+k*.019),.004,-.042),(side*(.068+k*.022),.006,.045),.014,breast,w)
        rod('Tarsus',(side*.032,-.034,.015),(side*.033,-.083,.006),.004,p['darkwood'],r)
        for t in [-1,0,1]:rod('Bird toe',(side*.033,-.081,.006),(side*.033+t*.014,-.083,-.031),.002,p['darkwood'],r,.0007,8)
    for j in range(5):leaf('Tail feather',((j-2)*.010,-.009,.080),((j-2)*.017,-.008,.244),.014,feather,r)
    return r

def frog():
    r=pivot('frog');skin=mat('Mottled olive frog skin',(.18,.27,.064),'stone',.48)
    ell('Frog trunk',(0,0,.016),(.16,.11,.21),skin,r);ell('Broad frog snout',(0,.018,-.069),(.16,.073,.12),skin,r)
    ell('Pale throat',(0,-.028,-.065),(.115,.035,.085),cream,r)
    for side in [-1,1]:
        ell('Eye bulge',(side*.058,.055,-.065),(.052,.046,.052),skin,r)
        ell('Golden iris',(side*.060,.064,-.085),(.030,.030,.018),p['metal'],r)
        ell('Horizontal pupil',(side*.060,.065,-.094),(.025,.010,.008),black,r)
        ell('Folded thigh',(side*.085,-.021,.069),(.086,.071,.15),skin,r)
        rod('Shin',(side*.11,-.032,.105),(side*.07,-.041,.01),.018,skin,r,.010)
        rod('Foreleg',(side*.06,-.016,-.04),(side*.10,-.043,-.081),.010,skin,r,.007)
        for k in range(3):
            a=(side*.10,-.043,-.08);b=(side*(.09+k*.018),-.044,-.12-k*.003)
            rod('Splayed finger',a,b,.0035,skin,r,.0015,8)
        for k in range(4):
            x=side*(.025+k*.012);z=.015+k*.018
            y=.055*math.sqrt(max(0,1-(x/.08)**2-((z-.016)/.105)**2))+.0005
            ell('Dorsal mottling',(x,y,z),(.012,.002,.018),p['darkwood'],r,12,8)
    return r

def insect(kind):
    r=pivot(kind);bee=kind=='bee';dragon=kind=='dragonfly';butter=kind=='butterfly';fire=kind=='firefly'
    gold=mat('Bee golden fuzz',(.49,.29,.045),'fur');teal=mat('Dragonfly chitin',(.035,.28,.23),'scales',.35,.25)
    coat=gold if bee else teal if dragon else p['darkwood']
    ell('Thorax',(0,0,-.017),(.026,.027,.028),coat,r,20,12)
    ell('Head',(0,.005,-.039),(.024,.023,.021),black,r,20,12)
    ell('Abdomen',(0,-.002,.020),(.026,.027,.049) if bee else (.012,.014,.095) if dragon else (.012,.014,.046),coat,r,24,16)
    for j in range(5 if dragon else 3):
        z=.0+j*(.015 if dragon else .011)
        ell('Abdominal segment',(0,-.002,z),(.013,.015,.004) if dragon else (.027,.028,.006) if bee else (.013,.015,.003),black,r,16,8)
    for side in [-1,1]:
        ell('Compound eye',(side*.009,.007,-.043),(.012,.014,.012),teal if dragon else black,r,16,12)
        for j in range(3):
            rod('Leg femur',(side*.008,-.006,-.023+j*.012),(side*.024,-.016,-.027+j*.014),.0018,black,r,vertices=8)
            rod('Leg tibia',(side*.024,-.016,-.027+j*.014),(side*.031,-.030,-.020+j*.016),.0013,black,r,.0006,8)
        rod('Antenna',(side*.007,.010,-.044),(side*.015,.029,-.057),.0008,black,r,.0004,8)
        w=pivot('WingL' if side<0 else 'WingR',(side*.008,.009,-.011),r);w['side']=side
        wingmat=mat('Butterfly ochre scales',(.68,.25,.045),'scales') if butter else mat('Veined insect membrane',(.64,.75,.72),rough=.32,alpha=.46)
        for j in range(2):
            end=(side*(.090 if butter else .095 if dragon else .063),.0,-.039+j*.070)
            if butter:
                tip=Vector(end);axis=tip.normalized();cross=Vector((-axis.z,0,axis.x));vs=[tip*.5+Vector((0,.002,0))]
                for k in range(32):
                    t=k*math.tau/32;point=tip*.5+tip*.5*math.cos(t)+cross*(.033 if j==0 else .029)*math.sin(t);vs.append(point)
                mesh('Rounded butterfly wing',vs,[(0,k+1,(k+1)%32+1) for k in range(32)],wingmat,w,False)
                for k in range(32):rod('Dark scalloped wing margin',vs[k+1],vs[(k+1)%32+1],.0014,black,w,vertices=6)
            else:
                leaf('Forewing' if j==0 else 'Hindwing',(0,0,0),end,.012,wingmat,w)
            for k in range(4):
                a=Vector((0,.001,0));b=Vector(end)+Vector((0,0,(k-1.5)*(.012 if butter else .004)))
                rod('Wing vein',a,b,.00055,black if butter else p['ivory'],w,.00015,6)
            if butter:
                for k in range(5):
                    x=side*(.036+k*.010);z=(-.027 if j==0 else .023)+(k-2)*.002
                    ell('Wing border spot',(x,.002,z),(.006,.002,.008),p['ivory'],w,12,8)
                ell('Eyespot',(side*.064,.003,-.030+j*.061),(.023,.003,.021),black,w,16,10)
                ell('Eyespot amber',(side*.064,.005,-.030+j*.061),(.013,.003,.011),gold,w,16,10)
    if fire:
        glow=mat('Firefly lantern',(.61,.79,.12));bs=glow.node_tree.nodes.get('Principled BSDF');bs.inputs['Emission Color'].default_value=(.61,.9,.10,1);bs.inputs['Emission Strength'].default_value=3
        ell('Bioluminescent abdomen',(0,-.001,.043),(.014,.013,.015),glow,r)
    return r

def shell_spot(parent,x,z,radius):
    vertices=[];faces=[]
    for ring in range(5):
        for k in range(32):
            px=x+math.cos(k*math.tau/32)*radius*ring/4
            pz=z+math.sin(k*math.tau/32)*radius*ring/4
            y=.021+.025*math.sqrt(max(.001,1-(px/.033)**2-((pz-.008)/.043)**2))+.00045
            vertices.append((px,y,pz))
    for ring in range(4):
        for k in range(32):
            a=ring*32+k;b=ring*32+(k+1)%32
            faces.append((a,a+32,b+32,b))
    mesh('Flush elytron pigment',vertices,faces,black,parent,False)

def lady_beetle():
    r=pivot('lady_beetle')
    scarlet=mat('Lady beetle scarlet wing cases',(.58,.022,.012),'shell',.30)
    ell('Black abdomen',(0,.015,.004),(.057,.028,.078),black,r,24,16)
    ell('Pronotum',(0,.025,-.028),(.050,.030,.027),black,r,24,16)
    ell('Head',(0,.018,-.046),(.030,.023,.025),black,r,20,12)
    for side in [-1,1]:
        # Two closed wing covers share an elliptical dome with a fine central seam.
        vertices=[]; faces=[]; rings=18; sectors=32
        for j in range(rings+1):
            theta=j*math.pi/(2*rings)
            for k in range(sectors+1):
                phi=k*math.pi/sectors
                vertices.append((side*(.0002+.033*math.sin(theta)*math.sin(phi)),.021+.025*math.cos(theta),.008+.043*math.sin(theta)*math.cos(phi)))
        for j in range(rings):
            for k in range(sectors):
                a=j*(sectors+1)+k; face=(a,a+1,a+sectors+2,a+sectors+1)
                faces.append(face if side<0 else tuple(reversed(face)))
        mesh('Scarlet elytron',vertices,faces,scarlet,r,False)

        ell('Ivory pronotum marking',(side*.019,.034,-.032),(.011,.002,.010),p['ivory'],r,16,10)
        ell('Eye',(side*.012,.023,-.048),(.007,.007,.007),black,r,12,8)
        for x,z,radius in [(side*.012,-.011,.0045),(side*.021,.011,.0055),(side*.012,.034,.0045)]:
            shell_spot(r,x,z,radius)
        for j in range(3):
            leg=pivot(('LegL' if side<0 else 'LegR')+str(j),(side*.017,.013,-.021+j*.022),r)
            rod('Femur',(0,0,0),(side*.016,-.003,-.010+j*.005),.002,black,leg,vertices=8)
            rod('Tibia',(side*.016,-.003,-.010+j*.005),(side*.025,-.012,-.016+j*.008),.0015,black,leg,.0008,8)
        rod('Clubbed antenna',(side*.008,.025,-.055),(side*.019,.029,-.066),.0012,black,r,.0009,8)
        ell('Antenna club',(side*.019,.029,-.066),(.004,.004,.005),black,r,12,8)
    shell_spot(r,0,-.023,.0045)
    return r

def fish():
    r=pivot('fish');scales=mat('Copper koi scales',(.64,.22,.066),'scales',.34)
    ell('Fusiform fish',(0,0,0),(.22,.065,.080),scales,r)
    ell('Koi cream flank',(.035,-.012,0),(.16,.048,.077),cream,r)
    for side in [-1,1]:
        ell('Fish eye',(.073,.012,side*.029),(.015,.015,.009),black,r,16,10)
        # Fins are closed thin leaves, with supporting rays.
        leaf('Pectoral fin',(.025,-.008,side*.026),(-.020,-.024,side*.077),.015,scales,r)
        for k in range(3):rod('Gill crease',(.05,.019-k*.009,side*.034),(.037,.016-k*.009,side*.039),.001, p['darkwood'],r,vertices=6)
    for side in [-1,1]:
        mesh('Forked tail',[(-.094,0,0),(-.165,side*.041,.004),(-.145,side*.004,0),(-.165,side*.041,-.004)],[(0,1,2),(0,2,3)],scales,r,False)
        for k in range(4):rod('Tail ray',(-.094,0,0),(-.158,side*(.008+k*.009),0),.0009,cream,r,.0002,6)
    mesh('Dorsal fin',[(.025,.027,0),(-.04,.060,0),(-.075,.023,0)],[(0,1,2)],scales,r,False)
    return r

roots=[]
for kind in ['rabbit','kangaroo','kangaroo_joey','songbird','native_bird','frog','bee','butterfly','dragonfly','firefly','fish','lady_beetle']:
    r=mammal('kangaroo',True) if kind=='kangaroo_joey' else mammal(kind) if kind in ['rabbit','kangaroo'] else bird(kind) if kind in ['songbird','native_bird'] else frog() if kind=='frog' else fish() if kind=='fish' else lady_beetle() if kind=='lady_beetle' else insect(kind)
    if '--only-lady-beetle' not in sys.argv or kind=='lady_beetle':export(r,'wildlife',kind)
    else:merge_meshes(r)
    roots.append(r)
for i,r in enumerate(roots):r.location=vec(((i%4)*1.8,0,(i//4)*2.2));r.hide_set(False)
save('wildlife_library.blend')
