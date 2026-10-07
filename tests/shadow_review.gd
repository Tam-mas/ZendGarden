extends RefCounted

static func run(g) -> void:
 if DisplayServer.get_name()=="headless":return
 g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 var sign=g.Art.furnishing("sign");g.world_root.add_child(sign)
 sign.position=GardenTerrain.point(Vector3(64,0,-15.3));sign.rotation.y=-PI/4
 g.camera.global_position=Vector3(66.5,3.05,-13.3)
 g.camera.look_at(Vector3(63.6,1.5,-16.5));g.camera.fov=74
 g.climate.current=Vector3.ZERO;g.climate.snow=0
 DirAccess.make_dir_recursive_absolute("res://captures/shadow-review")
 for profile in ["before","after"]:
  GardenWorldLighting.configure(g)
  if profile=="before":
   g.sun.directional_shadow_max_distance=90
   g.sun.directional_shadow_split_1=.1;g.sun.directional_shadow_split_2=.2;g.sun.directional_shadow_split_3=.5
   g.sun.directional_shadow_blend_splits=false;g.sun.shadow_blur=1.
   g.sun.shadow_bias=.1;g.sun.shadow_normal_bias=2.
   RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
  for frame in range(32):
   g.clock_time=.59+frame*.10/g.DAY_SECONDS
   g.update_lighting();g.climate.apply(g)
   for settling in range(2):await g.get_tree().process_frame
   await RenderingServer.frame_post_draw
   g.get_viewport().get_texture().get_image().save_png("res://captures/shadow-review/%s-%03d.png"%[profile,frame])
 sign.queue_free();g.photo_mode=false
