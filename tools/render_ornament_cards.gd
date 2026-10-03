extends SceneTree

func _initialize() -> void: call_deferred("render_cards")

func bounds(node: Node3D, origin: Node3D) -> AABB:
 var result=AABB()
 if node is MeshInstance3D:result=origin.global_transform.affine_inverse()*node.global_transform*node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var box=bounds(child,origin)
   if box.size.length()>0:result=box if result.size.length()==0 else result.merge(box)
 return result

func render_cards() -> void:
 get_root().size=Vector2i(320,320)
 var stage=Node3D.new();root.add_child(stage)
 var world=WorldEnvironment.new();world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR
 world.environment.background_color=Color("5b624b")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color=Color.WHITE
 world.environment.ambient_light_energy=.75
 stage.add_child(world)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-30,0);stage.add_child(sun)
 var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;stage.add_child(camera)
 DirAccess.make_dir_recursive_absolute("res://assets/ui/shop")
 for item in GardenCatalogue.furnishings():
  var model=GardenArt.furnishing(item.kind)
  stage.add_child(model)
  var box=bounds(model,model)
  var center=box.get_center()
  camera.size=maxf(box.size.length()*.90,.4)
  camera.position=center+Vector3(1.4,.95,1.8)*maxf(1.0,box.size.length())
  camera.look_at(center)
  for i in range(4):await process_frame
  await RenderingServer.frame_post_draw
  GardenArt.save_card(get_root().get_texture().get_image(),"res://assets/ui/shop/"+item.kind)
  model.free()
 stage.free()
 print("ORNAMENT_CARDS: PASS")
 quit()
