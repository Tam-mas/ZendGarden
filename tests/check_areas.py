"""Check exported habitats, independent collection meshes and connected height grids."""
import json, math, struct, hashlib, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
layout=json.loads((ROOT/'assets/areas/layout.json').read_text())
assert layout['version']==1 and len(layout['areas'])==10 and len(layout['specialties'])==18
hashes=set();triangles=0
for area in layout['areas']:
    grid=area['heightmap']
    assert len(grid)==25 and all(len(row)==25 for row in grid)
    assert all(math.isfinite(h) and -2<h<8 for row in grid for h in row)
    # Authored boundaries meet the next trail without gaps or a vertical wall.
    assert all(abs(h-1.2)<.01 for h in grid[0]+grid[-1]+[row[0] for row in grid]+[row[-1] for row in grid])
    for slot in area['slots']:
        assert len(slot['pos'])==2 and all(-12<v<12 for v in slot['pos'])
for path in sorted((ROOT/'assets/areas').rglob('*.glb')):
    raw=path.read_bytes();assert raw[:4]==b'glTF'
    n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);binary=raw[28+n:]
    digest=hashlib.sha256(raw).hexdigest();assert digest not in hashes, f'Duplicate landscape or species: {path}'
    hashes.add(digest)
    count=0
    for mesh in doc['meshes']:
        for p in mesh['primitives']:
            attrs=p['attributes'];assert {'POSITION','NORMAL','TEXCOORD_0'}<=attrs.keys(),path
            count+=doc['accessors'][p['indices']]['count']//3
            for channel,width in [('POSITION',3),('NORMAL',3),('TEXCOORD_0',2)]:
                a=doc['accessors'][attrs[channel]];v=doc['bufferViews'][a['bufferView']]
                start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',4*width)
                assert all(all(math.isfinite(x) for x in struct.unpack_from('<'+'f'*width,binary,start+i*stride)) for i in range(a['count'])),(path,channel)
            assert 'pbrMetallicRoughness' in doc['materials'][p['material']],path
    assert 0<count<=(250000 if path.parent.name=='areas' else 120000), (path,count)
    assert all('bufferView' in im and 'uri' not in im for im in doc.get('images',[])),(path,'external image')
    assert path.with_suffix('.glb.import').is_file(),(path,'missing import settings')
    assert 'gltf/embedded_image_handling=2' in path.with_suffix('.glb.import').read_text(),path
    if path.parent.name=='areas':
        assert any(node.get('extras',{}).get('area_ground') for node in doc['nodes']), (path,'missing editable terrain')
        assert doc.get('images'), (path,'missing surface textures')
        rocks=[node['extras']['footprint'] for node in doc['nodes'] if 'footprint' in node.get('extras',{})]
        anchors=[node for node in doc['nodes'] if 'area_species' in node.get('extras',{})]
        for node in anchors:
            x,_,z=node.get('translation',[0,0,0])
            assert all(((x-rx)/rw)**2+((z-rz)/rd)**2>=1 for rx,rz,rw,rd in rocks), (path,'plant rooted inside stone',node['name'])
    else:
        assert any(node['name'].startswith('Leaves') for node in doc['nodes']),path
        assert doc.get('images'), (path,'missing botanical PBR textures')
        assert all(any(node['name'].startswith(stage) for node in doc['nodes']) for stage in ['Seedling','Juvenile','Buds']), (path,'missing anatomical growth stages')
        assert any(m.get('normalTexture') for m in doc['materials']), (path,'missing leaf relief')
        assert any(node['name'].startswith('Flowers') for node in doc['nodes']),path
    triangles+=count
assert len(hashes)==28 and triangles<1200000
with wave.open(str(ROOT/'assets/audio/alpine_chime.wav')) as audio:
    assert audio.getnchannels()==1 and audio.getsampwidth()==2 and audio.getframerate()==22050
    frames=audio.readframes(audio.getnframes());samples=struct.unpack('<'+'h'*(len(frames)//2),frames)
    assert max(abs(s) for s in samples)<6000 and max(abs(s) for s in samples[-2205:])<300
print(f'AREA_ASSETS_RESULT: PASS — 10 distinct habitats, 18 collection plants, {triangles:,} triangles, packed textures and a quiet chime')
