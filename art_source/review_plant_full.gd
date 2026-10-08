# Matched portraits of the full plant art pass using the game's actual materials.
# This isolated review scene never loads a player's garden or changes game settings.
extends SceneTree

var IDS=range(218)
const FOLDER="res://captures/plant-full"

func _initialize() -> void:call_deferred("review")

func bounds(node: Node3D, parent: Transform3D=Transform3D.IDENTITY) -> AABB:
 var result=AABB()
 var transform=parent*node.transform
 if node is MeshInstance3D:result=transform*node.get_aabb()
 for child in node.get_children():
  if child is Node3D:
   var box=bounds(child,transform)
   if box.size.length()>0:result=box if result.size.length()==0 else result.merge(box)
 return result

func capture(viewport: SubViewport, path: String) -> void:
 for frame in range(3):await process_frame
 await RenderingServer.frame_post_draw
 viewport.get_texture().get_image().save_png(path)

func review() -> void:
 var before="--before" in OS.get_cmdline_user_args()
 var variant="before" if before else "after"
 var output=FOLDER+"/"+variant
 DirAccess.make_dir_recursive_absolute(output)
 var ignore=FileAccess.open(FOLDER+"/.gdignore",FileAccess.WRITE)
 ignore.close()
 var viewport=SubViewport.new()
 viewport.size=Vector2i(320,320) if "--stages" in OS.get_cmdline_user_args() else Vector2i(512,512)
 viewport.msaa_3d=Viewport.MSAA_2X
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var world=WorldEnvironment.new()
 world.environment=Environment.new()
 world.environment.background_mode=Environment.BG_COLOR
 world.environment.background_color=Color("263331")
 world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 world.environment.ambient_light_color=Color("e4e7cc")
 world.environment.ambient_light_energy=.4
 world.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 viewport.add_child(world)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-40,-35,0)
 sun.light_color=Color("ffe5bd")
 sun.light_energy=1.15
 sun.shadow_enabled=true
 viewport.add_child(sun)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.far=100
 camera.current=true
 viewport.add_child(camera)
 var frame_path=FOLDER+"/framing.json"
 var frames={}
 if FileAccess.file_exists(frame_path):frames=JSON.parse_string(FileAccess.get_file_as_string(frame_path))
 var catalogue=GardenCatalogue.plants()
 var chosen=IDS
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--ids="):
   chosen=[]
   for value in arg.trim_prefix("--ids=").split(","):chosen.append(int(value))
 for id in chosen:
  var model=GardenArt.plant(catalogue[id],true)
  viewport.add_child(model)
  var box=bounds(model)
  if before:
   var c=box.get_center()
   frames[str(id)]={"center":[c.x,c.y,c.z],"size":maxf(box.size.y,maxf(box.size.x,box.size.z)*1.25)*1.48}
  var f=frames[str(id)]
  var center=Vector3(f.center[0],f.center[1],f.center[2])
  camera.position=center+Vector3(1,.48,1.5).normalized()*30
  camera.look_at(center)
  camera.size=f.size
  if not "--stages" in OS.get_cmdline_user_args():await capture(viewport,output+"/%02d.png"%id)
  for i in range(5 if "--stages" in OS.get_cmdline_user_args() else 0):
   var fraction=[.10,.35,.65,.85,1.0][i]
   var scale=Vector3.ONE*lerpf(.12,1.0,fraction)
   model.scale=scale
   GardenPlantGrowth.apply(model,catalogue[id],fraction,812+id,scale)
   await capture(viewport,output+"/%02d-stage-%d.png"%[id,i])
  model.free()
  print("PLANT_FULL_REVIEW: ",variant," ",id)
 if before:
  var file=FileAccess.open(frame_path,FileAccess.WRITE)
  file.store_string(JSON.stringify(frames," "))
 print("PLANT_FULL_REVIEW: PASS ",variant)
 quit()
