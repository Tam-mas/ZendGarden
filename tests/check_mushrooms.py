"""Mushroom export coverage, attachment, packed-map and growth contracts."""
import hashlib
import json
import math
import re
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from mushroom_data import MUSHROOMS
import check_plant_art_full as glb

specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
catalogue=(ROOT/'scripts/catalogue.gd').read_text()
assert len(specs)==288
assert json.loads(re.search(r'const ROWS\s*=\s*(\[.*?\n\])',catalogue,re.S)[1])==specs
heights=json.loads((ROOT/'scripts/plant_profiles.gd').read_text().split('const HEIGHTS=')[1])
assert len(heights)==288
manifest=json.loads((ROOT/'art_source/mushroom_manifest.json').read_text())
assert [r['id'] for r in manifest]==list(range(278,288))
assert len({r['form'] for r in manifest})==10
mt=gt=0
for data,record in zip(MUSHROOMS,manifest):
    idx,name,botanical,color,height,days,form=data
    assert specs[idx]==[name,'Mushrooms',color,0,days,'shade','none']
    assert (ROOT/record['source']).is_file()
    mature=glb.inspect(ROOT/f'assets/plants/plant_{idx}.glb',idx)
    growth=glb.inspect(ROOT/f'assets/plants/growth/growth_{idx}.glb',idx,True)
    glb.verify_sites(idx,mature,growth)
    assert abs(mature['bounds']['max'][1]-height)<.001,(name,'height')
    assert heights[idx]==height
    assert mature['bounds']['min'][1]>=-.025,(name,'buried model')
    assert mature['triangles']==record['mature_triangles']<60000
    assert growth['triangles']==record['growth_triangles']<=18000
    mt+=mature['triangles'];gt+=growth['triangles']
    for kind,folder in [('plant','assets/plants'),('growth','assets/plants/growth')]:
        path=ROOT/f'{folder}/{kind}_{idx}.glb'
        doc,blob=glb.read_glb(path)
        assert all('bufferView' in image for image in doc['images'])
        assert 'gltf/embedded_image_handling=2' in path.with_suffix('.glb.import').read_text()
        for mat in doc['materials']:
            assert not mat['name'].startswith('Leaf'),(name,'rigid fungus has leaf wind')
            assert 'normalTexture' in mat
            assert {'baseColorTexture','metallicRoughnessTexture'}<=mat['pbrMetallicRoughness'].keys()
        if kind=='growth':
            sizes={}
            for node in doc['nodes']:
                if 'mesh' not in node:continue
                pts=[p for primitive in doc['meshes'][node['mesh']]['primitives'] for p in glb.accessor(doc,blob,primitive['attributes']['POSITION'])]
                sizes[node['name'].split('.')[0]]=max(p[1] for p in pts)
            assert 0<sizes['Seedling']<sizes['Juvenile']<height*.75,(name,'independent young stages',sizes)
    assert any((ROOT/f'assets/ui/plants/{idx}{ext}').is_file() for ext in ['.webp','.png']),(name,'missing portrait')
# A local pre-build snapshot also verifies old exports remained byte-identical.
baseline=ROOT/'captures/mushrooms/existing_asset_hashes.json'
if baseline.exists():
    for path,digest in json.loads(baseline.read_text()).items():
        assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,(path,'legacy model changed')
assert mt<350000 and gt<180000
print('MUSHROOM_ASSETS: PASS — 10 species;',mt,'mature triangles;',gt,'growth triangles; packed maps and local caps')
