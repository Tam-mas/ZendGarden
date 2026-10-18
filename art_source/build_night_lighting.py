"""Packed, editable handheld torch and garden lighting, built in isolation.

Geometry is specified in garden Y-up metres and converted for glTF export.
Reuses the garden's existing metal, stone and smooth tissue PBR maps.
"""
import bpy,json,math,struct,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import material

def point(p):return Vector((p[0],-p[2],p[1]))

def export_tints(path,materials):
 # Blender's exporter keeps the image but drops this MixRGB pigment multiplier.
 # glTF's native linear baseColorFactor expresses the same multiplication.
 raw=path.read_bytes();length,kind=struct.unpack_from('<I4s',raw,12)
 assert kind==b'JSON'
 doc=json.loads(raw[20:20+length]);colors={m.name:list(m.diffuse_color) for m in materials}
 for mat in doc['materials']:mat['pbrMetallicRoughness']['baseColorFactor']=colors[mat['name']]
 encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
 body=struct.pack('<I4s',len(encoded),b'JSON')+encoded+raw[20+length:]
 path.write_bytes(struct.pack('<4sII',b'glTF',2,12+len(body))+body)

def build():
 previous=bpy.context.window.scene;scene=bpy.data.scenes.new('ZendGarden_NightLighting');bpy.context.window.scene=scene
 records=[];source='art_source/night_lighting.blend'
 try:
  def surface(name,color,rough=.65,metal=0,glow=False):
   m=material(name,color,rough);bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Metallic'].default_value=metal
   base=ROOT/'art_source/overhaul/textures'
   for suffix,input_name in [('albedo','Base Color'),('normal','Normal'),('roughness','Roughness')]:
    path=base/f'HQ brushed tool steel_{suffix}.png'
    im=bpy.data.images.load(str(path),check_existing=True);im.pack()
    if suffix!='albedo':im.colorspace_settings.name='Non-Color'
    node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im
    if suffix=='normal':
     normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.25
     m.node_tree.links.new(node.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs['Normal'],bs.inputs['Normal'])
    elif suffix=='roughness':m.node_tree.links.new(node.outputs['Color'],bs.inputs['Roughness'])
    else:
     tint=m.node_tree.nodes.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY';tint.inputs[0].default_value=1;tint.inputs[2].default_value=bs.inputs['Base Color'].default_value
     m.node_tree.links.new(node.outputs['Color'],tint.inputs[1]);m.node_tree.links.new(tint.outputs[0],bs.inputs['Base Color'])
   if glow:
    bs.inputs['Emission Color'].default_value=(*[int(color[k:k+2],16)/255 for k in [0,2,4]],1)
    bs.inputs['Emission Strength'].default_value=1.4
   return m
  iron=surface('Garden light graphite metal','56605c',.44,.75)
  brass=surface('Garden light brushed brass','b39b63',.38,.65)
  sage=surface('Torch sage enamel','719483',.45,.35)
  grip=surface('Torch dark grip','3a4540',.88)
  stone=surface('Lamp stone footing','a5a196',.93)
  warm=surface('Garden lamp glow warm diffuser','ffe4b7',.38,glow=True)
  white=surface('Garden lamp glow white LED','e9f4f0',.28,glow=True)
  def finish(obj,name,mat,parent,bevel=0):
   obj.name=name;obj.parent=parent;obj.data.materials.append(mat)
   bpy.context.view_layer.objects.active=obj;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
   if bevel:
    mod=obj.modifiers.new('Rounded machined edges','BEVEL');mod.width=bevel;mod.segments=3
    bpy.ops.object.modifier_apply(modifier=mod.name)
   bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
   bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
   return obj
  def box(name,c,size,mat,parent,bevel=.008):
   bpy.ops.mesh.primitive_cube_add(size=1,location=point(c));o=bpy.context.object;o.scale=(size[0],size[2],size[1]);return finish(o,name,mat,parent,bevel)
  def rod(name,a,b,r,mat,parent,r2=None):
   a,b=point(a),point(b);d=b-a
   bpy.ops.mesh.primitive_cone_add(vertices=32,radius1=r,radius2=r if r2 is None else r2,depth=d.length,location=(a+b)*.5)
   o=bpy.context.object;o.rotation_euler=d.to_track_quat('Z','Y').to_euler()
   for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
   return finish(o,name,mat,parent,min(r*.12,.006))
  def sphere(name,c,size,mat,parent):
   bpy.ops.mesh.primitive_uv_sphere_add(segments=24,ring_count=12,location=point(c));o=bpy.context.object;o.scale=(size[0],size[2],size[1])
   for f in o.data.polygons:f.use_smooth=True
   return finish(o,name,mat,parent)
  def cage(root,c,width,height):
   x,y,z=c
   box('Amber light diffuser',(x,y,z),(width*.68,height*.80,width*.68),warm,root,.012)
   for level in [-1,1]:box('Lantern rim',(x,y+level*height*.5,z),(width,.032,width),iron,root)
   for dx in [-1,1]:
    for dz in [-1,1]:box('Lantern corner rail',(x+dx*width*.43,y,z+dz*width*.43),(.019,height,.019),brass,root,.004)
   rod('Sloped lantern roof',(x,y+height*.5+.025,z),(x,y+height*.5+.11,z),width*.78,iron,root,width*.32)
   sphere('Roof finial',(x,y+height*.5+.125,z),(.025,.03,.025),brass,root)
  for offset,kind in enumerate(['torch','path_lantern','garden_lamppost','garden_floodlight']):
   root=bpy.data.objects.new('NightLighting_'+kind,None);scene.collection.objects.link(root)
   if kind=='torch':
    rod('Enamel torch body',(0,0,.07),(0,0,-.16),.031,sage,root)
    rod('Knurled rubber grip',(0,0,.04),(0,0,-.105),.033,grip,root)
    for k in range(11):
     z=.03-k*.012
     rod('Grip rib',(0,0,z),(0,0,z-.003),.035,grip,root)
    rod('Tail cap',(0,0,.065),(0,0,.083),.035,brass,root)
    rod('Torch flared reflector',(0,0,-.15),(0,0,-.22),.036,iron,root,.055)
    rod('Torch brass bezel',(0,0,-.217),(0,0,-.238),.056,brass,root)
    rod('Torch glass lens',(0,0,-.238),(0,0,-.241),.047,white,root)
    for k in range(8):
     a=k*math.tau/8;box('Bezel rib',(math.cos(a)*.054,math.sin(a)*.054,-.226),(.009,.009,.026),iron,root,.002)
    box('Thumb switch',(0,.034,-.135),(.023,.012,.027),brass,root,.004)
   elif kind=='path_lantern':
    box('Stone path footing',(0,.035,0),(.30,.07,.30),stone,root,.015)
    rod('Bollard foot',(0,.07,0),(0,.16,0),.08,iron,root,.055)
    rod('Bollard stem',(0,.13,0),(0,.54,0),.045,iron,root)
    for y in [.17,.48]:rod('Brass collar',(0,y,0),(0,y+.018,0),.052,brass,root)
    cage(root,(0,.66,0),.25,.24)
   elif kind=='garden_lamppost':
    box('Stone post footing',(0,.055,0),(.45,.11,.45),stone,root,.025)
    rod('Tapered iron pedestal',(0,.11,0),(0,.48,0),.12,iron,root,.065)
    rod('Fluted lamp column',(0,.44,0),(0,2.2,0),.051,iron,root,.037)
    for y in [.47,.58,1.95,2.18]:rod('Column brass collar',(0,y,0),(0,y+.035,0),.065 if y<.8 else .05,brass,root)
    cage(root,(0,2.40,0),.40,.46)
   else:
    for k in range(3):
     a=k*math.tau/3
     foot=(math.cos(a)*.50,.025,math.sin(a)*.50)
     rod('Tripod leg',foot,(0,.60,0),.026,iron,root)
     sphere('Rubber ground foot',foot,(.052,.025,.052),grip,root)
    rod('Tripod centre',(0,.26,0),(0,1.36,0),.035,iron,root,.024)
    rod('Stand adjustment collar',(0,.84,0),(0,.90,0),.05,brass,root)
    box('Floodlight housing',(0,1.50,0),(.55,.34,.11),iron,root,.025)
    box('LED reflector',(0,1.50,-.063),(.47,.26,.016),brass,root,.012)
    for x in [-.145,0,.145]:
     for y in [1.43,1.57]:box('LED light cell',(x,y,-.078),(.12,.105,.014),white,root,.008)
    for x in [-.30,.30]:
     box('Tilt bracket',(x,1.43,0),(.026,.32,.11),iron,root,.01)
     rod('Tilt knob',(x,1.5,0),(x*1.13,1.5,0),.042,brass,root)
    box('Bracket support',(0,1.28,0),(.62,.035,.11),iron,root)
   parts=list(root.children_recursive)
   bpy.ops.object.select_all(action='DESELECT')
   for obj in [root,*parts]:obj.select_set(True)
   bpy.context.view_layer.objects.active=root
   folder='tools' if kind=='torch' else 'shop';path=ROOT/f'assets/{folder}/{kind}.glb'
   bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_image_format='AUTO')
   export_tints(path,[iron,brass,sage,grip,stone,warm,white])
   triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in parts if o.type=='MESH')
   records.append({'kind':kind,'path':str(path.relative_to(ROOT)),'triangles':triangles,'source':source})
   root.location.x=offset*2.3
   print('NIGHT_LIGHT_EXPORT',kind,triangles,flush=True)
  bpy.data.libraries.write(str(ROOT/source),{scene},fake_user=True,compress=True)
  (ROOT/'art_source/night_lighting_manifest.json').write_text(json.dumps(records,indent=2)+'\n')
 finally:bpy.context.window.scene=previous

if __name__=='__main__':build()
