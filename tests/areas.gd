extends RefCounted

static func check(value: bool,failures: Array,message: String) -> void:
 if not value:failures.append(message)

static func mature(g,index: int) -> void:
 var s=GardenAreas.state(g,index)
 for p in s.beds.values():p.age=float(GardenAreaCatalogue.data().specialties[p.species].days);p.water=4
 for p in g.planted:
  if int(p.plot)==index+4:p.age=float(g.catalogue[int(p.id)].days);g.refresh_plant(p,false)
 GardenAreas.visual(g,index)

static func add(g,index: int,id: int,x: float,z: float,maturity: float=1.0) -> Dictionary:
 return g.add_plant(id,GardenAreaCatalogue.center(index)+Vector3(x,0,z),index+4,float(g.catalogue[id].days)*maturity)

static func capture(g,index: int,suffix: String="") -> void:
 if DisplayServer.get_name()=="headless":return
 GardenAreaAtlas.close(g);g.ui.hide();g.touch.hide();g.player.hide()
 var info=GardenAreaCatalogue.entry(index);var center=GardenAreaCatalogue.center(index)
 g.photo_mode=true;g.view_fov=55
 g.camera.global_position=center+Vector3(info.camera[0],info.camera[1],info.camera[2])
 if index==9:g.clock_time=.77
 else:g.clock_time=.43
 g.camera.fov=55;g.camera.look_at(center+Vector3(info.focus[0],info.focus[1],info.focus[2]))
 g.update_lighting();g.climate.current=Vector3.ZERO;g.climate.snow=0;g.climate.apply(g)
 for j in range(g.area_roots.size()):g.area_roots[j].visible=true
 GardenAreas.visual(g,index);g.animate_garden(.016,12)
 await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://captures/areas")
 var image=g.get_viewport().get_texture().get_image()
 image.save_png("res://captures/areas/"+info.kind+suffix+".png")
 if suffix.is_empty():
  image.resize(960,600,Image.INTERPOLATE_LANCZOS)
  image.save_webp("res://captures/areas/"+info.kind+"-gallery.webp",true,.70)
  DirAccess.make_dir_recursive_absolute("res://assets/ui/areas")
  image.resize(480,300,Image.INTERPOLATE_LANCZOS)
  image.save_webp("res://assets/ui/areas/"+info.kind+".webp",true,.85)
 g.ui.show();g.player.show();g.photo_mode=false

static func demo(g) -> void:
 GardenAreaProgression.unlock_review(g)
 # Mature example planting for review captures; this test uses its own save.
 for index in [0,1,6,8,9]:
  var s=GardenAreas.state(g,index)
  if index==1:s.discoveries=["Mossy hollow","Old fern grove","Spring clearing"]
  if index==6:
   for bay in range(3):GardenAreas.restore_bay(g,bay)
  for slot in range(GardenAreaCatalogue.entry(index).slots.size()):
   if not s.beds.has(str(slot)):GardenAreas.plant_collection(g,index,slot,GardenAreas.default_species(index,slot),false)
  mature(g,index)
 for obj in g.objects:
  if obj.kind=="vertical_planter" and g.nearest_plot(obj.pos)==9:
   for slot in range(6):
    var plant=GardenContainers.plant(g,obj,slot,12 if slot%2==0 else 50)
    if not plant.is_empty():plant.age=float(g.catalogue[int(plant.id)].days);g.refresh_plant(plant,false)
 for index in [2,3,5,7]:
  for j in range(60 if index==3 else 36):
   var x=[-4.4,-3.2,-2,2,3.2,4.4][j%6];var z=[-4.4,-3.2,-2,2,3.2,4.4][floori(j/6.0)%6]
   var pos=GardenAreaCatalogue.center(index)+Vector3(x,0,z)
   if not g.plantable_ground(pos):continue
   var id={2:[124,125,126,129,130,134,135,127],3:[0,1,2,7,65,66,36,37],5:[46,47,48,54,56,51,52,104],7:[8,13,16,109,146,147]}[index][j%(8 if index in [2,3,5] else 6)]
   add(g,index,id,x,z)
 mature(g,4)
 GardenAreas.state(g,2).shelters[0]=true
 GardenAreas.state(g,7).gates=[true,true]
 GardenAreas.state(g,9).lanterns=1
 g.refresh_wildlife()

static func run(g,failures: Array) -> void:
 GardenAreaProgression.unlock_review(g)
 g.set_process(false);g.settings.intro_seen=true;g.settings.request_notifications=false
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.dismiss_request();g.side_panel.hide();g.settings.controls="keyboard";g.touch.configure()
 g.coins=2000;g.day=1;g.clock_time=.42;g.orders=[];g.unlocked_plants=range(g.catalogue.size())
 g.hover_container_uid=""
 check(g.area_roots.size()==10 and g.plots.size()>=14,failures,"Ten authored habitats are not in the world")
 check(g.terrain_meshes.filter(func(e):return e.node.global_position.x>=44 or (e.node.global_transform*e.base.get_aabb()).position.x>=44).size()>=10,failures,"Habitat ground is missing matching sculpt/collision surfaces")
 for index in range(10):
  GardenAreas.visit(g,index)
  check(g.current_plot==index+4 and g.accessible(g.player.position) and g.player.position.x>=44,failures,"Atlas visit inaccessible: "+str(index))
  check(GardenAreaCatalogue.plot_open(g,index+4),failures,"New trail blocked behind original plot progression")
  var initialized=g.planted.size();var structures=g.objects.size()
  GardenAreas.initialize(g,index)
  check(g.planted.size()==initialized and g.objects.size()==structures,failures,"Starter collection repeated on another visit")
  check(is_finite(GardenTerrain.base_rise(g.player.position.x,g.player.position.z)),failures,"Invalid authored terrain height")
  # Exercise the viewer's actual update after an atlas visit, including gravity.
  # Horizontal progress alone used to pass even while the player fell below it.
  for frame in range(40):
   await g.get_tree().physics_frame
   g._process(g.get_physics_process_delta_time())
  check(g.player.is_on_floor() and absf(g.player.position.y-GardenTerrain.point(g.player.position).y)<.5,failures,"Atlas arrival fell through "+GardenAreaCatalogue.entry(index).name+" at "+str(g.player.position))
  # Include every eight-metre collision partition, boundaries and varied slopes.
  for x in [-10,-8,-4,0,4,8,10]:
   for z in [-10,-8,-4,0,4,8,10]:
    var pos=GardenAreaCatalogue.center(index)+Vector3(x,0,z)
    var ray=PhysicsRayQueryParameters3D.create(Vector3(pos.x,12,pos.z),Vector3(pos.x,-3,pos.z))
    ray.exclude=[g.player.get_rid()]
    var ground=g.get_world_3d().direct_space_state.intersect_ray(ray)
    check(not ground.is_empty() and ground.position.y> -1 and ground.normal.y>0,failures,"Missing ground collision in "+GardenAreaCatalogue.entry(index).name+" at "+str(pos))
 # Verify ordinary gardening through the same tools players use, rather than
 # assuming all ten habitats accept plants because demo helpers can add them.
 for index in range(10):
  var positions=[];var center=GardenAreaCatalogue.center(index)
  for x in range(-17,18):
   for z in range(-17,18):
    var pos=GardenTerrain.point(center+Vector3(x*g.GRID,0,z*g.GRID))
    if g.can_plant(0,pos,index+4).is_empty():positions.append(pos)
    if positions.size()==2:break
   if positions.size()==2:break
  if positions.size()<2:
   failures.append("No editable planting ground in "+GardenAreaCatalogue.entry(index).name);continue
  var count=g.planted.size()
  g.mode="plant";g.selected=0;g.hover_cell=positions[0];g.hover_plot=index+4
  g.hover_valid=true;g.hover_target=-1;g.hover_object=null;g.action_cooldown=0
  g.perform_action()
  check(g.planted.size()==count+1,failures,"Plant tool failed in "+GardenAreaCatalogue.entry(index).name)
  if g.planted.size()!=count+1:continue
  g.mode="move";g.moved_index=count;g.moved_object=-1;g.hover_cell=positions[1];g.action_cooldown=0
  g.perform_action()
  check(g.planted[count].pos.is_equal_approx(positions[1]),failures,"Move tool failed in "+GardenAreaCatalogue.entry(index).name)
  g.mode="remove";g.hover_cell=g.planted[count].pos;g.hover_target=count
  g.hover_valid=true;g.hover_object=null;g.action_cooldown=0
  g.perform_action()
  check(g.planted.size()==count,failures,"Remove tool failed in "+GardenAreaCatalogue.entry(index).name)
 g.mode="walk";g.moved_index=-1;g.hover_valid=false
 # Bed surfaces retain the precise soil footprint and save their choices.
 for plot in [8,9]:
  var soils=g.terrain_meshes.filter(func(e):return int(e.node.get_meta("area_bed_plot",-1))==plot)
  check(not soils.is_empty(),failures,"Missing changeable habitat soil: "+str(plot))
  check(GardenBedSurfaces.apply(g,plot,"bark"),failures,"Habitat bed cannot change surface: "+str(plot))
  for soil in soils:
   check(soil.node.material_override.get_shader_parameter("earth").resource_path.ends_with("beds/bark.webp"),failures,"Bed finish missed an authored soil patch")
  var surface_save={"owned_surfaces":g.owned_surfaces.duplicate(),"bed_surfaces":g.bed_surfaces.duplicate()}
  GardenBedSurfaces.restore(g,surface_save);GardenBedSurfaces.rebuild(g)
  check(g.bed_surfaces[str(plot)]=="bark",failures,"Habitat bed finish did not survive restore")
  GardenBedSurfaces.apply(g,plot,"soil")
 # Ordinary bed planting must reject the actual stone footprint too.
 var bed_point: Vector3=g.plots[0].center
 g.add_object("stone",bed_point,0,false,.7)
 await g.get_tree().physics_frame
 check(not g.can_plant(0,bed_point,0).is_empty(),failures,"Planting inside an ordinary bed still ignores stone surfaces")
 var temporary=g.objects.pop_back();temporary.node.free()
 var boulder=GardenAreaCatalogue.center(1)+Vector3(-5,0,-5)
 check(not g.plantable_ground(boulder),failures,"Fern Gully boulder remains plantable")
 for old in [Vector3(-5,0,5),Vector3(4,0,-5),Vector3(3,0,0),Vector3(-5,0,-6)]:
  var original=GardenAreaCatalogue.center(2)+old
  var corrected=GardenAreas.repair_starter_container("pot",original,0)
  check(corrected.distance_to(original)>.2,failures,"Original terrace container was not freed from masonry")
  check(GardenAreas.repair_starter_container("pot",original+Vector3(.2,0,0),0)==original+Vector3(.2,0,0),failures,"A moved player container was repositioned")
 # Traverse real collisions on the eastern approach and every area path.
 var walker=preload("res://tests/walking.gd")
 for segment in [[Vector3(25.2,0,6),Vector3(34.5,0,6)],[Vector3(34.5,0,6),Vector3(44.5,0,6)]]:
  await walker.cross(g,segment[0],segment[1],failures,"Eastern trail")
 var routes=[[[6,5.1],[0,5.1]],[[0,6],[0,1]],[[6.5,6],[6.5,0]],[[0,5],[0,0]],[[0,4],[0,-2]],[[0,8.5],[0,2]],[[0,7],[0,0]],[[-3.5,3],[3.5,3]],[[0,5],[0,0]],[[6,6],[6,0]]]
 for index in range(10):
  var a=routes[index][0];var b=routes[index][1];var center=GardenAreaCatalogue.center(index)
  await walker.cross(g,center+Vector3(a[0],0,a[1]),center+Vector3(b[0],0,b[1]),failures,"Trail "+GardenAreaCatalogue.entry(index).name)
 var trail_hit=g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(34.5,4,6),Vector3(34.5,-2,6)))
 check(not trail_hit.is_empty() and trail_hit.normal.y>.8 and absf(trail_hit.position.y-GardenRavine.deck(34.5,6.))<.02,failures,"Eastern trail has a backward or mismatched walking surface")
 await preload("res://tests/area_cohesion.gd").run(g,failures)
 # A restored terrain edit must move the collider along with the visible ground.
 var sculpt_ray=PhysicsRayQueryParameters3D.create(Vector3(82,12,-22),Vector3(82,-3,-22))
 sculpt_ray.exclude=[g.player.get_rid()]
 var before=g.get_world_3d().direct_space_state.intersect_ray(sculpt_ray)
 GardenSculpt.restore(g,{"82:-22":.3})
 await g.get_tree().physics_frame
 var after=g.get_world_3d().direct_space_state.intersect_ray(sculpt_ray)
 check(not before.is_empty() and not after.is_empty() and absf(after.position.y-before.position.y-.3)<.02,failures,"Edited habitat ground lost its matching collision")
 GardenSculpt.restore(g,{})
 await g.get_tree().physics_frame
 # Reedwater really follows the sluice level and depth preferences.
 var inlet=GardenAreas.state(g,0);GardenAreas.plant_collection(g,0,4,"reed",false)
 inlet.sluice=0;var low=GardenAreas.pocket_rate(g,0,4,inlet.beds["4"])
 inlet.sluice=2;var high=GardenAreas.pocket_rate(g,0,4,inlet.beds["4"])
 check(low!=high,failures,"Changing inlet does not alter depth-dependent growth (low=%s, high=%s, soil=%s)"%[low,high,GardenAreas.slot_position(g,0,4).y])
 GardenAreas.visual(g,0)
 check(is_equal_approx(g.area_roots[0].get_node("InletWater").position.y,.2),failures,"Sluice has no visible water-level change")
 inlet.sluice=1
 # Canopy controls change actual light; the discovery is obtained by walking.
 var shade=add(g,1,13,-3,2,0)
 var closed=GardenPlantInspector.growth_context(g,shade).rate
 GardenAreas.state(g,1).clearings[0]=true
 check(GardenPlantInspector.growth_context(g,shade).rate<closed,failures,"Fern clearing does not change shade preference")
 g.player.position=GardenTerrain.point(GardenAreaCatalogue.center(1)+Vector3(-3,0,3))
 GardenAreas.update(g,.6)
 check("Mossy hollow" in GardenAreas.state(g,1).discoveries and "birdsnest" in GardenAreas.choices(g,1,1),failures,"Walking discovery does not unlock fern collection")
 # Offsets preserve an independent young nursery plant with a real cooldown.
 var succulent=add(g,2,124,1,1)
 check(GardenAreas.offsets(g,succulent) and g.workshop_state.nursery.back().id==124,failures,"Mature succulent did not yield a nursery offset")
 check(not GardenAreas.offsets(g,succulent),failures,"Succulent offset cooldown ignored")
 var covered=add(g,2,125,-3,3,0)
 GardenAreas.state(g,2).shelters[0]=true
 check(not GardenAreas.rain_reaches(g,covered),failures,"Unfolded rain shelter does not keep its pocket dry")
 # A journal sighting is tied to mature, varied player flowers and pays once.
 for j in range(6):add(g,3,[0,1,2,7,36,65][j],-3+j,.0)
 var journal=GardenAreas.observe_meadow(g,false)
 var count=GardenAreas.state(g,3).journal.size()
 check(journal.size()>=3 and GardenAreas.observe_meadow(g,false).is_empty() and GardenAreas.state(g,3).journal.size()==count,failures,"Habitat journal thresholds or one-time rewards wrong")
 check(GardenAreas.season_coverage(g).size()>=3,failures,"Meadow flower calendar missing seasonal coverage")
 # Training changes the silhouette, and a compatible graft yields donor fruit.
 var fruit=g.planted.filter(func(p):return int(p.plot)==8 and int(p.id)==84)[0]
 fruit.age=float(g.catalogue[84].days);g.refresh_plant(fruit,false)
 check(GardenAreas.train(g,fruit,"espalier") and fruit.node.scale.z<fruit.node.scale.x*.5,failures,"Espalier training does not flatten a tree")
 g.inventory["85"]=4
 check(GardenAreas.graft(g,fruit,85) and fruit.node.has_node("GraftedBranch"),failures,"Compatible graft has no visible branch")
 check(not GardenAreas.graft(g,fruit,88),failures,"Incompatible graft accepted")
 var donor=int(g.inventory["85"])
 check(g.collect_plant(fruit) and int(g.inventory["85"])==donor+1,failures,"Gathering grafted tree does not yield donor fruit")
 # Companion and rotation bonuses integrate with normal growth.
 var lettuce=add(g,5,48,-3,-3,0);add(g,5,54,-3.7,-3)
 check(GardenPlantInspector.growth_context(g,lettuce).rate>=1.15,failures,"Kitchen companions have no growth benefit")
 GardenAreas.state(g,5).rotation["0"]="Roots"
 check(GardenPlantInspector.growth_context(g,lettuce).rate>=1.25,failures,"Crop rotation does not add its growth benefit")
 g.inventory.merge({"48":4,"47":4,"56":4},true)
 check(GardenAreas.kitchen_basket(g,"salad") and not GardenAreas.kitchen_basket(g,"salad"),failures,"Kitchen basket ingredients or daily limit wrong")
 # Restoration changes visible panes, out-of-season growth and pocket access.
 var cost=g.coins
 check(GardenAreas.restore_bay(g,0) and g.coins==cost-30 and not GardenAreas.restore_bay(g,0),failures,"Glasshouse restoration cost/repetition wrong")
 var restored=GardenAreas.find(g.area_roots[6],"RestoredBay0")
 check(restored!=null and restored.visible and not GardenAreas.find(g.area_roots[6],"OldBay0").visible,failures,"Restored glasshouse is not visibly different")
 var glassflower=add(g,6,0,0,-3.5,0);g.day=40
 check(GardenPlantInspector.growth_context(g,glassflower).rate>=1,failures,"Restored bay does not allow year-round growth")
 g.day=1
 # Only the selected stream strip receives ordinary irrigation.
 var west=add(g,7,8,-3,-3,0);var east=add(g,7,8,3,-3,0);west.water=0;east.water=0
 GardenAreas.state(g,7).gates=[true,false];GardenAreas.morning(g)
 check(west.water==4 and east.water==0,failures,"Stream gates irrigate the wrong strip")
 # Shelter and seasonal snowmelt have real growing/care outcomes.
 var alpine=add(g,8,14,-4,-1,0)
 check(GardenAreas.context(g,alpine,"sun").bonus>1 and GardenAreas.stress_gain(g,alpine,.13)<.13,failures,"Alpine shelter has no benefit")
 g.day=48;GardenAreas.morning(g)
 check(int(GardenAreas.state(g,8).melt)==3,failures,"Spring snowmelt did not begin after winter")
 g.day=1
 # Night flowers close in daylight and open after waiting until twilight.
 GardenAreas.plant_collection(g,9,2,"primrose",false);mature(g,9)
 g.clock_time=.42;GardenAreas.visual(g,9)
 var flowers=GardenAreas.find(g.area_roots[9].get_node("LivingCollection/Pocket0"),"Flowers")
 check(flowers!=null and not flowers.visible,failures,"Moonflowers are open in daylight")
 g.clock_time=.82;GardenAreas.visual(g,9)
 flowers=GardenAreas.find(g.area_roots[9].get_node("LivingCollection/Pocket0"),"Flowers")
 check(flowers.visible,failures,"Dusk flowers do not open at night")
 g.camera.position=GardenAreaCatalogue.center(9)+Vector3(4,3,7);GardenAreas.photograph(g)
 check(GardenAreas.state(g,9).photo,failures,"Moon Garden photo memory did not record")
 # Old generic gardens migrate indices without moving anything or losing care.
 var old={"version":2,"unlocked_plots":8,"plants":[{"id":0,"plot":5,"pos":[17,-34],"age":4,"water":2,"stress":.1}],"automation":{"5water":true},"expansions":{"5":2},"bed_surfaces":{"5":"sand"},"workshop":{"nursery":[{"plot":5}]}}
 var migrated=GardenAreaCatalogue.migrate(old)
 check(migrated.plants[0].plot==15 and migrated.plants[0].pos==old.plants[0].pos and migrated.automation.has("15water") and migrated.bed_surfaces.has("15"),failures,"Older expansion garden migration loses coordinates or controls")
 g.save_game();var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(GardenSaveFormat.valid(saved,g.catalogue.size(),g.furniture.map(func(item):return item.kind)),failures,"New areas save does not pass garden-file validation")
 var copy=saved.duplicate(true);copy.areas.gardens.reedwater.sluice=20
 check(not GardenSaveFormat.valid(copy,g.catalogue.size(),g.furniture.map(func(item):return item.kind)),failures,"Invalid area controls accepted in an imported save")
 var previous=g.areas_state.duplicate(true);GardenAreas.restore(g,saved)
 check(JSON.parse_string(JSON.stringify(g.areas_state))==JSON.parse_string(JSON.stringify(previous)),failures,"Restored area activities changed progress")
 # Real rendered previews and small-screen controls are part of the regression.
 demo(g)
 for index in range(10):await capture(g,index)
 await details(g)
 if DisplayServer.get_name()!="headless":
  g.ui.show();g.player.show();g.photo_mode=false
  for dimensions in [Vector2i(320,568),Vector2i(390,844),Vector2i(667,375)]:
   DisplayServer.window_set_size(dimensions)
   await g.get_tree().process_frame
   GardenAreaAtlas.open(g,6);await g.get_tree().process_frame;GardenAreaAtlas.fit(g)
   check(g.welcome.position.x>=0 and g.welcome.position.y>=0 and g.welcome.size.x<=g.get_viewport().get_visible_rect().size.x,failures,"Atlas exceeds a small viewport")
   await RenderingServer.frame_post_draw
   g.get_viewport().get_texture().get_image().save_png("res://captures/areas/atlas-%dx%d.png"%[dimensions.x,dimensions.y])
   GardenAreaAtlas.close(g)
  DisplayServer.window_set_size(Vector2i(1280,800))

static func details(g) -> void:
 if DisplayServer.get_name()=="headless":return
 g.ui.hide();g.touch.hide();g.player.hide();g.photo_mode=true;g.camera.fov=52
 var views=[
  [1,"fern-fronds",Vector3(5.7,4,3.9),Vector3(3,2.6,1)],
  [1,"fern-creek",Vector3(3,2.1,7),Vector3(-.1,1.1,0)],
  [1,"fallen-log",Vector3(-.5,2.5,4.7),Vector3(-3.3,1.8,2.1)],
  [2,"terrace-containers",Vector3(-1,2.4,8.4),Vector3(-4.5,1.7,6)],
  [4,"orchard-bench-soil",Vector3(-2,2.9,8),Vector3(-5,2,4)],
  [4,"harvest-table",Vector3(2.7,2.5,8.4),Vector3(0,2.1,6)],
  [5,"kitchen-beds",Vector3(1,3.1,5.8),Vector3(-3.2,1.6,1.8)],
  [6,"potted-orchids",Vector3(-1,3.4,3),Vector3(-3.8,3.05,0)],
  [6,"woven-shade",Vector3(0,2.8,3.3),Vector3(0,4.55,0)],
  [7,"stream-bridge",Vector3(-4.7,2.5,5.8),Vector3(0,1.9,3)]
 ]
 DirAccess.make_dir_recursive_absolute("res://captures/area-refinement/details")
 for view in views:
  var center=GardenAreaCatalogue.center(view[0]);g.clock_time=.43
  g.camera.global_position=center+view[2];g.camera.look_at(center+view[3]);g.update_lighting()
  await g.get_tree().process_frame;await RenderingServer.frame_post_draw
  var image=g.get_viewport().get_texture().get_image()
  image.save_png("res://captures/area-refinement/details/"+view[1]+".png")
  image.resize(960,600,Image.INTERPOLATE_LANCZOS)
  image.save_webp("res://captures/area-refinement/details/"+view[1]+"-gallery.webp",true,.65)
 g.ui.show();g.player.show();g.photo_mode=false
