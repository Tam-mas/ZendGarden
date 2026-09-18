extends RefCounted

static func run(g, failures: Array) -> void:
 # Catch a stale .godot scene even when the source GLB and scripts are current.
 var glb=FileAccess.open("res://assets/environment/lake_garden.glb",FileAccess.READ)
 glb.seek(12)
 var json_length=glb.get_32()
 glb.get_32()
 var document=JSON.parse_string(glb.get_buffer(json_length).get_string_from_utf8())
 for mesh in document.meshes:
  if mesh.name in ["AlpineLakeValley","ContourLake","ShorelineRocks","OuterMountainRidges"] or mesh.name.begins_with("ForestChunk_"):
   var expected=0
   for surface in mesh.primitives: expected+=int(document.accessors[int(surface.indices)].count)
   var node=g.world_root.find_child(mesh.name,true,false)
   var actual=0
   if is_instance_valid(node):
    for i in range(node.mesh.get_surface_count()): actual+=node.mesh.surface_get_array_index_len(i)
   if actual!=expected: failures.append("Stale imported environment mesh: "+mesh.name)
 for id in range(60):
  if not is_equal_approx(GardenCatalogue.saved_age(id, float(GardenCatalogue.ROWS[id][4])*.5,1),g.catalogue[id].days*.5): failures.append("Legacy growth migration changed maturity")
 var old_day=g.day
 var old_clock=g.clock_time
 var old_open=g.unlocked_plots
 var old_weather=g.climate.save_state()
 var old_position=g.player.position
 var old_yaw=g.yaw
 var old_pitch=g.pitch
 g.unlocked_plots=4
 # Every bed and purchased expansion doubles its already increased capacity.
 for i in range(4):
  if g.plot_capacity(i)!=(int(g.plots[i].cap)+int(g.expansions.get(str(i),0))*20)*4: failures.append("Bed density did not double")
 var center=g.plots[3].center
 var test_plants: Array=[]
 for i in range(170):
  var position=g.snap_to_bed(center+Vector3((i%15-7)*g.GRID,0,(int(i/15)-7)*g.GRID),3)
  var id=[0,1,2,7,37][i%5]
  if not g.can_plant(id,position,3).is_empty(): failures.append("Dense bed rejected plant "+str(i)); break
  test_plants.append(g.add_plant(id,position,3,g.catalogue[id].days))
 if test_plants.size()!=170 or g.capacity_used(3)!=340: failures.append("Dense bed capacity count incorrect")
 if g.can_plant(0,g.snap_to_bed(center+Vector3(4,0,4),3),3).is_empty(): failures.append("Dense bed exceeded capacity")
 # Dormancy retains progress; the same plant resumes in season or under glass.
 var seasonal=g.add_plant(47,g.snap_to_bed(Vector3(17,0,0),1),1,0)
 test_plants.append(seasonal)
 if not seasonal.marker.visible: failures.append("New seed marker missing")
 g.day=1
 if g.growth_conditions(seasonal)!=0: failures.append("Summer tomato growing in spring")
 var before=seasonal.age
 g.advance_growth()
 if seasonal.age!=before: failures.append("Dormant plant lost or gained progress")
 g.day=13
 if g.growth_conditions(seasonal)<=0: failures.append("Seasonal growth did not resume in summer")
 g.advance_growth()
 if seasonal.age<=before: failures.append("In-season plant failed to grow")
 g.day=37
 g.add_object("greenhouse",seasonal.pos,120)
 var greenhouse=g.objects.back()
 if g.growth_conditions(seasonal)!=1: failures.append("Greenhouse does not protect seasonal plants")
 g.objects.erase(greenhouse)
 greenhouse.node.queue_free()
 seasonal.age=g.catalogue[47].days
 g.refresh_plant(seasonal)
 if seasonal.marker.visible: failures.append("Mature plant marker did not retire")
 # Rain fades in continuously and actually waters a dry plant.
 g.day=1
 g.clock_time=.75
 g.climate.restore({"values":[0,0,0],"target":"Clear","snow":0,"slot":-1})
 seasonal.water=0
 g.climate.update(g,.5)
 if g.climate.current.y<=0 or g.climate.current.y>=1: failures.append("Weather transition is abrupt")
 for i in range(80): g.climate.update(g,.5)
 if g.climate.current.y<.99 or seasonal.water<=0: failures.append("Rain did not arrive or water plants")
 var serialized=g.climate.save_state()
 g.climate.restore(serialized)
 if g.climate.save_state()!=serialized: failures.append("Weather save round trip failed")
 g.day=37
 g.climate.slot=-1
 g.climate.update(g,.1)
 if g.climate.target!="Snow": failures.append("Winter precipitation is not snow")
 if GardenClimate.season(49)!="Spring": failures.append("Season year did not wrap")
 # Terrain sampling, placement and actual character collision agree.
 var low=GardenTerrain.point(Vector3(-4,0,0))
 var high=GardenTerrain.point(Vector3(4,0,0))
 if high.y-low.y<.3: failures.append("Garden bed remained flat")
 g.player.position=high+Vector3(0,.2,0)
 await g.get_tree().create_timer(.5).timeout
 if absf(g.player.position.y-high.y)>.15: failures.append("Player collision does not follow raised soil")
 g.player.position=Vector3(8.5,.4,5.9)
 await g.get_tree().create_timer(.5).timeout
 if absf(g.player.position.y-.155)>.12: failures.append("Bridge deck collision failed")
 GardenCompanion.prepare_navigation(g)
 var route=GardenCompanion.navigation.get_point_path(Vector2i(0,12),Vector2i(34,12))
 if route.size()<2: failures.append("Companion cannot route over bridge")
 for p in route:
  if not g.accessible(Vector3(p.x,0,p.y)): failures.append("Companion route crosses water")
 for pet in g.pets:
  if not is_instance_valid(pet.body) or pet.legs.size()!=4: failures.append("Articulated companion joints missing")
  var tail_before=pet.tail.rotation.y
  pet.animate(g,.15,0)
  if pet.tail.rotation.y==tail_before: failures.append("Companion tail is not animated")
 # Visual acceptance captures: packed flowers, seed stakes, pets and winter weather.
 g.day=13
 g.clock_time=.40
 g.climate.restore({"values":[0,0,0],"target":"Clear","snow":0,"slot":37})
 g.player.position=GardenTerrain.point(center+Vector3(0,0,6))+Vector3(0,.1,0)
 g.yaw=0
 g.pitch=.22
 g.ui.hide()
 await g.get_tree().create_timer(1.2).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/dense-seasonal-garden.png")
 for i in range(4):
  var marker=g.add_plant([51,47,28,1][i],g.snap_to_bed(Vector3(-1.15+i*g.GRID,0,3.45),0),0,0)
  test_plants.append(marker)
 g.player.position=GardenTerrain.point(Vector3(0,0,5.5))+Vector3(0,.1,0)
 g.pitch=.72
 await g.get_tree().create_timer(.4).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/new-plant-markers.png")
 g.player.position=GardenTerrain.point(Vector3(-6.6,0,8))+Vector3(0,.1,0)
 g.pitch=.38
 g.pets[0].position=GardenTerrain.point(Vector3(-7.3,0,5.4))
 g.pets[1].position=GardenTerrain.point(Vector3(-5.9,0,5.4))
 for pet in g.pets: pet.path.clear(); pet.route_timer=10; pet.rotation.y=PI
 await g.get_tree().create_timer(.5).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/companions.png")
 g.day=37
 g.clock_time=.75
 g.climate.restore({"values":[.85,0,.55],"target":"Snow","snow":1,"slot":-1})
 g.pitch=.1
 await g.get_tree().create_timer(3).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/winter-snow.png")
 for plant in test_plants:
  g.planted.erase(plant)
  plant.node.queue_free()
  plant.marker.queue_free()
 g.ui.show()
 g.day=old_day
 g.clock_time=old_clock
 g.unlocked_plots=old_open
 g.climate.restore(old_weather)
 g.player.position=old_position
 g.yaw=old_yaw
 g.pitch=old_pitch
