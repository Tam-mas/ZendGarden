"""Read-only Blender source checks; run in a separate background Blender process."""
import bpy,json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
results=[]
for name in ['botanical_library.blend','botanical_expansion.blend','botanical_additions.blend','plant_growth.blend','low_grasses.blend','flower_additions.blend','lake_garden.blend','companions.blend','shop_library.blend','wildlife_library.blend','hand_tools.blend','overhaul/animals.blend','overhaul/structures.blend','overhaul/Area_Furnishings.blend','overhaul/WorkingGarden.blend','overhaul/scenery.blend','overhaul/environment.blend','overhaul/tools.blend','cat_study/cat_game.blend',*[f'overhaul/Area_{k}.blend' for k in ['reedwater','fern_gully','limestone','pollinator','orchard','kitchen','glasshouse','stream','alpine','moon','Collections']],*[f'animal_studies/{k}/{k}_game.blend' for k in ['dog','fox','echidna','rabbit']]]:
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
