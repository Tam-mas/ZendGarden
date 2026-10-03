"""Check self-contained model exports, articulation and triangle budgets."""
import json,struct,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
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
 if path in wildlife+companions:
  assert doc.get('animations'),(path,'missing authored movement clips')
  assert all(a.get('channels') for a in doc['animations']),(path,'empty movement clip')
  for node in doc['nodes']:
   if 'hq_rest_location' in node.get('extras',{}):
    assert 'translation' in node,(path,'missing neutral joint transform',node['name'])
 if path.name.startswith('plant_'):

  assert any('Foliage' in n.get('name','') for n in doc['nodes']),(path,'missing foliage')
print('BLENDER_ASSET_CHECK: PASS — 136 species, environment, 5 tools, 21 shop structures, 24 wildlife models, 3 scenery models and 2 articulated companions, with no default-scene objects')
