"""Add working equipment and planted displays without touching shipped libraries.

Run in an approved background Blender process. Metre-scale sockets are mirrored
in scripts/containers.gd; save a separate packed source gallery for rebuilding.
"""
import sys, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent/'overhaul'))
from common_hq import *

KINDS=['worm_farm','mulch_bin','shade_canopy','cold_frame','bird_feeder',
       'wide_bowl','large_planter','herb_trough','hanging_basket','vertical_planter','tiered_planter']

def fixing(root,x,y,z):
    ell('Recessed brass screw',(x,y,z),(.024,.024,.009),palette()['metal'],root,12,8)

def pocket(root,x,y,z,width=.48,depth=.33):
    m=palette()
    box('Pocket bottom',(x,y-.20,z),(width,.04,depth),m['wood'],root)
    for dx in [-width/2,width/2]:box('Pocket end',(x+dx,y-.10,z),(.035,.24,depth),m['wood'],root)
    for dz in [-depth/2,depth/2]:box('Pocket lip',(x,y-.10,z+dz),(width,.24,.035),m['wood'],root)
    box('Exposed potting soil',(x,y-.018,z),(width-.05,.035,depth-.04),m['soil'],root,.006)
    for dx in [-width*.40,width*.40]:fixing(root,x+dx,y-.06,z-depth/2-.02)

def build(kind):
    m=palette();r=pivot(kind)
    if kind=='worm_farm':
        for x in [-.34,.34]:
            for z in [-.26,.26]:box('Short wormery leg',(x,.12,z),(.07,.24,.07),m['darkwood'],r)
        for y in [.24,.45,.66]:
            box('Stackable casting tray',(0,y,0),(.86,.19,.66),m['wood'],r,.025)
            box('Tray separation',(0,y+.105,0),(.87,.025,.67),m['darkwood'],r,.004)
            rod('Lift handle',(-.10,y,-.35),(.10,y,-.35),.012,m['metal'],r)
        box('Wormery lid',(0,.81,0),(.92,.075,.72),m['wood'],r,.025)
        rod('Lid handle',(-.08,.87,0),(.08,.87,0),.02,m['iron'],r)
        curve('Drain tap',[(.28,.21,-.33),(.28,.21,-.42),(.28,.16,-.44)],[.016]*3,m['metal'],r)
    elif kind=='mulch_bin':
        for x in [-.48,.48]:
            for z in [-.40,.40]:box('Mulch bin corner',(x,.44,z),(.07,.88,.07),m['wood'],r)
        for y in [.10,.25,.40,.55,.70]:
            for x in [-.48,.48]:box('Ventilated side slat',(x,y,0),(.035,.11,.84),m['wood'],r)
            for z in [-.40,.40]:box('Ventilated front slat',(0,y,z),(.98,.11,.035),m['wood'],r)
        ell('Mulch heap',(0,.34,0),(.82,.55,.64),m['soil'],r,32,16)
        for j in range(35):
            a=j*2.3999;d=.30*math.sqrt((j+1)/35)
            ell('Dry leaf fragment',(math.cos(a)*d,.56+.035*math.sin(j),math.sin(a)*d*.8),(.07,.018,.04),m['wood'] if j%2 else m['leaf'],r,10,6)
    elif kind=='shade_canopy':
        for x in [-1,1]:
            for z in [-1,1]:
                box('Shade footing',(x,.035,z),(.18,.07,.18),m['stone'],r)
                box('Shade upright',(x,1.06,z),(.07,2.06,.07),m['wood'],r)
        for z in [-1,1]:box('Shade top rail',(0,2.08,z),(2.13,.07,.07),m['darkwood'],r)
        cloth=pivot('ShadeFabric',(0,2.08,0),r)
        fabric=material('Working garden sage shade cloth',(.18,.27,.17),'fabric',alpha=.94,size=512)
        vs=[(x*.10-1,-.08*math.sin((x/20)*math.pi)*math.sin((z/20)*math.pi),z*.10-1) for x in range(21) for z in range(21)]
        fs=[(x*21+z,(x+1)*21+z,(x+1)*21+z+1,x*21+z+1) for x in range(20) for z in range(20)]
        mesh('Woven shade sail',vs,fs,fabric,cloth,False)
        for j in range(5):rod('Shade eyelet',(-1+j*.5,0,-1),(-1+j*.5,0,-.96),.012,m['metal'],cloth)
    elif kind=='cold_frame':
        for z,h in [(-.75,.42),(.75,.76)]:
            for y in [.12,.29]:box('Cold frame long board',(0,y,z),(2.05,.15,.055),m['wood'],r)
            box('Frame top rail',(0,h,z),(2.05,.065,.065),m['darkwood'],r)
        for x in [-1,1]:
            box('Side panel',(x,.22,0),(.055,.42,1.5),m['wood'],r)
            rod('Sloped side rail',(x,.42,-.75),(x,.76,.75),.028,m['darkwood'],r)
        lid=pivot('ColdFrameLid',(0,.79,.75),r)
        for x in [-1,-.33,.33,1]:rod('Glazing mullion',(x,0,0),(x,-.34,-1.5),.018,m['darkwood'],lid)
        for z,y in [(0,0),(-1.5,-.34)]:box('Lid end rail',(0,y,z),(2.05,.045,.04),m['darkwood'],lid)
        for x in [-.665,0,.665]:
            mesh('Cold frame glass',[(x-.305,-.006,-.02),(x+.305,-.006,-.02),(x+.305,-.334,-1.48),(x-.305,-.334,-1.48)],[(0,1,2,3)],m['glass'],lid,False)
        rod('Lid handle',(-.10,-.29,-1.53),(.10,-.29,-1.53),.014,m['metal'],lid)
    elif kind=='bird_feeder':
        box('Bird table post',(0,.55,0),(.095,1.10,.095),m['wood'],r)
        for a in [0,math.pi/2]:
            foot=box('Crossed table foot',(0,.035,0),(.92,.07,.10),m['darkwood'],r)
            foot.rotation_euler.z=a
        box('Feeding platform',(0,1.10,0),(.80,.045,.62),m['wood'],r)
        for z in [-.31,.31]:box('Seed retaining lip',(0,1.15,z),(.83,.065,.035),m['darkwood'],r)
        for x in [-.40,.40]:
            box('Roof support',(x,1.33,0),(.045,.43,.045),m['wood'],r)
            roof=box('Sloping table roof',(x*.5,1.60,0),(.48,.055,.80),m['wood'],r)
            roof.rotation_euler.y=math.copysign(.36,x)
        feed=pivot('BirdFood',(0,1.135,0),r)
        for j in range(24):
            a=j*2.3999;d=.26*math.sqrt((j+1)/24)
            ell('Small seed',(math.cos(a)*d,0,math.sin(a)*d*.75),(.025,.012,.014),m['ivory'],feed,10,6)
    elif kind=='wide_bowl':
        lathe('Hollow terracotta bowl',[(0,0),(.28,0),(.50,.20),(.54,.29),(.53,.32),(.49,.32),(.47,.27),(.24,.055),(0,.055)],m['clay'],r,64)
        lathe('Bowl soil',[(0,.27),(.47,.27)],m['soil'],r,64)
    elif kind=='large_planter':
        for x in [-.53,.53]:
            for z in [-.53,.53]:box('Planter corner post',(x,.40,z),(.085,.80,.085),m['darkwood'],r)
        for y in [.12,.29,.46,.63]:
            for x in [-.55,.55]:box('Planter side board',(x,y,0),(.045,.145,1.10),m['wood'],r)
            for z in [-.55,.55]:box('Planter front board',(0,y,z),(1.10,.145,.045),m['wood'],r)
        box('Deep planter soil',(0,.71,0),(1.03,.06,1.03),m['soil'],r,.01)
    elif kind=='herb_trough':
        for x in [-.58,.58]:
            for z in [-.16,.16]:box('Raised trough leg',(x,.22,z),(.055,.44,.055),m['darkwood'],r)
        pocket(r,0,.68,0,1.40,.46)
    elif kind=='hanging_basket':
        for x in [-.60,.60]:
            box('Basket stand foot',(x,.035,0),(.16,.07,.68),m['darkwood'],r)
            rod('Iron basket upright',(x,.06,0),(x,1.90,0),.025,m['iron'],r)
        rod('Basket crossbar',(-.60,1.90,0),(.60,1.90,0),.025,m['iron'],r)
        lathe('Coconut lined basket',[(0,.91),(.14,.95),(.28,1.16),(.30,1.22),(.27,1.22),(.25,1.15),(.13,.98),(0,.98)],m['wood'],r,64)
        lathe('Basket soil',[(0,1.20),(.265,1.20)],m['soil'],r,64)
        for j in range(3):
            a=j*math.tau/3
            rod('Suspension chain',(math.cos(a)*.28,1.22,math.sin(a)*.28),(0,1.86,0),.008,m['iron'],r)
        for j in range(14):
            a=j*math.tau/14
            curve('Basket rib',[(math.cos(a)*d,y,math.sin(a)*d) for d,y in [(.12,.95),(.22,1.04),(.29,1.20)]],[.009]*3,m['iron'],r)
    elif kind=='vertical_planter':
        for x in [-.68,.68]:
            box('Living wall foot',(x,.04,.05),(.17,.08,.90),m['darkwood'],r)
            box('Living wall post',(x,1.02,.07),(.085,2.04,.085),m['wood'],r)
        for y in [.20,.43,.66,.89,1.12,1.35,1.58,1.81,2.02]:box('Living wall back slat',(0,y,.09),(1.42,.15,.045),m['wood'],r)
        for y in [.50,1.05,1.60]:
            for x in [-.40,.40]:pocket(r,x,y,-.18,.55,.33)
    elif kind=='tiered_planter':
        for z,y in [(-.40,.36),(0,.86),(.40,1.36)]:
            for x in [-.35,.35]:pocket(r,x,y,z,.54,.36)
        for x in [-.66,.66]:
            rod('Stepped display side',(x,.12,-.60),(x,1.30,.40),.035,m['darkwood'],r)
            box('Display back support',(x,.66,.43),(.065,1.32,.065),m['wood'],r)
            box('Display foot',(x,.035,0),(.10,.07,1.1),m['darkwood'],r)
    return r

scene('WorkingGarden')
roots=[]
for kind in KINDS:
    root=build(kind)
    export(root,'shop',kind)
    roots.append(root)
for i,root in enumerate(roots):root.location=vec(((i%4)*3.5,0,(i//4)*3.5))
save('WorkingGarden')
print('WORKING_GARDEN_MODELS:',len(roots))
