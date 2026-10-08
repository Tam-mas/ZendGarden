"""Build the seventy new flowering plants through Blender MCP or Blender CLI.

The only writable source library is flower_additions.blend. Existing plant IDs,
libraries and exports are retained byte-for-byte. Pigments are packed in the
source and GLBs; authored imagegen source maps remain compact WebP files.
"""
import bpy,sys,json,random
import numpy as np
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import material
from fruit_tree_geometry import add_anchor_channels
from flower_additions_data import FLOWER_ADDITIONS
from flower_additions_geometry import foliage,mature

def build(*, bushes_only=False):
    previous=bpy.context.window.scene
    library=ROOT/'art_source/flower_additions.blend'
    if bushes_only:
        # Load the complete editable library; replace only the twenty shrub families.
        with bpy.data.libraries.load(str(library),link=False) as (source,target):
            target.scenes=[name for name in source.scenes if name.startswith('ZendGarden_FlowerAdditions')]
        assert len(target.scenes)==1,'Expected one complete flower collection source scene'
        scene=target.scenes[0]
        assert sum(o.type=='MESH' for o in scene.objects)==350,'Incomplete source library'
        assert {o.get('catalogue_id') for o in scene.objects if 'catalogue_id' in o}==set(range(148,218))
        bpy.context.window.scene=scene
        roots=[o for o in scene.objects if o.parent is None and o.name.startswith(('Plant_','Growth_'))]
        for obj in roots:
            idx=int(obj.name.split('_')[1])
            if idx>=198:
                for child in list(obj.children):bpy.data.objects.remove(child,do_unlink=True)
                bpy.data.objects.remove(obj,do_unlink=True)
    else:
        scene=bpy.data.scenes.new('ZendGarden_FlowerAdditions')
        bpy.context.window.scene=scene
    temporary=ROOT/'captures/flower-additions/pigments';temporary.mkdir(parents=True,exist_ok=True)
    library=ROOT/'art_source/flower_additions.blend'
    old_mature=json.loads((ROOT/'art_source/botanical_manifest.json').read_text())
    old_growth=json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())
    mrecords={p['id']:p for p in old_mature};grecords={p['id']:p for p in old_growth}
    newfiles=[];materials={};textures={}
    def image(path,noncolor=False):
        key=(str(path),noncolor)
        if key not in textures:
            im=bpy.data.images.load(str(path),check_existing=True)
            if noncolor:im.colorspace_settings.name='Non-Color'
            im.pack();textures[key]=im
        return textures[key]
    def pigment(label,color,kind='petal',pattern=None):
        key=(label,color,kind,pattern)
        if key in materials:return materials[key]
        m=material(label,color,.68 if kind=='leaf' else .57 if kind=='petal' else .84)
        bs=m.node_tree.nodes.get('Principled BSDF')
        source=image(ROOT/'assets/textures/flower_additions'/f'{pattern}.webp') if pattern else image(ROOT/'assets/textures/botanical'/f'{kind}_color.png')
        pix=np.array(source.pixels[:],dtype='float32').reshape((-1,4))
        if not pattern:
            linear=np.array(m.diffuse_color[:3])
            swatch=np.where(linear>.0031308,1.055*linear**(1/2.4)-.055,12.92*linear)
            pix[:,:3]*=swatch
        elif pattern=='orchid_petal':
            linear=np.array(m.diffuse_color[:3])
            swatch=np.where(linear>.0031308,1.055*linear**(1/2.4)-.055,12.92*linear)
            pix[:,:3]*=swatch
        elif pattern=='leaf':
            # Generated leaf tissue is already green; keep its vein contrast.
            if label.startswith('Leaf FlowerAddition ') and int(label.split()[2])>=198:
                # Retain the generated veins while giving each shrub its real leaf pigment.
                linear=np.array(m.diffuse_color[:3])
                swatch=np.where(linear>.0031308,1.055*linear**(1/2.4)-.055,12.92*linear)
                mean=np.maximum(pix[:,:3].mean(axis=0),.03)
                pix[:,:3]=np.clip(pix[:,:3]/mean*swatch*.76,0,1)
            else:pix[:,:3]*=np.array([.78,.87,.72])
        texture=bpy.data.images.new(label+' albedo',width=source.size[0],height=source.size[1])
        texture.pixels.foreach_set(pix.ravel())
        texture.filepath_raw=str(temporary/(''.join(c if c.isalnum() else '_' for c in label)+'.jpg'))
        texture.file_format='JPEG';texture.save(quality=88);texture.pack()
        n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=texture
        m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
        for suffix in ['normal','roughness']:
            im=image(ROOT/'assets/textures/botanical'/f'{kind}_{suffix}.png',True)
            n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=im
            if suffix=='normal':
                nm=m.node_tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.18 if kind=='petal' else .35
                m.node_tree.links.new(n.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],bs.inputs['Normal'])
            else:m.node_tree.links.new(n.outputs['Color'],bs.inputs['Roughness'])
        materials[key]=m;return m
    def object(g,name,palette,parent):
        obj=g.object(name,palette);add_anchor_channels(obj.data,g)
        if getattr(g,'fruit_anchors',None):
            loop=obj.data.loops[0];anchor=g.fruit_anchors[loop.vertex_index]
            uv=obj.data.uv_layers['Fruit anchors'].data[0].uv
            assert abs(uv.x-anchor[0])<1e-5 and abs(uv.y-anchor[2])<1e-5,'Attachment UV was replaced by surface UV'
        obj.parent=parent;return obj
    def export(root,organs,path):
        bpy.ops.object.select_all(action='DESELECT')
        for obj in [root,*organs]:obj.select_set(True)
        bpy.context.view_layer.objects.active=organs[0]
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_image_format='AUTO')
        newfiles.append(str(path.relative_to(ROOT)))
    try:
        for row in FLOWER_ADDITIONS:
            idx=row['id']
            if bushes_only and idx<198:continue
            random.seed(idx*7919+181)
            name=row['name'];label=f'FlowerAddition {idx}'
            shrub={}
            if idx>=198:
                from flower_bush_geometry import profile
                shrub=profile(idx)
            leaves=[pigment('Botanical '+label+' stem',shrub.get('bark','5d7541'),'smooth'),pigment('Leaf '+label,shrub.get('green','56804b'),'leaf','leaf'),pigment('Leaf '+label+' young',shrub.get('young','80a358'),'leaf','leaf' if idx>=198 else None),pigment('Botanical '+label+' roots','d5d6bc','smooth')]
            primary_pattern='orchid_petal' if idx in [149,151,195] else None
            petal= pigment('Botanical '+label+' petals',row['color'],'petal',primary_pattern)
            cream=pigment('Botanical '+label+' cream','f4eee1','petal')
            pollen=pigment('Botanical '+label+' pollen','d7ab36','pollen')
            sepals=pigment('Botanical '+label+' sepals','80a357','leaf','orchid_sepal' if idx in [149,153,154] else None)
            lipcolor={148:'b94f97',149:'aa7751',150:'eaca36',151:'b164a2',152:'8f91d4',153:'884dab',154:'f4eee1',155:'efe5b0',156:'664733',157:'b763a2',165:'be692e',166:'493626',212:'8549a1'}.get(idx,'755937' if idx in [165,166] else row['color'])
            lip=pigment('Botanical '+label+' flower lip',lipcolor,'petal','orchid_petal' if idx==153 else None)
            blooms=[petal,cream,pollen,leaves[1],sepals,lip,petal]
            g,b,buds=mature(row)
            root=bpy.data.objects.new(f'Plant_{idx:02d}_{name}',None);scene.collection.objects.link(root)
            root['catalogue_id']=idx;root['botanical_name']=row['scientific'];root['botanical_notes']=row['notes'];root['reference_urls']='\n'.join(row['references'])
            organs=[object(g,'Foliage',leaves,root),object(b,'BloomFlower',blooms,root)]
            path=ROOT/'assets/plants'/f'plant_{idx:02d}.glb';export(root,organs,path)
            triangles=sum(len(f)-2 for f in g.f+b.f)
            assert 0<triangles<=200000,(name,triangles)
            mrecords[idx]={'id':idx,'name':name,'vertices':len(g.v)+len(b.v),'triangles':triangles,'path':str(path.relative_to(ROOT)),'morphology_version':4 if idx>=198 else 3,'source':'art_source/flower_additions.blend'}
            youngroot=bpy.data.objects.new(f'Growth_{idx:02d}_{name}',None);scene.collection.objects.link(youngroot)
            early=[]
            for stage,phase in [('Seedling','seedling'),('Juvenile','juvenile')]:
                earlyg,_=foliage(row,phase);early.append(object(earlyg,stage,leaves,youngroot))
            early.append(object(buds,'BudsFlower',[petal,leaves[1]],youngroot))
            export(youngroot,early,ROOT/'assets/plants/growth'/f'growth_{idx:02d}.glb')
            growth_tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in early)
            assert 0<growth_tris<=18000,(name,'growth budget',growth_tris)
            grecords[idx]={'id':idx,'name':name,'family':row['foliage'],'height':round(row['height'],4),'triangles':growth_tris,'source':'art_source/flower_additions.blend'}
            root.location=((idx-148)%10*4,(idx-148)//10*5,0)
            youngroot.location=root.location.copy();youngroot.location.y+=2
            print('FLOWER_ADDITION',idx,name,triangles,growth_tris,flush=True)
        # Only this complete scene and its packed dependencies are written.
        assert sum(o.type=='MESH' for o in scene.objects)==350,'Source must retain all seventy plants'
        bpy.data.libraries.write(str(library),{scene},fake_user=True,compress=True)
        mature_records=[mrecords[i] for i in sorted(mrecords)];growth_records=[grecords[i] for i in sorted(grecords)]
        assert [p['id'] for p in mature_records]==list(range(len(mature_records)))
        (ROOT/'art_source/botanical_manifest.json').write_text(json.dumps(mature_records,indent=2)+'\n')
        (ROOT/'art_source/plant_growth_manifest.json').write_text(json.dumps(growth_records,indent=2)+'\n')
        heights=[p['height'] for p in growth_records]
        (ROOT/'scripts/plant_profiles.gd').write_text('class_name GardenPlantProfiles\nextends RefCounted\n\n# Authored mature model heights in metres, including the new flowers.\nconst HEIGHTS='+json.dumps(heights)+'\n')
        return {'plants':len(newfiles)//2,'library':str(library),'exports':len(newfiles),'mature_triangles':sum(p['triangles'] for p in mature_records[148:]),'growth_triangles':sum(p['triangles'] for p in growth_records[148:]),'preserved_scene':previous.name}
    finally:
        bpy.context.window.scene=previous
        for path in temporary.glob('*.jpg'):path.unlink()

if __name__=='__main__':print('FLOWER_ADDITIONS_EXPORT',build())
