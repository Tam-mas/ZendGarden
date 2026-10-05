"""Original Zend Garden botanical library. Blender 5 / glTF, metres, Z-up.
Every species has its own seeded branching, leaf and inflorescence geometry.
Run only inside the isolated ZendGarden_AssetWorkshop scene.
"""
import bpy, math, random, json, os, sys
from pathlib import Path
from mathutils import Vector
from math import sin,cos,pi,sqrt
ROOT=str(Path(__file__).resolve().parents[1])
sys.path.insert(0,str(Path(__file__).resolve().parent))
import botanical_forms
from botanical_geometry import Geometry, material
scene=bpy.data.scenes.get('ZendGarden_AssetWorkshop')
if scene is None: scene=bpy.data.scenes.new('ZendGarden_AssetWorkshop')
bpy.context.window.scene=scene
random.seed(4207)


stem=material('Living stems','48662a')
bark=material('Ridged warm bark','675744')
leaves=[material('Leaf olive','537231'),material('Leaf young','739541'),material('Leaf deep','385c2b'),material('Leaf silver','7a9274')]
smooth_bark=material('Smooth pale gum bark','c4c1ad')
peeling_bark=material('Gum bark peeling patches','969483')

pollen=material('Pollen ochre','b78e31'); disk=material('Seed disk umber','483221')

# Real leaf UVs and original vein maps hold detail at first-person distances.
import numpy as np
for li,m in enumerate(leaves):
    N=128; yy,xx=np.mgrid[0:N,0:N]; u=xx/(N-1); v=yy/(N-1)
    mid=np.exp(-((u-.5)/.017)**2)
    vein=np.exp(-(np.sin((v-np.abs(u-.5)*.65)*pi*11)/.16)**2)*(.5-np.abs(u-.5))
    tone=.82+.16*np.sin(v*pi)+mid*.18+vein*.12+np.random.default_rng(li).normal(0,.02,(N,N))
    linear=np.array(m.diffuse_color[:3]); col=np.where(linear>.0031308,1.055*linear**(1/2.4)-.055,12.92*linear)
    pixels=np.concatenate([np.clip(col[None,None,:]*tone[:,:,None],0,1),np.ones((N,N,1))],2).astype('float32')
    im=bpy.data.images.new('Leaf veins '+str(li),width=N,height=N); im.pixels.foreach_set(pixels.ravel()); im.filepath_raw=ROOT+'/assets/textures/leaf_veins_'+str(li)+'.png'; im.file_format='PNG'; im.save()
    tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=im
    m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
if os.path.exists(ROOT+'/assets/textures/Aged_chestnut.png'):
    tex=bark.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=bpy.data.images.load(ROOT+'/assets/textures/Aged_chestnut.png',check_existing=True)
    bark.node_tree.links.new(tex.outputs['Color'],bark.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])


def flower(g,center,size,style,mat=0):
    c=Vector(center)
    if style=='spike':
        for k in range(7):
            for j in range(4):
                a=j*pi/2+k*.5
                g.ellipsoid(c+Vector((cos(a)*size*.32,sin(a)*size*.32,k*size*.22)),(size*.24,size*.17,size*.27),mat,3,6)
    elif style=='rose':
        for ring in range(4):
            count=13-ring*2
            radius=size*(1.0-ring*.23)
            for j in range(count):
                a=j*2*pi/count+ring*2.39996
                lower=c+Vector((cos(a)*size*.07,sin(a)*size*.07,-size*.20))
                if hasattr(g,'cupped_blade'):
                    g.cupped_blade(lower,a,radius,size*(.45-ring*.075),size*(.24+ring*.15),mat,.10)
                else:
                    g.leaf(lower,c+Vector((cos(a)*radius,sin(a)*radius,size*.3)),size*.25,mat,.3,6)
        g.ellipsoid(c+Vector((0,0,size*.24)),(size*.08,size*.08,size*.15),mat,5,8)
    elif style=='bell':
        # Downward-curving trumpet with an open, flared rim.
        for j in range(7):
            a=j*2*pi/7
            g.leaf(c+Vector((0,0,size*.6)),c+Vector((cos(a)*size*.65,sin(a)*size*.65,-size*.4)),size*.32,mat,-.35,5)
    else:
        count=18 if style=='sunflower' else 10 if style=='daisy' else 6
        for j in range(count):
            a=j*2*pi/count
            rr=size*random.uniform(.9,1.1)
            g.leaf(c+Vector((cos(a)*size*.14,sin(a)*size*.14,0)),c+Vector((cos(a)*rr,sin(a)*rr,random.uniform(-.04,.03))),size*(.15 if count>12 else .24),mat,.19,5)
        g.ellipsoid(c+Vector((0,0,.015)),(size*.35,size*.35,size*.15),1,4,10)
        if style=='sunflower':
            for j in range(36):
                a=j*2.39996; r=sqrt(j/36)*size*.3
                g.ellipsoid(c+Vector((cos(a)*r,sin(a)*r,size*.15)),(size*.034,)*3,2,2,5)

specs=json.load(open(ROOT+'/art_source/plant_specs.json'))
from botanical_detail import surfaces, texture_material, detail_geometry
surface_maps=surfaces(ROOT)
DetailedGeometry=detail_geometry(Geometry)
for material_item,kind in [(stem,'smooth'),(bark,'bark'),(smooth_bark,'smooth'),(peeling_bark,'bark'),(pollen,'pollen'),(disk,'pollen')]+[(m,'leaf') for m in leaves]:
    texture_material(material_item,kind,surface_maps)
manifest=[]
for idx,row in enumerate(specs[:60]):
    name,category,color,layer,days,climate,animal=row
    random.seed(idx*7381+69)
    foliage=DetailedGeometry(name,'foliage'); bloom=DetailedGeometry(name,'bloom')
    petal=material(name+' petals / fruit',{'Lavender':'8164b5','Bottlebrush':'bb373c','Wattle':'ecc72e','Banksia':'d6a53b','Grevillea':'d96b55','Rosemary':'9eabcc','Tomato':'c84432','Chilli':'c53728','Aubergine':'4f305d','Pea':'739443','Cucumber':'4c7038','Apple':'c35d43','Lemon':'e3c64b','Olive':'454c31','Blueberry':'536387','Lilly pilly':'b5496e','Poppy':'da5845','Chamomile':'f6f1db'}.get(name,color),.72)
    texture_material(petal,'fruit' if category=='Produce' or name in ['Apple','Lemon','Olive','Blueberry','Lilly pilly'] else 'petal',surface_maps)
    mats=[stem,*leaves,bark]
    bloom_mats=[petal,disk if name in ['Sunflower','Poppy'] else pollen,pollen,stem]
    if name in ['Apple','Lemon','Olive']:
        from fruit_tree_geometry import fruit_palette
        bloom_mats=fruit_palette(name,bloom_mats,surface_maps)
    # Species-specific foliage colours do not recolour flowers or menu swatches.
    accent=material('Leaf '+name+' characteristic foliage',{'Japanese maple':'943f32','Blue fescue':'799fa7','Lettuce':'9eba65','Beetroot':'9a3c50'}.get(name,'547536'))
    texture_material(accent,'leaf',surface_maps)
    mats += [smooth_bark,peeling_bark,accent]
    botanical_forms.build(name,category,layer,foliage,bloom,flower)
    root=bpy.data.objects.new('Plant_%02d_%s'%(idx,name.replace(' ','_')),None); scene.collection.objects.link(root)
    leaf_obj=foliage.object('Foliage',mats); leaf_obj.parent=root
    bloom_obj=bloom.object('BloomFruit' if hasattr(bloom,'fruit_anchors') else 'Bloom',bloom_mats); bloom_obj.parent=root
    bpy.ops.object.select_all(action='DESELECT')
    for ob in [root,leaf_obj,bloom_obj]: ob.select_set(True)
    bpy.context.view_layer.objects.active=leaf_obj
    path=ROOT+'/assets/plants/plant_%02d.glb'%idx
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
    manifest.append({'id':idx,'name':name,'vertices':len(foliage.v)+len(bloom.v),'path':path,'morphology_version':3,'triangles':sum(len(f)-2 for f in foliage.f+bloom.f)})
    # Keep a readable botanical library arranged in the source workshop.
    root.location=(idx%10*4,idx//10*8,0)
# A standalone original-library rebuild must retain the expansion's entries.
manifest_path=Path(ROOT)/'art_source/botanical_manifest.json'
existing=json.loads(manifest_path.read_text()) if manifest_path.exists() else []
combined=manifest+[entry for entry in existing if entry['id']>=60]
manifest_path.write_text(json.dumps(combined,indent=2)+'\n')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/art_source/botanical_library.blend')
result={'species':len(manifest),'vertices':sum(x['vertices'] for x in manifest),'source':ROOT+'/art_source/botanical_library.blend'}
