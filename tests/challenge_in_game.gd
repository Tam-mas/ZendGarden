extends RefCounted

func run(g) -> Array:
 var failures=[]
 g.SAVE_PATH="/tmp/zend-challenge-in-game.json"
 g.settings.reduced_motion=true
 g.set_process(false)
 if g.garden_mode!="challenge":failures.append("Challenge entry flag")
 if g.workshop_state.resources.get("mulch",0)!=4:failures.append("Starter mulch")
 if g.challenge.offers.is_empty():failures.append("Seasonal offers")
 g.add_plant(0,Vector3(1,0,1),0)
 var p=g.planted.back()
 p.water=0;p.dry_days=3;p.age=2
 var age=p.age
 g.advance_growth()
 if p.age!=age:failures.append("Dry dormant plant grew")
 GardenChallenge.water(g,p)
 g.advance_growth()
 if p.age<=age or p.dry_days!=0:failures.append("Water did not recover growth")
 g.hover_cell=p.pos;g.hover_plot=0;g.hover_valid=true;g.hover_container_uid=""
 g.set_mode("mulch",false);g.action_cooldown=0
 g.perform_action()
 if not GardenChallenge.mulched(g,p):failures.append("Actual mulch tool")
 var key=GardenChallenge.key_for(p)
 var patch=g.challenge.patches[key]
 patch.weed=1
 g.set_mode("weed",false);g.action_cooldown=0
 g.perform_action()
 if patch.weed!=0 or g.challenge.trimmings!=1:failures.append("Safe weed action")
 g.day=5;g.challenge.intro=2
 GardenChallenge.claim_starter(g)
 var barrel=g.objects.back()
 g.current_plot=0
 g.buy_automation("water")
 var controller=g.objects.back()
 controller.work.supply=barrel.uid
 if controller.kind!="soaker_controller":failures.append("Soaker purchase")
 GardenWorkshop.close(g)
 p.water=0
 g.advance_growth()
 if p.water<2:failures.append("Connected morning irrigation")
 g.add_object("reserve_tank",Vector3(3,0,3),90)
 var tank=g.objects.back()
 GardenChallenge.refill(g,tank)
 if tank.work.water!=48:failures.append("Tank refill")
 if not g.save_game():failures.append("Challenge save failed")
 var data=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if not GardenSaveFormat.valid(data,g.catalogue.size(),g.furniture.map(func(item):return item.kind)):failures.append("Actual saved Challenge rejected")
 if data.version!=4 or data.garden_mode!="challenge":failures.append("Wrong saved mode")
 var saved_water=p.water
 g.loaded_data={};g.smoke=false;g.load_game();g.smoke=true
 if g.loaded_data.get("garden_mode","")!="challenge":failures.append("Challenge load failed")
 # Cross-mode imports must install into the other slot, preserving this garden.
 var challenge_bytes=FileAccess.get_file_as_bytes(g.SAVE_PATH)
 var free_copy={"version":3,"plants":[],"day":2,"coins":123}
 g.save_files.busy=true
 if not g.save_files.preview(JSON.stringify(free_copy).to_utf8_buffer(),"free-copy.json"):
  failures.append("Free import preview failed in Challenge")
 elif g.save_files.upload_path==g.SAVE_PATH or not g.save_files.install_upload():
  failures.append("Cross-mode import did not route to another slot")
 else:
  var preserved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
  if preserved.get("garden_mode","")!="challenge":failures.append("Cross-mode import replaced Challenge")
  if JSON.parse_string(FileAccess.get_file_as_string(g.save_files.upload_path)).coins!=123:failures.append("Other-slot import contents")
 g.save_files.finish()
 # Natural dawn and the timed skip use the same care/weather result.
 g.day=8;g.clock_time=.4;p.water=3;p.age=1;p.stress=0;p.dry_days=0
 var before_challenge=g.challenge.duplicate(true)
 g.advance_growth()
 var expected=[p.water,p.age,p.stress,p.dry_days]
 g.day=8;g.clock_time=.4;p.water=3;p.age=1;p.stress=0;p.dry_days=0
 g.challenge=before_challenge
 g.settings.reduced_motion=false
 g.next_day();g.update_day_transition(g.TRANSITION_SECONDS)
 var skipped=[p.water,p.age,p.stress,p.dry_days]
 for i in range(4):
  if not is_equal_approx(float(expected[i]),float(skipped[i])):failures.append("Waiting/skip care mismatch")
 g.settings.reduced_motion=true
 for page in ["Care","Gardens","Orders","Shop"]:
  GardenMenus.visit(g,page)
  await g.get_tree().process_frame
  if g.list_box.get_child_count()==0:failures.append("Empty "+page)
 for size in [Vector2i(1440,900),Vector2i(390,844),Vector2i(820,1180)]:
  g.get_viewport().size=size
  g.settings.controls="touch";g.touch.configure()
  GardenMenus.visit(g,"Care")
  await g.get_tree().process_frame
  await g.get_tree().process_frame
  if g.side_panel.position.x<0 or g.side_panel.position.y<0:failures.append("Care panel outside viewport")
 g.garden_mode="free"
 var free=g.add_plant(0,Vector3(2,0,2),0)
 free.water=0;free.age=0
 g.automation["0water"]=true
 g.advance_growth()
 if free.age<=0 or free.water<2:failures.append("Free watering changed")
 if GardenChallenge.active(g):failures.append("Free mode boundary")
 g.garden_mode="challenge"
 g.settings.controls="keyboard";g.touch.configure()
 if "--challenge-review" in OS.get_cmdline_user_args():await review(g)
 g.set_process(true)
 print("CHALLENGE_IN_GAME_RESULT: ",JSON.stringify(failures))
 return failures

func review(g) -> void:
 DirAccess.make_dir_recursive_absolute("res://captures/challenge")
 g.set_process(false)
 g.get_viewport().size=Vector2i(1440,900)
 g.settings.controls="keyboard";g.touch.configure()
 g.camera.position=Vector3(8,7,11);g.camera.look_at(Vector3(0,0,0))
 g.side_panel.hide()
 g.pitch=.42;g.yaw=.6
 for key in g.challenge.patches:
  var patch=g.challenge.patches[key]
  if int(patch.plot)==0:patch.weed=2;patch.weed_age=3
 GardenChallenge.rebuild(g)
 for page in ["Care","Orders","Gardens"]:
  GardenMenus.visit(g,page)
  for frame in range(8):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/challenge/desktop-"+page.to_lower()+".png")
 g.side_panel.hide();g.ui.hide()
 for frame in range(4):await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("res://captures/challenge/garden.png")
 g.ui.show()
 for size in [Vector2i(390,844),Vector2i(820,1180)]:
  g.get_viewport().size=size
  g.settings.controls="touch";g.touch.configure()
  GardenMenus.visit(g,"Care")
  for frame in range(8):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("res://captures/challenge/care-%d.png"%size.x)
