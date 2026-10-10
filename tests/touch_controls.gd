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

static func capture(g, filename: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("res://captures/"+filename)

static func run(g, failures: Array) -> void:
 var was_processing=g.is_processing()
 g.set_process(false)
 var old_settings=g.settings.duplicate()
 var old_size=g.get_window().size
 g.get_window().size=Vector2i(1280,800)
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
 # Habitat starter trees now exist on day one too; water an original-garden
 # plant so this input test does not try to bypass an area milestone.
 var watered=g.planted.filter(func(plant):return int(plant.plot)==0)[0]
 g.hover_plot=0
 g.hover_cell=watered.pos
 watered.water=0.0
 g.action_cooldown=0
 touch._process(0)
 press(3,touch.buttons.action.get_global_rect().get_center())
 if watered.water<=0 or touch.stick_id!=1 or touch.look_id!=2: failures.append("Three-finger watering interrupted walking or looking")
 press(3,touch.buttons.action.get_global_rect().get_center(),false)
 if touch.held: failures.append("Water button stayed held after release")
 press(2,Vector2(530,220),false)
 press(1,touch.origin,false)
 if touch.stick!=Vector2.ZERO or touch.look_id!=-1: failures.append("Released touch kept moving")
 # Two thumbs can walk, water and turn. Dragging the action owns the look only
 # for continuous tools, and cancellation must stop both the tool and camera.
 var action_pos=touch.buttons.action.get_global_rect().get_center()
 press(11,touch.origin)
 press(12,action_pos)
 var action_yaw=g.yaw
 drag(12,action_pos+Vector2(20,0),Vector2(-900,900))
 if not touch.held or touch.stick_id!=11 or g.yaw==action_yaw:failures.append("Two-thumb tool-and-look gesture failed")
 press(12,action_pos,false,true)
 var released_yaw=g.yaw
 drag(12,action_pos+Vector2(40,0),Vector2(20,0))
 if touch.held or touch.action_id!=-1 or g.yaw!=released_yaw:failures.append("Canceled action kept working or looking")
 press(11,touch.origin,false)
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
 # Tablet landscapes, portrait and square unfolded screens; small layouts keep
 # a usable fallback without determining the tablet design.
 for size in [Vector2i(844,390),Vector2i(390,844),Vector2i(320,568),Vector2i(640,360),Vector2i(1024,768),Vector2i(768,1024),Vector2i(1366,1024),Vector2i(800,740),Vector2i(740,800),Vector2i(700,560)]:
  g.get_window().size=size
  await g.get_tree().process_frame
  touch.configure()
  for frame in range(5):await g.get_tree().process_frame
  touch.layout()
  g.open_sidebar("Settings")
  await g.get_tree().process_frame
  var bounds=Rect2(Vector2.ZERO,g.get_viewport().get_visible_rect().size)
  if not bounds.encloses(g.side_panel.get_global_rect()): failures.append("Touch menu overflow at %s: panel %s, viewport %s, minimum %s"%[size,g.side_panel.get_global_rect(),bounds,g.side_panel.get_combined_minimum_size()])
  touch.close_menu()
  if touch.tablet_layout:
   for page in ["Shop","Orders","Guide","Garden"]:
    touch.open_menu(page)
    await g.get_tree().process_frame
    if not bounds.encloses(g.side_panel.get_global_rect()):failures.append("Touch "+page+" menu overflow at "+str(size))
   touch.open_menu("Seeds")
   await g.get_tree().process_frame
   await g.get_tree().process_frame
   var cards=g.list_box.get_node("PlantCards")
   var previous_seed=g.selected
   g.list_box.get_parent().scroll_vertical=180
   await g.get_tree().process_frame
   var browsing_scroll=g.list_box.get_parent().scroll_vertical
   cards.get_child(0).pressed.emit()
   await g.get_tree().process_frame
   if g.active_tab!="Seed details" or not g.side_panel.visible or g.selected!=previous_seed:failures.append("Touch seed card skipped its details page")
   touch.back_to_seeds()
   await g.get_tree().process_frame
   await g.get_tree().process_frame
   if g.list_box.get_parent().scroll_vertical!=browsing_scroll:failures.append("Returning from plant details lost collection scroll")
   g.list_box.get_node("PlantCards").get_child(0).pressed.emit()
   await g.get_tree().process_frame
   await capture(g,"touch-details-%dx%d.png"%[size.x,size.y])
   var choose=g.list_box.get_node("PlantThisSeed")
   if choose.disabled:failures.append("Initial seed cannot be selected from details")
   else:choose.pressed.emit()
   if g.mode!="plant" or g.side_panel.visible:failures.append("Plant this did not return to gardening")
   # Discrete actions never become a camera drag or a repeating held tool.
   g.hover_valid=true
   touch._process(0)
   var pos=touch.buttons.action.get_global_rect().get_center()
   var discrete_yaw=g.yaw
   press(71,pos)
   drag(71,pos+Vector2(18,0),Vector2(18,0))
   if touch.held or g.yaw!=discrete_yaw:failures.append("Planting became a continuous camera gesture")
   press(71,pos,false)
   touch.open_menu("Seeds")
   await g.get_tree().process_frame
   if g.list_box.get_node("PlantCards").columns<2:failures.append("Touch collection lost its card grid")
   await capture(g,"touch-seeds-%dx%d.png"%[size.x,size.y])
   touch.close_menu()
   touch.show_drawer("tools")
   await g.get_tree().process_frame
   if touch.drawer.size.y>=bounds.size.y*.7:failures.append("Tool tray became a full-height menu")
   await capture(g,"touch-tools-%dx%d.png"%[size.x,size.y])
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
     var controls: Array=[touch.stick_base,touch.status_panel]
     if touch.context_panel.visible:controls.append(touch.context_panel)
     if touch.look_base.visible:controls.append(touch.look_base)
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
  await capture(g,"touch-%dx%d.png" % [size.x,size.y])
  if size==Vector2i(390,844):
   touch.show_drawer("tools")
   await g.get_tree().process_frame
   await capture(g,"touch-tools-390x844.png")
   touch.close_menu()
  if touch.tablet_layout:
   for handed in [false,true]:
    g.settings.left_handed=handed
    g.settings.touch_inset=100
    g.settings.touch_height=120
    g.settings.control_size=120
    touch.layout()
    for mode in ["build","prune","hoe","remove"]:
     g.mode=mode
     touch._process(0)
     await g.get_tree().process_frame
     var extreme_controls=[touch.stick_base,touch.look_base,touch.context_panel]
     for control in touch.buttons.values():
      if control.visible:extreme_controls.append(control)
     for i in range(extreme_controls.size()):
      var rect=extreme_controls[i].get_global_rect()
      if not bounds.encloses(rect) or rect.has_point(bounds.size/2):failures.append("Adjusted controls overflow or cover aim at "+str(size))
      for j in range(i):
       if rect.intersects(extreme_controls[j].get_global_rect()):failures.append("Adjusted controls overlap at "+str(size)+" "+mode)
   g.settings.touch_inset=0
   g.settings.touch_height=0
   g.settings.control_size=100
   g.settings.left_handed=false
 # Font metrics differ between macOS, Linux and browsers. Long settings labels
 # must not determine the width of the touch panel, even with a larger fallback.
 var normal_font=g.menu_theme.default_font
 g.menu_theme.default_font=ThemeDB.fallback_font
 for kind in ["CheckButton","OptionButton"]:g.menu_theme.set_font_size("font_size",kind,24)
 for size in [Vector2i(320,568),Vector2i(700,560),Vector2i(1024,768)]:
  g.get_window().size=size
  await g.get_tree().process_frame
  touch.configure()
  touch.open_menu("Settings")
  for frame in range(3):await g.get_tree().process_frame
  var bounds=Rect2(Vector2.ZERO,g.get_viewport().get_visible_rect().size)
  if not bounds.encloses(g.side_panel.get_global_rect()):failures.append("Fallback-font settings overflow at %s: %s"%[size,g.side_panel.get_global_rect()])
  touch.close_menu()
 for kind in ["CheckButton","OptionButton"]:g.menu_theme.clear_font_size("font_size",kind)
 g.menu_theme.default_font=normal_font
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
 g.settings.touch_inset=100
 g.settings.touch_height=120
 touch.layout()
 if touch.origin.x<g.get_viewport().get_visible_rect().size.x/2: failures.append("Left-handed layout did not swap movement")
 touch.stick=Vector2.ONE
 touch.held=true
 touch._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 if touch.stick!=Vector2.ZERO or touch.held: failures.append("Focus loss left a touch gesture active")
 var saved=JSON.parse_string(JSON.stringify(g.settings))
 if saved.controls!="touch" or not saved.left_handed or saved.control_size!=120 or saved.touch_inset!=100 or saved.touch_height!=120: failures.append("Touch preferences did not survive serialization")
 if not GardenSaveFormat.valid({"version":2,"plants":[],"settings":saved},g.catalogue.size(),[]):failures.append("Save validation rejected touch position preferences")
 g.settings=old_settings
 g.get_window().size=old_size
 touch.configure()
 g.set_mode("walk")
 g.set_process(was_processing)
 if DisplayServer.get_name()=="headless":
  # Fixed-FPS headless checks can finish before the audio thread releases its
  # looping WAV playbacks. Stop those test-only voices before shutting down.
  for voice in g.ambient.players.values():
   voice.stop()
   voice.stream=null
  await g.get_tree().process_frame
  OS.delay_msec(30)
 print("TOUCH_CONTROLS_RESULT: ",failures)
