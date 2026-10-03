"""Twenty-one furnishings based on the approved shape/reference sheets."""
import ast, math, numpy as np
from common_hq import *

def beam(a,b,width,parent,mat=None):
    a,b=Vector(a),Vector(b)
    o=box('Mortised timber',(a+b)*.5,(width,(b-a).length,width),mat or palette()['wood'],parent)
    o.rotation_euler=vec(b-a).to_track_quat('Z','Y').to_euler()
    return o

def hardware(parent,p,mat=None,r=.014):
    return ell('Inset fixing',p,(r*2,r*2,r*.55),mat or palette()['metal'],parent,12,8)

def original(kind):
    """Reuse shipped dimensions and glazing axes, upgrading materials/detail."""
    tree=ast.parse((ROOT/'art_source/build_shop.py').read_text())
    functions=ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)],type_ignores=[])
    namespace=dict(globals(),m=palette(),only=None,mat=material,export=lambda *args:None)
    exec(compile(functions,'preserved_shop_geometry','exec'),namespace)
    r=namespace['build'](kind)
    m=palette()
    if kind=='bench':
        for x in [-.65,.65]:
            for y in [.35,.58]:hardware(r,(x,y,-.285),r=.018)
        for x in [-.65,.65]:box('Iron foot shoe',(x,.035,-.30),(.12,.04,.13),m['iron'],r,.005)
    elif kind in ['arbor','pergola']:
        d=2.4 if kind=='pergola' else .7
        for x in [-1.15,1.15]:
            for z in [-d/2,d/2]:
                box('Post shoe',(x,.16,z),(.16,.075,.16),m['iron'],r,.003)
                hardware(r,(x,.19,z-.084))
    elif kind=='greenhouse':
        for x in [-1.6,1.6]:
            for z in [-1.4,0,1.4]:hardware(r,(x,2.28,z-.04),r=.008)
        for y in [.46,1.82]:
            box('Door hinge',(-.452,y,-1.448),(.026,.085,.022),m['metal'],r,.003)
    elif kind=='hive':
        for x in [-.24,.24]:hardware(r,(x,.33,-.316),r=.01)
    elif kind=='pot':
        rng=np.random.default_rng(16)
        for j in range(18):
            a=rng.uniform(0,math.tau);d=rng.uniform(.03,.29)
            ell('Soil aggregate',(math.cos(a)*d,.545,math.sin(a)*d),(.027,.013,.022),m['soil'],r,10,6)
    # Stone geometry has actual small weathering rather than only a flat colour.
    if kind in ['stone','bath','lantern','pond']:
        for o in r.children_recursive:
            if o.type=='MESH' and o.data.materials[0]==m['stone']:
                for v in o.data.vertices:
                    p=v.co;amount=.0022*math.sin(p.x*91+p.y*67+p.z*73)
                    v.co+=v.normal*amount
    return r

def build_new(kind):
    m=palette();r=pivot(kind)
    if kind=='potting_bench':
        for x in [-.72,.72]:
            for z in [-.25,.25]:
                box('Oak bench leg',(x,.44,z),(.085,.88,.085),m['wood'],r)
            box('Rear upright',(x,1.35,.27),(.075,1.08,.075),m['wood'],r)
        box('Zinc work surface',(0,.93,0),(1.68,.065,.68),m['zinc'],r)
        for j in range(5):box('Storage shelf slat',(0,.21,-.25+j*.12),(1.60,.04,.10),m['wood'],r)
        for y in [1.08,1.38,1.70]:box('Tool board slat',(0,y,.285),(1.60,.13,.05),m['wood'],r)
        for x in [-.40,.4]:
            box('Drawer front',(x,.80,-.31),(.73,.17,.055),m['wood'],r)
            rod('Drawer pull',(x-.07,.80,-.35),(x+.07,.80,-.35),.012,m['metal'],r)
        for j in range(3):
            p=pivot('Spare clay pot',(-.47+j*.45,.24,.06),r)
            lathe('Hollow nursery pot',[(0,0),(.08,0),(.13,.19),(.145,.20),(.14,.22),(.115,.22),(.11,.19),(.07,.035),(0,.035)],m['clay'],p,32)
        for x in [-.72,.72]:hardware(r,(x,.81,-.31))
        box('Loam bag',(0,.32,.08),(.32,.19,.22),material('HQ woven hessian',(.41,.31,.18),'fabric'),r,.035)
    elif kind=='compost_bays':
        for x in [-1.65,-.55,.55,1.65]:
            for z in [-.55,.55]:box('Compost corner post',(x,.55,z),(.10,1.10,.10),m['wood'],r)
            for j in range(7):box('Removable side slat',(x,.12+j*.14,0),(.045,.10,1.10),m['wood'],r)
        for j in range(7):
            box('Back slat',(0,.12+j*.14,.55),(3.35,.10,.045),m['wood'],r)
        for i,x in enumerate([-1.10,0,1.10]):
            for j in range(3+i):box('Lift-out front slat',(x,.12+j*.14,-.55),(1.02,.10,.045),m['wood'],r)
            ell('Compost mound',(x,.24+i*.07,0),(.90,.38+i*.08,.91),m['soil'],r,32,16)
        for x in [-1.65,-.55,.55,1.65]:
            for y in [.26,.82]:hardware(r,(x,y,-.58))
    elif kind=='rain_barrel':
        lathe('Staved barrel',[(0,0),(.33,0),(.36,.13),(.405,.50),(.39,.94),(.36,1.05),(.34,1.05),(.32,.98),(.36,.50),(.29,.07),(0,.07)],m['wood'],r,80)
        for y,rad in [(.12,.363),(.32,.39),(.75,.405),(.96,.388)]:
            lathe('Galvanized hoop',[(rad,y),(rad+.012,y),(rad+.012,y+.04),(rad,y+.04)],m['zinc'],r,80)
        for j in range(20):
            a=j*math.tau/20
            curve('Stave seam',[(math.cos(a)*q,h,math.sin(a)*q) for q,h in [(.333,.04),(.379,.25),(.407,.50),(.398,.80),(.363,1.035)]],[.0013]*5,m['darkwood'],r,6)
        lathe('Screened cover',[(0,1.025),(.34,1.025)],m['iron'],r,64)
        for j in range(-6,7):
            x=j*.045;z=math.sqrt(max(0,.33**2-x*x))
            rod('Cover screen',(x,1.033,-z),(x,1.033,z),.0012,m['zinc'],r,vertices=6)
        curve('Brass tap',[(0,.26,-.35),(0,.26,-.45),(0,.20,-.49)],[.019,.019,.015],m['metal'],r)
        rod('Tap cross handle',(-.055,.31,-.425),(.055,.31,-.425),.010,m['metal'],r)
        box('Screen lid grip',(0,1.06,0),(.14,.035,.035),m['zinc'],r,.006)
    elif kind=='raised_bed':
        for y in [.085,.235]:
            for z in [-.65,.65]:box('Bed long board',(0,y,z),(2,.14,.05),m['wood'],r)
            for x in [-.975,.975]:box('Bed end board',(x,y,0),(.05,.14,1.25),m['wood'],r)
        for x in [-.93,.93]:
            for z in [-.60,.60]:box('Inner corner stake',(x,.15,z),(.07,.30,.07),m['darkwood'],r)
        box('Grounded garden soil',(0,.10,0),(1.9,.20,1.20),m['soil'],r,.015)
        for x in [-.92,.92]:
            for y in [.085,.235]:hardware(r,(x,y,-.677),r=.009)
    elif kind=='trellis_screen':
        for panel in range(3):
            x=(panel-1)*.78
            for dx in [-.37,.37]:
                box('Screen upright',(x+dx,1.02,0),(.07,1.86,.07),m['wood'],r)
                box('Stone screen foot',(x+dx,.06,0),(.23,.12,.30),m['stone'],r)
            for y in [.22,1.90]:box('Screen border',(x,y,0),(.78,.075,.075),m['wood'],r)
            for offset in np.arange(-.65,1.63,.18):
                for direction in [-1,1]:
                    start_y=max(0,float(offset));end_y=min(1.63,float(offset)+.66)
                    start_x=-.33+max(0,-float(offset));end_x=.33-max(0,float(offset)+.66-1.63)
                    if end_y>start_y:
                        beam((x+start_x*direction,.25+start_y,0),(x+end_x*direction,.25+end_y,0),.018,r,m['darkwood'])
            for y in [.30,1.70]:hardware(r,(x-.37,y,-.039),r=.008)
    elif kind=='gazebo':
        for j in range(6):
            a=j*math.tau/6;x,z=math.cos(a)*1.65,math.sin(a)*1.65
            box('Gazebo post',(x,1.30,z),(.13,2.6,.13),m['wood'],r)
            box('Stone post foot',(x,.06,z),(.25,.12,.25),m['stone'],r)
            b=(j+1)*math.tau/6
            beam((x,2.5,z),(math.cos(b)*1.65,2.5,math.sin(b)*1.65),.14,r,m['darkwood'])
            beam((x,2.04,z),(x*.76,2.50,z*.76),.075,r)
            mesh('Hexagonal roof slope',[(0,3.48,0),(math.cos(a)*1.96,2.57,math.sin(a)*1.96),(math.cos(b)*1.96,2.57,math.sin(b)*1.96)],[(0,2,1)],m['darkwood'],r,False)
            for k in range(9):
                t0=k/9;t1=min(1,(k+1)/9+.012)
                count=max(1,round((k+.5)/9*11))
                for n in range(count):
                    def tile_point(t,u):
                        return ((math.cos(a)*(1-u)+math.cos(b)*u)*1.96*t,
                            3.48-.91*t+.019+(8-k)*.0015,
                            (math.sin(a)*(1-u)+math.sin(b)*u)*1.96*t)
                    u0=n/count+.004;u1=(n+1)/count-.004
                    tile=mesh('Individual fitted hexagonal shingle',[tile_point(t0,u0),tile_point(t0,u1),tile_point(t1,u1),tile_point(t1,u0)],[(0,1,2,3)],m['wood'],r,False)
                    thickness=tile.modifiers.new('Shingle edge','SOLIDIFY');thickness.thickness=.012
                    bpy.context.view_layer.objects.active=tile;bpy.ops.object.modifier_apply(modifier=thickness.name)
            if j in [1,2,3]:
                middle=(Vector((x,0,z))+Vector((math.cos(b)*1.65,0,math.sin(b)*1.65)))*.40
                seat=box('Built-in gazebo seat',middle+Vector((0,.49,0)),(1.52,.065,.40),m['wood'],r)
                seat.rotation_euler.z=-(a+b)/2+math.pi/2
        ell('Gazebo finial',(0,3.53,0),(.10,.15,.10),m['metal'],r)
    elif kind=='arched_bridge':
        length=3.6
        def height(x):return .10+.36*math.cos(x/length*math.pi)
        for i in range(20):
            x=-length/2+(i+.5)*length/20
            plank=box('Arched deck plank',(x,height(x),0),(.17,.075,1.42),m['wood'],r)
            plank.rotation_euler.y=-math.atan(-.36*math.pi/length*math.sin(x/length*math.pi))
            for z in [-.52,.52]:ell('Deck fixing',(x,height(x)+.043,z),(.012,.005,.012),m['metal'],r,8,6)
        for z in [-.68,.68]:
            for x in [-1.65,-.55,.55,1.65]:box('Bridge rail post',(x,height(x)+.47,z),(.075,.91,.075),m['wood'],r)
            for level in [.33,.87]:
                points=[(-1.8+i*.18,height(-1.8+i*.18)+level,z) for i in range(21)]
                curve('Continuous curved rail',points,[.045]*len(points),m['wood'],r,8)
        for x in [-1.85,1.85]:box('Stone bridge landing',(x,.03,0),(.35,.10,1.62),m['stone'],r,.03)
    elif kind=='fountain':
        lathe('Fountain catch basin',[(0,0),(.80,0),(.88,.05),(.92,.18),(.92,.32),(.87,.36),(.79,.31),(.72,.13),(0,.13)],m['stone'],r,96)
        lathe('Fountain pedestal',[(0,.12),(.26,.12),(.22,.24),(.13,.65),(.23,.76),(.25,.83)],m['stone'],r,64)
        lathe('Upper fountain bowl',[(0,.74),(.23,.76),(.47,.86),(.50,.94),(.47,.99),(.41,.92),(0,.85)],m['stone'],r,80)
        lathe('Catch basin water',[(0,.27),(.80,.27)],m['water'],r,96)
        lathe('Upper bowl water',[(0,.93),(.43,.93)],m['water'],r,80)
        for j in range(12):
            a=j*math.tau/12
            curve('Falling water thread',[(math.cos(a)*.45,.93,math.sin(a)*.45),(math.cos(a)*.49,.62,math.sin(a)*.49),(math.cos(a)*.56,.28,math.sin(a)*.56)],[.008,.011,.013],m['water'],r,8)
        ell('Fountain spout',(0,.995,0),(.065,.09,.065),m['metal'],r)
    elif kind=='garden_swing':
        for x in [-1.15,1.15]:
            for z in [-.72,.72]:
                beam((x,.04,z),(x,2.25,0),.115,r)
                box('Swing footing',(x,.025,z),(.23,.06,.23),m['stone'],r)
            beam((x,.91,-.40),(x,.91,.40),.085,r,m['darkwood'])
        box('Swing top beam',(0,2.28,0),(2.65,.15,.15),m['darkwood'],r)
        seat=pivot('Swing',(0,2.20,0),r)
        for x in [-.73,.73]:
            for z in [-.20,.20]:
                for j in range(17):
                    y=-.06-j*.089
                    bpy.ops.mesh.primitive_torus_add(major_segments=10,minor_segments=6,location=vec((x,y,z)),major_radius=.034,minor_radius=.008)
                    o=bpy.context.object;o.name='Interlocked chain';o.parent=seat;o.data.materials.append(m['iron'])
                    o.rotation_euler=(math.pi/2,0,(j%2)*math.pi/2)
        for z in [-.22,-.075,.075,.22]:box('Swing seat slat',(0,-1.62,z),(1.64,.06,.13),m['wood'],seat)
        for y in [-1.46,-1.28]:box('Swing back slat',(0,y,.25),(1.64,.13,.06),m['wood'],seat)
        for x in [-.74,.74]:box('Swing armrest',(x,-1.35,0),(.09,.06,.57),m['wood'],seat)
        def sway(t,rest):seat.rotation_euler.x=.035*math.sin(t*math.tau)
        animate(r,[('sway',6.0,sway)])
    elif kind=='insect_hotel':
        for x in [-.38,.38]:box('Hotel leg',(x,.19,0),(.08,.38,.08),m['wood'],r)
        box('Habitat back',(0,.97,.18),(.88,1.2,.06),m['darkwood'],r)
        for x in [-.44,.44]:box('Cabinet side',(x,.97,0),(.065,1.23,.39),m['wood'],r)
        for y in [.36,.72,1.12,1.55]:box('Habitat shelf',(0,y,0),(.94,.055,.39),m['wood'],r)
        for side in [-1,1]:beam((0,1.84,0),(side*.56,1.53,0),.10,r,m['darkwood'])
        for side in [-1,1]:
            roof=box('Hotel pitched roof',(side*.26,1.71,0),(.63,.05,.55),m['wood'],r)
            roof.rotation_euler.y=side*.49
        rng=np.random.default_rng(81)
        reed=material('HQ dry reeds',(.52,.37,.16),'wood')
        for j in range(65):
            x=rng.uniform(-.36,.36);y=rng.uniform(.77,1.065);rad=rng.uniform(.011,.024)
            rod('Reed nesting tube',(x,y,-.17),(x,y,.15),rad,reed,r,vertices=10)
            ell('Reed tube opening',(x,y,-.175),(rad*1.45,rad*1.45,.003),m['darkwood'],r,10,6)
        for x in [-.23,0,.23]:
            rod('Drilled timber log',(x,.52,-.17),(x,.52,.15),.102,m['wood'],r,vertices=18)
            for dx,dy in [(-.025,-.030),(.03,-.020),(0,.035)]:ell('Nesting bore',(x+dx,.52+dy,-.174),(.026,.026,.003),m['black'],r,12,8)
        for j in range(16):
            x=rng.uniform(-.32,.32);y=rng.uniform(1.20,1.48)
            rod('Twig chamber',(x,y,-.15),(x+.04,y+.01,.16),.019,m['wood'],r,vertices=10)
    else:raise ValueError(kind)
    return r

OLD=['stone','pot','bench','lantern','arbor','pergola','greenhouse','pond','bath','hive','sign']
NEW=['potting_bench','compost_bays','rain_barrel','raised_bed','trellis_screen','gazebo','arched_bridge','fountain','garden_swing','insect_hotel']

def build(kind):
    s=scene('structures')
    replace_authored('structures','shop',kind)
    r=original(kind) if kind in OLD else build_new(kind)
    record=export(r,'shop',kind)
    i=(OLD+NEW).index(kind);r.location=vec(((i%5)*5.5,0,(i//5)*5.5));r.hide_set(False)
    save('structures')
    return record
