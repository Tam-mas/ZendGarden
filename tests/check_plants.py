"""Validate all detailed botanical exports and optional pre-pass dimensions."""
import argparse,json,struct,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def inspect(path):
    raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+n]);binary=raw[28+n:]
    verts=[];triangles=0
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            triangles+=doc['accessors'][primitive['indices']]['count']//3
            assert 'TEXCOORD_0' in primitive['attributes'],(path,'missing UVs')
            a=doc['accessors'][primitive['attributes']['POSITION']]
            view=doc['bufferViews'][a['bufferView']]
            offset=view.get('byteOffset',0)+a.get('byteOffset',0)
            stride=view.get('byteStride',12)
            verts.extend(struct.unpack_from('<fff',binary,offset+i*stride) for i in range(a['count']))
    assert all(math.isfinite(x) for v in verts for x in v),(path,'invalid position')
    extent=[max(v[i] for v in verts)-min(v[i] for v in verts) for i in range(3)]
    return doc,triangles,extent

parser=argparse.ArgumentParser();parser.add_argument('--baseline',type=Path);args=parser.parse_args()
manifest=json.loads((ROOT/'art_source/botanical_manifest.json').read_text())
assert len(manifest)==218 and all(x['morphology_version']==3 for x in manifest),'Incomplete catalogue update'
assert [p['id'] for p in manifest]==list(range(218)), 'Plant IDs must remain contiguous'
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
assert [p['name'] for p in manifest]==[p[0] for p in specs], 'Source/catalogue ID mismatch'
report=[]
for plant in manifest:
    path=ROOT/'assets/plants'/f"plant_{plant['id']:02d}.glb"
    doc,tris,size=inspect(path)
    assert 0<tris<=200000,(plant['name'],'triangle budget',tris)
    assert all('bufferView' in im for im in doc['images']),(path,'external texture')
    for mat in doc['materials']:
        assert 'normalTexture' in mat,(plant['name'],mat['name'],'missing surface normal detail')
        pbr=mat['pbrMetallicRoughness']
        assert 'baseColorTexture' in pbr and 'metallicRoughnessTexture' in pbr,(plant['name'],'missing PBR textures')
    if args.baseline and (args.baseline/path.name).exists():
        _,old_tris,old_size=inspect(args.baseline/path.name)
        assert all(.65<new/old<1.4 for new,old in zip(size,old_size)),(plant['name'],'changed placement envelope',size,old_size)
    report.append((plant['name'],tris))
assert sum(x[1] for x in report[:60])<2600000, 'Original library geometry budget exceeded'
assert sum(x[1] for x in report[60:106])<3600000
assert sum(x[1] for x in report[106:136])<900000, 'New library geometry budget exceeded'
assert sum(x[1] for x in report[136:148])<250000, 'Low-grass geometry budget exceeded'
assert sum(x[1] for x in report[148:])<3000000, 'Flower collection geometry budget exceeded'
assert sum(x[1] for x in report)<10350000,'Whole-library geometry budget exceeded'
print('DETAILED_PLANT_ASSETS: PASS',json.dumps({'species':len(report),'triangles':sum(x[1] for x in report),'largest':max(report,key=lambda x:x[1]),'baseline_dimensions':bool(args.baseline)}))
