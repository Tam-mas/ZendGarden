extends RefCounted

static func check(value: bool, failures: Array, message: String) -> void:
 if not value:failures.append(message)

static func press(g, text: String) -> bool:
 for button in g.welcome.find_children("*","Button",true,false):
  if button.text==text and not button.disabled:button.pressed.emit();return true
 return false

static func run(g, failures: Array) -> void:
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.dismiss_request();g.side_panel.hide()
 for p in g.planted:p.node.queue_free();p.marker.queue_free()
 g.planted.clear();g.plant_index.invalidate()
 g.breeding_state=GardenPlantBreeding.initial_state();g.workshop_state=GardenWorkshop.initial_state()
 g.workshop_state.resources.starter_mix=12;g.day=1;g.coins=1000
 var id=192
 var parent=g.add_plant(id,Vector3.ZERO,0,float(g.catalogue[id].days)*.4,1.0,0,425)
 GardenPlantBreeding.observe(g,parent)
 var uid=str(parent.get("form_uid",""))
 check(not uid.is_empty(),failures,"Live garden did not reveal the first discovery")
 parent.age=float(g.catalogue[id].days);GardenPlantBreeding.observe(g,parent);g.refresh_plant(parent,false)
 g.add_object("potting_bench",Vector3(-4,0,1),75)
 var bench=g.objects.back()
 g.breeding_tab="Propagate";g.breeding_selected=uid;GardenWorkshop.open(g,bench.uid)
 check(press(g,"Prepare cutting"),failures,"Live bench cannot prepare a cutting")
 check(g.breeding_state.jobs.size()==1,failures,"Bench button did not queue a propagation")
 GardenWorkshop.close(g)
 g.advance_growth();g.advance_growth()
 check(g.breeding_state.nursery.size()==1,failures,"Actual garden mornings did not establish the cutting")
 g.breeding_tab="Nursery";GardenWorkshop.open(g,bench.uid)
 var name=g.welcome.find_child("CultivarName0",true,false) as LineEdit
 check(name!=null,failures,"Established cutting has no naming field")
 if name:name.text="Silver Bells"
 check(press(g,"Register this cultivar"),failures,"Live naming action failed")
 check(GardenPlantBreeding.form(g,uid).registered,failures,"Bench registration did not unlock the cultivar")
 GardenWorkshop.close(g);GardenPlantBreeding.choose(g,uid)
 g.hover_cell=GardenTerrain.point(Vector3(1.15,0,0));g.hover_plot=0;g.hover_valid=true;g.action_cooldown=0
 g.hover_container_uid="";g.hover_object=null;g.hover_target=-1
 var count=g.planted.size()
 g.update_placement_preview("p"+str(id));g.perform_action()
 check(g.planted.size()==count+1,failures,"Live custom planting was blocked: "+g.can_plant(id,g.hover_cell,0))
 if g.planted.size()>count:
  var clone=g.planted.back()
  check(clone.get("form_uid","")==uid and clone.height_factor==1.0,failures,"Plant action lost cultivar traits")
  GardenContainers.store(g,clone)
  check(g.workshop_state.nursery.back().get("form_uid","")==uid,failures,"Live stored cultivar lost identity")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(GardenSaveFormat.valid(saved,g.catalogue.size(),g.furniture.map(func(item):return str(item.kind))),failures,"Live garden cultivar save is not importable")
 g.set_mode("walk");g.side_panel.hide()
 GardenBreedingUI.open_library(g)
 check(g.welcome.find_child("CultivarPreview",true,false)!=null,failures,"My cultivars has no live plant preview")
 GardenWorkshop.close(g)
 # Drain audio playback before a fast headless exit; fixed-FPS test mornings
 # can otherwise finish between the audio thread's stop commands.
 for voice in g.find_children("*","AudioStreamPlayer",true,false)+g.find_children("*","AudioStreamPlayer3D",true,false):
  voice.stop()
 OS.delay_msec(60)
 for frame in range(3):await g.get_tree().process_frame
