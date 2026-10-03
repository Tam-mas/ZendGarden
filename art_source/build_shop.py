"""Build all eleven game-ready shop assets, with embedded PBR textures."""
import sys, math
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent/'detail'))
from common import *
from mathutils import Matrix

args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
only=args[1] if len(args)==2 and args[0]=='--only' else None
if args and only!='greenhouse': raise ValueError('Supported selective rebuild: --only greenhouse')
if only:
    # Run with shop_library.blend loaded in a separate background process.
    gallery=next((scene for scene in bpy.data.scenes if any(
        obj.parent is None and obj.name.split('.')[0]=='greenhouse' for obj in scene.objects)),None)
    assert gallery, 'Load shop_library.blend for a selective rebuild'
    bpy.context.window.scene=gallery
    original=next(obj for obj in gallery.objects if obj.parent is None and obj.name.split('.')[0]=='greenhouse')
    original_name=original.name
    materials={material.name.split('.')[0]:material for obj in original.children_recursive
               if obj.type=='MESH' for material in obj.data.materials}
    m={key:materials[name] for key,name in {
        'wood':'Weathered cedar','darkwood':'Oiled oak','stone':'Carved limestone',
        'metal':'Aged bronze','glass':'Greenhouse glass'}.items()}
else:
    scene_new('ZendGarden_DetailedShop'); m=palette()

def bolt(p,parent):ell('Recessed bronze fixing',p,(.025,.025,.013),m['metal'],parent,12,8)
def beam(a,b,width,parent,material=None):
    a,b=Vector(a),Vector(b);o=box('Braced joinery',(a+b)*.5,(width,(b-a).length,width),material or m['wood'],parent);o.rotation_euler=vec(b-a).to_track_quat('Z','Y').to_euler();return o

def build(kind):
    r=pivot(kind)
    if only: r.name=original_name
    if kind=='bench':
        for x in [-.65,.65]:
            for z in [-.23,.23]:
                beam((x,0,z*1.3),(x,.60,z),.085,r,m['iron'])
            box('Seat bearer',(x,.55,0),(.085,.10,.64),m['iron'],r)
            beam((x,.55,.26),(x,1.10,.34),.065,r,m['iron'])
            beam((x,.30,-.23),(x,.57,.23),.045,r,m['iron'])
            box('Armrest',(x,.81,0),(.11,.07,.60),m['wood'],r)
            beam((x,.58,-.20),(x,.79,-.20),.045,r,m['iron'])
        beam((-.65,.25,0),(.65,.25,0),.055,r,m['iron'])
        for z in [-.24,-.08,.08,.24]:
            box('Separate seat slat',(0,.62,z),(1.75,.065,.145),m['wood'],r)
            for x in [-.65,.65]:ell('Seat bolt',(x,.656,z),(.022,.008,.022),m['metal'],r,12,8)
        for y in [.83,1.01]:
            box('Back slat',(0,y,.31),(1.75,.15,.06),m['wood'],r)
            for x in [-.65,.65]:bolt((x,y,.275),r)
    elif kind in ['arbor','pergola']:
        d=2.4 if kind=='pergola' else .7
        for x in [-1.15,1.15]:
            for z in [-d/2,d/2]:
                box('Stone footing',(x,.06,z),(.24,.12,.24),m['stone'],r)
                box('Cedar upright',(x,1.34,z),(.14,2.56,.14),m['wood'],r)
                box('Post cap',(x,2.63,z),(.20,.055,.20),m['darkwood'],r)
                beam((x,2.03,z),(x-math.copysign(.46,x),2.48,z),.085,r)
                for y in [.19,2.44]:bolt((x,y,z-.075),r)
            for y in [.48,1.10,1.72]:box('Trellis rail',(x,y,0),(.075,.07,d),m['darkwood'],r)
            # Diamond trellis contained inside each side frame.
            for j in range(7):
                z=-d/2+j*d/6
                beam((x,.48,z),(x,1.72,min(d/2,z+.45)),.025,r)
                beam((x,.48,z),(x,1.72,max(-d/2,z-.45)),.025,r)
        for z in [-d/2,d/2]:box('Lintel',(0,2.51,z),(2.9,.19,.15),m['darkwood'],r)
        for j in range(9):box('Overhead rafter',(-1.4+j*.35,2.66,0),(.075,.15,d+.55),m['wood'],r)
    elif kind=='greenhouse':
        for x in [-1.6,1.6]:
            box('Masonry curb',(x,.10,0),(.16,.20,2.94),m['stone'],r)
            for z in [-1.4,-.7,0,.7,1.4]:
                box('Wall mullion',(x,1.25,z),(.055,2.3,.055),m['darkwood'],r)
                beam((x,2.3,z),(0,3.05,z),.05,r,m['darkwood'])
            for y in [.2,1.22,2.30]:box('Glazing rail',(x,y,0),(.065,.055,2.87),m['darkwood'],r)
            for z in [-1.05,-.35,.35,1.05]:
                for y in [.70,1.76]:box('Individual glass pane',(x,y,z),(.016,.98,.65),m['glass'],r,.002)
                a=Vector((x,2.3,z));b=Vector((0,3.05,z))
                o=box('Roof glass',(a+b)*.5,(.016,(b-a).length-.03,.66),m['glass'],r,.002)
                # box() maps height to Blender Z and width to Blender Y.
                # Keep the width parallel to the ridge; a generic track/up
                # quaternion turned these panes 90 degrees out of the roof.
                slope=vec(b-a).normalized();width=vec((0,0,1))
                normal=width.cross(slope).normalized()
                o.rotation_euler=Matrix((normal,width,slope)).transposed().to_euler()
            box('Gutter',(x,2.26,0),(.10,.075,3.05),m['metal'],r)
            rod('Downpipe',(x,.1,1.48),(x,2.28,1.48),.025,m['metal'],r)
            box('Potting shelf',(x*.78,.85,.22),(.48,.055,2.1),m['wood'],r)
            for z in [-.7,.8]:beam((x*.78,.05,z),(x*.78,.83,z),.055,r)
        box('Ridge cap',(0,3.06,0),(.075,.075,2.98),m['metal'],r)
        for z in [-1.4,1.4]:
            for x in [-.48,.48]:box('Door jamb',(x,1.16,z),(.065,2.3,.065),m['darkwood'],r)
            for x in [-1.05,1.05]:box('End glazing',(x,1.25,z),(1.02,2.1,.016),m['glass'],r,.002)
            box('Door header',(0,2.30,z),(3.2,.07,.07),m['darkwood'],r)
            mesh('Gable glass',[(-1.55,2.34,z),(1.55,2.34,z),(0,3.03,z)],[(0,1,2)],m['glass'],r,False)
        for y in [.2,1.2,2.2]:box('Door crossbar',(0,y,-1.405),(.88,.055,.055),m['wood'],r)
        for x in [-.43,.43]:box('Door stile',(x,1.2,-1.405),(.055,2.08,.055),m['wood'],r)
        box('Door glass',(0,1.2,-1.4),(.82,1.94,.013),m['glass'],r,.002)
        rod('Door handle',(.31,1.01,-1.46),(.31,1.2,-1.46),.015,m['metal'],r)
        box('Entry step',(0,.035,-1.58),(1.04,.07,.35),m['stone'],r)
    elif kind=='hive':
        for x in [-.24,.24]:
            for z in [-.20,.20]:box('Hive stand leg',(x,.17,z),(.075,.34,.075),m['darkwood'],r)
        box('Bottom board',(0,.33,0),(.74,.07,.62),m['wood'],r)
        for y in [.49,.77]:
            box('Brood chamber',(0,y,0),(.66,.26,.54),m['wood'],r)
            for x in [-.337,.337]:box('Recessed side grip',(x,y+.015,0),(.025,.04,.18),m['darkwood'],r)
            for x in [-.29,.29]:
                for k in range(4):box('Finger joint',(x,y-.10+k*.06,-.276),(.06,.028,.013),m['darkwood'],r,.003)
        box('Vent slot',(0,.365,-.276),(.43,.028,.014),m['iron'],r)
        box('Landing board',(0,.32,-.37),(.54,.04,.27),m['wood'],r)
        box('Weatherproof metal cap',(0,.94,0),(.78,.075,.66),m['metal'],r)
        for z in [-.32,.32]:box('Folded roof lip',(0,.905,z),(.78,.045,.023),m['metal'],r)
    elif kind=='sign':
        for x in [-.65,.65]:
            box('Oak sign post',(x,.30,0),(.07,.60,.07),m['darkwood'],r)
        box('Solid carved signboard',(0,.62,0),(1.8,.52,.10),m['wood'],r)
        for z in [-.051,.051]:
            for x in [-.84,.84]:box('Border upright',(x,.62,z),(.025,.46,.007),m['darkwood'],r,.002)
            for y in [.395,.845]:box('Border edge',(0,y,z),(1.70,.025,.007),m['darkwood'],r,.002)
            for x in [-.78,.78]:bolt((x,.62,z*1.1),r)
    elif kind=='pot':
        lathe('Hollow thrown terracotta',[(0,0),(.24,0),(.27,.06),(.37,.53),(.405,.55),(.413,.60),(.40,.645),(.35,.645),(.346,.59),(.325,.54),(.235,.095),(0,.095)],m['clay'],r)
        for y in [.13,.18,.49]:lathe('Thrown clay bead',[(.278+(y-.13)*.22,y),(.281+(y-.13)*.22,y+.01),(.279+(y-.13)*.22,y+.019)],m['clay'],r)
        lathe('Soil below rim',[(0,.54),(.325,.54)],m['soil'],r)
    elif kind=='bath':
        lathe('Turned stone pedestal',[(0,0),(.32,0),(.33,.04),(.30,.09),(.22,.13),(.16,.25),(.115,.66),(.16,.82),(.24,.86),(.25,.9)],m['stone'],r)
        lathe('Concave bird bath',[(0,.84),(.25,.85),(.48,.89),(.60,.97),(.605,1.035),(.575,1.07),(.53,1.055),(.47,1.005),(.32,.965),(0,.95)],m['stone'],r)
        lathe('Bath water',[(0,1.018),(.495,1.018)],m['water'],r)
        for j in range(24):
            a=j*math.tau/24;ell('Rim carving',(.585*math.cos(a),1.02,.585*math.sin(a)),(.024,.023,.024),m['darkwood'],r,12,8)
    elif kind=='lantern':
        lathe('Stone base',[(0,0),(.32,0),(.33,.07),(.27,.12),(.22,.15),(.15,.22),(.14,.66),(.24,.70)],m['stone'],r)
        box('Lantern hearth',(0,.73,0),(.46,.09,.46),m['stone'],r)
        amber=mat('Amber lantern glass',(.8,.46,.13),rough=.23,alpha=.65)
        for x in [-.18,.18]:
            for z in [-.18,.18]:box('Lantern corner',(x,.90,z),(.055,.31,.055),m['stone'],r)
        for x in [-.178,.178]:box('Glazed side',(x,.90,0),(.012,.23,.30),amber,r)
        for z in [-.178,.178]:box('Glazed face',(0,.90,z),(.30,.23,.012),amber,r)
        lathe('Pagoda roof',[(0,1.02),(.24,1.02),(.39,1.06),(.40,1.09),(.31,1.14),(.17,1.28),(.07,1.31),(0,1.31)],m['stone'],r,48)
        ell('Roof finial',(0,1.34,0),(.10,.10,.10),m['stone'],r)
        glow=mat('Warm flame',(.95,.47,.10)); bs=glow.node_tree.nodes.get('Principled BSDF');bs.inputs['Emission Color'].default_value=(1,.39,.07,1);bs.inputs['Emission Strength'].default_value=2
        ell('Flame',(0,.87,0),(.07,.15,.07),glow,r)
    elif kind=='stone':
        o=ell('Irregular limestone',(0,.10,0),(.64,.23,.46),m['stone'],r,32,20)
        for v in o.data.vertices:
            v.co*=1+.04*math.sin(v.co.x*5+v.co.y*3)*math.cos(v.co.z*7)
    elif kind=='pond':
        lathe('Pond water',[(0,.045),(1.63,.045)],m['water'],r,96)
        lathe('Dark pond liner',[(0,-.10),(1.6,-.10),(1.65,.025)],m['stone'],r,96)
        for j in range(22):
            a=j*math.tau/22;rng=np.random.default_rng(j);o=ell('Weathered pond edging',(math.cos(a)*1.69,.12,math.sin(a)*1.69),(.48,.25+float(rng.random())*.09,.36),m['stone'],r,20,12);o.rotation_euler.z=-a
            for v in o.data.vertices:v.co*=1+.05*math.sin(v.co.x*6+v.co.y*4+v.co.z*7)
        petal=mat('Water lily petals',(.79,.53,.52),'feather')
        for j in range(5):
            a=j*2.4;x,z=math.cos(a)*(.65+j*.09),math.sin(a)*(.65+j*.09)
            vs=[(x,.062,z)]+[(x+math.cos(t*.15+.2)*.24,.063,z+math.sin(t*.15+.2)*.24) for t in range(40)]
            mesh('Notched lily pad',vs,[(0,k,k+1) for k in range(1,40)],m['leaf'],r,False)
            for k in range(7):
                t=k*math.tau/7;rod('Lily veins',(x,.066,z),(x+math.cos(t)*.21,.066,z+math.sin(t)*.21),.0015,m['darkwood'],r,vertices=6)
            if j<2:
                for k in range(12):
                    t=k*math.tau/12;leaf('Lily petal',(x,.07,z),(x+math.cos(t)*.14,.14,z+math.sin(t)*.14),.034,petal,r)
                ell('Lily centre',(x,.10,z),(.055,.05,.055),m['ivory'],r)
    export(r,'shop',kind)
    return r
if only:
    old=original;location=old.location.copy()
    for obj in list(old.children_recursive)+[old]:bpy.data.objects.remove(obj,do_unlink=True)
    replacement=build(only);replacement.location=location;replacement.hide_set(False)
else:
    roots=[build(k) for k in ['stone','pot','bench','lantern','arbor','pergola','greenhouse','pond','bath','hive','sign']]
    # Arrange editable source assets as a gallery; exported origins remain at ground centre.
    for i,r in enumerate(roots):r.location=vec(((i%4)*4.8,0,(i//4)*4.8));r.hide_set(False)
save('shop_library.blend')
