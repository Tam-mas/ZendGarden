extends SceneTree

# Render the same authored tools held in the game, with the shop portrait setup.
func _initialize() -> void:call_deferred("render_cards")

func bounds(node: Node3D, origin: Node3D) -> AABB:
 var result=AABB()
 if node is MeshInstance3D:result=origin.global_transform.affine_inverse()*node.global_transform*node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var box=bounds(child,origin)
   if box.size.length()>0:result=box if result.size.length()==0 else result.merge(box)
 return result

func render_cards() -> void:
 var viewport=SubViewport.new()
 viewport.size=Vector2i(320,320)
 viewport.transparent_bg=true
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var stage=Node3D.new();viewport.add_child(stage)
 var world=WorldEnvironment.new();world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR
 world.environment.background_color=Color(0,0,0,0)
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color=Color.WHITE
 world.environment.ambient_light_energy=1.25
 stage.add_child(world)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-30,0);sun.light_energy=1.4;stage.add_child(sun)
 var fill=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,145,0);fill.light_energy=.8;stage.add_child(fill)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;stage.add_child(camera)
 DirAccess.make_dir_recursive_absolute("res://assets/ui/tools")
 var kinds=["torch"] if "--torch-only" in OS.get_cmdline_user_args() else ["can","shears","trowel","rake"]
 for kind in kinds:
  var model=load("res://assets/tools/"+kind+".glb").instantiate()
  stage.add_child(model)
  var box=bounds(model,model)
  var center=box.get_center()
  camera.size=maxf(box.size.length()*.82,.4)
  camera.position=center+Vector3(1.4,1.1,-1.8 if kind=="torch" else 1.8)*maxf(1.0,box.size.length())
  camera.look_at(center)
  for frame in range(4):await process_frame
  await RenderingServer.frame_post_draw
  GardenArt.save_card(viewport.get_texture().get_image(),"res://assets/ui/tools/"+kind)
  model.free()
 viewport.free()
 print("TOOL_CARDS: PASS")
 quit()
