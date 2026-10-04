"""Read-only packed-map, export and evaluated animation/contact verification."""
import bpy,json,math,sys,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parent
kind=sys.argv[sys.argv.index('--')+1]
scene=next(s for s in bpy.data.scenes if s.name=='Zend STL — '+kind)
bpy.context.window.scene=scene
rig=scene.objects['AnimalRig'];skin=scene.objects['Coat']
assert len(skin.data.uv_layers)==1
assert all(1<=len(v.groups)<=4 and abs(sum(g.weight for g in v.groups)-1)<1e-4 for v in skin.data.vertices)
used=[im for im in bpy.data.images if im.type=='IMAGE' and im.users]
assert all(im.packed_file and im.filepath.endswith('.webp') for im in used),[(im.name,im.filepath) for im in used]
raw=(ROOT/kind/'export'/(kind+'.glb')).read_bytes()
length,typ=struct.unpack('<II',raw[12:20]);data=json.loads(raw[20:20+length])
assert data['images'] and all(im.get('mimeType')=='image/webp' for im in data['images'])
assert 'EXT_texture_webp' in data['extensionsUsed']
clips={};rig.animation_data.use_nla=False
foot_vertices={}
if kind=='wombat':
 ear_groups={skin.vertex_groups[name].index for name in ['EarL','EarR']}
 assert all(v.co.y<-.175 and v.co.z>.32 for v in skin.data.vertices if any(g.group in ear_groups for g in v.groups)),('ear weights outside pinnae',kind)
 for name in ['BackL','FrontL','BackR','FrontR']:
  group=skin.vertex_groups[name+'_Paw'].index
  foot_vertices[name]=[v.index for v in skin.data.vertices if v.co.z<.04 and any(g.group==group and g.weight>.999 for g in v.groups)]
  assert foot_vertices[name],('missing sole weights',kind,name)
for track in rig.animation_data.nla_tracks:
 strip=track.strips[0];rig.animation_data.action=strip.action;rig.animation_data.action_slot=strip.action_slot
 scene.frame_set(int(strip.frame_start));bpy.context.view_layer.update()
 first={p.name:p.matrix.copy() for p in rig.pose.bones}
 scene.frame_set(int(strip.frame_end));bpy.context.view_layer.update()
 last={p.name:p.matrix.copy() for p in rig.pose.bones}
 seam=max(abs(first[n][i][j]-last[n][i][j]) for n in first for i in range(4) for j in range(4))
 heights=[];paws=[];contacts={name:[] for name in foot_vertices}
 for frame in range(int(strip.frame_start),int(strip.frame_end)+1):
  scene.frame_set(frame);bpy.context.view_layer.update()
  assert all(math.isfinite(v) for p in rig.pose.bones for row in p.matrix for v in row)
  paws.append(rig.pose.bones['FrontL_Paw'].matrix.translation.copy())
  if track.name in ['walk','hop'] or kind=='wombat':
   ev=skin.evaluated_get(bpy.context.evaluated_depsgraph_get())
   heights.append(min(v.co.z for v in ev.data.vertices))
   for name,indices in foot_vertices.items():
    phase=((frame-strip.frame_start)/(strip.frame_end-strip.frame_start)+{'BackL':0,'FrontL':.25,'BackR':.5,'FrontR':.75}[name])%1
    if track.name!='walk' or phase<.80:
     contacts[name].append(min(ev.data.vertices[i].co.z for i in indices))
 motion=max((p-paws[0]).length for p in paws)
 clips[track.name]={'seconds':(strip.frame_end-strip.frame_start)/30,'loop_seam':seam,'paw_motion':motion,
                   'min_floor':min(heights) if heights else None,'max_floor':max(heights) if heights else None}
 if contacts:
  clips[track.name]['support_paws']={name:{'min_floor':min(values),'max_floor':max(values)} for name,values in contacts.items()}
 if track.name in ['walk','hop']:
  ev=skin.evaluated_get(bpy.context.evaluated_depsgraph_get());lowest=min(range(len(ev.data.vertices)),key=lambda i:ev.data.vertices[i].co.z)
  clips[track.name]['lowest_rest_vertex']=list(skin.data.vertices[lowest].co)
  clips[track.name]['lowest_weights']={skin.vertex_groups[g.group].name:g.weight for g in skin.data.vertices[lowest].groups}
report={'animal':kind,'clips':clips,'maps_packed_webp':True,'skin_weights_valid':True,'export_images_webp':len(data['images'])}
(ROOT/kind/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('ANIMAL_VALIDATION: '+json.dumps(report),flush=True)
assert all(v['loop_seam']<1e-4 for v in clips.values()),('loop seam',clips)
for name,c in clips.items():
 if kind=='wombat':
  assert c['min_floor']>-.004,('floor penetration',kind,name,c)
  assert c['max_floor']<.012,('floating paws',kind,name,c)
  for paw,contact in c['support_paws'].items():
   assert -.004<contact['min_floor'] and contact['max_floor']<.004,('support paw contact',kind,name,paw,contact)
 if name in ['walk','hop']:
  assert c['paw_motion']>(.015 if kind=='echidna' else .035),('static gait',kind,c)
  assert c['min_floor']>-.004,('floor penetration',kind,c)
  assert c['max_floor']<(.075 if name=='hop' else .012),('floating gait',kind,c)
print('ANIMAL_VALIDATION: PASS '+kind,flush=True)
