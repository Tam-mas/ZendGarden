extends RefCounted

static func check(value: bool, failures: Array, message: String) -> void:
 if not value:failures.append(message)

static func space(g, echo: bool=false) -> void:
 var event=InputEventKey.new()
 event.physical_keycode=KEY_SPACE
 event.pressed=true
 event.echo=echo
 g._unhandled_input(event)

static func step(g, motion: Vector3=Vector3.ZERO) -> void:
 await g.get_tree().physics_frame
 g.move_player(motion,g.get_physics_process_delta_time())
 g.update_camera(0)

static func land(g, failures: Array) -> void:
 for frame in range(180):
  await step(g)
  if g.player.is_on_floor():return
 failures.append("Jump did not land on the garden surface")

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.settings.controls="touch" if DisplayServer.get_name()=="headless" else "keyboard"
 g.settings.request_notifications=false
 g.touch.configure()
 g.dismiss_request()
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.set_mode("walk")
 g.side_panel.hide()
 # Headless uses the touch gameplay gate because it cannot capture a pointer.
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 g.player.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.65,0)
 g.player.velocity=Vector3.ZERO
 await land(g,failures)
 var floor_y=g.player.position.y
 check(g.can_jump(),failures,"Grounded player cannot jump")
 var binding=InputEventKey.new()
 binding.physical_keycode=KEY_SPACE
 check(InputMap.event_is_action(binding,"jump"),failures,"Space is not bound to the jump action")
 # Exercise Godot's real input dispatch as well as the direct guard checks.
 binding.pressed=true
 Input.parse_input_event(binding);Input.flush_buffered_events()
 binding=binding.duplicate();binding.pressed=false
 Input.parse_input_event(binding);Input.flush_buffered_events()
 check(g.jumps_used==1 and g.player.velocity.y>0,failures,"Space did not start the first jump")
 space(g,true)
 check(g.jumps_used==1,failures,"Keyboard repeat consumed the double jump")
 var single_peak=floor_y
 for frame in range(65):
  await step(g)
  single_peak=maxf(single_peak,g.player.position.y)
  if g.player.is_on_floor():break
 check(single_peak-floor_y>.8 and single_peak-floor_y<1.2,failures,"Single jump has an unexpected height: "+str(single_peak-floor_y))
 check(g.player.is_on_floor() and g.jumps_used==0,failures,"Landing did not restore jumping")
 # Press again near the apex. A third press must not reset falling velocity.
 space(g)
 for frame in range(18):await step(g)
 var before_second=g.player.position.y
 space(g)
 check(g.jumps_used==2 and is_equal_approx(g.player.velocity.y,g.JUMP_SPEED),failures,"Second press did not boost the airborne player")
 for frame in range(5):await step(g)
 var falling_speed=g.player.velocity.y
 space(g)
 check(g.jumps_used==2 and is_equal_approx(g.player.velocity.y,falling_speed),failures,"Third press allowed an extra jump")
 var double_peak=g.player.position.y
 for frame in range(100):
  await step(g)
  double_peak=maxf(double_peak,g.player.position.y)
  if g.player.is_on_floor():break
 check(double_peak>single_peak+.6 and double_peak>before_second+.8,failures,"Double jump did not reach above the single jump")
 check(g.jumps_used==0 and g.can_jump(),failures,"Double jump did not reset on landing")
 # The player retains horizontal control and the camera follows their height.
 space(g)
 var start=g.player.position
 for frame in range(8):await step(g,Vector3.RIGHT)
 check(g.player.position.x>start.x+.3,failures,"Jump blocked horizontal walking")
 check(g.camera.position.is_equal_approx(g.player.position+Vector3(0,1.62,0)),failures,"Camera did not follow the jumping player")
 await land(g,failures)
 # Menus, rest, transitions and camera-only modes must not spend a jump.
 if not is_instance_valid(g.request_popup):
  g.request_popup=PanelContainer.new();g.ui.add_child(g.request_popup);g.request_popup.hide()
 var states=["menu","photo","rest","transition","view","note","text"]
 if DisplayServer.get_name()!="headless":states.append("pointer")
 for state in states:
  var text_field: LineEdit
  match state:
   "menu":g.side_panel.show()
   "photo":g.photo_mode=true
   "rest":g.rest_kind="bench"
   "transition":g.day_transition=true
   "view":g.clear_view=true
   "pointer":Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
   "note":g.request_popup.show()
   "text":
    text_field=LineEdit.new();g.ui.add_child(text_field);text_field.grab_focus()
  space(g)
  check(g.jumps_used==0 and g.player.velocity.y<=0,failures,"Jump escaped the "+state+" input guard")
  g.side_panel.hide();g.photo_mode=false;g.rest_kind="";g.day_transition=false;g.clear_view=false
  g.request_popup.hide()
  if is_instance_valid(text_field):text_field.release_focus();text_field.queue_free()
  Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 # A low ceiling must stop both boosts through the real capsule collision.
 var ceiling=StaticBody3D.new()
 var shape=CollisionShape3D.new()
 var box=BoxShape3D.new()
 box.size=Vector3(4,.2,4)
 shape.shape=box;ceiling.add_child(shape)
 ceiling.position=g.player.position+Vector3(0,2.3,0)
 g.world_root.add_child(ceiling)
 await g.get_tree().physics_frame
 var ceiling_y=ceiling.position.y-.1
 space(g)
 for frame in range(8):await step(g)
 space(g)
 for frame in range(8):
  await step(g)
  check(g.player.position.y+1.665<ceiling_y+.05,failures,"Jump passed through a ceiling")
 ceiling.queue_free()
 await land(g,failures)
 # Jumping is available with a gardening tool selected too.
 g.set_mode("water")
 space(g)
 await step(g)
 check(g.jumps_used==1 and g.player.velocity.y>0 and g.mode=="water",failures,"Jump changed or blocked the selected gardening tool")
 await land(g,failures)
 g.set_mode("walk")
 # Two rapid presses before the next frame still consume at most two jumps.
 space(g);space(g);space(g)
 check(g.jumps_used==2,failures,"Rapid Space presses bypassed the two-jump limit")
 await land(g,failures)
 check(g.jumps_used==0,failures,"Rapid double jump did not reset on landing")
 if DisplayServer.get_name()=="headless":
  # Let looping audio release its playbacks before the fixed-FPS test exits.
  for voice in g.ambient.players.values():
   voice.stop();voice.stream=null
  await g.get_tree().process_frame
  OS.delay_msec(30)
