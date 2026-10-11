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
 await sign_editing(g,failures)
 for voice in g.ambient.players.values():voice.stop();voice.stream=null
 print("MENU_REBUILD_RESULT: ",JSON.stringify(failures))

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
