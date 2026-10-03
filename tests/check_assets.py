"""Check self-contained model exports, articulation and triangle budgets."""
import json,struct,pathlib,hashlib,sys
root=pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'art_source/overhaul'))
from selection_policy import selected_old,retained_record
files=list((root/'assets/plants').glob('plant_*.glb'))
assert len(files)==136, f'Expected 136 species, got {len(files)}'
tools=[root/'assets/tools'/f'{kind}.glb' for kind in ['can','shears','trowel','rake','hoe']]
companions=[root/'assets/companions'/f'{kind}.glb' for kind in ['cat','dog']]
shop=[root/'assets/shop'/f'{kind}.glb' for kind in ['stone','pot','bench','lantern','arbor','pergola','greenhouse','pond','bath','hive','sign','potting_bench','compost_bays','rain_barrel','raised_bed','trellis_screen','gazebo','arched_bridge','fountain','garden_swing','insect_hotel']]
wildlife=[root/'assets/wildlife'/f'{kind}.glb' for kind in ['rabbit','kangaroo','kangaroo_joey','songbird','native_bird','frog','bee','butterfly','dragonfly','firefly','fish','lady_beetle','echidna','wombat','fox','fairy_wren','kookaburra','lorikeet','magpie','blue_banded_bee','hoverfly','mantis','leaf_insect','emperor_gum_moth']]
scenery=list((root/'assets/scenery').glob('*.glb'))
assert len(scenery)==3
for path in files+[root/'assets/environment/lake_garden.glb']+tools+companions+shop+wildlife+scenery:
 data=path.read_bytes()
 assert data[:4]==b'glTF', path
 length,kind=struct.unpack_from('<II',data,12)
 doc=json.loads(data[20:20+length])
 key=path.parent.name+'/'+path.stem
 retained=path in wildlife+companions and selected_old(key)
 if retained:
  original=retained_record(key)
  assert hashlib.sha256(data).hexdigest()==original['sha256'],(path,'selected original differs from retained baseline')
 assert len(doc['scenes'])==1,(path,'unexpected extra scene')
 assert not any(n.get('name')=='Cube' for n in doc['nodes']),(path,'default cube exported')
 assert doc.get('meshes'),(path,'empty export')
 if path in companions:
  for joint in ['Body','Head','Tail','FrontL','FrontR','BackL','BackR']:
   assert any(n.get('name','').startswith(joint) for n in doc['nodes']),(path,'missing joint '+joint)
 if path in shop+wildlife+companions+scenery:
  assert doc.get('images'),(path,'missing embedded textures')
  assert all('bufferView' in image for image in doc['images']),(path,'external texture dependency')
  triangles=sum(doc['accessors'][primitive['indices']]['count']//3 for mesh in doc['meshes'] for primitive in mesh['primitives'])
  assert triangles<65000,(path,'detail triangle budget exceeded',triangles)
  for mesh in doc['meshes']:
   for primitive in mesh['primitives']:
    assert 'TEXCOORD_0' in primitive['attributes'],(path,'missing UVs')
  if path.stem in ['songbird','native_bird','bee','butterfly','dragonfly','firefly']:
   for joint in ['WingL','WingR']:
    assert any(n.get('name','').startswith(joint) for n in doc['nodes']),(path,'missing wing pivot')
 if path in wildlife+companions and not retained:
  assert doc.get('animations'),(path,'missing authored movement clips')
  assert all(a.get('channels') for a in doc['animations']),(path,'empty movement clip')
  if path.stem in ['cat','dog','rabbit','kangaroo','kangaroo_joey','echidna','wombat','fox','songbird','native_bird','fairy_wren','kookaburra','lorikeet','magpie']:
   assert len(doc.get('skins',[]))==1,(path,'missing continuous anatomical skin')
   names={doc['nodes'][i]['name'] for i in doc['skins'][0]['joints']}
   assert {'Skin_Body','Skin_Head'}<=names,(path,'missing body/head skin joints')
   for node in doc['nodes']:
    if 'skin' not in node:continue
    for primitive in doc['meshes'][node['mesh']]['primitives']:
     assert {'JOINTS_0','WEIGHTS_0'}<=primitive['attributes'].keys(),(path,'unweighted skin or coat')
     accessor=doc['accessors'][primitive['attributes']['WEIGHTS_0']]
     assert accessor['componentType']==5126 and accessor['type']=='VEC4',(path,'unexpected skin weight format')
     view=doc['bufferViews'][accessor['bufferView']]
     offset=20+length+8+view.get('byteOffset',0)+accessor.get('byteOffset',0)
     stride=view.get('byteStride',16)
     for index in range(accessor['count']):
      weight=struct.unpack_from('<4f',data,offset+index*stride)
      assert all(v>=0 for v in weight) and abs(sum(weight)-1)<.002,(path,'invalid or unnormalized skin weights')
  for node in doc['nodes']:
   if 'hq_rest_location' in node.get('extras',{}):
    assert 'translation' in node,(path,'missing neutral joint transform',node['name'])
  for material in doc.get('materials',[]):
   if material.get('name','').startswith('Fur cards '):
    assert material.get('alphaMode')=='MASK' and material.get('doubleSided'),(path,'hair opacity export lost')
    index=material['pbrMetallicRoughness']['baseColorTexture']['index']
    image=doc['images'][doc['textures'][index]['source']]
    assert image['mimeType']=='image/png',(path,'hair alpha compressed to JPEG')
    view=doc['bufferViews'][image['bufferView']]
    # MIME alone is insufficient: an RGB PNG cannot provide hair cutouts.
    binary_start=20+length+8
    png=data[binary_start+view.get('byteOffset',0):binary_start+view.get('byteOffset',0)+view['byteLength']]
    assert png[:8]==b'\x89PNG\r\n\x1a\n' and png[25] in [4,6],(path,'hair PNG has no alpha channel')
 if path.name.startswith('plant_'):

  assert any('Foliage' in n.get('name','') for n in doc['nodes']),(path,'missing foliage')
print('BLENDER_ASSET_CHECK: PASS — 136 species, environment, 5 tools, 21 shop structures, 24 wildlife models, 3 scenery models and 2 articulated companions, with no default-scene objects')
