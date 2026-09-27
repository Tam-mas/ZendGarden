# Read-only render review; does not load or write a player save.
extends SceneTree

func _initialize() -> void:
 call_deferred("review")

func set_mountain_material(node: Node, shader: Shader) -> void:
 if node is MeshInstance3D and str(node.name) in ["AlpineLakeValley","OuterMountainRidges"]:
  var material=ShaderMaterial.new()
  material.shader=shader
  material.set_shader_parameter("strata",load("res://assets/textures/Mountain_strata.png"))
  material.set_shader_parameter("rock_normal",load("res://assets/textures/Mountain_strata_normal.png"))
  node.material_override=material
 for child in node.get_children(): set_mountain_material(child,shader)

func review() -> void:
 root.size=Vector2i(1440,900)
 var stage=Node3D.new()
 root.add_child(stage)
 var environment=WorldEnvironment.new()
 var env=Environment.new()
 env.background_mode=Environment.BG_SKY
 env.sky=Sky.new()
 var sky=ShaderMaterial.new()
 sky.shader=load("res://shaders/country_sky.gdshader")
 var angle=(.44-.25)*TAU
 var direction=Vector3(cos(angle)*.45,sin(angle),cos(angle)*.89).normalized()
 sky.set_shader_parameter("sun_direction",direction)
 sky.set_shader_parameter("sky_motion",13.44)
 sky.set_shader_parameter("day_phase",.44)
 env.sky.sky_material=sky
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color=Color("e4e7cc")
 env.ambient_light_energy=.54
 env.fog_enabled=true
 env.fog_density=.00012
 env.fog_light_color=Color("bfd6cd")
 env.fog_sky_affect=.08
 environment.environment=env
 stage.add_child(environment)
 var sun=DirectionalLight3D.new()
 sun.light_color=Color("ffedcd")
 sun.light_energy=.975
 sun.quaternion=Quaternion(Vector3.FORWARD,-direction)
 stage.add_child(sun)
 var camera=Camera3D.new()
 camera.position=Vector3(0,4,8)
 camera.far=10000
 camera.fov=60
 stage.add_child(camera)
 var review_dir="res://captures/woodland" if "--woodland" in OS.get_cmdline_user_args() else "res://captures/mountains"
 DirAccess.make_dir_recursive_absolute(review_dir)
 var variants=["after"]
 if "--compare" in OS.get_cmdline_user_args(): variants=["before","after"]
 for variant in variants:
  var path=review_dir+"/before.glb" if variant=="before" else "res://assets/environment/lake_garden.glb"
  var landscape: Node3D
  if variant=="before":
   var document=GLTFDocument.new()
   var state=GLTFState.new()
   if document.append_from_file(path,state)!=OK:
    push_error("Could not import baseline landscape")
    quit(1)
    return
   landscape=document.generate_scene(state)
  else:
   landscape=load(path).instantiate()
  stage.add_child(landscape)
  GardenLandscape.recede_landscape(landscape)
  if variant=="before": set_mountain_material(landscape,load(review_dir+"/before.gdshader"))
  var views={"west":Vector3(-1,.18,-.30),"north":Vector3(-.15,.15,-1),"east":Vector3(1,.20,-.15),"south":Vector3(.10,.15,1)}
  for label in views:
   camera.look_at(camera.position+views[label])
   for frame in range(12): await process_frame
   if "--benchmark" in OS.get_cmdline_user_args():
    var started=Time.get_ticks_usec()
    for frame in range(120): await process_frame
    var seconds=(Time.get_ticks_usec()-started)/1000000.0
    print("MOUNTAIN_BENCHMARK: ",variant," ",label," fps=",snappedf(120.0/seconds,.1))
   await RenderingServer.frame_post_draw
   var suffix="-compat" if RenderingServer.get_current_rendering_method()=="gl_compatibility" else ""
   var file=review_dir+"/"+variant+"-"+label+suffix+".png"
   root.get_texture().get_image().save_png(file)
   print("MOUNTAIN_PREVIEW: ",file)
  landscape.free()
 print("MOUNTAIN_PREVIEW: PASS")
 quit()
