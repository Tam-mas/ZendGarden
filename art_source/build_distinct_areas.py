"""Author ten playable habitats through the interactive Blender MCP bridge.

Y-up metres; deterministic geometry and shared PBR materials. Never clears a
scene or saves user preferences. Call build_one(index) sequentially from MCP.
"""
import bpy, math, random, json, sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'art_source/overhaul'))
import common_hq as hq

KINDS = ['reedwater', 'fern_gully', 'limestone', 'pollinator', 'orchard',
         'kitchen', 'glasshouse', 'stream', 'alpine', 'moon']
NAMES = ['Reedwater Garden', 'Fern Gully', 'Limestone Terraces',
         'Pollinator Meadow', 'Orchard Clearing', 'Walled Kitchen Garden',
         'Old Glasshouse', 'Stream Garden', 'Alpine Lookout', 'Moon Garden']
DESCRIPTIONS = [
    'Plant at three water depths and adjust the inlet sluice.',
    'Open little clearings, grow ferns and discover hidden shade collections.',
    'Choose drainage pockets, fold rain shelters and propagate succulent offsets.',
    'Grow a changing flower calendar and record visiting pollinators.',
    'Train fruit trees, graft compatible varieties and fill seasonal baskets.',
    'Pair companion crops, rotate beds and prepare kitchen baskets.',
    'Restore three bays and tune their light, ventilation and mist.',
    'Open stream gates and send water to the growing strips you choose.',
    'Create sheltered rock pockets and collect little alpine plants.',
    'Grow dusk-opening flowers, dim lanterns and collect night photographs.'
]
CONDITIONS = ['water', 'shade', 'sun', 'sun', 'sun', 'sun', 'any', 'water', 'sun', 'any']
SEEDS = [[8,16,147], [4,13,109], [124,126,135], [0,1,19], [35,83,84],
         [47,48,54], [5,23,123], [8,13,146], [14,126,144], [2,60,74]]
MATS = {}

def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a))); return t*t*(3-2*t)

def height(i,x,z):
    """One exported lattice drives Blender, Godot rays, collision and planting."""
    edge=1-smooth(9,12,max(abs(x),abs(z)))
    base=1.2
    if i==0:
        r=math.sqrt(((x+1.4)*.95)**2+((z+.2)*1.1)**2)
        land=.12+1.08*smooth(2.1,6.0,r)
    elif i==1:
        land=.72+1.65*smooth(1.1,7.5,abs(x))+.12*math.sin(z*.7)
    elif i==2:
        land=1.1+.65*smooth(5.2,2.8,z)+.65*smooth(.7,-1.7,z)+.65*smooth(-3.8,-6.2,z)
    elif i==3:
        land=1.15+.28*math.sin(x*.3)*math.cos(z*.25)
    elif i==4:
        land=1.15+.12*math.sin(z*.2)
    elif i in [5,6]: land=1.2
    elif i==7:
        land=1.25-.75*(1-smooth(.6,1.6,abs(x-1.5*math.sin(z*.4))))
    elif i==8:
        land=1.2+4.2*(1-smooth(2.0,10.5,math.hypot(x+1.2,z+3.5)))
    else:
        land=1.2-.85*(1-smooth(2.2,3.2,math.hypot(x+1,z)))
    return round(base+(land-base)*edge,5)

def at(i,x,z,dy=0):return (x,height(i,x,z)+.07+dy,z)

def materials():
    if MATS:return MATS
    p=hq.palette();MATS.update(p)
    for name,c in [('grass',(.17,.27,.12)),('moss',(.12,.23,.095)),('gravel',(.53,.50,.42)),
                   ('sand',(.53,.42,.26)),('slate',(.21,.25,.27)),('cream',(.65,.63,.49)),
                   ('brick',(.40,.19,.12)),('bark',(.19,.13,.075))]:
        MATS[name]=hq.material('Area '+name,c,'stone',size=512)
    for n,c in [('green',(.045,.145,.03)),('sage',(.12,.24,.11)),('silver',(.33,.43,.35)),
                ('fern',(.055,.19,.04)),('lime',(.13,.29,.05)),('reed',(.16,.24,.075)),
                ('white',(.87,.86,.73)),('pink',(.69,.27,.43)),('purple',(.35,.21,.54)),
                ('yellow',(.83,.60,.13)),('blue',(.23,.40,.64)),('orange',(.78,.29,.10))]:
        MATS[n]=hq.material('Area foliage '+n,c,None,rough=.82)
        MATS[n].use_backface_culling=False
    for key,file in [('mossrock','mossy-granite.png'),('paving','aged-brick.png')]:
        m=hq.material('Area generated '+key,(1,1,1),None,rough=.94)
        im=bpy.data.images.load(str(ROOT/'art_source/areas/textures'/file),check_existing=True);im.pack()
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im
        m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
        MATS[key]=m
    return MATS

class Geometry:
    """Batch primitives by material and functional pivot, retaining UV detail."""
    def __init__(self):self.groups={}
    def poly(self,parent,mat,vs,fs):
        group=self.groups.setdefault((parent,mat),[[],[]]);start=len(group[0])
        group[0].extend(vs);group[1].extend([tuple(start+j for j in f) for f in fs])
    def box(self,parent,mat,p,size,angle=0):
        x,y,z=p;w,h,d=[v/2 for v in size]
        points=[(a*w,b*h,c*d) for a,b,c in [(-1,-1,-1),(1,-1,-1),(1,-1,1),(-1,-1,1),(-1,1,-1),(1,1,-1),(1,1,1),(-1,1,1)]]
        co=[(x+a*math.cos(angle)-c*math.sin(angle),y+b,z+a*math.sin(angle)+c*math.cos(angle)) for a,b,c in points]
        self.poly(parent,mat,co,[tuple(reversed(face)) for face in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]])
    def ell(self,parent,mat,p,size,seed=0,sectors=16,rings=8,rough=0):
        rng=random.Random(seed);vs=[];fs=[]
        for k in range(rings+1):
            t=math.pi*k/rings
            for j in range(sectors):
                a=math.tau*j/sectors;f=1+rough*(math.sin(a*3+seed*.5)*.35+math.sin(t*4+a*2)*.35)
                vs.append((p[0]+math.sin(t)*math.cos(a)*size[0]*.5*f,p[1]+math.cos(t)*size[1]*.5*f,p[2]+math.sin(t)*math.sin(a)*size[2]*.5*f))
        for k in range(rings):
            for j in range(sectors):
                a=k*sectors+j;b=k*sectors+(j+1)%sectors;fs.append((a,b,b+sectors,a+sectors))
        self.poly(parent,mat,vs,fs)
    def tube(self,parent,mat,points,radii,sides=8):
        ps=[Vector(p) for p in points];vs=[];fs=[]
        for k,p in enumerate(ps):
            tangent=(ps[min(k+1,len(ps)-1)]-ps[max(k-1,0)]).normalized()
            axis=tangent.cross(Vector((0,1,0)))
            if axis.length<.01:axis=tangent.cross(Vector((1,0,0)))
            axis.normalize();cross=tangent.cross(axis).normalized()
            for j in range(sides):
                a=j*math.tau/sides;vs.append(tuple(p+(axis*math.cos(a)+cross*math.sin(a))*radii[k]))
        for k in range(len(ps)-1):
            for j in range(sides):
                a=k*sides+j;b=k*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
        fs.extend([tuple(reversed(range(sides))),tuple(range((len(ps)-1)*sides,len(vs)))])
        self.poly(parent,mat,vs,fs)
    def leaf(self,parent,mat,a,b,width,bend=.06):
        a=Vector(a);b=Vector(b);d=b-a;c=d.cross(Vector((0,1,0))).normalized()*width
        mid=a+d*.48+Vector((0,bend,0))
        self.poly(parent,mat,[tuple(a),tuple(a+d*.3+c),tuple(a+d*.73+c*.7),tuple(b),tuple(a+d*.73-c*.7),tuple(a+d*.3-c),tuple(mid)],[(0,1,6),(1,2,6),(2,3,6),(3,4,6),(4,5,6),(5,0,6)])
    def flush(self):
        for (parent,mat),(vs,fs) in self.groups.items():
            me=bpy.data.meshes.new(parent.name+' '+mat.name)
            me.from_pydata([hq.vec(p) for p in vs],[],fs);me.update()
            layer=me.uv_layers.new(name='UVMap')
            for face in me.polygons:
                face.use_smooth=not parent.get('flat',False)
                major=max(range(3),key=lambda k:abs(face.normal[k]));axes=[k for k in range(3) if k!=major]
                scale=2.0 if 'paving' in mat.name else .8
                for li in face.loop_indices:
                    v=me.vertices[me.loops[li].vertex_index].co
                    layer.data[li].uv=(v[axes[0]]/scale,v[axes[1]]/scale)
            ob=bpy.data.objects.new(parent.name+' '+mat.name,me);bpy.context.scene.collection.objects.link(ob)
            ob.parent=parent;me.materials.append(mat)
            if parent.get('ground'):ob['area_ground']=True
            if parent.get('collision'):ob['area_collision']=True
        self.groups.clear()

def pivot(name,root,p=(0,0,0),**extras):
    o=hq.pivot(name,p,root)
    for k,v in extras.items():o[k]=v
    return o

def rock(G,parent,i,x,z,size,seed=0,moss=True):
    G.ell(parent,MATS['mossrock' if moss else 'stone'],at(i,x,z,size[1]*.27),size,seed,rough=.19)

def pot(G,parent,p,r=.30,color='clay'):
    points=[];vs=[];fs=[];segments=20
    for radius,y in [(r*.63,0),(r*.74,.12),(r,.56),(r*1.06,.58),(r*1.06,.64),(r*.92,.64),(r*.87,.58),(r*.73,.15)]:
        for j in range(segments):
            a=j*math.tau/segments;vs.append((p[0]+radius*math.cos(a),p[1]+y,p[2]+radius*math.sin(a)))
    for k in range(7):
        for j in range(segments):
            a=k*segments+j;b=k*segments+(j+1)%segments;fs.append((a,b,b+segments,a+segments))
    G.poly(parent,MATS[color],vs,fs)
    G.ell(parent,MATS['soil'],(p[0],p[1]+.56,p[2]),(r*1.8,.035,r*1.8),sectors=20,rings=4)

def flower(G,parent,p,color='white',height=.6,count=5,seed=0):
    rng=random.Random(seed)
    for j in range(count):
        x=p[0]+rng.uniform(-.22,.22);z=p[2]+rng.uniform(-.22,.22);y=p[1]+height*rng.uniform(.7,1)
        G.tube(parent,MATS['green'],[(x,p[1],z),(x+.03,y-.12,z+.04),(x,y,z)],[.012,.008,.006],6)
        for k in range(2):
            a=j*2.3+k*2;G.leaf(parent,MATS['sage'],(x,y*.0+p[1]+height*(.25+k*.2),z),(x+math.cos(a)*.20,p[1]+height*(.35+k*.2),z+math.sin(a)*.20),.055)
        for k in range(8):
            a=k*math.tau/8;G.ell(parent,MATS[color],(x+math.cos(a)*.08,y,z+math.sin(a)*.08),(.10,.027,.07),sectors=8,rings=4)
        G.ell(parent,MATS['yellow'],(x,y+.02,z),(.068,.025,.068),sectors=8,rings=4)

def grass(G,parent,p,size=1,seed=0,color='reed'):
    rng=random.Random(seed)
    for k in range(18):
        a=rng.random()*math.tau;h=rng.uniform(.4,1)*size
        end=(p[0]+math.cos(a)*size*.33,p[1]+h,p[2]+math.sin(a)*size*.33)
        G.leaf(parent,MATS[color],p,end,.018+size*.009,bend=.015)
        if k%4==0:G.ell(parent,MATS['sand'],(end[0],end[1]+.08,end[2]),(.045,.18,.045),sectors=6,rings=4)

def fern(G,parent,p,size=1,seed=0,tree=False):
    rng=random.Random(seed)
    if tree:
        G.tube(parent,MATS['bark'],[(p[0],p[1],p[2]),(p[0]+.12,p[1]+size*2,p[2]+.05)],[size*.15,size*.11],12)
        p=(p[0]+.12,p[1]+size*2,p[2]+.05)
    for j in range(9):
        a=j*math.tau/9+rng.uniform(-.12,.12);length=size*rng.uniform(.8,1.2)
        ps=[(p[0]+math.cos(a)*length*t,p[1]+size*(.08+.45*math.sin(t*math.pi*.95)),p[2]+math.sin(a)*length*t) for t in [k/8 for k in range(9)]]
        G.tube(parent,MATS['lime'],ps,[.013*size*(1-k/10) for k in range(9)],5)
        for k in range(1,9):
            t=k/9;center=Vector(ps[k]);w=size*.18*math.sin(math.pi*t)
            for side in [-1,1]:
                end=center+Vector((math.cos(a+side*1.15)*w,size*.025,math.sin(a+side*1.15)*w))
                G.leaf(parent,MATS['fern' if j%3 else 'green'],center,end,w*.32,bend=.015)

def rail(G,parent,i,a,b,height_=1.0,wood=True):
    mat=MATS['wood' if wood else 'iron'];length=math.hypot(b[0]-a[0],b[1]-a[1]);n=max(1,int(length/1.3))
    for j in range(n+1):
        t=j/n;x=a[0]*(1-t)+b[0]*t;z=a[1]*(1-t)+b[1]*t;p=at(i,x,z)
        G.box(parent,mat,(x,p[1]+height_*.5,z),(.09,height_,.09))
    for dy in [.45,height_]:
        ps=[at(i,a[0]*(1-k/16)+b[0]*k/16,a[1]*(1-k/16)+b[1]*k/16,dy) for k in range(17)]
        G.tube(parent,mat,ps,[.038]*17,8)

def bench(G,parent,i,x,z):
    # The game places the detailed, usable bench on first arrival.
    pass

def terrain_material(i,x,z):
    if i==0:return 'sand' if math.hypot(x+1.4,(z+.2)*1.1)<5.6 else 'grass'
    if i==1:return 'moss' if abs(x)>1.4 else 'slate'
    if i==2:return 'gravel' if abs(x)<6 and abs(z)<7 else 'sand'
    if i==3:return 'grass' if abs(x-3*math.sin(z*.4))<.9 else 'moss'
    if i==4:return 'soil' if abs(x)>1 and abs(x)<6 and abs(z)<6 else 'grass'
    if i==5:return 'soil' if 1.2<abs(x)<5.0 and 1.2<abs(z)<5 else 'paving' if abs(x)<7 and abs(z)<7 else 'grass'
    if i==6:return 'paving' if abs(x)<4.5 and abs(z)<5.5 else 'grass'
    if i==7:return 'slate' if abs(x-1.5*math.sin(z*.4))<1.2 else 'moss'
    if i==8:return 'gravel' if abs(x-2.4*math.sin(z*.45))<.75 else 'mossrock'
    return 'slate' if math.hypot(x+1,z)<3.0 else 'gravel' if abs(x)<6 and abs(z)<6 else 'grass'

def ground(G,root,i):
    p=pivot('Ground',root,ground=True,flat=True)
    for xk in range(96):
        for zk in range(96):
            x=-12+xk*.25;z=-12+zk*.25
            v=[at(i,x,z,-.035),at(i,x+.25,z,-.035),at(i,x+.25,z+.25,-.035),at(i,x,z+.25,-.035)]
            G.poly(p,MATS[terrain_material(i,x+.125,z+.125)],v,[(0,3,2),(0,2,1)])
    # Soil sides occur only on the outer boundary of the connected extension.
    for side in ([-12] if i%2==0 else [12]):
        for k in range(24):
            z=-12+k
            if i==0 and 4<=z<=7:continue
            G.poly(p,MATS['stone'],[(side,-2,z),(side,-2,z+1),at(i,side,z+1),at(i,side,z)],[(0,1,2,3)])

def props_reed(G,root,i):
    solid=pivot('Boardwalk',root,collision=True,flat=True)
    for k in range(34):
        x=-7+k*.42;G.box(solid,MATS['wood'],(x,1.45,5.1),(.39,.12,1.7))
        if k%5==0:G.box(solid,MATS['darkwood'],(x,.79,5.1),(.15,1.4,.15))
    rail(G,solid,i,(-7,5.9),(7,5.9),.85)
    for x,z in [(-6,-3),(-5,3),(3,-4),(4,2)]:rock(G,root,i,x,z,(1.5,.8,1.1),int(x*10+z))
    for k in range(35):
        a=k*2.399;r=4.5+(k%3)*.3;x=-1.4+math.cos(a)*r;z=math.sin(a)*r*.8
        grass(G,root,at(i,x,z),1.05,k)
    jetty=pivot('Sluice wheel',root,at(i,5,-3),collision=True)
    G.box(jetty,MATS['wood'],(0,.35,0),(1.0,.7,.8))
    ps=[(.34*math.cos(j*math.tau/24),1.02+.34*math.sin(j*math.tau/24),-.45) for j in range(25)]
    G.tube(jetty,MATS['iron'],ps,[.025]*25,8)
    for j in range(4):
        a=j*math.pi/4;G.tube(jetty,MATS['iron'],[(-.32*math.cos(a),1.02-.32*math.sin(a),-.45),(.32*math.cos(a),1.02+.32*math.sin(a),-.45)],[.018,.018],8)
    bench(G,root,i,6,3)

def props_fern(G,root,i):
    for k,(x,z) in enumerate([(-5,-5),(-6,0),(-5,5),(5,-6),(6,-1),(5,4),(-2,-7),(3,7)]):
        rock(G,root,i,x,z,(2.5,1.9,2.1),k)
        fern(G,root,at(i,x+.5,z+.5),1.25,k,True)
    for group,x in enumerate([-3.8,0,3.8]):
        canopy=pivot('Canopy%d'%group,root)
        for k in range(3):fern(G,canopy,at(i,x+(k-1)*.9,-4),1.05,k+group*3,True)
    for k in range(28):
        a=k*2.399;r=3+(k%4)*.9;fern(G,root,at(i,math.cos(a)*r,math.sin(a)*r),.45+(k%3)*.12,k)
    log=pivot('Fallen log',root,at(i,-3,2),collision=True)
    G.tube(log,MATS['bark'],[(-1.7,.35,-.4),(0,.34,0),(1.7,.38,.5)],[.27,.30,.22],16)
    for k in range(5):G.ell(log,MATS['moss'],(-1.2+k*.5,.59,.08),(.42,.1,.35),sectors=12,rings=4)
    stones=pivot('Stepping stones',root,collision=True)
    for z in [-6,-4,-2,0,2,4,6]:G.ell(stones,MATS['stone'],at(i,.0,z,.08),(1.0,.15,.8),z,sectors=12,rings=4,rough=.1)
    bench(G,root,i,-5,7)

def props_limestone(G,root,i):
    solid=pivot('Terrace masonry',root,collision=True,flat=True)
    for z in [-5,-.5,4]:
        for k in range(15):
            x=-6+k*.85
            G.box(solid,MATS['stone'],at(i,x,z,-.15),(.82,.4,.40))
            G.box(solid,MATS['cream'],at(i,x,z,.08),(.88,.09,.48))
    steps=pivot('Terrace steps',root,flat=True)
    for k in range(16):
        z=6-k*.76;G.box(steps,MATS['stone'],at(i,6.5,z,.015),(1.5,.14,.70))
    for j,z in enumerate([3.1,-1.4,-5.7]):
        roof=pivot('RainShelter%d'%j,root,at(i,-3,z))
        for x in [-1.1,1.1]:G.box(roof,MATS['iron'],(x,.9,0),(.035,1.8,.035))
        G.box(roof,MATS['glass'],(0,1.78,0),(2.5,.05,1.7))
        for x in [-1.2,0,1.2]:G.box(roof,MATS['iron'],(x,1.8,0),(.035,.04,1.7))
    # Functional bowls and pots are placed by the game on the first visit.
    for k in range(18):
        x=(-1 if k%2 else 1)*(6.5+(k%3)*.8);z=-8+(k//2)*1.8
        rock(G,root,i,x,z,(1.1,.6,1.0),k,False)
        grass(G,root,at(i,x+.4,z),.4,k,'silver')
    bench(G,root,i,2,6.5)

def props_meadow(G,root,i):
    rng=random.Random(413)
    for k in range(95):
        x=rng.uniform(-8,8);z=rng.uniform(-8,8)
        if abs(x-3*math.sin(z*.4))<1.1:continue
        flower(G,root,at(i,x,z),['white','pink','purple','yellow','blue'][k%5],.45+(k%3)*.14,3,k)
        if k%3==0:grass(G,root,at(i,x+.3,z),.85,k,'sage')
    fence=pivot('Meadow fence',root,collision=True)
    rail(G,fence,i,(-8,-8),(8,-8),.82)
    for x,z in [(-6,6),(6,-6),(7,5)]:rock(G,root,i,x,z,(1.4,.65,1),int(x+z),False)
    bench(G,root,i,6,5)

def props_orchard(G,root,i):
    fence=pivot('Orchard fence',root,collision=True)
    for a,b in [((-8,-8),(8,-8)),((-8,-8),(-8,7)),((8,-8),(8,7))]:rail(G,fence,i,a,b,.9)
    training=pivot('Espalier wires',root,collision=True)
    for x in [-6,-3,0,3,6]:G.box(training,MATS['wood'],at(i,x,-6,1.2),(.10,2.4,.1))
    for y in [.7,1.2,1.7,2.2]:G.tube(training,MATS['iron'],[at(i,-6,-6,y),at(i,6,-6,y)],[.007,.007],6)
    for j,(x,z) in enumerate([(-4,4),(4,4),(-4,-1),(4,-1)]):
        for dx in [-.7,.7]:G.box(training,MATS['wood'],at(i,x+dx,z,.6),(.06,1.2,.06))
    table=pivot('Harvest table',root,at(i,0,6),collision=True,flat=True)
    for x in [-.8,.8]:G.box(table,MATS['wood'],(x,.4,0),(.1,.8,.6))
    G.box(table,MATS['wood'],(0,.84,0),(2.1,.09,.85))
    for x in [-.53,.53]:
        for z in [-.25,.25]:G.box(table,MATS['wood'],(x,.99,z),(.92,.22,.04))
        G.box(table,MATS['wood'],(x,.91,0),(.92,.04,.52))
    for k in range(24):flower(G,root,at(i,-6+(k%6)*2.4,-8.2+(k//6)*.4),'white',.23,2,k)
    bench(G,root,i,-6,6)

def props_kitchen(G,root,i):
    solid=pivot('Kitchen walls',root,collision=True,flat=True)
    for x in [-7,7]:
        G.box(solid,MATS['brick'],(x,2.3,0),(.35,2.2,14))
        G.box(solid,MATS['stone'],(x,3.43,0),(.47,.14,14.1))
    G.box(solid,MATS['brick'],(0,2.3,-7),(14,.0+2.2,.35))
    G.box(solid,MATS['stone'],(0,3.43,-7),(14.1,.14,.47))
    for x in [-4.3,4.3]:G.box(solid,MATS['brick'],(x,2.3,7),(5.4,2.2,.35))
    arch=pivot('Entry arch',root,collision=True)
    for x in [-1.6,1.6]:G.box(arch,MATS['stone'],(x,2.32,7),(.30,2.25,.48))
    ps=[(1.6*math.cos(t*math.pi/24),3.42+1.3*math.sin(t*math.pi/24),7) for t in range(25)]
    G.tube(arch,MATS['stone'],ps,[.17]*25,8)
    beds=pivot('Kitchen bed edging',root,collision=True,flat=True)
    for x in [-3.2,3.2]:
        for z in [-3.1,3.1]:
            for dx in [-1.8,1.8]:G.box(beds,MATS['wood'],(x+dx,1.35,z),(.09,.28,3.8))
            for dz in [-1.9,1.9]:G.box(beds,MATS['wood'],(x,1.35,z+dz),(3.7,.28,.09))
    trellis=pivot('Kitchen espalier',root,collision=True)
    for k in range(13):G.box(trellis,MATS['wood'],(-6+k,2.4,-6.65),(.035,2.2,.04))
    for y in [1.6,2.1,2.6,3.1]:G.box(trellis,MATS['wood'],(0,y,-6.65),(12,.035,.04))
    for x in [-6,6]:pot(G,root,at(i,x,5),.38)
    bench(G,root,i,5.5,-5.8)

def props_glasshouse(G,root,i):
    structure=pivot('Glasshouse frame',root,collision=True,flat=True)
    # Walk-through front; frames have honest open doors and a broad aisle.
    for x in [-4.4,4.4]:
        G.box(structure,MATS['stone'],(x,1.55,0),(.22,.7,11))
    G.box(structure,MATS['stone'],(0,1.55,-5.5),(8.8,.7,.22))
    for bay in range(3):
        z=-3.65+bay*3.65
        frame=pivot('BayFrame%d'%bay,root)
        panes=pivot('RestoredBay%d'%bay,root)
        old=pivot('OldBay%d'%bay,root)
        for dz in [-1.78,0,1.78]:
            # Curved Gothic roof ribs.
            ps=[(4.4*math.cos(k*math.pi/24),3.6+2.0*math.sin(k*math.pi/24),z+dz) for k in range(25)]
            G.tube(frame,MATS['iron'],ps,[.048]*25,8)
            for x in [-4.4,4.4]:G.box(frame,MATS['iron'],(x,2.55,z+dz),(.07,2.1,.07))
        for j in range(8):
            a=j*math.pi/8;b=(j+1)*math.pi/8
            for dz in [-.88,.88]:
                pts=[(4.4*math.cos(t),3.6+2*math.sin(t),z+d) for t,d in [(a,dz-.85),(b,dz-.85),(b,dz+.85),(a,dz+.85)]]
                G.poly(panes,MATS['glass'],pts,[(0,3,2,1)])
                if (j+bay)%3!=0:G.poly(old,MATS['glass'],pts,[(0,3,2,1)])
        for x in [-4.4,4.4]:
            for dz in [-1.2,0,1.2]:
                G.box(panes,MATS['glass'],(x,2.7,z+dz),(.025,1.55,1.12))
                if bay%2==0:G.box(old,MATS['glass'],(x,2.7,z+dz),(.025,1.55,1.12))
        shade=pivot('GlassShade%d'%bay,root)
        G.box(shade,MATS['sage'],(0,4.56,z),(6.0,.022,3.4))
        vent=pivot('GlassVent%d'%bay,root,(0,5.5,z))
        G.box(vent,MATS['iron'],(0,.05,0),(1.4,.05,1.1))
    for x in [-4.4,4.4]:
        for y in [1.9,3.6]:G.box(structure,MATS['iron'],(x,y,0),(.06,.06,11))
    for x in [-3.8,3.8]:
        G.box(structure,MATS['wood'],(x,2.08,0),(1.1,.08,8.6))
        for z in [-3,0,3]:G.box(structure,MATS['iron'],(x,1.65,z),(.05,.9,.9))
        for z in [-3.7,-2.1,-.5,1.1,2.7]:pot(G,root,(x,2.12,z),.26)
    for x in [-4.0,4.0]:
        for z in [-3,0,3]:
            G.tube(root,MATS['iron'],[(x,4.3,z),(x,3.7,z)],[.008,.008],6)
            pot(G,root,(x,3.05,z),.18,'zinc')
    bench(G,root,i,0,-4.6)

def props_stream(G,root,i):
    for k in range(24):
        z=-9+k*.8;x=1.5*math.sin(z*.4)
        for side in [-1,1]:rock(G,root,i,x+side*1.15,z,(.8,.45,.65),k*3+side)
    bridge=pivot('Stream bridge',root,flat=True)
    for k in range(17):
        x=-3.2+k*.4;y=1.35+.2*(1-(x/3.6)**2)
        G.box(bridge,MATS['wood'],(x,y,3.0),(.37,.1,1.2))
    railing=pivot('Stream bridge railing',root,collision=True)
    rail(G,railing,i,(-3.2,3.6),(3.2,3.6),.95)
    stones=pivot('Stream stepping stones',root,collision=True)
    for x,z in [(-2,-3),(-1,-3.3),(0,-3.4),(1,-3.3),(2,-3)]:
        G.ell(stones,MATS['stone'],(x,1.28,z),(.8,.18,.62),int(x+6),sectors=12,rings=4,rough=.15)
    for branch,x in enumerate([-3.0,3.0]):
        gate=pivot('StreamGate%d'%branch,root,at(i,x,-.5),collision=True)
        for dx in [-.5,.5]:G.box(gate,MATS['wood'],(dx,.35,0),(.08,.85,.08))
        G.box(gate,MATS['wood'],(0,.20,0),(1.1,.34,.08))
        G.tube(gate,MATS['iron'],[(0,.45,0),(0,1.05,0)],[.025,.025],8)
        G.box(gate,MATS['iron'],(0,1.05,0),(.34,.035,.035))
    for k in range(18):fern(G,root,at(i,-6+(k%2)*12,-8+(k//2)*1.8),.65,k)
    bench(G,root,i,-5,5)

def props_alpine(G,root,i):
    for k in range(32):
        a=k*2.399;r=5+(k%5)*.7;x=math.cos(a)*r;z=-2+math.sin(a)*r
        rock(G,root,i,x,z,(1.7+(k%3)*.4,1.1,1.6),k,False)
        grass(G,root,at(i,x+.55,z),.36,k,'silver')
    for j,(x,z) in enumerate([(-4,-2),(2,-5),(4,1)]):
        shelter=pivot('Windbreak%d'%j,root)
        for k in range(5):rock(G,shelter,i,x-1+k*.5,z,(.68,.72,.58),k+j*5,False)
    lookout=pivot('Lookout railing',root,collision=True)
    rail(G,lookout,i,(-6,-7.5),(2,-8.5),.95)
    bench(G,root,i,-2,-7)
    chime=pivot('Alpine wind chime',root,at(i,-6,-5))
    G.box(chime,MATS['wood'],(0,1.3,0),(.10,2.6,.10))
    G.box(chime,MATS['wood'],(.35,2.55,0),(.75,.09,.09))
    swing=pivot('ChimeSwing',chime,(.35,2.55,0))
    for k in range(5):
        x=-.25+k*.12;G.tube(swing,MATS['iron'],[(x,0,0),(x,-.35,0)],[.008,.008],6)
        G.tube(swing,MATS['metal'],[(x,-.35,0),(x,-.95+(k%3)*.13,0)],[.027,.027],10)

def props_moon(G,root,i):
    rim=pivot('Reflection pool rim',root,collision=True)
    ps=[(-1+3.12*math.cos(k*math.tau/64),1.12,3.12*math.sin(k*math.tau/64)) for k in range(65)]
    G.tube(rim,MATS['cream'],ps,[.18]*65,10)
    pergola=pivot('Moon pergola',root,collision=True,flat=True)
    for x in [-5.9,-3.5]:
        for z in [-4.5,1]:G.box(pergola,MATS['cream'],(x,2.55,z),(.15,2.7,.15))
    for x in [-6,-3.4]:G.box(pergola,MATS['cream'],(x,3.93,-1.75),(.16,.18,6.0))
    for k in range(10):G.box(pergola,MATS['cream'],(-4.7,4.08,-4.8+k*.64),(3.2,.09,.14))
    blooms=pivot('DuskFlowers',root)
    for k in range(28):
        x=(-1 if k%2 else 1)*(3.8+(k%3)*.55);z=-6+(k//2)*.9
        grass(G,root,at(i,x,z),.45,k,'silver');flower(G,blooms,at(i,x+.2,z),'white',.65,3,k)
    for j,(x,z) in enumerate([(-5,5),(5,4),(4,-5)]):
        lamp=pivot('MoonLantern%d'%j,root,at(i,x,z),collision=True)
        G.box(lamp,MATS['stone'],(0,.55,0),(.18,1.1,.18))
        G.box(lamp,MATS['iron'],(0,1.15,0),(.45,.08,.45))
        G.box(lamp,MATS['glass'],(0,1.35,0),(.29,.34,.29))
        G.box(lamp,MATS['iron'],(0,1.57,0),(.47,.07,.47))
        for dx in [-.16,.16]:
            for dz in [-.16,.16]:G.box(lamp,MATS['iron'],(dx,1.37,dz),(.025,.4,.025))
    bench(G,root,i,3.8,6)

def borders(G,root,i):
    rng=random.Random(500+i)
    for k in range(38):
        side=k%4;t=-8.5+(k//4)*1.8
        x,z=[(-9.5,t),(9.5,t),(t,-9.5),(t,9.5)][side]
        x+=rng.uniform(-.35,.35);z+=rng.uniform(-.35,.35)
        if i==1:
            fern(G,root,at(i,x,z),.55+(k%3)*.09,k)
        elif i==2 or i==8:
            grass(G,root,at(i,x,z),.35,k,'silver')
            if k%3==0:rock(G,root,i,x,z,(.6,.38,.55),k,False)
        else:
            grass(G,root,at(i,x,z),.65+(k%3)*.12,k,'sage')
            if k%3==0:flower(G,root,at(i,x+.25,z),'white' if i==9 else ['white','purple','pink'][k%3],.4,2,k)

SPECIALTIES={
 'lily':{'name':'White water lily','days':8,'depth':'deep','color':'white'},
 'hawthorn':{'name':'Water hawthorn','days':9,'depth':'deep','color':'white'},
 'iris':{'name':'Marsh iris','days':7,'depth':'margin','color':'purple'},
 'reed':{'name':'Soft rush','days':6,'depth':'margin','color':'reed'},
 'mint':{'name':'Water mint','days':6,'depth':'bank','color':'pink'},
 'maidenhair':{'name':'Maidenhair fern','days':8,'color':'fern'},
 'birdsnest':{'name':'Bird’s nest fern','days':9,'color':'lime'},
 'treefern':{'name':'Soft tree fern','days':12,'color':'fern'},
 'orchid':{'name':'Moth orchid','days':10,'color':'white'},
 'cymbidium':{'name':'Cymbidium orchid','days':12,'color':'yellow'},
 'hoya':{'name':'Wax flower','days':9,'color':'pink'},
 'edelweiss':{'name':'Edelweiss','days':8,'color':'white'},
 'gentian':{'name':'Alpine gentian','days':9,'color':'blue'},
 'saxifrage':{'name':'Cushion saxifrage','days':8,'color':'pink'},
 'primrose':{'name':'Evening primrose','days':7,'color':'yellow','night':True},
 'nicotiana':{'name':'White flowering tobacco','days':8,'color':'white','night':True},
 'moonflower':{'name':'Moonflower','days':10,'color':'white','night':True},
 'nightphlox':{'name':'Night phlox','days':7,'color':'white','night':True},
}

def specialist(G,root,key,seed=0):
    d=SPECIALTIES[key];leaves=pivot('Leaves',root);blooms=pivot('Flowers',root)
    if key in ['lily','hawthorn']:
        for k in range(5):
            a=k*2.399;r=.15+(k%3)*.12;x=math.cos(a)*r;z=math.sin(a)*r
            if key=='lily':
                vs=[(x,.05,z)]+[(x+math.cos(a+j*math.tau/20)*.22,.05+.012*math.sin(j),z+math.sin(a+j*math.tau/20)*.22) for j in range(2,20)]
                G.poly(leaves,MATS['green'],vs,[(0,j,j+1) for j in range(1,len(vs)-1)])
            else:G.leaf(leaves,MATS['green'],(x,.02,z),(x+.1,.055,z+.34),.09,.005)
        for layer in range(3):
            for k in range(10-layer*2):
                a=k*math.tau/(10-layer*2)+layer*.3
                G.leaf(blooms,MATS['white'],(0,.06,0),(.22*math.cos(a)/(1+layer*.35),.07+layer*.05,.22*math.sin(a)/(1+layer*.35)),.055,.065)
        G.ell(blooms,MATS['yellow'],(0,.14,0),(.08,.08,.08),sectors=12,rings=6)
    elif key=='reed':grass(G,leaves,(0,0,0),1.0,seed)
    elif key in ['maidenhair','treefern']:fern(G,leaves,(0,0,0),.58 if key=='maidenhair' else .85,seed,key=='treefern')
    elif key=='birdsnest':
        for k in range(14):
            a=k*2.399;G.leaf(leaves,MATS['lime'],(0,.04,0),(.44*math.cos(a),.52,.44*math.sin(a)),.12,.15)
    elif key in ['orchid','cymbidium','hoya']:
        for k in range(7):
            a=k*2.399;G.leaf(leaves,MATS['green'],(0,.05,0),(.24*math.cos(a),.20 if key=='orchid' else .7,.24*math.sin(a)),.06)
        G.tube(leaves,MATS['green'],[(0,.02,0),(.03,.5,0),(.14,.85,.05)],[.012,.01,.007],8)
        for j in range(5):
            x=.03+j*.025;y=.42+j*.09;z=.02
            for k in range(5):
                a=k*math.tau/5
                G.ell(blooms,MATS[d['color']],(x+.08*math.cos(a),y+.08*math.sin(a),z),(.12,.08,.04),sectors=10,rings=6)
            G.ell(blooms,MATS['pink'],(x,y-.025,z-.018),(.045,.045,.045),sectors=8,rings=4)
    elif key=='iris':
        for k in range(9):G.leaf(leaves,MATS['sage'],(0,0,0),((k-4)*.045,.6+abs(k-4)*.05,0),.025,.005)
        flower(G,blooms,(0,.30,0),'purple',.6,3,seed)
    elif key in ['edelweiss','gentian','saxifrage']:
        for k in range(16):
            a=k*2.399;G.leaf(leaves,MATS['silver' if key=='edelweiss' else 'sage'],(0,.0,0),(.22*math.cos(a),.06,.22*math.sin(a)),.032,.015)
        flower(G,blooms,(0,0,0),d['color'],.18 if key!='gentian' else .26,7,seed)
    else:
        flower(G,blooms,(0,0,0),d['color'],.75 if key!='nightphlox' else .35,6,seed)
        for k in range(8):
            a=k*2.399;G.leaf(leaves,MATS['sage'],(0,.03,0),(.33*math.cos(a),.23,.33*math.sin(a)),.07)

def layout():
    areas=[]
    for i,kind in enumerate(KINDS):
        c=[56+(i%2)*24,-(i//2)*24]
        slots=[]
        if i==0:
            for key,depth,points in [('lily','deep',[[-2,0],[-.3,0],[-2,-1.8]]),('iris','margin',[[1.5,-2.4],[1.8,1.1],[-3.8,1.6]]),('mint','bank',[[-4.7,-3.4],[3.1,3.1]])]:
                for x,z in points:slots.append({'pos':[x,z],'depth':depth,'default':key})
        elif i==1:
            for x,z,key in [(-3,0,'maidenhair'),(0,-2,'birdsnest'),(3,1,'treefern'),(-2,4,'maidenhair'),(3,-3,'birdsnest')]:slots.append({'pos':[x,z],'default':key})
        elif i==6:
            for bay,z in enumerate([-3.6,0,3.6]):
                for x in [-3.8,3.8]:slots.append({'pos':[x,z],'elevation':1.41,'bay':bay,'default':['orchid','cymbidium','hoya'][bay]})
        elif i==8:
            for x,z,key in [(-4,-1,'edelweiss'),(2,-4,'gentian'),(4,2,'saxifrage'),(-2,3,'edelweiss'),(0,-6,'gentian'),(4,-3,'saxifrage')]:slots.append({'pos':[x,z],'default':key})
        elif i==9:
            for x,z,key in [(-5,3,'moonflower'),(4,0,'nicotiana'),(4,-2,'primrose'),(-4,4,'nightphlox'),(3,3,'nicotiana'),(5,-4,'nightphlox')]:slots.append({'pos':[x,z],'default':key})
        areas.append({'kind':kind,'name':NAMES[i],'description':DESCRIPTIONS[i],'condition':CONDITIONS[i],
          'center':c,'seeds':SEEDS[i],'slots':slots,'heightmap':[[height(i,x,z) for x in range(-12,13)] for z in range(-12,13)],
          'camera':[9,9,12] if i!=8 else [10,12,12],'focus':[0,2,-1] if i!=6 else [0,3,0]})
    path=ROOT/'assets/areas/layout.json';path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps({'version':1,'areas':areas,'specialties':SPECIALTIES},indent=2)+'\n')
    return areas

BUILDERS=[props_reed,props_fern,props_limestone,props_meadow,props_orchard,props_kitchen,props_glasshouse,props_stream,props_alpine,props_moon]

def build_one(index):
    previous=bpy.context.window.scene;selected=list(bpy.context.selected_objects);active=bpy.context.view_layer.objects.active
    if bpy.context.mode!='OBJECT':raise RuntimeError('Switch to Object mode before authoring habitats')
    info=layout()[index];materials()
    s=hq.scene('Area_'+info['kind'])
    for old in [o for o in s.objects if o.parent is None and o.get('area_kind')==info['kind']]:
        for child in list(old.children_recursive)+[old]:bpy.data.objects.remove(child,do_unlink=True)
    root=pivot('Area_'+info['kind'],None)
    root['area_kind']=info['kind'];root['metre_scale']=True
    G=Geometry();ground(G,root,index);BUILDERS[index](G,root,index);borders(G,root,index);G.flush()
    record=hq.export(root,'areas',info['kind'])
    path=hq.save('Area_'+info['kind'])
    bpy.context.window.scene=previous
    bpy.ops.object.select_all(action='DESELECT')
    for o in selected:
        if o.name in previous.objects:o.select_set(True)
    if active and active.name in previous.objects:bpy.context.view_layer.objects.active=active
    return {'asset':record,'source':path}

def build_specialties():
    previous=bpy.context.window.scene
    s=hq.scene('Area_Collections');materials();records=[]
    for old in [o for o in s.objects if o.parent is None and str(o.get('export_path','')).startswith('assets/areas/plants/')]:
        for child in list(old.children_recursive)+[old]:bpy.data.objects.remove(child,do_unlink=True)
    for index,key in enumerate(SPECIALTIES):
        root=pivot('Collection_'+key,None);G=Geometry();specialist(G,root,key,index);G.flush()
        records.append(hq.export(root,'areas/plants',key))
    path=hq.save('Area_Collections');bpy.context.window.scene=previous
    return {'plants':records,'source':path}

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
    if args and args[0]=='plants':print(json.dumps(build_specialties()))
    else:
        for i in ([int(args[0])] if args else range(10)):print(json.dumps(build_one(i)))
