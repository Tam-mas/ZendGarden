# Matched plant portraits from actual imported models, without loading player saves.
extends SceneTree

func _initialize() -> void:
 call_deferred("review")

func bounds(node: Node3D, parent: Transform3D=Transform3D.IDENTITY) -> AABB:
 var result=AABB()
 var combined=parent*node.transform
 if node is MeshInstance3D: result=combined*node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var box=bounds(child,combined)
   if box.size.length()>0: result=box if result.size.length()==0 else result.merge(box)
 return result

func old_leaf_materials(node: Node) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var source=node.mesh.surface_get_material(surface)
   if source is StandardMaterial3D and str(source.resource_name).begins_with("Leaf"):
    var material=ShaderMaterial.new()
    material.shader=load("res://captures/plants/before-leaf.gdshader")
    material.set_shader_parameter("leaf_texture",source.albedo_texture)
    material.set_shader_parameter("leaf_color",source.albedo_color)
    node.set_surface_override_material(surface,material)
 for child in node.get_children(): old_leaf_materials(child)

func review() -> void:
 var variant="before" if "--before" in OS.get_cmdline_user_args() else "after"
 var viewport=SubViewport.new()
 viewport.size=Vector2i(768,768)
 viewport.msaa_3d=Viewport.MSAA_4X
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var world=WorldEnvironment.new()
 world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR
 world.environment.background_color=Color("263331")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color=Color("e3e9df")
 world.environment.ambient_light_energy=.55
 world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 viewport.add_child(world)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-38,-32,0)
 sun.light_energy=1.4
 sun.shadow_enabled=true
 viewport.add_child(sun)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.far=100
 camera.current=true
 viewport.add_child(camera)
 var frames={}
 var frame_path="res://captures/plants/framing.json"
 if variant=="after": frames=JSON.parse_string(FileAccess.get_file_as_string(frame_path))
 var output_variant=variant+("-compat" if RenderingServer.get_current_rendering_method()=="gl_compatibility" else "")
 DirAccess.make_dir_recursive_absolute("res://captures/plants/"+output_variant)
 for data in GardenCatalogue.plants():
  var model: Node3D
  if "--raw" in OS.get_cmdline_user_args() or (variant=="before" and FileAccess.file_exists("res://captures/plants/before-assets/plant_00.glb")):
   var document=GLTFDocument.new()
   var state=GLTFState.new()
   var asset="res://captures/plants/before-assets/plant_%02d.glb"%data.id if variant=="before" else "res://assets/plants/plant_%02d.glb"%data.id
   if document.append_from_file(asset,state)!=OK:
    push_error("Could not load plant "+str(data.id))
    quit(1)
    return
   model=document.generate_scene(state)
   if variant=="before": old_leaf_materials(model)
   else: GardenArt.add_leaf_wind(model)
   model.rotation.y=float(data.id)*2.39996
  else:
   model=GardenArt.plant(data,true)
  viewport.add_child(model)
  var box=bounds(model)
  var key=str(data.id)
  if variant=="before":
   var c=box.get_center()
   frames[key]={"center":[c.x,c.y,c.z],"size":maxf(box.size.y,maxf(box.size.x,box.size.z)*1.25)*1.42}
  var f=frames[key]
  var center=Vector3(f.center[0],f.center[1],f.center[2])
  camera.position=center+Vector3(1,.48,1.5).normalized()*30
  camera.look_at(center)
  camera.size=f.size
  for frame in range(4): await process_frame
  await RenderingServer.frame_post_draw
  viewport.get_texture().get_image().save_png("res://captures/plants/%s/%02d.png"%[output_variant,data.id])
  print("PLANT_REVIEW: ",variant," ",data.id," ",data.name)
  model.free()
 if variant=="before":
  var file=FileAccess.open(frame_path,FileAccess.WRITE)
  file.store_string(JSON.stringify(frames," "))
 print("PLANT_REVIEW: PASS ",variant)
 quit()
