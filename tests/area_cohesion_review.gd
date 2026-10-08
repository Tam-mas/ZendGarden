extends RefCounted

static func run(g) -> int:
 GardenAreaProgression.unlock_review(g)
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.coins=2000;g.orders=[];g.unlocked_plants=range(g.catalogue.size())
 for index in range(10):GardenAreas.initialize(g,index)
 preload("res://tests/areas.gd").demo(g)
 GardenAreaAtlas.close(g);g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 g.camera.fov=55;g.view_fov=55
 var directory="res://captures/garden-cohesion"
 var trail_only="--trail-review" in OS.get_cmdline_user_args()
 var junction_only="--junction-review" in OS.get_cmdline_user_args()
 var two_paths="--two-paths-review" in OS.get_cmdline_user_args()
 if trail_only:directory="res://captures/bluestone-trails"
 if junction_only:directory="res://captures/fitted-path-junctions"
 if two_paths:directory="res://captures/fern-moon-paths"
 if "--forward-review" in OS.get_cmdline_user_args():directory+="/forward-plus"
 DirAccess.make_dir_recursive_absolute(directory)
 var conditions=[["morning",.30,Vector3.ZERO],["midday",.48,Vector3.ZERO],["dusk",.735,Vector3.ZERO],["rain",.43,Vector3(1,1,.35)]]
 if trail_only or junction_only or two_paths:conditions=[]
 for condition in conditions:
  for index in range(10):
   var info=GardenAreaCatalogue.entry(index);var center=GardenAreaCatalogue.center(index)
   g.clock_time=condition[1];g.climate.current=condition[2];g.climate.snow=0
   g.camera.global_position=center+Vector3(info.camera[0],info.camera[1],info.camera[2])
   g.camera.look_at(center+Vector3(info.focus[0],info.focus[1],info.focus[2]))
   g.climate.position=g.camera.global_position+Vector3(0,6,0)
   g.climate.rain_particles.emitting=condition[0]=="rain"
   g.climate.rain_particles.material_override.albedo_color.a=.45
   g.update_lighting();g.climate.apply(g)
   for root in g.area_roots:root.visible=true
   for other in range(10):GardenAreas.visual(g,other)
   g.animate_garden(.016,12)
   for settling in range(4):await g.get_tree().process_frame
   await RenderingServer.frame_post_draw
   var image=g.get_viewport().get_texture().get_image()
   image.save_png(directory+"/"+info.kind+"-"+condition[0]+".png")
   image.resize(720,450,Image.INTERPOLATE_LANCZOS)
   image.save_webp(directory+"/"+info.kind+"-"+condition[0]+".webp",true,.56)
   print("COHESION_VIEW: ",info.kind," ",condition[0])
 g.clock_time=.43;g.climate.current=Vector3.ZERO
 g.climate.rain_particles.emitting=false;g.update_lighting();g.climate.apply(g)
 var views=[
  ["connected-trail",Vector3(68,4.2,-6),Vector3(68,1.6,-48)],
  ["terrace-entrance",Vector3(67,3,-13),Vector3(63,1.5,-16)],
  ["glasshouse-entrance",Vector3(64,3.3,-62),Vector3(56,2.3,-66)],
  ["kitchen-entrance",Vector3(80,3.5,-36),Vector3(80,2,-43)],
  ["orchard-floor",Vector3(65,2.5,-40),Vector3(59,1.4,-46)]
 ]
 if trail_only:
  views.append(["eastern-link",Vector3(53,9.5,17),Vector3(57,1.5,9)])
  for index in range(10):
   var center=GardenAreaCatalogue.center(index)
   var middle=GardenAreaTransitions.approach(index,.5)
   var side=1 if index%2==0 else -1
   views.append([GardenAreaCatalogue.entry(index).kind+"-join",center+Vector3(side*14,8,14),center+Vector3(middle.x,1.4,middle.y)])
 if junction_only or two_paths:
  views=[
   ["pollinator-junction",Vector3(79.6,2.95,-15.6),Vector3(83.,1.45,-19.4)],
   ["glasshouse-threshold",Vector3(57.3,2.85,-63.6),Vector3(55.4,1.3,-67.4)],
   ["pollinator-junction-above",Vector3(80,7.4,-13.8),Vector3(81.4,1.4,-17.6)]
  ]
  views.append(["stream-entrance-above",Vector3(73,7.8,-64),Vector3(75.5,1.4,-68.5)])
  if two_paths:views=[]
  for index in range(10):
   if two_paths and index not in [1,9]:continue
   var center=GardenAreaCatalogue.center(index)
   var eye=GardenAreaTransitions.approach(index,.77)
   var end=GardenAreaTransitions.approach(index,1.)
   var direction=(end-eye).normalized()
   var camera=GardenTerrain.point(center+Vector3(eye.x,0,eye.y))+Vector3(0,1.8,0)
   var focus=GardenTerrain.point(center+Vector3(end.x+direction.x*1.1,0,end.y+direction.y*1.1))
   views.append([GardenAreaCatalogue.entry(index).kind+"-arrival-detail",camera,focus])
  if two_paths:
   # Keep the previous cameras too, so the exact reported defects can be
   # compared after reshaping their approaches.
   views.append(["fern_gully-original-angle",GardenTerrain.point(Vector3(79.83676,0,10.30316))+Vector3(0,1.8,0),GardenTerrain.point(Vector3(82.0555,0,7.4292))])
   views.append(["moon-original-angle",GardenTerrain.point(Vector3(76.05979,0,-88.85773))+Vector3(0,1.8,0),GardenTerrain.point(Vector3(78.3619,0,-90.6836))])
   views.append(["fern_gully-above",Vector3(79.3,8,12.5),Vector3(80.0,1.2,8.7)])
   views.append(["moon-above",Vector3(76,8,-86),Vector3(76.7,1.2,-89.8)])
 for view in views:
  g.camera.global_position=view[1];g.camera.look_at(view[2]);g.update_lighting();g.climate.apply(g)
  for settling in range(4):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  var image=g.get_viewport().get_texture().get_image();image.save_png(directory+"/"+view[0]+".png")
  image.resize(720,450,Image.INTERPOLATE_LANCZOS);image.save_webp(directory+"/"+view[0]+".webp",true,.56)
 if two_paths and "--forward-review" not in OS.get_cmdline_user_args():
  for index in [1,9]:await preload("res://tests/areas.gd").capture(g,index)
 if "--refresh-atlas" in OS.get_cmdline_user_args():
  for index in range(10):await preload("res://tests/areas.gd").capture(g,index)
 print("COHESION_REVIEW_RESULT: ",views.size()," transition details", "" if trail_only or junction_only or two_paths else " and 40 light/weather views")
 if two_paths:
  g.photo_mode=false
  var failures=[]
  await preload("res://tests/area_cohesion.gd").run(g,failures,[1,9])
  print("TWO_PATHS_WALK_RESULT: ",failures)
  if not failures.is_empty():return 1
 return 0
