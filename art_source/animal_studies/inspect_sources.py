"""Sequential intake previews; leaves the interactive Blender project alone."""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parent
HEIGHTS={'dog':.58,'fox':.52,'rabbit':.35,'echidna':.28}
animals=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['fox','dog','echidna','rabbit']
for kind in animals:
    folder=ROOT/kind
    with bpy.data.libraries.load(str(folder/'intake.blend'),link=False) as (src,dst):dst.scenes=src.scenes
    scene=dst.scenes[0];bpy.context.window.scene=scene
    ob=next(o for o in scene.objects if o.type=='MESH');ob.name='Sculpt'
    corners=[Vector(c) for c in ob.bound_box]
    lo=Vector([min(c[k] for c in corners) for k in range(3)]);hi=Vector([max(c[k] for c in corners) for k in range(3)])
    center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z));scale=HEIGHTS[kind]/(hi.z-lo.z)
    rot=Matrix.Rotation(math.pi/2 if kind!='echidna' else 0,4,'Z')
    transform=rot@Matrix.Scale(scale,4)@Matrix.Translation(-center)
    ob.data.transform(transform)
    ob['intake_transform']=[list(row) for row in transform]
    for p in ob.data.polygons:p.use_smooth=True
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    mod=ob.modifiers.new('Inspection reduction','DECIMATE');mod.ratio=.045
    bpy.ops.object.modifier_apply(modifier=mod.name)
    m=bpy.data.materials.new('Neutral sculpt');m.diffuse_color=(.32,.32,.32,1);ob.data.materials.append(m)
    scene.world=bpy.data.worlds.new('Inspection studio');scene.world.use_nodes=True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.5,.55,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value=.4
    bbox=[Vector(c) for c in ob.bound_box];span=max(ob.dimensions)
    center=Vector((0,0,HEIGHTS[kind]*.44))
    bpy.ops.mesh.primitive_plane_add(size=20);floor=bpy.context.object
    floor.data.materials.append(m)
    for pos,power,size in [((.9,-.7,1.2),130,1.2),((-.7,.5,.9),90,.9)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(pos)*span)
        light=bpy.context.object;light.data.energy=power*span*span;light.data.size=size*span
        light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.object.camera_add();cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=span*1.45;scene.camera=cam
    scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=900;scene.render.resolution_y=900
    scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
    for view,pos in [('quarter',(.8,-1.3,.65)),('reverse',(.8,1.3,.65)),('side',(1.5,0,.25))]:
        cam.location=center+Vector(pos)*span;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(folder/'previews'/('raw_'+view+'.png'));bpy.ops.render.render(write_still=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'prepared.blend'),compress=True)
    data={'animal':kind,'dimensions':list(ob.dimensions),'bounds':[list(c) for c in ob.bound_box],
          'triangles':len(ob.data.polygons),'transform':[list(r) for r in transform]}
    (folder/'inspection.json').write_text(json.dumps(data,indent=2)+'\n')
    print('STL_INSPECTION: '+json.dumps(data),flush=True)
    # Release each heavy mesh before starting the next animal.
    for obj in list(scene.objects):
        data=obj.data;bpy.data.objects.remove(obj,do_unlink=True)
        if data and data.users==0 and isinstance(data,bpy.types.Mesh):bpy.data.meshes.remove(data)
    bpy.context.window.scene=bpy.data.scenes['Scene'];bpy.data.scenes.remove(scene)
