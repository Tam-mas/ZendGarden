extends RefCounted

static func settle(g) -> void:
 for frame in range(5):await g.get_tree().process_frame

static func capture(g, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("res://captures/menu-"+name+".png")

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.settings.request_notifications=false
 g.settings.controls="keyboard"
 g.get_window().size=Vector2i(1280,800)
 g.touch.configure()
 g.dismiss_request()
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.coins=1000
 g.day=20
 GardenMenus.visit(g,"Seeds")
 await settle(g)
 var cards=g.list_box.get_node("PlantCards")
 if cards.get_child_count()!=g.catalogue.size():failures.append("Default catalogue loses plants")
 var first=cards.get_child(0)
 if first.get_global_rect().position.y>g.side_panel.position.y+250:failures.append("Seed toolbar crowds out cards")
 if first.size.y>245:failures.append("Compact card has too much unused height: "+str(first.size))
 if g.detail_label.visible:failures.append("Permanent footer returned")
 await capture(g,"desktop-seeds")
 var picker=g.list_box.get_node("SeedBrowse/CollectionView")
 picker.item_selected.emit(1)
 if g.category!="Flowers" or g.list_box.get_node("SeedFilters").visible:failures.append("Quick plant type needs expanded filters")
 picker.item_selected.emit(0)
 await settle(g)
 first=g.list_box.get_node("PlantCards").get_child(0)
 first.get_node("PlantInfo").pressed.emit()
 await settle(g)
 if g.active_tab!="Seed details":failures.append("Desktop information button did not open details")
 g.touch.back_to_seeds()
 await settle(g)
 g.list_box.get_node("PlantCards").get_child(0).pressed.emit()
 if g.mode!="plant" or g.side_panel.visible:failures.append("Desktop quick planting changed")
 await settle(g)
 g.menu_utilities.get_node("SettingsMenu").pressed.emit()
 g.update_hud()
 await settle(g)
 if g.active_tab!="Settings" or not g.side_panel.visible:failures.append("Gear did not open Settings")
 if g.menu_utilities.position.y>=g.menu_tabs.position.y:failures.append("Settings and close icons must sit above the tabs")
 for child in g.list_box.get_children():
  if child is VBoxContainer and child.visible:failures.append("Settings should initially be collapsed")
 g.list_box.get_node("SettingsSound").pressed.emit()
 if not g.list_box.get_node("SoundOptions").visible:failures.append("Sound accordion did not open")
 var volume=g.list_box.get_node("SoundOptions/music_volume")
 volume.value=0
 if not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")):failures.append("Music slider did not apply immediately")
 g.list_box.get_node("SettingsControls").pressed.emit()
 if g.list_box.get_node("SoundOptions").visible or not g.list_box.get_node("ControlsOptions").visible:failures.append("Multiple settings categories expanded")
 g.list_box.get_node("SettingsControls").pressed.emit()
 if g.list_box.get_node("ControlsOptions").visible:failures.append("Settings cannot collapse again")
 g.list_box.get_node("SettingsSound").pressed.emit()
 await settle(g)
 await capture(g,"desktop-settings")
 GardenMenus.visit(g,"Shop")
 for section in ["Decor","Equipment","Tools","Bed care"]:
  g.menu_sections.shop=section;g.refresh_sidebar()
  await settle(g)
  if g.basket_total()>0 and g.list_box.get_children().any(func(c):return c is Label and c.text.begins_with("YOUR BASKET")):failures.append("Harvest inventory leaked into shop")
  if section=="Decor":await capture(g,"desktop-shop")
  if section=="Tools":
   var tools=g.list_box.get_node("ToolCards")
   if tools.get_child_count()!=5:failures.append("Tool cards lost an upgrade")
   var before_level=int(g.upgrades.can)
   var before_cost=g.coins
   tools.get_node("Tool_can").pressed.emit()
   if int(g.upgrades.can)!=before_level+1 or g.coins!=before_cost-(45+before_level*45):failures.append("Tool card does not buy the expected upgrade")
   await settle(g)
   await capture(g,"desktop-tools")
 g.menu_sections.shop="Bed care";g.refresh_sidebar()
 var space_link=g.list_box.get_children().filter(func(c):return c is Button and c.text=="More garden space & milestones")
 space_link[0].pressed.emit()
 if g.active_tab!="Guide" or not g.list_box.get_node("MoregardenspaceOptions").visible:failures.append("Bed care did not link to expanded garden space in Guide")
 g.orders=[{"person":"Test neighbour","plant":0,"count":2,"reward":24}]
 g.inventory={"0":5,"1":7}
 GardenMenus.visit(g,"Orders")
 await settle(g)
 var before=g.coins
 var deliver=g.list_box.get_children().filter(func(c):return c is Button and c.text=="Deliver request")
 if deliver.is_empty():failures.append("Ready request cannot be delivered")
 else:deliver[0].pressed.emit()
 if int(g.inventory["0"])!=3 or g.coins<=before:failures.append("Delivery changed inventory or reward rules")
 g.orders=[{"person":"Test neighbour","plant":0,"count":2,"reward":24}]
 g.menu_sections.orders="Basket";g.refresh_sidebar()
 var sell=g.list_box.get_children().filter(func(c):return c is Button and c.text.begins_with("Sell "))
 if sell.is_empty():failures.append("Basket cannot sell spare harvest")
 else:sell[0].pressed.emit()
 if int(g.inventory["0"])!=2 or int(g.inventory["1"])!=0:failures.append("Selling did not protect reserved harvest")
 g.menu_sections.orders="Requests";g.refresh_sidebar()
 await settle(g)
 await capture(g,"desktop-orders")
 GardenMenus.visit(g,"Guide")
 for topic in GardenMenus.GUIDE:
  g.menu_sections.guide=topic;g.refresh_sidebar()
  if g.list_box.get_child_count()<3:failures.append("Guide topic missing: "+topic)
 g.menu_sections.guide="";g.refresh_sidebar()
 await settle(g)
 g.list_box.get_node("GardenactionsSection").pressed.emit()
 if not g.list_box.get_node("GardenactionsOptions").visible:failures.append("Guide garden actions did not expand")
 g.list_box.get_node("GardenactionsSection").pressed.emit()
 g.list_box.get_node("CompanionsSection").pressed.emit()
 if not g.list_box.get_node("CompanionsOptions").visible:failures.append("Guide companions did not expand")
 g.list_box.get_node("CompanionsSection").pressed.emit()
 await capture(g,"desktop-guide")
 g.menu_utilities.get_node("CloseMenu").pressed.emit()
 if g.side_panel.visible:failures.append("Close icon did not return to the garden")
 for dimensions in [Vector2i(1024,768),Vector2i(768,1024),Vector2i(800,740),Vector2i(320,568)]:
  g.get_window().size=dimensions
  await settle(g)
  g.settings.controls="touch";g.touch.configure()
  for page in ["Seeds","Shop","Orders","Guide","Settings"]:
   GardenMenus.visit(g,page)
   await settle(g)
   var bounds=g.get_viewport().get_visible_rect()
   if g.menu_utilities.size.y>52:failures.append("Menu title and icon row grew too tall: "+page+str(dimensions))
   if not bounds.encloses(g.side_panel.get_global_rect()):failures.append("Menu overflows "+page+" "+str(dimensions)+" "+str(g.side_panel.get_global_rect()))
   if g.side_panel.position.x>20:failures.append("Menu no longer stays left")
   if dimensions.x>=700 and g.side_panel.size.x>430:failures.append("Touch menu expands across screen")
  for title in ["Sound","Controls","Display","Comfort & play","Save files","About"]:
   g.menu_sections.settings=title;g.refresh_sidebar()
   await settle(g)
   if not g.get_viewport().get_visible_rect().encloses(g.side_panel.get_global_rect()):failures.append("Expanded settings overflow: "+title+str(dimensions))
  if dimensions.x>=700:
   g.menu_sections.settings="Controls";g.refresh_sidebar()
   await settle(g)
   await capture(g,"touch-settings-%dx%d"%[dimensions.x,dimensions.y])
   GardenMenus.visit(g,"Seeds")
   await settle(g)
   await capture(g,"touch-seeds-%dx%d"%[dimensions.x,dimensions.y])
 await touch_browsing(g,failures)
 await sign_editing(g,failures)
 for voice in g.ambient.players.values():voice.stop();voice.stream=null
 print("MENU_REBUILD_RESULT: ",JSON.stringify(failures))

static func touch_browsing(g, failures: Array) -> void:
 var input=preload("res://tests/touch_controls.gd")
 g.get_window().size=Vector2i(1024,768)
 await settle(g)
 g.settings.controls="touch";g.settings.reduced_motion=true
 g.touch.configure()
 g.category="All";g.collection_query="";g.collection_filters=g.default_collection_filters()
 GardenMenus.visit(g,"Seeds")
 g.menu_scrollbox.scroll_vertical=0
 await settle(g)
 var card=g.list_box.get_node("PlantCards").get_child(0)
 var point=card.get_global_rect().get_center()
 var start_y=g.menu_scrollbox.scroll_vertical
 var yaw=g.yaw
 input.press(51,point)
 input.drag(51,point-Vector2(0,60),Vector2(0,-60))
 input.press(51,point-Vector2(0,60),false)
 await settle(g)
 if g.active_tab!="Seeds" or g.menu_scrollbox.scroll_vertical<=start_y+30:failures.append("Swiping a plant card did not scroll without opening it")
 if g.yaw!=yaw or g.touch.stick!=Vector2.ZERO:failures.append("Menu swipe leaked into garden controls")
 card=g.list_box.get_node("PlantCards").get_child(0)
 var star=card.get_node("Favourite")
 point=star.get_global_rect().get_center()
 var favourites=g.favourite_plants.duplicate()
 input.press(52,point)
 input.drag(52,point-Vector2(0,24),Vector2(0,-24))
 input.press(52,point-Vector2(0,24),false)
 await settle(g)
 if g.favourite_plants!=favourites:failures.append("Swiping over a favourite changed it")
 # A small natural finger wobble is still a tap, and opens details once.
 card=g.list_box.get_node("PlantCards").get_child(0)
 point=card.get_global_rect().get_center()
 var browse_position=g.menu_scrollbox.scroll_vertical
 input.press(53,point)
 input.drag(53,point+Vector2(2,2),Vector2(2,2))
 input.press(53,point+Vector2(2,2),false)
 await settle(g)
 if g.active_tab!="Seed details":
  failures.append("Normal card tap stopped opening details")
  return
 var portrait=g.list_box.get_node("PlantPortrait")
 point=portrait.get_global_rect().get_center()
 input.press(54,point);input.press(54,point,false,true)
 await settle(g)
 if not g.side_panel.visible:failures.append("Canceled portrait tap entered planting")
 input.press(55,point);input.press(55,point,false)
 await settle(g)
 if g.mode!="plant" or g.side_panel.visible:failures.append("Portrait tap did not jump into planting")
 g.touch.open_menu("Seeds")
 await settle(g)
 if absi(g.menu_scrollbox.scroll_vertical-browse_position)>3:failures.append("Returning from planting lost the collection position")
 # Locked plants use the same affordability gate for the image and action.
 var locked=g.catalogue.filter(func(p):return p.id not in g.unlocked_plants)[0]
 g.coins=0;g.touch.open_seed_details(locked)
 await settle(g)
 if not g.list_box.get_node("PlantPortrait").disabled or not g.list_box.get_node("PlantThisSeed").disabled:failures.append("Portrait bypasses seed affordability")
 var old_selected=g.selected
 point=g.list_box.get_node("PlantPortrait").get_global_rect().get_center()
 input.press(56,point);input.press(56,point,false)
 if g.selected!=old_selected or not g.side_panel.visible:failures.append("Unaffordable portrait bought seeds")
 g.coins=int(locked.price)+5;g.refresh_sidebar()
 await settle(g)
 point=g.list_box.get_node("PlantPortrait").get_global_rect().get_center()
 input.press(63,point);input.press(63,point,false)
 if locked.id not in g.unlocked_plants or g.coins!=5 or g.selected!=locked.id or g.side_panel.visible:failures.append("Portrait discovery did not charge once and enter planting")
 # Real text and request buttons scroll too, without delivering on release.
 g.coins=1000;g.orders=[];g.inventory={"0":100}
 for index in range(12):g.orders.append({"person":"Neighbour %d"%index,"plant":0,"count":2,"reward":24})
 g.menu_sections.orders="Requests";GardenMenus.visit(g,"Orders")
 await settle(g)
 var deliver=g.list_box.get_children().filter(func(c):return c is Button and c.text=="Deliver request")[0]
 point=deliver.get_global_rect().get_center()
 var coins=g.coins
 input.press(57,point)
 input.drag(57,point-Vector2(0,30),Vector2(0,-30))
 input.press(57,point-Vector2(0,30),false)
 await settle(g)
 if g.menu_scrollbox.scroll_vertical<20 or g.coins!=coins or int(g.inventory["0"])!=100:failures.append("Request-button swipe failed or delivered an order")
 # Settings sliders and text fields retain their own direct manipulation.
 g.menu_sections.settings="Sound";GardenMenus.visit(g,"Settings")
 await settle(g)
 var slider=g.list_box.get_node("SoundOptions/music_volume")
 var old_volume=slider.value
 point=slider.get_global_rect().position+Vector2(slider.size.x*.25,slider.size.y*.5)
 input.press(58,point)
 input.drag(58,point+Vector2(slider.size.x*.4,0),Vector2(slider.size.x*.4,0))
 input.press(58,point+Vector2(slider.size.x*.4,0),false)
 if is_equal_approx(slider.value,old_volume) or g.menu_scrollbox.scroll_vertical!=0:failures.append("Menu scrolling stole a volume-slider drag: %s to %s, scroll %s, rect %s"%[old_volume,slider.value,g.menu_scrollbox.scroll_vertical,slider.get_global_rect()])
 GardenMenus.visit(g,"Seeds")
 await settle(g)
 g.menu_scrollbox.scroll_vertical=0
 await settle(g)
 var search=g.list_box.get_node("SeedSearch")
 point=search.get_global_rect().get_center()
 input.press(59,point);input.press(59,point,false)
 if not search.has_focus():failures.append("Menu scrolling stole the search field tap")
 # A mouse/trackpad press-and-drag also works with the Touch controls setting.
 g.menu_scrollbox.scroll_vertical=500
 await settle(g)
 point=g.menu_scrollbox.get_global_rect().get_center()
 var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=point;mouse.pressed=true
 g.menu_scrollbox._input(mouse)
 var motion=InputEventMouseMotion.new();motion.position=point-Vector2(0,80)
 g.menu_scrollbox._input(motion)
 mouse.pressed=false;g.menu_scrollbox._input(mouse)
 if g.menu_scrollbox.scroll_vertical<550:failures.append("Mouse drag in touch mode cannot scroll")
 g.settings.reduced_motion=false
 input.press(60,point)
 input.drag(60,point-Vector2(0,60),Vector2(0,-60))
 input.press(60,point-Vector2(0,60),false)
 var released_at=g.menu_scrollbox.scroll_vertical
 g.menu_scrollbox._process(.08)
 if g.menu_scrollbox.scroll_vertical<=released_at:failures.append("A flick has no scroll momentum")
 input.press(61,point);input.press(61,point,false)
 if g.active_tab!="Seeds" or g.menu_scrollbox.scrolling:failures.append("Tapping a gliding list selected a card instead of stopping")
 # Canceling a gesture or rebuilding a page stops momentum and pending taps.
 input.press(62,point)
 input.drag(62,point-Vector2(0,60),Vector2(0,-60))
 input.press(62,point-Vector2(0,60),false,true)
 released_at=g.menu_scrollbox.scroll_vertical
 g.menu_scrollbox._process(.1)
 if g.menu_scrollbox.scroll_vertical!=released_at or g.active_tab!="Seeds":failures.append("Canceled swipe kept moving or selected a card")
 g.menu_scrollbox.cancel_gesture()

static func sign_editing(g, failures: Array) -> void:
 g.get_window().size=Vector2i(1280,800)
 g.set_mode("walk")
 g.rest_kind="";g.rest_object=null
 var point=GardenTerrain.point(Vector3(0,0,2))
 g.add_object("sign",point,15,false,.35,"Before editing",Color("f1e5c7"))
 var index=g.objects.size()-1
 var sign=g.objects[index]
 var lettering=sign.node.get_node("FrontText").global_position
 for control in ["keyboard","touch"]:
  g.settings.controls=control;g.touch.configure();GardenMenus.close(g)
  g.player.position=point+Vector3(0,.1,2)
  g.camera.global_position=point+Vector3(0,1.62,2)
  g.camera.look_at(lettering)
  await g.get_tree().physics_frame
  await g.get_tree().physics_frame
  if GardenLeisure.sign_target(g)!=index:failures.append("Aiming at a nearby sign does not select it: "+control)
  GardenLeisure.update(g)
  g.touch._process(0)
  if control=="keyboard":
   # The headless display does not keep desktop pointer capture; the rendered
   # run checks visibility as well as the prompt and the real E-key action.
   if g.leisure_panel.get_child(0).get_child(1).text!="Edit sign · E" or (DisplayServer.get_name()!="headless" and not g.leisure_panel.visible):failures.append("Desktop sign prompt is missing")
   var key=InputEventKey.new();key.physical_keycode=KEY_E;key.pressed=true
   g._unhandled_input(key)
  else:
   if not g.touch.buttons.greet.visible or g.touch.buttons.greet.text!="Edit sign":failures.append("Touch sign action is missing")
   g.touch.buttons.greet.pressed.emit()
  if g.active_tab!="Sign" or not g.side_panel.visible or g.editing_sign!=index:failures.append("Sign interaction did not open its editor: "+control)
  var field=g.list_box.get_node("SignText")
  field.text="Updated with "+control;field.text_changed.emit(field.text)
  g.sign_color=Color("b4d6ff")
  var before=g.coins
  g.finish_sign_editor()
  if g.side_panel.visible or sign.text!="Updated with "+control or sign.text_color!="b4d6ff" or g.coins!=before:failures.append("Editing a sign changed cost, lost text or failed to close")
  if sign.node.get_node("BackText").text!=sign.text or not is_equal_approx(sign.rotation,.35):failures.append("Editing changed rotation or lost the back lettering")
 # Aiming away, standing too far off, and using a tool must not edit a sign.
 g.camera.look_at(g.camera.global_position+Vector3.RIGHT)
 if GardenLeisure.sign_target(g)>=0:failures.append("Looking away still selects a sign")
 g.player.position=point+Vector3(0,.1,5)
 g.camera.global_position=point+Vector3(0,1.62,5);g.camera.look_at(lettering)
 if GardenLeisure.sign_target(g)>=0:failures.append("A distant sign can be edited")
 g.player.position=point+Vector3(0,.1,2)
 g.camera.global_position=point+Vector3(0,1.62,2);g.camera.look_at(lettering)
 g.mode="water"
 if GardenLeisure.sign_target(g)>=0:failures.append("Sign editing steals the watering action")
 g.mode="walk"
 # The nearer board blocks the first; the ray must select the visible sign.
 g.add_object("sign",point+Vector3(0,0,.4),15,false,0,"In front",Color.WHITE)
 var front=g.objects.back()
 g.camera.look_at(front.node.get_node("FrontText").global_position)
 await g.get_tree().physics_frame
 await g.get_tree().physics_frame
 if GardenLeisure.sign_target(g)!=g.objects.size()-1:failures.append("Editing selects a sign behind another sign")
