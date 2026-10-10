class_name GardenTouch
extends CanvasLayer

var view_return_fingers: Dictionary={}

# Touch gestures own their finger IDs so walking, looking and actions can coexist.
var g
var enabled=false
var detected=false
var stick=Vector2.ZERO
var stick_id=-1
var look_id=-1
var action_id=-1
var finger_positions: Dictionary={}
var display_size=Vector2.ZERO
var status_panel: Panel
var status_text: Label
var context_panel: Panel
var context_title: Label
var context_hint: Label
var walk_label: Label
var look_label: Label
var look_base: Panel
var look_knob: Panel
var look_origin=Vector2.ZERO
var look_anchor=Vector2.ZERO
var action_anchor=Vector2.ZERO
var context_keys: Array=[]
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
var tablet_layout=false
var wide_menu=false
var seed_detail: Dictionary={}
var seed_scroll=0

const CONTINUOUS_TOOLS=["water","rake","hoe","harvest"]
const TOOL_CHOICES=[["walk","Wander"],["plant","Plant"],["water","Water"],["prune","Prune"],["harvest","Gather"],["move","Move"],["remove","Remove"],["rake","Rake"],["hoe","Hoe"]]

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
 status_panel=readout()
 status_text=readout_label(status_panel,16)
 context_panel=readout()
 context_title=readout_label(context_panel,17)
 context_hint=readout_label(context_panel,14)
 walk_label=readout_label(hud,14)
 walk_label.text="WALK"
 walk_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 look_base=Panel.new()
 look_knob=Panel.new()
 for panel in [look_base,look_knob]:
  panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var style=StyleBoxFlat.new()
  style.bg_color=Color(.22,.30,.19,.38) if panel==look_base else Color(.9,.84,.62,.55)
  style.set_corner_radius_all(100)
  panel.add_theme_stylebox_override("panel",style)
  hud.add_child(panel)
 look_label=readout_label(hud,14)
 look_label.text="LOOK"
 look_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 add_button("garden","Garden",func(): open_menu("Garden"))
 add_button("seeds","Seeds",func(): open_menu("Seeds"))
 add_button("tools","Tools",func(): show_drawer("tools"))
 GardenTheme.disclosure(buttons.tools)
 add_button("action","Water",act)
 add_button("layer","Layer",func():
  if g.mode=="hoe":GardenTools.toggle_hoe(g)
  else:cycle_layer())
 add_button("cancel","Cancel",func(): g.set_mode("walk"))
 add_button("left","Turn left",func():
  if g.mode=="prune":GardenTools.resize_pruners(g,-1)
  else:g.rotate_structure(-1))
 add_button("right","Turn right",func():
  if g.mode=="prune":GardenTools.resize_pruners(g,1)
  else:g.rotate_structure(1))
 add_button("greet","Interact",func(): GardenLeisure.interact(g))
 add_button("undo","Undo lift",undo_remove)
 add_button("up","Rise",func(): g.camera_target.y+=.5)
 add_button("down","Lower",func(): g.camera_target.y-=.5)
 add_button("photo","Take photo",g.capture_photo)
 add_button("done","Done",g.toggle_photo)
 close_button=g.button("Back to garden",close_menu)
 close_button.name="TouchBackToGarden"
 g.side_panel.get_child(0).add_child(close_button)
 close_button.hide()
 get_viewport().size_changed.connect(func(): last_size=Vector2.ZERO)
 configure()

func readout() -> Panel:
 var panel=Panel.new()
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",GardenTheme.frame("button",Color(1,1,1,.94),10))
 hud.add_child(panel)
 return panel

func readout_label(parent: Control, font_size: int) -> Label:
 var text=g.label("",font_size,Color("fff0cc"))
 text.mouse_filter=Control.MOUSE_FILTER_IGNORE
 text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 text.max_lines_visible=2
 parent.add_child(text)
 return text

func add_button(key: String, title: String, action: Callable) -> void:
 var b=g.button(title,action,Vector2(0,52))
 b.add_theme_font_size_override("font_size",17)
 b.focus_mode=Control.FOCUS_NONE
 b.clip_text=true
 hud.add_child(b)
 buttons[key]=b

func configure() -> void:
 reset_gestures()
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
  display_size=dimensions
  var factor=maxf(1.0,minf(dimensions.x/1100.0,dimensions.y/760.0))
  get_window().content_scale_size=Vector2i(dimensions/factor)
 elif previous:
  if not g.side_panel.visible: g.resume_controls()
  if is_instance_valid(drawer): drawer.queue_free(); drawer=null
 if not enabled:
  var dimensions=Vector2(get_window().size)
  if OS.has_feature("web"):
   var canvas=JavaScriptBridge.get_interface("document").getElementById("canvas")
   dimensions=Vector2(float(canvas.clientWidth),float(canvas.clientHeight))
  var factor=maxf(1.0,minf(dimensions.x/1600.0,dimensions.y/1000.0))
  get_window().content_scale_size=Vector2i(dimensions/factor)
  GardenInterface.layout(g,true)
  var atlas_button=g.side_panel.get_child(0).get_child(4)
  atlas_button.text="Garden atlas · milestones & trails"
  g.side_panel.get_child(0).get_child(5).custom_minimum_size.y=30
  g.side_title.autowrap_mode=TextServer.AUTOWRAP_OFF
  g.side_title.custom_minimum_size.x=0
 apply_graphics()
 last_size=Vector2.ZERO
 # Establish coordinates before the next touch, not on the following frame.
 if enabled: layout()

func apply_graphics() -> void:
 var low=g.settings.graphics=="mobile" or (g.settings.graphics=="auto" and enabled)
 var population=g.planted.size() if is_instance_valid(g.plant_batches) else g.loaded_data.get("plants",[]).size()
 var dense=not low and g.settings.graphics=="auto" and population>=GardenPlantBatches.MIN_PLANTS
 var key=str(g.settings.graphics)+str(low)+str(dense)+str(g.settings.render_scale)
 if graphics_applied==key: return
 graphics_applied=key
 g.sun.shadow_enabled=not low
 g.sun.directional_shadow_max_distance=40.0 if dense else 90.0
 get_viewport().scaling_3d_scale=maxf(.5,float(g.settings.render_scale)/100.0) if int(g.settings.render_scale)>0 else (.7 if low else .85 if dense else 1.0)
 get_viewport().msaa_3d=Viewport.MSAA_DISABLED if low or dense else Viewport.MSAA_2X
 # Compatibility/WebGL does not implement Godot's screen-space AA.
 get_viewport().screen_space_aa=Viewport.SCREEN_SPACE_AA_FXAA if dense and RenderingServer.get_current_rendering_method()!="gl_compatibility" else Viewport.SCREEN_SPACE_AA_DISABLED
 get_viewport().mesh_lod_threshold=2.0 if dense else 1.0
 apply_detail(g.world_root,90.0 if low else 0.0)
 apply_detail(g.plant_root,65.0 if low else 0.0)
 GardenAreaFlora.update_detail(g)
 if is_instance_valid(g.plant_batches):g.plant_batches.invalidate()

func apply_detail(node: Node, distance_limit: float) -> void:
 if node is MeshInstance3D and not node.get_meta("sculpt_registered",false) and node.get_aabb().size.length()<10:
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
 repeat_time=0.0
 finger_positions.clear()

func close_menu() -> void:
 g.side_panel.hide()
 if is_instance_valid(drawer): drawer.queue_free(); drawer=null
 g.get_viewport().gui_release_focus()
 reset_gestures()
 g.resume_controls()

func cycle_layer() -> void:
 g.selected_layer=(g.selected_layer+1)%4
 g.toast("Target layer: "+["groundcover","flowers","shrubs","canopy"][g.selected_layer])
 GardenTutorial.hint(g,"layers","One spot can hold groundcover, flowers, shrubs and a tree. Switch layers to choose the plant you mean.")

func open_menu(page: String) -> void:
 if is_instance_valid(drawer):drawer.queue_free();drawer=null
 reset_gestures()
 # Shortcuts always open the page, even if it was last selected.
 g.side_panel.hide()
 g.open_sidebar(page)
 layout_menu()

func open_seed_details(plant: Dictionary) -> void:
 seed_scroll=g.list_box.get_parent().scroll_vertical
 seed_detail=plant.duplicate()
 g.active_tab="Seed details"
 g.refresh_sidebar()
 g.list_box.get_parent().set_deferred("scroll_vertical",0)
 layout_menu()

func back_to_seeds() -> void:
 var restore_scroll=seed_scroll
 g.active_tab="Seeds"
 g.refresh_sidebar()
 layout_menu()
 var cards=g.list_box.get_node("PlantCards")
 # Card heights settle over container layout passes. Restoring sooner clamps
 # against the old details page's scroll range and loses the browsing position.
 await g.get_tree().process_frame
 await g.get_tree().process_frame
 if g.active_tab=="Seeds" and g.side_panel.visible and is_instance_valid(cards) and cards.get_parent()==g.list_box:
  g.list_box.get_parent().scroll_vertical=restore_scroll

func garden_page() -> void:
 g.side_title.text="Your garden"
 g.add_note("Browse Seeds, Shop, Orders and Guide with the tabs above. Return to the garden whenever you’re ready.",17)
 g.list_box.add_child(g.button("Garden atlas · milestones & trails",func():GardenAreaAtlas.open(g)))
 g.list_box.add_child(g.button("Next morning",func():close_menu();g.next_day()))
 g.add_note("COMPANIONS",15)
 for index in range(g.companion_names.size()):
  var pet_index=index
  g.list_box.add_child(g.button("Call "+g.companion_names[index],func():close_menu();GardenLeisure.call_pet(g,pet_index)))
  if not g.rest_kind.is_empty():
   g.list_box.add_child(g.button("Invite "+g.companion_names[index]+" to settle",func():close_menu();GardenLeisure.call_pet(g,pet_index,true)))
 if not g.rest_kind.is_empty():g.list_box.add_child(g.button("Stand up",func():close_menu();GardenLeisure.leave(g)))
 if g.pets.any(func(p):return p.position.distance_to(g.player.position)<4):
  g.list_box.add_child(g.button("Pet companion",func():close_menu();g.greet_pet()))
 g.add_note("STAY A WHILE",15)
 g.list_box.add_child(g.button("Photo mode",func():close_menu();g.toggle_photo()))
 g.list_box.add_child(g.button("Enjoy the view",func():close_menu();GardenClearView.enter(g)))
 g.detail_label.text="Your usual garden menus, with room to browse by touch."

func show_drawer(kind: String) -> void:
 if kind=="garden":open_menu("Garden");return
 if is_instance_valid(drawer):close_menu();return
 reset_gestures()
 g.side_panel.hide()
 drawer=PanelContainer.new()
 drawer.name="TouchToolTray"
 drawer.theme=g.menu_theme
 drawer.add_theme_stylebox_override("panel",GardenTheme.frame())
 add_child(drawer)
 var frame=VBoxContainer.new()
 frame.add_theme_constant_override("separation",8)
 drawer.add_child(frame)
 frame.add_child(g.label("Choose a tool",22))
 var scroll=ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 frame.add_child(scroll)
 var col=GridContainer.new()
 col.columns=3
 col.add_theme_constant_override("h_separation",8)
 col.add_theme_constant_override("v_separation",8)
 col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(col)
 for entry in TOOL_CHOICES:
  var key=entry[0]
  var choice=g.button(entry[1],func():
   close_menu()
   g.set_mode(key),Vector2(0,54))
  choice.name="Tool"+key.capitalize()
  GardenTheme.choose(choice,g.mode==key)
  choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  col.add_child(choice)
 frame.add_child(g.button("Back to garden",close_menu,Vector2(0,48)))
 fit_drawer()

func fit_drawer() -> void:
 if not is_instance_valid(drawer): return
 var size=get_viewport().get_visible_rect().size
 var width=minf(368,size.x-24)
 var height=minf(310,size.y-24)
 drawer.size=Vector2(width,height)
 var x=clampf(buttons.tools.position.x,12,size.x-width-12)
 if g.settings.left_handed:x=clampf(buttons.tools.position.x+buttons.tools.size.x-width,12,size.x-width-12)
 drawer.position=Vector2(x,maxf(12,buttons.tools.position.y-height-12))

func layout() -> void:
 # A changed coordinate system invalidates fingers already on the glass.
 reset_gestures()
 var size=get_viewport().get_visible_rect().size
 last_size=size
 hud.size=size
 tablet_layout=size.x>=700 and size.y>=560
 wide_menu=tablet_layout and size.x>=960 and size.x/size.y>=1.25
 if tablet_layout:
  layout_tablet(size)
  layout_menu()
  fit_drawer()
  return
 var scale=minf(float(g.settings.control_size)/100.0,(size.x-48)/234.0)
 radius=54*scale
 var left=bool(g.settings.left_handed)
 var margin=16.0
 origin=Vector2(size.x-radius-margin if left else radius+margin,size.y-radius-32)
 stick_base.position=origin-Vector2.ONE*radius
 stick_base.size=Vector2.ONE*radius*2
 stick_knob.size=Vector2.ONE*radius*.72
 walk_label.position=Vector2(origin.x-radius,size.y-28)
 walk_label.size=Vector2(radius*2,22)
 var action_width=126*scale
 var action_x=margin if left else size.x-action_width-margin
 var action_y=size.y-32-maxf(60,64*scale)
 var tool_y=action_y-8-maxf(48,48*scale)
 place("tools",Vector2(action_x,tool_y),Vector2(action_width,maxf(48,48*scale)))
 for key in ["action","greet","photo"]:
  place(key,Vector2(action_x,action_y),Vector2(action_width,maxf(60,64*scale)))
 place("garden",Vector2(size.x-110,12),Vector2(98,48))
 place("seeds",Vector2(size.x-204,12),Vector2(86,48))
 place("done",buttons.garden.position,buttons.garden.size)
 status_panel.position=Vector2(12,12)
 status_panel.size=Vector2(minf(320,size.x-224),48)
 status_text.position=Vector2(10,4)
 status_text.size=Vector2(status_panel.size.x-20,40)
 status_text.add_theme_font_size_override("font_size",14 if size.x<380 else 16)
 status_text.max_lines_visible=2
 place("undo",Vector2(size.x-132,68),Vector2(120,48))
 var portrait=size.x<600
 var context_width=minf(500,size.x-2*(maxf(radius*2,action_width)+32)) if not portrait else size.x-24
 context_panel.size=Vector2(context_width,70)
 context_panel.position=Vector2((size.x-context_width)/2,size.y-150 if not portrait else (72.0 if size.y<650 else tool_y-146))
 context_title.position=Vector2(12,7)
 context_title.size=Vector2(context_width-24,24)
 context_title.max_lines_visible=1
 context_title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 context_hint.position=Vector2(12,32)
 context_hint.size=Vector2(context_width-24,34)
 g.reticle.position=size/2-Vector2(8,18)
 g.toast_label.size.x=minf(480,size.x-32)
 g.toast_label.position=Vector2((size.x-g.toast_label.size.x)/2,72)
 g.toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 g.transition_label.position=Vector2(16,size.y/2-40)
 g.transition_label.size.x=size.x-32
 layout_menu()
 context_keys=[]
 fit_drawer()

func layout_menu() -> void:
 var size=get_viewport().get_visible_rect().size
 var col=g.side_panel.get_child(0)
 col.add_theme_constant_override("separation",5)
 for tab in col.get_child(0).get_children():
  tab.custom_minimum_size.y=48
  tab.add_theme_font_size_override("font_size",14 if size.x<380 else 16)
 col.get_child(4).custom_minimum_size.y=48
 col.get_child(5).custom_minimum_size.y=48
 close_button.custom_minimum_size.y=48
 col.get_child(2).custom_minimum_size=Vector2(264,80 if tablet_layout else 0)
 g.detail_label.hide()
 g.side_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 g.side_title.custom_minimum_size.x=264
 col.get_child(4).text="Garden & companions"
 var menu_width=minf(480,size.x-24)
 if tablet_layout:menu_width=clampf(size.x*.42,392,520) if wide_menu else minf(740,size.x*.9)
 g.side_panel.position=Vector2(20 if wide_menu else (size.x-menu_width)/2,16 if tablet_layout else 12)
 g.side_panel.size=Vector2(menu_width,size.y-(32 if tablet_layout else 24))
 if g.active_tab=="Seeds":GardenSeedCollection.layout_cards(g,menu_width-44)
 var ornaments=g.list_box.get_node_or_null("OrnamentCards")
 if ornaments:ornaments.columns=clampi(int((menu_width-44)/170),2,4) if tablet_layout else 2

func layout_tablet(size: Vector2) -> void:
 var scale=clampf(float(g.settings.control_size)/100.0,.8,1.2)
 radius=60*scale
 var inset=clampf(float(g.settings.get("touch_inset",0)),0,minf(100,(size.x-640)/2))
 var lift=clampf(float(g.settings.get("touch_height",0)),0,minf(120,size.y*.15))
 var edge=20+inset
 var left=bool(g.settings.left_handed)
 origin=Vector2(size.x-edge-radius if left else edge+radius,size.y-20-radius-lift)
 look_origin=Vector2(edge+radius if left else size.x-edge-radius,origin.y)
 for entry in [[stick_base,origin],[look_base,look_origin]]:
  entry[0].position=entry[1]-Vector2.ONE*radius
  entry[0].size=Vector2.ONE*radius*2
 stick_knob.size=Vector2.ONE*radius*.72
 look_knob.size=Vector2.ONE*radius*.55
 for entry in [[walk_label,origin],[look_label,look_origin]]:
  entry[0].position=Vector2(entry[1].x-radius,entry[1].y+radius+2)
  entry[0].size=Vector2(radius*2,20)
 var row_width=minf(240*scale,(size.x-2*edge-224)/2)
 var row_x=size.x-edge-row_width if left else edge
 var row_y=origin.y-radius-68
 var seed_width=80*scale
 place("seeds",Vector2(row_x,row_y),Vector2(seed_width,56))
 place("tools",Vector2(row_x+seed_width+8,row_y),Vector2(row_width-seed_width-8,56))
 var action_width=160*scale
 var action_x=edge if left else size.x-edge-action_width
 for key in ["action","greet","photo"]:place(key,Vector2(action_x,row_y),Vector2(action_width,56))
 place("garden",Vector2(size.x-124,20),Vector2(104,52))
 place("done",buttons.garden.position,buttons.garden.size)
 status_panel.position=Vector2(20,16)
 status_panel.size=Vector2(minf(480,size.x-164),80)
 status_text.position=Vector2(12,6)
 status_text.size=status_panel.size-Vector2(24,12)
 status_text.max_lines_visible=3
 status_text.add_theme_font_size_override("font_size",16)
 var context_width=minf(460,size.x-2*(row_width+edge+12))
 context_panel.size=Vector2(maxf(200,context_width),70)
 context_title.position=Vector2(12,7)
 context_title.size=Vector2(context_panel.size.x-24,24)
 context_title.max_lines_visible=1
 context_title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 context_hint.position=Vector2(12,32)
 context_hint.size=Vector2(context_panel.size.x-24,34)
 g.reticle.position=size/2-Vector2(8,18)
 g.toast_label.size=Vector2(minf(520,size.x-40),0)
 g.toast_label.position=Vector2((size.x-g.toast_label.size.x)/2,110)
 g.toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 g.transition_label.position=Vector2(20,size.y/2-40)
 g.transition_label.size.x=size.x-40
 context_keys=[]
 layout_context([],true)

func layout_context(keys: Array, force: bool=false) -> void:
 if keys==context_keys and not force: return
 context_keys=keys.duplicate()
 var size=get_viewport().get_visible_rect().size
 var width=context_panel.size.x
 if tablet_layout:
  var columns=3 if width>=300 else 2
  var rows=ceili(float(keys.size())/columns)
  var x=(size.x-width)/2
  var y=size.y-20-70-(rows*56+8 if rows>0 else 0)
  context_panel.position=Vector2(x,y)
  var option_width=(width-8*(columns-1))/columns
  for index in range(keys.size()):
   place(keys[index],Vector2(x+(index%columns)*(option_width+8),y+78+(index/columns)*56),Vector2(option_width,48))
   buttons[keys[index]].add_theme_font_size_override("font_size",16)
  return
 if keys.is_empty(): return
 var button_width=minf(180,(width-8*(keys.size()-1))/keys.size())
 var row_width=button_width*keys.size()+8*(keys.size()-1)
 var x=context_panel.position.x+(width-row_width)/2
 var y=buttons.tools.position.y-60 if size.x<600 else context_panel.position.y+context_panel.size.y+8
 for index in range(keys.size()):
  place(keys[index],Vector2(x+index*(button_width+8),y),Vector2(button_width,48))
  buttons[keys[index]].add_theme_font_size_override("font_size",14 if keys.size()>3 else 16)

func place(key: String, pos: Vector2, size: Vector2) -> void:
 buttons[key].position=pos
 buttons[key].size=size

func fit_popup(popup: Control) -> void:
 var area=get_viewport().get_visible_rect().size-Vector2(24,24)
 var factor=minf(1.0,minf(area.x/popup.size.x,area.y/popup.size.y))
 popup.scale=Vector2.ONE*factor
 popup.position=(area+Vector2(24,24)-popup.size*factor)/2

func _process(delta: float) -> void:
 if g.clear_view:return
 if get_window().size!=window_size: configure()
 if not enabled: return
 if get_viewport().get_visible_rect().size!=last_size: layout()
 if Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE: Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if blocked(): reset_gestures()
 for panel in [g.hud_top,g.hud_title,g.hud_tools,g.hud_foot,g.hud_capacity,g.tip_label,g.rotation_panel,g.photo_panel,g.view_button]: panel.hide()
 g.compact_hud.hide()
 g.reticle.visible=not blocked() and not g.photo_mode
 status_panel.visible=not blocked()
 context_panel.visible=not blocked() and not g.tutorial_state.get("active",false) and (not tablet_layout or g.mode!="walk" or not g.inspector_lines.is_empty() or not g.rest_kind.is_empty() or g.photo_mode)
 walk_label.visible=not blocked()
 look_label.visible=tablet_layout and not blocked()
 look_base.visible=look_label.visible
 look_knob.visible=look_label.visible
 status_text.text="Day %d · %d petals\n%s" % [g.day,g.coins,GardenClimate.season(g.day)]
 if tablet_layout:
  status_text.text=g.plots[g.current_plot].name+"\nDay %d · %02d:%02d · %d petals\n%s · %s"%[g.day,int(g.clock_time*24),int(fmod(g.clock_time*1440,60)),g.coins,GardenClimate.season(g.day),g.climate.description()]
 if last_size.x<380: status_text.text="Day %d\n%d petals"%[g.day,g.coins]
 for b in buttons.values(): b.visible=not blocked()
 stick_base.visible=not blocked()
 stick_knob.visible=not blocked()
 stick_knob.position=origin+stick*radius*.65-stick_knob.size/2
 var look_offset=Vector2.ZERO
 if finger_positions.has(look_id):look_offset=finger_positions[look_id]-look_anchor
 elif held and finger_positions.has(action_id):look_offset=finger_positions[action_id]-action_anchor
 look_knob.position=look_origin+look_offset.limit_length(radius*.65)-look_knob.size/2
 if blocked():
  if is_instance_valid(g.request_popup) and g.request_popup.visible: fit_popup(g.request_popup)
  if is_instance_valid(g.welcome):
   if g.workshop_open:GardenWorkshop.fit(g)
   elif g.area_atlas_open:GardenAreaAtlas.fit(g)
   else:fit_popup(g.welcome)
  return
 var moving=g.mode=="move" and (g.moved_index>=0 or g.moved_object>=0)
 var rotating=g.mode=="build" or (g.mode=="move" and g.moved_object>=0)
 buttons.action.visible=g.mode!="walk" and not g.photo_mode
 buttons.action.disabled=not g.hover_valid
 buttons.action.text={"plant":"Plant here","build":"Place here","move":"Place" if moving else "Pick up","remove":"Remove","water":"Water","prune":"Prune","harvest":"Gather","rake":"Rake","hoe":"Raise ground" if g.hoe_raise else "Lower ground"}.get(g.mode,"Use")
 buttons.tools.text="Tools"
 for entry in TOOL_CHOICES:
  if entry[0]==g.mode:buttons.tools.text=entry[1]
 if buttons.tools.size.x<104:buttons.tools.text="Tools"
 context_title.text={"walk":"Explore your garden","water":"Water · +20% growth","prune":"Prune · %.2f m square"%GardenTools.prune_width(g),"harvest":"Gather · %.1f m square"%GardenTools.gather_width(g),"hoe":"Hoe · "+("raise ground" if g.hoe_raise else "lower ground")}.get(g.mode,g.mode.capitalize())
 if g.mode=="plant": context_title.text="Plant · "+g.catalogue[g.selected].name
 if g.mode=="build": context_title.text="Place · "+g.furniture[g.selected_furniture].name
 context_hint.text="Drag the view to look. Choose Tools to start gardening." if g.mode=="walk" else g.status_label.text.replace("\n"," · ")
 if g.mode in CONTINUOUS_TOOLS: context_hint.text="Hold "+buttons.action.text+" and drag to look. Release to stop."
 if not g.inspector_lines.is_empty():
  context_title.text=g.inspector_lines[0]
  context_hint.text=" · ".join(g.inspector_lines.slice(1,4))
 if g.mode=="plant" and not g.preview_error.is_empty(): context_hint.text=g.preview_error
 elif g.mode=="plant" and g.inspector_lines.is_empty():
  context_hint.text="%s · %d capacity\nBed: %d / %d used"%[g.catalogue[g.selected].condition.capitalize(),g.catalogue[g.selected].capacity,g.capacity_used(g.current_plot),g.plot_capacity(g.current_plot)]
 if g.photo_mode:
  context_title.text="Photo mode"
  context_hint.text="Walk and drag to frame your picture."
 buttons.layer.visible=(g.mode in ["prune","move","remove","hoe"] or (g.hover_target>=0 and g.mode in ["walk","water","harvest"])) and not g.photo_mode
 buttons.layer.text=["Ground","Flowers","Shrubs","Trees"][g.selected_layer]
 if g.mode=="hoe":buttons.layer.text="Switch to "+("lower" if g.hoe_raise else "raise")
 if g.mode=="hoe" and tablet_layout and context_panel.size.x<300:buttons.layer.text="Lower" if g.hoe_raise else "Raise"
 buttons.cancel.visible=g.mode!="walk" and not g.photo_mode
 buttons.cancel.text="Done"
 buttons.left.visible=(rotating or g.mode=="prune") and not g.photo_mode
 buttons.left.text="Smaller" if g.mode=="prune" else "Turn left"
 buttons.right.visible=(rotating or g.mode=="prune") and not g.photo_mode
 buttons.right.text="Larger" if g.mode=="prune" else "Turn right"
 var rest_target=GardenLeisure.target(g)
 var work_target=GardenWorkshop.target(g)
 buttons.greet.visible=g.mode=="walk" and not g.photo_mode and (not g.rest_kind.is_empty() or not rest_target.is_empty() or not work_target.is_empty() or GardenAreaCatalogue.index_at(g.player.position)>=0 or g.pets.any(func(p): return p.position.distance_to(g.player.position)<4))
 buttons.greet.text="Stand up" if not g.rest_kind.is_empty() else GardenLeisure.VERBS.get(rest_target.get("kind",""),"Pet companion")
 if g.rest_kind.is_empty() and work_target.is_empty() and rest_target.is_empty() and GardenAreaCatalogue.index_at(g.player.position)>=0:buttons.greet.text="Garden activities"
 if g.rest_kind.is_empty() and not work_target.is_empty():buttons.greet.text="Use planter" if work_target.kind in GardenContainers.SPECS else "Use equipment"
 var habitat=GardenAreaCatalogue.index_at(g.player.position)
 if g.rest_kind.is_empty() and habitat>=0 and not GardenAreaProgression.unlocked(g,habitat):buttons.greet.text="Garden milestone"
 if not g.rest_kind.is_empty():
  context_title.text={"bench":"Sitting in your garden","pergola":"Resting in the shade","pond":"Watching the pond"}.get(g.rest_kind,"Resting")
  context_hint.text="Drag to look. Garden lets you invite a companion. Walk or tap Stand up to leave."
 for key in ["up","down","photo","done"]: buttons[key].visible=g.photo_mode
 buttons.seeds.visible=not g.photo_mode
 buttons.garden.visible=not g.photo_mode
 buttons.tools.visible=not g.photo_mode
 undo_time=maxf(0,undo_time-delta)
 buttons.undo.visible=undo_time>0 and not removed.is_empty() and not g.photo_mode
 var options=[]
 for key in ["layer","left","right","cancel","undo","up","down"]:
  if buttons[key].visible: options.append(key)
 layout_context(options)
 if held and g.mode in CONTINUOUS_TOOLS:
  repeat_time-=delta
  if repeat_time<=0:
   act(true)
   repeat_time=GardenTools.GATHER_INTERVAL if g.mode=="harvest" else .3

func _input(event: InputEvent) -> void:
 if (event is InputEventScreenTouch or event is InputEventScreenDrag) and view_return_fingers.has(event.index):
  if event is InputEventScreenTouch and (not event.pressed or event.canceled):view_return_fingers.erase(event.index)
  get_viewport().set_input_as_handled()
  return
 if get_viewport().is_input_handled():return
 if g.clear_view:return
 if enabled and g.settings.controls=="auto" and event is InputEventKey and event.pressed and not blocked() and event.physical_keycode in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_UP,KEY_DOWN,KEY_LEFT,KEY_RIGHT]:
  detected=false
  g.settings.controls="keyboard"
  configure()
  g.settings.controls="auto"
 if event is InputEventScreenTouch and event.pressed and not enabled and g.settings.controls=="auto":
  detected=true
  configure()
 if not enabled: return
 if get_viewport().get_visible_rect().size!=last_size: layout()
 if event is InputEventScreenTouch and (not event.pressed or event.canceled):
  var owned=finger_positions.has(event.index)
  finger_positions.erase(event.index)
  if event.index==stick_id: stick_id=-1; stick=Vector2.ZERO
  if event.index==look_id: look_id=-1
  if event.index==action_id: action_id=-1; held=false
  if owned: get_viewport().set_input_as_handled()
  return
 if blocked(): return
 if event is InputEventScreenTouch and event.pressed and is_instance_valid(g.tutorial_panel) and g.tutorial_panel.visible and g.tutorial_panel.get_global_rect().has_point(event.position):
  finger_positions[event.index]=event.position
  for control in g.tutorial_panel.find_children("*","Button",true,false):
   if control.is_visible_in_tree() and not control.disabled and control.get_global_rect().has_point(event.position):
    control.pressed.emit()
    break
  get_viewport().set_input_as_handled()
  return
 # Godot synthesizes mouse events for touchscreen UI. Gameplay has its own
 # multitouch dispatch; consuming these prevents double actions and stolen focus.
 if event is InputEventMouse and event.device==-1:
  get_viewport().set_input_as_handled()
  return
 if event is InputEventScreenTouch and event.pressed:
  if finger_positions.has(event.index):
   get_viewport().set_input_as_handled()
   return
  finger_positions[event.index]=event.position
  for key in buttons:
   var b=buttons[key]
   if b.visible and b.get_global_rect().has_point(event.position):
    if not b.disabled:
     if key=="action" and action_id<0:
      action_id=event.index; held=g.mode in CONTINUOUS_TOOLS
      action_anchor=event.position
      repeat_time=GardenTools.GATHER_INTERVAL if g.mode=="harvest" else .3
     b.pressed.emit()
    get_viewport().set_input_as_handled()
    return
 if event is InputEventScreenDrag and finger_positions.has(event.index):
  # Web touch events can report another finger's relative movement when the
  # changedTouches order changes. Compute displacement from this ID's position.
  var movement: Vector2=event.position-finger_positions[event.index]
  finger_positions[event.index]=event.position
  if event.index==stick_id:
   stick=((event.position-origin)/radius).limit_length(1.0)
   if stick.length()<.12: stick=Vector2.ZERO
  elif event.index==look_id:
   var css_scale=display_size/get_viewport().get_visible_rect().size
   g.apply_mouse_look(movement*css_scale*1.7)
  elif event.index==action_id and held and look_id<0:
   # The same thumb holds the tool and turns the view; no third finger needed.
   var css_scale=display_size/get_viewport().get_visible_rect().size
   g.apply_mouse_look(movement*css_scale*1.7)
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if not enabled or blocked(): return
 if event is InputEventScreenTouch and event.pressed and not event.canceled:
  if event.position.distance_to(origin)<radius*1.5:
   # A second thumb in the movement zone must never become a looking finger.
   if stick_id<0:
    stick_id=event.index
    stick=((event.position-origin)/radius).limit_length(1.0)
  elif look_id<0:
   look_id=event.index
   look_anchor=event.position
  get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  reset_gestures()
  if is_instance_valid(g) and enabled and not g.smoke: g.save_game()

func act(repeating: bool=false) -> void:
 if blocked() or not g.hover_valid: return
 removed.clear()
 if g.mode=="remove":
  var index=g.aimed_plant()
  if index>=0:
   removed=g.planted[index].duplicate()
   if GardenContainers.is_contained(g.planted[index]):removed=GardenContainers.record(g.planted[index])
   removed.erase("node"); removed.erase("marker")
   removed["plant"]=true
  else:
   index=g.aimed_object()
   if index>=0:
    removed=g.objects[index].duplicate()
    removed["supported_pots"]=GardenAreaFurnishings.removal_snapshot(g,g.objects[index])
    removed.erase("node")
    removed["plant"]=false
 var count=g.planted.size()+g.objects.size()
 g.perform_action(repeating)
 if count==g.planted.size()+g.objects.size(): removed.clear()
 else: undo_time=12.0

func undo_remove() -> void:
 if removed.is_empty(): return
 var old=removed
 if old.plant:
  if old.has("container_uid"):
   var planter=GardenContainers.object(g,str(old.container_uid))
   if planter.is_empty() or not GardenContainers.can_plant(g,planter,int(old.container_slot),int(old.id),-1,str(old.get("form_uid",""))).is_empty():g.toast("Make room in that pocket before undoing.");return
   GardenContainers.restore_record(g,old)
   removed.clear();g.refresh_ui();g.toast("Back in its planting pocket.");return
  if not g.can_plant(old.id,old.pos,old.plot).is_empty(): g.toast("Make room in that spot before undoing."); return
  var p=g.add_plant(old.id,old.pos,old.plot,old.age,old.height_factor,float(old.get("orientation",0)),int(old.get("shape_seed",0)),str(old.get("form_uid","")))
  for key in ["water","stress","pruned","prune_cuts","treatments","watered_until","breeding_checked"]:
   if old.has(key):p[key]=old[key]
  g.refresh_plant(p)
 else:
  if not GardenAreaProgression.allowed(g,old.pos,true):return
  var occupied=g.objects.any(func(obj):return obj.pos.distance_to(old.pos)<.8 and not old.get("supported_pots",{}).has(obj.uid))
  if g.coins<old.price or occupied: g.toast("The refund and the original space are needed to undo."); return
  g.coins-=old.price
  g.add_object(old.kind,old.pos,old.price,old.fish,old.get("rotation",0.0),old.get("text","My garden"),Color.from_string(old.get("text_color","f1e5c7"),Color("f1e5c7")),old)
  var restored=g.objects.back()
  GardenAreaFurnishings.restore_collection(g,restored)
  GardenAreaFurnishings.restore_dependents(g,old.get("supported_pots",{}))
  if old.kind in GardenContainers.SPECS:
   for saved in g.workshop_state.nursery.duplicate():
    if saved.get("storage_source","")==old.uid:
     var slot=int(saved.get("storage_slot",-1))
     if GardenContainers.can_plant(g,restored,slot,int(saved.id)).is_empty():
      GardenContainers.replant(g,g.workshop_state.nursery.find(saved),restored,slot)
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
  choice.fit_to_longest_item=false
  choice.clip_text=true
  for title in entry[2]: choice.add_item(title)
  choice.select(maxi(0,values.find(g.settings[key])))
  choice.item_selected.connect(func(index): g.settings[key]=values[index]; configure(); g.save_game())
  g.list_box.add_child(choice)
 g.add_note("Auto graphics balances detail in fuller gardens. Choose Standard for full plant shadows, or set your preferred 3D resolution.")
 var handed=CheckButton.new()
 handed.text="Left-handed controls"
 handed.clip_text=true
 handed.tooltip_text=handed.text
 handed.button_pressed=g.settings.left_handed
 handed.custom_minimum_size.y=48
 handed.toggled.connect(func(value): g.settings.left_handed=value; last_size=Vector2.ZERO; g.save_game())
 g.list_box.add_child(handed)
 for entry in [["control_size","Touch control size",80,120,10],["touch_inset","Controls farther from the edges",0,100,10],["touch_height","Raise the bottom controls",0,120,10]]:
  var key=entry[0]
  g.add_note(entry[1])
  var slider=HSlider.new()
  slider.min_value=entry[2]; slider.max_value=entry[3]; slider.step=entry[4]
  slider.value=g.settings.get(key,0)
  slider.custom_minimum_size.y=48
  slider.value_changed.connect(func(value): g.settings[key]=value; last_size=Vector2.ZERO; apply_graphics())
  slider.drag_ended.connect(func(_changed): g.save_game())
  g.list_box.add_child(slider)
 g.add_note("Position adjustments apply on tablets and unfolded phones. Text stays the same size when you resize the controls. Hold Water, Gather, Rake or the hoe action and drag that thumb to look; release to stop.")

func welcome_page() -> void:
 GardenExperience.welcome(g)
