extends RefCounted

static func press(index: int, pos: Vector2, down: bool = true) -> void:
 var event=InputEventScreenTouch.new()
 event.index=index
 var root=Engine.get_main_loop().root
 var scale=Vector2(root.size)/root.get_visible_rect().size
 event.position=pos*scale
 event.pressed=down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

static func drag(index: int, pos: Vector2, relative: Vector2) -> void:
 var event=InputEventScreenDrag.new()
 event.index=index
 var root=Engine.get_main_loop().root
 var scale=Vector2(root.size)/root.get_visible_rect().size
 event.position=pos*scale
 event.relative=relative*scale
 Input.parse_input_event(event)
 Input.flush_buffered_events()

static func run(g, failures: Array) -> void:
 var old_settings=g.settings.duplicate()
 var old_size=g.get_window().size
 g.settings.controls="touch"
 g.touch.configure()
 g.set_mode("walk")
 g.dismiss_request()
 if is_instance_valid(g.welcome): GardenExperience.finish(g)
 await g.get_tree().process_frame
 var touch=g.touch
 touch.layout()
 if not g.touch_active() or Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE: failures.append("Touch controls require mouse capture")
 press(1,touch.origin)
 await g.get_tree().process_frame
 drag(1,touch.origin+Vector2(0,-touch.radius/2),Vector2(0,-30))
 await g.get_tree().process_frame
 if not is_equal_approx(touch.stick.y,-.5): failures.append("Touch joystick lost analogue movement")
 var yaw=g.yaw
 press(2,Vector2(500,220))
 await g.get_tree().process_frame
 drag(2,Vector2(530,220),Vector2(30,0))
 await g.get_tree().process_frame
 if g.yaw==yaw or touch.stick_id!=1: failures.append("Simultaneous walking and looking failed")
 # A third finger can water while the first two still walk and look.
 g.mode="water"
 g.hover_valid=true
 g.hover_cell=g.planted[0].pos
 g.planted[0].water=0.0
 g.action_cooldown=0
 touch._process(0)
 press(3,touch.buttons.action.get_global_rect().get_center())
 if g.planted[0].water<=0 or touch.stick_id!=1 or touch.look_id!=2: failures.append("Three-finger watering interrupted walking or looking")
 press(3,touch.buttons.action.get_global_rect().get_center(),false)
 if touch.held: failures.append("Water button stayed held after release")
 press(2,Vector2(530,220),false)
 press(1,touch.origin,false)
 if touch.stick!=Vector2.ZERO or touch.look_id!=-1: failures.append("Released touch kept moving")
 g.open_sidebar("Settings")
 await g.get_tree().process_frame
 if g.gameplay_active() or touch.stick!=Vector2.ZERO: failures.append("Menu did not stop touch gameplay")
 touch.close_menu()
 if not g.gameplay_active(): failures.append("Closing touch menu did not resume gameplay")
 # Original action dispatch remains responsible for costs and game rules.
 g.mode="plant"
 g.selected=0
 g.hover_plot=0
 g.hover_cell=GardenTerrain.point(Vector3(-3.2,0,4))
 g.hover_valid=true
 g.action_cooldown=0
 var count=g.planted.size()
 touch.act()
 if g.planted.size()!=count+1: failures.append("Touch plant action failed")
 g.mode="remove"
 g.action_cooldown=0
 touch.act()
 if g.planted.size()!=count or touch.removed.is_empty(): failures.append("Touch lift did not offer undo")
 touch.undo_remove()
 if g.planted.size()!=count+1: failures.append("Touch undo did not restore the plant")
 g.notify_requests()
 await g.get_tree().process_frame
 if g.gameplay_active() or not g.request_popup.visible: failures.append("Neighbour note did not block touch movement")
 g.dismiss_request()
 touch.show_drawer("garden")
 if g.gameplay_active(): failures.append("Garden drawer did not block touch movement")
 touch.close_menu()
 # Test mobile aspect ratios without touching the real player's saved garden.
 for size in [Vector2i(844,390),Vector2i(390,844),Vector2i(1024,768)]:
  g.get_window().size=size
  await g.get_tree().process_frame
  touch.configure()
  touch.layout()
  g.open_sidebar("Settings")
  await g.get_tree().process_frame
  var bounds=Rect2(Vector2.ZERO,g.get_viewport().get_visible_rect().size)
  if not bounds.encloses(g.side_panel.get_global_rect()): failures.append("Touch menu overflow at "+str(size))
  touch.close_menu()
  await g.get_tree().process_frame
  for key in ["garden","tools","action","layer"]:
   if not bounds.encloses(touch.buttons[key].get_global_rect()): failures.append("Touch control overflow: "+key+str(size))
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/touch-%dx%d.png" % [size.x,size.y])
 # Saved overrides and handedness must work without relying on device detection.
 g.settings.left_handed=true
 g.settings.control_size=120
 touch.layout()
 if touch.origin.x<g.get_viewport().get_visible_rect().size.x/2: failures.append("Left-handed layout did not swap movement")
 touch.stick=Vector2.ONE
 touch.held=true
 touch._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 if touch.stick!=Vector2.ZERO or touch.held: failures.append("Focus loss left a touch gesture active")
 var saved=JSON.parse_string(JSON.stringify(g.settings))
 if saved.controls!="touch" or not saved.left_handed or saved.control_size!=120: failures.append("Touch preferences did not survive serialization")
 g.settings=old_settings
 g.get_window().size=old_size
 touch.configure()
 g.set_mode("walk")
 print("TOUCH_CONTROLS_RESULT: ",failures)
