"""Render the shipped GLBs, so review includes the real exported materials."""
import bpy,math,json,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'captures/details';OUT.mkdir(parents=True,exist_ok=True)
filters=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
records=json.loads((OUT/"dimensions.json").read_text()) if filters and (OUT/"dimensions.json").exists() else []
for folder in ['shop','companions','wildlife']:
 for path in sorted((ROOT/'assets'/folder).glob('*.glb')):
    if filters and path.stem not in filters:continue
    records=[r for r in records if r['asset']!=folder+'/'+path.stem]
    scene=bpy.data.scenes.new('Review '+path.stem);bpy.context.window.scene=scene
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes=[o for o in scene.objects if o.type=='MESH'];bpy.context.view_layer.update()
    corners=[o.matrix_world@Vector(v) for o in meshes for v in o.bound_box]
    lo=Vector([min(v[k] for v in corners) for k in range(3)]);hi=Vector([max(v[k] for v in corners) for k in range(3)]);center=(lo+hi)/2;span=max(hi-lo)
    scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.35,.4,.46,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
    bpy.ops.mesh.primitive_plane_add(size=200,location=(center.x,center.y,lo.z-.005));plane=bpy.context.object
    m=bpy.data.materials.new('Studio sand');m.diffuse_color=(.22,.25,.23,1);plane.data.materials.append(m)
    bpy.ops.object.camera_add(location=center+Vector((1.15,1.7,1.05))*span);cam=bpy.context.object;cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=span*1.48;scene.camera=cam;cam.data.clip_start=.001
    for offset,energy,size in [((1,1,3),110,2.5),((-2,1,1.5),65,2),((0,-2,2),85,2)]:
        bpy.ops.object.light_add(type='AREA',location=center+Vector(offset)*span);light=bpy.context.object;light.data.energy=energy*span*span;light.data.shape='DISK';light.data.size=size*span;light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
    scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=12;scene.cycles.use_denoising=True
    scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
    scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/(folder+'_'+path.stem+'.png'))
    bpy.ops.render.render(write_still=True)
    records.append({'asset':folder+'/'+path.stem,'dimensions':list(hi-lo),'triangles':sum(len(o.data.polygons) for o in meshes)})
    # Review-only scene is discarded; source libraries and interactive Blender stay intact.
    for o in list(scene.objects):bpy.data.objects.remove(o,do_unlink=True)
(OUT/'dimensions.json').write_text(json.dumps(records,indent=2))
