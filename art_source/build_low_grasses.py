"""Small grasses and grass-like groundcovers, IDs 136–147.

Can be imported and called through Blender MCP. Only creates its own scene;
library writing preserves the user's open file and active scene.
"""
import bpy, sys, json, random, math
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'art_source'))
from botanical_geometry import Geometry, material
from botanical_detail import texture_material
from botanical_additions_forms import grass_blade
from low_grasses_data import LOW_GRASSES

def striped_blade(g,base,angle,height,spread,width,form):
    rows=[]
    side=Vector((-math.sin(angle),math.cos(angle),0))
    direction=Vector((math.cos(angle),math.sin(angle),0))
    divisions=[-1,-.7,.7,1] if form=='evergold' else [-1,-.82,.82,1]
    for j in range(21):
        t=j/20
        centre=base+direction*(spread*t*t)+Vector((0,0,height*(math.sin(t*math.pi*.65)/math.sin(math.pi*.65))-.24*height*t**4))
        w=width*math.sin(math.pi*(t*.96+.02))**.7*(1-.3*t)
        row=[]
        for q in divisions:
            row.append(len(g.v));g.v.append(tuple(centre+side*q*w));g.uv[len(g.v)-1]=((q+1)*.5,t)
        rows.append(row)
    for lower,upper in zip(rows,rows[1:]):
        for band in range(3):
            accent=band==1 if form=='evergold' else band!=1
            g.face((lower[band],lower[band+1],upper[band+1],upper[band]),2 if accent else 1)

def geometry(form, height, young=False):
    g, bloom = Geometry(), Geometry()
    carpet = form in ['zoysia','buffalo','bent','red_fescue']
    patches = 5 if young else 19 if carpet else 7
    radius = .07 if young else .34 if carpet else .15
    for cluster in range(patches):
        a=cluster*2.39996
        base=Vector((math.cos(a),math.sin(a),0))*radius*math.sqrt((cluster+.1)/patches)
        if carpet and cluster:
            previous=base*.5
            g.tube([previous,base],[.0014,.001],0,5)
        count=7 if young else 14 if carpet else 26
        for j in range(count):
            turn=j*2.39996+cluster
            h=height*random.uniform(.55,1)
            width=.0009 if form in ['zoysia','bent','red_fescue','sheep','bearskin'] else .004 if form in ['mondo','black','sesleria','acorus'] else .0055
            spread=h*(.45 if carpet or form in ['sheep','bearskin','zoysia'] else 1.1)
            # Variegation is longitudinal across each blade, never random stripes.
            if form in ['evergold','snowline']:
                striped_blade(g,base,turn,h,spread,width,form)
            else:grass_blade(g,base,turn,h,spread,width,1+(j%3==0))
        if young:continue
        if carpet and cluster%5:continue
        tip=base+Vector((.012*math.cos(a),.012*math.sin(a),height*(.72 if form in ['mondo','black','acorus'] else 1.3)))
        bloom.tube([base,tip],[.0012,.0006],2,5)
        if form in ['mondo','black']:
            for k in range(3):
                p=tip+Vector((.013*math.cos(k*2.4),.013*math.sin(k*2.4),-.015*k))
                for petal in range(6):
                    angle=petal*math.tau/6
                    bloom.leaf(p,p+Vector((math.cos(angle)*.008,math.sin(angle)*.008,.003)),.003,0,.3,5)
        else:
            # Small, restrained seed spikes; lawn forms remain predominantly leaves.
            for k in range(5):
                p=tip-Vector((0,0,.008*k))
                bloom.ellipsoid(p,(.0025,.0025,.006),1 if form in ['buffalo','sheep'] else 0,3,5)
    return g,bloom

def build():
    previous=bpy.context.window.scene
    scene=bpy.data.scenes.new('ZendGarden_LowGrasses')
    bpy.context.window.scene=scene
    try:
        intermediates=set()
        maps={kind:[bpy.data.images.load(str(ROOT/'assets/textures/botanical'/f'{kind}_{suffix}.png'),check_existing=True) for suffix in ['color','normal','roughness']] for kind in ['leaf','petal','smooth','pollen']}
        for images in maps.values():
            images[1].colorspace_settings.name='Non-Color';images[2].colorspace_settings.name='Non-Color'
        def pigment(name,color,kind='leaf'):
            m=material('Leaf '+name if kind=='leaf' else 'Botanical '+name,color)
            texture_material(m,kind,maps)
            # Opaque pigment maps compress well as JPEG inside standard glTF.
            # Keep normal and roughness maps lossless; WebP remains standalone.
            tex=next(n.image for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image.colorspace_settings.name=='sRGB')
            intermediates.add(Path(tex.filepath_raw))
            tex.filepath_raw=str(Path(tex.filepath_raw).with_suffix('.jpg'))
            intermediates.add(Path(tex.filepath_raw))
            tex.file_format='JPEG'
            tex.save(quality=92)
            tex.pack()
            return m
        mature=json.loads((ROOT/'art_source/botanical_manifest.json').read_text())[:136]
        growth=json.loads((ROOT/'art_source/plant_growth_manifest.json').read_text())[:136]
        for idx,(name,botanical,color,light,height,form) in enumerate(LOW_GRASSES,136):
            random.seed(idx*179)
            body='487443' if form in ['evergold','snowline'] else '24222e' if form=='black' else color
            palette=[pigment(name+' runners','647146','smooth'),pigment(name+' blades',body),pigment(name+' stripe','e4d79b' if form=='evergold' else 'e8e4d1' if form=='snowline' else body)]
            flowers=[pigment(name+' flowers','ceb8d4' if form in ['mondo','black'] else 'b1a987','petal'),pigment(name+' seeds','c8ba82','pollen'),palette[0]]
            g,b=geometry(form,height)
            root=bpy.data.objects.new(f'Plant_{idx:02d}_{name}',None);scene.collection.objects.link(root)
            root['catalogue_id']=idx;root['botanical_notes']=botanical
            organs=[g.object('Foliage',palette),b.object('Bloom',flowers)]
            for obj in organs:obj.parent=root
            def export(root,organs,path):
                bpy.ops.object.select_all(action='DESELECT')
                for obj in [root,*organs]:obj.select_set(True)
                bpy.context.view_layer.objects.active=organs[0]
                bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
            export(root,organs,ROOT/'assets/plants'/f'plant_{idx:02d}.glb')
            tris=sum(len(f)-2 for f in g.f+b.f)
            mature.append({'id':idx,'name':name,'vertices':len(g.v)+len(b.v),'triangles':tris,'path':f'assets/plants/plant_{idx:02d}.glb','morphology_version':3,'source':'art_source/low_grasses.blend'})
            h=max(v[2] for v in g.v)
            root.location=((idx-136)%4*2,(idx-136)//4*3,0)
            youngroot=bpy.data.objects.new(f'Growth_{idx:02d}_{name}',None);scene.collection.objects.link(youngroot)
            early=[]
            for label,fraction in [('Seedling',.20),('Juvenile',.52)]:
                seed,_=geometry(form,height,True)
                seed.v=[tuple(Vector(v)*fraction) for v in seed.v]
                obj=seed.object(label,palette);obj.parent=youngroot;early.append(obj)
            buds=Geometry()
            for cluster in range(5):
                a=cluster*2.39996
                buds.ellipsoid((math.cos(a)*.08,math.sin(a)*.08,height*.75),(.002,.002,.006),0,3,5)
            obj=buds.object('Buds',flowers);obj.parent=youngroot;early.append(obj)
            export(youngroot,early,ROOT/'assets/plants/growth'/f'growth_{idx:02d}.glb')
            growth.append({'id':idx,'name':name,'family':'low_grass','height':round(h,4),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in early)})
            youngroot.location=root.location+Vector((0,1,0))
        # Write only this authored scene and its dependencies, leaving the user's file alone.
        for image in maps.values():
            for im in image:
                if not im.packed_file:im.pack()
        bpy.data.libraries.write(str(ROOT/'art_source/low_grasses.blend'),{scene},fake_user=True,compress=True)
        # Pigments are reproducible and packed into both exports and the source
        # library. Avoid accumulating intermediate PNG/JPEG files on each rebuild.
        for path in intermediates:path.unlink(missing_ok=True)
        (ROOT/'art_source/botanical_manifest.json').write_text(json.dumps(mature,indent=2)+'\n')
        (ROOT/'art_source/plant_growth_manifest.json').write_text(json.dumps(growth,indent=2)+'\n')
        (ROOT/'scripts/plant_profiles.gd').write_text('class_name GardenPlantProfiles\nextends RefCounted\n\n# Generated from the authored mature foliage, in garden metres.\nconst HEIGHTS='+json.dumps([r['height'] for r in growth])+'\n')
        return {'plants':12,'mature_triangles':sum(x['triangles'] for x in mature[136:]),'preserved_scene':previous.name}
    finally:bpy.context.window.scene=previous

if __name__=='__main__':print('LOW_GRASSES_EXPORT',build())
