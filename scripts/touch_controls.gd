class_name GardenTouch
extends CanvasLayer

# Touch gestures own their finger IDs so walking, looking and actions can coexist.
var g
var enabled=false
var detected=false
var stick=Vector2.ZERO
var stick_id=-1
var look_id=-1
var action_id=-1
var origin=Vector2.ZERO
var radius=62.0
var held=false
var repeat_time=0.0
var hud: Control
var stick_base: Panel
var stick_knob: Panel
var buttons: Dictionary={}
var drawer: PanelContainer
var close_button: Button
var last_size=Vector2.ZERO
var window_size=Vector2i.ZERO
var removed: Dictionary={}
var undo_time=0.0
var graphics_applied=""

func setup(game) -> void:
 g=game
 layer=8
 detected=DisplayServer.is_touchscreen_available() or OS.has_feature("web_ios") or OS.has_feature("web_android")
 if OS.has_feature("web"):
  var browser=JavaScriptBridge.get_interface("window")
  detected=(browser.navigator.maxTouchPoints>0 and browser.matchMedia("(any-pointer: coarse)").matches) or detected
 hud=Control.new()
 hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(hud)
 stick_base=Panel.new()
 stick_knob=Panel.new()
 for panel in [stick_base,stick_knob]:
  panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var style=StyleBoxFlat.new()
  style.bg_color=Color(.22,.30,.19,.65) if panel==stick_base else Color(.9,.84,.62,.85)
  style.set_corner_radius_all(100)
  panel.add_theme_stylebox_override("panel",style)
  hud.add_child(panel)
 add_button("garden","Garden",func(): show_drawer("garden"))
 add_button("tools","Tools",func(): show_drawer("tools"))
 add_button("action","Water",act)
 add_button("layer","Layer",cycle_layer)
 add_button("cancel","Cancel",func(): g.set_mode("walk"))
 add_button("left","Turn left",func(): g.rotate_structure(-1))
 add_button("right","Turn right",func(): g.rotate_structure(1))
 add_button("greet","Greet",g.greet_pet)
 add_button("undo","Undo lift",undo_remove)
 add_button("up","Rise",func(): g.camera_target.y+=.5)
 add_button("down","Lower",func(): g.camera_target.y-=.5)
 add_button("photo","Take photo",g.capture_photo)
 add_button("done","Done",g.toggle_photo)
 close_button=g.button("Back to garden",close_menu)
 g.side_panel.get_child(0).add_child(close_button)
 close_button.hide()
 get_viewport().size_changed.connect(func(): last_size=Vector2.ZERO)
 configure()

func add_button(key: String, title: String, action: Callable) -> void:
 var b=g.button(title,action,Vector2(0,52))
 b.add_theme_font_size_override("font_size",18)
 hud.add_child(b)
 buttons[key]=b

func configure() -> void:
 var previous=enabled
 enabled=g.settings.controls=="touch" or (g.settings.controls=="auto" and detected)
 window_size=get_window().size
 hud.visible=enabled
 close_button.visible=enabled
 if enabled:
  Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  # Keep one logical UI pixel close to a CSS pixel, including retina devices.
  var dimensions=Vector2(get_window().size)
  if OS.has_feature("web"):
   var canvas=JavaScriptBridge.get_interface("document").getElementById("canvas")
   dimensions=Vector2(float(canvas.clientWidth),float(canvas.clientHeight))
  var factor=maxf(1.0,minf(dimensions.x/1100.0,dimensions.y/760.0))
  get_window().content_scale_size=Vector2i(dimensions/factor)
 elif previous:
  reset_gestures()
  get_window().content_scale_size=Vector2i(1440,900)
  g.side_panel.position=Vector2(24,112)
  g.side_panel.size=Vector2(300,664)
  g.side_panel.get_child(0).get_child(2).custom_minimum_size=Vector2(264,448)
  g.detail_label.show()
  g.side_panel.get_child(0).add_theme_constant_override("separation",12)
  g.reticle.position=Vector2(712,432)
  g.compact_hud.position=Vector2(28,24)
  g.compact_hud.size=Vector2.ZERO
  g.compact_hud.autowrap_mode=TextServer.AUTOWRAP_OFF
  g.toast_label.position=Vector2(430,125)
  g.toast_label.size.x=560
  g.transition_label.position=Vector2(430,92)
  g.transition_label.size.x=580
  if not g.side_panel.visible: g.resume_controls()
  if is_instance_valid(drawer): drawer.queue_free(); drawer=null
 apply_graphics()
 last_size=Vector2.ZERO

func apply_graphics() -> void:
 var low=g.settings.graphics=="mobile" or (g.settings.graphics=="auto" and enabled)
 var key=str(low)+str(g.settings.render_scale)
 if graphics_applied==key: return
 graphics_applied=key
 g.sun.shadow_enabled=not low
 get_viewport().scaling_3d_scale=maxf(.5,float(g.settings.render_scale)/100.0) if int(g.settings.render_scale)>0 else (.7 if low else 1.0)
 get_viewport().msaa_3d=Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
 apply_detail(g.world_root,90.0 if low else 0.0)
 apply_detail(g.plant_root,65.0 if low else 0.0)

func apply_detail(node: Node, distance_limit: float) -> void:
 if node is MeshInstance3D and node.get_aabb().size.length()<10:
  node.visibility_range_end=distance_limit
  node.visibility_range_end_margin=8.0 if distance_limit>0 else 0.0
 for child in node.get_children(): apply_detail(child,distance_limit)

func blocked() -> bool:
 return g.side_panel.visible or is_instance_valid(g.welcome) or (is_instance_valid(g.request_popup) and g.request_popup.visible) or is_instance_valid(drawer) or g.day_transition

func reset_gestures() -> void:
 stick_id=-1
 look_id=-1
 action_id=-1
 stick=Vector2.ZERO
 held=false

func close_menu() -> void:
 g.side_panel.hide()
 if is_instance_valid(drawer): drawer.queue_free(); drawer=null
 g.get_viewport().gui_release_focus()
 reset_gestures()
 g.resume_controls()

func cycle_layer() -> void:
 g.selected_layer=(g.selected_layer+1)%4
 g.toast("Target layer: "+["groundcover","flowers","shrubs","canopy"][g.selected_layer])

func show_drawer(kind: String) -> void:
 reset_gestures()
 g.side_panel.hide()
 if is_instance_valid(drawer): drawer.queue_free()
 drawer=PanelContainer.new()
 drawer.theme=g.menu_theme
 drawer.add_theme_stylebox_override("panel",GardenTheme.frame())
 add_child(drawer)
 var frame=VBoxContainer.new()
 drawer.add_child(frame)
 frame.add_child(g.button("Back to garden",close_menu,Vector2(0,48)))
 var scroll=ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 frame.add_child(scroll)
 var col=VBoxContainer.new()
 col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(col)
 var choices=[["Seeds","Seeds"],["Shop","Shop"],["Orders","Orders"],["Guide","Guide"],["Settings","Settings"]]
 if kind=="tools": choices=[["walk","Wander"],["plant","Plant"],["water","Water"],["prune","Prune"],["harvest","Gather"],["move","Move"],["remove","Remove"],["rake","Rake"]]
 for entry in choices:
  var key=entry[0]
  col.add_child(g.button(entry[1],func():
   close_menu()
   if kind=="tools": g.set_mode(key)
   else: g.open_sidebar(key),Vector2(0,48)))
 if kind=="garden":
  col.add_child(g.button("Next morning",func(): close_menu(); g.next_day(),Vector2(0,48)))
  col.add_child(g.button("Photo mode",func(): close_menu(); g.toggle_photo(),Vector2(0,48)))
 fit_drawer()

func fit_drawer() -> void:
 if not is_instance_valid(drawer): return
 var size=get_viewport().get_visible_rect().size
 drawer.position=Vector2(maxf(12,(size.x-400)/2),12)
 drawer.size=Vector2(minf(400,size.x-24),size.y-24)

func layout() -> void:
 var size=get_viewport().get_visible_rect().size
 last_size=size
 hud.size=size
 var scale=float(g.settings.control_size)/100.0
 radius=58*scale
 var left=bool(g.settings.left_handed)
 origin=Vector2(size.x-radius-26 if left else radius+26,size.y-radius-24)
 stick_base.position=origin-Vector2.ONE*radius
 stick_base.size=Vector2.ONE*radius*2
 stick_knob.size=Vector2.ONE*radius*.72
 var action_x=24.0 if left else size.x-130.0*scale-24.0
 place("garden",Vector2(size.x-118,12),Vector2(104,48))
 place("tools",Vector2(action_x,size.y-198*scale),Vector2(130,50)*scale)
 place("action",Vector2(action_x,size.y-136*scale),Vector2(130,66)*scale)
 place("layer",Vector2(size.x/2-90,size.y-58),Vector2(180,46))
 place("cancel",Vector2(size.x/2-54,size.y-110),Vector2(108,46))
 place("left",Vector2(size.x/2-120,size.y-168),Vector2(115,48))
 place("right",Vector2(size.x/2+5,size.y-168),Vector2(115,48))
 place("greet",Vector2(action_x,size.y-136*scale),Vector2(130,66)*scale)
 place("undo",Vector2(size.x/2-60,64),Vector2(120,48))
 place("up",Vector2(size.x/2-110,size.y-116),Vector2(100,48))
 place("down",Vector2(size.x/2+10,size.y-116),Vector2(100,48))
 place("photo",Vector2(action_x,size.y-136*scale),Vector2(130,66)*scale)
 place("done",Vector2(size.x-118,12),Vector2(104,48))
 if size.x<600:
  buttons.layer.position.y=size.y-244
  buttons.cancel.position.y=size.y-296
  buttons.left.position.y=size.y-352
  buttons.right.position.y=size.y-352
 g.reticle.position=size/2-Vector2(8,18)
 g.toast_label.position=Vector2(16,65)
 g.toast_label.size.x=size.x-32
 g.toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 g.compact_hud.position=Vector2(18,12)
 g.compact_hud.size.x=size.x-160
 g.compact_hud.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 g.compact_hud.add_theme_font_size_override("font_size",16)
 g.transition_label.position=Vector2(16,size.y/2-40)
 g.transition_label.size.x=size.x-32
 var col=g.side_panel.get_child(0)
 col.add_theme_constant_override("separation",5)
 for tab in col.get_child(0).get_children():
  tab.custom_minimum_size.y=48
  tab.add_theme_font_size_override("font_size",16)
 col.get_child(4).custom_minimum_size.y=48
 close_button.custom_minimum_size.y=48
 col.get_child(2).custom_minimum_size=Vector2(264,0)
 g.detail_label.hide()
 g.side_panel.position=Vector2(12,12)
 g.side_panel.size=Vector2(minf(430,size.x-24),size.y-24)
 fit_drawer()

func place(key: String, pos: Vector2, size: Vector2) -> void:
 buttons[key].position=pos
 buttons[key].size=size

func fit_popup(popup: Control) -> void:
 var area=get_viewport().get_visible_rect().size-Vector2(24,24)
 var factor=minf(1.0,minf(area.x/popup.size.x,area.y/popup.size.y))
 popup.scale=Vector2.ONE*factor
 popup.position=(area+Vector2(24,24)-popup.size*factor)/2

func _process(delta: float) -> void:
 if not enabled: return
 if get_window().size!=window_size: configure()
 if get_viewport().get_visible_rect().size!=last_size: layout()
 if Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE: Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if blocked(): reset_gestures()
 for panel in [g.hud_top,g.hud_title,g.hud_tools,g.hud_foot,g.hud_capacity,g.tip_label,g.rotation_panel,g.photo_panel]: panel.hide()
 g.compact_hud.visible=not blocked()
 g.compact_hud.text="Day %d · %d petals\n%s" % [g.day,g.coins,g.status_label.text if g.mode!="walk" else g.plots[g.current_plot].name]
 for b in buttons.values(): b.visible=not blocked()
 stick_base.visible=not blocked()
 stick_knob.visible=not blocked()
 stick_knob.position=origin+stick*radius*.65-stick_knob.size/2
 if blocked():
  if is_instance_valid(g.request_popup) and g.request_popup.visible: fit_popup(g.request_popup)
  if is_instance_valid(g.welcome): fit_popup(g.welcome)
  return
 var moving=g.mode=="move" and (g.moved_index>=0 or g.moved_object>=0)
 var rotating=g.mode=="build" or (g.mode=="move" and g.moved_object>=0)
 buttons.action.visible=g.mode!="walk" and not g.photo_mode
 buttons.action.disabled=not g.hover_valid
 if g.mode=="plant": g.compact_hud.text="%s · %d petals\n%s" % [g.catalogue[g.selected].name,g.coins,g.status_label.text]
 buttons.action.text={"plant":"Plant here","build":"Place here","move":"Place" if moving else "Pick up","remove":"Remove","water":"Water","prune":"Prune","harvest":"Gather","rake":"Rake"}.get(g.mode,"Use")
 buttons.layer.visible=g.mode!="walk" and not g.photo_mode
 buttons.layer.text="Layer: "+["Ground","Flowers","Shrubs","Trees"][g.selected_layer]
 buttons.cancel.visible=g.mode in ["build","move","plant"] and not g.photo_mode
 buttons.left.visible=rotating and not g.photo_mode
 buttons.right.visible=rotating and not g.photo_mode
 buttons.greet.visible=g.mode=="walk" and not g.photo_mode and g.pets.any(func(p): return p.position.distance_to(g.player.position)<4)
 for key in ["up","down","photo","done"]: buttons[key].visible=g.photo_mode
 buttons.garden.visible=not g.photo_mode
 buttons.tools.visible=not g.photo_mode
 undo_time=maxf(0,undo_time-delta)
 buttons.undo.visible=undo_time>0 and not removed.is_empty() and not g.photo_mode
 if held and g.mode in ["water","rake"]:
  repeat_time-=delta
  if repeat_time<=0: act(); repeat_time=.3

func _input(event: InputEvent) -> void:
 if enabled and g.settings.controls=="auto" and event is InputEventKey and event.pressed and not blocked() and event.physical_keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
  detected=false
  g.settings.controls="keyboard"
  configure()
  g.settings.controls="auto"
 if event is InputEventScreenTouch and event.pressed and not enabled and g.settings.controls=="auto":
  detected=true
  configure()
 if not enabled: return
 if event is InputEventScreenTouch and not event.pressed:
  if event.index==stick_id: stick_id=-1; stick=Vector2.ZERO
  if event.index==look_id: look_id=-1
  if event.index==action_id: action_id=-1; held=false
 if blocked(): return
 if event is InputEventMouse and event.device==-1:
  for b in buttons.values():
   if b.visible and b.get_global_rect().has_point(event.position):
    get_viewport().set_input_as_handled()
    return
 if event is InputEventScreenTouch and event.pressed:
  for key in buttons:
   var b=buttons[key]
   if b.visible and not b.disabled and b.get_global_rect().has_point(event.position):
    if key=="action": action_id=event.index; held=true; repeat_time=.3
    b.pressed.emit()
    get_viewport().set_input_as_handled()
    return
 if event is InputEventScreenDrag:
  if event.index==stick_id:
   stick=((event.position-origin)/radius).limit_length(1.0)
   if stick.length()<.12: stick=Vector2.ZERO
   get_viewport().set_input_as_handled()
  elif event.index==look_id:
   g.apply_mouse_look(event.relative*1.7)
   get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if not enabled or blocked(): return
 if event is InputEventScreenTouch and event.pressed:
  if event.position.distance_to(origin)<radius*1.5 and stick_id<0:
   stick_id=event.index
   stick=((event.position-origin)/radius).limit_length(1.0)
  elif look_id<0:
   look_id=event.index
  get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  reset_gestures()
  if is_instance_valid(g) and enabled and not g.smoke: g.save_game()

func act() -> void:
 if blocked() or not g.hover_valid: return
 removed.clear()
 if g.mode=="remove":
  var index=g.plant_at(g.hover_cell,g.selected_layer)
  if index<0:
   for layer_index in range(4):
    index=g.plant_at(g.hover_cell,layer_index)
    if index>=0: break
  if index>=0:
   removed=g.planted[index].duplicate()
   removed.erase("node"); removed.erase("marker")
   removed["plant"]=true
  else:
   index=g.object_at(g.hover_cell)
   if index>=0:
    removed=g.objects[index].duplicate()
    removed.erase("node")
    removed["plant"]=false
 var count=g.planted.size()+g.objects.size()
 g.perform_action()
 if count==g.planted.size()+g.objects.size(): removed.clear()
 else: undo_time=12.0

func undo_remove() -> void:
 if removed.is_empty(): return
 var old=removed
 if old.plant:
  if not g.can_plant(old.id,old.pos,old.plot).is_empty(): g.toast("Make room in that spot before undoing."); return
  var p=g.add_plant(old.id,old.pos,old.plot,old.age,old.height_factor)
  for key in ["water","stress","pruned"]: p[key]=old[key]
  g.refresh_plant(p)
 else:
  if g.coins<old.price or g.object_at(old.pos)>=0: g.toast("The refund and the original space are needed to undo."); return
  g.coins-=old.price
  g.add_object(old.kind,old.pos,old.price,old.fish,old.get("rotation",0.0),old.get("text","My garden"),Color.from_string(old.get("text_color","f1e5c7"),Color("f1e5c7")))
 removed.clear()
 g.refresh_ui()
 g.toast("Back where it belongs.")

func settings_page() -> void:
 g.add_note("CONTROLS & DISPLAY",15)
 for entry in [["controls",["auto","touch","keyboard"],["Auto controls","Touch controls","Keyboard & mouse"]],["graphics",["auto","mobile","standard"],["Auto graphics","Mobile graphics","Standard graphics"]],["render_scale",[0,50,70,85,100],["Auto 3D resolution","3D resolution: 50%","3D resolution: 70%","3D resolution: 85%","3D resolution: 100%"]]]:
  var key=entry[0]
  var values=entry[1]
  var choice=OptionButton.new()
  choice.custom_minimum_size.y=48
  for title in entry[2]: choice.add_item(title)
  choice.select(maxi(0,values.find(g.settings[key])))
  choice.item_selected.connect(func(index): g.settings[key]=values[index]; configure(); g.save_game())
  g.list_box.add_child(choice)
 var handed=CheckButton.new()
 handed.text="Left-handed touch layout"
 handed.button_pressed=g.settings.left_handed
 handed.custom_minimum_size.y=48
 handed.toggled.connect(func(value): g.settings.left_handed=value; last_size=Vector2.ZERO; g.save_game())
 g.list_box.add_child(handed)
 for entry in [["control_size","Touch control size",80,120,10]]:
  var key=entry[0]
  g.add_note(entry[1])
  var slider=HSlider.new()
  slider.min_value=entry[2]; slider.max_value=entry[3]; slider.step=entry[4]
  slider.value=g.settings[key]
  slider.custom_minimum_size.y=48
  slider.value_changed.connect(func(value): g.settings[key]=value; last_size=Vector2.ZERO; apply_graphics())
  slider.drag_ended.connect(func(_changed): g.save_game())
  g.list_box.add_child(slider)

func welcome_page() -> void:
 g.welcome=g.panel_at(Vector2.ZERO,Vector2(360,330))
 g.welcome.z_index=30
 var col=VBoxContainer.new()
 col.add_theme_constant_override("separation",12)
 g.welcome.add_child(col)
 col.add_child(g.label("Welcome to your garden",24))
 var note=g.label("Left thumb: walk. Drag the view to look around.\n\nTools lets you plant, water, prune and gather. Aim with the centre dot, then tap the action button.\n\nGarden opens seeds, the shop, requests and settings. Turn your phone sideways for more room.",18)
 note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 note.custom_minimum_size.x=300
 col.add_child(note)
 col.add_child(g.button("Explore the garden",func(): GardenExperience.finish(g),Vector2(0,52)))
 fit_popup(g.welcome)
