"""Continuous mammal/bird skin, weighted to existing authored motion controls.

The controls remain available to gameplay. A real armature and deforming mesh
replace rigid coat pieces; baked NLA bone actions ship through ordinary glTF.
"""
import bpy, math
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
from common_hq import fuse_surface, vec

PARTS=['Body','Head','Tail','FrontL','FrontR','BackL','BackR',
       'LowerFrontL','LowerFrontR','LowerBackL','LowerBackR']

def label(o):
    return o.name.split('.')[0]

def connect(root,kind):
    bird=kind in ['songbird','native_bird','fairy_wren','kookaburra','lorikeet','magpie']
    parts=['Body','Head'] if bird else PARTS
    controls={label(o):o for o in root.children_recursive if o.type=='EMPTY' and label(o) in parts}
    if 'Body' not in controls or 'Head' not in controls:return None
    scene=bpy.context.scene;scene.frame_set(0);bpy.context.view_layer.update()
    inverse=root.matrix_world.inverted()
    rest={name:inverse@o.matrix_world for name,o in controls.items()}
    selected=[];vertices=[];faces=[];face_bones=[];face_mats=[];materials=[]
    for o in list(root.children_recursive):
        if o.type!='MESH' or not o.data.materials or not o.parent:continue
        owner=label(o.parent)
        if owner not in controls:continue
        mat=o.data.materials[0]
        keywords=['plumage','breast','cobalt head'] if bird else ['coat','animal fur']
        if not any(w in mat.name for w in keywords):continue
        if any(w in o.name.lower() for w in ['whisker','ruff lock','ear','fur']):continue
        selected.append(o)
        transform=inverse@o.matrix_world
        offset=len(vertices);vertices.extend(transform@v.co for v in o.data.vertices)
        o.data.calc_loop_triangles()
        for tri in o.data.loop_triangles:
            faces.append(tuple(offset+i for i in tri.vertices));face_bones.append(owner)
            m=o.data.materials[tri.material_index]
            if m not in materials:materials.append(m)
            face_mats.append(materials.index(m))
    if not selected:return None
    bvh=BVHTree.FromPolygons(vertices,faces,all_triangles=True)
    # Join in root coordinates. No unrelated scene or source asset is touched.
    for o in selected:
        o.data.transform(inverse@o.matrix_world)
        o.parent=root;o.matrix_parent_inverse=Matrix.Identity(4);o.matrix_basis=Matrix.Identity(4)
    voxel=.0027 if bird else {'cat':.0058,'dog':.0085,'fox':.0065,'wombat':.009,'rabbit':.0058,
           'echidna':.006,'kangaroo':.0095,'kangaroo_joey':.0095}[kind]
    skin=fuse_surface(selected,voxel);skin.name='Continuous skin'
    skin.parent=root;skin.matrix_parent_inverse=Matrix.Identity(4)
    bpy.context.view_layer.update()
    # fuse_surface keeps its active object's transform, which is identity here.
    skin.data.materials.clear()
    for m in materials:skin.data.materials.append(m)
    for poly in skin.data.polygons:
        _,_,index,_=bvh.find_nearest(poly.center)
        poly.material_index=face_mats[index]
    from realism import coat_uv
    coat_uv(skin)
    if bird:
        for datum in skin.data.uv_layers.active.data:datum.uv*=2
    skeleton=bpy.data.armatures.new(kind+' anatomical skeleton')
    rig=bpy.data.objects.new('SkinRig',skeleton);scene.collection.objects.link(rig)
    rig.parent=root;rig.show_in_front=True
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
    bones={}
    for name,control in controls.items():
        bone=skeleton.edit_bones.new('Skin_'+name)
        bone.head=rest[name].translation
        children=[n for n,c in controls.items() if c.parent==control]
        if name=='Body':end=bone.head+Vector((0,0,.13))
        elif children:end=rest[children[0]].translation
        elif name=='Tail':end=bone.head+Vector((0,-.13,0))
        elif name=='Head':end=bone.head+Vector((0,.09,.02))
        else:end=bone.head+Vector((0,0,-.07))
        if (end-bone.head).length<.01:end=bone.head+Vector((0,0,.05))
        bone.tail=end;bones[name]=bone
    for name,control in controls.items():
        if name=='Body':continue
        parent=label(control.parent) if control.parent else ''
        if parent not in bones:parent='Body'
        bones[name].parent=bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    # Initial weights follow the nearest authored anatomical surface. Smoothing
    # across the connected topology produces soft joints without distant limb
    # influence or the cross-leg bleeding of generic automatic heat weights.
    weights=[]
    for v in skin.data.vertices:
        _,_,index,_=bvh.find_nearest(v.co)
        weights.append({face_bones[index]:1.0})
    neighbours=[set() for _ in skin.data.vertices]
    for edge in skin.data.edges:
        a,b=edge.vertices;neighbours[a].add(b);neighbours[b].add(a)
    for iteration in range(7):
        next_weights=[]
        for i,current in enumerate(weights):
            if not neighbours[i]:next_weights.append(current);continue
            mixed={k:v*.52 for k,v in current.items()}
            scale=.48/len(neighbours[i])
            for n in neighbours[i]:
                for k,v in weights[n].items():mixed[k]=mixed.get(k,0)+v*scale
            mixed={k:v for k,v in mixed.items() if v>.015}
            total=sum(mixed.values());next_weights.append({k:v/total for k,v in mixed.items()})
        weights=next_weights
    groups={name:skin.vertex_groups.new(name='Skin_'+name) for name in controls}
    for i,weight in enumerate(weights):
        for name,value in weight.items():groups[name].add([i],value,'REPLACE')
    skin.parent=rig;skin.matrix_parent_inverse=Matrix.Identity(4)
    modifier=skin.modifiers.new('Continuous anatomical deformation','ARMATURE');modifier.object=rig
    modifier.use_deform_preserve_volume=True
    other=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in root.children_recursive if o.type=='MESH' and o!=skin)
    triangles=sum(len(p.vertices)-2 for p in skin.data.polygons)
    limit=max(12000,49000-other)
    if triangles>limit:
        bpy.context.view_layer.objects.active=skin
        reduction=skin.modifiers.new('Skin triangle budget','DECIMATE');reduction.ratio=limit/triangles
        bpy.ops.object.modifier_apply(modifier=reduction.name)
    bake(rig,controls,rest,root.get('hq_clips',[]))
    root['continuous_skin']=True
    return rig

def bake(rig,controls,rest,clips):
    scene=bpy.context.scene
    original={o:(o.location.copy(),o.rotation_euler.copy(),o.scale.copy()) for o in controls.values()}
    track_objects=[o for o in controls.values() if o.animation_data]
    rest_bones={name:rig.data.bones['Skin_'+name].matrix_local.copy() for name in controls}
    # Pose matrices are set parent first, in armature/root coordinates.
    order=sorted(controls,key=lambda n:depth(rig.data.bones['Skin_'+n]))
    # Baking needs control matrices, not repeatedly evaluated skin geometry.
    # Restore every modifier flag before exporting or returning to the gallery.
    modifiers=[(m,m.show_viewport) for o in scene.objects for m in o.modifiers if m.type=='ARMATURE']
    for modifier,_ in modifiers:modifier.show_viewport=False
    try:
        for clip in clips:
            for o in track_objects:
                for track in o.animation_data.nla_tracks:track.mute=track.name!=clip
            track=next(t for t in track_objects[0].animation_data.nla_tracks if t.name==clip)
            end=int(round(track.strips[0].frame_end))
            rig.animation_data_create();rig.animation_data.action=None
            for frame in range(1,end+1,2):
                scene.frame_set(frame);bpy.context.view_layer.update()
                inverse=rig.matrix_world.inverted()
                desired={name:inverse@controls[name].matrix_world@rest[name].inverted()@rest_bones[name] for name in order}
                for name in order:
                    pose=rig.pose.bones['Skin_'+name];pose.rotation_mode='QUATERNION'
                    parent=pose.parent.name.removeprefix('Skin_') if pose.parent else None
                    local=rest_bones[parent].inverted()@rest_bones[name] if parent else rest_bones[name]
                    relative=desired[parent].inverted()@desired[name] if parent else desired[name]
                    pose.matrix_basis=local.inverted()@relative
                    for prop in ['location','rotation_quaternion','scale']:pose.keyframe_insert(prop,frame=frame)
            action=rig.animation_data.action;action.name=rig.name+'_'+clip
            nla=rig.animation_data.nla_tracks.new();nla.name=clip
            strip=nla.strips.new(clip,1,action);strip.extrapolation='NOTHING';nla.mute=True
            rig.animation_data.action=None
    finally:
        for o in track_objects:
            for track in o.animation_data.nla_tracks:track.mute=True
        scene.frame_set(0)
        for o,(loc,rot,scale) in original.items():o.location=loc;o.rotation_euler=rot;o.scale=scale
        for pose in rig.pose.bones:pose.matrix_basis=Matrix.Identity(4)
        for modifier,visible in modifiers:modifier.show_viewport=visible
        bpy.context.view_layer.update()

def depth(bone):
    return 0 if bone.parent is None else 1+depth(bone.parent)
