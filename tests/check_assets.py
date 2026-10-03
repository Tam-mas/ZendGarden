"""Check all 136 glTF exports contain only the intended Blender scene."""
import json,struct,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
files=list((root/'assets/plants').glob('plant_*.glb'))
assert len(files)==136, f'Expected 136 species, got {len(files)}'
tools=[root/'assets/tools'/f'{kind}.glb' for kind in ['can','shears','trowel','rake','hoe']]
companions=[root/'assets/companions'/f'{kind}.glb' for kind in ['cat','dog']]
shop=[root/'assets/shop'/f'{kind}.glb' for kind in ['stone','pot','bench','lantern','arbor','pergola','greenhouse','pond','bath','hive','sign']]
wildlife=[root/'assets/wildlife'/f'{kind}.glb' for kind in ['rabbit','kangaroo','kangaroo_joey','songbird','native_bird','frog','bee','butterfly','dragonfly','firefly','fish','lady_beetle']]
for path in files+[root/'assets/environment/lake_garden.glb']+tools+companions+shop+wildlife:
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
 if path in shop+wildlife+companions:
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
 if path.name.startswith('plant_'):

  assert any('Foliage' in n.get('name','') for n in doc['nodes']),(path,'missing foliage')
print('BLENDER_ASSET_CHECK: PASS — 136 species, environment, 5 tools, 11 shop structures, 12 wildlife models and 2 articulated companions, with no default-scene objects')
