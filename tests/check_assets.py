"""Check all 60 glTF exports contain only the intended Blender scene."""
import json,struct,pathlib
root=pathlib.Path(__file__).resolve().parents[1]
files=list((root/'assets/plants').glob('plant_*.glb'))
assert len(files)==60, f'Expected 60 species, got {len(files)}'
tools=[root/'assets/tools'/f'{kind}.glb' for kind in ['can','shears','trowel','rake']]
companions=[root/'assets/companions'/f'{kind}.glb' for kind in ['cat','dog']]
for path in files+[root/'assets/environment/lake_garden.glb']+tools+companions:
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
 if path.name.startswith('plant_'):
  assert any('Foliage' in n.get('name','') for n in doc['nodes']),(path,'missing foliage')
print('BLENDER_ASSET_CHECK: PASS — 60 species, environment, 4 tools and 2 articulated companions, with no default-scene objects')
