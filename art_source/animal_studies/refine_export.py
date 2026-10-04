"""Small review correction without rebaking unchanged source maps and skinning."""
import bpy,json,sys,math
from pathlib import Path
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parent;kind=sys.argv[sys.argv.index('--')+1];folder=ROOT/kind
scene=next(s for s in bpy.data.scenes if s.name=='Zend STL — '+kind);bpy.context.window.scene=scene
rig=scene.objects['AnimalRig'];rig.animation_data.action=None
for track in rig.animation_data.nla_tracks:
 action=track.strips[0].action
 curves=action.layers[0].strips[0].channelbags[0].fcurves
 for bone in ['LidL','LidR']:
  path='pose.bones["'+bone+'"].scale';y=next(c for c in curves if c.data_path==path and c.array_index==1)
  values=[.005+.995*max(0,min(1,(float(k.co.y)-.025)/.975)) for k in y.keyframe_points]
  for curve in [c for c in curves if c.data_path==path]:
   for key,value in zip(curve.keyframe_points,values):key.co.y=value;key.interpolation='LINEAR'
   curve.update()
 if kind=='echidna':
  for mat in bpy.data.materials:
   if mat.name==kind+' glossy iris':mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(.006,.004,.002,1)
scene.frame_set(0)
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for n in ['LidL','LidR']:rig.pose.bones[n].scale=Vector((.005,.005,.005))
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
for ob in rig.children_recursive:ob.select_set(True)
for track in rig.animation_data.nla_tracks:track.mute=False;track.strips[0].influence=1
rig.rotation_euler.z=math.pi
bpy.ops.export_scene.gltf(filepath=str(folder/'export'/(kind+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=False,export_animations=True,export_extras=True,export_animation_mode='NLA_TRACKS',export_merge_animation='NLA_TRACK',export_nla_strips=True,export_image_format='WEBP',export_image_webp_fallback=False,export_image_quality=95)
rig.rotation_euler.z=0
for track in rig.animation_data.nla_tracks:track.mute=True;track.strips[0].influence=1
scene.frame_set(0)
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for n in ['LidL','LidR']:rig.pose.bones[n].scale=Vector((.005,.005,.005))
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=str(folder/(kind+'.blend')),compress=True)
scene.render.filepath=str(folder/'previews/textured.png');bpy.ops.render.render(write_still=True)
reference=next(o for o in scene.objects if o.name.startswith('SOURCE —'))
collections=list(reference.users_collection)
for collection in collections:collection.objects.unlink(reference)
bpy.data.libraries.write(str(folder/(kind+'_review.blend')),{scene},compress=True)
for collection in collections:collection.objects.link(reference)
report=json.loads((folder/'report.json').read_text());report['glb_bytes']=(folder/'export'/(kind+'.glb')).stat().st_size;report['review_refinement']='Retracted open lids leave no flattened flap; echidna eyes are dark.'
(folder/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print('ANIMAL_REFINE: '+kind,flush=True)
