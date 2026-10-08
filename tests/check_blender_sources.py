"""Read-only Blender source checks; run in a separate background Blender process."""
import bpy,json,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
results=[]
legacy_sources=['botanical_library.blend','botanical_expansion.blend','botanical_additions.blend','plant_growth.blend','low_grasses.blend','flower_additions.blend','plant_art_sample.blend','lake_garden.blend','companions.blend','shop_library.blend','wildlife_library.blend','hand_tools.blend','overhaul/animals.blend','overhaul/structures.blend','overhaul/Area_Furnishings.blend','overhaul/WorkingGarden.blend','overhaul/AlpineRavine.blend','overhaul/scenery.blend','overhaul/environment.blend','overhaul/tools.blend','cat_study/cat_game.blend',*[f'overhaul/Area_{k}.blend' for k in ['reedwater','fern_gully','limestone','pollinator','orchard','kitchen','glasshouse','stream','alpine','moon','Collections']],*[f'animal_studies/{k}/{k}_game.blend' for k in ['dog','fox','echidna','rabbit']]]
full_sources=sorted({row['source'].removeprefix('art_source/') for row in json.loads((root/'art_source/plant_full_art_manifest.json').read_text())})
sources=full_sources if '--full-plants-only' in sys.argv else legacy_sources+full_sources
if '--areas-only' in sys.argv:sources=[name for name in legacy_sources if name.startswith('overhaul/Area_') or name=='overhaul/AlpineRavine.blend']
for name in sources:
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
