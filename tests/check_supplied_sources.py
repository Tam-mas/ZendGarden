"""Read-only production pose/contact checks, run in isolated Blender."""
import bpy, json, math
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
results={}
for kind in ['cat','dog','fox','echidna','rabbit']:
    folder=ROOT/'art_source'/('cat_study' if kind=='cat' else 'animal_studies/'+kind)
    bpy.ops.wm.open_mainfile(filepath=str(folder/(kind+'_game.blend')),load_ui=False,use_scripts=False)
    scene=next(s for s in bpy.data.scenes if s.name.startswith('Zend'))
    bpy.context.window.scene=scene
    rig=next(o for o in scene.objects if o.type=='ARMATURE')
    coat=next(o for o in rig.children_recursive if o.type=='MESH' and ('coat' in o.name.lower()))
    assert all(image.packed_file and image.filepath.endswith('.webp') for image in bpy.data.images if image.type=='IMAGE' and image.users)
    rig.animation_data.use_nla=False
    clips={}
    for track in rig.animation_data.nla_tracks:
        strip=track.strips[0]
        rig.animation_data.action=strip.action
        rig.animation_data.action_slot=strip.action_slot
        scene.frame_set(int(strip.frame_start))
        bpy.context.view_layer.update()
        first={p.name:p.matrix.copy() for p in rig.pose.bones}
        scene.frame_set(int(strip.frame_end))
        bpy.context.view_layer.update()
        seam=max(abs(first[p.name][i][j]-p.matrix[i][j]) for p in rig.pose.bones for i in range(4) for j in range(4))
        assert seam<1e-4,(kind,track.name,'loop seam',seam)
        floor=[]
        for fraction in [i/24 for i in range(25)]:
            scene.frame_set(round(strip.frame_start+(strip.frame_end-strip.frame_start)*fraction))
            bpy.context.view_layer.update()
            assert all(math.isfinite(v) for p in rig.pose.bones for row in p.matrix for v in row)
            evaluated=coat.evaluated_get(bpy.context.evaluated_depsgraph_get())
            floor.append(min(v.co.z for v in evaluated.data.vertices))
        assert min(floor)>-.004,(kind,track.name,'floor penetration',min(floor))
        assert max(floor)<(.075 if track.name=='hop' else .012),(kind,track.name,'floating',max(floor))
        clips[track.name]={'loop_seam':seam,'min_floor':min(floor),'max_floor':max(floor)}
    results[kind]=clips
(ROOT/'art_source/animal_studies/production_validation.json').write_text(json.dumps(results,indent=2)+'\n')
print('SUPPLIED_SOURCE_CHECK: PASS '+json.dumps(results),flush=True)
