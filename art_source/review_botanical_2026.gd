# Isolated art review: uses game materials without opening or saving a garden.
extends SceneTree

func _initialize() -> void:call_deferred("review")

func bounds(node: Node3D, parent: Transform3D=Transform3D.IDENTITY) -> AABB:
 var result=AABB()
 var transform=parent*node.transform
 if node is MeshInstance3D:result=transform*node.get_aabb()
 for child in node.get_children():
  if child is Node3D and child.visible:
   var box=bounds(child,transform)
   if box.size.length()>0:result=box if result.size.length()==0 else result.merge(box)
 return result

func review() -> void:
 var ids=[49,78,79]
 ids.append_array(range(218,278))
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--ids="):
   ids=[]
   for value in arg.trim_prefix("--ids=").split(","):ids.append(int(value))
 var stages="--stages" in OS.get_cmdline_user_args()
 var folder="res://captures/botanical-2026/review"
 DirAccess.make_dir_recursive_absolute(folder)
 var view=SubViewport.new()
 view.size=Vector2i(512,512)
 view.msaa_3d=Viewport.MSAA_2X
 view.own_world_3d=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var world=WorldEnvironment.new()
 world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR
 world.environment.background_color=Color("dedacb")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color=Color("e7eee4")
 world.environment.ambient_light_energy=.55
 view.add_child(world)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-38,-35,0)
 sun.light_color=Color("fff3dc")
 sun.light_energy=1.0
 view.add_child(sun)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.current=true
 view.add_child(camera)
 var catalogue=GardenCatalogue.plants()
 for id in ids:
  var model=GardenArt.plant(catalogue[id],true)
  view.add_child(model)
  for stage_index in range(5 if stages else 1):
   if stages:
    var fraction=[.10,.35,.65,.85,1.0][stage_index]
    model.scale=Vector3.ONE*lerpf(.12,1.0,fraction)
    GardenPlantGrowth.apply(model,catalogue[id],fraction,1000+id,model.scale)
   var box=bounds(model)
   var center=box.get_center()
   var distance=maxf(5,box.size.length()*2)
   camera.position=center+Vector3(1,.50,1.5).normalized()*distance
   camera.look_at(center)
   camera.size=maxf(box.size.y,maxf(box.size.x,box.size.z)*1.25)*1.27
   camera.far=distance*3
   for frame in range(3):await process_frame
   await RenderingServer.frame_post_draw
   view.get_texture().get_image().save_png(folder+("/%02d-stage-%d.png"%[id,stage_index] if stages else "/%02d.png"%id))
  model.free()
  print("BOTANICAL_2026_REVIEW ",id)
 print("BOTANICAL_2026_REVIEW: PASS")
 quit()
