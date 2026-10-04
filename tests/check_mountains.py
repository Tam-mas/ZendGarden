"""Validate the exported terrain, shoreline and optional unchanged garden baseline."""
import argparse, hashlib, json, math, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def glb(path):
    data=path.read_bytes();length=struct.unpack_from('<I',data,12)[0]
    doc=json.loads(data[20:20+length]);offset=20+length
    binary=data[offset+8:]
    def accessor(index):
        a=doc['accessors'][index];view=doc['bufferViews'][a['bufferView']]
        kind={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        count={'VEC3':3,'SCALAR':1}[a['type']]
        fmt='<'+kind*count; width=struct.calcsize(fmt)
        start=view.get('byteOffset',0)+a.get('byteOffset',0);stride=view.get('byteStride',width)
        return [struct.unpack_from(fmt,binary,start+i*stride) for i in range(a['count'])]
    return doc,accessor

def named_mesh(doc,name):
    return next(doc['meshes'][n['mesh']] for n in doc['nodes'] if n.get('name')==name and 'mesh' in n)

def positions(doc,accessor,name):
    return [v for p in named_mesh(doc,name)['primitives'] for v in accessor(p['attributes']['POSITION'])]

def triangle_signature(doc,read,name):
    digest=hashlib.sha256()
    for primitive in named_mesh(doc,name)['primitives']:
        points=read(primitive['attributes']['POSITION'])
        normals=read(primitive['attributes']['NORMAL'])
        for (index,) in read(primitive['indices']):
            digest.update(struct.pack('<6f',*points[index],*normals[index]))
    return digest.hexdigest()

parser=argparse.ArgumentParser();parser.add_argument('--baseline',type=Path);args=parser.parse_args()
path=ROOT/'assets/environment/lake_garden.glb';doc,accessor=glb(path)
for node in doc['nodes']:
    if node.get('name','').startswith('ForestChunk_'):
        assert doc['meshes'][node['mesh']].get('name')==node['name'],('Stale imported forest resource name',node['name'])
report={}
for name,budget in [('AlpineLakeValley',500000),('OuterMountainRidges',50000)]:
    mesh=named_mesh(doc,name)
    triangles=sum(doc['accessors'][p['indices']]['count']//3 for p in mesh['primitives'])
    assert all(set(p['attributes'])=={'POSITION','NORMAL'} for p in mesh['primitives']), (name,'unused terrain channels exported')
    verts=positions(doc,accessor,name)
    assert 0<triangles<=budget,(name,'triangle budget',triangles)
    assert all(math.isfinite(x) for v in verts for x in v),(name,'non-finite vertices')
    assert max(v[1] for v in verts)>450,(name,'missing high relief')
    normals=[v for p in mesh['primitives'] for v in accessor(p['attributes']['NORMAL'])]
    assert min(n[1] for n in normals)>0,(name,'inverted terrain normals')
    report[name]={'triangles':triangles,'highest_point':round(max(v[1] for v in verts),2)}
lake=positions(doc,accessor,'ContourLake')
assert lake and all(abs(v[1]+39)<.001 for v in lake),'Lake height changed'
validation=json.loads((ROOT/'art_source/landscape_validation.json').read_text())
assert validation['minimum_boundary_height']>validation['lake_level']+20,'Open shoreline at terrain edge'
assert validation['southern_forest_sections']>=10,'Southern woodland missing'
assert validation['forest_trees']>=20000, 'Background woodland is too sparse'
assert min(validation['added_forest_by_direction'].values())>=1000, 'Woodland expansion missing a direction'
forest_triangles=sum(doc['accessors'][p['indices']]['count']//3 for node in doc['nodes'] if node.get('name','').startswith('ForestChunk_') for p in doc['meshes'][node['mesh']]['primitives'])
assert forest_triangles==validation['forest_triangles'], 'Stale forest export metadata'
assert forest_triangles<1800000, 'Forest geometry budget exceeded'
report['woodland']={'trees':validation['forest_trees'],'triangles':forest_triangles}
assert path.stat().st_size<95*1024*1024,'Landscape exceeded previous 98 MiB asset budget'
if args.baseline:
    before,read_before=glb(args.baseline)
    # Include the detailed shed parts actually present in the supplied baseline.
    names=[n['name'] for n in before['nodes'] if 'mesh' in n]
    assert set(names)=={n['name'] for n in doc['nodes'] if 'mesh' in n}
    for name in names:
        assert triangle_signature(doc,accessor,name)==triangle_signature(before,read_before,name),('Rendered positions, winding or normals changed',name)
    report['all_rendered_geometry']='byte-identical triangle positions and normals to baseline'
print('MOUNTAIN_ASSET_CHECK: PASS '+json.dumps(report))
