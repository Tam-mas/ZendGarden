"""Review the exported GLBs through MCP, with isolated studio scenes."""
import bpy, math, json
from mathutils import Vector,Matrix
from common_hq import ROOT

def render(folder,kind,frame=1):
    previous=bpy.context.window.scene
    selected=list(bpy.context.selected_objects);active=bpy.context.view_layer.objects.active
    banks=['meshes','armatures','actions','cameras','lights','curves','collections','worlds','materials','images']
    before={name:set(getattr(bpy.data,name)) for name in banks}
    s=bpy.data.scenes.new('ZendGarden_Review_'+kind);bpy.context.window.scene=s
    try:
        bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets'/folder/(kind+'.glb')))
        # Static silhouette review uses the authored neutral pose. Imported glTF
        # chooses its first clip (usually flight); that is reviewed separately.
        for o in list(s.objects):
            if o.animation_data:o.animation_data_clear()
            if o.type=='ARMATURE':
                for bone in o.pose.bones:bone.matrix_basis=Matrix.Identity(4)
            if 'hq_rest_location' in o:
                o.rotation_mode='XYZ';o.location=o['hq_rest_location'];o.rotation_euler=o['hq_rest_rotation'];o.scale=o['hq_rest_scale']
        s.frame_set(0);bpy.context.view_layer.update()
        meshes=[o for o in s.objects if o.type=='MESH']
        depsgraph=bpy.context.evaluated_depsgraph_get()
        corners=[]
        for o in meshes:
            evaluated=o.evaluated_get(depsgraph)
            geometry=evaluated.to_mesh()
            corners.extend(evaluated.matrix_world@v.co for v in geometry.vertices)
            evaluated.to_mesh_clear()
        lo=Vector([min(v[k] for v in corners) for k in range(3)])
        hi=Vector([max(v[k] for v in corners) for k in range(3)])
        center=(lo+hi)*.5;span=max(hi-lo)
        s.world=bpy.data.worlds.new('ZendGarden_Review_World');s.world.use_nodes=True
        s.world.node_tree.nodes['Background'].inputs[0].default_value=(.55,.57,.59,1)
        s.world.node_tree.nodes['Background'].inputs[1].default_value=.55
        bpy.ops.mesh.primitive_plane_add(size=max(10,span*25),location=(center.x,center.y,lo.z-.003))
        plane=bpy.context.object;m=bpy.data.materials.new('ZendGarden_Review_Ivory');m.diffuse_color=(.68,.65,.58,1);plane.data.materials.append(m)
        bpy.ops.object.camera_add(location=center+Vector((1.25,1.75,1.04))*span)
        camera=bpy.context.object;camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
        camera.data.type='ORTHO';camera.data.ortho_scale=span*1.52;camera.data.clip_start=.001;s.camera=camera
        for offset,power,size in [((1,-1,3),140,2.5),((-2,-1,1.7),90,2),((0,2,2),150,2)]:
            bpy.ops.object.light_add(type='AREA',location=center+Vector(offset)*span)
            light=bpy.context.object;light.data.energy=power*span*span;light.data.shape='DISK';light.data.size=size*span
            light.rotation_euler=(center-light.location).to_track_quat('-Z','Y').to_euler()
        s.render.engine='BLENDER_EEVEE'
        s.render.resolution_x=640;s.render.resolution_y=640;s.render.resolution_percentage=100
        s.view_settings.view_transform='AgX';s.render.image_settings.file_format='PNG'
        out=ROOT/'captures/overhaul';out.mkdir(parents=True,exist_ok=True)
        s.render.filepath=str(out/(folder+'_'+kind+'.png'))
        bpy.ops.render.render(write_still=True)
        return {'image':s.render.filepath,'dimensions':list(hi-lo),'frame':frame}
    finally:
        # Delete only transient review objects created by this call.
        for o in list(s.objects):bpy.data.objects.remove(o,do_unlink=True)
        bpy.context.window.scene=previous;bpy.data.scenes.remove(s)
        for name in banks:
            bank=getattr(bpy.data,name)
            for datum in list(bank):
                if datum not in before[name] and datum.users==0:bank.remove(datum)
        for ob in bpy.context.selected_objects:ob.select_set(False)
        for ob in selected:ob.select_set(True)
        bpy.context.view_layer.objects.active=active
