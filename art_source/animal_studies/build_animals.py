"""Sequential STL species authoring, PBR WebP maps and species-specific rigs.

Run in background Blender; preserve interactive authoring and production assets.
"""
import bpy,math,json,sys,subprocess,hashlib
import numpy as np
from pathlib import Path
from mathutils import Vector,Matrix,Quaternion
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT))
from species import SPECIES
PYTHON='/Users/tam/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3'
KIND=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'fox'
C=SPECIES[KIND];FOLDER=ROOT/KIND
(FOLDER/'textures').mkdir(exist_ok=True);(FOLDER/'export').mkdir(exist_ok=True)
CONVERSIONS=[]

def select(ob):
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob

def sm(a,b,v):
 t=np.clip((v-a)/(b-a),0,1);return t*t*(3-2*t)

def scalar(a,b,v):return float(sm(a,b,v))

def material(name,color,rough=.75):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=(*color,1)
 bs.inputs['Roughness'].default_value=rough;bs.inputs['Specular IOR Level'].default_value=.22
 return m

def webp(im,lossless=False):
 png=FOLDER/'textures'/(im.name+'.png');target=png.with_suffix('.webp')
 im.filepath_raw=str(png);im.file_format='PNG';im.save()
 data=json.loads(subprocess.check_output([PYTHON,str(ROOT/'convert_map.py'),str(png),str(target),'lossless' if lossless else 'colour'],text=True))
 data['file']=target.name;CONVERSIONS.append(data)
 converted=bpy.data.images.load(str(target),check_existing=False)
 converted.name=im.name+'_WebP';converted.colorspace_settings.name=im.colorspace_settings.name;converted.pack()
 png.unlink();return converted

fur=bpy.data.images.load(str(ROOT/'textures/neutral-short-fur.webp'),check_existing=False)
fur.scale(512,512)
fur_data=np.empty(512*512*4,np.float32);fur.pixels.foreach_get(fur_data);fur_data=fur_data.reshape((512,512,4))
micro=fur_data[:,:,:3].mean(axis=2);micro/=max(1e-6,float(micro.mean()))

def pigment(points,normals=None):
 x,y,z=points.T
 sample=micro[(np.floor((z+y*.35)*12000).astype(int)%512),(np.floor(x*15000).astype(int)%512)]
 variation=np.clip(.77+.23*sample,.82,1.18)
 rgb=np.tile(np.array(C['coat']),(len(points),1))*variation[:,None]
 if KIND=='fox':
  pale=sm(.39,.32,z)*sm(-.16,-.25,y)*.92
  belly=sm(.26,.17,z)*sm(-.27,-.12,y)*sm(.060,.027,np.abs(x))
  tip=sm(.26,.35,y)
  white=np.maximum.reduce([pale,belly,tip])
  rgb=rgb*(1-white[:,None])+np.array([.48,.43,.34])*white[:,None]*variation[:,None]
  boots=sm(.155,.08,z)*(1-sm(.16,.25,y))
  rgb=rgb*(1-boots[:,None])+np.array([.018,.013,.010])*boots[:,None]*variation[:,None]
  dark_back=sm(.30,.39,z)*sm(-.2,.04,y)*(1-sm(.14,.25,y))
  rgb*=1-.22*dark_back[:,None]
 elif KIND=='dog':
  feather=sm(.23,.17,z)*(1-sm(.2,.32,y))*.6
  rgb=rgb*(1-feather[:,None])+np.array([.63,.48,.24])*feather[:,None]*variation[:,None]
  ear=np.exp(-((np.abs(x)-.075)/.028)**2)*sm(.35,.42,z)*sm(-.20,-.28,y)
  rgb*=1-.20*ear[:,None]
  # Paint the existing open mouth/teeth, respecting its sculpted surfaces.
  mouth=np.exp(-(((x+.06)/.10)**4))*sm(-.305,-.335,y)*sm(.489,.466,z)*sm(.433,.450,z)
  teeth=mouth*sm(.462,.475,z)
  rgb=rgb*(1-mouth[:,None])+np.array([.075,.026,.023])*mouth[:,None]
  rgb=rgb*(1-teeth[:,None])+np.array([.64,.60,.48])*teeth[:,None]
 elif KIND=='rabbit':
  mottled=.88+.12*np.sin(x*300+np.sin(y*97))*.5+.08*np.sin(z*280+y*147)
  rgb*=mottled[:,None]
  belly=sm(.145,.07,z)*.82;chin=np.exp(-((y+.19)/.036)**2-((z-.177)/.026)**2)
  tail=sm(.13,.177,y)
  white=np.maximum.reduce([belly,chin,tail])
  rgb=rgb*(1-white[:,None])+np.array([.60,.57,.52])*white[:,None]*variation[:,None]
  inside=sm(.254,.29,z)*sm(.022,.010,np.abs(np.abs(x)-.036))
  if normals is not None:inside*=sm(.1,-.4,normals[:,1])
  rgb=rgb*(1-inside[:,None])+np.array([.32,.18,.16])*inside[:,None]
 else:
  # Radial bands vary along the actual spine geometry; face/legs remain dark.
  radius=np.sqrt((x/.100)**2+((y-.030)/.155)**2+((z-.107)/.107)**2)
  spines=sm(.10,.145,z)*sm(-.11,-.045,y)
  middle=sm(.95,1.15,radius)*(1-sm(1.46,1.68,radius))
  gold=np.array([.49,.37,.20]);dark=np.array([.055,.043,.031])
  spinecol=dark[None,:]*(1-middle[:,None])+gold[None,:]*middle[:,None]
  rgb=rgb*(1-spines[:,None])+spinecol*spines[:,None]*variation[:,None]
 p=np.array(C['nose']);size=np.array(C['nose_size'])
 nose=np.exp(-np.sum(((points-p)/size)**4,axis=1))
 color=np.array([.24,.13,.12]) if KIND=='rabbit' else np.array([.009,.008,.007])
 rgb=rgb*(1-nose[:,None])+color*nose[:,None]
 return np.column_stack((np.clip(rgb,0,1),np.ones(len(rgb)))).astype(np.float32)

scene=next(s for s in bpy.data.scenes if s.name.startswith('Zend STL intake'))
bpy.context.window.scene=scene;scene.name='Zend STL — '+KIND
scene.render.fps=30
skin=scene.objects['Sculpt'];skin.name='Coat'
transform=Matrix(json.loads((FOLDER/'inspection.json').read_text())['transform'])
flip=Matrix.Rotation(math.pi if C['flip'] else 0,4,'Z');skin.data.transform(flip)
with bpy.data.libraries.load(str(FOLDER/'intake.blend'),link=False) as (src,dst):
 dst.objects=[n for n in src.objects if n.endswith('_source')]
high=dst.objects[0];high.name='SOURCE — '+KIND+' original sculpt'
reference=bpy.data.collections.new('REFERENCE — preserved source sculpt');scene.collection.children.link(reference);reference.objects.link(high)
high.data.transform(flip@transform)
for p in high.data.polygons:p.use_smooth=True
select(skin);dec=skin.modifiers.new('Export triangle budget','DECIMATE');dec.ratio=C['triangles']/len(skin.data.polygons)
bpy.ops.object.modifier_apply(modifier=dec.name)
skin.data.validate(verbose=False,clean_customdata=True);skin.data.update()
if KIND in ['dog','fox']:
 group=skin.vertex_groups.new(name='Soften printed fur')
 for v in skin.data.vertices:
  if v.co.y>C['head_y'][0] or v.co.z<C['head_z'][0]:group.add([v.index],1,'REPLACE')
 mod=skin.modifiers.new('Subtle ridge relaxation','SMOOTH');mod.factor=.50;mod.iterations=22;mod.vertex_group=group.name
 bpy.ops.object.modifier_apply(modifier=mod.name);skin.vertex_groups.remove(skin.vertex_groups['Soften printed fur'])
if KIND!='echidna':
 select(skin);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
 bpy.ops.uv.smart_project(angle_limit=math.radians(70),island_margin=.005,area_weight=.5)
 bpy.ops.object.mode_set(mode='OBJECT')
else:skin.data.uv_layers.new(name='Spine colour atlas')
bpy.context.view_layer.update()
points=np.array([tuple(v.co) for v in skin.data.vertices]);normals=np.array([tuple(v.normal) for v in skin.data.vertices])
attribute=skin.data.color_attributes.new(name='Species pigment',type='FLOAT_COLOR',domain='POINT')
attribute.data.foreach_set('color',pigment(points,normals).ravel())
coat=material(KIND+' UV coat',C['coat'],C['rough']);skin.data.materials.clear();skin.data.materials.append(coat)
nodes=coat.node_tree.nodes;links=coat.node_tree.links;bs=nodes['Principled BSDF'];output=nodes['Material Output']
bs.inputs['Sheen Weight'].default_value=.10 if KIND!='echidna' else .025
vc=nodes.new('ShaderNodeVertexColor');vc.layer_name=attribute.name
em=nodes.new('ShaderNodeEmission');links.new(vc.outputs['Color'],em.inputs['Color']);links.new(em.outputs[0],output.inputs['Surface'])
def bake_image(name,noncolor=False):
 im=bpy.data.images.new(KIND+'_'+name,2048,2048,alpha=False)
 if noncolor:im.colorspace_settings.name='Non-Color'
 node=nodes.new('ShaderNodeTexImage');node.image=im;nodes.active=node;return im,node
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8
albedo,albedo_node=bake_image('albedo')
select(skin);high.hide_set(True);scene.render.bake.use_selected_to_active=False;scene.render.bake.margin=12
if KIND!='echidna':bpy.ops.object.bake(type='EMIT')
else:
 # Thousands of narrow spines defeat automatic island packing. Give every
 # triangle its own padded atlas tile, with interpolated anatomical pigment.
 pixels=np.ones((2048,2048,4),np.float32);colors=pigment(points,normals)
 grid=np.indices((8,8)).transpose((1,2,0));uv=skin.data.uv_layers.active
 assert len(skin.data.polygons)<=256*256
 for face in skin.data.polygons:
  tx=(face.index%256)*8;ty=(face.index//256)*8;cols=colors[list(face.vertices),:3]
  u=(grid[:,:,1]-2)/4;v=(grid[:,:,0]-2)/4
  values=cols[0]+u[:,:,None]*(cols[1]-cols[0])+v[:,:,None]*(cols[2]-cols[0])
  pixels[ty:ty+8,tx:tx+8,:3]=np.clip(values,cols.min(axis=0),cols.max(axis=0))
  for li,corner in zip(face.loop_indices,[(2,2),(6,2),(2,6)]):uv.data[li].uv=((tx+corner[0]+.5)/2048,(ty+corner[1]+.5)/2048)
 albedo.pixels.foreach_set(pixels.ravel())
# Add the generated fine fibres at texture resolution, rather than just vertices.
pixels=np.empty(2048*2048*4,np.float32);albedo.pixels.foreach_get(pixels);pixels=pixels.reshape((2048,2048,4))
tile=(np.arange(2048)*7)%512;detail=micro[tile[:,None],tile[None,:]]
pixels[:,:,:3]*=np.clip(.65+.35*detail,.72,1.20)[:,:,None]
albedo.pixels.foreach_set(pixels.astype(np.float32).ravel());albedo_node.image=webp(albedo)
links.new(bs.outputs[0],output.inputs['Surface']);links.new(albedo_node.outputs['Color'],bs.inputs['Base Color'])
normal,normal_node=bake_image('normal',True)
high.hide_set(False);high.select_set(True);scene.render.bake.use_selected_to_active=True
scene.render.bake.cage_extrusion=.004;scene.render.bake.max_ray_distance=.01;scene.render.bake.normal_space='TANGENT'
if KIND!='echidna':bpy.ops.object.bake(type='NORMAL')
else:
 # The preserved spine geometry supplies its silhouette/relief directly.
 # A flat map avoids rays striking neighbouring spines and making black facets.
 normal.scale(64,64);flat=np.tile(np.array([.5,.5,1,1],np.float32),(64*64,1));normal.pixels.foreach_set(flat.ravel())
normal_node.image=webp(normal,True)
nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.18 if KIND!='rabbit' else .40
links.new(normal_node.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs[0],bs.inputs['Normal'])
high.hide_set(True);high.hide_render=True;reference.hide_render=True
bpy.data.images.remove(albedo);bpy.data.images.remove(normal);bpy.data.images.remove(fur)
print('ANIMAL_MAPS: '+KIND+' '+json.dumps(CONVERSIONS),flush=True)

bvh=BVHTree.FromPolygons([v.co.copy() for v in skin.data.vertices],[list(p.vertices) for p in skin.data.polygons])
eye_sites=[]
for i,guess in enumerate(C['eyes']):
 # A side ray fits the socket even when the sculpt's face is asymmetric.
 side=-1 if i==0 else 1
 pos,normal,_,_=bvh.ray_cast(Vector((side*2,guess[1],guess[2])),Vector((-side,0,0)))
 if pos is None:pos,normal,_,_=bvh.find_nearest(Vector(guess))
 expected=Vector((side,-.6,.12)).normalized()
 if normal.dot(expected)<.35:normal=expected
 eye_sites.append((pos,normal))

# Anatomy seeds follow this model rather than a universal symmetric cat rig.
skeleton=bpy.data.armatures.new(KIND+' skeleton');rig=bpy.data.objects.new('AnimalRig',skeleton);scene.collection.objects.link(rig)
rig.show_in_front=True;select(rig);bpy.ops.object.mode_set(mode='EDIT');defs={}
def bone(name,a,b,parent=None):
 ob=skeleton.edit_bones.new(name);ob.head=a;ob.tail=b
 if parent:ob.parent=skeleton.edit_bones[parent]
 defs[name]=(Vector(a),Vector(b));return ob
bone('Root',(0,0,C['height']*.16),(0,0,C['height']*.24))
pelvis=Vector(C['pelvis']);chest=Vector(C['chest']);middle=(pelvis+chest)/2
bone('Pelvis',pelvis,middle,'Root');bone('Spine',middle,chest,'Pelvis');bone('Chest',chest,C['neck'],'Spine');bone('Head',C['neck'],C['head'],'Chest')
for i,(a,b) in enumerate(zip(C['ears'],C['ear_tips'])):bone('Ear'+('L' if i==0 else 'R'),a,b,'Head')
for i in range(len(C['tail'])-1):bone('Tail'+str(i+1),C['tail'][i],C['tail'][i+1],'Pelvis' if i==0 else 'Tail'+str(i))
for i,(p,_) in enumerate(eye_sites):
 head=p+Vector((0,0,C['eye_size']*.9));bone('Lid'+('L' if i==0 else 'R'),head,head+Vector((0,0,.003)),'Head')
legs={}
for front in [True,False]:
 for side in [-1,1]:
  name=('Front' if front else 'Back')+('L' if side<0 else 'R')
  subset=points[(points[:,2]>=-.002)&(points[:,2]<C['ankle']+.008)&(points[:,0]*side>.012)&((points[:,1]<C['front_cut']) if front else ((points[:,1]>C['back_cut'])&(points[:,1]<C['pelvis'][1]+.12)))]
  assert len(subset)>20,(KIND,name,'no paw sample')
  paw=np.median(subset,axis=0);paw[2]=C['ankle']
  body=chest if front else pelvis
  top=Vector((paw[0]*.86,body.y,body.z*.91))
  knee=(top+Vector(paw))*.5;knee.y+=.015 if front else -.022
  names=[name+'_Upper',name+'_Lower',name+'_Paw']
  bone(names[0],top,knee,'Chest' if front else 'Pelvis');bone(names[1],knee,paw,names[0])
  bone(names[2],paw,(paw[0],paw[1]-.023,max(.002,paw[2]-.012)),names[1])
  legs[name]={'paw':Vector(paw),'bones':names,'front':front}
bpy.ops.object.mode_set(mode='OBJECT')
def distance(p,a,b):
 d=b-a;t=max(0,min(1,(p-a).dot(d)/d.length_squared));return (p-a-t*d).length
groups={n:skin.vertex_groups.new(name=n) for n in defs}
for v in skin.data.vertices:
 p=v.co;x,y,z=p
 w={'Chest':scalar(middle.y,chest.y,y),'Pelvis':scalar(middle.y,pelvis.y,y)};w['Spine']=max(.12,1-sum(w.values()))
 total=sum(w.values());w={k:a/total for k,a in w.items()}
 head=scalar(*C['head_y'],y)*scalar(*C['head_z'],z)
 w={k:a*(1-head) for k,a in w.items()};w['Head']=head
 for i,(a,b) in enumerate(zip(C['ears'],C['ear_tips'])):
  e=scalar(a[2]-.01,a[2]+.035,z)*math.exp(-((x-a[0])/.035)**4)
  if KIND=='dog':e=math.exp(-((x-a[0])/.035)**4)*scalar(-.19,-.23,y)*scalar(.39,.45,z)*.90
  w={k:q*(1-e) for k,q in w.items()};w['Ear'+('L' if i==0 else 'R')]=e
 tail=0
 if C['tail']:
  tail=scalar(C['tail'][0][1]+.015,C['tail'][0][1]+.070,y)
  names=['Tail'+str(i+1) for i in range(len(C['tail'])-1)]
  if KIND=='rabbit':tail*=math.exp(-((z-.10)/.05)**4)
  else:
   tail*=scalar(C['tail_radius']*1.65,C['tail_radius']*.85,min(distance(p,*defs[n]) for n in names))
   # The supplied tail drapes beside a hind foot; keep that foot in its leg chain.
   if z<.13 and y<.22:tail=0
  if tail:
   tw={n:1/(.012+distance(p,*defs[n]))**4 for n in names};s=sum(tw.values())
   w={k:q*(1-tail) for k,q in w.items()}
   for n,q in tw.items():w[n]=tail*q/s
 if z<C['height']*.58 and (y<C['front_cut'] or y>C['back_cut'] or KIND=='echidna'):
  family='Front' if y<C['front_cut'] else 'Back'
  if KIND=='echidna':family=min(legs,key=lambda n:distance(p,*defs[legs[n]['bones'][2]]))[:-1]
  mid=(legs[family+'L']['paw'].x+legs[family+'R']['paw'].x)/2
  name=family+('L' if x<mid else 'R');ns=legs[name]['bones']
  nearest=min(distance(p,*defs[n]) for n in ns)
  top=defs[ns[0]][0].z
  blend=scalar(top*.99,C['ankle']+.035,z)*scalar(.090,.040,nearest)*(1-head)*(1-tail)
  if z<C['ankle']+.008:blend=1-head-tail
  blend=max(0,min(1,blend))
  d={n:1/(.009+distance(p,*defs[n]))**5 for n in ns}
  if z<C['ankle']+.008:d={ns[0]:0,ns[1]:0,ns[2]:1}
  s=sum(d.values());w={k:q*(1-blend) for k,q in w.items()}
  for n,q in d.items():w[n]=w.get(n,0)+blend*q/s
 if KIND=='echidna' and z>.145 and y>-.085:w={'Spine':1}
 w=dict(sorted(((n,q) for n,q in w.items() if q>.006),key=lambda a:a[1],reverse=True)[:4]);s=sum(w.values())
 for n,q in w.items():groups[n].add([v.index],q/s,'REPLACE')
skin.parent=rig;mod=skin.modifiers.new('Anatomical skinning','ARMATURE');mod.object=rig;mod.use_deform_preserve_volume=True

# Sparse laid, tapered hair softens silhouettes without millions of strands.
hair_count=0
if KIND!='echidna':
 source=bpy.data.images.load(str(ROOT.parent/'overhaul/textures/generated/fine-fur-card.png'),check_existing=False)
 source.scale(256,256);rgba=np.empty(256*256*4,np.float32);source.pixels.foreach_get(rgba);rgba=rgba.reshape((256,256,4))
 luminance=rgba[:,:,:3].mean(axis=2);variation=np.clip(luminance/max(float(luminance.mean()),1e-6),.82,1.18)
 tones=[C['coat'],tuple(np.array(C['coat'])*.36),(.48,.43,.34),tuple(np.array(C['coat'])*1.28)]
 mats=[]
 for index,tint in enumerate(tones):
  mat=material('Fur cards '+KIND+' '+str(index),tint,.94);mat.surface_render_method='DITHERED';mat.use_backface_culling=False
  values=rgba.copy();values[:,:,:3]=variation[:,:,None]*np.array(tint)
  im=bpy.data.images.new(KIND+'_fur_'+str(index),256,256,alpha=True);im.pixels.foreach_set(values.astype(np.float32).ravel())
  node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=webp(im,True);bpy.data.images.remove(im)
  bs_hair=mat.node_tree.nodes['Principled BSDF'];bs_hair.inputs['Specular IOR Level'].default_value=.12
  mat.node_tree.links.new(node.outputs['Color'],bs_hair.inputs['Base Color']);mat.node_tree.links.new(node.outputs['Alpha'],bs_hair.inputs['Alpha']);mats.append(mat)
 rng=np.random.default_rng(491+len(KIND));polys=list(skin.data.polygons);areas=np.array([p.area for p in polys]);areas/=areas.sum()
 vs=[];faces=[];uvs=[];weights=[];normals=[];tints=[]
 for index in rng.choice(len(polys),4000 if KIND!='rabbit' else 2800,p=areas):
  poly=polys[index];p=poly.center.copy();n=poly.normal.copy()
  if p.z<C['height']*.12 or (p.y<C['head_y'][1] and p.z<C['head'][2]):continue
  flow=Vector((0,1,-.30)) if p.y>C['neck'][1] else Vector((0,.35,-1))
  tangent=flow-n*flow.dot(n)
  if tangent.length<1e-4:continue
  tangent.normalize();across=tangent.cross(n).normalized();length=rng.uniform(.002,.004)*(1 if KIND!='rabbit' else .7)
  p+=n*.00020;start=len(vs);influence={}
  for vi in poly.vertices:
   for g in skin.data.vertices[vi].groups:
    name=skin.vertex_groups[g.group].name;influence[name]=influence.get(name,0)+g.weight/len(poly.vertices)
  influence=dict(sorted(influence.items(),key=lambda a:a[1],reverse=True)[:4]);total=sum(influence.values());influence={k:v/total for k,v in influence.items()}
  tint=pigment(np.array([tuple(p)]))[0,:3];material_index=int(np.argmin(np.linalg.norm(np.array(tones)-tint,axis=1)))
  for row in range(3):
   t=row/2;center=p+tangent*length*t+n*length*(.12*t+.12*t*t)
   for side in [-1,1]:
    vs.append(tuple(center+across*length*.35*(1-.55*t)*side));uvs.append(((side+1)/2,t));weights.append(influence);normals.append(tuple(n))
  for row in range(2):faces.append((start+row*2,start+row*2+1,start+row*2+3,start+row*2+2));tints.append(material_index)
  hair_count+=1
 data=bpy.data.meshes.new('Weighted laid short fur');data.from_pydata(vs,[],faces);data.update()
 hair=bpy.data.objects.new('Laid silhouette fur',data);scene.collection.objects.link(hair);hair.parent=rig
 for mat in mats:data.materials.append(mat)
 uv=data.uv_layers.new(name='Hair UV')
 for poly in data.polygons:
  poly.material_index=tints[poly.index];poly.use_smooth=True
  for li in poly.loop_indices:uv.data[li].uv=uvs[data.loops[li].vertex_index]
 data.normals_split_custom_set_from_vertices(normals);hairgroups={n:hair.vertex_groups.new(name=n) for n in defs}
 for index,influence in enumerate(weights):
  for n,value in influence.items():hairgroups[n].add([index],value,'REPLACE')
 mod=hair.modifiers.new('Fur follows skin','ARMATURE');mod.object=rig;bpy.data.images.remove(source)

def sphere(name,p,size,mat,parent='Head',normal=None):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=p)
 ob=bpy.context.object;ob.name=name;ob.scale=size
 if normal:ob.rotation_euler=Vector(normal).to_track_quat('Y','Z').to_euler()
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for face in ob.data.polygons:face.use_smooth=True
 ob.data.materials.append(mat);world=ob.matrix_world.copy();ob.parent=rig;ob.parent_type='BONE';ob.parent_bone=parent
 bpy.context.view_layer.update();ob.matrix_world=world;return ob

eye=material(KIND+' glossy iris',(.006,.004,.002) if KIND=='echidna' else (.028,.016,.008) if KIND=='rabbit' else (.12,.073,.022),.19)
black=material(KIND+' round pupil',(.002,.002,.002),.14)
actual_eyes=[]
for i,(pos,normal) in enumerate(eye_sites):
 size=C['eye_size'];name='L' if i==0 else 'R'
 sphere('Inset eye '+name,pos-normal*size*.28,(size,size*.4,size*.84),eye,normal=normal)
 sphere('Round pupil '+name,pos+normal*size*.055,(size*.62,size*.13,size*.62),black,normal=normal)
 lidmat=material(KIND+' eyelid '+name,tuple(pigment(np.array([tuple(pos)]))[0,:3]),C['rough'])
 sphere('Blink lid '+name,pos+normal*size*.12,(size*1.06,size*.49,size*.92),lidmat,'Lid'+name,normal=normal)
 actual_eyes.append({'surface':list(pos),'normal':list(normal)})

# IK targets bake into ordinary FK animation; game runtimes need no constraints.
targets={};constraints=[]
for name,leg in legs.items():
 target=bpy.data.objects.new(name+' ground contact',None);scene.collection.objects.link(target);target.location=leg['paw']
 target.rotation_mode='QUATERNION';target.rotation_quaternion=rig.data.bones[leg['bones'][2]].matrix_local.to_quaternion();targets[name]=target
 pb=rig.pose.bones[leg['bones'][1]];ik=pb.constraints.new('IK');ik.target=target;ik.chain_count=2;ik.use_stretch=False;constraints.append((pb,ik))
 pb=rig.pose.bones[leg['bones'][2]];flat=pb.constraints.new('COPY_ROTATION');flat.target=target;flat.owner_space='WORLD';flat.target_space='WORLD';constraints.append((pb,flat))
 for n in leg['bones'][:2]:rig.pose.bones[n].ik_stretch=0
for pb in rig.pose.bones:pb.rotation_mode='XYZ'
order=sorted(defs,key=lambda n:len(list(rig.data.bones[n].parent_recursive)))
offsets={'BackL':0,'FrontL':.25,'BackR':.5,'FrontR':.75}
def pose(clip,t,duration):
 for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 for name,ob in targets.items():ob.location=legs[name]['paw']
 p=t/duration;wave=math.sin(p*math.tau);breath=math.sin(p*math.tau*(2 if clip=='idle' else 1))
 rig.pose.bones['Spine'].scale.x=1+(.003 if KIND=='echidna' else .007)*breath
 yaw=.025*wave;pitch=0
 if clip in ['look','sniff','forage']:
  envelope=math.sin(math.pi*p)**2
  yaw=(.24 if KIND=='fox' else .16 if KIND=='dog' else .10 if KIND=='rabbit' else .065)*wave*envelope
  if clip in ['sniff','forage']:pitch=(.18 if KIND=='dog' else .085 if KIND=='rabbit' else .095)*envelope
  else:pitch=-.035*envelope
 for i in range(len(C['tail'])-1):
  amplitude=(.22 if KIND=='dog' else .025 if KIND=='fox' else .015)*(1+i*.45)
  pb=rig.pose.bones['Tail'+str(i+1)];pb.rotation_mode='QUATERNION'
  axes=rig.data.bones[pb.name].matrix_local.to_3x3().inverted()
  lift=(.13 if KIND=='fox' else .17 if KIND=='dog' else 0) if i==0 else 0
  pb.rotation_quaternion=Quaternion(axes@Vector((1,0,0)),lift)@Quaternion(axes@Vector((0,0,1)),amplitude*math.sin(p*math.tau*(3 if KIND=='dog' else 1)+i*.6))
 for i in range(len(C['ears'])):
  pb=rig.pose.bones['Ear'+('L' if i==0 else 'R')]
  flick=math.exp(-((t-duration*(.26 if i==0 else .63))/.11)**2) if clip not in ['walk','hop'] else 0
  pb.rotation_euler.x=(.045*math.sin(p*math.tau*2+i) if KIND=='dog' else .16*flick)
 blink=max([math.exp(-((t-at)/.07)**4) for at in [duration*.34,duration*.77]]) if clip not in ['walk','hop'] else 0
 for name in ['LidL','LidR']:rig.pose.bones[name].scale=Vector((1,1,1))*(.005+.995*blink)
 if clip=='walk':
  for name,target in targets.items():
   phase=(p+offsets[name])%1;stance=C['stance'];stride=C['stride']
   if phase<stance:y=-stride/2+stride*phase/stance;lift=0
   else:
    u=(phase-stance)/(1-stance);y=stride/2-stride*(u*u*(3-2*u));lift=(.008 if KIND=='echidna' else .023)*math.sin(math.pi*u)**1.4
   target.location=legs[name]['paw']+Vector((0,y,lift))
  rig.pose.bones['Root'].location.y=-C['drop']+.0015*math.sin(p*math.tau*2)
  if KIND=='echidna':rig.pose.bones['Root'].rotation_euler.z=.025*wave
  if KIND=='fox':pitch=.02
 if clip=='hop':
  air=.18<p<.64
  lift=.055*math.sin(math.pi*(p-.18)/.46) if air else 0
  compression=-.007*math.sin(math.pi*p/.18) if p<=.18 else -.006*math.sin(math.pi*(p-.64)/.36) if p>=.64 else 0
  rig.pose.bones['Root'].location.y=lift+compression
  for name,target in targets.items():
   leg=legs[name];height=lift+(.014*math.sin(math.pi*(p-.18)/.46) if air else 0)
   if not leg['front'] and .64<p<.80:height=.015*math.sin(math.pi*(p-.64)/.16)
   target.location=leg['paw']+Vector((0,.025*math.sin(p*math.tau+(.3 if leg['front'] else 0)),height))
  pitch=.045*math.sin(p*math.tau)
 head=rig.pose.bones['Head'];head.rotation_mode='QUATERNION';axes=rig.data.bones['Head'].matrix_local.to_3x3().inverted()
 head.rotation_quaternion=Quaternion(axes@Vector((0,0,1)),yaw)@Quaternion(axes@Vector((1,0,0)),pitch)
 bpy.context.view_layer.update()

samples={}
for name,duration in C['clips']:
 stored=[];count=round(duration*30)
 for frame in range(count+1):
  pose(name,duration*frame/count,duration)
  ev=rig.evaluated_get(bpy.context.evaluated_depsgraph_get());mats={n:ev.pose.bones[n].matrix.copy() for n in order};basis={}
  for n in order:
   b=rig.data.bones[n];relative=mats[b.parent.name].inverted()@mats[n] if b.parent else mats[n]
   rest=b.parent.matrix_local.inverted()@b.matrix_local if b.parent else b.matrix_local
   basis[n]=(rest.inverted()@relative).decompose()
  stored.append(basis)
 samples[name]=stored
for pb,c in constraints:pb.constraints.remove(c)
for ob in targets.values():bpy.data.objects.remove(ob,do_unlink=True)
for pb in rig.pose.bones:pb.rotation_mode='QUATERNION'
rig.animation_data_create()
for name,stored in samples.items():
 rig.animation_data.action=None
 for frame,basis in enumerate(stored,1):
  for n,(loc,rot,scale) in basis.items():
   pb=rig.pose.bones[n];pb.location=loc;pb.rotation_quaternion=rot;pb.scale=scale
   for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame)
 action=rig.animation_data.action;action.name=KIND+'_'+name
 track=rig.animation_data.nla_tracks.new();track.name=name;strip=track.strips.new(name,1,action);strip.extrapolation='NOTHING';track.mute=True
 rig.animation_data.action=None
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for name in ['LidL','LidR']:rig.pose.bones[name].scale=Vector((.005,.005,.005))
scene.frame_set(0);bpy.context.view_layer.update();select(rig)
for ob in rig.children_recursive:ob.select_set(True)
for track in rig.animation_data.nla_tracks:track.mute=False;track.strips[0].influence=1
rig.rotation_euler.z=math.pi
bpy.ops.export_scene.gltf(filepath=str(FOLDER/'export'/(KIND+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,
 export_yup=True,export_apply=False,export_animations=True,export_extras=True,export_animation_mode='NLA_TRACKS',
 export_merge_animation='NLA_TRACK',export_nla_strips=True,export_image_format='WEBP',export_image_webp_fallback=False,export_image_quality=95)
rig.rotation_euler.z=0
for track in rig.animation_data.nla_tracks:track.mute=True;track.strips[0].influence=1
scene.frame_set(0)
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for name in ['LidL','LidR']:rig.pose.bones[name].scale=Vector((.005,.005,.005))
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=1000;scene.render.resolution_y=1000
camera=scene.camera;center=Vector((0,0,C['height']*.44));span=max(skin.dimensions)
camera.location=center+Vector((.8,-1.3,.60))*span;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.ortho_scale=span*1.37
scene.render.filepath=str(FOLDER/'previews/textured.png')
bpy.ops.wm.save_as_mainfile(filepath=str(FOLDER/(KIND+'.blend')),compress=True)
bpy.ops.render.render(write_still=True)
# Compact editable review source omits only the original dense reference mesh.
high.hide_render=True
for c in list(high.users_collection):c.objects.unlink(high)
bpy.data.libraries.write(str(FOLDER/(KIND+'_review.blend')),{scene},compress=True)
reference.objects.link(high)
raw=(Path('/Users/tam/Downloads')/(KIND+'.stl')).read_bytes()
report={'animal':KIND,'source_sha256':hashlib.sha256(raw).hexdigest(),'source_triangles':json.loads((FOLDER/'intake.json').read_text())['triangles'],
 'exported_triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in rig.children_recursive if o.type=='MESH'),
 'glb_bytes':(FOLDER/'export'/(KIND+'.glb')).stat().st_size,'bones':len(defs),'clips':dict(C['clips']),'fur_cards':hair_count,
 'texture_conversions':CONVERSIONS,'paw_centres':{n:list(v['paw']) for n,v in legs.items()},'eye_surfaces':actual_eyes,'prototype_only':True}
(FOLDER/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print('ANIMAL_STUDY: '+json.dumps(report),flush=True)
