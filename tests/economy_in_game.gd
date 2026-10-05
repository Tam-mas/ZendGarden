extends RefCounted

static func run(g, failures: Array) -> void:
 var old_path=g.SAVE_PATH
 var was_processing=g.is_processing()
 var old_dimensions=g.get_viewport().size
 var old_loaded=g.loaded_data
 g.set_process(false)
 g.SAVE_PATH="user://economy-flow-test.json"
 g.save_game()
 var original=FileAccess.get_file_as_bytes(g.SAVE_PATH)
 var old_paths=g.clean_paths.duplicate()
 var old_widths=g.path_widths.duplicate()
 var lawn=g.world_root.get_node_or_null("MeadowGrass")
 var lawn_buffer=lawn.multimesh.buffer if lawn else PackedFloat32Array()
 var old_rake=g.upgrades.rake
 var old_mode=g.mode
 g.dismiss_request()
 for i in range(GardenEconomy.MODES.size()):
  g.side_panel.hide()
  g.open_sidebar("Settings")
  var choice=g.list_box.get_node_or_null("PetalRate") as OptionButton
  if not choice or choice.item_count!=3:
   failures.append("Petal earnings selector missing from Settings")
   break
  choice.select(i)
  choice.item_selected.emit(i)
  var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
  if g.settings.petal_rate!=GardenEconomy.MODES[i] or saved.settings.petal_rate!=GardenEconomy.MODES[i]:
   failures.append("Settings selection was not applied and saved")
  g.petal_remainder=0
  g.orders=[{"person":"Test neighbour","plant":0,"count":2,"reward":24}]
  g.inventory={"0":12}
  var before=g.coins
  # Ten spare Cosmos sell for 60 at the original rate; keep two for the order.
  g.sell_harvest()
  var expected=[60,36,18][i]
  if g.coins!=before+expected or int(g.inventory.get("0",0))!=2:
   failures.append("Harvest rate or reserved order items incorrect")
  g.open_sidebar("Orders")
  var reward=GardenEconomy.preview(g,24)
  if not g.list_box.get_children().any(func(control):return control is Button and control.text=="Deliver   +%d petals"%reward):
   failures.append("Order button does not show the selected rate")
  before=g.coins
  g.fulfill_order(0)
  if g.coins!=before+reward or int(g.inventory.get("0",-1))!=0:
   failures.append("Order paid the wrong amount or kept its items")
  g.fulfill_order(0)
  if g.coins!=before+reward:failures.append("Order paid twice after scaling")
 # Removal remains a full refund, including a saved fraction on Hard.
 g.settings.petal_rate="hard"
 g.petal_remainder=80
 var spot=GardenTerrain.point(Vector3(-7,0,8))
 g.add_object("stone",spot,3)
 var stone=g.objects.back()
 g.mode="remove";g.hover_target=-1;g.hover_object=stone.node
 g.hover_cell=spot;g.hover_valid=true;g.action_cooldown=0
 var before=g.coins
 g.perform_action()
 if stone in g.objects or g.coins!=before+3 or g.petal_remainder!=80:
  failures.append("Hard difficulty reduced a refund or changed its fraction")
 # Find clear lawn and check the actual raking award, including the raw daily cap.
 var raked=false
 g.upgrades.rake=0;g.rake_petals=0;g.petal_remainder=80
 for x in range(-7,25):
  if raked:break
  for z in range(-24,9):
   var point=Vector3(x,0,z)
   var key="%d:%d"%[x,z]
   if key in g.clean_paths:continue
   g.hover_cell=point
   var paths_before=g.clean_paths.size()
   before=g.coins
   GardenCare.rake(g)
   if g.clean_paths.size()>paths_before:
    if g.coins!=before+1 or g.petal_remainder!=10 or g.rake_petals!=1:
     failures.append("Raking did not scale found petals or preserve the raw daily cap")
    g.raked_nodes[key].queue_free()
    g.raked_nodes.erase(key)
    raked=true
    break
 if not raked:failures.append("No clear lawn found for petal raking test")
 g.clean_paths=old_paths;g.path_widths=old_widths;g.upgrades.rake=old_rake
 if lawn and not lawn_buffer.is_empty():lawn.multimesh.buffer=lawn_buffer
 # Actual save/reload carries the choice and fractional earnings.
 g.settings.petal_rate="hard";g.petal_remainder=70
 var balance=g.coins
 g.save_game()
 g.settings.petal_rate="easy";g.petal_remainder=0;g.coins=0
 g.smoke=false;g.load_game();g.smoke=true
 if g.settings.petal_rate!="hard" or g.petal_remainder!=70 or g.coins!=balance:
  failures.append("Save reload lost the rate, fraction or existing balance")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if GardenSaveFormat.read(JSON.stringify(saved).to_utf8_buffer(),g.catalogue.size(),g.furniture.map(func(item):return item.kind)).has("error"):
  failures.append("Actual garden with petal settings rejected by save upload")
 saved.settings.erase("petal_rate");saved.erase("petal_remainder")
 GardenSaveFiles.write_atomic(g.SAVE_PATH,JSON.stringify(saved).to_utf8_buffer())
 g.smoke=false;g.load_game();g.smoke=true
 if g.settings.petal_rate!="easy" or g.petal_remainder!=0 or g.coins!=balance:
  failures.append("Loading a legacy garden changed its balance or earnings")
 # Confirm the real selector fits desktop and narrow touch Settings layouts.
 for size in [Vector2i(1280,800),Vector2i(390,844),Vector2i(320,568),Vector2i(667,375)]:
  g.get_viewport().size=size
  g.settings.controls="touch" if size.x<700 else "keyboard"
  g.touch.configure()
  g.side_panel.hide()
  g.open_sidebar("Settings")
  await g.get_tree().process_frame
  await g.get_tree().process_frame
  var choice=g.list_box.get_node_or_null("PetalRate") as OptionButton
  if not choice or not choice.is_visible_in_tree() or choice.size.x>g.list_box.size.x+1 or choice.size.y<(48 if size.x<700 else 38):
   failures.append("Petal selector does not fit Settings at "+str(size))
  elif choice:
   var scroll=g.list_box.get_parent() as ScrollContainer
   scroll.ensure_control_visible(choice)
   await g.get_tree().process_frame
   if not scroll.get_global_rect().grow(1).encloses(choice.get_global_rect()):
    failures.append("Petal selector cannot scroll fully into view at "+str(size))
  if DisplayServer.get_name()!="headless" and "--economy-test" in OS.get_cmdline_user_args():
   await RenderingServer.frame_post_draw
   DirAccess.make_dir_recursive_absolute("res://captures/economy")
   g.get_viewport().get_texture().get_image().save_png("res://captures/economy/settings-%dx%d.png"%[size.x,size.y])
 GardenSaveFiles.write_atomic(g.SAVE_PATH,original)
 g.smoke=false;g.load_game();g.smoke=true
 g.loaded_data=old_loaded
 g.get_viewport().size=old_dimensions
 g.touch.configure()
 g.mode=old_mode
 g.refresh_ui()
 DirAccess.remove_absolute(g.SAVE_PATH)
 g.SAVE_PATH=old_path
 g.set_process(was_processing)
