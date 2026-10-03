extends RefCounted

static func image(g, name: String) -> void:
 for i in range(6): await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://captures/plant-improvements")
 g.get_viewport().get_texture().get_image().save_png("res://captures/plant-improvements/"+name+".png")

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.settings.intro_seen=true
 g.settings.controls="keyboard"
 g.settings.request_notifications=false
 g.request_popup_time=0
 g.unlocked_plants=range(GardenCatalogue.ROWS.size())
 g.day=7;g.clock_time=.4;g.coins=500
 g.player.position=GardenTerrain.point(Vector3(0,0,5))+Vector3(0,.1,0)
 g.yaw=0;g.pitch=.15
 g.update_camera(0);g.update_lighting()
 g.active_tab="Seeds";g.category="All"
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.side_panel.show();g.refresh_ui()
 var query=g.list_box.get_node("SeedSearch")
 var succulent_button: Button
 for button in g.list_box.get_node("SeedCategories").get_children():
  if button.get_meta("category","")=="Cacti & succulents":succulent_button=button
 if succulent_button==null:failures.append("New category button missing")
 else:
  succulent_button.pressed.emit()
  if GardenSeedCollection.matching(g).size()!=20 or g.list_box.get_node("PlantCards").get_child_count()!=20:failures.append("New category does not show twenty seed cards")
  await image(g,"succulent-category")
 g.category="All"
 query.text="rose";query.text_changed.emit("rose")
 if GardenSeedCollection.matching(g).size()!=8: failures.append("Actual seed search missed rose varieties and black rose aeonium")
 await image(g,"catalogue-search")
 g.collection_filters_open=true;g.refresh_sidebar()
 await image(g,"catalogue-filters")
 g.active_tab="Shop";g.refresh_sidebar()
 if g.list_box.get_node("OrnamentCards").get_child_count()!=GardenCatalogue.furnishings().size():failures.append("Shop cards missing ornaments")
 # Scroll to ornaments using the real scroll container.
 g.list_box.get_parent().scroll_vertical=600
 await image(g,"ornament-shop")
 g.side_panel.hide();g.set_mode("move")
 g.selected_layer=1
 var target=g.add_plant(0,GardenTerrain.point(Vector3(0,0,1.2)),0,1,1,.6,340)
 var tree=g.add_plant(29,GardenTerrain.point(Vector3(.15,0,1.2)),0,100,1,.2,523)
 g.hover_valid=true;g.hover_target=g.planted.find(target);g.hover_cell=target.pos;g.hover_plot=0
 g.update_hud();GardenPlantInspector.update(g)
 if g.highlighted_plant!=target.node:failures.append("Move target differs from highlighted plant")
 # A missing selected layer falls back to the displayed plant, not layer order.
 g.selected_layer=2
 if g.aimed_plant()!=g.hover_target:failures.append("Missing selected layer changes the action target")
 await image(g,"plant-inspector")
 # Trigger the actual Move dispatcher and verify it picks the displayed plant.
 g.action_cooldown=0;g.perform_action()
 if g.moved_index!=g.planted.find(target):failures.append("Move picked a different plant from the inspector")
 g.set_mode("walk");g.side_panel.hide()
 g.set_mode("plant");g.selected=0
 g.update_placement_preview("p0")
 await image(g,"plant-preview")
 g.set_mode("walk");g.side_panel.hide()
 for frame in range(4):await g.get_tree().process_frame
 g.selected_layer=3;g.hover_target=g.planted.find(tree);GardenPlantInspector.update(g)
 if not g.inspector_label.text.contains("Canopy"):failures.append("Layer switching leaves stale inspector text")
 g.set_mode("move");g.selected_layer=1
 g.hover_target=g.planted.find(target);g.hover_valid=true
 GardenPlantInspector.update(g)
 g.settings.controls="touch";g.touch.configure();g.touch.layout()
 g.get_window().size=Vector2i(390,844)
 for i in range(8):await g.get_tree().process_frame
 g.update_hud();GardenPlantInspector.update(g)
 g.set_mode("walk")
 g.hover_target=g.planted.find(target);g.hover_valid=true
 GardenPlantInspector.update(g)
 g.touch._process(0)
 if not g.touch.buttons.layer.visible:failures.append("Touch inspection cannot switch plant layers")
 g.set_mode("move");g.hover_target=g.planted.find(target);g.hover_valid=true
 GardenPlantInspector.update(g)
 await image(g,"touch-inspector")
 g.active_tab="Seeds";g.collection_query="";g.category="All";g.collection_filters_open=false
 g.open_sidebar("Seeds")
 g.list_box.get_parent().scroll_vertical=0
 await image(g,"touch-catalogue")
 g.collection_filters_open=true;g.refresh_sidebar()
 g.list_box.get_parent().scroll_vertical=0
 await image(g,"touch-filters")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if saved.version!=2 or not saved.plants.back().has("shape_seed"):failures.append("In-game save lacks stable plant appearance")
 await verify_readable_layouts(g,failures)
 await preload("res://tests/structure_removal.gd").run(g,failures)

static func verify_readable_layouts(g, failures: Array) -> void:
 var samples=[["keyboard",Vector2i(1280,800)],["keyboard",Vector2i(1024,768)],["keyboard",Vector2i(900,600)],["touch",Vector2i(320,568)],["touch",Vector2i(390,844)],["touch",Vector2i(844,390)]]
 for sample in samples:
  g.settings.controls=sample[0]
  g.get_window().size=sample[1]
  g.touch.configure()
  for page in ["Seeds","Shop","Orders","Settings","Guide"]:
   g.active_tab=page;g.category="All";g.collection_filters_open=false
   g.side_panel.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
   g.refresh_ui()
   # This test pauses the garden's process loop. Match the live game's repeated
   # HUD layout updates while deferred text wrapping and containers settle.
   for frame in range(6):
    g.update_hud()
    if g.touch_active():g.touch.layout()
    await g.get_tree().process_frame
   g.update_hud()
   if g.touch_active():g.touch.layout()
   var bounds=g.get_viewport().get_visible_rect()
   if not bounds.encloses(g.side_panel.get_global_rect()):failures.append("Readable menu escapes viewport: "+str(sample)+page+" bounds "+str(g.side_panel.get_global_rect())+" minimum "+str(g.side_panel.get_combined_minimum_size()))
   if not g.touch_active():
    if g.side_panel.size.x>GardenInterface.SIDEBAR_WIDTH+1:failures.append("Desktop sidebar exceeds compact width: "+page+str(g.side_panel.size))
    if g.side_panel.get_global_rect().intersects(g.hud_tools.get_global_rect()):failures.append("Desktop menu overlaps tools: "+str(sample))
    if not bounds.encloses(g.hud_tools.get_global_rect()):failures.append("Desktop toolbar escapes viewport: "+str(sample))
    if g.tip_label.get_global_rect().intersects(g.hud_tools.get_global_rect()):failures.append("Desktop instructions overlap tools: "+str(sample))
    if page=="Seeds" and g.list_box.get_node("SeedSearch").get_theme_font_size("font_size")<16:failures.append("Desktop search text shrinks below readable size")
   if page=="Seeds":
    for card in g.list_box.get_node("PlantCards").get_children():
     if not card is Button:continue
     var content=card.get_child(0)
     for caption in content.get_children():
      if caption is Label and not card.get_global_rect().grow(1).encloses(caption.get_global_rect()):
       failures.append("Card caption is clipped: "+caption.text+str(sample));break
   await image(g,"readable-%s-%dx%d-%s"%[sample[0],sample[1].x,sample[1].y,page.to_lower()])
   if page=="Seeds":
    g.category="Cacti & succulents";g.refresh_sidebar()
    for frame in range(4):await g.get_tree().process_frame
    if not bounds.encloses(g.side_panel.get_global_rect()):failures.append("Succulent category escapes compact menu: "+str(sample))
    if g.list_box.get_node("PlantCards").get_child_count()!=20:failures.append("Responsive succulent category lost cards: "+str(sample))
    await image(g,"succulents-%s-%dx%d"%[sample[0],sample[1].x,sample[1].y])
  if not g.touch_active():
   g.side_panel.hide();g.set_mode("walk")
   g.player.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.1,0)
   g.yaw=0;g.pitch=atan2(g.player.position.y+1.62-GardenTerrain.point(Vector3.ZERO).y,g.player.position.z)
   g.update_camera(0);g.update_hover();g.update_hud()
   if not g.hover_valid or g.hover_cell.distance_to(GardenTerrain.point(Vector3.ZERO))>.1:failures.append("Desktop resize changed crosshair targeting: "+str(sample))
