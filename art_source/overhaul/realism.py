"""Generated surface assets and game-ready short fur, authored in Blender.

Generated images supply albedo only. Geometry, normals and pigment markings are
authored independently; colour is not treated as a physically measured height.
"""
import bpy, math, hashlib
import numpy as np
from mathutils import Vector
from pathlib import Path

FILES = Path(__file__).resolve().parent / 'textures/generated'
PIXELS = {}

def pixels(filename, size=1024):
    key=(filename,size)
    if key not in PIXELS:
        im=bpy.data.images.load(str(FILES/filename),check_existing=False)
        im.scale(size,size)
        values=np.empty(size*size*4,dtype=np.float32);im.pixels.foreach_get(values)
        PIXELS[key]=values.reshape(size,size,4).copy()
        bpy.data.images.remove(im)
    return PIXELS[key].copy()

def albedo(name,color,style,size):
    filename={'wood':'cedar-albedo.png','fur':'short-fur-albedo.png',
              'tabby':'short-fur-albedo.png','feather':'contour-feathers-albedo.png'}.get(style)
    if style=='feather' and 'flight feathers' in name:filename='feather-vane-albedo.png'
    if style=='stone' and any(s in name.lower() for s in ['limestone','plaster','stone']):
        filename='limestone-albedo.png'
    if not filename:return None
    data=pixels(filename,size)
    # Blender reads texture pixels in linear light. Preserve the generated
    # relative colour/microvariation while tinting to the species/material.
    rgb=data[:,:,:3];mean=np.mean(rgb,axis=(0,1))
    data[:,:,:3]=np.clip(rgb/np.maximum(mean,.001)*np.array(color)*.96,0,1)
    if style=='tabby':
        y,x=np.mgrid[0:size,0:size]/size
        # Fine broken mackerel markings: longitudinal body UVs place these
        # around the flanks. Subtle stripe edges retain the underfur detail.
        s=np.sin(x*math.tau*9+np.sin(y*math.tau*2)*.46)
        stripes=np.clip((s-.56)*3.6,0,1)
        broken=.82+.18*np.sin(y*math.tau*5+x*13)
        data[:,:,:3]*=(1-stripes*broken*.46)[:,:,None]
    return data

def fur_material(coat):
    from common_hq import MATS,texture
    name='Fur cards '+coat.name
    if name in MATS:return MATS[name]
    m=bpy.data.materials.new(name);m.use_nodes=True
    m.surface_render_method='DITHERED';m.use_transparency_overlap=False
    m.use_backface_culling=False
    b=m.node_tree.nodes['Principled BSDF'];b.inputs['Roughness'].default_value=.88
    b.inputs['Specular IOR Level'].default_value=.18
    b.inputs['Sheen Weight'].default_value=.05
    rgba=pixels('fur-card.png',512)
    mean=np.mean(rgba[:,:,:3][rgba[:,:,3]>.8],axis=0)
    # Fine card hair should not introduce large dark pigment flecks. The
    # underlying coat already carries markings; cards soften its silhouette.
    variation=np.clip(rgba[:,:,:3]/np.maximum(mean,.001),.70,1.30)
    rgba[:,:,:3]=np.clip((.82+.18*variation)*np.array(coat.diffuse_color[:3]),0,1)
    t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=texture(name+'_albedo',rgba)
    m.node_tree.links.new(t.outputs['Color'],b.inputs['Base Color'])
    m.node_tree.links.new(t.outputs['Alpha'],b.inputs['Alpha'])
    MATS[name]=m
    return m

def groom(root,kind):
    """Lay small alpha-textured curved strips along the actual skin surface.

    Each card shares its existing articulation parent, so authored clips still
    animate the hair. No simulation, thousands of cylinders or extra joints.
    """
    from common_hq import mesh
    if kind not in ['cat','dog','fox','rabbit','wombat','echidna','kangaroo','kangaroo_joey']:return
    length={'cat':.009,'dog':.022,'fox':.019,'rabbit':.013,'wombat':.009,'echidna':.007,'kangaroo':.010,'kangaroo_joey':.010}[kind]
    rng=np.random.default_rng(int(hashlib.sha256(kind.encode()).hexdigest()[:8],16))
    groups={}
    bpy.context.view_layer.update()
    for o in list(root.children_recursive):
        if o.type!='MESH' or not o.data.materials:continue
        coat=o.data.materials[0]
        if not any(w in coat.name for w in ['coat','animal fur']):continue
        if any(w in o.name.lower() for w in ['whisker','claw','ear recess','muzzle pad']):continue
        # Mostly body/head/tail; small foot geometry gets few short tufts.
        area=sum(p.area for p in o.data.polygons)*abs(o.scale.x*o.scale.y*o.scale.z)**(2/3)
        count=min(580,max(8,int(area*1250)))
        polys=list(o.data.polygons)
        weights=np.array([p.area for p in polys]);weights/=max(1e-9,weights.sum())
        normal_matrix=o.matrix_basis.to_3x3().inverted().transposed()
        for index in rng.choice(len(polys),count,p=weights):
            poly=polys[index]
            # Multi-material remeshed torsos include pale chest fur. Match
            # each card to that polygon rather than adding brown chest dots.
            local_coat=o.data.materials[poly.material_index]
            if not any(w in local_coat.name for w in ['coat','animal fur']):continue
            mat=fur_material(local_coat);key=(o.parent,mat)
            vs,fs,uvs=groups.setdefault(key,([],[],[]))
            pts=[o.data.vertices[i].co for i in poly.vertices]
            blend=rng.random(len(pts));blend/=blend.sum()
            p=o.matrix_basis@sum((v*float(w) for v,w in zip(pts,blend)),Vector())
            n=(normal_matrix@poly.normal).normalized()
            flow=Vector((0,-1,-.25)) if 'Tail' in o.parent.name else Vector((0,-.15,-1)) if 'Head' in o.parent.name else Vector((0,-1,-.5))
            tangent=(flow-n*flow.dot(n))
            if tangent.length<.01:tangent=n.cross(Vector((1,0,0)))
            tangent.normalize();across=n.cross(tangent).normalized()
            hair=length*rng.uniform(.72,1.2)
            p+=n*.0006
            offset=len(vs)
            for row in range(4):
                t=row/3
                center=p+tangent*hair*t+n*hair*(.14*t+.28*t*t)
                width=hair*.34
                for side in [-1,1]:
                    # mesh() consumes game coordinates; p is Blender local.
                    point=center+across*width*side
                    vs.append((point.x,point.z,-point.y));uvs.append(((side+1)/2,t))
            # Tangent x across points outward. Reversing this winding lights
            # strips from inside the animal and creates dark stippling.
            for row in range(3):fs.append((offset+row*2,offset+row*2+2,offset+row*2+3,offset+row*2+1))
    total=0
    for (parent,mat),(vs,fs,uvs) in groups.items():
        card=mesh('Laid short fur',vs,fs,mat,parent,False)
        for poly in card.data.polygons:
            for li in poly.loop_indices:card.data.uv_layers.active.data[li].uv=uvs[card.data.loops[li].vertex_index]
        total+=len(fs)*2
    root['fur_card_triangles']=total

def coat_uv(o):
    """One connected cylindrical UV field for remeshed anatomical coat parts."""
    if o.type!='MESH' or not o.data.uv_layers:return
    points=[o.matrix_basis@v.co for v in o.data.vertices]
    lo=min(p.y for p in points);hi=max(p.y for p in points)
    cz=(min(p.z for p in points)+max(p.z for p in points))*.5
    for poly in o.data.polygons:
        values=[]
        for li in poly.loop_indices:
            p=points[o.data.loops[li].vertex_index]
            # generated hairs run down V; longitudinal flow follows body axis.
            values.append((li,(math.atan2(p.z-cz,p.x)+math.pi)/math.tau,(p.y-lo)/max(.001,hi-lo)))
        seam=max(v[1] for v in values)-min(v[1] for v in values)>.5
        for li,u,v in values:o.data.uv_layers.active.data[li].uv=(u+1 if seam and u<.5 else u,v)
