extends RefCounted

static func key(code: int, echo: bool=false) -> void:
 var event=InputEventKey.new()
 event.physical_keycode=code;event.pressed=true;event.echo=echo
 Input.parse_input_event(event)
 Input.flush_buffered_events()
 event=InputEventKey.new();event.physical_keycode=code;event.pressed=false
 Input.parse_input_event(event)
 Input.flush_buffered_events()

static func capture(g, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await g.get_tree().create_timer(.2).timeout
 await RenderingServer.frame_post_draw
 var folder="res://captures/view-and-watering"+("/compat" if RenderingServer.get_current_rendering_method()=="gl_compatibility" else "")
 DirAccess.make_dir_recursive_absolute(folder)
 g.get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.touch.set_process(false)
 g.settings.controls="keyboard";g.touch.configure();g.touch.close_menu();g.dismiss_request()
 g.tutorial_state={"active":false}
 g.day_transition=false;g.photo_mode=false;g.upgrades.can=0
 g.set_mode("water")
 var center=GardenTerrain.point(Vector3.ZERO)
 var a=g.add_plant(0,center,0)
 var b=g.add_plant(1,GardenTerrain.point(center+Vector3(2,0,0)),0)
 a.water=0;b.water=0
 g.hover_valid=true;g.hover_cell=a.pos;g.action_cooldown=0
 preload("res://tests/gathering.gd").mouse(true)
 GardenTools.repeat_mouse(g)
 if a.water!=2 or b.water!=0:failures.append("Initial watering footprint incorrect")
 g.hover_cell=b.pos
 GardenTools.repeat_mouse(g)
 if b.water!=0:failures.append("Watering hold bypasses cooldown")
 g.action_cooldown=0;GardenTools.repeat_mouse(g)
 if b.water!=2 or GardenTools.growth_multiplier(g,b.pos,GardenTools.now(g))!=1.2:failures.append("Moving a held watering aim does not water new ground and plants")
 preload("res://tests/gathering.gd").mouse(false)
 b.water=0;g.action_cooldown=0;GardenTools.repeat_mouse(g)
 if b.water!=0:failures.append("Watering continues after release")
 # Starting a hold in an inactive state must never water behind its interface.
 g.hover_valid=false;preload("res://tests/gathering.gd").mouse(true);g.hover_valid=true
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;GardenTools.repeat_mouse(g)
 if b.water!=0:failures.append("Watering repeats in menus")
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;g.photo_mode=true;GardenTools.repeat_mouse(g)
 if b.water!=0:failures.append("Watering repeats in photo mode")
 g.photo_mode=false;g.day_transition=true;GardenTools.repeat_mouse(g)
 if b.water!=0:failures.append("Watering repeats during a day transition")
 g.day_transition=false;preload("res://tests/gathering.gd").mouse(false)
 var wider=g.add_plant(0,GardenTerrain.point(center+Vector3(1.3,0,0)),0)
 wider.water=0;b.water=0;g.upgrades.can=1;g.hover_cell=center;g.action_cooldown=0
 preload("res://tests/gathering.gd").mouse(true);GardenTools.repeat_mouse(g)
 if wider.water!=3.5 or b.water!=0:failures.append("Held watering ignores the purchased can footprint or duration")
 preload("res://tests/gathering.gd").mouse(false);g.upgrades.can=0
 # Real button / input dispatch, including the return key having no G action.
 g.clock_time=.45
 g.player.position=GardenTerrain.point(Vector3(0,0,5))+Vector3(0,.1,0)
 g.pitch=.12;g.yaw=0;g.update_camera(0);g.update_hud();g.update_hover()
 await capture(g,"normal")
 var day=g.day;var position=g.camera.position;var angle=g.camera.rotation
 g.view_button.pressed.emit()
 if not g.clear_view or g.ui.visible or g.touch.visible or g.held_tool.is_visible_in_tree() or g.grid_cursor.visible or g.area_cursor.visible or g.grid_root.visible:failures.append("Enjoy-view button leaves interface or tool visible")
 g.hover_valid=true;g.hover_cell=b.pos;g.action_cooldown=0
 g.perform_action();GardenTools.repeat_mouse(g)
 if b.water!=0:failures.append("Tools act while enjoying the view")
 # Advance actual game/UI updates while hidden; timed notes must stay hidden.
 var clock=g.clock_time
 g._process(.1);g.touch._process(.1)
 if not g.ui.visible and not g.held_tool.is_visible_in_tree() and not g.reticle.is_visible_in_tree() and g.clock_time>clock:pass
 else:failures.append("Game updates expose UI or stop the garden while enjoying the view")
 if g.camera.position.distance_to(position)>.001 or g.camera.rotation.distance_to(angle)>.001:failures.append("Enjoy view changes the camera")
 await capture(g,"enjoy-view")
 key(KEY_H,true)
 if not g.clear_view:failures.append("Key autorepeat exits enjoy view")
 key(KEY_G)
 if g.clear_view or not g.ui.visible or not g.tool_models.can.is_visible_in_tree() or g.day!=day or g.day_transition or g.mode!="water":failures.append("Return key changes the day/tool or fails to restore HUD")
 await capture(g,"returned")
 # Menu state also survives; Escape must only restore that existing menu.
 g.open_sidebar("Guide")
 var guide_button: Button
 for child in g.list_box.get_children():
  if child is Button and child.text.begins_with("Enjoy the view"):guide_button=child
 if guide_button==null:failures.append("Guide has no enjoy-view button")
 else:guide_button.pressed.emit()
 key(KEY_ESCAPE)
 if g.clear_view or not g.side_panel.visible or g.active_tab!="Guide" or Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE:failures.append("Enjoy view loses menu state on return")
 g.set_mode("water");g.update_camera(0);g.view_button.pressed.emit()
 preload("res://tests/gathering.gd").mouse(true)
 b.water=0;g.hover_valid=true;g.hover_cell=b.pos;g.action_cooldown=0
 GardenTools.repeat_mouse(g)
 if g.clear_view or b.water!=0:failures.append("Dismiss click waters through returned HUD")
 preload("res://tests/gathering.gd").mouse(false);GardenTools.repeat_mouse(g)
 # Touch players can enter from Garden and tap anywhere to return safely.
 g.settings.controls="touch";g.touch.configure();g.touch.show_drawer("garden")
 var touch_button: Button
 for child in g.touch.drawer.find_children("*","Button",true,false):
  if child.text=="Enjoy the view":touch_button=child
 if touch_button==null:failures.append("Touch Garden menu lacks enjoy-view button")
 else:touch_button.pressed.emit()
 g.touch._process(.1)
 if not g.clear_view or g.touch.visible:failures.append("Touch view keeps controls visible")
 var tap=InputEventScreenTouch.new();tap.index=11;tap.pressed=true;tap.position=Vector2(300,200)
 Input.parse_input_event(tap);Input.flush_buffered_events()
 if g.clear_view or not g.touch.visible or g.touch.held or not g.touch.finger_positions.is_empty():failures.append("Tap does not cleanly restore touch controls: view=%s visible=%s held=%s fingers=%s"%[g.clear_view,g.touch.visible,g.touch.held,g.touch.finger_positions])
 tap=InputEventScreenTouch.new();tap.index=11;tap.pressed=false
 Input.parse_input_event(tap);Input.flush_buffered_events()
 if not g.touch.view_return_fingers.is_empty():failures.append("Return finger suppression survives release")
 if b.water!=0:failures.append("Tap to return waters the garden")
 for id in [68,69,70,71,72,80]:
  if g.catalogue[id].category!="Grasses" or g.catalogue[id].layer!=(3 if id==80 else 2):failures.append("Bamboo category or saved layer changed incorrectly")
