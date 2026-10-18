"""Packed lighting exports, material coverage and runtime asset budgets."""
import json
import math
from pathlib import Path
from check_plant_art_full import read_glb, accessor

ROOT = Path(__file__).resolve().parents[1]
records = json.loads((ROOT / 'art_source/night_lighting_manifest.json').read_text())
assert [row['kind'] for row in records] == ['torch', 'path_lantern', 'garden_lamppost', 'garden_floodlight']
for record in records:
    path = ROOT / record['path']
    assert (ROOT / record['source']).is_file()
    doc, blob = read_glb(path)
    assert not doc.get('extensions', {}).get('KHR_lights_punctual'), 'Lights belong to the runtime manager'
    assert all('bufferView' in image for image in doc['images']), 'Unpacked lighting texture'
    assert 'gltf/embedded_image_handling=2' in path.with_suffix('.glb.import').read_text()
    assert any(any(mat.get('emissiveFactor', [])) for mat in doc['materials']), 'Missing luminous diffuser'
    for mat in doc['materials']:
        assert len(mat['pbrMetallicRoughness']['baseColorFactor']) == 4, 'Lost authored pigment multiplier'
        assert {'baseColorTexture', 'metallicRoughnessTexture'} <= mat['pbrMetallicRoughness'].keys()
        assert 'normalTexture' in mat
    triangles = 0
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            assert {'POSITION', 'NORMAL', 'TEXCOORD_0'} <= primitive['attributes'].keys()
            points = accessor(doc, blob, primitive['attributes']['POSITION'])
            assert all(math.isfinite(value) for point in points for value in point)
            triangles += doc['accessors'][primitive['indices']]['count'] // 3
    assert triangles == record['triangles'] < 20000, (record['kind'], triangles)
    folder = 'tools' if record['kind'] == 'torch' else 'shop'
    assert (ROOT / f'assets/ui/{folder}/{record["kind"]}.webp').is_file()
    if folder == 'shop':
        assert (ROOT / f'assets/shop/{record["kind"]}.tscn').is_file()
print('NIGHT_LIGHTING_ASSETS: PASS — four packed models, PBR maps, portraits and bounded geometry')
