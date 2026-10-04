"""Isolated STL intake, usable in background Blender or via Blender MCP.

Defaults to Tam's Downloads, or pass -- INPUT_DIRECTORY [animal ...].
Leaves the interactive scene, file, selection and preferences untouched.
"""
import bpy,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
inputs=Path(args[0]) if args else Path('/Users/tam/Downloads')
animals=args[1:] if len(args)>1 else ['fox','dog','echidna','rabbit']
assert bpy.context.mode=='OBJECT','Return to Object Mode before isolated intake.'
original=bpy.context.window.scene;active=bpy.context.view_layer.objects.active;selected=list(bpy.context.selected_objects)
reports=[]
for kind in animals:
 path=inputs/(kind+'.stl');assert path.is_file(),path
 folder=ROOT/kind;folder.mkdir(exist_ok=True);(folder/'previews').mkdir(exist_ok=True)
 scene=bpy.data.scenes.new('Zend STL intake — '+kind)
 try:
  bpy.context.window.scene=scene
  bpy.ops.wm.stl_import(filepath=str(path));obj=bpy.context.object;obj.name=kind+'_source'
  obj.data.calc_loop_triangles();corners=[obj.matrix_world@Vector(c) for c in obj.bound_box]
  report={'animal':kind,'input':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
          'vertices':len(obj.data.vertices),'triangles':len(obj.data.loop_triangles),
          'bounds':[[min(v[i] for v in corners) for i in range(3)],[max(v[i] for v in corners) for i in range(3)]]}
  bpy.data.libraries.write(str(folder/'intake.blend'),{scene},compress=True)
  (folder/'intake.json').write_text(json.dumps(report,indent=2)+'\n');reports.append(report)
 finally:
  bpy.context.window.scene=original
  for obj in list(scene.objects):
   data=obj.data;bpy.data.objects.remove(obj,do_unlink=True)
   if data and not data.users and isinstance(data,bpy.types.Mesh):bpy.data.meshes.remove(data)
  bpy.data.scenes.remove(scene)
bpy.context.view_layer.objects.active=active
for obj in selected:obj.select_set(True)
result={'imported':reports,'preserved_scene':original.name,'original_file_not_saved':bpy.data.filepath}
print('ANIMAL_INTAKE: '+json.dumps(result),flush=True)
