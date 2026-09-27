"""Deterministic metre-scale, Godot Y-up asset authoring helpers for Blender."""
import bpy, math, numpy as np
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
TEX=ROOT/'assets/textures/detail'
TEX.mkdir(parents=True,exist_ok=True)

def vec(p): return Vector((p[0],-p[2],p[1]))
def scene_new(name):
    s=bpy.data.scenes.new(name)
    bpy.context.window.scene=s
    s.world=bpy.data.worlds.new(name+' World'); s.world.use_nodes=True
    s.world.node_tree.nodes['Background'].inputs[0].default_value=(.32,.38,.45,1)
    return s

def image(name,pixels,noncolor=False):
    h,w=pixels.shape[:2]; im=bpy.data.images.new(name,width=w,height=h)
    if noncolor: im.colorspace_settings.name='Non-Color'
    im.pixels.foreach_set(pixels.astype(np.float32).ravel()); im.filepath_raw=str(TEX/(name+'.png')); im.file_format='PNG'; im.save(); im.pack()
    return im

MAT={}
def mat(name,color,style=None,rough=.8,metal=0,alpha=1):
    if name in MAT:return MAT[name]
    m=bpy.data.materials.new(name); m.use_nodes=True; m.diffuse_color=(*color,alpha)
    b=m.node_tree.nodes.get('Principled BSDF'); b.inputs['Base Color'].default_value=(*color,alpha); b.inputs['Roughness'].default_value=rough; b.inputs['Metallic'].default_value=metal; b.inputs['Alpha'].default_value=alpha
    if alpha<1: m.surface_render_method='DITHERED'; m.use_transparency_overlap=False
    if style:
        n=512; y,x=np.mgrid[0:n,0:n]/n; rng=np.random.default_rng(sum(map(ord,name)))
        noise=rng.random((n,n))-.5
        if style=='wood':
            grain=np.sin(x*280+np.sin(y*16)*2+np.sin(x*36+y*8)*3)
            field=.87+.10*grain+.07*np.sin(x*760+y*10)+noise*.07
            for cx,cy in [(.24,.32),(.73,.78)]:
                r=np.sqrt(((x-cx)*4)**2+((y-cy)*1.1)**2)
                field-=.20*np.exp(-r*14)*(1+.4*np.sin(r*220))
        elif style=='fur': field=.9+.07*np.sin(x*850+np.sin(y*38)*3)+noise*.13
        elif style=='tabby':
            stripes=np.maximum(0,np.sin(x*65+np.sin(y*13)*3+np.sin(y*27)*.7))**4
            field=(.96-.80*stripes)+noise*.08+.04*np.sin(x*930+y*17)
        elif style=='feather': field=.87+.11*np.cos(x*240+abs(y-.5)*80)+noise*.04
        elif style=='scales': field=.8+.18*np.abs(np.sin(x*95+np.floor(y*32)%2*1.57)*np.sin(y*100))+noise*.04
        else:
            # Isotropic mineral/cloud variation, without directional wood-like bands.
            field=np.full((n,n),.91)
            for grid,weight in [(4,.12),(8,.09),(16,.065),(32,.04),(64,.022)]:
                lattice=rng.random((grid+1,grid+1))-.5
                gx=x*grid;gy=y*grid;ix=gx.astype(int);iy=gy.astype(int);tx=gx-ix;ty=gy-iy
                tx=tx*tx*(3-2*tx);ty=ty*ty*(3-2*ty)
                field+=weight*((1-ty)*((1-tx)*lattice[iy,ix]+tx*lattice[iy,ix+1])+ty*((1-tx)*lattice[iy+1,ix]+tx*lattice[iy+1,ix+1]))
            field+=noise*(.09 if style=='stone' else .045)
        rgba=np.ones((n,n,4)); rgba[:,:,:3]=np.clip(field[:,:,None]*np.array(color),0,1)
        # Blender stores generated pixels in linear light and encodes PNG on save.
        tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image(name+'_color',rgba); m.node_tree.links.new(tex.outputs['Color'],b.inputs['Base Color'])
        dy,dx=np.gradient(field); normal=np.ones((n,n,4)); normal[:,:,:3]=np.stack((-dx*.65,-dy*.65,np.ones_like(dx)),axis=-1); normal[:,:,:3]/=np.linalg.norm(normal[:,:,:3],axis=-1)[:,:,None]; normal[:,:,:3]=normal[:,:,:3]*.5+.5
        nt=m.node_tree.nodes.new('ShaderNodeTexImage'); nt.image=image(name+'_normal',normal,True)
        nm=m.node_tree.nodes.new('ShaderNodeNormalMap'); m.node_tree.links.new(nt.outputs['Color'],nm.inputs['Color']); m.node_tree.links.new(nm.outputs['Normal'],b.inputs['Normal'])
        rm=np.ones((n,n,4)); rm[:,:,:3]=np.clip(rough+(field-.9)*.12,0,1)[:,:,None]
        rt=m.node_tree.nodes.new('ShaderNodeTexImage'); rt.image=image(name+'_roughness',rm,True); m.node_tree.links.new(rt.outputs['Color'],b.inputs['Roughness'])
    MAT[name]=m; return m

def palette():
    return dict(wood=mat('Weathered cedar',(.30,.17,.075),'wood'),darkwood=mat('Oiled oak',(.115,.068,.031),'wood'),stone=mat('Carved limestone',(.43,.42,.34),'stone'),clay=mat('Fired terracotta',(.46,.20,.10),'clay'),soil=mat('Potting soil',(.065,.039,.019),'stone'),metal=mat('Aged bronze',(.18,.15,.095),'stone',.43,.72),iron=mat('Graphite iron',(.038,.048,.045),rough=.4,metal=.82),glass=mat('Greenhouse glass',(.65,.83,.77),rough=.12,alpha=.17),water=mat('Garden water',(.07,.24,.21),rough=.17,alpha=.72),leaf=mat('Lily leaf',(.10,.23,.055),'feather'),ivory=mat('Ivory',(.72,.66,.52)),black=mat('Wet obsidian',(.009,.012,.011),rough=.2))

def pivot(name,p=(0,0,0),parent=None):
    o=bpy.data.objects.new(name,None); bpy.context.scene.collection.objects.link(o); o.parent=parent; o.location=vec(p); return o

def finish(o,name,p,material,parent):
    o.name=name; o.parent=parent; o.location=vec(p)
    if material:o.data.materials.append(material)
    return o

def ell(name,p,size,material,parent,segments=24,rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings)
    o=finish(bpy.context.object,name,p,material,parent); o.scale=(size[0]/2,size[2]/2,size[1]/2)
    for f in o.data.polygons:f.use_smooth=True
    return o

def box(name,p,size,material,parent,bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o=finish(bpy.context.object,name,p,material,parent); o.scale=(size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft worn edges','BEVEL'); mod.width=min(bevel,min(size)*.2); mod.segments=3
        bpy.ops.object.modifier_apply(modifier=mod.name)
        mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL'); bpy.ops.object.modifier_apply(modifier=mod.name)
    return o

def rod(name,a,b,r,material,parent,r2=None,vertices=16):
    a,b=vec(a),vec(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r,radius2=r if r2 is None else r2,depth=d.length)
    o=bpy.context.object; o.name=name;o.parent=parent;o.location=(a+b)*.5;o.rotation_euler=d.to_track_quat('Z','Y').to_euler();o.data.materials.append(material)
    for f in o.data.polygons:f.use_smooth=True
    return o

def lathe(name,profile,material,parent,segments=64):
    vs=[]; fs=[]
    for r,y in profile:
        for j in range(segments):
            a=j*math.tau/segments;vs.append(vec((r*math.cos(a),y,r*math.sin(a))))
    for k in range(len(profile)-1):
        for j in range(segments):
            a=k*segments+j;b=k*segments+(j+1)%segments;fs.append((a,a+segments,b+segments,b))
    return mesh(name,vs,fs,material,parent)

def mesh(name,vs,fs,material,parent,converted=True):
    me=bpy.data.meshes.new(name); me.from_pydata(vs if converted else [vec(p) for p in vs],[],fs);me.update()
    o=bpy.data.objects.new(name,me);bpy.context.scene.collection.objects.link(o);o.parent=parent;me.materials.append(material)
    for f in me.polygons:f.use_smooth=True
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.015);bpy.ops.object.mode_set(mode='OBJECT')
    return o

def leaf(name,a,b,width,material,parent):
    a,b=Vector(a),Vector(b);d=b-a;cross=d.cross(Vector((0,1,0))).normalized()*width
    return mesh(name,[a,a+d*.38+cross,a+d*.76+cross*.68,b,a+d*.76-cross*.68,a+d*.38-cross,(a+b)*.5+Vector((0,.006,0))],[(0,1,6),(1,2,6),(2,3,6),(3,4,6),(4,5,6),(5,0,6)],material,parent,False)

def merge_meshes(root):
    # One mesh per articulation pivot and material; retain all moving transforms.
    groups={}
    for o in list(root.children_recursive):
        if o.type=='MESH': groups.setdefault((o.parent,o.data.materials[0]),[]).append(o)
    for (parent,material),obs in groups.items():
        if len(obs)<2:continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in obs:o.select_set(True)
        bpy.context.view_layer.objects.active=obs[0];bpy.ops.object.join();obs[0].name=parent.name+' '+material.name

def export(root,folder,kind):
    merge_meshes(root)
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
    for o in root.children_recursive:o.select_set(True)
    p=ROOT/'assets'/folder/(kind+'.glb');p.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(p),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True,export_extras=True)
    root.hide_set(True)

def save(name):
    for im in bpy.data.images:
        if im.source=='FILE' and not im.packed_file:im.pack()
    bpy.data.libraries.write(str(ROOT/'art_source'/name),{bpy.context.scene},fake_user=True,compress=True)

def fuse_surface(objects,voxel=.009):
    """Blend overlapping anatomical volumes into one continuous editable surface."""
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=objects[0]
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    rem=o.modifiers.new('Continuous anatomy','REMESH');rem.mode='VOXEL';rem.voxel_size=voxel;rem.use_smooth_shade=True;bpy.ops.object.modifier_apply(modifier=rem.name)
    smooth=o.modifiers.new('Surface relaxation','SMOOTH');smooth.factor=.7;smooth.iterations=3;bpy.ops.object.modifier_apply(modifier=smooth.name)
    dec=o.modifiers.new('Game surface budget','DECIMATE');dec.ratio=.45;bpy.ops.object.modifier_apply(modifier=dec.name)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.01);bpy.ops.object.mode_set(mode='OBJECT')
    return o
