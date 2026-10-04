"""An isolated, reproducible STL -> textured, skinned cat experiment.

Run in a separate Blender process. Never writes any production assets.
The original sculpt remains in its own hidden reference collection.
"""
import bpy, bmesh, math, json, hashlib, sys
import numpy as np
from pathlib import Path
from mathutils import Vector, Matrix, Quaternion

ROOT=Path(__file__).resolve().parent
EYE_SITES=[('L',(-.025,-.232,.359),(-.20,-1,.02)),('R',(.027,-.247,.361),(.45,-1,.02))]
SOURCE=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path('/Users/tam/Downloads/cat.stl')
ROOT.mkdir(exist_ok=True);(ROOT/'textures').mkdir(exist_ok=True);(ROOT/'export').mkdir(exist_ok=True)

def select(obj):
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj

def material(name,color,rough=.6):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
    b=m.node_tree.nodes['Principled BSDF'];b.inputs['Base Color'].default_value=(*color,1)
    b.inputs['Roughness'].default_value=rough
    return m

def smoothstep(a,b,x):
    t=np.clip((x-a)/(b-a),0,1);return t*t*(3-2*t)

def pigment(points):
    x,y,z=points.T
    # Markings are defined in anatomical coordinates, then baked into a UV map.
    # Warm brown mackerel tabby, pale chin/bib and socks, ringed upright tail.
    phase=y*162+np.sin(z*41)*1.15+np.sin(y*29)*.6+x*9
    stripes=smoothstep(.48,.84,np.sin(phase))
    head=smoothstep(.16,.205,-y)*smoothstep(.22,.3,z)
    face_stripes=smoothstep(.40,.83,np.sin(x*170+np.sin(z*83)*1.4+y*14))
    stripes=stripes*(1-head)+face_stripes*head
    tail=smoothstep(.14,.19,y)*smoothstep(.275,.32,z)
    stripes=stripes*(1-tail)+smoothstep(.20,.60,np.sin(z*179+y*22))*tail
    col=np.tile(np.array([.30,.172,.083]),(len(x),1))
    col*= (1-.63*stripes)[:,None]
    col*= (1-.23*smoothstep(.255,.325,z)*(1-head)*(1-tail))[:,None]
    micro=.97+.025*np.sin(x*2300+np.sin(y*630)*1.4)+.015*np.sin(z*4300+y*1920)
    col*=micro[:,None]
    belly=smoothstep(.23,.155,z)*(1-head)*(1-tail)*.6
    bib=smoothstep(.125,.17,-y)*smoothstep(.28,.24,z)*smoothstep(.04,.016,np.abs(x))
    socks=smoothstep(.059,.037,z)
    chin=np.exp(-((x-.006)/.027)**2-((y+.257)/.022)**2-((z-.322)/.018)**2)
    pale=np.maximum.reduce([belly,bib,socks,chin])
    col=col*(1-pale[:,None])+np.array([.58,.53,.44])*pale[:,None]
    # Rose leather nose is integrated into the sculpt, not another floating ball.
    nose=np.exp(-((x-.006)/.008)**4-((y+.270)/.0065)**4-((z-.337)/.0058)**4)
    col=col*(1-nose[:,None])+np.array([.25,.092,.080])*nose[:,None]
    return np.column_stack([np.clip(col,0,1),np.ones(len(col))]).astype(np.float32)

def image_node(mat,name,noncolor=False):
    im=bpy.data.images.new(name,2048,2048,alpha=False)
    if noncolor:im.colorspace_settings.name='Non-Color'
    node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=im
    mat.node_tree.nodes.active=node;node.select=True
    return im,node

def save_image(im):
    im.filepath_raw=str(ROOT/'textures'/(im.name+'.png'));im.file_format='PNG';im.save();im.pack()

def sphere(name,pos,scale,mat,parent_bone=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32,ring_count=16,location=pos)
    ob=bpy.context.object;ob.name=name;ob.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for p in ob.data.polygons:p.use_smooth=True
    ob.data.materials.append(mat)
    if parent_bone:
        world=ob.matrix_world.copy();ob.parent=rig;ob.parent_type='BONE';ob.parent_bone=parent_bone
        bpy.context.view_layer.update();ob.matrix_world=world
    return ob

scene=bpy.data.scenes.new('Zend Cat — STL prototype')
bpy.context.window.scene=scene
scene.render.fps=30
scene.unit_settings.system='METRIC'
bpy.ops.wm.stl_import(filepath=str(SOURCE))
high=bpy.context.object;high.name='SOURCE — untouched sculpt shape'
corners=[Vector(c) for c in high.bound_box]
lo=Vector([min(v[k] for v in corners) for k in range(3)]);hi=Vector([max(v[k] for v in corners) for k in range(3)])
unit=.52/(hi.z-lo.z);center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
high.data.transform(Matrix.Scale(unit,4)@Matrix.Translation(-center))
for p in high.data.polygons:p.use_smooth=True
reference=bpy.data.collections.new('REFERENCE — original two-million-triangle sculpt')
scene.collection.children.link(reference)
for c in list(high.users_collection):c.objects.unlink(high)
reference.objects.link(high)
skin=bpy.data.objects.new('Cat — deforming coat',high.data.copy());scene.collection.objects.link(skin)
select(skin)
dec=skin.modifiers.new('Game mesh reduction','DECIMATE');dec.ratio=.024
bpy.ops.object.modifier_apply(modifier=dec.name)
# Mildly relax the carved fur ridges. Eyes/ears/nose retain their sculpted shape.
vg=skin.vertex_groups.new(name='Coat ridge relaxation')
for v in skin.data.vertices:
    if v.co.y>-.165 or v.co.z<.23:vg.add([v.index],1,'REPLACE')
relax=skin.modifiers.new('Soften print-scale fur grooves','SMOOTH');relax.factor=.5;relax.iterations=15;relax.vertex_group=vg.name
bpy.ops.object.modifier_apply(modifier=relax.name)
skin.vertex_groups.remove(skin.vertex_groups['Coat ridge relaxation'])
select(skin);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(72),island_margin=.006,area_weight=.4)
bpy.ops.object.mode_set(mode='OBJECT')
points=np.array([tuple(v.co) for v in skin.data.vertices])
colors=pigment(points)
attr=skin.data.color_attributes.new(name='Anatomical pigment',type='FLOAT_COLOR',domain='POINT')
attr.data.foreach_set('color',colors.ravel())
coat=material('STL cat — baked short-coat tabby',(.30,.172,.083),.79)
skin.data.materials.clear();skin.data.materials.append(coat)
nodes=coat.node_tree.nodes;links=coat.node_tree.links
bs=nodes['Principled BSDF'];out=nodes['Material Output']
bs.inputs['Specular IOR Level'].default_value=.24;bs.inputs['Sheen Weight'].default_value=.15
colnode=nodes.new('ShaderNodeVertexColor');colnode.layer_name=attr.name
em=nodes.new('ShaderNodeEmission');links.new(colnode.outputs['Color'],em.inputs['Color']);links.new(em.outputs[0],out.inputs['Surface'])
albedo,albedonode=image_node(coat,'cat_tabby_albedo')
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=16
select(skin);high.hide_set(True)
scene.render.bake.use_selected_to_active=False;scene.render.bake.margin=12
bpy.ops.object.bake(type='EMIT');save_image(albedo)
links.new(bs.outputs['BSDF'],out.inputs['Surface']);links.new(albedonode.outputs['Color'],bs.inputs['Base Color'])
normal,normalnode=image_node(coat,'cat_sculpt_normal',True)
high.hide_set(False);high.select_set(True)
scene.render.bake.use_selected_to_active=True;scene.render.bake.cage_extrusion=.005
scene.render.bake.max_ray_distance=.012;scene.render.bake.normal_space='TANGENT'
bpy.ops.object.bake(type='NORMAL');save_image(normal)
nm=nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.20
links.new(normalnode.outputs['Color'],nm.inputs['Color']);links.new(nm.outputs['Normal'],bs.inputs['Normal'])
high.select_set(False);high.hide_set(True);high.hide_render=True;reference.hide_render=True
# Remove only the exposed ends of the thick printable whiskers. Thin tapered
# replacement whiskers are attached to the head bone below.
bm=bmesh.new();bm.from_mesh(skin.data)
remove=[]
for face in bm.faces:
    p=face.calc_center_median()
    if .315<p.z<.339 and p.y<-.258 and abs(p.x-.005)>.050:remove.append(face)
bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(skin.data);bm.free()
print('CAT_STUDY: maps baked',flush=True)

# Anatomical rig, four separate leg chains, planted paw IK and a three-bone tail.
skeleton=bpy.data.armatures.new('Imported cat anatomical skeleton')
rig=bpy.data.objects.new('CatRig',skeleton);scene.collection.objects.link(rig);rig.show_in_front=True
select(rig);bpy.ops.object.mode_set(mode='EDIT')
defs={}
def bone(name,head,tail,parent=None,deform=True):
    b=skeleton.edit_bones.new(name);b.head=head;b.tail=tail;b.use_deform=deform
    if parent:b.parent=skeleton.edit_bones[parent]
    defs[name]=(Vector(head),Vector(tail));return b
bone('Root',(0,0,.12),(0,0,.20))
bone('Pelvis',(0,.13,.235),(0,.055,.255),'Root')
bone('Spine',(0,.055,.255),(0,-.07,.265),'Pelvis')
bone('Chest',(0,-.07,.265),(0,-.14,.29),'Spine')
bone('Head',(.005,-.14,.29),(.006,-.224,.354),'Chest')
bone('EarL',(-.038,-.19,.39),(-.046,-.183,.422),'Head')
bone('EarR',(.034,-.204,.391),(.037,-.209,.419),'Head')
for name,pos,_ in EYE_SITES:
    p=Vector(pos)+Vector((0,0,.008))
    bone('Lid'+name,p,p+Vector((0,0,.004)),'Head')
bone('Tail1',(-.012,.173,.28),(-.022,.221,.366),'Pelvis')
bone('Tail2',(-.022,.221,.366),(-.039,.254,.447),'Tail1')
bone('Tail3',(-.039,.254,.447),(-.048,.247,.514),'Tail2')
legs={}
for front in [True,False]:
    for side in [-1,1]:
        name=('Front' if front else 'Back')+('L' if side<0 else 'R')
        subset=points[(points[:,2]>.025)&(points[:,2]<.048)&(points[:,0]*side>.01)&((points[:,1]<-.06) if front else (points[:,1]>.075))]
        paw=subset.mean(axis=0);paw[2]=.040
        shoulder=np.array([paw[0]*.80,-.109 if front else .14,.250 if front else .235])
        knee=np.array([paw[0]*.96,-.111 if front else .115,.135 if front else .13])
        upper=name+'_Upper';lower=name+'_Lower';foot=name+'_Paw'
        bone(upper,shoulder,knee,'Chest' if front else 'Pelvis')
        bone(lower,knee,paw,upper)
        bone(foot,paw,(paw[0],paw[1]-.03,.013),lower)
        legs[name]={'paw':Vector(paw),'bones':[upper,lower,foot],'side':side,'front':front}
bpy.ops.object.mode_set(mode='OBJECT')

# Region-aware weights prevent neighbouring legs or the upright tail influencing
# each other. A body blend joins each limb smoothly into the sculpted torso.
groups={n:skin.vertex_groups.new(name=n) for n in defs}
def seg_distance(p,a,b):
    d=b-a;t=max(0,min(1,(p-a).dot(d)/d.length_squared));return (p-(a+t*d)).length
def scalar_smooth(a,b,v):
    t=max(0,min(1,(v-a)/(b-a)));return t*t*(3-2*t)
for vertex in skin.data.vertices:
    p=vertex.co;x,y,z=p
    body={'Chest':scalar_smooth(.07,-.09,y),'Pelvis':scalar_smooth(-.045,.14,y)}
    body['Spine']=max(.12,1-sum(body.values()))
    total=sum(body.values());body={k:v/total for k,v in body.items() if v>0}
    head=scalar_smooth(-.14,-.188,y)*scalar_smooth(.20,.29,z)
    w={k:v*(1-head) for k,v in body.items()};w['Head']=head
    tail=scalar_smooth(.14,.19,y)*scalar_smooth(.27,.315,z)
    if tail:
        tt={n:1/(.006+seg_distance(p,*defs[n]))**4 for n in ['Tail1','Tail2','Tail3']}
        s=sum(tt.values());w={k:v*(1-tail) for k,v in w.items()}
        for n,v in tt.items():w[n]=tail*v/s
    for n in ['EarL','EarR']:
        a,b=defs[n];e=scalar_smooth(.38,.409,z)*math.exp(-((x-a.x)/.028)**4)*scalar_smooth(-.155,-.18,y)
        w={k:v*(1-e) for k,v in w.items()};w[n]=e
    if z<.238 and (y<-.055 or y>.08):
        family='Front' if y<0 else 'Back'
        # The sculpt is asymmetrical: the inside of one front paw crosses X=0.
        # Classify using the measured paw centres, not an assumed centreline.
        middle=(legs[family+'L']['paw'].x+legs[family+'R']['paw'].x)*.5
        name=family+('L' if x<middle else 'R')
        lw=scalar_smooth(.239,.142,z)*(1-head)*(1-tail)
        ns=legs[name]['bones'];dist={n:1/(.008+seg_distance(p,*defs[n]))**5 for n in ns}
        # The underside and toes remain one planted paw, not a rubbery ankle.
        if z<.037:dist={ns[0]:0,ns[1]:0,ns[2]:1}
        s=sum(dist.values());w={k:v*(1-lw) for k,v in w.items()}
        for n,v in dist.items():w[n]=w.get(n,0)+lw*v/s
    w=dict(sorted(((k,v) for k,v in w.items() if v>.007),key=lambda item:item[1],reverse=True)[:4]);s=sum(w.values())
    for n,v in w.items():groups[n].add([vertex.index],v/s,'REPLACE')
skin.parent=rig
arm=skin.modifiers.new('Natural joint deformation','ARMATURE');arm.object=rig;arm.use_deform_preserve_volume=True

# Sparse 2–3 mm laid hair breaks the silhouette, using the project's existing
# generated alpha hair sheet. Cards are interpolated into the skin's weights.
hair_source=ROOT.parent/'overhaul/textures/generated/fine-fur-card.png'
hair_count=0
if hair_source.exists():
    source=bpy.data.images.load(str(hair_source),check_existing=False);source.scale(256,256)
    rgba=np.empty(256*256*4,np.float32);source.pixels.foreach_get(rgba);rgba=rgba.reshape((256,256,4))
    luminance=rgba[:,:,:3].mean(axis=2);variation=np.clip(luminance/(luminance.mean()+1e-6),.8,1.2)
    hairmats=[];tones=[(.28,.153,.07),(.09,.055,.026),(.55,.50,.41)]
    for index,tint in enumerate(tones):
        mat=material('Fur cards STL short silhouette '+str(index),tint,.88);mat.surface_render_method='DITHERED'
        mat.use_backface_culling=False
        values=rgba.copy();values[:,:,:3]=variation[:,:,None]*np.array(tint)
        im=bpy.data.images.new('cat_short_fur_'+str(index),256,256,alpha=True)
        im.pixels.foreach_set(values.astype(np.float32).ravel());save_image(im)
        node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=im
        pb=mat.node_tree.nodes['Principled BSDF'];pb.inputs['Specular IOR Level'].default_value=.15
        mat.node_tree.links.new(node.outputs['Color'],pb.inputs['Base Color']);mat.node_tree.links.new(node.outputs['Alpha'],pb.inputs['Alpha'])
        hairmats.append(mat)
    rng=np.random.default_rng(904);polys=list(skin.data.polygons)
    areas=np.array([p.area for p in polys]);areas/=areas.sum()
    vs=[];fs=[];uvs=[];influences=[];face_tints=[];normals=[]
    for index in rng.choice(len(polys),850,p=areas):
        poly=polys[index];p=poly.center.copy();n=poly.normal.copy()
        if p.z<.055 or (p.y<-.165 and p.z<.38):continue
        flow=Vector((0,.4,-1)) if p.y<-.14 else Vector((0,.25,1)) if p.y>.16 and p.z>.3 else Vector((0,1,-.30))
        tangent=flow-n*flow.dot(n)
        if tangent.length<1e-4:continue
        tangent.normalize();across=tangent.cross(n).normalized()
        length=rng.uniform(.0019,.0031);p+=n*.0002;start=len(vs)
        weights={}
        for vi in poly.vertices:
            for g in skin.data.vertices[vi].groups:
                name=skin.vertex_groups[g.group].name;weights[name]=weights.get(name,0)+g.weight/len(poly.vertices)
        weights=dict(sorted(weights.items(),key=lambda kv:kv[1],reverse=True)[:4]);s=sum(weights.values())
        weights={k:v/s for k,v in weights.items()}
        tint=pigment(np.array([tuple(p)]))[0,:3]
        material_index=int(np.argmin(np.linalg.norm(np.array(tones)-tint,axis=1)))
        for row in range(3):
            t=row/2;center=p+tangent*length*t+n*length*(.18*t+.16*t*t)
            for side in [-1,1]:
                vs.append(tuple(center+across*length*.27*(1-.5*t)*side));uvs.append(((side+1)/2,t));influences.append(weights);normals.append(tuple(n))
        for row in range(2):fs.append((start+row*2,start+row*2+1,start+row*2+3,start+row*2+2));face_tints.append(material_index)
        hair_count+=1
    data=bpy.data.meshes.new('Weighted short coat cards');data.from_pydata(vs,[],fs);data.update()
    hair=bpy.data.objects.new('Laid silhouette hairs',data);scene.collection.objects.link(hair);hair.parent=rig
    for mat in hairmats:data.materials.append(mat)
    uv=data.uv_layers.new(name='Hair alpha UV')
    for poly in data.polygons:
        poly.material_index=face_tints[poly.index];poly.use_smooth=True
        for li in poly.loop_indices:uv.data[li].uv=uvs[data.loops[li].vertex_index]
    data.normals_split_custom_set_from_vertices(normals)
    hairgroups={n:hair.vertex_groups.new(name=n) for n in defs}
    for index,weights in enumerate(influences):
        for name,value in weights.items():hairgroups[name].add([index],value,'REPLACE')
    modifier=hair.modifiers.new('Hair follows the skin','ARMATURE');modifier.object=rig
    bpy.data.images.remove(source)

whisker_mat=material('Fine ivory whiskers',(.52,.49,.42),.55)
for side in [-1,1]:
    for index in range(5):
        curve=bpy.data.curves.new('Tapered natural whisker','CURVE');curve.dimensions='3D'
        curve.resolution_u=3;curve.bevel_depth=.00022;curve.bevel_resolution=1
        spline=curve.splines.new('POLY');spline.points.add(6)
        for k,point in enumerate(spline.points):
            t=k/6
            point.co=(.005+side*(.024+(.041+index*.003)*t),-.263+.016*t*t+(index-2)*.0025*t,.327+(index-2)*.0023+.008*t-.010*t*t,1)
            point.radius=1-.95*t
        ob=bpy.data.objects.new('Fine whisker',curve);scene.collection.objects.link(ob);curve.materials.append(whisker_mat)
        select(ob);bpy.ops.object.convert(target='MESH')
        ob=bpy.context.object;world=ob.matrix_world.copy();ob.parent=rig;ob.parent_type='BONE';ob.parent_bone='Head'
        bpy.context.view_layer.update();ob.matrix_world=world

# The original sculpt contains thick printed whiskers. Tint them to a neutral
# pale shade in the bake; leave their shape intact for this first experiment.
# Small glossy amber eyes sit inside the existing sculpted eye rims.
iris=material('Amber iris',(.18,.12,.030),.23)
black=material('Slit pupil',(.003,.005,.003),.17)
eye_white=material('Warm eye rim',(.18,.16,.095),.4)
eyes=[]
for name,pos,normal_dir in EYE_SITES:
    p=Vector(pos);direction=Vector(normal_dir).normalized()
    eyeball=sphere('Amber eye '+name,p,(.008,.0035,.0068),iris,'Head')
    pupil=sphere('Vertical pupil '+name,p+direction*.0034,(.0013,.0010,.0048),black,'Head')
    lidcoat=material('Eyelid coat '+name,tuple(pigment(np.array([pos]))[0,:3]),.82)
    lid=sphere('Blinking lid '+name,p+direction*.0012,(.009,.0045,.0082),lidcoat,'Lid'+name)
    eyes.append((p,direction))

targets={};constraints=[]
for name,leg in legs.items():
    target=bpy.data.objects.new(name+' planted target',None);scene.collection.objects.link(target);target.location=leg['paw']
    target.rotation_mode='QUATERNION';target.rotation_quaternion=rig.data.bones[leg['bones'][2]].matrix_local.to_quaternion()
    targets[name]=target
    ik=rig.pose.bones[leg['bones'][1]].constraints.new('IK');ik.target=target;ik.chain_count=2;ik.use_stretch=False
    constraints.append((rig.pose.bones[leg['bones'][1]],ik))
    flat=rig.pose.bones[leg['bones'][2]].constraints.new('COPY_ROTATION');flat.target=target;flat.target_space='WORLD';flat.owner_space='WORLD'
    constraints.append((rig.pose.bones[leg['bones'][2]],flat))
    rig.pose.bones[leg['bones'][0]].ik_stretch=0;rig.pose.bones[leg['bones'][1]].ik_stretch=0
for pb in rig.pose.bones:pb.rotation_mode='XYZ'
order=sorted(list(defs),key=lambda n:len(list(rig.data.bones[n].parent_recursive)))
clips={};samples={};frames_per_second=30
phase_offsets={'BackL':0,'FrontL':.25,'BackR':.5,'FrontR':.75}
def pose(kind,t,duration):
    for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
    for name,ob in targets.items():ob.location=legs[name]['paw']
    loop=t/duration
    breath=math.sin(loop*math.tau*(2 if kind=='idle' else 1))
    rig.pose.bones['Spine'].scale=(1+.009*breath,1,1+.004*breath)
    rig.pose.bones['Head'].rotation_euler[1]=.035*math.sin(loop*math.tau)
    tail_phase=loop*math.tau*(2 if kind=='idle' else 1)
    rig.pose.bones['Tail1'].rotation_euler[1]=.032*math.sin(tail_phase)
    rig.pose.bones['Tail2'].rotation_euler[2]=.06*math.sin(tail_phase+.8)
    rig.pose.bones['Tail3'].rotation_euler[2]=.12*math.sin(tail_phase+1.6)
    blink=0
    if kind in ['idle','look']:
        for moment in ([2.85,6.1] if kind=='idle' else [1.9]):
            blink=max(blink,math.exp(-((t-moment)/.066)**4))
    for n in ['LidL','LidR']:rig.pose.bones[n].scale.y=.025+.975*blink
    if kind=='idle':
        # Sparse, staggered ear flicks rather than synchronised twitching.
        flick=math.exp(-((t-2.0)/.10)**2)-.55*math.exp(-((t-2.19)/.13)**2)
        rig.pose.bones['EarR'].rotation_euler[1]=.18*flick
    if kind=='look':
        a=math.sin(math.pi*t/duration)**2
        rig.pose.bones['Head'].rotation_euler[1]=.35*a*math.sin(t*math.tau/duration)
        rig.pose.bones['Head'].rotation_euler[0]=-.08*a
        rig.pose.bones['EarL'].rotation_euler[2]=.16*a
    if kind=='walk':
        p=t/duration;stride=.13;stance=.65
        for name,target in targets.items():
            cycle=(p+phase_offsets[name])%1
            if cycle<stance:
                # Constant speed through stance, with no vertical foot movement.
                y=-stride/2+stride*cycle/stance;lift=0
            else:
                u=(cycle-stance)/(1-stance)
                y=stride/2-stride*(u*u*(3-2*u));lift=.025*math.sin(math.pi*u)**1.4
            target.location=legs[name]['paw']+Vector((0,y,lift))
        # Root's local Y axis is vertical. Lower the shoulders slightly so
        # straight forelegs can reach both ends of the planted stance.
        rig.pose.bones['Root'].location.y=-.015+.0015*math.sin(p*math.tau*2)
        rig.pose.bones['Chest'].rotation_euler[2]=.011*math.sin(p*math.tau)
        rig.pose.bones['Head'].rotation_euler[0]=-.018*math.sin(p*math.tau*2)
    # Aim around anatomical/world axes instead of rolling around the sloping
    # neck bone's own axis.
    head=rig.pose.bones['Head'];head.rotation_mode='QUATERNION'
    yaw=.035*math.sin(loop*math.tau);pitch=0
    if kind=='look':
        a=math.sin(math.pi*t/duration)**2;yaw=.35*a*math.sin(t*math.tau/duration);pitch=-.08*a
    if kind=='walk':pitch=-.018*math.sin(loop*math.tau*2)
    axes=rig.data.bones['Head'].matrix_local.to_3x3().inverted()
    head.rotation_quaternion=Quaternion(axes@Vector((0,0,1)),yaw)@Quaternion(axes@Vector((1,0,0)),pitch)
    bpy.context.view_layer.update()

for kind,duration in [('idle',8),('look',5),('walk',1.2)]:
    frame_count=round(duration*30);clips[kind]=frame_count
    stored=[]
    for frame in range(frame_count+1):
        t=frame/30
        # Round walk endpoint to exactly one cycle so it closes cleanly.
        if kind=='walk':t=duration*frame/frame_count
        pose(kind,t,duration)
        ev=rig.evaluated_get(bpy.context.evaluated_depsgraph_get())
        mats={n:ev.pose.bones[n].matrix.copy() for n in order};basis={}
        for n in order:
            b=rig.data.bones[n]
            relative=mats[b.parent.name].inverted()@mats[n] if b.parent else mats[n]
            rest=b.parent.matrix_local.inverted()@b.matrix_local if b.parent else b.matrix_local
            basis[n]=(rest.inverted()@relative).decompose()
        stored.append(basis)
    samples[kind]=stored
for pb,c in constraints:pb.constraints.remove(c)
for target in targets.values():bpy.data.objects.remove(target,do_unlink=True)
for pb in rig.pose.bones:pb.rotation_mode='QUATERNION'
rig.animation_data_create()
for name,stored in samples.items():
    rig.animation_data.action=None
    for frame,basis in enumerate(stored,1):
        for n,(loc,rot,scale) in basis.items():
            pb=rig.pose.bones[n];pb.location=loc;pb.rotation_quaternion=rot;pb.scale=scale
            for prop in ['location','rotation_quaternion','scale']:pb.keyframe_insert(prop,frame=frame)
    action=rig.animation_data.action;action.name='ImportedCat_'+name
    track=rig.animation_data.nla_tracks.new();track.name=name
    strip=track.strips.new(name,1,action);strip.extrapolation='NOTHING';track.mute=True
    rig.animation_data.action=None
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for n in ['LidL','LidR']:rig.pose.bones[n].scale.y=.025
scene.frame_set(0);bpy.context.view_layer.update()
select(rig)
for ob in rig.children_recursive:ob.select_set(True)
for track in rig.animation_data.nla_tracks:track.mute=False
rig.rotation_euler.z=math.pi # Export facing -Z, matching GardenCompanion.
bpy.ops.export_scene.gltf(filepath=str(ROOT/'export/cat_study.glb'),export_format='GLB',use_selection=True,use_active_scene=True,
    export_yup=True,export_apply=False,export_extras=True,export_animations=True,
    export_animation_mode='NLA_TRACKS',export_merge_animation='NLA_TRACK',export_nla_strips=True,
    export_image_format='JPEG',export_image_quality=90)
for track in rig.animation_data.nla_tracks:
    track.mute=True
    track.strips[0].influence=1
rig.rotation_euler.z=0
scene.frame_set(0)
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
for n in ['LidL','LidR']:rig.pose.bones[n].scale.y=.025

# Matching studio lights make the sculpt, finished cat and production cat comparable.
scene.world=bpy.data.worlds.new('Cat study soft daylight');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.5,.55,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.35
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object;floor.name='STUDIO — floor';floor.data.materials.append(material('Warm slate floor',(.20,.225,.22),.93))
target=Vector((0,0,.25))
for label,pos,power,size in [('key',(.75,-.8,1.35),80,.9),('fill',(-.8,-.3,.7),45,.8),('rim',(.2,.8,1.1),60,.7)]:
    bpy.ops.object.light_add(type='AREA',location=pos)
    ob=bpy.context.object;ob.name='STUDIO — '+label;ob.data.energy=power;ob.data.size=size
    ob.rotation_euler=(target-ob.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(.8,-1.2,.65))
cam=bpy.context.object;cam.name='STUDIO — camera';cam.data.type='ORTHO';cam.data.ortho_scale=.79
cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();scene.camera=cam
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=1000;scene.render.resolution_y=1000
scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG';scene.view_settings.view_transform='AgX'
scene.render.filepath=str(ROOT/'previews/textured_quarter.png')
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'cat_study.blend'),compress=True)
bpy.ops.render.render(write_still=True)
summary={'source_file':SOURCE.name,'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'source_triangles':2000000,'mesh_triangles':sum(len(p.vertices)-2 for p in skin.data.polygons),
    'exported_triangles_total':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in rig.children_recursive if o.type=='MESH'),
    'exported_bytes':(ROOT/'export/cat_study.glb').stat().st_size,
    'bones':len(defs),'silhouette_hair_cards':hair_count,'clips':{k:round(v/30,3) for k,v in clips.items()},'target_height_metres':.52,
    'walk_stride_metres':.13,'walk_stance_fraction':.65,'nominal_walk_speed_metres_second':.13/(1.2*.65),
    'prototype_only':True,'blender_version':bpy.app.version_string}
(ROOT/'report.json').write_text(json.dumps(summary,indent=2)+'\n')
print('CAT_STUDY: '+json.dumps(summary),flush=True)
