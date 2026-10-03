"""Catalogue compatibility and renderer contracts for botanical additions."""
import json, re, struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
rows=json.loads((ROOT/'art_source/plant_specs.json').read_text())
assert len(rows)==148
assert sum(row[1]=='Grasses' for row in rows)==36
assert sum(row[1]=='Cacti & succulents' for row in rows)==20
assert all(row[1]=='Grasses' for row in rows[106:116])
for i in [68,69,70,71,72,80]:
    assert rows[i][1]=='Grasses' and rows[i][3]==(3 if i==80 else 2), 'Bamboo category or placement layer changed incorrectly'
assert all(row[1]=='Cacti & succulents' for row in rows[116:136])
assert rows[9][0]=='Sweet pea' and rows[10][0]=='Clematis'
catalogue=(ROOT/'scripts/catalogue.gd').read_text()
literal=re.search(r'const ROWS\s*=\s*(\[.*?\n\])',catalogue,re.S).group(1)
assert json.loads(literal)==rows,'Source specification and runtime catalogue diverged'
for i in [9,10,*range(106,136)]:
    for folder,name in [('assets/plants',f'plant_{i:02d}.glb'),('assets/plants/growth',f'growth_{i:02d}.glb')]:
        path=ROOT/folder/name
        raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
        doc=json.loads(raw[20:20+length])
        assert all(m.get('alphaMode','OPAQUE')=='OPAQUE' for m in doc['materials']),(name,'Unexpected transparent surfaces')
        if i>=116:
            assert not any(m.get('name','').startswith('Leaf') for m in doc['materials']),(name,'Rigid succulent organs receive leaf wind')
        assert 'gltf/embedded_image_handling=2' in path.with_suffix('.glb.import').read_text(),(name,'Embedded images are not compressed')
    assert any((ROOT/f'assets/ui/plants/{i:02d}{ext}').exists() for ext in ['.png','.webp']),(i,'Portrait missing')
print('BOTANICAL_ADDITIONS_CHECK: PASS — ten grasses, twenty succulents, opaque flowers and rigid fleshy organs')
