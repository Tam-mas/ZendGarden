extends SceneTree

func _initialize() -> void:call_deferred("render_motion")

func render_motion() -> void:
 root.size=Vector2i(640,640)
 root.content_scale_size=Vector2i(640,640)
 var stage=Node3D.new()
 root.add_child(stage)
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("e4e0d5")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=.45
 environment.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 stage.add_child(environment)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-45,-30,0)
 sun.light_energy=1.0
 sun.shadow_enabled=true
 stage.add_child(sun)
 var floor=MeshInstance3D.new()
 var plane=PlaneMesh.new()
 plane.size=Vector2(30,30)
 floor.mesh=plane
 var material=StandardMaterial3D.new()
 material.albedo_color=Color(.24,.225,.195)
 material.roughness=1
 floor.material_override=material
 floor.position.y=-.015
 stage.add_child(floor)
 var camera=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.current=true
 stage.add_child(camera)
 DirAccess.make_dir_recursive_absolute("res://captures/overhaul/motion")
 for pair in [["cat","walk"],["wombat","walk"],["kangaroo","hop"],["kookaburra","flight"],["fairy_wren","perch"],["fish","swim"]]:
  var model=GardenArt.detailed_model("companions" if pair[0]=="cat" else "wildlife",pair[0])
  stage.add_child(model)
  var size=.8 if pair[0] in ["kookaburra","fairy_wren","fish"] else 1.7 if pair[0]=="kangaroo" else 1.3
  var center=Vector3(0,size*.28,0)
  camera.size=size*.90
  camera.position=center+Vector3(1.4,.8,-1.8)*size
  camera.look_at(center)
  var player=GardenAnimalMotion.player(model)
  GardenAnimalMotion.advance(model,pair[1],0)
  var duration=player.get_animation(pair[1]).length
  for frame in range(16):
   player.seek(duration*float(frame)/16,true)
   for tick in range(3):await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://captures/overhaul/motion/%s_%s_%02d.png"%[pair[0],pair[1],frame])
  model.free()
 stage.free()
 print("OVERHAUL_MOTION_REVIEW: PASS")
 quit()
