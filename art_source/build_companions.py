"""Original articulated tabby cat and collie, metres. Isolated Blender workshop only."""
import bpy, math, os
from mathutils import Vector
from pathlib import Path
ROOT=str(Path(__file__).resolve().parents[1])
scene=bpy.data.scenes.get('ZendGarden_AssetWorkshop')
bpy.context.window.scene=scene
# Clear only this dedicated generation scene.
for ob in list(scene.objects): bpy.data.objects.remove(ob,do_unlink=True)
os.makedirs(ROOT+'/assets/companions',exist_ok=True)
def vec(p): return Vector((p[0],-p[2],p[1]))
def material(name,c):
    m=bpy.data.materials.new(name); m.diffuse_color=(*c,1); m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*c,1); bs.inputs['Roughness'].default_value=.88
    return m
cream=material('Warm ivory fur',(.65,.58,.44)); ginger=material('Tabby coat',(.34,.17,.055)); dark=material('Tabby stripes and collie saddle',(.065,.046,.032)); nose=material('Soft nose',(.075,.043,.043)); pink=material('Ear velvet',(.42,.22,.20)); green=material('Amber green eyes',(.25,.36,.12)); black=material('Pupils',(.008,.012,.011)); collar=material('Sage woven collar',(.11,.22,.18))
def pivot(name,pos,parent=None):
    n=bpy.data.objects.new(name,None); scene.collection.objects.link(n); n.parent=parent; n.location=vec(pos); return n

def ell(name,pos,size,mat,parent):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10)
    n=bpy.context.object; n.name=name; n.parent=parent; n.location=vec(pos); n.scale=(size[0]/2,size[2]/2,size[1]/2); n.data.materials.append(mat)
    for f in n.data.polygons: f.use_smooth=True
    return n

def segment(name,a,b,r,mat,parent,r2=None):
    a,b=vec(a),vec(b); d=b-a
    bpy.ops.mesh.primitive_cone_add(vertices=10,radius1=r,radius2=r if r2 is None else r2,depth=d.length)
    n=bpy.context.object; n.name=name; n.parent=parent; n.location=(a+b)*.5; n.rotation_euler=d.to_track_quat('Z','Y').to_euler(); n.data.materials.append(mat)
    for f in n.data.polygons: f.use_smooth=True
    return n
def paint_tabby(torso):
    # Bake markings into the coat texture: no separate geometry can float or flicker.
    mat=material('Painted tabby coat',(.34,.17,.055))
    torso.data.materials.clear(); torso.data.materials.append(mat)
    nodes=mat.node_tree.nodes; links=mat.node_tree.links; nodes.clear()
    coord=nodes.new('ShaderNodeTexCoord'); axes=nodes.new('ShaderNodeSeparateXYZ')
    links.new(coord.outputs['Generated'],axes.inputs[0])
    length=nodes.new('ShaderNodeMath'); length.operation='MULTIPLY'; length.inputs[1].default_value=36
    links.new(axes.outputs['Y'],length.inputs[0])
    bend=nodes.new('ShaderNodeMath'); bend.operation='MULTIPLY'; bend.inputs[1].default_value=3
    links.new(axes.outputs['Z'],bend.inputs[0])
    add=nodes.new('ShaderNodeMath'); add.operation='ADD'; links.new(length.outputs[0],add.inputs[0]); links.new(bend.outputs[0],add.inputs[1])
    sine=nodes.new('ShaderNodeMath'); sine.operation='SINE'; links.new(add.outputs[0],sine.inputs[0])
    ramp=nodes.new('ShaderNodeValToRGB'); ramp.color_ramp.elements[0].position=.72; ramp.color_ramp.elements[0].color=(.34,.17,.055,1)
    ramp.color_ramp.elements[1].position=.88; ramp.color_ramp.elements[1].color=(.065,.046,.032,1)
    links.new(sine.outputs[0],ramp.inputs[0])
    emit=nodes.new('ShaderNodeEmission'); links.new(ramp.outputs[0],emit.inputs[0])
    out=nodes.new('ShaderNodeOutputMaterial'); links.new(emit.outputs[0],out.inputs['Surface'])
    image=bpy.data.images.new('Tabby painted fur',width=1024,height=1024)
    tex=nodes.new('ShaderNodeTexImage'); tex.image=image; nodes.active=tex
    bpy.ops.object.select_all(action='DESELECT'); torso.select_set(True); bpy.context.view_layer.objects.active=torso
    scene.render.engine='CYCLES'; scene.cycles.samples=1
    bpy.ops.object.bake(type='EMIT',margin=8)
    image.filepath_raw=ROOT+'/assets/companions/tabby_coat.png'; image.file_format='PNG'; image.save(); image.pack()
    nodes.clear(); tex=nodes.new('ShaderNodeTexImage'); tex.image=image
    bs=nodes.new('ShaderNodeBsdfPrincipled'); bs.inputs['Roughness'].default_value=.88
    out=nodes.new('ShaderNodeOutputMaterial'); links.new(tex.outputs['Color'],bs.inputs['Base Color']); links.new(bs.outputs[0],out.inputs['Surface'])

for cat in [True,False]:
    kind='cat' if cat else 'dog'; root=pivot(kind,(0,0,0)); coat=ginger if cat else dark
    body=pivot('Body',(0,.39 if cat else .52,0),root)
    torso=ell('Torso',(0,0,.03),(.32,.36,.65) if cat else (.43,.49,.85),coat,body)
    ell('Chest',(0,.015,-.22),(.28,.32,.24) if cat else (.38,.46,.32),cream,body)
    ell('Haunch',(0,-.025,.23),(.34,.35,.30) if cat else (.43,.46,.39),coat,body)
    head=pivot('Head',(0,.13,-.31) if cat else (0,.24,-.40),body)
    ell('Skull',(0,.03,0),(.30,.28,.27) if cat else (.34,.36,.38),coat,head)
    ell('Muzzle',(0,-.035,-.14),(.18,.11,.13) if cat else (.20,.18,.28),cream,head)
    ell('Nose',(0,-.012,-.208 if cat else -.29),(.054,.035,.038) if cat else (.095,.065,.06),nose,head)
    for side in [-1,1]:
        x=side*(.088 if cat else .099)
        ell('Eye',(x,.066,-.117 if cat else -.166),(.065,.055,.032),green if cat else cream,head)
        ell('Pupil',(x,.066,-.134 if cat else -.184),(.022,.043,.018) if cat else (.038,.045,.018),black,head)
        ell('Eye glint',(x-.008,.078,-.144 if cat else -.193),(.012,.012,.009),cream,head)
        ear=pivot('EarL' if side<0 else 'EarR',(side*.11,.135,.015),head)
        if cat:
            segment('Pointed ear',(0,0,0),(side*.025,.16,-.025),.08,coat,ear,.004)
            segment('Inner ear',(0,.025,-.045),(side*.025,.137,-.043),.043,pink,ear,.002)
            for k in range(3): segment('Whisker',(side*.045,-.015,-.18),(side*.22,-.03+k*.025,-.17-k*.012),.0018,cream,head,.0006)
        else:
            ell('Folded ear',(side*.033,-.025,.01),(.15,.27,.12),coat,ear)
            ell('Ear fold',(side*.035,-.05,-.047),(.08,.15,.026),pink,ear)
    for side in [-1,1]:
        for front in [True,False]:
            z=-.21 if front else .24
            leg=pivot(('Front' if front else 'Back')+('L' if side<0 else 'R'),(side*(.115 if cat else .16),-.08,z),body)
            length=.28 if cat else .40
            ell('Upper leg',(0,-length*.2,0),(.10,length*.75,.12) if cat else (.14,length*.75,.17),coat,leg)
            segment('Lower leg',(0,-length*.3,0),(0,-length+.035,-.02),.037 if cat else .048,cream,leg,.027 if cat else .039)
            ell('Paw',(0,-length+.025,-.043),(.095,.07,.14) if cat else (.13,.095,.19),cream,leg)
    tail=pivot('Tail',(0,.03,.30 if cat else .40),body)
    for k in range(6):
        a=(.035*math.sin(k*.45),k*.055,k*.067); b=(.035*math.sin((k+1)*.45),(k+1)*.055,(k+1)*.067)
        segment('Tail fur',a,b,(.035 if cat else .065)*(1-k*.11),dark if cat and k%2 else coat,tail)
    if cat:
        paint_tabby(torso)
    else:
        ell('White blaze',(0,.06,-.173),(.065,.22,.021),cream,head)
        ell('Neck ruff',(0,.10,-.27),(.42,.42,.22),cream,body)
    ell('Collar',(0,.035,-.26),(.32 if cat else .39,.055,.26),collar,body)
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    for ob in root.children_recursive: ob.select_set(True)
    bpy.ops.export_scene.gltf(filepath=ROOT+'/assets/companions/'+kind+'.glb',export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
    root.hide_set(True)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/art_source/companions.blend')
