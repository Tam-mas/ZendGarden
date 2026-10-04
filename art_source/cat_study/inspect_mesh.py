"""Inspect the supplied sculpt in an isolated background Blender process."""
import bpy, sys
from mathutils import Vector
from pathlib import Path

ROOT = Path(__file__).resolve().parent
scene = next((s for s in bpy.data.scenes if s.name.startswith('Zend —')),None)
if scene is None:
    scene=bpy.data.scenes.new('Zend — imported cat study')
    bpy.context.window.scene=scene
    source=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else '/Users/tam/Downloads/cat.stl'
    bpy.ops.wm.stl_import(filepath=source)
    bpy.context.object.name='Cat_STL_Reference'
bpy.context.window.scene = scene
cat = scene.objects['Cat_STL_Reference']
coords = [Vector(c) for c in cat.bound_box]
lo = Vector([min(v[k] for v in coords) for k in range(3)])
hi = Vector([max(v[k] for v in coords) for k in range(3)])
scale = .52 / (hi.z-lo.z)
for vertex in cat.data.vertices:
    vertex.co = (vertex.co - Vector(((lo.x+hi.x)/2, (lo.y+hi.y)/2, lo.z))) * scale
for polygon in cat.data.polygons:
    polygon.use_smooth = True
mat = bpy.data.materials.new('Neutral clay'); mat.diffuse_color=(.48,.48,.48,1)
cat.data.materials.append(mat)
bpy.context.view_layer.objects.active=cat
cat.select_set(True)
mod=cat.modifiers.new('Inspection reduction','DECIMATE'); mod.ratio=.075
bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.ops.mesh.primitive_plane_add(size=200)
floor=bpy.context.object
m=bpy.data.materials.new('Floor');m.diffuse_color=(.25,.29,.30,1);floor.data.materials.append(m)
scene.world=bpy.data.worlds.new('Study World');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.45,.5,.55,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.4
target=Vector((0,0,.25))
for pos,power,size in [((.8,-.6,1.4),110,1),((-.7,.2,.9),70,.7)]:
    bpy.ops.object.light_add(type='AREA',location=pos)
    o=bpy.context.object;o.data.energy=power;o.data.size=size
    o.rotation_euler=(target-o.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add()
cam=bpy.context.object;cam.data.type='ORTHO';cam.data.ortho_scale=.8;scene.camera=cam
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=800;scene.render.resolution_y=800
scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
scene.view_settings.view_transform='AgX'
for name,pos in [('front',(0,-1.4,.65)),('side',(1.4,0,.5)),('quarter',(.8,-1.2,.65)),('reverse',(.8,1.2,.65))]:
    cam.location=pos;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(ROOT/'previews'/('raw_'+name+'.png'))
    bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'inspection.blend'))
