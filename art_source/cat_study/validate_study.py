"""Read-only source/deformation checks. Run inside background Blender."""
import bpy, json, math
from pathlib import Path
from mathutils import Matrix

ROOT=Path(__file__).resolve().parent
scene=next(s for s in bpy.data.scenes if s.name.startswith('Zend Cat'))
bpy.context.window.scene=scene
rig=scene.objects['CatRig'];skin=scene.objects['Cat — deforming coat']
assert all(im.packed_file for im in bpy.data.images if im.type=='IMAGE' and im.users), 'unpacked texture'
assert len(skin.data.uv_layers)==1
assert all(abs(sum(g.weight for g in v.groups)-1)<1e-4 and 1<=len(v.groups)<=4 for v in skin.data.vertices)
clips={};contacts={}
rig.animation_data.use_nla=False
for track in rig.animation_data.nla_tracks:
    strip=track.strips[0]
    rig.animation_data.action=strip.action
    rig.animation_data.action_slot=strip.action_slot
    scene.frame_set(int(strip.frame_start));bpy.context.view_layer.update()
    first={b.name:b.matrix.copy() for b in rig.pose.bones}
    scene.frame_set(int(strip.frame_end));bpy.context.view_layer.update()
    last={b.name:b.matrix.copy() for b in rig.pose.bones}
    seam=max(abs(first[n][i][j]-last[n][i][j]) for n in first for i in range(4) for j in range(4))
    assert seam<1e-4,(track.name,seam)
    bounds=[];positions=[]
    for frame in range(int(strip.frame_start),int(strip.frame_end)+1):
        scene.frame_set(frame);bpy.context.view_layer.update()
        for b in rig.pose.bones:assert all(math.isfinite(v) for row in b.matrix for v in row)
        positions.append(rig.pose.bones['FrontL_Paw'].matrix.translation.copy())
        if track.name=='walk':
            dep=bpy.context.evaluated_depsgraph_get();ev=skin.evaluated_get(dep)
            bounds.append(min(v.co.z for v in ev.data.vertices))
    motion=max((p-positions[0]).length for p in positions)
    if track.name=='walk':assert motion>.05,('static walk',motion)
    clips[track.name]={'duration_seconds':(strip.frame_end-strip.frame_start)/30,'loop_seam_max_error':seam,'front_paw_motion_metres':motion}
    if bounds:
        assert min(bounds)>-.003,('paw penetration',min(bounds))
        assert max(bounds)<.008,('all paws floating',max(bounds))
        ev=skin.evaluated_get(bpy.context.evaluated_depsgraph_get())
        index=min(range(len(ev.data.vertices)),key=lambda i:ev.data.vertices[i].co.z)
        contacts={'minimum_skin_height':min(bounds),'maximum_lowest_skin_height':max(bounds),
                  'lowest_rest_vertex':list(skin.data.vertices[index].co),
                  'lowest_vertex_weights':{skin.vertex_groups[g.group].name:g.weight for g in skin.data.vertices[index].groups},
                  'paw_head_positions':{n:list(rig.pose.bones[n].matrix.translation) for n in ['FrontL_Paw','FrontR_Paw','BackL_Paw','BackR_Paw']}}
report={'passed':True,'clips':clips,'walk_floor_check':contacts,'packed_textures':True,'skin_weight_sums_valid':True}
(ROOT/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('CAT_STUDY_VALIDATION: '+json.dumps(report),flush=True)
