extends RefCounted

static func run(g, failures: Array) -> void:
 g.day_transition=false
 g.photo_mode=false
 g.side_panel.hide()
 var old_clock=g.clock_time
 g.clock_time=.4
 g.day=1
 var center=GardenTerrain.point(Vector3(2,0,3))
 if not GardenSculpt.allowed(g,center):
  for x in range(-3,5):
   for z in range(-3,5):
    var candidate=GardenTerrain.point(Vector3(x,0,z))
    if GardenSculpt.allowed(g,candidate) and GardenSculpt.allowed(g,candidate+Vector3(1,0,0)) and GardenSculpt.allowed(g,candidate+Vector3(0,0,1)):center=candidate
 # Ground watering benefits future planting and refreshes a single timer.
 GardenTools.water_ground(g,center,.65)
 var until=GardenTools.boost_until(g,center)
 if not is_equal_approx(until,GardenTools.now(g)+1):failures.append("Water bonus duration")
 GardenTools.water_ground(g,center,.65)
 if not is_equal_approx(GardenTools.growth_multiplier(g,center,GardenTools.now(g)),1.2):failures.append("Water bonus stacks or is missing")
 if GardenTools.growth_multiplier(g,center,until)!=1:failures.append("Water bonus does not expire")
 if GardenTools.growth_multiplier(g,center+Vector3(2,0,0),GardenTools.now(g))!=1:failures.append("Water bonus leaks outside watered ground")
 var wet=g.add_plant(0,center,0)
 var dry=g.add_plant(0,GardenTerrain.point(center+Vector3(2,0,0)),0)
 wet.age=0;dry.age=0;wet.water=4;dry.water=4;wet.stress=0;dry.stress=0
 var wet_expected=g.growth_conditions(wet)*1.2
 var dry_expected=g.growth_conditions(dry)
 if wet_expected<=0 or dry_expected<=0:failures.append("Growth test plants are dormant")
 g.advance_growth()
 if not is_equal_approx(wet.age,wet_expected) or not is_equal_approx(dry.age,dry_expected):failures.append("Actual daily growth does not apply exactly 20 percent")
 if GardenTools.growth_multiplier(g,center,GardenTools.now(g))!=1:failures.append("Water bonus remains after its day")
 g.mode="prune"
 var old_level=g.upgrades.shears
 for level in range(3):
  g.upgrades.shears=level
  var limit=1.3*pow(1.1,level)
  g.prune_width=100
  GardenTools.resize_pruners(g,1)
  if not is_equal_approx(g.prune_width,limit):failures.append("Pruner purchased maximum incorrect")
  for i in range(20):GardenTools.resize_pruners(g,-1)
  if not is_equal_approx(g.prune_width,GardenTools.PRUNE_MIN):failures.append("Pruner minimum incorrect")
 g.upgrades.shears=old_level
 g.prune_width=1.3
 if not GardenTools.in_square(center,center+Vector3(.64,20,.64),1.3) or GardenTools.in_square(center,center+Vector3(.66,0,0),1.3):failures.append("Pruning is not a square independent of terrain height")
 g.hover_valid=true;g.hover_cell=center;g.action_cooldown=0
 wet.pruned=0;dry.pruned=0
 g.perform_action()
 if wet.pruned!=1 or dry.pruned!=0:failures.append("Pruning action ignores selected footprint")
 # Exercise the real keyboard dispatch and touch button callbacks.
 var key=InputEventKey.new();key.pressed=true;key.physical_keycode=KEY_9
 g._unhandled_input(key)
 if g.mode!="hoe":failures.append("9 does not equip hoe")
 var was_raise=g.hoe_raise
 key.physical_keycode=KEY_R;g._unhandled_input(key)
 if g.hoe_raise==was_raise:failures.append("R does not toggle hoe")
 key.physical_keycode=KEY_4;g._unhandled_input(key)
 var width=g.prune_width
 key.physical_keycode=KEY_BRACKETLEFT;g._unhandled_input(key)
 if g.prune_width>=width:failures.append("Bracket key does not shrink pruning square")
 var controls=g.settings.controls
 g.settings.controls="touch";g.touch.configure();g.touch.close_menu()
 g.mode="prune";g.touch._process(0)
 width=g.prune_width
 g.touch.buttons.left.pressed.emit()
 if g.prune_width>=width or not g.touch.buttons.right.visible:failures.append("Touch pruner resize controls missing")
 g.mode="hoe";g.touch._process(0);was_raise=g.hoe_raise
 g.touch.buttons.layer.pressed.emit()
 if g.hoe_raise==was_raise or not g.touch.buttons.action.text.contains("ground"):failures.append("Touch hoe controls missing")
 g.settings.controls=controls;g.touch.configure()
 # Hoe modifies real ground, attached plants and physical walking collision.
 g.mode="hoe";g.hoe_raise=true;g.hover_cell=center
 if not GardenSculpt.allowed(g,center):failures.append("Test soil unexpectedly protected")
 var before=GardenTerrain.point(center).y
 var capture="--tools-test" in OS.get_cmdline_user_args()
 var camera: Camera3D
 if capture:
  camera=Camera3D.new();g.add_child(camera)
  camera.position=center+Vector3(4,3,5);camera.look_at(center);camera.current=true
  g.ui.hide();g.mode="walk";g.grid_cursor.hide();g.area_cursor.hide()
  DirAccess.make_dir_recursive_absolute("res://captures/tools")
  await g.get_tree().create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/tools/hoe-before.png")
  g.mode="hoe"
 g.hover_cell=center
 var started=Time.get_ticks_usec()
 GardenSculpt.apply_hoe(g)
 print("HOE_EDIT_MILLISECONDS: ",(Time.get_ticks_usec()-started)/1000.0)
 var raised=GardenTerrain.point(center).y
 if raised<=before+.1:failures.append("Hoe did not raise terrain")
 if absf(wet.node.position.y-raised)>.001:failures.append("Plant left behind by terrain edit")
 await g.get_tree().physics_frame
 await g.get_tree().physics_frame
 var query=PhysicsRayQueryParameters3D.create(Vector3(center.x,raised+4,center.z),Vector3(center.x,raised-4,center.z))
 var hit=g.get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty() or absf(hit.position.y-raised)>.16:failures.append("Hoe collision disagrees with visible height")
 var ray=GardenTerrain.ray(Vector3(center.x,raised+4,center.z),Vector3.DOWN)
 if absf(ray.y-raised)>.001:failures.append("Planting ray ignores sculpted height")
 if GardenSculpt.allowed(g,Vector3(8.5,0,5.9)) or GardenSculpt.allowed(g,Vector3(-7.4,0,-18)):failures.append("Hoe allows editing bridge or pavilion")
 GardenTools.water_ground(g,center,.65)
 g.prune_width=.78
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if saved.terrain.is_empty() or saved.watered_ground.is_empty() or absf(saved.prune_width-.78)>.001 or not saved.hoe_raise:failures.append("New tool state missing from save")
 GardenSculpt.restore(g,saved.terrain)
 if absf(GardenTerrain.point(center).y-raised)>.001:failures.append("Saved terrain does not restore")
 GardenTools.toggle_hoe(g)
 g.hover_cell=center
 GardenSculpt.apply_hoe(g)
 if absf(GardenTerrain.point(center).y-before)>.001:failures.append("Lowering does not reverse raising")
 GardenTools.restore_water(g,saved.watered_ground)
 if not is_equal_approx(GardenTools.growth_multiplier(g,center,GardenTools.now(g)),1.2):failures.append("Saved watering boost does not restore")
 g.refresh_wildlife();g.clock_time=.4;g.animate_garden(0,3.0)
 var beetles=g.wildlife.filter(func(entry):return entry.kind=="lady beetle")
 if beetles.size()!=3:failures.append("Flower garden has no lady beetles")
 for entry in beetles:
  if not entry.node.visible or absf(entry.node.position.y-GardenTerrain.point(entry.node.position).y-.008)>.001:failures.append("Lady beetle does not crawl on ground")
  if entry.legs.size()!=6:failures.append("Lady beetle is missing articulated legs")
 g.clock_time=.9;g.animate_garden(0,3.0)
 for entry in beetles:
  if entry.node.visible:failures.append("Lady beetles remain active at night")
 if capture:
  g.clock_time=.4;g.mode="walk"
  g.hoe_raise=true;g.hover_cell=center
  for i in range(6):GardenSculpt.apply_hoe(g)
  await g.get_tree().create_timer(.3).timeout
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/tools/hoe-after.png")
  camera.queue_free();g.camera.current=true;g.ui.show()
 g.clock_time=old_clock
 print("GARDEN_TOOLS_RESULT: ",failures)
