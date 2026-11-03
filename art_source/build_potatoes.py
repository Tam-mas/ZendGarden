"""Build the three potato varieties, their young stages and editable source."""
import json, math, sys
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import Geometry
from botanical_2026_geometry import leaf
from fruit_tree_geometry import mark_anchor, add_anchor_channels
from build_full_plant_art import Surfaces, triangles

VARIETIES=[(299,"Potato 'Kennebec'",'d5bc8b','f5f0e4'),(300,"Potato 'Red Pontiac'",'b85e58','e6c2d8'),(301,"Potato 'Purple Majesty'",'765887','b29acc')]

def foliage(scale=1, count=5):
 g=Geometry()
 for i in range(count):
  a=i*math.tau/count+.18; d=Vector((math.cos(a),math.sin(a),0)); base=Vector((0,0,.015))*scale; tip=d*.15*scale+Vector((0,0,(.48+i%2*.06)*scale))
  g.tube([base,tip*.52,tip],[.009*scale,.006*scale,.002*scale],0,7)
  for j in range(3):
   p=base.lerp(tip,.35+j*.22)
   for sign in [-1,1]:leaf(g,p,a+sign*1.0,(.16-j*.015)*scale,.043*scale,1,lift=.15)
  leaf(g,tip,a,.13*scale,.04*scale,1,lift=.14)
 return g

def tubers(scale=1):
 g=Geometry()
 for i in range(4):
  a=i*math.tau/4+.3; c=(math.cos(a)*.12,math.sin(a)*.12,.025)
  start=len(g.v);g.ellipsoid(c,(.074*scale,.052*scale,.042*scale),0,10,16)
  mark_anchor(g,start,c)
 return g

def build():
 previous=bpy.context.window.scene;scene=bpy.data.scenes.new('ZendGarden_Potatoes');bpy.context.window.scene=scene
 folder=ROOT/'captures/potatoes/pigments';folder.mkdir(parents=True,exist_ok=True);(folder.parent/'.gdignore').touch();surfaces=Surfaces(folder)
 manifests={name:{r['id']:r for r in json.loads((ROOT/f'art_source/{name}.json').read_text())} for name in ['botanical_manifest','plant_growth_manifest']}
 try:
  for idx,name,color,flower in VARIETIES:
   class Palette:
    @staticmethod
    def palette(_):return {'foliage':[('potato stems','63824f','leaf',True),('potato leaf','779c5f','leaf',True),('potato veins','9eb57b','leaf',True)],'bloom':[('potato skin',color,'smooth',False)]}
   leaves,harvest=surfaces.palette(idx,Palette)
   mature=foliage();fruit=tubers();seed=foliage(.22,2);young=foliage(.50,3);buds=tubers(.62)
   def mesh(geo,label,palette,parent):
    obj=geo.object(label,palette);add_anchor_channels(obj.data,geo);obj.parent=parent;return obj
   def export(parent,organs,path):
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [parent,*organs]:obj.select_set(True)
    bpy.context.view_layer.objects.active=organs[0]
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_image_format='AUTO',export_vertex_color='ACTIVE',export_all_vertex_colors=False)
   root=bpy.data.objects.new('Plant_'+str(idx),None);scene.collection.objects.link(root);root['catalogue_id']=idx;root['botanical_name']='Solanum tuberosum'
   export(root,[mesh(mature,'Foliage',leaves,root),mesh(fruit,'BloomFruit',harvest,root)],ROOT/f'assets/plants/plant_{idx}.glb')
   growth=bpy.data.objects.new('Growth_'+str(idx),None);scene.collection.objects.link(growth)
   export(growth,[mesh(seed,'Seedling',leaves,growth),mesh(young,'Juvenile',leaves,growth),mesh(buds,'BudsFruit',harvest,growth)],ROOT/f'assets/plants/growth/growth_{idx}.glb')
   root.location.x=(idx-299)*.8;growth.location.x=(idx-299)*.8;growth.location.y=.8
   manifests['botanical_manifest'][idx]={'id':idx,'name':name,'vertices':len(mature.v)+len(fruit.v),'triangles':triangles(mature)+triangles(fruit),'path':f'assets/plants/plant_{idx}.glb','source':'art_source/potatoes.blend','morphology_version':7}
   manifests['plant_growth_manifest'][idx]={'id':idx,'name':name,'family':'potato_tuber','height':.55,'triangles':sum(triangles(x) for x in [seed,young,buds]),'source':'art_source/potatoes.blend'}
  bpy.data.libraries.write(str(ROOT/'art_source/potatoes.blend'),{scene},fake_user=True,compress=True)
  for filename,records in manifests.items():(ROOT/f'art_source/{filename}.json').write_text(json.dumps([records[k] for k in sorted(records)],indent=2)+'\n')
  (ROOT/'scripts/plant_profiles.gd').write_text('class_name GardenPlantProfiles\nextends RefCounted\n\n# Authored mature model heights in metres, measured during asset export.\nconst HEIGHTS='+json.dumps([r['height'] for r in manifests['plant_growth_manifest'].values()])+'\n')
  print('POTATO_EXPORT: PASS',flush=True)
 finally:
  bpy.context.window.scene=previous
  for path in folder.glob('*.jpg'):path.unlink()
if __name__=='__main__':build()
