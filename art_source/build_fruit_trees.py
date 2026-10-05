"""Focused fruit-tree rebuild; preserve other plants and the interactive Blender.
Run in an approved, separate Blender process with --background --python.
The standard botanical/growth builders also reproduce these organs.
"""
import bpy, sys, json, random, shutil, hashlib
from datetime import datetime
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'art_source'))
from botanical_geometry import Geometry
from botanical_detail import detail_geometry
from fruit_tree_geometry import FRUIT_TREES, fruit_palette, fruit_buds
import botanical_forms, botanical_expansion_forms
Detailed = detail_geometry(Geometry)
specs = json.loads((ROOT / 'art_source/plant_specs.json').read_text())
manifest_path = ROOT / 'art_source/botanical_manifest.json'
manifest = json.loads(manifest_path.read_text())
growth_path = ROOT / 'art_source/plant_growth_manifest.json'
growth_report = json.loads(growth_path.read_text())
selected = [i for i, row in enumerate(specs) if row[0] in FRUIT_TREES]
attachments = {}

# Never overwrite a source library or production export without a verified,
# persistent recovery copy. Each run has its own snapshot, excluded from imports.
backups = ROOT / 'captures/fruit-tree-review/rebuild-backup'
backups.mkdir(parents=True, exist_ok=True)
(backups / '.gdignore').touch()
snapshot = backups / datetime.now().strftime('%Y%m%d-%H%M%S-%f')
protected = [ROOT / 'art_source' / name for name in
             ['botanical_library.blend', 'botanical_expansion.blend', 'plant_growth.blend',
              'botanical_manifest.json', 'plant_growth_manifest.json']]
protected += [ROOT / 'assets/plants' / f'plant_{idx:02d}.glb' for idx in selected]
protected += [ROOT / 'assets/plants/growth' / f'growth_{idx:02d}.glb' for idx in selected]
for original in protected:
    backup = snapshot / original.relative_to(ROOT)
    backup.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(original, backup)
    assert hashlib.sha256(backup.read_bytes()).digest() == hashlib.sha256(original.read_bytes()).digest()
print('FRUIT_TREE_BACKUP: PASS', len(protected), 'verified recovery copies', flush=True)


def export(root, children, path):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [root, *children]:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = children[0]
    location = root.location.copy()
    root.location = (0, 0, 0)
    kwargs = dict(filepath=str(path), export_format='GLB', use_selection=True,
                  use_active_scene=True, export_yup=True, export_apply=True)
    props = bpy.ops.export_scene.gltf.get_rna_type().properties
    if 'export_vertex_color' in props:
        kwargs['export_vertex_color'] = 'ACTIVE'
    bpy.ops.export_scene.gltf(**kwargs)
    root.location = location


for filename in ['botanical_library.blend', 'botanical_expansion.blend']:
    path = ROOT / 'art_source' / filename
    bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    maps = {kind: [bpy.data.images.load(str(ROOT / 'assets/textures/botanical' / f'{kind}_{suffix}.png'), check_existing=True)
                  for suffix in ['color', 'normal', 'roughness']] for kind in ['fruit']}
    maps['fruit'][1].colorspace_settings.name = 'Non-Color'
    maps['fruit'][2].colorspace_settings.name = 'Non-Color'
    for idx in selected:
        if (idx < 60) != (filename == 'botanical_library.blend'):
            continue
        name = specs[idx][0]
        root = next(o for o in bpy.context.scene.objects if o.name.startswith(f'Plant_{idx:02d}_'))
        foliage = next(o for o in root.children if o.name.startswith('Foliage'))
        old_bloom = next(o for o in root.children if o.name.startswith('Bloom'))
        g, b = Detailed(name, 'foliage'), Detailed(name, 'bloom')
        random.seed(idx * 7381 + 69)
        if idx < 60:
            botanical_forms.tree(name, g, b, None)
        else:
            botanical_expansion_forms.tree(name, g, b)
        # Independent fruit randomness must not change the existing tree canopy.
        assert len(g.v) == len(foliage.data.vertices), (name, 'foliage vertex count changed')
        assert max((v.co - Vector(p)).length for v, p in zip(foliage.data.vertices, g.v)) < .00001, (name, 'foliage changed')
        palette = fruit_palette(name, list(old_bloom.data.materials), maps)
        bloom = b.object('BloomFruit', palette)
        bloom.parent = root
        bpy.data.objects.remove(old_bloom, do_unlink=True)
        export(root, [foliage, bloom], ROOT / 'assets/plants' / f'plant_{idx:02d}.glb')
        attachments[idx] = {'height': growth_report[idx]['height'],
                            'anchors': list({tuple(p) for p in b.fruit_anchors.values()}),
                            }
        manifest[idx]['vertices'] = len(foliage.data.vertices) + len(b.v)
        manifest[idx]['triangles'] = sum(len(p.vertices) - 2 for p in foliage.data.polygons) + sum(len(p) - 2 for p in b.f)
        print('FRUIT_TREE_EXPORT', idx, name, len(attachments[idx]['anchors']), flush=True)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(path))

# Keep seedlings and juveniles; replace only fruit buds at their real twig sites.
path = ROOT / 'art_source/plant_growth.blend'
bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
for idx in selected:
    root = next(o for o in bpy.context.scene.objects if o.name.startswith(f'Growth_{idx:02d}_'))
    old_buds = next(o for o in root.children if o.name.startswith('Buds'))
    buds = Detailed(specs[idx][0], 'bloom')
    data = attachments[idx]
    fruit_buds(data['anchors'], buds, data['height'])
    obj = buds.object('BudsFruit', list(old_buds.data.materials))
    obj.parent = root
    bpy.data.objects.remove(old_buds, do_unlink=True)
    children = list(root.children)
    export(root, children, ROOT / 'assets/plants/growth' / f'growth_{idx:02d}.glb')
    growth_report[idx]['triangles'] = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in children)
    print('FRUIT_BUD_EXPORT', idx, specs[idx][0], flush=True)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(path))
manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
growth_path.write_text(json.dumps(growth_report, indent=2) + '\n')
print('FRUIT_TREE_REBUILD: PASS', len(selected), 'trees and bud stages', flush=True)
