"""Read-only Blender source checks; run in a separate background Blender process."""
import bpy,json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
results=[]
for name in ['botanical_library.blend','lake_garden.blend','companions.blend']:
    path=root/'art_source'/name
    bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert meshes, f'No meshes in {name}'
    missing=[]
    for image in bpy.data.images:
        if image.source=='FILE' and image.filepath and not image.packed_file:
            resolved=Path(bpy.path.abspath(image.filepath))
            if not resolved.is_file(): missing.append(str(resolved))
    assert not missing, f'Missing images in {name}: {missing}'
    results.append({'file':name,'scene':bpy.context.scene.name,'meshes':len(meshes),'missing_images':len(missing)})
print('BLENDER_SOURCE_CHECK: PASS '+json.dumps(results))
