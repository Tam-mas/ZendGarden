extends RefCounted

static func run(g, failures: Array) -> void:
 for key in [KEY_UP,KEY_RIGHT,KEY_DOWN,KEY_LEFT]:
  var event=InputEventKey.new()
  event.physical_keycode=key
  event.pressed=true
  Input.parse_input_event(event)
  Input.flush_buffered_events()
  var expected={KEY_UP:Vector2(0,-1),KEY_RIGHT:Vector2(1,0),KEY_DOWN:Vector2(0,1),KEY_LEFT:Vector2(-1,0)}
  if g.navigation_input()!=expected[key]: failures.append("Arrow navigation failed")
  var release=event.duplicate()
  release.pressed=false
  Input.parse_input_event(release)
  Input.flush_buffered_events()
 # Tomato is selectable once unlocked and planting is allowed in every season.
 g.coins=100
 g.choose_plant(49)
 if g.selected!=49 or 49 not in g.unlocked_plants: failures.append("Tomato seed selection failed")
 var old_day=g.day
 for day in [1,13,25,37]:
  g.day=day
  var pos=GardenTerrain.point(Vector3(-1.6,0,3.6))
  if not g.can_plant(49,pos,0).is_empty(): failures.append("Tomato planting blocked in "+GardenClimate.season(day))
 g.day=old_day
 var outside=g.add_plant(0,Vector3(-4,0,7.2),0,4)
 var inside=g.add_plant(20,Vector3(-4,0,3.6),0,10)
 g.mode="prune"
 g.hover_valid=true
 for plant in [outside,inside]:
  g.hover_cell=plant.pos
  for cut in range(3):
   g.action_cooldown=0
   g.perform_action()
 if outside in g.planted: failures.append("Three outside cuts did not remove the plant")
 if inside not in g.planted: failures.append("Bed pruning removed a plant")
 var wild=g.wild_plants[0]
 for cut in range(3): GardenCare.prune_wild(g,wild.pos,.1)
 if wild.node.visible: failures.append("Wild planting was not cleared")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if int(saved.wild_pruning.get(wild.key,0))!=3: failures.append("Border clearing not saved")
 GardenCare.restore_wild(g)
 if wild.node.visible: failures.append("Border clearing lost on restore")
 # Find clear lawn and validate widening instead of duplicate overlapping meshes.
 var spot=Vector3(-7,0,8)
 for plant in g.wild_plants:
  if plant.pos.distance_to(GardenTerrain.point(spot))<2: g.wild_pruning[plant.key]=3
 GardenCare.restore_wild(g)
 g.hover_cell=GardenTerrain.point(spot)
 g.upgrades.rake=0
 GardenCare.rake(g)
 var key="-7:8"
 if key not in g.path_widths: failures.append("Raking did not create a path")
 else:
  var first=g.raked_nodes[key]
  g.upgrades.rake=2
  GardenCare.rake(g)
  if g.path_widths[key]<1.89 or not first.is_queued_for_deletion(): failures.append("Upgraded rake did not replace and widen the path")
  if g.raked_nodes[key].get_child_count()==0: failures.append("Rake furrows missing")
 var coins=g.coins
 GardenCare.rake(g)
 if coins!=g.coins: failures.append("Repeated raking farmed petals")
 g.add_object("hive",Vector3(-8,0,5),65)
 g.refresh_wildlife()
 if g.wildlife.filter(func(w): return w.get("hive",false)).size()!=4: failures.append("Hive did not bring four bees")
 g.save_game()
 saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if not saved.objects.any(func(o): return o.kind=="hive"): failures.append("Hive not saved")
 g.visitors.random.seed=19
 for guest in g.visitors.guests: guest.node.queue_free()
 g.visitors.guests.clear()
 await g.get_tree().process_frame
 g.visitors.spawn_group(true)
 if g.visitors.guests.size()!=2 or not g.visitors.guests.any(func(v): return v.node.name=="KangarooWithJoey"): failures.append("Kangaroo family missing")
 for guest in g.visitors.guests: guest.node.queue_free()
 g.visitors.guests.clear()
 await g.get_tree().process_frame
 g.visitors.spawn_group(false)
 if g.visitors.guests.size()!=3: failures.append("Rabbit visitors missing")
 g.visitors._process(66)
 if not g.visitors.guests.is_empty(): failures.append("Visitors did not leave")
 print("GARDEN_ADDITIONS_RESULT: ",failures)
