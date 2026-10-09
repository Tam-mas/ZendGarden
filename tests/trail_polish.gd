extends RefCounted

static func check(value: bool,failures: Array,message: String) -> void:
 if not value:failures.append(message)

static func alpine_furniture(g,failures: Array) -> void:
 check(GardenAreaFurnishings.ordinary(8).is_empty(),failures,"Alpine hillside still receives a default chair")
 for index in range(10):
  if index!=8:check(GardenAreaFurnishings.ordinary(index).any(func(stock):return stock.id=="bench"),failures,"Another area's bench was removed: "+str(index))
 var original=GardenAreaCatalogue.center(8)+GardenAreaFurnishings.BENCHES[8]
 var before=g.objects.size()
 var added=[]
 for spec in [
  [original,0,0.,{"starter_id":"alpine:starter-bench"}],
  [original,0,0.,{}],
  [original+Vector3(3,0,3),0,0.,{"starter_id":"alpine:starter-bench"}],
  [original,0,.7,{"starter_id":"alpine:starter-bench"}],
  [original,12,0.,{}]
 ]:
  g.add_object("bench",spec[0],spec[1],false,spec[2],"My garden",Color("f1e5c7"),spec[3]);added.append(g.objects.back())
 GardenAreaFurnishings.restore(g)
 check(g.objects.size()==before+3,failures,"Old alpine chair cleanup removed player furniture or missed an untouched chair")
 check(not added[0] in g.objects and not added[1] in g.objects,failures,"Original hillside chairs remain in an existing save")
 for obj in added.slice(2):check(obj in g.objects,failures,"Moved, rotated or purchased chair was removed")
 GardenAreaFurnishings.restore(g)
 check(g.objects.size()==before+3,failures,"Chair cleanup changes furniture on a second restore")
 for obj in added:
  if obj in g.objects:obj.node.queue_free();g.objects.erase(obj)

static func capture(g) -> void:
 if DisplayServer.get_name()=="headless":return
 g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 g.clock_time=.43;g.climate.current=Vector3.ZERO;g.climate.snow=0
 g.update_lighting();g.climate.apply(g);g.camera.fov=65
 if not OS.has_feature("web"):DirAccess.make_dir_recursive_absolute("res://captures/trail-polish")
 for view in [
  ["fern-entrance",Vector3(69.2,3.2,7.3),Vector3(74,1.5,9.6)],
  ["main-trail-turn",Vector3(72,9,15),Vector3(65,1,9)],
  ["terrace-threshold",Vector3(64.8,3.1,-14.9),Vector3(62.5,1.3,-18)],
  ["meadow-gateway",Vector3(80,3,-35),Vector3(80.3,1.5,-30)],
  ["joining-meadow",Vector3(26,2.6,-7),Vector3(40,1.2,-24)],
  ["fern-current",Vector3(80,3,0),Vector3(80.3,.9,-3)],
  ["lake-waves",Vector3(-1,3,-24),Vector3(-16,-1,-42)]
 ]:
  g.camera.global_position=view[1];g.camera.look_at(view[2])
  for frame in range(4):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  # Browser exports keep res:// read-only; still draw every review camera.
  if not OS.has_feature("web"):g.get_viewport().get_texture().get_image().save_png("res://captures/trail-polish/"+view[0]+".png")
 g.photo_mode=false

static func run(g,failures: Array) -> void:
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.dismiss_request();g.side_panel.hide();GardenSculpt.restore(g,{})
 alpine_furniture(g,failures)
 var directions=g.world_root.get_node("GardenConnectingTrail")
 check(not directions.has_node("TrailDirections4"),failures,"Redundant Alpine Lookout/Moon Garden sign remains")
 for row in range(4):check(directions.has_node("TrailDirections%d"%row),failures,"Another trail sign was removed")
 await g.get_tree().physics_frame
 # The full board, rather than just its origin, must clear every approach.
 for index in range(10):
  var sign=g.area_roots[index].get_node("ActivitySign")
  for along in [-.9,-.45,0.,.45,.9]:
   var point: Vector3=sign.transform*Vector3(along,0,0)
   check(not GardenAreaTransitions.near_route(GardenAreaTransitions.route_data().approaches[index],Vector2(point.x,point.z),1.25),failures,"Activity sign intrudes into approach "+str(index)+" at "+str(point))
   if index==0:
    var world: Vector3=sign.global_transform*Vector3(along,0,0)
    check(not GardenAreaTransitions.near_route(GardenAreaTransitions.route_data().eastern_link,Vector2(world.x,world.z),1.35),failures,"Reedwater sign intrudes into the bluestone bend")
 # The alpine channel is clear of meadow grass; its banks retain tuft cover.
 if DisplayServer.get_name()!="headless":
  var bank_count=0
  for grass in g.get_tree().get_nodes_in_group("meadow_grass"):
   for i in range(grass.multimesh.instance_count):
    var t=grass.multimesh.get_instance_transform(i)
    if GardenConnectedLand.contains(t.origin):
     bank_count+=1
     check(GardenRavine.grass_allowed(t.origin),failures,"Grass in stream or crossing "+str(t.origin))
  check(bank_count>1200,failures,"Ravine upper banks have no meadow cover")
 var root=g.world_root.get_node("GardenConnectingTrail/Shared garden trail")
 # The northern end must form a bend on land, without the old edge spur.
 check(root.mesh.get_aabb().end.z<11.5,failures,"Bluestone trail still runs to the outer cliff")
 var c=GardenAreaCatalogue.center(2)
 var heights=[]
 for side in [-.68,0.,.68]:
  for along in [-.03,.03]:
   var p=c+Vector3(6.5+side,0,6.35+along)
   var ray=PhysicsRayQueryParameters3D.create(p+Vector3.UP*2,p+Vector3.DOWN*2)
   ray.exclude=[g.player.get_rid()]
   var hit=g.get_world_3d().direct_space_state.intersect_ray(ray)
   check(not hit.is_empty(),failures,"Terrace threshold has a missing corner")
   if not hit.is_empty():heights.append(hit.position.y)
 check(heights.size()==6 and heights.max()-heights.min()<.055,failures,"First terrace stair and approach differ across their width: "+str(heights))
 await preload("res://tests/water_surfaces.gd").run(g,failures)
 if "--water-review" in OS.get_cmdline_user_args():
  await preload("res://tests/water_review.gd").run(g);return
 if "--shadow-review" in OS.get_cmdline_user_args():
  await preload("res://tests/shadow_review.gd").run(g);return
 if "--trail-polish-review" in OS.get_cmdline_user_args():
  await capture(g);return
 var walker=preload("res://tests/walking.gd")
 var opening=3*sin(-8*.4)
 await walker.cross(g,GardenAreaCatalogue.center(3)+Vector3(opening,0,-6.5),GardenAreaCatalogue.center(3)+Vector3(opening,0,-9.3),failures,"Meadow fence opening")
 await walker.cross(g,GardenAreaCatalogue.center(3)+Vector3(opening,0,-9.3),GardenAreaCatalogue.center(3)+Vector3(opening,0,-6.5),failures,"Meadow fence return")
 # Walk the rear bend with the real player capsule, including both edges.
 var north: Array=GardenAreaTransitions.route_data().bridge_links[2]
 for side in [-.65,0.,.65]:
  await walker.cross(g,Vector3(68+side,0,-101.5),Vector3(68+side,0,-103.5),failures,"Rear trail into corner")
  for j in range(north.size()-1,maxi(0,north.size()-49),-8):
   var end=maxi(0,j-8)
   var a=Vector2(north[j][0],north[j][1]);var b=Vector2(north[end][0],north[end][1])
   var direction=(b-a).normalized();var offset=Vector2(-direction.y,direction.x)*side
   await walker.cross(g,Vector3(a.x+offset.x,0,a.y+offset.y),Vector3(b.x+offset.x,0,b.y+offset.y),failures,"Rear path corner lane "+str(side))
 await preload("res://tests/area_cohesion.gd").run(g,failures)
 await capture(g)
