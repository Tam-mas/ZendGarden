"""Audit botanical contrasts on exported shrub meshes, not only source presets."""
import json, math, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def read(path):
    raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
    return json.loads(raw[20:20+length]),raw[28+length:]

def values(doc,blob,index):
    accessor=doc['accessors'][index];view=doc['bufferViews'][accessor['bufferView']]
    n={'VEC2':2,'VEC3':3,'VEC4':4}[accessor['type']]
    fmt,size={5126:('f',4),5123:('H',2),5121:('B',1)}[accessor['componentType']]
    stride=view.get('byteStride',size*n);offset=view.get('byteOffset',0)+accessor.get('byteOffset',0)
    result=[struct.unpack_from('<'+fmt*n,blob,offset+i*stride) for i in range(accessor['count'])]
    if accessor.get('normalized'):result=[tuple(v/(65535 if size==2 else 255) for v in p) for p in result]
    return result

records={};leaf_textures=set()
for idx in range(198,218):
    doc,blob=read(ROOT/'assets/plants'/f'plant_{idx}.glb')
    positions=[];anchors=set();leaves=[]
    for node in doc['nodes']:
        if 'mesh' not in node:continue
        for primitive in doc['meshes'][node['mesh']]['primitives']:
            points=values(doc,blob,primitive['attributes']['POSITION']);positions+=points
            if node['name'].startswith('BloomFlower'):
                uv=values(doc,blob,primitive['attributes']['TEXCOORD_1']);colors=values(doc,blob,primitive['attributes']['COLOR_0'])
                for t,c in zip(uv,colors):
                    depth=(round(c[0]*255)*256+round(c[1]*255))/65535*16-8
                    anchors.add(tuple(round(v,4) for v in (t[0],1-t[1],depth)))
            else:
                mat=doc['materials'][primitive['material']]
                if mat['name'].startswith('Leaf '):
                    leaves+=points
                    image_index=doc['textures'][mat['pbrMetallicRoughness']['baseColorTexture']['index']]['source']
                    image=doc['images'][image_index];view=doc['bufferViews'][image['bufferView']]
                    start=view.get('byteOffset',0);leaf_textures.add(blob[start:start+view['byteLength']])
    bounds=[max(v[i] for v in positions)-min(v[i] for v in positions) for i in range(3)]
    records[idx]={'ratio':max(bounds[0],bounds[2])/max(v[1] for v in positions),'blooms':len(anchors),'leaf_points':len(leaves)}

# Contrasting real habits: fountain / dense cushion versus narrow, upright fine foliage.
assert records[207]['ratio']>1.8,('Spirea lost its wide cascading habit',records[207])
assert records[210]['ratio']>1.6,('Hebe lost its broad cushion habit',records[210])
assert records[215]['ratio']<1.2 and records[216]['ratio']<1.15,'Upright fine shrubs became generic rounded bushes'
assert records[207]['ratio']>records[216]['ratio']*1.7
assert records[199]['leaf_points']>records[205]['leaf_points']*5,'Forsythia should flower along nearly bare canes'
assert records[213]['leaf_points']>records[216]['leaf_points']*1.5,'Choisya must keep its larger three-leaflet foliage'
assert len(leaf_textures)>=18,'Species foliage pigments became identical'
assert records[198]['blooms']==24 and records[201]['blooms']==21
assert records[200]['blooms']>=175,'Pieris lost its many hanging urns'
assert records[205]['blooms']>=175 and records[216]['blooms']>=150,'Blossoms must line the wood'
assert records[210]['blooms']==30,'Hebe flowers must form separate complete racemes'
assert len({(round(r['ratio'],2),r['blooms']) for r in records.values()})==20
print('BUSH_VARIATION_ASSETS: PASS — 20 contrasting silhouettes, leaf pigments, flower heads and branch flowering')
