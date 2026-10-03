extends RefCounted

static func run(g,failures: Array) -> void:
 var before={"bed_surfaces":g.bed_surfaces.duplicate(true),"owned_surfaces":g.owned_surfaces.duplicate()}
 var coins=g.coins
 var unlocked=g.unlocked_plots
 var controls=g.settings.controls
 var previous_player=g.player.position
 var previous_pitch=g.pitch
 var previous_yaw=g.yaw
 var previous_clock=g.clock_time
 var previous_plot=g.current_plot
 g.unlocked_plots=maxi(2,unlocked)
 GardenBedSurfaces.restore(g,{})
 if g.owned_surfaces!=["soil"] or not g.bed_surfaces.is_empty():failures.append("Old saves do not default to garden soil")
 g.coins=0
 if GardenBedSurfaces.apply(g,0,"sand") or "sand" in g.owned_surfaces:failures.append("Unaffordable bed finish was purchased")
 g.coins=500
 var plants=g.planted.size()
 var player=g.player.position
 if GardenBedSurfaces.apply(g,g.unlocked_plots,"sand") or g.coins!=500:failures.append("A locked bed accepted a surface")
 for item in GardenBedSurfaces.FINISHES:
  if not GardenBedSurfaces.apply(g,0,item.id):failures.append("Could not apply bed finish: "+item.id)
  if item.id!="soil" and not g.bed_surface_nodes.has("0"):failures.append("Bed finish lacks real surface geometry: "+item.id)
 var paid=g.coins
 if not GardenBedSurfaces.apply(g,1,"sand") or g.coins!=paid:failures.append("Owned finish charged again in another bed")
 if g.planted.size()!=plants or g.player.position!=player:failures.append("Bed finish moved plants or player")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 GardenBedSurfaces.restore(g,saved)
 if g.bed_surfaces.get("1")!="sand" or "gravel" not in g.owned_surfaces:failures.append("Saved surfaces or purchases were lost")
 GardenBedSurfaces.rebuild(g)
 # Verify the finish uses the same vertices as sculpted soil, including edges.
 var edited=GardenTerrain.offsets.duplicate()
 GardenTerrain.offsets["0:0"]=.4
 GardenSculpt.rebuild(g,Vector3.ZERO)
 var patch: MeshInstance3D=g.bed_surface_nodes["0"]
 var bounds=patch.get_aabb()
 if absf(bounds.size.x-9.5)>.01 or absf(bounds.size.z-9.5)>.01:failures.append("Surface does not cover the entire original bed")
 var near=INF
 for v in patch.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
  if absf(v.x)<.01 and absf(v.z)<.01:near=minf(near,absf(v.y-GardenTerrain.point(v).y-.004))
 if near>.001:failures.append("Bed finish did not follow a terrain edit")
 GardenTerrain.offsets=edited
 GardenSculpt.rebuild(g,Vector3.ZERO)
 g.surface_shop_plot=1
 g.current_plot=1
 g.open_sidebar("Shop")
 if g.surface_shop_plot!=1:failures.append("Shop did not select the nearby bed")
 g.surface_shop_plot=1
 g.refresh_sidebar()
 if not g.list_box.has_node("SurfaceBedChoice") or not g.list_box.has_node("Surface_gravel"):failures.append("Surface controls missing from real Shop")
 for dimensions in [Vector2i(1280,800),Vector2i(390,844)]:
  g.get_window().size=dimensions
  g.settings.controls="touch" if dimensions.x<600 else "keyboard"
  g.touch.configure()
  g.refresh_ui()
  for frame in range(6):
   g.update_hud()
   if g.touch_active():g.touch.layout()
   await g.get_tree().process_frame
  g.get_viewport().get_texture().get_image().save_png("res://captures/bed-shop-%dx%d.png"%[dimensions.x,dimensions.y])
 g.get_window().size=Vector2i(1280,800)
 g.settings.controls=controls
 g.touch.configure()
 g.side_panel.hide()
 g.ui.hide()
 g.player.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.1,0)
 g.pitch=.55;g.yaw=0;g.clock_time=.42
 for item in GardenBedSurfaces.FINISHES:
  GardenBedSurfaces.apply(g,0,item.id)
  await g.get_tree().create_timer(.1).timeout
  g.get_viewport().get_texture().get_image().save_png("res://captures/bed-"+item.id+".png")
 g.ui.show()
 if not GardenBedSurfaces.apply(g,0,"soil") or g.bed_surface_nodes.has("0"):failures.append("Original soil could not be restored freely")
 GardenBedSurfaces.restore(g,{"owned_surfaces":["missing","sand"],"bed_surfaces":{"-1":"sand","wrong":"sand","0":"missing","999":"sand"}})
 if not g.bed_surfaces.is_empty() or "missing" in g.owned_surfaces:failures.append("Invalid saved finish or bed ID was accepted")
 for node in g.bed_surface_nodes.values():
  if is_instance_valid(node):node.free()
 g.bed_surface_nodes.clear()
 g.unlocked_plots=unlocked
 GardenBedSurfaces.restore(g,before)
 GardenBedSurfaces.rebuild(g)
 g.coins=coins
 g.player.position=previous_player
 g.pitch=previous_pitch;g.yaw=previous_yaw;g.clock_time=previous_clock
 g.current_plot=previous_plot
