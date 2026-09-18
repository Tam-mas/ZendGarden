"""Original first-person gardening tools, built in an isolated Blender scene."""
import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
scene=bpy.data.scenes.new('ZendGarden_HandTools')
bpy.context.window.scene=scene

def mat(name,color,metal=0,rough=.6):
 m=bpy.data.materials.new(name);m.use_nodes=True
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*color,1);b.inputs['Metallic'].default_value=metal;b.inputs['Roughness'].default_value=rough
 return m
sage=mat('Enamel sage',(.13,.26,.20),.3,.34)
steel=mat('Brushed steel',(.34,.39,.39),.8,.27)
wood=mat('Honey ash handles',(.31,.19,.075),0,.78)
dark=mat('Handle grips',(.04,.06,.045),0,.9)
inside=mat('Can opening',(.015,.025,.02),0,.9)

def finish(ob,m,parent):
 ob.data.materials.append(m);ob.parent=parent
 for p in ob.data.polygons:p.use_smooth=True
 return ob

def cyl(p,rad,depth,m,parent,top=None):
 bpy.ops.mesh.primitive_cone_add(vertices=24,radius1=rad,radius2=rad if top is None else top,depth=depth,location=p)
 return finish(bpy.context.object,m,parent)

def bar(a,b,r,m,parent):
 a,b=Vector(a),Vector(b);o=cyl((a+b)/2,r,(b-a).length,m,parent)
 o.rotation_mode='QUATERNION';o.rotation_quaternion=(b-a).to_track_quat('Z','Y');return o

def box(p,scale,m,parent):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bevel=o.modifiers.new('Rounded edges','BEVEL');bevel.width=.005;bevel.segments=3
 return finish(o,m,parent)

def ring(p,major,minor,m,parent,rotation=(0,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=32,minor_segments=8,location=p,rotation=rotation)
 return finish(bpy.context.object,m,parent)

for kind in ['can','shears','trowel','rake']:
 root=bpy.data.objects.new('Held_'+kind,None);scene.collection.objects.link(root)
 if kind=='can':
  cyl((0,0,0),.115,.205,sage,root,top=.105)
  cyl((0,0,.104),.096,.004,inside,root)
  ring((0,0,.106),.104,.009,sage,root)
  bar((-.065,.065,-.04),(-.17,.24,.09),.022,sage,root)
  rose=cyl((-.17,.24,.10),.047,.027,steel,root)
  rose.rotation_euler.x=math.radians(-35)
  for j in range(9):
   a=j*2.4;r=.032*(j/9)**.5
   cyl((-.17+math.cos(a)*r,.24+math.sin(a)*r,.118),.0025,.001,dark,root)
  for a,b in [((.08,-.07,-.04),(.16,-.13,-.03)),((.16,-.13,-.03),(.16,-.13,.15)),((.16,-.13,.15),(.065,-.025,.16))]:bar(a,b,.013,sage,root)
 elif kind=='shears':
  for side in [-1,1]:
   handle=ring((side*.042,-.10,0),.041,.013,dark,root)
   handle.scale.y=1.35
   bar((side*.024,-.045,0),(-side*.014,.095,0),.009,steel,root)
   blade=box((-side*.019,.122,.004),(.018,.14,.006),steel,root)
   blade.rotation_euler.z=side*.16
  cyl((0,.035,.01),.014,.017,wood,root)
 elif kind=='trowel':
  bar((0,-.20,0),(0,-.045,0),.027,wood,root)
  bar((0,-.045,0),(0,.09,.018),.013,steel,root)
  verts=[(-.05,.045,0),(.05,.045,0),(.065,.15,.015),(0,.27,.025),(-.065,.15,.015),(0,.10,-.015)]
  faces=[(0,1,5),(1,2,5),(2,3,5),(3,4,5),(4,0,5)]
  mesh=bpy.data.meshes.new('Curved trowel blade');mesh.from_pydata(verts,[],faces);mesh.update()
  ob=bpy.data.objects.new('Blade',mesh);scene.collection.objects.link(ob);finish(ob,steel,root)
  solid=ob.modifiers.new('Steel thickness','SOLIDIFY');solid.thickness=.003
 else:
  bar((0,-.40,0),(0,.25,.07),.016,wood,root)
  bar((-.13,.26,.07),(.13,.26,.07),.012,steel,root)
  for j in range(9):bar((-.12+j*.03,.26,.07),(-.12+j*.03,.32,.005),.006,steel,root)
 bpy.ops.object.select_all(action='DESELECT')
 root.select_set(True)
 for child in root.children:child.select_set(True)
 bpy.context.view_layer.objects.active=root
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/tools'/f'{kind}.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_apply=True)
 root.location.x=['can','shears','trowel','rake'].index(kind)*.7
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/hand_tools.blend'))
print('HAND_TOOLS_EXPORT: PASS')
