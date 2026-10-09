extends RefCounted

static func check(value: bool,failures: Array,message: String) -> void:
 if not value:failures.append(message)

static func labels(node: Node) -> String:
 var text=node.text+"\n" if node is Label or node is Button else ""
 for child in node.get_children():text+=labels(child)
 return text

static func shot(g,name: String,from: Vector3,target: Vector3) -> void:
 if DisplayServer.get_name()=="headless":return
 GardenAreaAtlas.close(g);g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true
 g.camera.global_position=from;g.camera.look_at(target);g.camera.fov=55
 g.clock_time=.43;g.update_lighting();g.climate.current=Vector3.ZERO;g.climate.apply(g)
 for frame in range(4):await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://captures/milestone-furniture")
 g.get_viewport().get_texture().get_image().save_png("res://captures/milestone-furniture/"+name+".png")
 g.ui.show();g.player.show();g.photo_mode=false

static func capture_atlas(g,name: String,index: int=-1) -> void:
 GardenAreaAtlas.open(g,index)
 if DisplayServer.get_name()!= "headless":
  for frame in range(3):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  DirAccess.make_dir_recursive_absolute("res://captures/milestone-furniture")
  g.get_viewport().get_texture().get_image().save_png("res://captures/milestone-furniture/"+name+".png")

static func run(g,failures: Array) -> void:
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.dismiss_request();g.side_panel.hide();g.settings.controls="keyboard";g.touch.configure()
 g.day=1;g.planted_total=0;g.fulfilled=0;g.coins=4000;g.orders=[]
 var starting=g.planted.size();var stock_count=g.objects.size()
 check(g.planted.filter(func(p):return int(p.plot)==8).size()==4 and GardenAreas.state(g,1).beds.has("0") and GardenAreas.state(g,9).beds.size()==2,failures,"Starter planting must be present before milestones are earned")
 check(g.area_roots.size()==10 and GardenAreaFurnishings.templates.size()==22,failures,"All ten areas and their 22 loose authored props must exist at start")
 for index in range(10):
  check(g.area_roots[index].visible and not GardenAreaCatalogue.plot_open(g,index+4),failures,"Day-one habitat must be visible but locked: %d"%index)
  GardenAreas.visit(g,index)
  check(g.accessible(g.player.position) and not GardenAreas.state(g,index).initialized,failures,"Visiting a locked area must not start its activities: %d"%index)
 check(g.planted.size()==starting and g.planted_total==0 and g.objects.size()==stock_count,failures,"Visits counted starter planting or duplicated furniture")
 await capture_atlas(g,"locked-atlas")
 var overview=labels(g.welcome)
 for index in range(10):
  check(GardenAreaCatalogue.entry(index).name in overview and GardenAreaProgression.requirement(index) in overview,failures,"Atlas omits a milestone: %d"%index)
 await capture_atlas(g,"locked-glasshouse",6)
 check("2000 new plants" in labels(g.welcome) and "Visit Old Glasshouse" in labels(g.welcome) and "Restore bay" not in labels(g.welcome),failures,"Locked area must show target and permit visiting without activities")
 GardenAreaAtlas.close(g)
 if DisplayServer.get_name()!= "headless":
  var original_size=g.get_window().size
  g.get_window().size=Vector2i(390,844);g.settings.controls="touch"
  for frame in range(3):await g.get_tree().process_frame
  g.touch.configure();await capture_atlas(g,"phone-locked-glasshouse",6)
  var screen=Rect2(Vector2.ZERO,g.get_viewport().get_visible_rect().size)
  check(screen.encloses(g.welcome.get_global_rect()),failures,"Locked atlas runs outside a phone screen")
  GardenAreaAtlas.close(g);GardenAreaAtlas.open(g)
  for frame in range(3):await g.get_tree().process_frame
  var scroll=g.welcome.find_child("AtlasScroll",true,false)
  scroll.scroll_vertical=100000
  for frame in range(3):await g.get_tree().process_frame
  var last=scroll.find_child("AtlasContent",true,false).get_children()[-3]
  check(scroll.get_global_rect().intersects(last.get_global_rect()),failures,"Last milestones cannot be reached by phone scrolling")
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/milestone-furniture/phone-last-milestones.png")
  GardenAreaAtlas.close(g);g.get_window().size=original_size;g.settings.controls="keyboard"
  for frame in range(3):await g.get_tree().process_frame
  g.touch.configure();g.side_panel.hide()
 # Test real action dispatch, container API and activities against locked saves.
 var locked_planter=g.objects.filter(func(obj):return obj.kind=="vertical_planter")[0]
 check(not GardenContainers.can_plant(g,locked_planter,0,12).is_empty() and GardenContainers.plant(g,locked_planter,0,12).is_empty(),failures,"Locked planter accepts new seeds")
 g.set_mode("remove");g.hover_object=locked_planter.node;g.hover_target=-1;g.hover_valid=true;g.hover_cell=locked_planter.pos;g.hover_plot=9;g.action_cooldown=0
 g.perform_action();check(locked_planter in g.objects,failures,"Remove bypasses the habitat milestone")
 check(not GardenAreas.restore_bay(g,0) and not GardenAreas.plant_collection(g,1,0,"maidenhair",false),failures,"Locked activity APIs remain active")
 var locked_bench=g.objects.filter(func(obj):return obj.kind=="bench" and GardenAreaCatalogue.index_at(obj.pos)==6)[0]
 g.set_mode("walk");g.player.position=locked_bench.pos+Vector3(0,.1,1)
 GardenLeisure.rest(g,locked_bench);check(g.rest_kind.is_empty(),failures,"Locked furniture use bypasses the milestone")
 # Saved visited/initialized state must not grandfather an unearned area.
 var old={"areas":g.areas_state.duplicate(true)}
 old.areas.gardens.glasshouse.initialized=true;old.areas.gardens.glasshouse.visited=true
 old.areas.gardens.glasshouse.beds={"0":{"species":"orchid","age":3.0,"water":2.0,"offset_day":0}}
 for s in old.areas.gardens.values():s.erase("unlocked")
 GardenAreas.restore(g,old)
 check(not GardenAreaProgression.unlocked(g,6) and GardenAreas.state(g,6).beds["0"].age==3.0 and g.objects.size()==stock_count,failures,"Existing areas bypass milestones or lose saved collections")
 # Earlier planting rewards must use the higher totals on existing saves.
 old.areas.erase("planting_milestones_revision")
 for index in [3,4,5,6]:old.areas.gardens[GardenAreaCatalogue.entry(index).kind].unlocked=true
 g.planted_total=100;GardenAreas.restore(g,old)
 for index in [3,4,5,6]:
  check(not GardenAreaProgression.unlocked(g,index),failures,"Earlier planting reward bypasses the higher target: %d"%index)
 check(GardenAreas.state(g,6).beds["0"].age==3.0 and g.objects.size()==stock_count,failures,"Higher target migration loses planting or furniture")
 g.planted_total=2000;GardenAreas.restore(g,old)
 for index in [3,4,5,6]:
  check(GardenAreaProgression.unlocked(g,index),failures,"Eligible old save loses its earned planting reward: %d"%index)
 var revised={"areas":g.areas_state.duplicate(true)}
 g.planted_total=0;GardenAreas.restore(g,revised)
 for index in [3,4,5,6]:
  check(GardenAreaProgression.unlocked(g,index),failures,"Revised permanent reward is revoked on reload: %d"%index)
 var invalid_revision=revised.duplicate(true);invalid_revision.areas.planting_milestones_revision="broken"
 check(not GardenAreaCatalogue.valid_save(invalid_revision),failures,"Invalid planting revision passes save validation")
 # Each threshold is independent and awards permanent access exactly at target.
 for index in range(10):
  for s in g.areas_state.gardens.values():s.unlocked=false
  g.day=1;g.planted_total=0;g.fulfilled=0
  var rule=GardenAreaProgression.RULES[index]
  g.set(rule.metric,int(rule.target)-1)
  check(not GardenAreaProgression.unlocked(g,index),failures,"Milestone opens early: %d"%index)
  g.set(rule.metric,int(rule.target));GardenAreaProgression.refresh(g,false)
  check(GardenAreas.state(g,index).unlocked and GardenAreaCatalogue.plot_open(g,index+4),failures,"Milestone does not open at target: %d"%index)
  g.set(rule.metric,1 if rule.metric=="day" else 0)
  check(GardenAreaProgression.unlocked(g,index),failures,"Earned reward was revoked: %d"%index)
 g.day=100;g.planted_total=2000;g.fulfilled=8;GardenAreaProgression.refresh(g,false)
 for index in range(10):GardenAreas.initialize(g,index)
 var metric_before=g.planted_total
 for index in range(10):GardenAreas.initialize(g,index)
 check(g.planted_total==metric_before,failures,"Starter plants count towards milestones")
 # All stock benches face their local focal point; front pockets face the court.
 for index in range(10):
  if index==8:
   check(not g.objects.any(func(obj):return obj.get("starter_id","")=="alpine:starter-bench"),failures,"Removed hillside bench returns with starter furniture")
   continue
  var bench=g.objects.filter(func(obj):return obj.get("starter_id","")==GardenAreaCatalogue.entry(index).kind+":starter-bench")[0]
  var direction=(GardenAreaFurnishings.FOCUS[index]-GardenAreaFurnishings.BENCHES[index]).normalized()
  check((-bench.node.global_basis.z).dot(direction)>.999,failures,"Starter bench points away from its garden: %d"%index)
 for obj in g.objects:
  if obj.kind=="vertical_planter":
   check(GardenContainers.position(obj,4).y-GardenContainers.position(obj,0).y>1.09 and GardenContainers.position(obj,0).z>obj.pos.z,failures,"Vertical pockets do not rise upright and face into the kitchen")
 # Mature review garden before destructive ownership tests.
 if DisplayServer.get_name()!= "headless":
  preload("res://tests/areas.gd").demo(g)
  for index in range(10):await preload("res://tests/areas.gd").capture(g,index)
  await shot(g,"kitchen-pockets",GardenAreaCatalogue.center(5)+Vector3(-2.3,3.5,-2.4),GardenAreaCatalogue.center(5)+Vector3(-5.6,2.4,-6.1))
  await shot(g,"glasshouse-displays",GardenAreaCatalogue.center(6)+Vector3(.6,3.8,5.7),GardenAreaCatalogue.center(6)+Vector3(-2,2.5,-.6))
 # Shelf tops are horizontal and legs stand upright in the imported model.
 var shelf=GardenAreaFurnishings.object(g,"glasshouse:shelf0")
 check(shelf.node.get_aabb()==AABB() if shelf.node is MeshInstance3D else shelf.node.global_basis.y.dot(Vector3.UP)>.999,failures,"Shelf root is tipped over")
 # A shelf move carries its supported pots; removal lowers them and touch Undo restores height.
 var pot=GardenAreaFurnishings.object(g,"glasshouse:pot0")
 var original_pot=pot.pos;var original_shelf=shelf.pos
 GardenAreaFurnishings.before_move(g,shelf);shelf.node.rotation.y=.4;shelf.rotation=.4;shelf.pos+=Vector3(.1,0,.1);shelf.node.position=shelf.pos;GardenAreaFurnishings.after_move(g,shelf)
 check(pot.pos.distance_to(original_pot)>.1 and absf(shelf.node.to_local(pot.pos).y-.92)<.02,failures,"Shelf move leaves pots floating behind")
 GardenAreaFurnishings.before_move(g,shelf);shelf.rotation=0;shelf.node.rotation.y=0;shelf.pos=original_shelf;shelf.node.position=shelf.pos;GardenAreaFurnishings.after_move(g,shelf)
 g.settings.controls="touch";g.touch.configure();g.side_panel.hide();g.set_mode("remove")
 await preload("res://tests/structure_removal.gd").aim(g,shelf)
 check(g.aimed_object()==g.objects.find(shelf),failures,"Authored shelf cannot be selected by its visible surface")
 g.action_cooldown=0;g.touch.act()
 check(shelf not in g.objects and absf(pot.pos.y-GardenTerrain.point(pot.pos).y)<.01,failures,"Shelf removal leaves floating pots")
 g.touch.undo_remove()
 check(pot.pos.distance_to(original_pot)<.02 and not GardenAreaFurnishings.object(g,"glasshouse:shelf0").is_empty(),failures,"Undo shelf loses original pot height")
 # Packing a specialist pot preserves its record, then restores it on Undo.
 var collection=GardenAreas.state(g,6).beds.get("0",{"species":"orchid","age":3.0,"water":2.0,"offset_day":0}).duplicate(true)
 GardenAreas.state(g,6).beds["0"]=collection;GardenAreas.visual_collection(g,6)
 g.set_mode("remove");await preload("res://tests/structure_removal.gd").aim(g,pot);g.action_cooldown=0;g.touch.act()
 check(pot not in g.objects and not GardenAreas.state(g,6).beds.has("0") and GardenAreas.state(g,6).packed_beds.get("0",{})==collection,failures,"Packing collection pot loses or floats its plant")
 g.save_game();var save=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(GardenSaveFormat.valid(save,g.catalogue.size(),g.furniture.map(func(item):return item.kind)),failures,"Milestones, packed collections and elevated furniture fail save validation")
 g.touch.undo_remove();check(GardenAreas.state(g,6).beds.get("0",{})==collection,failures,"Undo pot does not restore collection growth")
 g.settings.controls="touch" if DisplayServer.get_name()=="headless" else "keyboard";g.touch.configure();g.side_panel.hide()
 # Restore an actual save, including high pots and their independent plants.
 var ordinary_holder=GardenAreaFurnishings.object(g,"kitchen:pot0")
 var ordinary_plant=GardenContainers.plant(g,ordinary_holder,0,12)
 var ordinary_uid=ordinary_holder.uid;ordinary_plant.age=3.0;ordinary_plant.water=1.5
 g.save_game();var complete=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 var height=GardenAreaFurnishings.object(g,"glasshouse:pot0").pos.y
 for obj in g.objects:obj.node.free()
 g.objects.clear()
 for plant in g.planted:plant.node.free();plant.marker.free()
 g.planted.clear();g.plant_index.invalidate()
 g.loaded_data=complete;GardenWorkshop.restore(g,complete);GardenAreas.restore(g,complete)
 g.restore_garden();GardenAreaFurnishings.restore(g)
 check(absf(GardenAreaFurnishings.object(g,"glasshouse:pot0").pos.y-height)<.01,failures,"High pot falls to the floor on save reload")
 var restored_holder=GardenContainers.object(g,ordinary_uid)
 var restored_plant=g.planted[GardenContainers.occupant(g,restored_holder,0)]
 check(restored_plant.age==3.0 and restored_plant.water==1.5 and restored_plant.pos.distance_to(GardenContainers.position(restored_holder,0))<.01,failures,"Saved owned pot loses planting, elevation or growth")
 # Shop replacements can hold pots on their shelf, and carry them with Move.
 g.add_object("nursery_shelf",Vector3(-8,0,-8),60)
 var replacement=g.objects.back()
 g.add_object("pot",replacement.pos+Vector3(0,0,1.5),25)
 var replacement_pot=g.objects.back()
 check(absf(replacement_pot.pos.y-replacement.pos.y-.92)<.01,failures,"Replacement pot does not sit on its shelf")
 GardenAreaFurnishings.before_move(g,replacement);replacement.node.position+=Vector3(2,0,0);replacement.pos=replacement.node.position;GardenAreaFurnishings.after_move(g,replacement)
 check(absf(replacement.node.to_local(replacement_pot.pos).y-.92)<.01,failures,"Replacement shelf loses its new pot")
 # The longer Moon pergola has its own real post spacing for climbing shoots.
 var pergola=GardenAreaFurnishings.object(g,"moon:pergola")
 var climber=g.add_plant(9,pergola.node.to_global(Vector3(1.8,0,2.25)),13,float(g.catalogue[9].days))
 GardenClimbingSupport.grow(climber,pergola,1.0)
 var stem=climber.node.get_node("Vines").get_child(0)
 var vertices=stem.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 var tip=stem.global_transform*vertices[-2]
 var post=pergola.node.to_global(Vector3(1.2,2.73,2.75))
 check(Vector2(tip.x-post.x,tip.z-post.z).length()<.14 and absf(tip.y-post.y)<.02,failures,"Moon pergola climber follows a generic floating post")
 # Every newly owned authored loose prop must be reachable by a real tool ray.
 for id in GardenAreaFurnishings.templates:
  var obj=GardenAreaFurnishings.object(g,id)
  if obj.is_empty():continue
  g.set_mode("remove");await preload("res://tests/structure_removal.gd").aim(g,obj)
  check(g.aimed_object()==g.objects.find(obj),failures,"Authored loose prop cannot be picked: "+id)
  g.action_cooldown=0;g.perform_action()
  check(GardenAreaFurnishings.object(g,id).is_empty(),failures,"Authored prop cannot be removed: "+id)
 # Removing/visiting/reloading cannot silently respawn packed furniture.
 var remaining=g.objects.size();g.save_game();save=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 GardenAreas.restore(g,save);GardenAreaFurnishings.restore(g)
 for index in range(10):GardenAreas.initialize(g,index)
 check(g.objects.size()==remaining,failures,"Removed furniture reappears after reload or visit")
 check(GardenAreaCatalogue.valid_save(save),failures,"Final habitat save is invalid")
 # Moving stored plants is not another seed planting.
 g.add_object("pot",Vector3(-8,0,3),25)
 var ordinary_pot=g.objects.back();var plant=GardenContainers.plant(g,ordinary_pot,0,12);var count=g.planted_total
 GardenContainers.pack(g,ordinary_pot)
 check(GardenContainers.replant(g,g.workshop_state.nursery.size()-1,ordinary_pot,0) and g.planted_total==count,failures,"Nursery replanting inflates milestone count")
 g.set_mode("walk")
 print("MILESTONE_AUDIT: ten thresholds, legacy gating, 22 loose props, pot supports, touch Undo, persistent removals and seed counts")
