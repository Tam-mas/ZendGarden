"""Check the actual exported organs, anchors, botanical identities and textures."""
import json,struct,math,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from flower_additions_data import FLOWER_ADDITIONS

def glb(path):
    raw=path.read_bytes();assert raw[:4]==b'glTF',path
    length=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+length]),raw[28+length:]

def values(doc,blob,index):
    a=doc['accessors'][index];view=doc['bufferViews'][a['bufferView']]
    components={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    fmt,size={5126:('f',4),5123:('H',2),5121:('B',1)}[a['componentType']]
    stride=view.get('byteStride',size*components)
    offset=view.get('byteOffset',0)+a.get('byteOffset',0)
    result=[struct.unpack_from('<'+fmt*components,blob,offset+i*stride) for i in range(a['count'])]
    if a.get('normalized'):result=[tuple(v/(65535 if size==2 else 255) for v in point) for point in result]
    return result

specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
growth=json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())
assert len(specs)==len(growth)==218
assert [r['id'] for r in FLOWER_ADDITIONS]==list(range(148,218))
assert len(set(row[0] for row in specs))==218
assert all(r['references'] and r['scientific'] and r['notes'] for r in FLOWER_ADDITIONS)
assert sum((ROOT/'assets/textures/flower_additions'/n).stat().st_size for n in ['leaf.webp','orchid_petal.webp','orchid_sepal.webp'])<300000
for row in FLOWER_ADDITIONS:
    idx=row['id'];assert specs[idx][0]==row['name']
    for phase in ['mature','growth']:
        path=ROOT/'assets/plants'/f'plant_{idx:02d}.glb' if phase=='mature' else ROOT/'assets/plants/growth'/f'growth_{idx:02d}.glb'
        doc,blob=glb(path);all_positions=[];organs=[]
        assert doc.get('images') and all('bufferView' in im for im in doc['images'])
        for node in doc['nodes']:
            if 'mesh' not in node:continue
            organs.append(node['name'])
            for p in doc['meshes'][node['mesh']]['primitives']:
                points=values(doc,blob,p['attributes']['POSITION']);all_positions.extend(points)
                assert all(math.isfinite(v) for point in points for v in point)
                assert 'TEXCOORD_0' in p['attributes']
                if node['name'].startswith(('BloomFlower','BudsFlower')):
                    assert {'TEXCOORD_1','COLOR_0'}<=p['attributes'].keys(),(idx,'missing attached organ anchors')
                    uv2=values(doc,blob,p['attributes']['TEXCOORD_1'])
                    colors=values(doc,blob,p['attributes']['COLOR_0'])
                    for point,uv,color in zip(points,uv2,colors):
                        depth=(round(color[0]*255)*256+round(color[1]*255))/65535*16-8
                        anchor=(uv[0],1-uv[1],depth)
                        assert math.dist(point,anchor)<row['bloom_radius']*4,(idx,'surface UVs corrupted flower attachment data')
        assert all_positions
        if phase=='mature':
            assert any(n.startswith('Foliage') for n in organs) and any(n.startswith('BloomFlower') for n in organs)
            assert abs(max(p[1] for p in all_positions)-row['height'])<.002,(idx,'actual model height differs from sorting height')
        else:
            assert all(any(n.startswith(stage) for n in organs) for stage in ['Seedling','Juvenile','BudsFlower'])
        for m in doc['materials']:
            assert 'normalTexture' in m and 'baseColorTexture' in m['pbrMetallicRoughness'] and 'metallicRoughnessTexture' in m['pbrMetallicRoughness']
    assert abs(growth[idx]['height']-row['height'])<.001
    assert any((ROOT/'assets/ui/plants'/f'{idx:02d}{ext}').is_file() for ext in ['.webp','.png']),(idx,'missing actual model portrait')
print('FLOWER_ADDITION_ASSETS: PASS — 70 sourced plants, 140 models, attached buds and blooms, accurate heights, PBR maps and portraits')
