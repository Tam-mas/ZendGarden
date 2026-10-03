extends RefCounted

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.settings.request_notifications=false
 g.dismiss_request()
 g.set_mode("walk")
 var bench=g.objects.filter(func(o):return o.kind=="bench")[0]
 bench.node.rotation.y=PI/4;bench.rotation=PI/4
 var start=GardenTerrain.point(bench.pos+Vector3(0,0,-2))+Vector3(0,.1,0)
 g.player.position=start
 g.yaw=PI
 GardenLeisure.interact(g)
 if g.rest_kind!="bench":failures.append("Nearby facing bench was not interactable")
 g.update_camera(0)
 if absf(g.camera.position.y-g.player.position.y-.72)>.01:failures.append("Bench did not lower the eye position")
 if absf(g.yaw-PI/4)>.01:failures.append("Bench rotation was not respected")
 if (-g.camera.global_basis.z).dot(bench.node.global_basis.z)>-.9:failures.append("Seat faces into the bench back")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if Vector2(saved.player[0],saved.player[1]).distance_to(Vector2(start.x,start.z))>.01:failures.append("Resting save put the player inside furniture")
 GardenLeisure.call_pet(g,0,true)
 GardenLeisure.call_pet(g,1,true)
 for i in range(2):
  var pet=g.pets[i]
  var initial=pet.position
  pet.animate(g,.2,i)
  if pet.command_kind!="settle" or pet.destination!=pet.command_point or pet.command_time<89:failures.append("Companion did not follow the invitation")
  # Run the actual navigation and animation until it arrives.
  for frame in range(900):pet.animate(g,1.0/30.0,i)
  if Vector2(pet.position.x-pet.command_point.x,pet.position.z-pet.command_point.z).length()>.7 or pet.behaviour!="settle":failures.append("Companion could not walk to and settle beside the bench")
  pet.position=GardenTerrain.point(g.rest_object.to_global(Vector3(-.8 if i==0 else .8,0,-1.6)))
 var nearest=0 if g.player.position.distance_to(g.pets[0].position)<=g.player.position.distance_to(g.pets[1].position) else 1
 g.greet_pet()
 if g.pets[nearest].affection<=0:failures.append("Petting did not trigger affection")
 g.pets[nearest].animate(g,.1,nearest)
 if g.pets[nearest].behaviour!="pet":failures.append("Petting animation missing")
 GardenLeisure.update(g)
 g.pitch=.5
 g.refresh_ui();g.update_camera(0)
 await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("res://captures/bench-companions.png")
 if Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE:failures.append("Seated invitation buttons were not clickable")
 GardenLeisure.leave(g)
 if not g.rest_kind.is_empty() or g.player.position.distance_to(start)>.2:failures.append("Standing did not return to safe ground")
 g.player.position=bench.pos+Vector3(0,0,-6)
 GardenLeisure.rest(g,bench)
 if not g.rest_kind.is_empty():failures.append("Bench was usable beyond reach")
 for kind in ["pergola","pond"]:
  g.add_object(kind,Vector3(4,0,4),0,kind=="pond",PI/3)
  var obj=g.objects.back()
  g.player.position=obj.pos+Vector3(0,.1,-2)
  GardenLeisure.rest(g,obj)
  if g.rest_kind!=kind:failures.append("Missing rest interaction: "+kind)
  g.update_camera(0)
  if kind=="pond":
   var forward=-g.camera.global_basis.z
   var direction=(obj.pos-g.camera.position).normalized()
   if forward.dot(direction)<.7:failures.append("Pond view did not face the water")
  g.set_mode("water")
  if not g.rest_kind.is_empty():failures.append("Switching tools did not leave resting")
  g.set_mode("walk")
 g.player.position=GardenTerrain.point(bench.pos+Vector3(0,0,-2))+Vector3(0,.1,0)
 GardenLeisure.rest(g,bench)
 bench.node.queue_free()
 GardenLeisure.update(g)
 if not g.rest_kind.is_empty():failures.append("Removed furniture left a stuck seated player")
 g.objects.erase(bench)
 g.pets[0].command_time=0;g.pets[0].affection=0;g.pets[0].routine_time=37;g.clock_time=.4
 g.pets[0].destination=g.pets[0].position;g.pets[0].wander_cycle=int((37)/24.0)
 g.pets[0].animate(g,.01,0)
 if g.pets[0].behaviour!="stretch":failures.append("Cat sunny stretch animation missing")
 g.pets[1].command_time=0;g.pets[1].affection=0;g.pets[1].routine_time=24
 g.pets[1].destination=g.pets[1].position;g.pets[1].wander_cycle=int((24+11)/24.0)
 g.pets[1].animate(g,.01,1)
 if g.pets[1].behaviour!="sniff":failures.append("Dog investigating animation missing")
 g.settings.controls="touch";g.touch.configure()
 g.set_mode("walk")
 g.touch.show_drawer("garden")
 await g.get_tree().process_frame
 var buttons=g.touch.drawer.find_children("*","Button",true,false)
 if not buttons.any(func(b):return b.text=="Call "+g.companion_names[0]):failures.append("Touch companion call missing")
 g.touch.close_menu()
 g.settings.controls="keyboard";g.touch.configure()
 g.set_process(true)
