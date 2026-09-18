extends SceneTree

func _initialize() -> void:
 call_deferred("render_cards")

func bounds(node: Node3D, transform: Transform3D=Transform3D.IDENTITY) -> AABB:
 var result=AABB()
 var combined=transform*node.transform
 if node is MeshInstance3D: result=combined*node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var child_box=bounds(child,combined)
   if child_box.size.length()>0: result=child_box if result.size.length()==0 else result.merge(child_box)
 return result

func render_cards() -> void:
 var viewport=SubViewport.new()
 var review="--review" in OS.get_cmdline_user_args()
 viewport.size=Vector2i(512,512) if review else Vector2i(192,192)
 viewport.transparent_bg=true
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_CLEAR_COLOR
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=.8
 viewport.add_child(environment)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-40,-35,0)
 sun.light_energy=1.1
 viewport.add_child(sun)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 viewport.add_child(camera)
 camera.current=true
 var catalogue=GardenCatalogue.plants()
 for plant in catalogue:
  var model=GardenArt.plant(plant,true)
  viewport.add_child(model)
  var box=bounds(model)
  var center=box.get_center()
  camera.position=center+Vector3(1,.55,1.5).normalized()*maxf(5,box.size.length()*2)
  camera.look_at(center)
  camera.size=maxf(box.size.y,maxf(box.size.x,box.size.z)*1.25)*1.25
  camera.far=100
  await process_frame
  await RenderingServer.frame_post_draw
  viewport.get_texture().get_image().save_png(("res://captures/botanical-review/%02d.png" if review else "res://assets/ui/plants/%02d.png") % plant.id)
  viewport.remove_child(model)
  model.queue_free()
 print("PLANT_CARD_RENDER: PASS — 60 original model portraits")
 quit()
