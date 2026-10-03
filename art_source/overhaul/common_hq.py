"""Garden-only MCP authoring: metre-scale Y-up geometry, PBR maps and NLA clips.

Never clears Blender data or changes another scene. Each export selects one asset.
"""
import bpy, math, json, sys, hashlib, struct
from pathlib import Path
import numpy as np
from mathutils import Vector, Matrix, Euler

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'art_source/detail'))
import common as base
vec, pivot, ell, box, rod, lathe, leaf = base.vec, base.pivot, base.ell, base.box, base.rod, base.lathe, base.leaf
mesh, fuse_surface = base.mesh, base.fuse_surface
TEX = ROOT / 'art_source/overhaul/textures'
SOURCE = ROOT / 'art_source/overhaul'
TEX.mkdir(parents=True, exist_ok=True)
MATS = {}
SCENES = {}

def scene(category):
    key = 'ZendGarden_HQ_' + category
    s = SCENES.get(key)
    if not s:
        s = bpy.data.scenes.new(key)
        s.unit_settings.system = 'METRIC'
        s.render.fps = 30
        s.world = bpy.data.worlds.new(key + '_World')
        s.world.use_nodes = True
        s.world.node_tree.nodes['Background'].inputs[0].default_value = (.35, .40, .46, 1)
        SCENES[key] = s
    bpy.context.window.scene = s
    return s

def texture(name, values, noncolor=False):
    n = values.shape[0]
    im = bpy.data.images.new(name, width=n, height=n, alpha=True)
    im.alpha_mode='STRAIGHT'
    if noncolor: im.colorspace_settings.name = 'Non-Color'
    im.pixels.foreach_set(values.astype(np.float32).ravel())
    im.filepath_raw = str(TEX / (name + '.png'))
    im.file_format = 'PNG'
    im.save(); im.pack()
    return im

def material(name, color, style='stone', rough=.75, metal=0, alpha=1, size=1024):
    if name in MATS: return MATS[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.diffuse_color = (*color, alpha)
    bs = m.node_tree.nodes.get('Principled BSDF')
    bs.inputs['Base Color'].default_value = (*color, alpha)
    bs.inputs['Roughness'].default_value = rough
    bs.inputs['Metallic'].default_value = metal
    bs.inputs['Alpha'].default_value = alpha
    if alpha < 1:
        m.surface_render_method = 'DITHERED'
        m.use_transparency_overlap = False
    if style:
        y, x = np.mgrid[0:size, 0:size] / size
        rng = np.random.default_rng(int(hashlib.sha256(name.encode()).hexdigest()[:8], 16))
        noise = rng.random((size, size)) - .5
        field = np.ones((size, size)) * .96
        for grid, weight in [(3, .16), (7, .10), (17, .07), (43, .045)]:
            lattice = rng.random((grid+1, grid+1)) - .5
            gx, gy = x*grid, y*grid
            ix, iy = gx.astype(int), gy.astype(int)
            tx, ty = gx-ix, gy-iy
            tx, ty = tx*tx*(3-2*tx), ty*ty*(3-2*ty)
            field += weight*((1-ty)*((1-tx)*lattice[iy,ix]+tx*lattice[iy,ix+1])+ty*((1-tx)*lattice[iy+1,ix]+tx*lattice[iy+1,ix+1]))
        if style in ['wood', 'endgrain']:
            grain = x*210 + np.sin(y*8)*1.3 + np.sin(x*19+y*3)*2.1
            if style == 'endgrain': grain = np.sqrt((x-.46)**2+(y-.54)**2)*240
            field += .07*np.sin(grain) + .025*np.sin(grain*4.7) + noise*.028
            for cx, cy in [(.24,.32),(.73,.78)]:
                radius=np.sqrt(((x-cx)*3.6)**2+((y-cy)*.8)**2)
                field -= .25*np.exp(-radius*18)*(1+.3*np.sin(radius*190))
        elif style in ['fur', 'tabby']:
            field += .009*np.sin(x*950+np.sin(y*45)*2)+noise*.035
            if style=='tabby':
                stripes=np.maximum(0,np.sin(x*53+np.sin(y*14)*2.4+np.sin(y*25)*.6))**5
                field -= stripes*.61
        elif style == 'feather':
            shaft=np.abs(x-.5)
            field += .05*np.sin(y*610+shaft*120)+noise*.02
            field -= .12*np.exp(-shaft*170)
        elif style == 'scale':
            field += .06*np.cos(x*145 + (np.floor(y*45)%2)*math.pi)*np.cos(y*145)+noise*.018
        elif style == 'fabric': field += .05*np.sin(x*700)*np.sin(y*700)+noise*.02
        elif style == 'clay': field += .015*np.sin(y*560)+noise*.065
        else: field += noise*.05
        rgba=np.ones((size,size,4));rgba[:,:,:3]=np.clip(field[:,:,None]*np.array(color),0,1)
        from realism import albedo
        generated=albedo(name,color,style,size)
        if generated is not None:rgba=generated
        tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=texture(name+'_albedo',rgba)
        m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
        dy,dx=np.gradient(field)
        normal=np.ones((size,size,4))
        strength=5.0 if style in ['stone','clay'] else .65 if style in ['fur','tabby'] else 3.0
        normal[:,:,:3]=np.stack((-dx*strength,-dy*strength,np.ones_like(dx)),axis=-1)
        normal[:,:,:3]/=np.linalg.norm(normal[:,:,:3],axis=-1)[:,:,None]
        normal[:,:,:3]=normal[:,:,:3]*.5+.5
        nt=m.node_tree.nodes.new('ShaderNodeTexImage');nt.image=texture(name+'_normal',normal[::2,::2],True)
        nm=m.node_tree.nodes.new('ShaderNodeNormalMap');m.node_tree.links.new(nt.outputs['Color'],nm.inputs['Color']);m.node_tree.links.new(nm.outputs['Normal'],bs.inputs['Normal'])
        rm=np.ones((size,size,4));rm[:,:,:3]=np.clip(rough+(field-.96)*.18,.04,1)[:,:,None]
        if style not in ['fur','tabby','feather']:
            rt=m.node_tree.nodes.new('ShaderNodeTexImage');rt.image=texture(name+'_roughness',rm[::8,::8],True)
            m.node_tree.links.new(rt.outputs['Color'],bs.inputs['Roughness'])
        else:
            bs.inputs['Roughness'].default_value=.86 if style in ['fur','tabby'] else .79
            bs.inputs['Specular IOR Level'].default_value=.20
    MATS[name]=m
    return m

def palette():
    return dict(wood=material('HQ weathered cedar',(.33,.21,.11),'wood'),
        darkwood=material('HQ oiled oak',(.14,.08,.038),'wood'),
        stone=material('HQ warm limestone',(.48,.46,.38),'stone'),
        clay=material('HQ thrown terracotta',(.47,.20,.105),'clay'),
        soil=material('HQ potting loam',(.055,.032,.017),'stone'),
        metal=material('HQ aged bronze',(.25,.19,.095),'stone',.37,.75),
        iron=material('HQ graphite iron',(.032,.042,.039),'stone',.34,.83),
        zinc=material('HQ weathered zinc',(.30,.34,.34),'stone',.43,.78),
        glass=material('Greenhouse glass HQ',(.76,.89,.84),None,.095,alpha=.15),
        water=material('HQ still garden water',(.12,.28,.25),None,.14,alpha=.78),
        leaf=material('HQ lily leaf',(.09,.23,.065),'feather'),
        ivory=material('HQ warm ivory',(.72,.67,.55),'fur'),
        black=material('HQ glossy obsidian',(.004,.006,.005),None,.16))

def curve(name, points, radii, mat, parent, sides=12):
    """Swept smoothly tapering anatomical/wood tube; no cylinder seams."""
    points=[Vector(p) for p in points];vs=[];fs=[]
    for k,p in enumerate(points):
        tangent=points[min(k+1,len(points)-1)]-points[max(k-1,0)]
        tangent.normalize();axis=tangent.cross(Vector((0,1,0)))
        if axis.length<.001:axis=tangent.cross(Vector((1,0,0)))
        axis.normalize();cross=tangent.cross(axis).normalized()
        for j in range(sides):
            a=j*math.tau/sides;vs.append(p+(axis*math.cos(a)+cross*math.sin(a))*radii[k])
    for k in range(len(points)-1):
        for j in range(sides):
            a=k*sides+j;b=k*sides+(j+1)%sides;fs.append((a,b,b+sides,a+sides))
    fs += [tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))]
    return mesh(name,vs,fs,mat,parent,False)

def loft(name, profiles, mat, parent, sectors=32):
    """Closed sculpt profile along garden Z: (z, centre_y, half_width, half_height)."""
    vs=[];fs=[]
    for z,y,w,h in profiles:
        for j in range(sectors):
            a=j*math.tau/sectors;vs.append((w*math.cos(a),y+h*math.sin(a),z))
    for k in range(len(profiles)-1):
        for j in range(sectors):
            a=k*sectors+j;b=k*sectors+(j+1)%sectors;fs.append((a,b,b+sectors,a+sectors))
    fs += [tuple(range(sectors-1,-1,-1)),tuple(range((len(profiles)-1)*sectors,len(vs)))]
    o=mesh(name,vs,fs,mat,parent,False)
    # Organic longitudinal UVs keep coat stripes around the body, rather than
    # breaking into the unrelated islands of a mechanical smart unwrap.
    zmin=min(p[0] for p in profiles);zspan=max(p[0] for p in profiles)-zmin
    for poly in o.data.polygons:
        for li in poly.loop_indices:
            vi=o.data.loops[li].vertex_index
            row,around=divmod(vi,sectors)
            u=(profiles[row][0]-zmin)/max(.001,zspan)
            v=around/sectors
            if around==0 and any(o.data.loops[k].vertex_index%sectors==sectors-1 for k in poly.loop_indices):v=1
            o.data.uv_layers.active.data[li].uv=(u,v)
    sub=o.modifiers.new('Sculpt profile smoothing','SUBSURF');sub.levels=1
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=sub.name)
    return o

def feather(name, start, end, width, mat, parent, bend=.012):
    a,b=Vector(start),Vector(end);d=b-a
    lateral=d.cross(Vector((0,1,0))).normalized()
    vs=[];fs=[]
    for k in range(25):
        t=k/24
        # Rounded closed tips and an asymmetric vane rather than sharp comb
        # teeth. The narrow root stays underneath the overlapping coverts.
        w=width*(math.sin(math.pi*t)**.23 if 0<t<1 else .08)
        center=a+d*t+Vector((0,bend*math.sin(math.pi*t),0))
        vs += [center-lateral*w*.82,center+Vector((0,.002,0)),center+lateral*w]
    for k in range(24):
        for j in range(2):
            v=k*3+j;fs.append((v,v+3,v+4,v+1))
    o=mesh(name,vs,fs,mat,parent,False)
    for poly in o.data.polygons:
        for li in poly.loop_indices:
            row,col=divmod(o.data.loops[li].vertex_index,3)
            o.data.uv_layers.active.data[li].uv=(col/2,row/24)
    return o

def uv_grain(o):
    if o.type!='MESH' or not o.data.uv_layers:return
    me=o.data;long=max(range(3),key=lambda k:max(v.co[k] for v in me.vertices)-min(v.co[k] for v in me.vertices))
    others=[k for k in range(3) if k!=long]
    lo=[min(v.co[k] for v in me.vertices) for k in range(3)]
    extent=[max(v.co[k] for v in me.vertices)-lo[k] for k in range(3)]
    for poly in me.polygons:
        across=min(others,key=lambda k:abs(poly.normal[k]))
        for li in poly.loop_indices:
            p=me.vertices[me.loops[li].vertex_index].co
            me.uv_layers.active.data[li].uv=((p[across]-lo[across])/max(.001,extent[across]),(p[long]-lo[long])/max(.001,extent[long]))

def animate(root, clips):
    """One named NLA track per clip across articulated pivots, exported as one clip."""
    bpy.context.scene.frame_set(0)
    rest={o:(o.location.copy(),o.rotation_euler.copy(),o.scale.copy()) for o in [root]+list(root.children_recursive) if o.type=='EMPTY'}
    for o,(loc,rot,scale) in rest.items():
        o['hq_rest_location']=list(loc);o['hq_rest_rotation']=list(rot);o['hq_rest_scale']=list(scale)
    for name,seconds,pose in clips:
        frames=max(4,2*round(seconds*15))
        for o in rest:o.animation_data_create();o.animation_data.action=None
        for f in range(0,frames+1,1 if frames<10 else 2):
            t=f/frames
            for o,(loc,rot,scale) in rest.items():o.location=loc;o.rotation_euler=rot;o.scale=scale
            pose(t,rest)
            for o in rest:
                for prop in ['location','rotation_euler','scale']:o.keyframe_insert(prop,frame=f+1)
        for o in rest:
            action=o.animation_data.action
            action.name=root.name+'_'+name+'_'+o.name
            track=o.animation_data.nla_tracks.new();track.name=name
            strip=track.strips.new(name,1,action);strip.extrapolation='NOTHING'
            o.animation_data.action=None
    for o,(loc,rot,scale) in rest.items():o.location=loc;o.rotation_euler=rot;o.scale=scale
    root['hq_clips']=[c[0] for c in clips]
    for o in rest:
        for track in o.animation_data.nla_tracks:track.mute=True
    bpy.context.scene.frame_set(0)
    for o,(loc,rot,scale) in rest.items():o.location=loc;o.rotation_euler=rot;o.scale=scale

def retain_rest_transforms(path, transforms):
    """NLA exports must also have a useful unplayed/default glTF pose.

    Constant object channels can be optimized away independently per track.
    Preserve the authored local TRS in each node as well as in every clip.
    """
    raw=path.read_bytes();size=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+size]);tail=raw[20+size:]
    for node in doc['nodes']:
        rest=transforms.get(node.get('name'))
        if rest:
            node.pop('matrix',None)
            node.update(rest)
    for mat in doc.get('materials',[]):
        if mat.get('name','').startswith('Fur cards '):
            mat['alphaMode']='MASK';mat['alphaCutoff']=.28;mat['doubleSided']=True
    blob=json.dumps(doc,separators=(',',':')).encode();blob+=b' '*((-len(blob))%4)
    total=12+8+len(blob)+len(tail)
    path.write_bytes(struct.pack('<4sII',b'glTF',2,total)+struct.pack('<I4s',len(blob),b'JSON')+blob+tail)

def export(root, folder, kind):
    bpy.context.scene.frame_set(0)
    change=Matrix.Rotation(-math.pi/2,4,'X')
    transforms={}
    for o in [root]+list(root.children_recursive):
        if o.type=='EMPTY':
            basis=o.matrix_basis.copy()
            if 'hq_rest_location' in o:
                l=Vector(o['hq_rest_location']);rot=Euler(o['hq_rest_rotation'],'XYZ');sc=Vector(o['hq_rest_scale'])
                basis=Matrix.Translation(l)@rot.to_matrix().to_4x4()@Matrix.Diagonal((*sc,1.0))
                o.location=l;o.rotation_euler=rot;o.scale=sc
            loc,quat,scale=(change@basis@change.inverted()).decompose()
            transforms[o.name]={'translation':list(loc),'rotation':[quat.x,quat.y,quat.z,quat.w],'scale':list(scale)}
    for o in list(root.children_recursive):
        if o.type=='MESH' and o.data.materials and any('wood' in m.name.lower() or 'cedar' in m.name.lower() or 'oak' in m.name.lower() for m in o.data.materials):uv_grain(o)
    base.merge_meshes(root)
    # Joined groups inherit the active part's rotation. Bake that rotation into
    # mesh vertices so framing/LOD bounds describe the actual asset silhouette.
    bpy.ops.object.select_all(action='DESELECT')
    meshes=[o for o in root.children_recursive if o.type=='MESH']
    for o in meshes:o.select_set(True)
    if meshes:
        bpy.context.view_layer.objects.active=meshes[0]
        bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.ops.object.select_all(action='DESELECT');root.select_set(True)
    for o in root.children_recursive:o.select_set(True)
    bpy.context.view_layer.objects.active=root
    path=ROOT/'assets'/folder/(kind+'.glb');path.parent.mkdir(parents=True,exist_ok=True)
    animated=[o for o in [root]+list(root.children_recursive) if o.animation_data]
    for o in animated:
        for track in o.animation_data.nla_tracks:track.mute=False
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,
        export_yup=True,export_apply=True,export_extras=True,export_animations=True,
        export_animation_mode='NLA_TRACKS',export_merge_animation='NLA_TRACK',export_nla_strips=True,
        export_optimize_animation_size=True,export_optimize_animation_keep_anim_object=True,
        export_image_format='JPEG',export_image_quality=92)
    if root.get('hq_clips'):retain_rest_transforms(path,transforms)
    for o in animated:
        for track in o.animation_data.nla_tracks:track.mute=True
        if 'hq_rest_location' in o:
            o.location=o['hq_rest_location'];o.rotation_euler=o['hq_rest_rotation'];o.scale=o['hq_rest_scale']
    root['export_path']=str(path.relative_to(ROOT))
    bpy.context.view_layer.update()
    meshes=[o for o in root.children_recursive if o.type=='MESH']
    corners=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
    triangles=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    record={'kind':kind,'folder':folder,'triangles':triangles,'meshes':len(meshes),'bytes':path.stat().st_size,
            'dimensions':[max(p[k] for p in corners)-min(p[k] for p in corners) for k in (0,2,1)],'clips':list(root.get('hq_clips',[]))}
    mf=SOURCE/'manifest.json';data=json.loads(mf.read_text()) if mf.exists() else {}
    data[folder+'/'+kind]=record;mf.write_text(json.dumps(data,indent=2,sort_keys=True)+'\n')
    root.hide_set(True)
    return record

def save(category):
    s=SCENES['ZendGarden_HQ_'+category]
    path=SOURCE/(category+'.blend')
    bpy.data.libraries.write(str(path),{s},fake_user=True,compress=True)
    return str(path)

def replace_authored(category,folder,kind):
    """Replace only this branch's generated asset in its dedicated scene."""
    s=scene(category)
    roots=[r for r in s.objects if r.parent is None and r.get('export_path')==f'assets/{folder}/{kind}.glb']
    for r in roots:
        for o in list(r.children_recursive)+[r]:bpy.data.objects.remove(o,do_unlink=True)
