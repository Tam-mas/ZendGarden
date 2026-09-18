extends RefCounted

static func run(g, failures: Array) -> void:
 var validation=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/landscape_validation.json"))
 if validation.minimum_boundary_height<=validation.lake_level+20:
  failures.append("Lake reaches unfinished terrain boundary")
 if validation.southern_forest_sections<10:
  failures.append("Southern headland lacks woodland")
 for name in ["ContourLake","ShorelineRocks","OuterMountainRidges"]:
  if not is_instance_valid(g.world_root.find_child(name,true,false)):
   failures.append("Missing shoreline scenery: "+name)
 g.side_panel.hide()
 g.day=13
 g.clock_time=.44
 g.climate.restore({"values":[0,0,0],"target":"Clear","snow":0,"slot":36})
 g.player.position=GardenTerrain.point(Vector3(0,0,8))+Vector3(0,.1,0)
 g.pitch=.15
 for view in [["south",PI],["south-west",PI*.7],["south-east",-PI*.7],["north",0.0]]:
  g.yaw=view[1]
  await g.get_tree().create_timer(.5).timeout
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/shoreline-"+view[0]+".png")
