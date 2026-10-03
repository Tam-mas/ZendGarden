extends RefCounted

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.settings.reduced_motion=true
 g.settings.updates_seen=GardenUpdates.CURRENT_VERSION
 var old_orders=g.orders.duplicate(true)
 GardenTutorial.start(g)
 g.choose_plant(2)
 g.hover_cell=g.snap_to_bed(Vector3(3,0,3),0,1)
 g.hover_plot=0;g.hover_valid=true;g.action_cooldown=0
 g.perform_action()
 var p=GardenTutorial.flower(g)
 if p.is_empty() or g.tutorial_state.step!=1:failures.append("Actual planting did not start watering lesson")
 if p.is_empty():return
 g.set_mode("water")
 g.hover_cell=p.pos;g.hover_valid=true;g.action_cooldown=0
 g.perform_action()
 if g.tutorial_state.step!=2:failures.append("Watering the welcome flower did not advance")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if saved.tutorial.step!=2 or not saved.tutorial.active:failures.append("Welcome progress did not persist")
 g.tutorial_state=saved.tutorial
 g.next_day()
 if g.tutorial_state.step!=3 or p.age<g.catalogue[p.id].days:failures.append("Welcome morning did not blossom")
 g.set_mode("harvest")
 g.hover_cell=p.pos;g.hover_valid=true;g.action_cooldown=0
 g.perform_action()
 if g.tutorial_state.step!=4:failures.append("Gather did not open delivery lesson")
 var idx=-1
 for i in range(g.orders.size()):
  if g.orders[i].get("welcome",false):idx=i
 if idx<0:failures.append("No welcome request")
 else:
  var petals=g.coins
  g.fulfill_order(idx)
  if g.tutorial_state.active or not g.tutorial_state.completed or g.coins!=petals+12:failures.append("Welcome delivery did not complete or reward correctly")
  saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
  if not saved.orders[idx].pending:failures.append("Delivered welcome order could be repeated after reload")
 for i in range(old_orders.size()):
  if g.orders[i]!=old_orders[i]:failures.append("Welcome replaced an ordinary neighbour order")
 g.day+=3
 g.replenish_orders()
 GardenTutorial.start(g)
 GardenTutorial.finish(g,false)
 if g.tutorial_state.active or is_instance_valid(g.tutorial_panel):failures.append("Skip left the tutorial running")
 GardenTutorial.start(g)
 for size in [Vector2i(1280,800),Vector2i(320,568),Vector2i(844,390)]:
  g.get_window().size=size
  g.settings.controls="touch" if size.x!=1280 else "keyboard"
  g.touch.configure()
  await g.get_tree().create_timer(.3).timeout
  GardenTutorial.layout(g)
  await g.get_tree().process_frame
  var rect=g.tutorial_panel.get_global_rect()
  if rect.end.x>size.x or rect.end.y>size.y:failures.append("Welcome card outside screen: "+str(size))
  if g.touch_active():
   if g.touch.context_panel.visible and rect.intersects(g.touch.context_panel.get_global_rect()):failures.append("Touch readout covers the welcome card")
   if rect.has_point(g.get_viewport().get_visible_rect().size*.5):failures.append("Welcome card obscures the aiming point")
   if rect.intersects(g.touch.stick_base.get_global_rect()):failures.append("Welcome card obscures walking controls")
   await RenderingServer.frame_post_draw
   g.get_viewport().get_texture().get_image().save_png("res://captures/welcome-touch-%d.png"%size.x)
   var button=g.tutorial_panel.get_child(0).get_child(3).get_child(0)
   preload("res://tests/touch_controls.gd").press(20,button.get_global_rect().get_center())
   await g.get_tree().process_frame
   if not g.side_panel.visible or g.active_tab!="Seeds":failures.append("Touch lesson button did not open Seeds")
   preload("res://tests/touch_controls.gd").press(20,button.get_global_rect().get_center(),false)
   g.touch.close_menu()
 g.get_window().size=Vector2i(1280,800)
 await g.get_tree().create_timer(.6).timeout
 g.settings.controls="keyboard";g.touch.configure()
 await g.get_tree().create_timer(.4).timeout
 GardenTutorial.layout(g)
 await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("res://captures/welcome-interactive.png")
 GardenTutorial.finish(g,false)
 g.set_process(true)
