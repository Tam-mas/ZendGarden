"""Author/export the 60 additions and three focused repairs in isolated batches.

Run in a separate approved Blender process: --background --python-exit-code 1
--python art_source/build_botanical_2026.py -- --batch 0 (through 6).
--audit-only measures all generated organs without exporting or saving a scene.
"""
import argparse
import json
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
import botanical_2026_geometry as additions
import botanical_2026_repairs as repairs
from botanical_2026_data import BY_ID
from build_full_plant_art import Surfaces, triangles
from fruit_tree_geometry import add_anchor_channels

IDS=[49,78,79,*additions.IDS]
BATCHES=[IDS[:3]]+[IDS[i:i+10] for i in range(3,len(IDS),10)]
FRUIT_IDS={49,*range(218,238)}

class ExpansionSurfaces(Surfaces):
 source_kind=None
 def pigment(self,idx,descriptor):
  label,color,kind,wind=descriptor
  if kind not in ['tropical','parallel','succulent']:return super().pigment(idx,descriptor)
  self.source_kind=kind
  try:return super().pigment(idx,(label+' '+kind,color,'smooth' if kind=='succulent' else 'leaf',wind))
  finally:self.source_kind=None
 def image(self,path,noncolor=False):
  if self.source_kind and not noncolor:
   filename={'tropical':'tropical_leaf_tissue.png','parallel':'parallel_leaf_tissue.png','succulent':'succulent_cuticle.png'}[self.source_kind]
   path=ROOT/'assets/textures/botanical_2026'/filename
  image=super().image(path,noncolor)
  if not noncolor and (image.size[0]>512 or image.size[1]>512):
   image.scale(256,256);image.pack()
  return image

def geometry(idx):
 if idx in repairs.IDS:result=repairs.geometry(idx)
 else:
  g,b,bs=additions.build(idx);result=[g,b,bs,additions.build(idx,'seedling')[0],additions.build(idx,'juvenile')[0]]
  scale=BY_ID[idx]['height']/max(p[2] for p in g.v+b.v)
  for geo in result:
   geo.v=[tuple(v*scale for v in p) for p in geo.v]
   if hasattr(geo,'fruit_anchors'):geo.fruit_anchors={i:tuple(v*scale for v in p) for i,p in geo.fruit_anchors.items()}
 g,b,bs,seed,juv=result
 assert all(x.f for x in [g,bs,seed,juv]),(idx,'missing stage')
 for geo in result:
  assert all(math.isfinite(v) for p in geo.v for v in p),(idx,'invalid vertex')
  assert all(0<=v<len(geo.v) for f in geo.f for v in f),(idx,'invalid face')
 for geo in [b,bs]:assert len(getattr(geo,'fruit_anchors',{}))==len(geo.v),(idx,'missing attachments')
 record={'id':idx,'height':round(max(p[2] for p in g.v+b.v),4),'mature_triangles':triangles(g)+triangles(b),'growth_triangles':sum(triangles(x) for x in [bs,seed,juv])}
 assert record['mature_triangles']<=200000 and record['growth_triangles']<=18000,record
 return result,record

def build(batch):
 previous=bpy.context.window.scene;scene=bpy.data.scenes.new(f'ZendGarden_Botanical2026_{batch:02d}');bpy.context.window.scene=scene
 folder=ROOT/'captures/botanical-2026/pigments'/str(batch);folder.mkdir(parents=True,exist_ok=True)
 (ROOT/'captures/botanical-2026/.gdignore').touch()
 surfaces=ExpansionSurfaces(folder);specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
 mature={r['id']:r for r in json.loads((ROOT/'art_source/botanical_manifest.json').read_text())};growth={r['id']:r for r in json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())}
 manifest=ROOT/'art_source/botanical_2026_manifest.json';audit={r['id']:r for r in json.loads(manifest.read_text())} if manifest.exists() else {}
 source=f'art_source/botanical_2026_{batch:02d}.blend'
 def mesh(geo,name,palette,parent):
  obj=geo.object(name,palette);add_anchor_channels(obj.data,geo);obj.parent=parent;return obj
 def export(root,organs,path):
  bpy.ops.object.select_all(action='DESELECT')
  for obj in [root,*organs]:obj.select_set(True)
  bpy.context.view_layer.objects.active=organs[0]
  # Blender 5 defaults to MATERIAL colours, inserting white COLOR_0 and moving
  # the data layer to COLOR_1. Godot reads COLOR_0 for fruit attachment depth.
  bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_image_format='AUTO',export_vertex_color='ACTIVE',export_all_vertex_colors=False)
 try:
  for offset,idx in enumerate(BATCHES[batch]):
   (g,b,bs,seed,juv),record=geometry(idx);leaves,blooms=surfaces.palette(idx,repairs if idx in repairs.IDS else additions)
   root=bpy.data.objects.new(f'Plant_{idx:02d}_{specs[idx][0]}',None);scene.collection.objects.link(root);root['catalogue_id']=idx
   organs=[mesh(g,'Foliage',leaves,root)];suffix='Fruit' if idx in FRUIT_IDS else 'Flower'
   if b.f:organs.append(mesh(b,'Bloom'+suffix,blooms,root))
   export(root,organs,ROOT/f'assets/plants/plant_{idx:02d}.glb')
   young=bpy.data.objects.new(f'Growth_{idx:02d}_{specs[idx][0]}',None);scene.collection.objects.link(young)
   organs=[mesh(seed,'Seedling',leaves,young),mesh(juv,'Juvenile',leaves,young),mesh(bs,'Buds'+suffix,blooms,young)]
   export(young,organs,ROOT/f'assets/plants/growth/growth_{idx:02d}.glb')
   record.update(name=specs[idx][0],source=source);audit[idx]=record
   mature[idx]={**mature.get(idx,{}),'id':idx,'name':specs[idx][0],'vertices':len(g.v)+len(b.v),'triangles':record['mature_triangles'],'path':f'assets/plants/plant_{idx:02d}.glb','source':source,'morphology_version':5,'botanical_2026_revision':1}
   growth[idx]={**growth.get(idx,{}),'id':idx,'name':specs[idx][0],'family':BY_ID[idx]['form'] if idx in BY_ID else 'vine' if idx==49 else 'conifer','height':record['height'],'triangles':record['growth_triangles'],'source':source,'botanical_2026_revision':1}
   root.location=(offset%5*24,offset//5*24,0);young.location=root.location+Vector((0,8,0))
   print('BOTANICAL_2026_PLANT',json.dumps(record),flush=True)
  bpy.data.libraries.write(str(ROOT/source),{scene},fake_user=True,compress=True)
  for path,rows in [('botanical_manifest',mature),('plant_growth_manifest',growth),('botanical_2026_manifest',audit)]:
   (ROOT/f'art_source/{path}.json').write_text(json.dumps([rows[k] for k in sorted(rows)],indent=2)+'\n')
  (ROOT/'scripts/plant_profiles.gd').write_text('class_name GardenPlantProfiles\nextends RefCounted\n\n# Authored mature model heights in metres, measured during asset export.\nconst HEIGHTS='+json.dumps([growth[k]['height'] for k in sorted(growth)])+'\n')
  print('BOTANICAL_2026_EXPORT',batch,source,flush=True)
 finally:
  bpy.context.window.scene=previous
  for path in folder.glob('*.jpg'):path.unlink()

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--batch',type=int);parser.add_argument('--audit-only',action='store_true')
 options=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
 if options.audit_only:
  errors=[]
  for idx in IDS:
   try:print('BOTANICAL_2026_AUDIT',geometry(idx)[1],flush=True)
   except AssertionError as error:errors.append(str(error));print('BOTANICAL_2026_ERROR',idx,str(error),flush=True)
  assert not errors,errors
 else:
  assert options.batch is not None and 0<=options.batch<len(BATCHES)
  build(options.batch)
