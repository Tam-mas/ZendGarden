"""Second construction pass: fitted paths, honest structures and planted pockets."""
import bpy, math, random
from pathlib import Path
from mathutils import Vector
import numpy as np

def install(b):
 old_height=b.height;old_material=b.terrain_material;old_rock=b.rock
 reservations=[];rocks=[]
 def creek(z):return 1.0*math.sin(z*.42)+.30*math.sin(z*.83)
 def height(i,x,z):
  if i!=1:return old_height(i,x,z)
  edge=1-b.smooth(9,12,max(abs(x),abs(z)));d=abs(x-creek(z))
  land=.68+.008*z+1.58*b.smooth(.65,7.6,d)+.09*math.sin(z*.62)*b.smooth(1.3,4.5,d)
  return round(1.2+(land-1.2)*edge,5)
 b.height=height
 def terrain_material(i,x,z):
  if i==1:return 'sand' if abs(x-creek(z))<.78 else 'moss'
  if i==3:return 'moss'
  if i==8:return 'moss' if abs(x)<8 and abs(z)<8 else 'mossrock'
  if i==4:
   edge=5.7+.18*math.sin(z*1.7)+.1*math.sin(z*3.2)
   return 'soil' if 1.45+.12*math.sin(z*.7)<abs(x)<edge and abs(z)<5.8+.15*math.sin(x*2) else 'grass'
  if i==5:return 'soil' if 1.4<abs(x)<4.95 and 1.23<abs(z)<4.96 else old_material(i,x,z)
  return old_material(i,x,z)
 b.terrain_material=terrain_material
 # Keep exact shape reservations in source and glTF for placement auditing.
 def rock(G,parent,i,x,z,size,seed=0,moss=True):
  rx=size[0]*.55+.20;rz=size[2]*.55+.20
  if i==2 and abs(x-6.5)<rx+.82 and -6.5<z<6.6:return
  if i==8 and abs(x-2.4*math.sin(z*.45))<rx+.85 and -9.5<z<9.5:return
  if i==1 and (abs(x-creek(z))<rx+.60 or abs(x-creek(z)-1.55)<rx+.62):return
  if any(((x-px)/max(.3,rx+rr))**2+((z-pz)/max(.3,rz+rr))**2<1 for px,pz,rr in reservations):return
  node=b.pivot('Boulder',parent,collision=True,footprint=[x,z,rx,rz]);rocks.append((x,z,rx,rz))
  old_rock(G,node,i,x,z,size,seed,moss)
 b.rock=rock
 def clear(x,z,r=.13):return not any(((x-rx)/(rw+r))**2+((z-rz)/(rd+r))**2<1 for rx,rz,rw,rd in rocks)
 def flora(parent,pos,key=None,id=None,size=1,seed=0):
  # Geometry rooted in a stone cannot be disguised by leaves; move the root.
  x,y,z=pos
  for attempt in range(18):
   if clear(x,z,.15 if key!='treefern' else .28):break
   a=seed*2.399+attempt*2.399;d=.18*(attempt+1);x=pos[0]+math.cos(a)*d;z=pos[2]+math.sin(a)*d
   y=height(current[0],x,z)+.07
  else:return
  ob=b.pivot('BotanicalAnchor',parent,(x,y,z),area_species=key or '',area_plant_id=id if id is not None else -1,terrain_anchor=True)
  ob.scale=(size,size,size);ob.rotation_euler.z=seed*2.399
  if key=='treefern':ob['trunk_radius']=.17*size
  reservations.append((x,z,.16))
 def fern(G,parent,pos,size=1,seed=0,tree=False):flora(parent,pos,'treefern' if tree else 'maidenhair',size=size,seed=seed)
 def grass(G,parent,pos,size=1,seed=0,color='reed'):
  flora(parent,pos,'reed' if color=='reed' else None,id=None if color=='reed' else (144 if color=='silver' else 13),size=size*.65,seed=seed)
 def flower(G,parent,pos,color='white',height=.6,count=5,seed=0):
  if parent.name.startswith('DuskFlowers'):flora(parent,pos,'nightphlox',size=height/.38,seed=seed)
  else:flora(parent,pos,id={'white':0,'pink':65,'purple':1,'yellow':36,'blue':37}.get(color,0),size=height/.8,seed=seed)
 b.fern=fern;b.grass=grass;b.flower=flower
 original_rail=b.rail
 def rail(G,parent,i,a,b_,height_=1.0,wood=True):
  if not parent.name.startswith('Boardwalk'):return original_rail(G,parent,i,a,b_,height_,wood)
  for j in range(12):
   x=-7+j*14/11;G.box(parent,b.MATS['wood'],(x,1.51+height_*.5,5.9),(.09,height_,.09))
  for dy in [.4,height_]:G.tube(parent,b.MATS['wood'],[(-7,1.51+dy,5.9),(7,1.51+dy,5.9)],[.038,.038],8)
 b.rail=rail

 current=[0]
 old_ground=b.ground
 def ground(G,root,i):
  current[0]=i;rocks.clear();reservations.clear()
  reservations.extend((s['pos'][0],s['pos'][1],.40) for s in b.layout()[i]['slots'])
  if i==2:reservations.extend((x,z,.55) for x,z in [(-4.5,6),(4.1,-6.8),(3.3,1.5),(-4.4,-2.8)])
  old_ground(G,root,i)
  # The cohesion pass fits the inner and entrance paths as one paving network.
  # Independent ribbons here would double the flags at every intersection.
 b.ground=ground
 def fern_props(G,root,i):
  rocks.append((-3.3,2.23,1.98,.60))
  for k,(x,z) in enumerate([(-5,-5),(-6,0),(-5,5),(5,-6),(6,-1),(5,4),(-2,-7),(3,7)]):
   rock(G,root,i,x,z,(2.5,1.9,2.1),k)
   fern(G,root,b.at(i,x+(-1.8 if x<0 else 1.8),z+.8),1.05,k,True)
  for group,x in enumerate([-3.8,0,3.8]):
   canopy=b.pivot('Canopy%d'%group,root)
   for k in range(2):fern(G,canopy,b.at(i,x+(k-.5)*1.5,-5.2 if group!=1 else -8),.82,k+group*3,True)
  for k in range(38):
   a=k*2.399;r=2.7+(k%5)*.85;x=math.cos(a)*r;z=math.sin(a)*r
   if abs(x-creek(z))<1.0 or abs(x-creek(z)-1.55)<.65:continue
   fern(G,root,b.at(i,x,z),.65+(k%3)*.14,k)
  log=b.pivot('Fallen log',root,b.at(i,-3.3,2.1),collision=True,footprint=[-3.3,2.23,1.98,.60])
  # Tapered bark with its own cylindrical UVs, scarred broken end and branches.
  bark=b.MATS['bark'];n=36;rows=18;vs=[];fs=[]
  for k in range(rows+1):
   t=k/rows;radius=.32-.055*t+.018*math.sin(t*17)
   for j in range(n+1):
    a=j*math.tau/n;rr=radius*(1+.05*math.sin(a*9+t*12)+.025*math.sin(a*17))
    vs.append((-1.65+3.3*t,.33+math.cos(a)*rr,.25*t+math.sin(a)*rr))
  for k in range(rows):
   for j in range(n):q=k*(n+1)+j;fs.append((q,q+1,q+n+2,q+n+1))
  G.poly(log,bark,vs,fs)
  for end in [0,1]:
   x=-1.65+3.3*end;r=.32-.055*end
   G.ell(log,b.MATS['endgrain'],(x,.33,.25*end),(.025,r*1.95,r*1.95),4+end,sectors=32,rings=8,rough=.1)
   for j in range(5):
    a=j*2.4;G.tube(log,b.MATS['darkwood'],[(x,.33,.25*end),(x,.33+math.cos(a)*r*.78,.25*end+math.sin(a)*r*.78)],[.004,.001],4)
  for j in range(3):
   x=-1+j*.82;G.tube(log,bark,[(x,.53,.18),(x+.15,.70,.35),(x+.24,.72,.47)],[.08,.06,.035],12)
  for j in range(22):
   x=-1.5+j*.14;z=.06*math.sin(j*2);G.ell(log,b.MATS['moss'],(x,.60+.015*math.sin(j),z),(.21,.025,.17),j,sectors=10,rings=4,rough=.25)
  stones=b.pivot('Stepping stones',root,collision=True)
  for j,z in enumerate([-6,-4,-2,0,2,4,6]):
   G.ell(stones,b.MATS['stone'],(creek(z),.97+.008*z,z),(.85,.18,.68),j,sectors=18,rings=6,rough=.16)
 b.BUILDERS[1]=fern_props
 old_stream=b.props_stream
 def stream(G,root,i):
  old_stream(G,root,i)
  # Replace the old terrain-based rail, which dipped into the channel.
  for parent in list(G.groups):
   if parent[0].name.startswith('Stream bridge railing'):del G.groups[parent]
  railing=b.pivot('Stream bridge railing fitted',root,collision=True,flat=True)
  deck=lambda x:1.40+.2*(1-(x/3.6)**2)
  for z in [2.36,3.64]:
   for k in range(7):
    x=-3.2+k*(6.4/6);y=deck(x)
    G.box(railing,b.MATS['wood'],(x,y+.49,z),(.095,.98,.095))
    G.ell(railing,b.MATS['iron'],(x,y+.71,z-.053),(.025,.025,.013),sectors=8,rings=4)
   for dy in [.42,.96]:
    pts=[(-3.2+k*.2,deck(-3.2+k*.2)+dy,z) for k in range(33)]
    G.tube(railing,b.MATS['wood'],pts,[.037]*33,8)
   pts=[(-3.4+k*.2,deck(-3.4+k*.2)-.18,z) for k in range(35)]
   G.tube(railing,b.MATS['darkwood'],pts,[.08]*35,8)
 b.BUILDERS[7]=stream
 old_orchard=b.props_orchard
 def orchard(G,root,i):
  old_orchard(G,root,i)
  for key in list(G.groups):
   if key[0].name.startswith('Harvest table'):del G.groups[key]
  table=b.pivot('Harvest table refined',root,b.at(i,0,6),collision=True,flat=True)
  for x in [-.85,.85]:
   for z in [-.32,.32]:G.box(table,b.MATS['wood'],(x,.42,z),(.075,.84,.075))
   G.box(table,b.MATS['darkwood'],(x,.76,0),(.07,.08,.83))
  for j in range(6):G.box(table,b.MATS['wood'],(0,.86,-.375+j*.15),(2.1,.075,.13))
  for cx in [-.55,.55]:
   for j in range(5):G.box(table,b.MATS['wood'],(cx,.93,-.23+j*.115),(.88,.03,.095))
   for y in [1.00,1.075,1.15]:
    for z in [-.30,.30]:G.box(table,b.MATS['wood'],(cx,y,z),(.9,.055,.028))
    for dx in [-.45,.45]:G.box(table,b.MATS['wood'],(cx+dx,y,0),(.025,.055,.60))
   for dx in [-.41,.41]:
    for z in [-.26,.26]:G.box(table,b.MATS['darkwood'],(cx+dx,1.06,z),(.038,.27,.038))
 b.BUILDERS[4]=orchard
 old_glass=b.props_glasshouse
 def glass(G,root,i):
  old_glass(G,root,i)
  # Pot positions and collection roots share these exact six bay coordinates.
  # Remove only generic pots, keeping frame, glazing and baskets separate.
  for key in list(G.groups):
   parent,mat=key
   if parent==root and mat in [b.MATS['clay'],b.MATS['soil']]:del G.groups[key]
   if parent.name.startswith('GlassShade'):del G.groups[key]
  for x in [-3.8,3.8]:
   for z in [-3.6,0,3.6]:b.pot(G,root,(x,2.12,z),.31)
  for bay,z in enumerate([-3.65,0,3.65]):
   shade=b.pivot('GlassShade%d'%bay,root,flat=True)
   # Open woven mesh: real holes pass direct sun and give dappled shadows.
   for j in range(120):
    x=-3+j*.05;G.poly(shade,b.MATS['shadecloth'],[(x,4.56,z-1.7),(x+.021,4.56,z-1.7),(x+.021,4.56,z+1.7),(x,4.56,z+1.7)],[(0,1,2,3)])
   for j in range(68):
    zz=z-1.7+j*.05;G.poly(shade,b.MATS['shadecloth'],[(-3,4.565,zz),(3,4.565,zz),(3,4.565,zz+.021),(-3,4.565,zz+.021)],[(0,1,2,3)])
 b.BUILDERS[6]=glass
 old_mats=b.materials
 def materials():
  if b.MATS.get('refined'):return b.MATS
  old_mats();b.MATS['refined']=True
  m=b.hq.material('Area weathered bark',(1,1,1),None,rough=.93)
  im=bpy.data.images.load(str(b.ROOT/'art_source/areas/textures/weathered-bark.png'),check_existing=True);im.pack()
  tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
  # Derive a microrelief normal map; colour asset remains the ImageGen original.
  w,h=im.size;pixels=np.array(im.pixels[:]).reshape((h,w,4));field=pixels[:,:,:3].mean(2);dy,dx=np.gradient(field)
  normal=np.stack((-dx*1.8,-dy*1.8,np.ones_like(field)),2);normal/=np.linalg.norm(normal,axis=2)[:,:,None]
  ni=b.hq.texture('Area weathered bark normal',np.concatenate((normal*.5+.5,np.ones((h,w,1))),2),True)
  nt=m.node_tree.nodes.new('ShaderNodeTexImage');nt.image=ni;nm=m.node_tree.nodes.new('ShaderNodeNormalMap');m.node_tree.links.new(nt.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],m.node_tree.nodes['Principled BSDF'].inputs['Normal'])
  b.MATS['bark']=m;b.MATS['endgrain']=b.hq.material('Area log endgrain',(.27,.18,.10),'endgrain',size=512)
  b.MATS['shadecloth']=b.hq.material('Area woven shadecloth',(.11,.15,.095),None,rough=.95);b.MATS['shadecloth'].use_backface_culling=False
  return b.MATS
 b.materials=materials
