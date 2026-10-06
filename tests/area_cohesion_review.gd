extends RefCounted

static func run(g) -> void:
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.coins=2000;g.orders=[];g.unlocked_plants=range(g.catalogue.size())
 for index in range(10):GardenAreas.initialize(g,index)
 preload("res://tests/areas.gd").demo(g)
 GardenAreaAtlas.close(g);g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 g.camera.fov=55;g.view_fov=55
 var directory="res://captures/garden-cohesion"
 if "--forward-review" in OS.get_cmdline_user_args():directory+="/forward-plus"
 DirAccess.make_dir_recursive_absolute(directory)
 var conditions=[["morning",.30,Vector3.ZERO],["midday",.48,Vector3.ZERO],["dusk",.735,Vector3.ZERO],["rain",.43,Vector3(1,1,.35)]]
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
 for view in views:
  g.camera.global_position=view[1];g.camera.look_at(view[2]);g.update_lighting();g.climate.apply(g)
  for settling in range(4):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  var image=g.get_viewport().get_texture().get_image();image.save_png(directory+"/"+view[0]+".png")
  image.resize(720,450,Image.INTERPOLATE_LANCZOS);image.save_webp(directory+"/"+view[0]+".webp",true,.56)
 print("COHESION_REVIEW_RESULT: 40 light/weather views and five transition details")
