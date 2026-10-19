"""Export garlic with packed botanical PBR maps in an approved Blender subprocess."""
import json
import sys
from pathlib import Path
import bpy
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
import garlic_geometry as garlic
from build_full_plant_art import Surfaces, triangles
from fruit_tree_geometry import add_anchor_channels


def build():
    previous=bpy.context.window.scene;scene=bpy.data.scenes.new('ZendGarden_Garlic');bpy.context.window.scene=scene
    folder=ROOT/'captures/garlic/pigments';folder.mkdir(parents=True,exist_ok=True);(folder.parent/'.gdignore').touch()
    surfaces=Surfaces(folder)
    try:
        foliage,bulb,buds,seedling,juvenile=garlic.geometry();leaves,harvest=surfaces.palette(garlic.ID,garlic)
        def mesh(geo,name,palette,parent):
            obj=geo.object(name,palette);add_anchor_channels(obj.data,geo);obj.parent=parent;return obj
        def export(root,organs,path):
            bpy.ops.object.select_all(action='DESELECT')
            for obj in [root,*organs]:obj.select_set(True)
            bpy.context.view_layer.objects.active=organs[0]
            bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,
                export_yup=True,export_apply=True,export_image_format='AUTO',export_vertex_color='ACTIVE',export_all_vertex_colors=False)
        root=bpy.data.objects.new('Plant_298_Garlic',None);scene.collection.objects.link(root)
        root['catalogue_id']=garlic.ID;root['botanical_name']='Allium sativum'
        export(root,[mesh(foliage,'Foliage',leaves,root),mesh(bulb,'BloomFruit',harvest,root)],ROOT/'assets/plants/plant_298.glb')
        young=bpy.data.objects.new('Growth_298_Garlic',None);scene.collection.objects.link(young)
        export(young,[mesh(seedling,'Seedling',leaves,young),mesh(juvenile,'Juvenile',leaves,young),mesh(buds,'BudsFruit',harvest,young)],ROOT/'assets/plants/growth/growth_298.glb')
        young.location.x=.6
        bpy.data.libraries.write(str(ROOT/'art_source/garlic.blend'),{scene},fake_user=True,compress=True)
        source='art_source/garlic.blend'
        for filename,record in [
            ('botanical_manifest',{'id':298,'name':'Garlic','vertices':len(foliage.v)+len(bulb.v),'triangles':triangles(foliage)+triangles(bulb),'path':'assets/plants/plant_298.glb','source':source,'morphology_version':7}),
            ('plant_growth_manifest',{'id':298,'name':'Garlic','family':'allium_bulb','height':garlic.HEIGHT,'triangles':sum(triangles(g) for g in [buds,seedling,juvenile]),'source':source})]:
            path=ROOT/f'art_source/{filename}.json';records={r['id']:r for r in json.loads(path.read_text())};records[298]=record
            path.write_text(json.dumps([records[k] for k in sorted(records)],indent=2)+'\n')
        records=json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())
        (ROOT/'scripts/plant_profiles.gd').write_text('class_name GardenPlantProfiles\nextends RefCounted\n\n# Authored mature model heights in metres, measured during asset export.\nconst HEIGHTS='+json.dumps([r['height'] for r in records])+'\n')
        print('GARLIC_EXPORT: PASS',triangles(foliage)+triangles(bulb),sum(triangles(g) for g in [buds,seedling,juvenile]),flush=True)
    finally:
        bpy.context.window.scene=previous
        for path in folder.glob('*.jpg'):path.unlink()


if __name__=='__main__':build()
