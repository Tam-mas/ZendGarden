import bpy,sys,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
kind=sys.argv[sys.argv.index('--')+1]
scene=next(s for s in bpy.data.scenes if s.name=='Zend STL — '+kind);bpy.context.window.scene=scene
for ob in scene.objects:
 if ob.name.startswith(('Inset eye','Round pupil','Blink lid','Laid silhouette')):ob.hide_render=True
centres={'fox':(0,-.28,.414),'dog':(0,-.30,.49),'rabbit':(0,-.13,.225),'echidna':(0,-.16,.093)}
cam=scene.camera;center=Vector(centres[kind])
cam.data.ortho_scale=.21 if kind in ['dog','fox'] else .14;scene.render.resolution_x=800;scene.render.resolution_y=800
for side in [-1,1]:
 cam.location=center+Vector((side,0,0));cam.rotation_euler=(center-cam.location).to_track_quat('-Z','Y').to_euler()
 scene.render.filepath=str(ROOT/kind/'previews'/('head_'+str(side)+'.png'));bpy.ops.render.render(write_still=True)
print('Head centre',list(center),'span',cam.data.ortho_scale)
