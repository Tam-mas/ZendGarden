"""Export coverage and organ/PBR contracts for supplementary botanical stages."""
import json, struct, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
report=json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())
assert [p['id'] for p in report]==list(range(136))
triangles=0
for entry in report:
    path=ROOT/'assets/plants/growth'/f"growth_{entry['id']:02d}.glb"
    raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+length]);blob=raw[28+length:]
    for organ in ['Seedling','Juvenile','Buds']:
        assert any(n.get('name','').startswith(organ) and 'mesh' in n for n in doc['nodes']),(path,organ)
    assert all('bufferView' in im for im in doc['images']),(path,'external maps')
    count=0
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            assert 'TEXCOORD_0' in primitive['attributes']
            positions=doc['accessors'][primitive['attributes']['POSITION']]
            view=doc['bufferViews'][positions['bufferView']]
            start=view.get('byteOffset',0)+positions.get('byteOffset',0)
            stride=view.get('byteStride',12)
            assert all(math.isfinite(v) for i in range(positions['count']) for v in struct.unpack_from('<fff',blob,start+i*stride))
            count+=doc['accessors'][primitive['indices']]['count']//3
    for m in doc['materials']:
        assert 'normalTexture' in m and 'baseColorTexture' in m['pbrMetallicRoughness'] and 'metallicRoughnessTexture' in m['pbrMetallicRoughness'],(path,m['name'])
    assert 0<count<=18000,(path,count)
    triangles+=count
assert triangles<900000
print('PLANT_GROWTH_ASSETS: PASS',len(report),'species,',triangles,'triangles')
