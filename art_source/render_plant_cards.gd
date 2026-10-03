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
 var rendered=0
 var chosen: Array=[]
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--ids="):
   for id in arg.trim_prefix("--ids=").split(","):chosen.append(int(id))
 var review_directory="res://captures/botanical-review-compat" if "--compat-review" in OS.get_cmdline_user_args() else "res://captures/botanical-review"
 DirAccess.make_dir_recursive_absolute(review_directory)
 for plant in catalogue:
  if not chosen.is_empty() and plant.id not in chosen:continue
  if "--new-only" in OS.get_cmdline_user_args() and plant.id<60: continue
  rendered+=1
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
  var portrait=viewport.get_texture().get_image()
  if review:portrait.save_png((review_directory+"/%02d.png")%plant.id)
  else:GardenArt.save_card(portrait,"res://assets/ui/plants/%02d"%plant.id)
  if review and "--portraits" in OS.get_cmdline_user_args():
   portrait.resize(192,192,Image.INTERPOLATE_LANCZOS)
   GardenArt.save_card(portrait,"res://assets/ui/plants/%02d"%plant.id)
  viewport.remove_child(model)
  model.queue_free()
 print("PLANT_CARD_RENDER: PASS — %d model portraits" % rendered)
 quit()
