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
    if style in ['fur','tabby']:
        data=np.tile(pixels(filename,size//4),(4,4,1))
    else:data=pixels(filename,size)
    # Blender reads texture pixels in linear light. Preserve the generated
    # relative colour/microvariation while tinting to the species/material.
    rgb=data[:,:,:3];mean=np.mean(rgb,axis=(0,1))
    data[:,:,:3]=np.clip(rgb/np.maximum(mean,.001)*np.array(color)*.96,0,1)
    if style=='tabby':
        y,x=np.mgrid[0:size,0:size]/size
        # Fine broken mackerel markings: longitudinal body UVs place these
        # around the flanks. Subtle stripe edges retain the underfur detail.
        s=np.sin(y*math.tau*16+np.sin(x*math.tau*2)*.46)
        stripes=np.clip((s-.56)*3.6,0,1)
        broken=.82+.18*np.sin(x*math.tau*5+y*13)
        data[:,:,:3]*=(1-stripes*broken*.46)[:,:,None]
    return data

def fur_material(coat):
    from common_hq import MATS,texture
    name='Fur cards '+coat.name.split('.')[0]+' fine'
    if name in MATS:return MATS[name]
    m=bpy.data.materials.new(name);m.use_nodes=True
    m.surface_render_method='DITHERED';m.use_transparency_overlap=False
    m.use_backface_culling=False
    b=m.node_tree.nodes['Principled BSDF'];b.inputs['Roughness'].default_value=.88
    b.inputs['Specular IOR Level'].default_value=.18
    b.inputs['Sheen Weight'].default_value=.05
    rgba=pixels('fine-fur-card.png',512)
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
    if kind not in ['cat','dog','fox','rabbit','wombat','echidna','kangaroo','kangaroo_joey','bee','blue_banded_bee','emperor_gum_moth']:return
    insect=kind in ['bee','blue_banded_bee','emperor_gum_moth']
    length={'cat':.005,'dog':.015,'fox':.012,'rabbit':.008,'wombat':.006,'echidna':.005,'kangaroo':.006,'kangaroo_joey':.006,'bee':.002,'blue_banded_bee':.002,'emperor_gum_moth':.0025}[kind]
    rng=np.random.default_rng(int(hashlib.sha256(kind.encode()).hexdigest()[:8],16))
    groups={}
    bpy.context.view_layer.update()
    for o in list(root.children_recursive):
        if o.type!='MESH' or not o.data.materials:continue
        coat=o.data.materials[0]
        if not any(w in coat.name for w in ['coat','animal fur','fuzz']):continue
        if any(w in o.name.lower() for w in ['whisker','claw','ear recess','muzzle pad']):continue
        # Mostly body/head/tail; small foot geometry gets few short tufts.
        area=sum(p.area for p in o.data.polygons)*abs(o.scale.x*o.scale.y*o.scale.z)**(2/3)
        count=min(280 if insect else 1450 if kind in ['dog','fox'] else 1050,max(8,int(area*(45000 if insect else 2200))))
        polys=list(o.data.polygons)
        weights=np.array([p.area for p in polys]);weights/=max(1e-9,weights.sum())
        normal_matrix=o.matrix_basis.to_3x3().inverted().transposed()
        for index in rng.choice(len(polys),count,p=weights):
            poly=polys[index]
            # Multi-material remeshed torsos include pale chest fur. Match
            # each card to that polygon rather than adding brown chest dots.
            local_coat=o.data.materials[poly.material_index]
            if not any(w in local_coat.name for w in ['coat','animal fur','fuzz']):continue
            rig=next((m.object for m in o.modifiers if m.type=='ARMATURE'),None)
            mat=fur_material(local_coat);key=(o.parent,mat,rig)
            vs,fs,uvs,weights,normals=groups.setdefault(key,([],[],[],[],[]))
            pts=[o.data.vertices[i].co for i in poly.vertices]
            blend=rng.random(len(pts));blend/=blend.sum()
            influence={}
            if rig:
                for index,amount in zip(poly.vertices,blend):
                    for group in o.data.vertices[index].groups:
                        name=o.vertex_groups[group.group].name
                        influence[name]=influence.get(name,0)+group.weight*float(amount)
            p=o.matrix_basis@sum((v*float(w) for v,w in zip(pts,blend)),Vector())
            n=(normal_matrix@poly.normal).normalized()
            foot='Paw' in o.parent.name
            if foot and n.z<.15:continue
            flow=Vector((0,-1,-.25)) if 'Tail' in o.parent.name else Vector((0,-.15,-1)) if 'Head' in o.parent.name else Vector((0,-1,-.5))
            tangent=(flow-n*flow.dot(n))
            if tangent.length<.01:tangent=n.cross(Vector((1,0,0)))
            tangent.normalize();across=n.cross(tangent).normalized()
            hair=(min(length,.003) if foot else length)*rng.uniform(.72,1.2)
            p+=n*.0006
            offset=len(vs)
            for row in range(4):
                t=row/3
                center=p+tangent*hair*t+n*hair*(.14*t+.28*t*t)
                width=hair*.22*(1-.45*t)
                for side in [-1,1]:
                    # mesh() consumes game coordinates; p is Blender local.
                    point=center+across*width*side
                    vs.append((point.x,point.z,-point.y));uvs.append(((side+1)/2,t));weights.append(influence);normals.append(tuple(n))
            # Tangent x across points outward. Reversing this winding lights
            # strips from inside the animal and creates dark stippling.
            for row in range(3):fs.append((offset+row*2,offset+row*2+2,offset+row*2+3,offset+row*2+1))
    total=0
    for (parent,mat,rig),(vs,fs,uvs,weights,normals) in groups.items():
        card=mesh('Laid short fur',vs,fs,mat,parent,False)
        for poly in card.data.polygons:
            poly.use_smooth=True
            for li in poly.loop_indices:card.data.uv_layers.active.data[li].uv=uvs[card.data.loops[li].vertex_index]
        card.data.normals_split_custom_set_from_vertices(normals)
        if rig:
            names={n for influence in weights for n in influence}
            vg={n:card.vertex_groups.new(name=n) for n in names}
            for index,influence in enumerate(weights):
                weight_sum=sum(influence.values())
                for name,value in influence.items():vg[name].add([index],value/max(.001,weight_sum),'REPLACE')
            modifier=card.modifiers.new('Fur follows skin','ARMATURE');modifier.object=rig
            modifier.use_deform_preserve_volume=True
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
