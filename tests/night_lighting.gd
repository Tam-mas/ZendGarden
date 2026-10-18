extends RefCounted

static func check(ok: bool, failures: Array, message: String) -> void:
 if not ok:failures.append(message)

static func settle(g) -> void:
 for frame in range(3):await g.get_tree().process_frame

static func capture(g, name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await settle(g)
 await RenderingServer.frame_post_draw
 var folder="res://captures/night-lighting/"+RenderingServer.get_current_rendering_method()
 DirAccess.make_dir_recursive_absolute(folder)
 g.get_viewport().get_texture().get_image().save_png(folder+"/"+name+".png")

static func key(g, code: int) -> void:
 var event=InputEventKey.new();event.pressed=true;event.physical_keycode=code
 g._unhandled_input(event)

static func run(g, failures: Array) -> void:
 g.set_process(false);g.touch.set_process(false)
 g.settings.intro_seen=true;g.settings.request_notifications=false;g.tutorial_state={"active":false}
 g.settings.controls="keyboard";g.touch.configure();g.touch.close_menu();g.dismiss_request()
 g.climate.current=Vector3.ZERO;g.climate.snow=0;g.day=22;g.clock_time=.93
 g.side_panel.hide();g.set_mode("walk")
 check(is_equal_approx(GardenNightLights.night_amount(.5),0),failures,"Lights do not switch off in daylight")
 check(is_equal_approx(GardenNightLights.night_amount(0),1),failures,"Lights do not switch on at night")
 # Torch input is independent of the active gardening tool and has no cost.
 var petals=g.coins
 key(g,KEY_T)
 check(g.night_lights.torch_on and g.night_lights.torch_beam.visible,failures,"T does not switch on the carried torch")
 g.set_mode("water");g.night_lights.update_carried()
 check(g.mode=="water" and g.night_lights.torch_beam.visible,failures,"Torch prevents use of gardening tools")
 check(g.coins==petals,failures,"Included torch charged petals")
 g.yaw=.8;g.pitch=.2;g.update_camera(0)
 check(g.night_lights.torch_beam.get_parent()==g.camera,failures,"Torch beam is not attached to the view")
 var ahead=-g.camera.global_basis.z
 check(ahead.dot(-g.night_lights.torch_beam.global_basis.z)>.98,failures,"Torch beam does not follow the view")
 var echo=InputEventKey.new();echo.pressed=true;echo.echo=true;echo.physical_keycode=KEY_T;g._unhandled_input(echo)
 check(g.night_lights.torch_on,failures,"Held T toggles repeatedly")
 var field=LineEdit.new();g.ui.add_child(field);field.grab_focus();key(g,KEY_T)
 check(g.night_lights.torch_on,failures,"Typing T toggles torch")
 field.release_focus();field.queue_free()
 g.photo_mode=true;g.night_lights.update_carried()
 check(not g.night_lights.torch_beam.visible and not g.night_lights.torch_model.visible,failures,"Torch remains in photo mode")
 g.photo_mode=false;g.day_transition=true;g.night_lights.update_carried()
 check(not g.night_lights.torch_beam.visible,failures,"Torch shines during the sky transition")
 g.day_transition=false
 GardenClearView.enter(g);g.night_lights.update_carried()
 check(not g.night_lights.torch_model.visible and g.night_lights.torch_beam.visible,failures,"Enjoy the view does not hide the prop while retaining its light")
 GardenClearView.leave(g);g.clear_view_hold_guard=false
 # Touch can carry or stow it without changing the selected tool.
 g.settings.controls="touch";g.touch.configure();g.touch.show_drawer("tools")
 var toggle=g.touch.drawer.find_child("ToolTorch",true,false)
 check(toggle!=null,failures,"Touch tool tray has no torch control")
 if toggle:toggle.pressed.emit()
 check(not g.night_lights.torch_on and g.mode=="water",failures,"Touch torch control changes the gardening tool")
 g.settings.controls="keyboard";g.touch.configure();g.set_mode("walk")
 # The Lighting shop section includes both the old lantern and the additions.
 g.coins=1000;g.active_tab="Shop";g.menu_sections.shop="Lighting";g.side_panel.show();g.refresh_sidebar()
 await settle(g)
 var cards=g.list_box.get_node_or_null("OrnamentCards")
 check(cards!=null and cards.get_child_count()==4,failures,"Lighting shop must contain four placeable lights")
 check(g.list_box.get_node_or_null("ShopTorch")!=null,failures,"Shop does not explain the included torch")
 await capture(g,"shop-lighting")
 var created: Array=[]
 var new_kinds=["path_lantern","garden_lamppost","garden_floodlight"]
 for i in range(new_kinds.size()):
  g.active_tab="Shop";g.menu_sections.shop="Lighting";g.refresh_sidebar();await settle(g)
  var kind=new_kinds[i]
  var card=g.list_box.find_child("Shop_"+kind,true,false)
  check(card!=null,failures,"Missing shop card: "+kind)
  if card==null:continue
  card.pressed.emit()
  var before=g.objects.size();var price=int(g.furniture[g.selected_furniture].price);var coins=g.coins
  g.structure_rotation=.4+i*.3
  g.hover_valid=true;g.hover_target=-1;g.hover_object=null;g.hover_container_uid="";g.hover_plot=0
  g.hover_cell=GardenTerrain.point(Vector3(-9+i*2,0,1));g.action_cooldown=0;g.perform_action()
  check(g.objects.size()==before+1 and g.coins==coins-price,failures,"Purchase/placement failed: "+kind)
  if g.objects.size()!=before+1:continue
  var obj=g.objects.back();created.append(obj)
  check(obj.node.has_node("NightLight"),failures,"No real light attached: "+kind)
  check(is_equal_approx(obj.node.rotation.y,obj.rotation),failures,"Light ignores placement rotation: "+kind)
  check(not obj.node.get_meta("night_glow",[]).is_empty(),failures,"No visible lamp diffuser: "+kind)
  check(obj.node.get_node_or_null("StructureTarget")!=null,failures,"Light cannot be picked up or removed: "+kind)
 g.side_panel.hide();g.set_mode("walk");g.night_lights.update_lights()
 for obj in created:
  var light: Light3D=obj.node.get_node("NightLight")
  check(light.visible and light.light_energy>0,failures,"Placed light does not illuminate at night: "+obj.kind)
  if light is SpotLight3D:check(light.spot_range>=15 and is_equal_approx(light.global_rotation.y,obj.rotation),failures,"Floodlight beam ignores saved heading")
 g.clock_time=.5;g.night_lights.update_lights()
 for obj in created:
  check(not obj.node.get_node("NightLight").visible,failures,"Placed light stays on during the day")
  for mat in obj.node.get_meta("night_glow",[]):check(is_zero_approx(mat.emission_energy_multiplier),failures,"Lamp glow stays on during the day")
 g.clock_time=.93
 # Movement inherits the light's location/heading without storing light nodes.
 if not created.is_empty():
  var obj=created[0];var index=g.objects.find(obj)
  g.set_mode("move");g.moved_object=index;g.structure_rotation=1.1
  g.hover_valid=true;g.hover_plot=0;g.hover_cell=GardenTerrain.point(Vector3(-10,0,3));g.action_cooldown=0;g.perform_action()
  check(obj.pos.distance_to(GardenTerrain.point(Vector3(-10,0,3)))<.02,failures,"Placed light cannot be moved")
  check(is_equal_approx(obj.node.global_rotation.y,1.1),failures,"Moved light loses heading")
 check(g.save_game(),failures,"Lighting garden could not save")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 var kinds=g.furniture.map(func(item):return item.kind)
 check(not GardenSaveFormat.read(JSON.stringify(saved).to_utf8_buffer(),g.catalogue.size(),kinds).has("error"),failures,"Save validation rejects lighting items")
 var lights=saved.objects.filter(func(item):return item.kind in new_kinds)
 check(lights.size()==3,failures,"New light identities missing from save")
 var before_restore=g.objects.size()
 g.loaded_data={"version":3,"plants":[],"objects":lights};g.restore_garden()
 check(g.objects.size()==before_restore+3,failures,"Lighting items failed to restore")
 for i in range(before_restore,g.objects.size()):
  var obj=g.objects[i]
  check(obj.node.has_node("NightLight"),failures,"Restored object has no light")
  check(is_equal_approx(obj.node.rotation.y,float(obj.rotation)),failures,"Restored light lost heading")
 while g.objects.size()>before_restore:
  var restored=g.objects.pop_back()
  restored.node.queue_free()
 # Place many lights; only nearby lights may consume the finite renderer budget.
 var stress: Array=[]
 for i in range(12):
  g.add_object("path_lantern",GardenTerrain.point(Vector3(-8+(i%4),0,4+floori(i/4.0))),30)
  stress.append(g.objects.back())
 g.night_lights.torch_on=true;g.night_lights.update_lights()
 var active=1
 for obj in g.objects:
  if obj.node.has_node("NightLight") and obj.node.get_node("NightLight").visible:active+=1
 check(active<=GardenNightLights.MAX_LOCAL_LIGHTS,failures,"Too many local lights enabled for a dense garden")
 for obj in stress:g.objects.erase(obj);obj.node.queue_free()
 # Exercise the normal structure removal/refund against an authored surface.
 if not created.is_empty():
  # Headless has no captured mouse; touch uses the same centre-screen ray.
  if DisplayServer.get_name()=="headless":
   g.settings.controls="touch";g.touch.configure();g.touch.close_menu()
  var obj=created.back();g.set_mode("remove")
  # Aim at the broad front lens, clear of the restored copy and starter plants.
  obj.pos=GardenTerrain.point(Vector3(-12,0,5));obj.node.position=obj.pos
  for frame in range(3):await g.get_tree().physics_frame
  var face=obj.node.global_transform*Vector3(0,1.5,-.09)
  var forward=-obj.node.global_basis.z
  g.player.position=GardenTerrain.point(obj.pos+forward*3)+Vector3(0,.1,0)
  g.camera.global_position=face+forward*3
  g.camera.look_at(face)
  g.hover_target=-1;g.update_hover();GardenPlantInspector.update(g)
  var aimed=g.aimed_object();var plant=g.aimed_plant()
  var count=g.objects.size();var coins=g.coins;g.action_cooldown=0;g.perform_action()
  check(g.objects.size()==count-1 and g.coins==coins+obj.price,failures,"Light removal/refund failed (aimed %d, plant %d, objects %d -> %d, coins %d -> %d)"%[aimed,plant,count,g.objects.size(),coins,g.coins])
 # Restore one view for matched screenshots of actual garden illumination.
 g.settings.controls="keyboard";g.touch.configure();g.set_mode("walk");g.side_panel.hide()
 g.player.position=GardenTerrain.point(Vector3(-7,0,7))+Vector3(0,.1,0)
 g.yaw=0;g.pitch=.12;g.clock_time=.93;g.day=22
 g.update_camera(0);g.update_lighting();g.climate.apply(g);g.update_hud()
 g.night_lights.torch_on=false;g.night_lights.update_lights();g.update_hud()
 await capture(g,"garden-lights")
 # A matched torch comparison disables placed lighting in this view only.
 var previous_energy: Array=[]
 for obj in g.objects:
  if obj.node.has_node("NightLight"):
   var light=obj.node.get_node("NightLight");previous_energy.append([light,light.visible]);light.visible=false
 g.night_lights.set_process(false)
 await capture(g,"torch-off")
 g.night_lights.torch_on=true;g.night_lights.update_carried();g.update_hud()
 await capture(g,"torch-on")
 for pair in previous_energy:
  if is_instance_valid(pair[0]):pair[0].visible=pair[1]
 g.night_lights.set_process(true)
