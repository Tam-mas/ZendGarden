"""Build only IDs 60–105 in an isolated, editable Blender source library.
Run: Blender --background --python art_source/build_botanical_expansion.py
Optional -- --ids 60,61 filters exports for visual iteration (still builds source).
"""
import bpy, json, sys, random, math
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import Geometry, material
from botanical_detail import texture_material, detail_geometry
from botanical_expansion_forms import build
scene=bpy.data.scenes.new('ZendGarden_BotanicalExpansion')
bpy.context.window.scene=scene
maps={kind:[bpy.data.images.load(str(ROOT/'assets/textures/botanical'/f'{kind}_{suffix}.png'),check_existing=True) for suffix in ['color','normal','roughness']] for kind in ['leaf','petal','bark','smooth','fruit','pollen']}
for images in maps.values():
    images[1].colorspace_settings.name='Non-Color';images[2].colorspace_settings.name='Non-Color'
Detailed=detail_geometry(Geometry)
cache={}
def mat(label,color,kind):
    key=(label,color,kind)
    if key not in cache:
        m=material(('Leaf Expansion ' if kind=='leaf' else 'Expansion ')+label,color);texture_material(m,kind,maps);cache[key]=m
    return cache[key]

def pigment(m,style):
    """Bake botanical colour fields into the glTF-compatible albedo texture."""
    node=next(n for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image and n.image.colorspace_settings.name=='sRGB')
    im=node.image;n=im.size[0];v,u=np.mgrid[0:n,0:n]/(n-1)
    rgba=np.array(im.pixels[:],dtype='float32').reshape(n,n,4)
    if style=='stripe':
        field=np.sin(u*51+np.sin(v*17)*1.2)+.55*np.sin(u*107+v*11)
        mask=np.clip((field-.20)*3,0,1)
        rgba[:,:,:3]=rgba[:,:,:3]*(1-mask[:,:,None])+np.array([.94,.86,.73])[None,None,:]*mask[:,:,None]
    elif style=='gum':
        f=np.sin(u*17+np.sin(v*12)*1.7)+np.sin(v*19-u*8)*.7
        palette=np.array([[.45,.49,.42],[.68,.70,.59],[.84,.82,.73],[.57,.57,.54]],dtype='float32')
        index=np.clip(((f+1.7)/3.4*4).astype(int),0,3)
        rgba[:,:,:3]=palette[index]*(.96+.04*np.sin(u*153+v*34))[:,:,None]
    elif style=='blush':
        mask=np.clip(.5+.45*np.sin(u*7+np.sin(v*5))+.07*np.sin(u*87+v*13),0,1)
        rgba[:,:,:3]=rgba[:,:,:3]*(1-mask[:,:,None]*.6)+np.array([.68,.14,.10])[None,None,:]*mask[:,:,None]*.6
    elif style=='fan':
        ribs=.83+.14*(.5+.5*np.sin(u*95))+.03*np.sin(u*190+v*40)
        rgba[:,:,:3]*=ribs[:,:,None]
    im.pixels.foreach_set(rgba.ravel());im.save();im.unpack(method='REMOVE');im.reload();im.pack()
    if style in ['gum','fan']:
        normal=next(n for n in m.node_tree.nodes if n.type=='NORMAL_MAP');normal.inputs['Strength'].default_value=.25
    return m

stem=mat('living stem','50723b','smooth')
leaf=mat('leaf green','4a7639','leaf');young=mat('new leaves','70934a','leaf');dark=mat('glossy foliage','315b32','leaf');silver=mat('glaucous foliage','829a88','leaf')
bark=mat('branch bark','74624b','bark');smooth=pigment(mat('mottled snow gum bark','c7c4ad','smooth'),'gum');sheath=mat('dry sheaths','b7a57b','bark')
pollen=mat('anthers','d9b445','pollen');cream=mat('ivory buds','f5edda','petal')
selected=None
if '--ids' in sys.argv:selected={int(i) for i in sys.argv[sys.argv.index('--ids')+1].split(',')}
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text());old_manifest=json.loads((ROOT/'art_source/botanical_manifest.json').read_text());manifest=old_manifest[:60]
assert len(specs)>=106
for idx,row in enumerate(specs[60:106],60):
    name,category,color,*_=row;random.seed(idx*7381+69)
    g=Detailed(name,'foliage');b=Detailed(name,'bloom')
    accent=mat(name+' characteristic pigment',color,'smooth' if 'bamboo' in name.lower() else 'leaf')
    tree_bark=mat('redwood fibrous bark','9a5944','bark') if 'redwood' in name else bark
    nodes=mat('bamboo node collars','a4b18a','smooth') if 'bamboo' in name.lower() else smooth
    palette=[stem,leaf,young,dark,silver,tree_bark,nodes,sheath,accent]
    if name=='Ginkgo':palette[1]=pigment(mat('ginkgo fan','8aab4d','leaf'),'fan');palette[2]=palette[1]
    if name=='Rhubarb':palette[8]=mat('rhubarb petiole','bf4654','smooth')
    if name=='Black bamboo':palette[0]=mat('juvenile black bamboo','59814a','smooth')
    fruitlike=category=='Produce' or category=='Trees' and name not in ['Giant redwood','Coast redwood','Giant bamboo','Ginkgo']
    primary=mat(name+' flower or fruit',color,'fruit' if fruitlike else 'petal')
    shade_color={'Pink jasmine':'d785a2',"Dahlia 'Café au Lait'":'d8b7a5',"Tulip 'Queen of Night'":'271828',"Rose 'Mister Lincoln'":'861e32',"Rose 'Iceberg'":'f2eada',"Rose 'Golden Celebration'":'daa12b',"Rose 'Just Joey'":'d98e63',"Rose 'Scentimental'":'a32b43','Broccoli':'46734a','Cauliflower':'dcdac3','Capsicum':'5d8d3d','Red flowering gum':'594d3c'}.get(name,color)
    shade=mat(name+' shaded pigment',shade_color,'fruit' if fruitlike else 'petal')
    if name=="Rose 'Scentimental'":pigment(primary,'stripe');pigment(shade,'stripe')
    if name in ['Peach','Nectarine','Apricot','Pear']:pigment(primary,'blush')
    secondary=mat('redwood cone','90734b','bark') if 'redwood' in name else mat('jasmine pink buds','d586a3','petal') if name=='Pink jasmine' else cream
    bloom_stem=mat('harvest greens','7a9a54','leaf') if category=='Produce' else stem
    if name=='Leek':
        primary=mat('leek white shaft','e7e5cb','smooth');palette[6]=primary
    bloom_palette=[primary,secondary,pollen,bloom_stem,shade]
    build(name,category,g,b)
    assert g.v and b.v,(name,'empty geometry')
    root=bpy.data.objects.new(f'Plant_{idx:02d}_{name}',None);scene.collection.objects.link(root)
    root['catalogue_id']=idx;root['botanical_notes']='See botanical_expansion_references.md'
    foliage=g.object('Foliage',palette);foliage.parent=root
    bloom=b.object('Bloom',bloom_palette);bloom.parent=root
    # Exact semantic child names on every export, independent of Blender suffixes.
    bpy.ops.object.select_all(action='DESELECT')
    for obj in [root,foliage,bloom]:obj.select_set(True)
    bpy.context.view_layer.objects.active=foliage
    path=ROOT/'assets/plants'/f'plant_{idx:02d}.glb'
    if selected is None or idx in selected:
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
    manifest.append({'id':idx,'name':name,'vertices':len(g.v)+len(b.v),'triangles':sum(len(f)-2 for f in g.f+b.f),'path':str(path.relative_to(ROOT)),'morphology_version':3,'source':'art_source/botanical_expansion.blend'})
    root.location=((idx-60)%8*6,(idx-60)//8*15,0)
    print('EXPANSION_PLANT',idx,name,manifest[-1]['triangles'],flush=True)
(ROOT/'art_source/botanical_manifest.json').write_text(json.dumps(manifest+old_manifest[106:],indent=2)+'\n')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/botanical_expansion.blend'))
print('BOTANICAL_EXPANSION: PASS — 46 new plant assets')
