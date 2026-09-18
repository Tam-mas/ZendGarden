extends RefCounted

static func run(g, failures: Array) -> void:
 if g.DAY_SECONDS!=600: failures.append("Day length is not ten minutes")
 g.unlocked_plots=maxi(4,g.unlocked_plots)
 var pos=GardenTerrain.point(Vector3(3,0,5.5))
 if g.bed_at(pos)>=0 or not g.can_plant(0,pos,0).is_empty(): failures.append("Outside-bed planting rejected dry ground")
 var plant=g.add_plant(0,pos,0)
 if g.can_plant(0,pos,0).is_empty(): failures.append("Outside-bed occupancy ignored")
 if g.can_plant(0,Vector3(8.5,0,5.9),0).is_empty(): failures.append("Bridge accepted planting")
 g.clean_paths.append("3:6")
 g.path_widths["3:6"]=1.55
 var patch=GardenGroundFinish.path(g,Vector3(3,0,6),1.55)
 for v in patch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
  if absf(v.y-GardenTerrain.point(v).y-.018)>.001: failures.append("Raked ground floats above slope"); break
 g.clock_time=.32
 g.update_lighting()
 var sunrise=g.sun.quaternion
 g.clock_time=.68
 g.update_lighting()
 if sunrise.is_equal_approx(g.sun.quaternion) or not g.sun.shadow_enabled: failures.append("Sun and shadows do not track day")
 g.side_panel.hide()
 g.player.position=GardenTerrain.point(Vector3(3,0,8))+Vector3(0,.1,0)
 g.yaw=0
 g.pitch=.55
 g.clock_time=.42
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 await g.get_tree().create_timer(.5).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/contoured-paths.png")
 g.pitch=-.45
 await g.get_tree().create_timer(.3).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/layered-clouds.png")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if not is_equal_approx(float(saved.path_widths["3:6"]),1.55): failures.append("Rake upgrade width not persisted")
 if not saved.plants.any(func(p): return absf(p.pos[0]-pos.x)<.01 and absf(p.pos[1]-pos.z)<.01): failures.append("Outside-bed plant missing from save")
