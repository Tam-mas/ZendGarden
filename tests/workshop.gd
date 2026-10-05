extends RefCounted

static func check(condition: bool, failures: Array, message: String) -> void:
 if not condition:failures.append(message)

static func clear_garden(g) -> void:
 for p in g.planted:p.node.queue_free();p.marker.queue_free()
 for obj in g.objects:obj.node.queue_free()
 g.planted.clear();g.objects.clear();g.plant_index.invalidate()
 g.workshop_state=GardenWorkshop.initial_state()

static func station(g, kind: String, spot: Vector3=Vector3(-6,0,1)) -> Dictionary:
 g.add_object(kind,spot,50)
 return g.objects.back()

static func click(g, obj: Dictionary, slot: int, mode: String) -> void:
 g.set_mode(mode)
 g.hover_container_uid=obj.uid;g.hover_container_slot=slot
 g.hover_cell=GardenContainers.position(obj,slot);g.hover_plot=g.nearest_plot(obj.pos)
 g.hover_target=GardenContainers.occupant(g,obj,slot);g.hover_object=null
 g.hover_valid=true;g.action_cooldown=0
 g.perform_action()

static func capture(g, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://captures/workshop")
 g.get_viewport().get_texture().get_image().save_png("res://captures/workshop/"+name+".png")

static func run(g, failures: Array) -> void:
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 g.settings.controls="keyboard";g.touch.configure();g.side_panel.hide();g.dismiss_request()
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 clear_garden(g)
 g.day=1;g.coins=1000;g.unlocked_plants=range(g.catalogue.size())
 g.orders=[{"person":"Reserved harvest","plant":0,"count":2,"reward":24}]
 g.inventory={"0":9}
 var compost=station(g,"compost_bays")
 check(not GardenEquipment.start(g,compost) and int(g.inventory["0"])==9,failures,"Crafting consumes reserved harvest or a partial recipe")
 g.inventory["0"]=30
 check(GardenEquipment.start(g,compost) and int(g.inventory["0"])==22,failures,"Compost recipe did not consume exactly eight spare items")
 check(not GardenEquipment.start(g,compost),failures,"Unupgraded station accepts two batches")
 var balance=g.coins
 check(GardenEquipment.upgrade(g,compost) and g.coins==balance-40 and compost.price==90,failures,"Station upgrade/refund price wrong")
 check(GardenEquipment.start(g,compost) and not GardenEquipment.start(g,compost),failures,"Upgraded batch slots wrong")
 var worm=station(g,"worm_farm",Vector3(-5,0,1))
 check(not GardenEquipment.start(g,worm),failures,"Wormery accepted non-produce")
 g.inventory["48"]=30
 check(GardenEquipment.start(g,worm),failures,"Wormery did not accept spare produce")
 var mulch=station(g,"mulch_bin",Vector3(-4,0,1))
 var bench=station(g,"potting_bench",Vector3(-3,0,1))
 check(GardenEquipment.start(g,mulch) and GardenEquipment.start(g,bench),failures,"Mulch or starter mix recipe failed")
 # Batches become ready once, on their promised morning, through real growth.
 g.advance_growth()
 check(int(g.workshop_state.resources.get("mulch",0))==4 and int(g.workshop_state.resources.get("starter_mix",0))==4 and not g.workshop_state.resources.has("compost"),failures,"One-morning jobs or slower batches have wrong completion day")
 g.advance_growth()
 check(int(g.workshop_state.resources.get("compost",0))==8 and not g.workshop_state.resources.has("castings"),failures,"Two-morning jobs have wrong yield/timing")
 g.advance_growth()
 check(int(g.workshop_state.resources.get("castings",0))==4 and g.workshop_state.jobs.is_empty(),failures,"Three-morning jobs or duplicate delivery failed")
 var p=g.add_plant(48,Vector3(-2,0,2),0,0)
 p.stress=.5
 check(GardenEquipment.treat(g,p,"castings") and is_equal_approx(p.stress,.15),failures,"Castings do not ease existing stress")
 check(GardenEquipment.treat(g,p,"compost") and GardenEquipment.treat(g,p,"mulch"),failures,"Applying soil care failed")
 var portions=int(g.workshop_state.resources.compost)
 check(not GardenEquipment.treat(g,p,"compost") and int(g.workshop_state.resources.compost)==portions,failures,"Active treatment consumes another portion")
 check(is_equal_approx(GardenEquipment.growth_multiplier(g,p,1.2),1.3) and is_equal_approx(GardenEquipment.water_loss(g,p),.5) and is_equal_approx(GardenEquipment.stress_gain(g,p),.05),failures,"Treatment benefits wrong")
 var hive=station(g,"hive",Vector3(-2,0,3))
 var hotel=station(g,"insect_hotel",Vector3(-1,0,3))
 check(is_equal_approx(GardenEquipment.growth_multiplier(g,p,1.2),1.3) and is_equal_approx(GardenEquipment.stress_gain(g,p),.01),failures,"Hive/hotel benefit or combined growth cap failed")
 var old_day=g.day
 g.day+=4
 check(not GardenEquipment.active(p,"compost",g.day) and is_equal_approx(GardenEquipment.growth_multiplier(g,p,1),1.05),failures,"Expired compost still benefits plants")
 check(GardenEquipment.active(p,"mulch",g.day),failures,"Mulch expires before its six mornings")
 g.day=old_day
 g.workshop_state.use_starter=true
 var starter_before=int(g.workshop_state.resources.starter_mix)
 var fresh=g.add_plant(12,Vector3(-2,0,3),0)
 GardenEquipment.starter(g,fresh)
 check(is_equal_approx(fresh.age,float(g.catalogue[12].days)*.08) and fresh.water==4 and int(g.workshop_state.resources.starter_mix)==starter_before-1,failures,"Starter mix beginning/consumption wrong")
 # Every kind has real pockets, rejects trees/occupied pockets, and carries care.
 var planter_objects=[]
 for kind in GardenContainers.SPECS:
  var obj=station(g,kind,Vector3(-5+(planter_objects.size()%4)*2.0,0,-3-floori(planter_objects.size()/4.0)*2.6))
  planter_objects.append(obj)
  check(not GardenContainers.can_plant(g,obj,0,28).is_empty(),failures,"Container accepted a tree: "+kind)
  var capacity=g.capacity_used(0)
  var plant=GardenContainers.plant(g,obj,0,12)
  check(not plant.is_empty() and plant.pos.is_equal_approx(GardenContainers.position(obj,0)) and g.capacity_used(0)==capacity,failures,"Functional pocket or independent capacity failed: "+kind)
  check(not GardenContainers.can_plant(g,obj,0,12).is_empty(),failures,"Occupied pocket still accepts plants: "+kind)
 var vertical=planter_objects.filter(func(obj):return obj.kind=="vertical_planter")[0]
 for slot in range(1,6):GardenContainers.plant(g,vertical,slot,12)
 var vp=g.planted[GardenContainers.occupant(g,vertical,5)]
 vp.age=3;vp.water=1;vp.stress=.3;vp.pruned=.4;vp.treatments={"mulch":g.day+6}
 var state=GardenContainers.record(vp)
 # Use the actual Move action, including object rotation and all six plant nodes.
 g.set_mode("move");g.moved_object=g.objects.find(vertical);g.structure_rotation=PI/2
 g.hover_container_uid="";g.hover_cell=GardenTerrain.point(Vector3(-6,0,-8));g.hover_plot=0;g.hover_valid=true;g.action_cooldown=0
 g.perform_action()
 for slot in range(6):
  var plant=g.planted[GardenContainers.occupant(g,vertical,slot)]
  check(plant.pos.is_equal_approx(GardenContainers.position(vertical,slot)) and plant.node.position.is_equal_approx(plant.pos),failures,"Moving/rotating display lost a pocket")
 check(vp.age==state.age and vp.stress==state.stress and vp.pruned==state.pruned,failures,"Moving display changed plant care/growth")
 # Real camera targeting of an upper elevated pocket and its plant preview.
 g.player.position=vertical.pos+Vector3(0,.1,2)
 var center=GardenContainers.position(vertical,4)+Vector3(0,.15,0)
 g.camera.global_position=center+Vector3(0,.1,2)
 g.camera.look_at(center)
 g.selected=12;g.set_mode("plant");Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 g.update_hover()
 check(g.hover_container_uid==vertical.uid and g.hover_container_slot==4 and g.hover_cell.y>vertical.pos.y+1.5,failures,"Upper vertical pocket is not reachable from the camera aim")
 check(is_instance_valid(g.preview) and g.preview.position.is_equal_approx(g.hover_cell),failures,"Elevated planting preview misplaced")
 # Tools act on the aimed pocket rather than every pocket above the same ground.
 for slot in range(6):g.planted[GardenContainers.occupant(g,vertical,slot)].water=0
 click(g,vertical,4,"water")
 check(g.planted[GardenContainers.occupant(g,vertical,4)].water>0 and vp.water==0,failures,"Pocket watering leaks into other pockets")
 click(g,vertical,5,"prune");click(g,vertical,5,"prune");click(g,vertical,5,"prune")
 check(vp in g.planted,failures,"Pruning clears a contained plant after three cuts")
 vp.age=float(g.catalogue[vp.id].days)
 var basket=g.basket_total()
 click(g,vertical,5,"harvest")
 check(g.basket_total()==basket+1,failures,"Pocket gathering missed or harvested unrelated plants")
 # Rain stores a finite amount; irrigation spends drinks only on thirsty pockets.
 var barrel=station(g,"rain_barrel",vertical.pos+Vector3(1.5,0,0))
 GardenEquipment.weather(g,1,900)
 check(barrel.work.water==12,failures,"Unupgraded barrel overflowed")
 GardenEquipment.upgrade(g,barrel);GardenEquipment.weather(g,1,900)
 check(barrel.work.water==24,failures,"Upgraded barrel capacity wrong")
 barrel.work.water=2;barrel.work.irrigating=true
 for plant in g.planted:plant.water=0
 GardenEquipment.morning(g)
 check(barrel.work.water==0 and g.planted.filter(func(plant):return plant.water==4).size()==2 and p.water==0,failures,"Irrigation creates free drinks or waters ground plants")
 # Shelter conditions and actual visible toggles.
 var shade=station(g,"shade_canopy",Vector3(2,0,4))
 var shadow=g.add_plant(13,shade.pos,0)
 check(g.growth_conditions(shadow)==1,failures,"Shade cloth does not satisfy shade-loving plants")
 shade.work.shade_on=false;GardenEquipment.visual(g,shade)
 check(not shade.node.find_child("ShadeFabric*",true,false).visible and g.growth_conditions(shadow)<1,failures,"Folded shade cloth still gives shade")
 var frame=station(g,"cold_frame",Vector3(0,0,4))
 var seasonal_id=-1
 for data in g.catalogue:
  if int(data.layer)<2 and not data.seasons.is_empty() and GardenClimate.season(g.day) not in data.seasons:seasonal_id=int(data.id);break
 check(seasonal_id>=0,failures,"No seasonal plant for shelter check")
 if seasonal_id>=0:
  var seasonal=g.add_plant(seasonal_id,frame.pos,0)
  check(is_equal_approx(g.growth_conditions(seasonal),.6),failures,"Closed cold frame does not give out-of-season growth")
  frame.work.closed=false;GardenEquipment.visual(g,frame)
  check(g.growth_conditions(seasonal)==0 and frame.node.find_child("ColdFrameLid*",true,false).rotation.x<-.9,failures,"Open cold frame still shelters or has no visible lid change")
 var feeder=station(g,"bird_feeder",Vector3(3,0,3))
 g.refresh_wildlife();var bird_count=g.wildlife.filter(func(entry):return entry.kind=="songbird").size()
 g.inventory["48"]=30
 check(GardenEquipment.feed(g,feeder) and not GardenEquipment.feed(g,feeder),failures,"Feeder consumes food twice")
 check(g.wildlife.filter(func(entry):return entry.kind=="songbird").size()==bird_count+2,failures,"Fed table does not attract two extra birds")
 for entry in g.wildlife:
  if entry.get("feeder","")==feeder.uid:check(GardenWildlifeMotion.perch(g,entry).distance_to(feeder.pos)<1.5,failures,"Feeder birds do not visit the table")
 g.day+=3;g.refresh_wildlife();GardenEquipment.visual(g,feeder)
 check(g.wildlife.filter(func(entry):return entry.kind=="songbird").size()==bird_count and not feeder.node.find_child("BirdFood*",true,false).visible,failures,"Feeder food/extra visitors do not expire")
 # Packing a display stores all contents; touch Undo restores both without copies.
 g.set_mode("remove");g.settings.controls="touch";g.touch.configure();g.side_panel.hide();g.action_cooldown=0
 g.hover_container_uid="";g.hover_object=vertical.node;g.hover_cell=vertical.pos;g.hover_valid=true;g.hover_target=-1
 balance=g.coins;var nursery=g.workshop_state.nursery.size()
 g.touch.act()
 check(vertical not in g.objects and g.workshop_state.nursery.size()==nursery+6 and g.coins==balance+vertical.price,failures,"Packing a display loses plants or refund: %s stored %d expected %d petals %d expected %d"%[str(vertical in g.objects),g.workshop_state.nursery.size(),nursery+6,g.coins,balance+vertical.price])
 g.touch.undo_remove()
 vertical=GardenContainers.object(g,vertical.uid)
 check(not vertical.is_empty() and g.workshop_state.nursery.size()==nursery and g.coins==balance,failures,"Touch Undo did not restore planted container")
 vp=g.planted[GardenContainers.occupant(g,vertical,5)]
 GardenContainers.store(g,vp)
 var saved_plant=g.workshop_state.nursery.back().duplicate(true)
 var mix_before=int(g.workshop_state.resources.starter_mix)
 check(GardenContainers.replant(g,g.workshop_state.nursery.size()-1,vertical,5),failures,"Nursery plant cannot be replanted")
 vp=g.planted[GardenContainers.occupant(g,vertical,5)]
 check(vp.age==saved_plant.age and vp.stress==saved_plant.stress and vp.shape_seed==saved_plant.shape_seed and int(g.workshop_state.resources.starter_mix)==mix_before,failures,"Replanting resets care or spends starter mix")
 GardenContainers.store(g,vp)
 # Actual JSON roundtrip, including jobs, supplies, stored plants and socket refs.
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 var kinds=g.furniture.map(func(item):return item.kind)
 check(GardenSaveFormat.valid(saved,g.catalogue.size(),kinds),failures,"Working garden rejected by save upload")
 var bad=saved.duplicate(true);bad.workshop.nursery[0].storage_slot="bad"
 check(not GardenSaveFormat.valid(bad,g.catalogue.size(),kinds),failures,"Malformed nursery slot accepted")
 bad=saved.duplicate(true);bad.plants.append(bad.plants.filter(func(plant):return plant.has("container_uid"))[0].duplicate(true))
 check(not GardenSaveFormat.valid(bad,g.catalogue.size(),kinds),failures,"Duplicate occupied pocket accepted")
 clear_garden(g);g.smoke=false;g.load_game();g.smoke=true;g.restore_garden()
 vertical=g.objects.filter(func(obj):return obj.kind=="vertical_planter")[0]
 check(g.workshop_state.nursery.size()==1 and GardenContainers.occupant(g,vertical,5)==-1,failures,"Save reload loses nursery or recreates stored plants")
 for slot in range(5):
  var plant=g.planted[GardenContainers.occupant(g,vertical,slot)]
  check(plant.node.position.is_equal_approx(GardenContainers.position(vertical,slot)),failures,"Save reload grounded an elevated plant")
 var legacy=saved.duplicate(true);legacy.erase("workshop")
 legacy.plants=legacy.plants.filter(func(plant):return not plant.has("container_uid"))
 for obj in legacy.objects:obj.erase("uid");obj.erase("work")
 check(GardenSaveFormat.valid(legacy,g.catalogue.size(),kinds),failures,"Legacy garden save became incompatible")
 # Operate the modal at narrow touch and desktop sizes; content must be scrollable.
 g.set_mode("walk");g.side_panel.hide()
 g.player.position=vertical.node.to_global(Vector3(0,.1,-2));g.yaw=vertical.rotation+PI
 GardenLeisure.interact(g)
 check(g.workshop_open and g.workshop_uid==vertical.uid,failures,"Wander interaction does not open the facing planter")
 GardenWorkshop.close(g)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for size in [Vector2i(1280,800),Vector2i(390,844),Vector2i(320,568),Vector2i(667,375)]:
  g.get_viewport().size=size;g.settings.controls="touch" if size.x<700 else "keyboard";g.touch.configure()
  GardenWorkshop.open(g,vertical.uid)
  for frame_count in range(3):await g.get_tree().process_frame
  GardenWorkshop.fit(g)
  var viewport=Rect2(Vector2.ZERO,Vector2(size))
  check(viewport.encloses(g.welcome.get_global_rect()),failures,"Workshop panel exceeds viewport at "+str(size))
  var scroll=g.welcome.find_child("WorkshopScroll",true,false) as ScrollContainer
  var content=scroll.get_node("WorkshopContent")
  var choice=content.get_node("Pocket5Seeds") as OptionButton
  check(choice!=null and choice.size.y>=48 and choice.size.x<=content.size.x+1,failures,"Pocket selector does not fit at "+str(size))
  scroll.scroll_vertical=int(choice.position.y)
  for frame_count in range(2):await g.get_tree().process_frame
  scroll.ensure_control_visible(choice)
  for frame_count in range(2):await g.get_tree().process_frame
  check(scroll.get_global_rect().grow(1).encloses(choice.get_global_rect()),failures,"Pocket selector cannot be scrolled into view at %s: scroll %s choice %s max %s"%[str(size),str(scroll.get_global_rect()),str(choice.get_global_rect()),str(scroll.get_v_scroll_bar().max_value)])
  await capture(g,"planter-%dx%d"%[size.x,size.y])
  GardenWorkshop.close(g)
 g.set_mode("walk");g.side_panel.hide();g.settings.controls="touch";g.touch.configure()
 g.touch._process(0)
 check(g.touch.buttons.greet.visible and g.touch.buttons.greet.text=="Use planter",failures,"Touch interaction does not identify the planter")
 g.touch.buttons.greet.pressed.emit()
 check(g.workshop_open and g.workshop_uid==vertical.uid,failures,"Touch interaction does not open the planter")
 GardenWorkshop.close(g)
 # One real modal button plants the stored record without changing its growth.
 GardenWorkshop.open(g,vertical.uid)
 for frame_count in range(2):await g.get_tree().process_frame
 var choice=g.welcome.find_child("Pocket5Seeds",true,false) as OptionButton
 choice.select(choice.item_count-1)
 var content=g.welcome.find_child("WorkshopContent",true,false)
 for control in content.get_children():
  if control is Button and control.text=="Plant in pocket 6":control.pressed.emit();break
 check(g.workshop_state.nursery.is_empty() and GardenContainers.occupant(g,vertical,5)>=0,failures,"Modal pocket planting failed")
 GardenWorkshop.close(g)
 # Real rendered gallery with mature planting in containers.
 g.get_viewport().size=Vector2i(1280,800);g.settings.controls="keyboard";g.touch.configure();g.side_panel.hide()
 g.workshop_state.use_starter=false
 var displays={"pot":[0],"raised_bed":[2,54,50,12,46,0],"wide_bowl":[122,124],"large_planter":[20],"herb_trough":[54,2,50],"hanging_basket":[50],"vertical_planter":[121,122,124,11,50,54],"tiered_planter":[2,50,121,54,124,122]}
 for obj in g.objects:
  if obj.kind not in displays:continue
  for slot in range(displays[obj.kind].size()):
   var index=GardenContainers.occupant(g,obj,slot)
   if index>=0:
    var previous=g.planted[index]
    g.planted.remove_at(index);previous.node.queue_free();previous.marker.queue_free()
   check(not GardenContainers.plant(g,obj,slot,displays[obj.kind][slot]).is_empty(),failures,"Varied container display rejected a suitable species")
 for plant in g.planted:plant.age=float(g.catalogue[plant.id].days);g.refresh_plant(plant,false)
 vertical.pos=GardenTerrain.point(Vector3(-1,0,1));vertical.node.position=vertical.pos
 GardenContainers.sync(g,vertical)
 g.set_mode("walk");g.side_panel.hide();g.update_hud()
 g.camera.global_position=vertical.node.to_global(Vector3(2,2.3,-3.8))
 g.camera.look_at(vertical.pos+Vector3(0,1,0))
 if is_instance_valid(g.preview):g.preview.hide()
 g.animate_garden(0,12)
 for frame_count in range(4):await g.get_tree().process_frame
 await capture(g,"vertical-garden")
 GardenWorkshop.open(g)
 for frame_count in range(3):await g.get_tree().process_frame
 await capture(g,"working-garden")
 GardenWorkshop.close(g)
