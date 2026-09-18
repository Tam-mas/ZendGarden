extends RefCounted

static func all_buttons(node: Node) -> Array:
 var found: Array=[]
 if node is Button: found.append(node)
 for child in node.get_children(): found.append_array(all_buttons(child))
 return found

static func run(g, failures: Array) -> void:
 # Build and rotate both directions, then rotate an existing ornament in place.
 g.day=13
 g.clock_time=.4
 g.unlocked_plots=4
 g.coins=1000
 g.selected_furniture=1
 g.set_mode("build")
 g.hover_valid=true
 g.hover_plot=0
 g.hover_cell=GardenTerrain.point(Vector3(5,0,2))
 g.action_cooldown=0
 g.rotate_structure(1)
 if not is_equal_approx(g.structure_rotation,-PI/12): failures.append("Clockwise rotation has wrong direction")
 g.rotate_structure(-1)
 if not is_zero_approx(g.structure_rotation): failures.append("Anticlockwise rotation did not reverse")
 g.rotate_structure(1)
 g.perform_action()
 var object=g.objects.back()
 if not is_equal_approx(object.node.rotation.y,-PI/12): failures.append("Placed structure lost preview rotation")
 g.set_mode("move")
 g.action_cooldown=0
 g.perform_action()
 if g.moved_object<0: failures.append("Existing structure could not be picked up")
 g.rotate_structure(1)
 g.perform_action()
 if not is_equal_approx(object.node.rotation.y,-PI/6): failures.append("Existing structure could not rotate in place")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if not is_equal_approx(float(saved.objects.back().rotation),-PI/6): failures.append("Structure rotation missing from save")
 g.add_object("bench",GardenTerrain.point(Vector3(5,0,4)),45,false,float(saved.objects.back().rotation))
 if not is_equal_approx(g.objects.back().node.rotation.y,object.node.rotation.y): failures.append("Restored structure rotation differs")
 # Menus use a two-column catalogue with a portrait and actionable card for every species.
 g.set_mode("walk")
 g.unlocked_plants=range(60)
 g.active_tab="Seeds"
 g.category="Trees"
 g.selected=28
 g.player.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.1,0)
 g.yaw=0
 g.pitch=.05
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.side_panel.show()
 g.toast_time=0
 g.refresh_ui()
 var cards=g.list_box.get_node("PlantCards")
 if cards.columns!=2 or cards.get_child_count()!=8: failures.append("Tree catalogue is not a two-column grid")
 for id in range(60):
  if not ResourceLoader.exists("res://assets/ui/plants/%02d.png" % id): failures.append("Missing plant thumbnail "+str(id))
 for button in all_buttons(g.hud_top):
  if button.text in ["Seeds","Shop","Orders","Guide","Next morning  G","Photo  P"]: failures.append("Duplicate header button remains")
 await g.get_tree().create_timer(.4).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/parchment-plant-menu.png")
 # Click the actual card to exercise unlocking/selection and pointer capture.
 cards.get_child(1).pressed.emit()
 if g.selected!=29 or Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED: failures.append("Plant card selection failed")
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.active_tab="Guide"
 g.side_panel.show()
 g.refresh_ui()
 await g.get_tree().create_timer(.3).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/parchment-guide.png")
 # Replay G through the real input path, including repeated presses during the transition.
 g.set_mode("walk")
 g.clock_time=.40
 g.climate.restore({"values":[0,0,0],"target":"Clear","snow":0,"slot":(g.day-1)*3+1})
 var original_day=g.day
 var original_coins=g.coins
 var event=InputEventKey.new()
 event.pressed=true
 event.physical_keycode=KEY_G
 g._unhandled_input(event)
 g._unhandled_input(event)
 if not g.day_transition or g.day!=original_day: failures.append("G did not start an animated transition")
 var screenshots={"sunset":false,"stars":false,"sunrise":false}
 var night_energy=1.0
 var elapsed=0.0
 while g.day_transition and elapsed<9:
  await g.get_tree().process_frame
  elapsed+=g.get_process_delta_time()
  var stage=""
  if g.day==original_day and g.clock_time>.735 and g.clock_time<.77: stage="sunset"
  if g.day==original_day and g.clock_time>.90: stage="stars"; night_energy=g.sun.light_energy
  if g.day>original_day and g.clock_time>.25: stage="sunrise"
  if not stage.is_empty() and not screenshots[stage]:
   screenshots[stage]=true
   await RenderingServer.frame_post_draw
   g.get_viewport().get_texture().get_image().save_png("res://captures/time-lapse-"+stage+".png")
 if g.day_transition: failures.append("Day transition never completed")
 if g.day!=original_day+1 or g.coins!=original_coins: failures.append("Repeated G granted multiple dawn rewards")
 if absf(g.clock_time-.30)>.02: failures.append("Day skip did not finish at sunrise")
 if night_energy>=g.sun.light_energy: failures.append("Night and dawn lighting did not transition")
 for key in screenshots:
  if not screenshots[key]: failures.append("Missing transition phase "+key)
 g.set_mode("walk")
