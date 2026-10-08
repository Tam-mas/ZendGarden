extends RefCounted

static func floor_at(g,pos: Vector3) -> Dictionary:
 var ray=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*9,pos+Vector3.DOWN*9)
 ray.exclude=[g.player.get_rid()]
 return g.get_world_3d().direct_space_state.intersect_ray(ray)

static func capture(g) -> void:
 if DisplayServer.get_name()=="headless":return
 g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 g.clock_time=.43;g.climate.current=Vector3.ZERO;g.climate.snow=0
 g.update_lighting();g.climate.apply(g);g.camera.fov=65
 var dir="res://captures/alpine-ravine"
 if "--forward-review" in OS.get_cmdline_user_args():dir+="/forward-plus"
 DirAccess.make_dir_recursive_absolute(dir)
 for view in [
  ["blocked-bank-path",Vector3(27,2.5,-21),Vector3(27,.6,-27)],
  ["south-landing",Vector3(24,2.4,9),Vector3(27,.6,4)],
  ["west-exposed-side",Vector3(12,2,-36),Vector3(31,-1,-55)],
  ["east-outer-edge",Vector3(89,3,-51),Vector3(93,1,-65)],
  ["outlet-edge",Vector3(22,3,14),Vector3(31,-3,12)],
  ["original-edge",Vector3(-7,2.5,6),Vector3(-12,0,-2)],
  ["north-outer-edge",Vector3(62,3,-104),Vector3(59,1,-110)],
  ["south-bridge",Vector3(29,5,17),Vector3(36,-.1,3)],
  ["stream-walk",Vector3(27.9,2.5,-13),Vector3(35,-2,-29)],
  ["central-arch",Vector3(31,-.1,-38),Vector3(35,0,-48)],
  ["middle-connection",Vector3(52,15,-38),Vector3(47,0,-54)],
  ["north-bridge",Vector3(29,5,-91),Vector3(36,-.1,-102)],
  ["cascades",Vector3(37,-.2,-19),Vector3(34,-2.7,-29)],
  ["all-three-bridges",Vector3(2,82,26),Vector3(42,-1,-49)],
  ["bridge-walking",Vector3(26.3,2.2,6),Vector3(43,2,6)],
  ["north-connection",Vector3(54,13,-118),Vector3(52,1,-104)]
 ]:
  g.camera.global_position=view[1];g.camera.look_at(view[2])
  for frame in range(5):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png(dir+"/"+view[0]+".png")
 # Lighting and flowing water must hold up in rain and at dusk.
 for lighting in [["dusk",.78,Vector3.ZERO],["rain",.43,Vector3(.7,.75,.3)]]:
  g.clock_time=lighting[1];g.climate.current=lighting[2];g.update_lighting();g.climate.apply(g)
  g.camera.global_position=Vector3(29,5,17);g.camera.look_at(Vector3(36,-.1,3))
  for frame in range(6):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png(dir+"/south-"+lighting[0]+".png")
 g.photo_mode=false

static func run(g,failures: Array) -> void:
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.dismiss_request();g.side_panel.hide();GardenSculpt.restore(g,{})
 await g.get_tree().physics_frame
 var samples=0
 for j in range(3):
  var z: float=GardenRavine.BRIDGES[j]
  for x in range(26,44):
   for offset in [-.95,0.,.95]:
    var p=Vector3(x,0,z+offset);var hit=floor_at(g,p);samples+=1
    if not g.accessible(p) or hit.is_empty() or hit.normal.y<.96 or absf(hit.position.y-GardenRavine.deck(x,z))>.012:
     failures.append("Stone bridge floor mismatch "+str(p)+": "+str(hit))
  # Rails guard both sides of the river span without blocking either landing.
  for side in [-1,1]:
   var p=Vector3(35,GardenRavine.deck(35,z)+.55,z)
   var query=PhysicsRayQueryParameters3D.create(p,p+Vector3(0,0,side*2.1));query.exclude=[g.player.get_rid()]
   if g.get_world_3d().direct_space_state.intersect_ray(query).is_empty():failures.append("Missing bridge parapet "+str(j))
 for route in GardenAreaTransitions.route_data().bridge_links:
  for j in range(0,route.size(),2):
   var p=Vector3(route[j][0],0,route[j][1]);var hit=floor_at(g,p);samples+=1
   if hit.is_empty() or hit.normal.y<.88 or absf(hit.position.y-GardenTerrain.point(p).y-.055)>.08:
    failures.append("Bridge link floor obstructed "+str(p)+": "+str(hit))
 for z in range(-106,11,2):
  var s=GardenRavine.stream(z)
  if s.y< GardenRavine.stream(z+.25).y:failures.append("Stream flows uphill "+str(z))
  if GardenRavine.bridge_at(Vector3(s.x,0,z))<0 and g.accessible(Vector3(s.x,0,z)):failures.append("Player can walk into deep stream "+str(z))
  if g.plantable_ground(Vector3(s.x,0,z)):failures.append("Stream allows planting")
  if GardenRavine.ground(s.x,z)>s.y-.30:failures.append("Dry streambed "+str(z))
  for x in [25.51,43.99]:
   if absf(GardenRavine.ground(x,z)-(GardenTerrain.original_rise(25.5,z)+.02 if x<30 else 1.235))>.006:failures.append("Bank seam gap "+str(Vector2(x,z)))
 for index in range(10):
  if GardenAreaCatalogue.plot_open(g,index+4):failures.append("Bridge bypassed garden milestone "+str(index))
 # Old sculpt data survives saving but cannot deform new protected foundations.
 var p=Vector3(35,0,6);var before=floor_at(g,p)
 GardenSculpt.restore(g,{"35:6":.28,"35:-40":.24});await g.get_tree().physics_frame
 var after=floor_at(g,p)
 if not GardenTerrain.offsets.has("35:6") or before.is_empty() or after.is_empty() or absf(before.position.y-after.position.y)>.001:failures.append("Legacy sculpt offsets moved the new bridge")
 g.save_game();var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if absf(saved.terrain.get("35:6",0)-.28)>.001:failures.append("Legacy terrain record lost")
 GardenSculpt.restore(g,{})
 for q in [Vector3(35,0,-40),Vector3(35,0,6)]:
  var restored=GardenRavine.safe_player(q)
  if not g.accessible(restored) or (GardenRavine.bridge_at(q)>=0 and restored.y<1.):failures.append("Saved player restored beneath crossing or in water")
 # A previous save can contain planting and a working container on the lawn.
 var stored_count=g.workshop_state.nursery.size()
 var seed=g.add_plant(12,Vector3(35,0,-40),0,4.)
 g.add_object("pot",Vector3(36,0,-42),20)
 var pot=g.objects.back();var uid=pot.uid
 var pocket=g.add_plant(0,pot.pos,0,3.);GardenContainers.attach(g,pocket,pot,0)
 GardenRavine.recover_arrangements(g)
 if g.workshop_state.nursery.size()!=stored_count+1 or g.workshop_state.nursery.back().age!=4.:failures.append("Former lawn plant care record lost")
 if GardenConnectedLand.contains(pot.pos) or pot.uid!=uid or pocket.container_uid!=uid or pocket.pos.distance_to(GardenContainers.position(pot,0))>.001:failures.append("Former lawn planter or contents lost")
 GardenRavine.recover_arrangements(g)
 if g.workshop_state.nursery.size()!=stored_count+1:failures.append("Ravine recovery duplicates plants")
 pocket.node.queue_free();pocket.marker.queue_free();g.planted.erase(pocket)
 pot.node.queue_free();g.objects.erase(pot)
 g.workshop_state.nursery.resize(stored_count);GardenSaveFiles.arrival_notice=""
 # Companions follow the three deck crossings and stay above the water.
 GardenCompanion.prepare_navigation(g)
 var pet_route=GardenCompanion.navigation.get_point_path(Vector2i(54,-96),Vector2i(90,-96))
 if pet_route.is_empty():failures.append("Companions cannot reach the middle bridge")
 for waypoint in pet_route:
  if not g.accessible(Vector3(waypoint.x,0,waypoint.y)):failures.append("Companion route enters ravine")
 var pet=g.pets[0];pet.position=Vector3(35,0,-48);pet.animate(g,0.,0)
 if absf(pet.position.y-GardenRavine.deck(35,-48))>.001:failures.append("Companion sinks below arch deck")
 await preload("res://tests/water_surfaces.gd").run(g,failures)
 if "--land-review" not in OS.get_cmdline_user_args():
  var walker=preload("res://tests/walking.gd")
  for z in GardenRavine.BRIDGES:
   for segment in [[26.2,31.],[31.,37.],[37.,44.5],[44.5,37.],[37.,31.],[31.,26.2]]:
    await cross_bridge(g,walker,Vector3(segment[0],0,z),Vector3(segment[1],0,z),failures)
  for route in GardenAreaTransitions.route_data().bridge_links:
   for j in range(0,route.size()-1,20):
    var a=route[j];var b=route[mini(j+20,route.size()-1)]
    await walker.cross(g,Vector3(a[0],0,a[1]),Vector3(b[0],0,b[1]),failures,"Bridge approach")
  for z in range(6,-102,-6):
   await walker.cross(g,Vector3(27,0,z),Vector3(27,0,z-6),failures,"Full bank trail outward")
   await walker.cross(g,Vector3(27,0,z-6),Vector3(27,0,z),failures,"Full bank trail return")
  for side in [-.8,0.,.8]:
   await walker.cross(g,Vector3(23.3,0,6+side),Vector3(29,0,6+side),failures,"Wide southern landing")
   await walker.cross(g,Vector3(29,0,6+side),Vector3(23.3,0,6+side),failures,"Southern landing return")
 await preload("res://tests/garden_boundary.gd").run(g,failures)
 await capture(g)
 print("CONNECTED_LAND_RESULT: ",failures," (",samples," bridge and approach samples)")

static func cross_bridge(g,walker,start: Vector3,finish: Vector3,failures: Array) -> void:
 # The walker starts above planting terrain; lift it to the actual arch deck.
 # Divide at the crown and compare contact through a dedicated physical walk.
 g.player.position=GardenRavine.safe_player(start)+Vector3.UP*.6;g.player.velocity=Vector3.ZERO
 await walker.land(g)
 for frame in range(180):
  await g.get_tree().physics_frame
  var d=finish-g.player.position;d.y=0
  if d.length()<.2:return
  var dt=g.get_physics_process_delta_time();d=d.normalized()*3.2
  if not g.accessible(g.player.position+d*dt):failures.append("Bridge access blocked "+str(g.player.position));return
  g.player.velocity=Vector3(d.x,0 if g.player.is_on_floor() else g.player.velocity.y-18*dt,d.z)
  g.walk_motion(d*dt);g.player.move_and_slide()
  if g.player.position.y<.1:failures.append("Fell under stone bridge "+str(g.player.position));return
 failures.append("Stone bridge walk blocked "+str(g.player.position))
