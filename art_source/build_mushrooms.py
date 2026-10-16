"""Build mushroom libraries for IDs 278–297, preserving existing assets and the interactive scene.

Run via an approved background Blender process. Uses the established botanical
mesh, packed PBR surface and local growth attachment exporters.
"""
import json
import math
import sys
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from build_full_plant_art import Surfaces, triangles
from fruit_tree_geometry import add_anchor_channels
from mushroom_data import MUSHROOMS
import mushroom_geometry
import mushroom_expansion_geometry


def build(expansion=False):
    module=mushroom_expansion_geometry if expansion else mushroom_geometry
    plants=[p for p in MUSHROOMS if (p[0]>=288)==expansion]
    previous=bpy.context.window.scene
    scene=bpy.data.scenes.new('ZendGarden_Mushrooms02' if expansion else 'ZendGarden_Mushrooms')
    bpy.context.window.scene=scene
    folder=ROOT/('captures/mushrooms-02/pigments' if expansion else 'captures/mushrooms/pigments');folder.mkdir(parents=True,exist_ok=True)
    (folder.parent/'.gdignore').touch()
    surfaces=Surfaces(folder)
    source='art_source/mushrooms_02.blend' if expansion else 'art_source/mushrooms.blend'
    mature={r['id']:r for r in json.loads((ROOT/'art_source/botanical_manifest.json').read_text())}
    growth={r['id']:r for r in json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())}
    manifest=ROOT/'art_source/mushroom_manifest.json'
    audit={r['id']:r for r in json.loads(manifest.read_text())} if manifest.exists() else {}
    def mesh(geo,name,palette,parent):
        obj=geo.object(name,palette);add_anchor_channels(obj.data,geo);obj.parent=parent
        return obj
    def export(root,organs,path):
        bpy.ops.object.select_all(action='DESELECT')
        for obj in [root,*organs]:obj.select_set(True)
        bpy.context.view_layer.objects.active=organs[0]
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_image_format='AUTO',export_vertex_color='ACTIVE',export_all_vertex_colors=False)
    try:
        for offset,(idx,name,botanical,color,height,days,form) in enumerate(plants):
            g,b,buds,seed,juv=module.geometry(idx)
            for geo in [g,b,buds,seed,juv]:
                assert geo.f and all(math.isfinite(v) for p in geo.v for v in p),(idx,'invalid geometry')
                assert all(0<=v<len(geo.v) for f in geo.f for v in f)
            mt=triangles(g)+triangles(b);gt=sum(triangles(x) for x in [buds,seed,juv])
            assert mt<60000 and gt<=18000,(idx,mt,gt)
            leaves,blooms=surfaces.palette(idx,module)
            root=bpy.data.objects.new(f'Plant_{idx}_{name}',None);scene.collection.objects.link(root)
            root['catalogue_id']=idx;root['botanical_name']=botanical
            organs=[mesh(g,'Foliage',leaves,root),mesh(b,'BloomFlower',blooms,root)]
            export(root,organs,ROOT/f'assets/plants/plant_{idx}.glb')
            young=bpy.data.objects.new(f'Growth_{idx}_{name}',None);scene.collection.objects.link(young)
            organs=[mesh(seed,'Seedling',leaves,young),mesh(juv,'Juvenile',leaves,young),mesh(buds,'BudsFlower',blooms,young)]
            export(young,organs,ROOT/f'assets/plants/growth/growth_{idx}.glb')
            mature[idx]={'id':idx,'name':name,'vertices':len(g.v)+len(b.v),'triangles':mt,'path':f'assets/plants/plant_{idx}.glb','source':source,'morphology_version':6}
            growth[idx]={'id':idx,'name':name,'family':'mushroom_'+form,'height':height,'triangles':gt,'source':source}
            audit[idx]={'id':idx,'name':name,'botanical_name':botanical,'form':form,'height':height,'mature_triangles':mt,'growth_triangles':gt,'source':source}
            root.location=(offset%5*.8,offset//5*1.3,0)
            young.location=root.location+Vector((0,.55,0))
            print('MUSHROOM_EXPORT',idx,name,mt,gt,flush=True)
        bpy.data.libraries.write(str(ROOT/source),{scene},fake_user=True,compress=True)
        for filename,records in [('botanical_manifest',mature),('plant_growth_manifest',growth)]:
            (ROOT/f'art_source/{filename}.json').write_text(json.dumps([records[k] for k in sorted(records)],indent=2)+'\n')
        manifest.write_text(json.dumps([audit[k] for k in sorted(audit)],indent=2)+'\n')
        (ROOT/'scripts/plant_profiles.gd').write_text('class_name GardenPlantProfiles\nextends RefCounted\n\n# Authored mature model heights in metres, measured during asset export.\nconst HEIGHTS='+json.dumps([growth[k]['height'] for k in sorted(growth)])+'\n')
        print('MUSHROOM_LIBRARY',source,flush=True)
    finally:
        bpy.context.window.scene=previous
        for path in folder.glob('*.jpg'):path.unlink()

if __name__=='__main__':
    if '--new-only' not in sys.argv:build()
    build(True)
