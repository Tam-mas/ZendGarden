# Close-up of the actual exported game model; no player save is loaded.
extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(1200,800)
 var stage=Node3D.new();root.add_child(stage)
 var env=WorldEnvironment.new();env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color("263d33")
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color("e1efd8");env.environment.ambient_light_energy=.65
 stage.add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-30,0);sun.light_energy=1.3;sun.shadow_enabled=true;stage.add_child(sun)
 var model=GardenArt.visitor("lady beetle");stage.add_child(model)
 var ground=MeshInstance3D.new();ground.mesh=PlaneMesh.new();ground.mesh.size=Vector2(2,2)
 ground.material_override=GardenArt.mat(Color("54724a"),.85);stage.add_child(ground)
 var camera=Camera3D.new();camera.near=.001;camera.position=Vector3(.09,.105,-.13);camera.fov=39;stage.add_child(camera);camera.look_at(Vector3(0,.02,0))
 for frame in range(12):await process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://captures/tools")
 root.get_texture().get_image().save_png("res://captures/tools/lady-beetle.png")
 print("LADY_BEETLE_PREVIEW: PASS")
 quit()
