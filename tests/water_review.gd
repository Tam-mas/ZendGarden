extends RefCounted

static func run(g) -> void:
 if DisplayServer.get_name()=="headless":return
 var water=g.get_node("GardenWater");water.set_process(false)
 g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 g.clock_time=.43;g.climate.current=Vector3.ZERO;g.climate.snow=0
 g.camera.fov=60;g.update_lighting();g.climate.apply(g)
 DirAccess.make_dir_recursive_absolute("res://captures/water-review")
 for view in [
  ["lake",Vector3(-1,3,-24),Vector3(-16,-1,-42)],
  ["stream",Vector3(80,2.6,1),Vector3(80,.85,-3.5)],
  ["ripples",Vector3(79,3.5,-91),Vector3(79,.95,-96)]
 ]:
  g.camera.global_position=view[1];g.camera.look_at(view[2]);g.update_lighting()
  for entry in water.surfaces:entry.events.clear();water.sync_events(entry)
  water.elapsed=0.
  for frame in range(36):
   if view[0]=="ripples" and frame==4:GardenWater.disturb(g,Vector3(79,.95,-96),1.2)
   water._process(1./12.)
   for settling in range(2):await g.get_tree().process_frame
   await RenderingServer.frame_post_draw
   g.get_viewport().get_texture().get_image().save_png("res://captures/water-review/%s-%03d.png"%[view[0],frame])
 water.set_process(true);g.photo_mode=false
