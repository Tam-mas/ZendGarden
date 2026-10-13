"""Actual GLB/source/catalogue contracts for all 60 new plants and three repairs."""
import collections
import json
import math
import re
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_2026_data import PLANTS
import check_plant_art_full as glb

specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
assert len(specs)==278 and len({p[0] for p in specs})==278
baseline=json.loads((ROOT/'art_source/plant_full_baseline.json').read_text())
assert [p[0] for p in specs[:218]]==[p['name'] for p in baseline], 'Existing save identities moved'
assert collections.Counter(p['group'] for p in PLANTS)=={'Fruit trees':20,'Cacti & succulents':20,'Rainforest & tree ferns':20}
catalogue=(ROOT/'scripts/catalogue.gd').read_text()
assert json.loads(re.search(r'const ROWS\s*=\s*(\[.*?\n\])',catalogue,re.S)[1])==specs
heights=json.loads((ROOT/'scripts/plant_profiles.gd').read_text().split('const HEIGHTS=')[1])
audit={r['id']:r for r in json.loads((ROOT/'art_source/botanical_2026_manifest.json').read_text())}
assert set(audit)=={49,78,79,*range(218,278)}
glb.FRUIT.update({49,*range(218,238)})
sources=set();mature_total=0;growth_total=0
for idx,row in audit.items():
 source=ROOT/row['source'];assert source.is_file();sources.add(source)
 mature_path=ROOT/f'assets/plants/plant_{idx:02d}.glb';growth_path=ROOT/f'assets/plants/growth/growth_{idx:02d}.glb'
 mature=glb.inspect(mature_path,idx);growth=glb.inspect(growth_path,idx,True)
 glb.verify_sites(idx,mature,growth)
 assert abs(mature['bounds']['max'][1]-heights[idx])<.002,(idx,'Height metadata differs from mesh')
 assert mature['triangles']==row['mature_triangles'] and growth['triangles']==row['growth_triangles']
 assert mature['triangles']<=200000 and growth['triangles']<=18000
 mature_total+=mature['triangles'];growth_total+=growth['triangles']
 doc,blob=glb.read_glb(growth_path);stages={}
 for node in doc['nodes']:
  if 'mesh' not in node:continue
  name=node['name'].split('.')[0];points=[]
  for primitive in doc['meshes'][node['mesh']]['primitives']:
   points.extend(glb.accessor(doc,blob,primitive['attributes']['POSITION']))
  stages[name]=max(p[1] for p in points)
 assert 0<stages['Seedling']<stages['Juvenile']<heights[idx]*.65,(idx,'Early stages are not independently small',stages)
 for path in [mature_path,growth_path]:
  assert 'gltf/embedded_image_handling=2' in path.with_suffix('.glb.import').read_text()
  doc,_=glb.read_glb(path)
  assert all('bufferView' in image for image in doc['images']), (idx,'External texture')
  for material in doc['materials']:
   assert 'normalTexture' in material and 'baseColorTexture' in material['pbrMetallicRoughness'] and 'metallicRoughnessTexture' in material['pbrMetallicRoughness']
   if idx in range(238,258) or idx==221:
    assert not material['name'].startswith('Leaf') and 'young leaf' not in material['name'],(idx,'Fleshy tissue receives leaf wind')
 assert any((ROOT/f'assets/ui/plants/{idx:02d}{ext}').is_file() for ext in ['.webp','.png']),(idx,'Missing portrait')
 assert mature_path.stat().st_size<25_000_000,(idx,'Asset exceeds Cloudflare Pages file limit')

# Pumpkin peduncles keep a vertex on each vine attachment through ripening.
doc,blob=glb.read_glb(ROOT/'assets/plants/plant_49.glb');attachments=collections.defaultdict(list)
for node in doc['nodes']:
 if not node.get('name','').startswith('BloomFruit'):continue
 for primitive in doc['meshes'][node['mesh']]['primitives']:
  a=primitive['attributes'];positions=glb.accessor(doc,blob,a['POSITION']);uv=glb.accessor(doc,blob,a['TEXCOORD_1']);colors=glb.accessor(doc,blob,a['COLOR_0'])
  for p,q,c in zip(positions,uv,colors):
   anchor=(q[0],1-q[1],(round(c[0]*255)*256+round(c[1]*255))/65535*16-8)
   attachments[tuple(round(v,4) for v in anchor)].append(p)
assert len(attachments)==4
for anchor,points in attachments.items():
 assert min(math.dist(anchor,p) for p in points)<.025,'Pumpkin stalk detached from vine'
 assert -.002<min(p[1] for p in points)<.03,'Pumpkin is floating or buried'
for idx,target in [(78,42),(79,48)]:assert abs(heights[idx]-target)<.001
assert len(sources)==7
print('BOTANICAL_2026_ASSETS: PASS',len(PLANTS),'additions; 3 repairs;',mature_total,'mature triangles;',growth_total,'growth triangles')
