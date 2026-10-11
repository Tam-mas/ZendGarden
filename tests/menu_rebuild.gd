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
 for section in ["Decor","Tools","Bed care","Equipment","Owned"]:
  g.menu_sections.shop=section;g.refresh_sidebar()
  await settle(g)
  if g.basket_total()>0 and g.list_box.get_children().any(func(c):return c is Label and c.text.begins_with("YOUR BASKET")):failures.append("Harvest inventory leaked into shop")
  if section=="Decor":await capture(g,"desktop-shop")
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
 for voice in g.ambient.players.values():voice.stop();voice.stream=null
 print("MENU_REBUILD_RESULT: ",JSON.stringify(failures))
