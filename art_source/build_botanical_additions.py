"""Build IDs 106–135 and revised climbers 9/10 in an isolated Blender library.
Optional -- --ids comma,separated filters exports, preserving other catalogue files.
"""
import bpy, json, random, sys
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import Geometry, material
from botanical_detail import texture_material, detail_geometry
from botanical_additions_data import ADDITIONS
from botanical_additions_forms import grasses, succulents, climber
scene=bpy.data.scenes.new('ZendGarden_BotanicalAdditions');bpy.context.window.scene=scene
maps={kind:[bpy.data.images.load(str(ROOT/'assets/textures/botanical'/f'{kind}_{suffix}.png'),check_existing=True) for suffix in ['color','normal','roughness']] for kind in ['leaf','petal','smooth','fruit','pollen']}
for images in maps.values():
    images[1].colorspace_settings.name='Non-Color';images[2].colorspace_settings.name='Non-Color'
cache={}
def mat(label,color,kind='fruit',wind=False):
    key=(label,color,kind,wind)
    if key not in cache:
        m=material(('Leaf ' if wind else 'Botanical ')+label,color)
        texture_material(m,kind,maps)
        # A restrained micro-normal prevents harsh vein shading on waxy organs and petals.
        next(n for n in m.node_tree.nodes if n.type=='NORMAL_MAP').inputs['Strength'].default_value=.15 if kind in ['fruit','petal'] else .35
        cache[key]=m
    return cache[key]
def longitudinal_stripe(m):
    im=next(n.image for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image.colorspace_settings.name=='sRGB')
    n=im.size[0];v,u=np.mgrid[0:n,0:n]/(n-1)
    pixels=np.array(im.pixels[:],dtype='float32').reshape(n,n,4)
    stripe=(np.sin(u*28)>.30)[:,:,None]
    pixels[:,:,:3]=np.where(stripe,pixels[:,:,:3]*np.array([.53,.70,.48]),pixels[:,:,:3])
    im.pixels.foreach_set(pixels.ravel());im.save();im.pack();return m
selected=None
if '--ids' in sys.argv:selected={int(x) for x in sys.argv[sys.argv.index('--ids')+1].split(',')}
manifest=json.loads((ROOT/'art_source/botanical_manifest.json').read_text())
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text());assert len(specs)>=136
Detailed=detail_geometry(Geometry)

def save(idx,name,g,b,palette,bloom_palette,notes):
    assert g.v and b.v,(idx,'empty organs')
    root=bpy.data.objects.new(f'Plant_{idx:02d}_{name}',None);scene.collection.objects.link(root)
    root['catalogue_id']=idx;root['botanical_notes']=notes
    foliage=g.object('Foliage',palette);foliage.parent=root
    bloom=b.object('Bloom',bloom_palette);bloom.parent=root
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [root,foliage,bloom]:obj.select_set(True)
    bpy.context.view_layer.objects.active=foliage
    path=ROOT/'assets/plants'/f'plant_{idx:02d}.glb'
    if selected is None or idx in selected:
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
    entry={'id':idx,'name':name,'vertices':len(g.v)+len(b.v),'triangles':sum(len(f)-2 for f in g.f+b.f),'path':str(path.relative_to(ROOT)),'morphology_version':3,'source':'art_source/botanical_additions.blend'}
    if idx<len(manifest):manifest[idx]=entry
    else:manifest.append(entry)
    root.location=(idx%8*4,(idx//8)*5,0)
    print('ADDITION_PLANT',idx,name,entry['triangles'],flush=True)

for idx,row in enumerate(ADDITIONS,106):
    name,scientific,color,layer,days,condition,animal,height,form=row;random.seed(idx*7381+69)
    grass=idx<116;g=Geometry();b=Geometry()
    body={'banded':'688647','reed':'5d774c','switch':'749794','forest':'d3c364','blood':'6a9251','moor':'687547','hair':'537349','quaking':'708950','sesleria':'a8b76c','muhly':'658256','barrel':'5f864d','star':'83937b','column':'4c795c','wool':'6c8a61','finger':'64834f','bunny':'879e5d','pear':'789571','holiday':'447550','snowball':'a6bfb8','lipstick':'a1b17b','hens':'91a375','aloe':'81a28e','agave':'8fa7a5','zebra':'3c664a','window':'789e75','jade':'4f8057','gollum':'73945e','aeonium':'492830','beans':'779a55','lithops':'a5806d'}[form]
    tip={'banded':'d9cc88','blood':'ae3d4d','lipstick':'a84946','hens':'9d535b','agave':'6a5944','beans':'b65749','lithops':'614b3b'}.get(form,'aa9e74')
    stem=mat(name+' stems','77875b' if grass else body if form in ['beans','holiday'] else '8d8170','smooth',grass)
    leaf=mat(name+' blades' if grass else name+' flesh',body,'leaf' if grass else 'fruit',grass)
    if form=='forest':longitudinal_stripe(leaf)
    young=mat(name+' young', 'bcceb2' if form=='window' else body,'leaf' if grass else 'fruit',grass)
    white=mat('old man white hairs' if form=='wool' else 'golden barrel spines' if form=='barrel' else 'fine ivory spines','e4e4d6' if form=='wool' else 'd9bc67' if form=='barrel' else 'd9d3ac','pollen')
    accent=mat(name+' tips',tip,'leaf' if grass else 'fruit',grass)
    palette=[stem,leaf,young,white,accent]
    bloom_color={'barrel':'e4c15c','bunny':'ecd18a','pear':'e6bd64','finger':'f0e6ce','star':'e0bd5c','holiday':'d96687','snowball':'e7939d','lipstick':'d77961','hens':'d8a7ab','aloe':'d7a34f','zebra':'e5dbbf','window':'e2d9bf','jade':'e6d1cd','gollum':'e9ddcd','beans':'e6c66c','lithops':'e5c359'}.get(form,color)
    primary=mat(name+' seedheads' if grass else name+' flowers',bloom_color,'petal',grass)
    pollen=mat('warm flower centre','d3a04f','pollen')
    bloom_palette=[primary,pollen,stem]
    if grass:grasses(form,height,g,b)
    else:succulents(form,height,g,b)
    save(idx,name,g,b,palette,bloom_palette,scientific+'; '+form+'; see botanical_additions_references.md')

# Reuse the old packed foliage pigments; source library is loaded read-only.
with bpy.data.libraries.load(str(ROOT/'art_source/botanical_library.blend'),link=False) as (src,dst):
    dst.objects=[n for n in src.objects if n.startswith(('Plant_09_','Plant_10_','Foliage','Bloom'))]
for idx in [9,10]:
    name=specs[idx][0];old=next(o for o in dst.objects if o and o.name.startswith(f'Plant_{idx:02d}_'))
    original=next(o for o in old.children if o.name.startswith('Foliage'))
    palette=list(original.data.materials)
    g=Detailed(name,'foliage');b=Geometry();random.seed(idx*7381+69);climber(name,g,b)
    primary=mat(name+' revised petals',specs[idx][2],'petal')
    cream=mat('Clematis fine cream stamens','e7debd','pollen')
    save(idx,name,g,b,palette,[primary,cream], 'Outward-facing flowers; explicit curved petals; see botanical_additions_references.md')
for obj in list(bpy.data.objects):
    if not obj.users_collection:bpy.data.objects.remove(obj)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/botanical_additions.blend'))
(ROOT/'art_source/botanical_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('BOTANICAL_ADDITIONS: PASS — 30 additions, revised Sweet pea and Clematis',flush=True)
