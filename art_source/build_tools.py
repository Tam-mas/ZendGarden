"""Original first-person gardening tools, built in an isolated Blender scene."""
import bpy,math,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
only=args[args.index('--only')+1].split(',') if '--only' in args else []
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

def curved_tube(name,points,r,m,parent):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D'
 curve.resolution_u=12;curve.bevel_depth=r;curve.bevel_resolution=3;curve.use_fill_caps=True
 spline=curve.splines.new('BEZIER');spline.bezier_points.add(len(points)-1)
 for point,co in zip(spline.bezier_points,points):
  point.co=co;point.handle_left_type='AUTO';point.handle_right_type='AUTO'
 ob=bpy.data.objects.new(name,curve);scene.collection.objects.link(ob)
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 bpy.ops.object.convert(target='MESH')
 return finish(bpy.context.object,m,parent)

for kind in ['can','shears','trowel','rake','hoe']:
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
  # Rounded rear loop, attached at two points on the body rather than above
  # the open rim. The clear finger opening stays clear of the filling hole.
  curved_tube('Can rounded rear handle',[(.075,-.075,.068),(.165,-.165,.086),(.205,-.205,.048),(.213,-.213,0),(.198,-.198,-.054),(.155,-.155,-.083),(.075,-.075,-.067)],.012,sage,root)
  curved_tube('Can soft handle grip',[(.205,-.205,.038),(.212,-.212,.012),(.213,-.213,-.012),(.205,-.205,-.038)],.015,dark,root)
  for z in [.068,-.067]:
   mount=bar((.064,-.064,z),(.084,-.084,z),.019,sage,root)
   mount.name='Can handle mounting collar'
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
 elif kind=='hoe':
  bar((0,-.42,0),(0,.22,.065),.018,wood,root)
  bar((0,.19,.060),(0,.30,.11),.012,steel,root)
  bar((0,.30,.11),(0,.30,.025),.012,steel,root)
  blade=box((0,.30,.01),(.22,.075,.018),steel,root)
  blade.rotation_euler.x=.25
  ring((0,-.34,0),.019,.004,dark,root,rotation=(math.pi/2,0,0))
 else:
  bar((0,-.40,0),(0,.25,.07),.016,wood,root)
  bar((-.13,.26,.07),(.13,.26,.07),.012,steel,root)
  for j in range(9):bar((-.12+j*.03,.26,.07),(-.12+j*.03,.32,.005),.006,steel,root)
 bpy.ops.object.select_all(action='DESELECT')
 root.select_set(True)
 for child in root.children:child.select_set(True)
 bpy.context.view_layer.objects.active=root
 if not only or kind in only:
  bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/tools'/f'{kind}.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_apply=True)
 root.location.x=['can','shears','trowel','rake','hoe'].index(kind)*.7
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/hand_tools.blend'))
print('HAND_TOOLS_EXPORT: PASS')
