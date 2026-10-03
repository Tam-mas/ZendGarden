extends RefCounted

static func press(index: int, pos: Vector2, down: bool = true, canceled: bool = false) -> void:
 var event=InputEventScreenTouch.new()
 event.index=index
 var root=Engine.get_main_loop().root
 var scale=Vector2(root.size)/root.get_visible_rect().size
 event.position=pos*scale
 event.pressed=down
 event.canceled=canceled
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
 var was_processing=g.is_processing()
 g.set_process(false)
 var old_settings=g.settings.duplicate()
 var old_size=g.get_window().size
 g.settings.controls="touch"
 g.touch.configure()
 g.set_mode("walk")
 g.dismiss_request()
 if is_instance_valid(g.welcome): GardenExperience.finish(g)
 for frame in range(5):await g.get_tree().process_frame
 # macOS can deliver the initial focus/resize event after its first drawn frames.
 await g.get_tree().create_timer(.5).timeout
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
 # Regression: the web backend's relative delta can come from another finger.
 # Alternate nonsequential IDs and wildly wrong relative values; only absolute
 # displacement of the looking finger may affect the camera.
 var look_start=Vector2(500,220)
 var previous_pitch=g.pitch
 var previous_yaw=g.yaw
 press(0,touch.origin)
 press(37,look_start)
 drag(0,touch.origin+Vector2(0,-20),Vector2(900,-900))
 drag(37,look_start+Vector2(12,0),Vector2(-700,-700))
 if not is_equal_approx(g.pitch,previous_pitch): failures.append("Other finger's relative delta changed camera pitch")
 var css_scale=touch.display_size/g.get_viewport().get_visible_rect().size
 var expected_yaw=previous_yaw-12*css_scale.x*1.7*.0022*float(g.settings.sensitivity)*(-1 if g.settings.invert_x else 1)
 if not is_equal_approx(g.yaw,expected_yaw): failures.append("Look did not follow its own finger position: actual %s expected %s display %s viewport %s"%[g.yaw,expected_yaw,touch.display_size,g.get_viewport().get_visible_rect().size])
 press(0,touch.origin,false)
 drag(37,look_start+Vector2(20,0),Vector2(0,800))
 if not is_equal_approx(g.pitch,previous_pitch) or touch.look_id!=37: failures.append("Lifting the joystick finger disturbed looking")
 press(37,look_start,false,true)
 if touch.look_id!=-1: failures.append("Canceled look finger retained ownership")
 # ID reuse starts at the new position; holding the joystick must not steal look.
 press(37,Vector2(600,180))
 press(0,touch.origin)
 press(42,touch.origin+Vector2(5,5))
 var before_reuse=g.pitch
 drag(37,Vector2(610,180),Vector2(900,900))
 if not is_equal_approx(g.pitch,before_reuse) or touch.stick_id!=0: failures.append("Reused touch ID jumped or stole the joystick")
 press(42,touch.origin,false)
 press(37,Vector2(610,180),false)
 press(0,touch.origin,false,true)
 if touch.stick!=Vector2.ZERO or not touch.finger_positions.is_empty(): failures.append("Canceled touch left movement or positions behind")
 # Disabled action buttons own the touch too, rather than turning into a look.
 g.hover_valid=false
 touch._process(0)
 var disabled_pos=touch.buttons.action.get_global_rect().get_center()
 press(14,disabled_pos)
 drag(14,disabled_pos+Vector2(0,20),Vector2(0,20))
 if touch.look_id!=-1: failures.append("Disabled action button became camera look")
 press(14,disabled_pos,false)
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
 # Exercise layouts across short phones, portrait phones and large tablets.
 for size in [Vector2i(844,390),Vector2i(390,844),Vector2i(320,568),Vector2i(640,360),Vector2i(1024,768),Vector2i(768,1024),Vector2i(1366,1024)]:
  g.get_window().size=size
  await g.get_tree().process_frame
  touch.configure()
  for frame in range(5):await g.get_tree().process_frame
  touch.layout()
  g.open_sidebar("Settings")
  await g.get_tree().process_frame
  var bounds=Rect2(Vector2.ZERO,g.get_viewport().get_visible_rect().size)
  if not bounds.encloses(g.side_panel.get_global_rect()): failures.append("Touch menu overflow at "+str(size))
  touch.close_menu()
  g.toast_time=0
  for handed in [false,true]:
   for control_size in [80,100,120]:
    g.settings.left_handed=handed
    g.settings.control_size=control_size
    touch.layout()
    for mode in ["walk","water","plant","build","prune","harvest","hoe","move","remove","photo"]:
     g.mode=mode
     g.photo_mode=mode=="photo"
     touch.removed={"plant":true} if mode=="remove" else {}
     touch.undo_time=12 if mode=="remove" else 0
     touch._process(0)
     await g.get_tree().process_frame
     var controls: Array=[touch.stick_base,touch.status_panel,touch.context_panel]
     for key in touch.buttons:
      var button=touch.buttons[key]
      if button.visible:
       controls.append(button)
       if button.size.x<44 or button.size.y<44: failures.append("Small touch target: "+key+str(size))
     for i in range(controls.size()):
      var rect=controls[i].get_global_rect()
      if rect.has_point(bounds.size/2): failures.append("HUD covers aiming point at "+str(size)+" "+mode)
      if not bounds.encloses(rect): failures.append("HUD overflow at "+str(size)+" "+mode+" "+controls[i].name+" rect "+str(rect)+" viewport "+str(bounds)+" last "+str(touch.last_size)+" display "+str(touch.display_size))
      for j in range(i):
       if rect.intersects(controls[j].get_global_rect()): failures.append("HUD overlap at "+str(size)+" "+mode+" "+controls[i].name+" / "+controls[j].name)
  g.settings.left_handed=false
  g.settings.control_size=100
  g.mode="water"
  g.photo_mode=false
  touch.layout()
  touch._process(0)
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/touch-%dx%d.png" % [size.x,size.y])
  if size==Vector2i(390,844):
   touch.show_drawer("tools")
   await g.get_tree().process_frame
   await RenderingServer.frame_post_draw
   g.get_viewport().get_texture().get_image().save_png("res://captures/touch-tools-390x844.png")
   touch.close_menu()
 # Resize while fingers are held: old coordinates must not survive rotation.
 press(0,touch.origin)
 press(8,Vector2(500,200))
 touch.layout()
 var rotation_pitch=g.pitch
 drag(8,Vector2(700,100),Vector2(200,-100))
 if touch.stick_id!=-1 or touch.look_id!=-1 or g.pitch!=rotation_pitch: failures.append("Viewport resize retained an old touch gesture")
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
 g.set_process(was_processing)
 print("TOUCH_CONTROLS_RESULT: ",failures)
