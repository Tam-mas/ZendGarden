"""Export ten reference-led plants through Blender MCP, preserving other assets.

Run build() in a separate Blender process. The editable sample is an override
library: rebuild it after older botanical builders. No runtime quality, wind,
lighting, batching, catalogue, height or save setting is written here.
"""
import json
import math
import sys
from pathlib import Path
import bpy
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'art_source'))
from botanical_geometry import material
from fruit_tree_geometry import add_anchor_channels
import plant_sample_flowers
import plant_sample_woody
import plant_sample_rosettes

IDS = [20,30,109,124,148,149,158,174,198,212]
# Measured from the shipped GLBs, in game X/Y/Z. Keep saved planting envelopes.
TARGETS = {
 20:(1.17762148,1.34943372,1.27576751), 30:(2.98917317,3.23057795,2.68224406),
 109:(.44289336,1.04896802,1.03370672),124:(.30299997,.54708180,.51260081),
 148:(.5,.50289659,.41133478),149:(.3,.33460373,.16109625),
 158:(.75,.36370026,.35034946),174:(.18,.11932177,.11411977),
 198:(2.,1.98925441,2.01174742),212:(1.6,2.63270771,2.64674080),
}


def triangles(g):return sum(len(f)-2 for f in g.f)


def build():
    previous = bpy.context.window.scene
    scene = bpy.data.scenes.new('ZendGarden_PlantArtSample')
    bpy.context.window.scene = scene
    temporary = ROOT/'captures/plant-sample/pigments'
    temporary.mkdir(parents=True,exist_ok=True)
    specs = json.loads((ROOT/'art_source/plant_specs.json').read_text())
    mature_records = json.loads((ROOT/'art_source/botanical_manifest.json').read_text())
    growth_records = json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())
    sources = {}
    materials = {}
    audit = []

    def image(path, noncolor=False):
        key=(str(path),noncolor)
        if key not in sources:
            im=bpy.data.images.load(str(path),check_existing=True)
            if noncolor:im.colorspace_settings.name='Non-Color'
            im.pack();sources[key]=im
        return sources[key]

    def pigment(label,color,kind,wind=False,pattern=None):
        key=(label,color,kind,wind,pattern)
        if key in materials:return materials[key]
        m=material(('Leaf ' if wind else 'Botanical ')+label,color)
        bs=m.node_tree.nodes.get('Principled BSDF')
        tissue='leaf' if kind=='leaf' else 'petal' if kind=='petal' else None
        source=image(ROOT/'assets/textures/flower_additions'/f'{pattern}.webp') if pattern else image(ROOT/'assets/textures/plant_sample'/f'{tissue}_tissue.webp') if tissue else image(ROOT/'assets/textures/botanical'/f'{"leaf" if kind=="grass" else kind}_color.png')
        pixels=np.array(source.pixels[:],dtype='float32').reshape(source.size[1],source.size[0],4)
        # Source tissue becomes neutral value modulation; pigments stay species-specific.
        luma=pixels[:,:,:3].mean(axis=2)
        level=.87 if tissue=='leaf' else .94
        field=np.clip(luma/max(float(luma.mean()),.01)*level,.30,1.0)
        swatch=np.array([int(color[i:i+2],16)/255 for i in (0,2,4)])
        if not pattern:pixels[:,:,:3]=field[:,:,None]*swatch
        if kind=='grass':
            u=np.linspace(0,1,source.size[0])[None,:]
            stripe=((np.sin(u*23+.2)>.65)|(np.sin(u*47)<-.9))[:,:,None]
            pixels[:,:,:3]=np.where(stripe,pixels[:,:,:3]*np.array([.48,.72,.46]),pixels[:,:,:3])
        tex=bpy.data.images.new(label+' albedo',width=source.size[0],height=source.size[1])
        tex.pixels.foreach_set(pixels.ravel())
        tex.filepath_raw=str(temporary/(''.join(c if c.isalnum() else '_' for c in label)+'.jpg'))
        tex.file_format='JPEG';tex.save(quality=88);tex.pack()
        n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=tex;m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
        mapkind='leaf' if kind=='grass' else kind
        for suffix in ['normal','roughness']:
            n=m.node_tree.nodes.new('ShaderNodeTexImage')
            n.image=image(ROOT/'assets/textures/botanical'/f'{mapkind}_{suffix}.png',True)
            if suffix=='normal':
                normal=m.node_tree.nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.16 if kind in ['petal','fruit'] else .30
                m.node_tree.links.new(n.outputs['Color'],normal.inputs['Color']);m.node_tree.links.new(normal.outputs['Normal'],bs.inputs['Normal'])
            else:m.node_tree.links.new(n.outputs['Color'],bs.inputs['Roughness'])
        materials[key]=m
        return m

    def palette(idx):
        stem,leaf,young={
            20:('756242','477243','829253'),30:('766b60','993c42','bb5951'),
            109:('b2b471','d3c971','e0d787'),124:('aa9b8b','91b4ad','abc6bc'),
            148:('819259','51784b','859658'),149:('75894d','557849','8b9f69'),
            158:('7f9877','718f70','9aaf88'),174:('7c9871','749889','9db5a1'),
            198:('877452','426e48','8c9659'),212:('916352','557654','88a16b'),
        }[idx]
        foliage_kind='grass' if idx==109 else 'fruit' if idx==124 else 'leaf'
        leaves=[pigment(f'Sample {idx} stem',stem,'smooth',idx==109),
                pigment(f'Sample {idx} leaf',leaf,foliage_kind,idx!=124),
                pigment(f'Sample {idx} '+('young flesh' if idx==124 else 'young leaf'),young,foliage_kind,idx!=124),
                pigment(f'Sample {idx} roots','d4c9aa','smooth')]
        primary={124:'de8996',149:'c1a365',212:'d53465'}.get(idx,specs[idx][2])
        secondary={20:'e6a5b0',158:'5752a5',198:'e88373'}.get(idx,primary)
        lip={148:'a6439b',149:'ad8251',174:'789553',198:'a72e3f',212:'8442a6'}.get(idx,primary)
        sepal={149:'b6bd7a',174:'71955e'}.get(idx,leaf)
        blooms=[pigment(f'Sample {idx} petals',primary,'petal',idx==109),
                pigment(f'Sample {idx} cream','f0e9d7' if idx!=124 else 'ebce75','petal'),
                pigment('Sample pollen','d4ae4d','pollen'),leaves[1],
                pigment(f'Sample {idx} sepal',sepal,'leaf',pattern='orchid_sepal' if idx==149 else None),
                pigment(f'Sample {idx} flower lip',lip,'petal'),
                pigment(f'Sample {idx} secondary petals',secondary,'petal')]
        return leaves,blooms

    def object(g,name,palette,parent):
        assert g.v and g.f,(parent.name,name,'empty geometry')
        obj=g.object(name,palette);add_anchor_channels(obj.data,g);obj.parent=parent
        return obj

    def export(root,organs,path):
        bpy.ops.object.select_all(action='DESELECT')
        for obj in [root,*organs]:obj.select_set(True)
        bpy.context.view_layer.objects.active=organs[0]
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_image_format='AUTO')

    try:
        for idx in IDS:
            module=plant_sample_flowers if idx in plant_sample_flowers.IDS else plant_sample_woody if idx in plant_sample_woody.IDS else plant_sample_rosettes
            g,b,buds=module.build(idx)
            seed=module.build(idx,'seedling')[0];juvenile=module.build(idx,'juvenile')[0]
            geometry=[g,b,buds,seed,juvenile]
            points=g.v+b.v
            target_height,target_x,target_y=TARGETS[idx]
            scale=target_height/max(v[2] for v in points)
            widths=[(max(v[i] for v in points)-min(v[i] for v in points))*scale for i in [0,1]]
            lower=max(.70*target_x/widths[0],.70*target_y/widths[1])
            upper=min(1.32*target_x/widths[0],1.32*target_y/widths[1])
            assert lower<=upper,(idx,'incompatible placement envelope',widths)
            spread=min(upper,max(lower,1.0))
            factors=(scale*spread,scale*spread,scale)
            for geo in geometry:
                geo.v=[tuple(p[i]*factors[i] for i in range(3)) for p in geo.v]
                assert all(math.isfinite(c) for p in geo.v for c in p)
                if getattr(geo,'fruit_anchors',None):geo.fruit_anchors={j:tuple(p[i]*factors[i] for i in range(3)) for j,p in geo.fruit_anchors.items()}
            leaves,blooms=palette(idx)
            root=bpy.data.objects.new(f'Plant_{idx:02d}_{specs[idx][0]}',None);scene.collection.objects.link(root)
            root['catalogue_id']=idx;root['art_sample_revision']=1
            foliage=object(g,'Foliage',leaves,root)
            organs=[foliage]
            # Maple's display is foliage; GardenArt creates its empty harvest group.
            if b.f:organs.append(object(b,'BloomFlower',blooms,root))
            path=ROOT/'assets/plants'/f'plant_{idx:02d}.glb'
            export(root,organs,path)
            early=bpy.data.objects.new(f'Growth_{idx:02d}_{specs[idx][0]}',None);scene.collection.objects.link(early)
            organs=[object(seed,'Seedling',leaves,early),object(juvenile,'Juvenile',leaves,early),object(buds,'BudsFlower',blooms,early)]
            export(early,organs,ROOT/'assets/plants/growth'/f'growth_{idx:02d}.glb')
            mature_tris=triangles(g)+triangles(b);growth_tris=triangles(seed)+triangles(juvenile)+triangles(buds)
            assert mature_tris<=200000 and growth_tris<=18000,(idx,mature_tris,growth_tris)
            mature_records[idx].update(vertices=len(g.v)+len(b.v),triangles=mature_tris,source='art_source/plant_art_sample.blend',art_sample_revision=1)
            growth_records[idx].update(triangles=growth_tris,source='art_source/plant_art_sample.blend',art_sample_revision=1)
            audit.append({'id':idx,'name':specs[idx][0],'height':target_height,'mature_triangles':mature_tris,'growth_triangles':growth_tris,'normalization':list(factors)})
            root.location=((IDS.index(idx)%5)*5,(IDS.index(idx)//5)*6,0)
            early.location=root.location.copy();early.location.y+=2.3
            print('PLANT_ART_SAMPLE',idx,mature_tris,growth_tris,flush=True)
        library=ROOT/'art_source/plant_art_sample.blend'
        bpy.data.libraries.write(str(library),{scene},fake_user=True,compress=False)
        (ROOT/'art_source/botanical_manifest.json').write_text(json.dumps(mature_records,indent=2)+'\n')
        (ROOT/'art_source/plant_growth_manifest.json').write_text(json.dumps(growth_records,indent=2)+'\n')
        (ROOT/'art_source/plant_art_sample_manifest.json').write_text(json.dumps(audit,indent=2)+'\n')
        return {'plants':len(audit),'exports':len(audit)*2,'mature_triangles':sum(p['mature_triangles'] for p in audit),'growth_triangles':sum(p['growth_triangles'] for p in audit),'library':str(library),'preserved_scene':previous.name}
    finally:
        bpy.context.window.scene=previous
        for path in temporary.glob('*.jpg'):path.unlink()


if __name__=='__main__':print('PLANT_ART_SAMPLE_RESULT',build())
