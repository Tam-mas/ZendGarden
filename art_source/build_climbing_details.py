"""Small botanical organs for support growth, using the existing petal forms.

Run in background Blender; this never opens or saves an interactive project.
Textures are shared with the planted species at runtime, not embedded again.
"""
import bpy, json, sys, math
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import Geometry, material
from botanical_detail import detail_geometry
from botanical_additions_forms import clematis_flower, sweet_pea_flower, petal

scene=bpy.data.scenes.new('ZendGarden_ClimbingDetails')
bpy.context.window.scene=scene
folder=ROOT/'assets/plants/climbing'
folder.mkdir(parents=True,exist_ok=True)
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
Detailed=detail_geometry(Geometry)
manifest=[]
for idx in [9,10,52,56,60,61]:
    name=specs[idx][0]
    leaf=Detailed(name,'foliage')
    count=3 if idx==10 else 2
    for i in range(count):
        angle=(i/(count-1)-.5)*1.5
        tip=Vector((math.cos(angle)*.14,math.sin(angle)*.14,.035))
        leaf.leaf(Vector(),tip,.045,0,.12,6)
    foliage=leaf.object('SupportLeaves',[material('Leaf support foliage','678557')])
    flower=Geometry()
    center=Vector((.15,0,0))
    if idx==10:
        clematis_flower(flower,center,.085)
    elif idx in [9,52]:
        sweet_pea_flower(flower,center,.05 if idx==9 else .032)
    else:
        normal=Vector((1,0,.20)).normalized()
        right=Vector((0,1,0));up=normal.cross(right)
        size=.045 if idx==56 else .023
        for j in range(5):
            a=j*math.tau/5
            direction=right*math.cos(a)+up*math.sin(a)
            tangent=-right*math.sin(a)+up*math.cos(a)
            petal(flower,center,direction,tangent,normal,size,size*.30,0,idx==56)
        flower.ellipsoid(center+normal*.004,(.005,.005,.005),1,4,6)
    flower.v=[tuple(Vector(v)-center) for v in flower.v]
    tint='e8c452' if idx==56 else 'f2edde' if idx in [52,60,61] else specs[idx][2]
    bloom=flower.object('SupportFlower',[material('Support petals',tint),material('Support stamens','e7debd')])
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [foliage,bloom]:obj.select_set(True)
    bpy.context.view_layer.objects.active=foliage
    path=folder/f'climber_{idx:02d}.glb'
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
    manifest.append({'id':idx,'name':name,'path':str(path.relative_to(ROOT)),'triangles':sum(len(f)-2 for f in leaf.f+flower.f)})
    scene.collection.objects.unlink(foliage);scene.collection.objects.unlink(bloom)
(ROOT/'art_source/climbing_details_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('CLIMBING_DETAILS: PASS',flush=True)
