"""Reproducible full-library art export, run in isolated Blender MCP batches.

build(batch) exports one of the sequential 12-plant batches. The approved ten
live in plant_art_sample.blend and are never rewritten here. Models keep their
measured planting envelope, identifiers, heights, existing shaders and settings.
Images are packed into editable Blender4 libraries and portable glTF exports.
"""
import hashlib
import json
import math
import sys
from pathlib import Path
import bpy
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import material
from fruit_tree_geometry import add_anchor_channels
import plant_full_herbs,plant_full_woody,plant_full_low,plant_full_flowers
MODULES=[plant_full_herbs,plant_full_woody,plant_full_low,plant_full_flowers]
SAMPLE_IDS=[20,30,109,124,148,149,158,174,198,212]
IDS=sorted(idx for module in MODULES for idx in module.IDS)
assert len(IDS)==208 and set(IDS)==set(range(218))-set(SAMPLE_IDS)
BATCHES=[IDS[i:i+12] for i in range(0,len(IDS),12)]
FRUIT_IDS=[31,34,35,82,83,84,85,86,87,88,89,90,91]
BASELINE=json.loads((ROOT/'art_source/plant_full_baseline.json').read_text())


def triangles(g):return sum(len(face)-2 for face in g.f)


def normalized(idx,module):
    g,b,buds=module.build(idx);seed=module.build(idx,'seedling')[0];juv=module.build(idx,'juvenile')[0]
    geometry=[g,b,buds,seed,juv];points=g.v+b.v
    record=BASELINE[idx];bounds=record['bounds'];target_z=bounds['max'][1]
    scale=target_z/max(p[2] for p in points)
    widths=[(max(p[k] for p in points)-min(p[k] for p in points))*scale for k in [0,1]]
    targets=[bounds['max'][k]-bounds['min'][k] for k in [0,2]]
    lower=max(.71*targets[k]/widths[k] for k in [0,1]);upper=min(1.30*targets[k]/widths[k] for k in [0,1])
    if lower<=upper:
        spread=min(upper,max(lower,1.0));factors=(scale*spread,scale*spread,scale)
    else:
        factors=tuple(scale*min(1.30*targets[k]/widths[k],max(.71*targets[k]/widths[k],1.0)) for k in [0,1])+(scale,)
    for geo in geometry:
        geo.v=[tuple(point[k]*factors[k] for k in range(3)) for point in geo.v]
        if hasattr(geo,'fruit_anchors'):geo.fruit_anchors={i:tuple(point[k]*factors[k] for k in range(3)) for i,point in geo.fruit_anchors.items()}
        assert all(math.isfinite(v) for p in geo.v for v in p),(idx,'invalid coordinates')
        assert all(0<=v<len(geo.v) for face in geo.f for v in face),(idx,'invalid face')
    assert g.f and seed.f and juv.f and buds.f,(idx,'missing authored stage')
    for geo in [b,buds]:assert len(getattr(geo,'fruit_anchors',{}))==len(geo.v),(idx,'incomplete attachments')
    mature_tris=triangles(g)+triangles(b);growth_tris=sum(triangles(x) for x in [buds,seed,juv])
    assert mature_tris<=200000 and growth_tris<=18000,(idx,mature_tris,growth_tris)
    return geometry,{'id':idx,'name':record['name'],'height':target_z,'mature_triangles':mature_tris,'growth_triangles':growth_tris,'normalization':list(factors)}


class Surfaces:
    def __init__(self,folder):self.folder=folder;self.images={};self.materials={}
    def image(self,path,noncolor=False):
        key=(str(path),noncolor)
        if key not in self.images:
            image=bpy.data.images.load(str(path),check_existing=False)
            if noncolor:image.colorspace_settings.name='Non-Color'
            image.pack();self.images[key]=image
        return self.images[key]
    def pigment(self,idx,descriptor):
        label,color,kind,wind=descriptor
        pattern='orchid_sepal' if idx in [153,154] and label=='sepals' else 'orchid_petal' if idx in [151,195] and label=='petals' else None
        pattern='stripe' if idx==77 and 'petals' in label else 'gum' if idx in [45,92,93] and label=='smooth bark' else pattern
        key=(color,kind,wind,label,pattern)
        if key in self.materials:return self.materials[key]
        name=('Leaf ' if wind else 'Botanical ')+label+' '+color
        m=material(name,color);bs=m.node_tree.nodes.get('Principled BSDF')
        tissue='leaf' if kind in ['leaf','grass'] else 'petal' if kind=='petal' else None
        source_path=ROOT/'assets/textures/flower_additions'/f'{pattern}.webp' if pattern in ['orchid_sepal','orchid_petal'] else ROOT/'assets/textures/plant_sample'/f'{tissue}_tissue.webp' if tissue else ROOT/'assets/textures/botanical'/f'{kind}_color.png'
        src=self.image(source_path);pixels=np.array(src.pixels[:],dtype=np.float32).reshape(src.size[1],src.size[0],4)
        # Retain fine tissue in a 256px color map, matching the existing PBR maps.
        if src.size[0]==512:pixels=pixels.reshape(256,2,256,2,4).mean(axis=(1,3))
        h,w=pixels.shape[:2];luma=pixels[:,:,:3].mean(axis=2)
        field=np.clip(luma/max(float(luma.mean()),.01)*(.87 if tissue=='leaf' else .94),.35,1)
        swatch=np.array([int(color[k:k+2],16)/255 for k in [0,2,4]])
        if pattern not in ['orchid_sepal','orchid_petal']:pixels[:,:,:3]=field[:,:,None]*swatch
        v,u=np.mgrid[0:h,0:w]/max(h-1,1)
        if kind=='grass':pixels[:,:,:3]*=(.94+.06*np.sin(u*64))[:,:,None]
        if pattern=='stripe':
            field=np.sin(u*51+np.sin(v*17)*1.2)+.55*np.sin(u*107+v*11);mask=np.clip((field-.20)*3,0,1)
            pixels[:,:,:3]=pixels[:,:,:3]*(1-mask[:,:,None])+np.array([.94,.86,.73])*mask[:,:,None]
        elif pattern=='gum':
            field=np.sin(u*17+np.sin(v*12)*1.7)+np.sin(v*19-u*8)*.7
            colors=np.array([[.45,.49,.42],[.68,.70,.59],[.84,.82,.73],[.57,.57,.54]])
            pixels[:,:,:3]=colors[np.clip(((field+1.7)/3.4*4).astype(int),0,3)]*(.96+.04*np.sin(u*153+v*34))[:,:,None]
        image=bpy.data.images.new(name+' albedo',width=w,height=h);image.pixels.foreach_set(pixels.ravel())
        image.filepath_raw=str(self.folder/(hashlib.sha256(repr(key).encode()).hexdigest()[:16]+'.jpg'));image.file_format='JPEG';image.save(quality=89);image.pack()
        node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;m.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color'])
        mapkind='leaf' if kind=='grass' else kind
        for suffix in ['normal','roughness']:
            node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=self.image(ROOT/'assets/textures/botanical'/f'{mapkind}_{suffix}.png',True)
            if suffix=='normal':
                normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.16 if kind in ['petal','fruit'] else .30
                m.node_tree.links.new(node.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs['Normal'],bs.inputs['Normal'])
            else:m.node_tree.links.new(node.outputs['Color'],bs.inputs['Roughness'])
        self.materials[key]=m;return m
    def palette(self,idx,module):
        p=module.palette(idx)
        return [self.pigment(idx,d) for d in p['foliage']],[self.pigment(idx,d) for d in p['bloom']]


def build(batch):
    assert 0<=batch<len(BATCHES)
    previous=bpy.context.window.scene;scene=bpy.data.scenes.new(f'ZendGarden_PlantFull_{batch:02d}');bpy.context.window.scene=scene
    temporary=ROOT/'captures/plant-full/pigments'/f'{batch:02d}';temporary.mkdir(parents=True,exist_ok=True)
    (ROOT/'captures/plant-full/.gdignore').touch()
    surfaces=Surfaces(temporary);specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
    mature_records=json.loads((ROOT/'art_source/botanical_manifest.json').read_text());growth_records=json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())
    manifest=ROOT/'art_source/plant_full_art_manifest.json';audit={row['id']:row for row in json.loads(manifest.read_text())} if manifest.exists() else {}
    source=f'art_source/plant_full_{batch:02d}.blend';completed=[]
    def object(geo,name,palette,parent):
        assert geo.f and max(geo.mi)<len(palette),(parent.name,name,'invalid material')
        obj=geo.object(name,palette);add_anchor_channels(obj.data,geo);obj.parent=parent;return obj
    def export(root,organs,path):
        bpy.ops.object.select_all(action='DESELECT')
        for obj in [root,*organs]:obj.select_set(True)
        bpy.context.view_layer.objects.active=organs[0]
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_image_format='AUTO')
    try:
        for idx in BATCHES[batch]:
            module=next(m for m in MODULES if idx in m.IDS)
            (g,b,buds,seed,juv),record=normalized(idx,module);leaves,blooms=surfaces.palette(idx,module)
            plant=bpy.data.objects.new(f'Plant_{idx:02d}_{specs[idx][0]}',None);scene.collection.objects.link(plant)
            plant['catalogue_id']=idx;plant['full_art_revision']=1
            organs=[object(g,'Foliage',leaves,plant)]
            if b.f:organs.append(object(b,'BloomFruit' if idx in FRUIT_IDS else 'BloomFlower',blooms,plant))
            export(plant,organs,ROOT/'assets/plants'/f'plant_{idx:02d}.glb')
            growth=bpy.data.objects.new(f'Growth_{idx:02d}_{specs[idx][0]}',None);scene.collection.objects.link(growth)
            organs=[object(seed,'Seedling',leaves,growth),object(juv,'Juvenile',leaves,growth),object(buds,'BudsFruit' if idx in FRUIT_IDS else 'BudsFlower',blooms,growth)]
            export(growth,organs,ROOT/'assets/plants/growth'/f'growth_{idx:02d}.glb')
            mature_records[idx].update(vertices=len(g.v)+len(b.v),triangles=record['mature_triangles'],source=source,full_art_revision=1,path=f'assets/plants/plant_{idx:02d}.glb')
            growth_records[idx].update(triangles=record['growth_triangles'],source=source,full_art_revision=1)
            record['source']=source;audit[idx]=record;completed.append(idx)
            plant.location=((len(completed)-1)%4*8,(len(completed)-1)//4*9,0);growth.location=plant.location.copy();growth.location.y+=3.5
        bpy.data.libraries.write(str(ROOT/source),{scene},fake_user=True,compress=True)
        (ROOT/'art_source/botanical_manifest.json').write_text(json.dumps(mature_records,indent=2)+'\n')
        (ROOT/'art_source/plant_growth_manifest.json').write_text(json.dumps(growth_records,indent=2)+'\n')
        manifest.write_text(json.dumps([audit[k] for k in sorted(audit)],indent=2)+'\n')
        return {'batch':batch,'ids':completed,'exports':len(completed)*2,'library':source,'preserved_scene':previous.name}
    finally:
        bpy.context.window.scene=previous
        for path in temporary.glob('*.jpg'):path.unlink()


if __name__=='__main__':
    import argparse
    parser=argparse.ArgumentParser();parser.add_argument('--batch',type=int,required=True)
    options=parser.parse_args(sys.argv[sys.argv.index('--')+1:]);print('PLANT_FULL_EXPORT',build(options.batch))
