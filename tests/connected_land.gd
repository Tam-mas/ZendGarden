extends RefCounted

static func floor_at(g,pos: Vector3) -> Dictionary:
 var ray=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*6,pos+Vector3.DOWN*4)
 ray.exclude=[g.player.get_rid()]
 return g.get_world_3d().direct_space_state.intersect_ray(ray)

static func capture(g) -> void:
 if DisplayServer.get_name()=="headless":return
 g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 g.clock_time=.43;g.climate.current=Vector3.ZERO;g.climate.snow=0
 g.update_lighting();g.climate.apply(g);g.camera.fov=65
 DirAccess.make_dir_recursive_absolute("res://captures/connected-land")
 for view in [
  ["walking-view",Vector3(24,3,7.8),Vector3(52,1.5,-10)],
  ["overhead",Vector3(9,46,29),Vector3(43,0,-30)],
  ["all-gardens",Vector3(29,75,-30),Vector3(48,0,-45)]
 ]:
  g.camera.global_position=view[1];g.camera.look_at(view[2])
  for frame in range(4):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/connected-land/"+view[0]+".png")
 g.photo_mode=false

static func run(g,failures: Array) -> void:
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.dismiss_request();g.side_panel.hide()
 await g.get_tree().physics_frame
 var samples=0
 for z in [8.,0.,-8.,-16.,-24.,-36.,-48.,-60.,-72.,-84.,-96.,-107.5]:
  for x in [25.6,26.,30.,34.,38.,42.,43.9]:
   var p=Vector3(x,0,z);var hit=floor_at(g,p);samples+=1
   if not g.accessible(p) or hit.is_empty() or hit.normal.y<.9 or absf(hit.position.y-GardenConnectedLand.surface(p).y)>.025:
    failures.append("Joining lawn has no matching floor at "+str(p)+": "+str(hit))
 # The connection follows exact old and habitat heights, rather than moving
 # either garden. No new entrance is allowed to bypass a reward milestone.
 for index in range(10):
  if GardenAreaCatalogue.plot_open(g,index+4):failures.append("Land connection bypassed milestone "+str(index))
 for z in [0.,-24.,-48.,-72.,-96.]:
  if absf(GardenTerrain.base_rise(44-.001,z)-GardenTerrain.base_rise(44,z))>.001:
   failures.append("Habitat edge has a height step at "+str(z))
  var p=GardenTerrain.point(Vector3(44,0,z))+Vector3.UP*.25
  var ray=PhysicsRayQueryParameters3D.create(p-Vector3.RIGHT,p+Vector3.RIGHT)
  ray.exclude=[g.player.get_rid()]
  if not g.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
   failures.append("An old island wall blocks the joining lawn at "+str(z))
 # Saved hoe offsets update both the joining ground and original connector.
 for p in [Vector3(35,0,-40),Vector3(35,0,6)]:
  var before=floor_at(g,p)
  var key="%d:%d"%[p.x,p.z]
  GardenSculpt.restore(g,{key:.28});await g.get_tree().physics_frame
  var after=floor_at(g,p)
  if not GardenTerrain.offsets.has(key) or before.is_empty() or after.is_empty() or absf(after.position.y-before.position.y-.28)>.015:
   failures.append("Saved terrain edit detached the joining floor at "+str(p))
  g.save_game()
  var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
  if absf(float(saved.terrain.get(key,0))-.28)>.001:failures.append("Joining terrain was not saved at "+str(p))
  GardenSculpt.restore(g,saved.terrain)
  GardenSculpt.restore(g,{});await g.get_tree().physics_frame
 if g.plantable_ground(Vector3(35,0,6)):failures.append("Planting can cover the bluestone connector")
 if "--land-review" in OS.get_cmdline_user_args():
  await capture(g);print("CONNECTED_LAND_REVIEW_RESULT: ",failures);return
 var walker=preload("res://tests/walking.gd")
 for z in [0.,-20.]:
  await walker.cross(g,Vector3(24,0,z),Vector3(30,0,z),failures,"Original meadow seam "+str(z))
  await walker.cross(g,Vector3(30,0,z),Vector3(24,0,z),failures,"Original meadow return "+str(z))
 for z in [0.,-24.,-48.,-72.,-96.]:
  for points in [[28.,36.],[36.,45.],[45.,36.]]:
   await walker.cross(g,Vector3(points[0],0,z),Vector3(points[1],0,z),failures,"Lawn to habitat "+str(z))
 for z in [6.,-12.,-36.,-60.,-84.]:
  await walker.cross(g,Vector3(35,0,z),Vector3(35,0,z-8),failures,"Along joining land "+str(z))
 await capture(g)
 # Later original bed rows meet the same land without recreating an internal
 # earth bank. Exercise a newly built row rather than only the first garden.
 g.unlocked_plots=12;GardenExpansion.prepare(g)
 for row in range(2,int(GardenAreaCatalogue.legacy_plot_count(g)/2)):GardenExpansion.build_row(g,row)
 await g.get_tree().physics_frame
 await walker.cross(g,Vector3(24,0,-34),Vector3(30,0,-34),failures,"Growing meadow seam")
 await walker.cross(g,Vector3(30,0,-34),Vector3(24,0,-34),failures,"Growing meadow return")
 print("CONNECTED_LAND_RESULT: ",failures," (",samples," floor samples and 26 real walks)")
