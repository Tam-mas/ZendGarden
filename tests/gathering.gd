extends RefCounted

static func mouse(down: bool) -> void:
 var event=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
 Input.parse_input_event(event)
 Input.flush_buffered_events()

static func run(g, failures: Array) -> void:
 var old_planted=g.planted;var old_wild=g.wild_plants
 var old_settings=g.settings.duplicate();var old_upgrades=g.upgrades.duplicate()
 var old_coins=g.coins;var old_day=g.day;var old_inventory=g.inventory.duplicate()
 g.planted=[];g.wild_plants=[];g.inventory={}
 g.set_process(false)
 g.photo_mode=false;g.day_transition=false
 g.settings.controls="keyboard";g.touch.configure();g.touch.close_menu();g.dismiss_request()
 g.upgrades.gather=0;g.upgrades.shears=2
 g.set_mode("harvest");g.hover_valid=true;g.hover_plot=0
 var center=GardenTerrain.point(Vector3.ZERO)
 var a=g.add_plant(0,center,0,float(g.catalogue[0].days))
 var b=g.add_plant(12,center,0,float(g.catalogue[12].days))
 b.pos.y+=2;b.node.position=b.pos
 var growing=g.add_plant(20,center,0,.5)
 var near=g.add_plant(1,GardenTerrain.point(Vector3(.9,0,0)),0,float(g.catalogue[1].days))
 var far=g.add_plant(2,GardenTerrain.point(Vector3(1.3,0,0)),0,float(g.catalogue[2].days))
 var wild_node=Node3D.new();g.world_root.add_child(wild_node)
 wild_node.position=center+Vector3(.3,0,.3)
 GardenCare.register_wild(g,wild_node,"gather-test",3)
 g.wild_collection.erase("gather-test")
 g.hover_cell=center;g.action_cooldown=0
 g.perform_action()
 if g.basket_total()!=3 or a.age>=g.catalogue[0].days or b.age>=g.catalogue[12].days:failures.append("Gather did not collect all ready layers and border plants")
 if growing.age!=.5 or near.age!=g.catalogue[1].days or far.age!=g.catalogue[2].days:failures.append("Gather changed unready or out-of-range plants")
 var message=g.toast_label.text
 g.action_cooldown=0;g.perform_action(true)
 if g.basket_total()!=3 or g.toast_label.text!=message:failures.append("Repeated gathering duplicated yield or spammed empty messages")
 if not is_equal_approx(GardenTools.gather_width(g),1.3):failures.append("Pruner upgrades incorrectly change Gather reach")
 # Upgrade price, unlock day, footprint, cap and persistence.
 g.coins=500;g.day=1;g.buy_tool("gather")
 if g.upgrades.gather!=0 or g.coins!=500:failures.append("Gather upgrade bypassed unlock day")
 g.day=3;g.coins=44;g.buy_tool("gather")
 if g.upgrades.gather!=0 or g.coins!=44:failures.append("Gather upgrade bypassed cost")
 g.coins=500;g.buy_tool("gather")
 if g.upgrades.gather!=1 or g.coins!=455 or not is_equal_approx(GardenTools.gather_width(g),2.1):failures.append("First Gather upgrade incorrect")
 g.action_cooldown=0;g.perform_action()
 if near.age>=g.catalogue[1].days or far.age!=g.catalogue[2].days:failures.append("First Gather upgrade footprint incorrect")
 g.buy_tool("gather")
 if g.upgrades.gather!=1 or g.coins!=455:failures.append("Master Gather unlocked early")
 g.day=18;g.buy_tool("gather")
 if g.upgrades.gather!=2 or g.coins!=365 or not is_equal_approx(GardenTools.gather_width(g),2.9):failures.append("Master Gather upgrade incorrect")
 g.action_cooldown=0;g.perform_action()
 if far.age>=g.catalogue[2].days:failures.append("Master Gather did not reach farther plant")
 g.buy_tool("gather")
 if g.upgrades.gather!=2 or g.coins!=365:failures.append("Gather upgrade exceeded purchased cap")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 var probe=load("res://scripts/garden.gd").new()
 probe.SAVE_PATH=g.SAVE_PATH;probe.load_game()
 if probe.upgrades.get("gather",-1)!=2:failures.append("Gather upgrade did not survive reload")
 probe.free()
 saved.upgrades.erase("gather")
 var legacy_path=g.SAVE_PATH+".gather-legacy-test"
 var file=FileAccess.open(legacy_path,FileAccess.WRITE);file.store_string(JSON.stringify(saved));file.close()
 probe=load("res://scripts/garden.gd").new();probe.SAVE_PATH=legacy_path;probe.load_game()
 if probe.upgrades.get("gather",-1)!=0:failures.append("Older save did not default to base Gather reach")
 probe.free();DirAccess.remove_absolute(legacy_path)
 # Keep the mouse held while moving the aim; release, menus and photo mode stop it.
 g.upgrades.gather=0
 g.hover_cell=center;g.action_cooldown=0;a.age=float(g.catalogue[0].days)
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 mouse(true)
 GardenTools.repeat_mouse(g)
 if a.age>=g.catalogue[0].days:failures.append("Held mouse does not gather")
 near.age=float(g.catalogue[1].days);g.hover_cell=near.pos;g.action_cooldown=0
 GardenTools.repeat_mouse(g)
 if near.age>=g.catalogue[1].days:failures.append("Moving held Gather aim did not collect another plant")
 mouse(false)
 near.age=float(g.catalogue[1].days);g.action_cooldown=0;GardenTools.repeat_mouse(g)
 if near.age!=g.catalogue[1].days:failures.append("Gather continued after mouse release")
 g.hover_valid=false;mouse(true);g.hover_valid=true
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;GardenTools.repeat_mouse(g)
 if near.age!=g.catalogue[1].days:failures.append("Gather continued in menus")
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;g.photo_mode=true;GardenTools.repeat_mouse(g)
 if near.age!=g.catalogue[1].days:failures.append("Gather continued in photo mode")
 g.photo_mode=false;g.day_transition=true;GardenTools.repeat_mouse(g)
 if near.age!=g.catalogue[1].days:failures.append("Gather continued during day transition")
 g.day_transition=false;mouse(false)
 # Touch repeats through the same readiness and inventory rules.
 g.settings.controls="touch";g.touch.configure();g.touch.close_menu()
 g.hover_cell=near.pos;g.hover_valid=true;g.action_cooldown=0
 g.touch._process(0)
 var action_pos=g.touch.buttons.action.get_global_rect().get_center()
 preload("res://tests/touch_controls.gd").press(9,action_pos)
 near.age=float(g.catalogue[1].days);g.action_cooldown=0
 g.touch.repeat_time=0;g.touch._process(.2)
 if near.age>=g.catalogue[1].days:failures.append("Holding touch Gather does not repeat")
 preload("res://tests/touch_controls.gd").press(9,action_pos,false)
 near.age=float(g.catalogue[1].days);g.action_cooldown=0
 g.touch._process(.2)
 if near.age!=g.catalogue[1].days:failures.append("Touch Gather continued after release")
 g.touch.reset_gestures()
 for p in g.planted:p.node.queue_free();p.marker.queue_free()
 wild_node.queue_free();g.wild_collection.erase("gather-test")
 g.planted=old_planted;g.wild_plants=old_wild;g.inventory=old_inventory
 g.upgrades=old_upgrades;g.coins=old_coins;g.day=old_day
 g.settings=old_settings;g.touch.configure();g.set_mode("walk");g.set_process(true)
 print("GATHERING_RESULT: ",failures)
