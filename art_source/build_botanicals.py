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
scene=bpy.data.scenes.get('ZendGarden_AssetWorkshop')
if scene is None: scene=bpy.data.scenes.new('ZendGarden_AssetWorkshop')
bpy.context.window.scene=scene
random.seed(4207)

def material(name,hexcolor,roughness=.8):
    m=bpy.data.materials.new(name); m.use_nodes=True
    col=tuple(int(hexcolor[i:i+2],16)/255 for i in (0,2,4))
    # glTF values are linear, unlike the supplied art-direction swatches.
    col=tuple(((c+.055)/1.055)**2.4 if c>.04045 else c/12.92 for c in col)
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*col,1)
    bs.inputs['Roughness'].default_value=roughness
    bs.inputs['Specular IOR Level'].default_value=.25
    m.diffuse_color=(*col,1); m.use_backface_culling=False
    return m

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

class Geometry:
    def __init__(self): self.v=[]; self.f=[]; self.mi=[]; self.uv={}
    def face(self,indices,mat): self.f.append(indices); self.mi.append(mat)
    def tube(self,points,radii,mat=0,sides=6):
        points=[Vector(p) for p in points]; start=len(self.v)
        for i,p in enumerate(points):
            d=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized()
            up=Vector((0,0,1)) if abs(d.z)<.9 else Vector((1,0,0))
            a=d.cross(up).normalized(); b=d.cross(a).normalized()
            for j in range(sides): self.v.append(tuple(p+(a*cos(j*2*pi/sides)+b*sin(j*2*pi/sides))*radii[i]))
        for i in range(len(points)-1):
            for j in range(sides): self.face((start+i*sides+j,start+i*sides+(j+1)%sides,start+(i+1)*sides+(j+1)%sides,start+(i+1)*sides+j),mat)
        self.face(tuple(start+j for j in reversed(range(sides))),mat)
        self.face(tuple(start+(len(points)-1)*sides+j for j in range(sides)),mat)
    def leaf(self,base,tip,width,mat=1,curl=.12,segments=5,lobed=False):
        base=Vector(base); tip=Vector(tip); d=tip-base
        side=d.cross(Vector((0,0,1))).normalized()
        if side.length<.01: side=Vector((1,0,0))
        start=len(self.v)
        for j in range(segments+1):
            t=j/segments; w=sin(pi*t)**.85*width
            if lobed: w*=.7+.3*cos(t*6*pi)
            mid=base+d*t+Vector((0,0,sin(pi*t)*d.length*curl))
            self.v.extend([tuple(mid-side*w-Vector((0,0,w*.18))),tuple(mid+Vector((0,0,w*.1))),tuple(mid+side*w-Vector((0,0,w*.18)))])
        for j in range(segments+1):
            for side in range(3): self.uv[start+j*3+side]=(side*.5,j/segments)
        for j in range(segments):
            k=start+j*3
            self.face((k+1,k+4,k+3,k),mat); self.face((k+2,k+5,k+4,k+1),mat)
    def ellipsoid(self,c,scale,mat=1,rings=5,sides=8,ribs=0):
        start=len(self.v); c=Vector(c)
        for i in range(rings+1):
            theta=pi*i/rings
            for j in range(sides):
                a=2*pi*j/sides; r=1+ribs*cos(a*10)
                self.v.append(tuple(c+Vector((sin(theta)*cos(a)*scale[0]*r,sin(theta)*sin(a)*scale[1]*r,cos(theta)*scale[2]))))
        for i in range(rings):
            for j in range(sides): self.face((start+(i+1)*sides+j,start+(i+1)*sides+(j+1)%sides,start+i*sides+(j+1)%sides,start+i*sides+j),mat)
    def object(self,name,mats):
        mesh=bpy.data.meshes.new(name); mesh.from_pydata(self.v,[],self.f); mesh.update()
        uv=mesh.uv_layers.new(name='Botanical UV')
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                vi=mesh.loops[li].vertex_index; point=mesh.vertices[vi].co
                uv.data[li].uv=self.uv.get(vi,(point.x*.7+point.y*.7,point.z*.7))
        for m in mats: mesh.materials.append(m)
        obj=bpy.data.objects.new(name,mesh); scene.collection.objects.link(obj)
        for p,mi in zip(mesh.polygons,self.mi): p.material_index=mi; p.use_smooth=True
        return obj

def flower(g,center,size,style,mat=0):
    c=Vector(center)
    if style=='spike':
        for k in range(7):
            for j in range(4):
                a=j*pi/2+k*.5
                g.ellipsoid(c+Vector((cos(a)*size*.32,sin(a)*size*.32,k*size*.22)),(size*.24,size*.17,size*.27),mat,3,6)
    elif style=='rose':
        for k in range(4):
            for j in range(7+k*2):
                a=j*2*pi/(7+k*2)+k*.7
                r=size*(.2+k*.23)
                g.leaf(c+Vector((cos(a)*r*.3,sin(a)*r*.3,k*size*.06)),c+Vector((cos(a)*r,sin(a)*r,size*(.5-k*.16))),size*(.25+k*.035),mat,.5,5)
        g.ellipsoid(c+Vector((0,0,size*.12)),(size*.16,)*3,mat,4,7)
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
manifest=[]
for idx,row in enumerate(specs):
    name,category,color,layer,days,climate,animal=row
    random.seed(idx*7381+69)
    foliage=Geometry(); bloom=Geometry()
    petal=material(name+' petals / fruit',{'Lavender':'8164b5','Bottlebrush':'bb373c','Wattle':'ecc72e','Banksia':'d6a53b','Grevillea':'d96b55','Rosemary':'9eabcc','Tomato':'c84432','Chilli':'c53728','Aubergine':'4f305d','Pea':'739443','Cucumber':'4c7038','Apple':'c35d43','Lemon':'e3c64b','Olive':'454c31','Blueberry':'536387','Lilly pilly':'b5496e','Poppy':'da5845','Chamomile':'f6f1db'}.get(name,color),.72)
    mats=[stem,*leaves,bark]
    bloom_mats=[petal,disk if name in ['Sunflower','Poppy'] else pollen,pollen]
    # Species-specific foliage colours do not recolour flowers or menu swatches.
    accent=material('Leaf '+name+' characteristic foliage',{'Japanese maple':'943f32','Blue fescue':'799fa7','Lettuce':'9eba65','Beetroot':'9a3c50'}.get(name,'547536'))
    mats += [smooth_bark,peeling_bark,accent]
    botanical_forms.build(name,category,layer,foliage,bloom,flower)
    root=bpy.data.objects.new('Plant_%02d_%s'%(idx,name.replace(' ','_')),None); scene.collection.objects.link(root)
    leaf_obj=foliage.object('Foliage',mats); leaf_obj.parent=root
    bloom_obj=bloom.object('Bloom',bloom_mats); bloom_obj.parent=root
    bpy.ops.object.select_all(action='DESELECT')
    for ob in [root,leaf_obj,bloom_obj]: ob.select_set(True)
    bpy.context.view_layer.objects.active=leaf_obj
    path=ROOT+'/assets/plants/plant_%02d.glb'%idx
    bpy.ops.export_scene.gltf(filepath=path,export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
    manifest.append({'id':idx,'name':name,'vertices':len(foliage.v)+len(bloom.v),'path':path,'morphology_version':2})
    # Keep a readable botanical library arranged in the source workshop.
    root.location=(idx%10*4,idx//10*8,0)
json.dump(manifest,open(ROOT+'/art_source/botanical_manifest.json','w'),indent=2)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/art_source/botanical_library.blend')
result={'species':len(manifest),'vertices':sum(x['vertices'] for x in manifest),'source':ROOT+'/art_source/botanical_library.blend'}
