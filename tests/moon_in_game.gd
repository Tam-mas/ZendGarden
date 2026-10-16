extends RefCounted

static func check(value: bool, failures: Array, message: String) -> void:
 if not value:failures.append(message)

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.settings.request_notifications=false
 g.dismiss_request()
 g.side_panel.hide()
 g.climate.current=Vector3.ZERO
 g.climate.snow=0.
 g.day=8;g.clock_time=.85
 g.update_lighting();g.climate.apply(g)
 var sky=g.environment.environment.sky.sky_material
 check(sky.get_shader_parameter("moon_direction").distance_to(GardenMoon.at(g.day,g.clock_time).direction)<.0001,failures,"Sky does not use the saved lunar position")
 check(g.moon_light.light_energy>.08,failures,"Full moon does not light the garden")
 var clear_energy=g.moon_light.light_energy
 g.climate.current.x=1.;g.update_lighting();g.climate.apply(g)
 check(g.moon_light.light_energy<clear_energy*.3,failures,"Overcast does not soften moonlight")
 g.climate.current=Vector3.ZERO
 g.day=1;g.clock_time=.65;g.update_lighting();g.update_hud()
 check(g.compact_hud.text.contains("First quarter"),failures,"HUD has no moon phase")
 g.menu_sections.guide="Moon & night sky";g.active_tab="Guide";g.refresh_sidebar()
 check(g.list_box.get_children().any(func(c):return c is Label and c.text.contains("lit")),failures,"Moon guide has no current phase/visibility")
 var look=g.list_box.get_children().filter(func(c):return c is Button and c.text=="Look toward the moon")
 check(look.size()==1,failures,"No way to find the moon from its guide")
 if not look.is_empty():
  look[0].pressed.emit()
  check((-g.camera.global_basis.z).dot(GardenMoon.at(g.day,g.clock_time).direction)>.99,failures,"Moon guide did not frame its position")
 # Existing format-3 and Challenge format-4 clocks reconstruct the same sky.
 for mode in ["free","challenge"]:
  g.garden_mode=mode;g.day=17;g.clock_time=.281
  var before=GardenMoon.at(g.day,g.clock_time)
  check(g.save_game(),failures,"Moon fixture could not save")
  g.day=1;g.clock_time=.8;g.smoke=false;g.load_game();g.smoke=true
  check(GardenMoon.at(g.day,g.clock_time).direction.distance_to(before.direction)<.00001,failures,"Lunar position changed after "+mode+" reload")
 g.garden_mode="free"
 # Drive the real twelve-second skip, including its midnight growth boundary.
 g.day=8;g.clock_time=.45;g.settings.reduced_motion=false
 g.yaw=1.2;g.pitch=.12;g.side_panel.hide();g.next_day()
 var followed=false
 var previous=GardenMoon.at(g.day,g.clock_time)
 for frame in range(722):
  g.update_day_transition(1./60.)
  g.update_camera(1./60.);g.update_lighting()
  var state=GardenMoon.at(g.day,g.clock_time)
  check(previous.direction.distance_to(state.direction)<.02,failures,"Discontinuous moon during day skip")
  previous=state
  if g.clock_time>.88 and g.clock_time<.96:
   followed=followed or (-g.camera.global_basis.z).dot(state.direction)>.85
  if not g.day_transition:break
 check(followed,failures,"Night transition never frames the moon")
 check(g.day==9 and absf(g.clock_time-.30)<.0001,failures,"Moon transition changed dawn progression")
 check(absf(g.yaw-1.2)<.0001 and absf(g.pitch-.12)<.0001,failures,"Transition changed the player's saved view")
 g.update_camera(0.)
 check(absf(g.camera.rotation.x+g.pitch)<.0001,failures,"Transition did not restore the player's view")
 g.settings.reduced_motion=true;g.next_day()
 check(not g.day_transition and g.day==10 and absf(g.clock_time-.30)<.0001,failures,"Reduced motion no longer skips instantly")
 g.settings.reduced_motion=false
 # Menu/photo pauses do not move the celestial clock, including in normal play.
 g.smoke=false;g.settings.controls="keyboard";g.touch.configure()
 g.settings.pause_menus=true;g.side_panel.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var saved_clock=g.clock_time
 g._process(.25)
 check(is_equal_approx(g.clock_time,saved_clock),failures,"Moon advances while menus pause time")
 g.photo_mode=true;g._process(.25)
 check(is_equal_approx(g.clock_time,saved_clock),failures,"Moon moves during a paused photograph")
 g.photo_mode=false;g.smoke=true;g.side_panel.hide()
 if DisplayServer.get_name()!="headless":await render_review(g,failures)

static func render_review(g, failures: Array) -> void:
 # Exercise the real sky shader in a small isolated world for every phase.
 var viewport=SubViewport.new()
 viewport.size=Vector2i(256,256)
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 g.add_child(viewport)
 var environment=WorldEnvironment.new()
 environment.environment=g.environment.environment.duplicate(true)
 environment.environment.fog_enabled=false
 viewport.add_child(environment)
 var camera=Camera3D.new();camera.fov=9.;viewport.add_child(camera)
 var direction=Vector3(0,.6,-.8)
 var right=direction.cross(Vector3.UP).normalized()
 var up=right.cross(direction)
 camera.look_at(direction)
 var material=environment.environment.sky.sky_material
 material.set_shader_parameter("moon_direction",direction)
 material.set_shader_parameter("moon_right",right)
 material.set_shader_parameter("moon_radius",GardenMoon.ANGULAR_RADIUS)
 material.set_shader_parameter("daylight",0.)
 material.set_shader_parameter("twilight",0.)
 material.set_shader_parameter("overcast",0.)
 material.set_shader_parameter("cloud_opacity",0.)
 material.set_shader_parameter("moonlight",0.)
 var sheet=Image.create(1024,512,false,Image.FORMAT_RGB8)
 var coverage=[]
 for phase in range(8):
  var angle=float(phase)*TAU/8.
  material.set_shader_parameter("sun_direction",direction*cos(angle)+right*sin(angle))
  material.set_shader_parameter("moon_illumination",(1.-cos(angle))*.5)
  for frame in range(3):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  var image=viewport.get_texture().get_image()
  image.convert(Image.FORMAT_RGB8)
  sheet.blit_rect(image,Rect2i(0,0,256,256),Vector2i((phase%4)*256,int(phase/4)*256))
  var lit=0;var pixels=0;var left=0;var right_lit=0
  for y in range(86,170):
   for x in range(86,170):
    if Vector2(x-128,y-128).length()>39:continue
    pixels+=1
    if image.get_pixel(x,y).get_luminance()>.22:
     lit+=1
     if x<128:left+=1
     else:right_lit+=1
  coverage.append(float(lit)/pixels)
  if phase==2:check(right_lit>left*2,failures,"Waxing limb does not face the sun")
  if phase==6:check(left>right_lit*2,failures,"Waning limb did not reverse")
 sheet.save_png("/tmp/zend-moon-phases.png")
 check(coverage[0]<.03 and coverage[4]>.90,failures,"New/full moon disc coverage is wrong: "+str(coverage))
 check(coverage[1]>.04 and coverage[1]<.30 and coverage[3]>.65,failures,"Crescent/gibbous phases rendered incorrectly: "+str(coverage))
 print("MOON_RENDER_COVERAGE: ",coverage)
 viewport.queue_free()
 # Render real garden skies as well as the close phase inspection.
 g.ui.hide();g.settings.controls="keyboard";g.touch.configure()
 for view in [[8,.85,"night"],[1,.65,"day"],[26,.79,"crescent"]]:
  g.day=view[0];g.clock_time=view[1];g.climate.current=Vector3.ZERO
  g.update_lighting();g.climate.apply(g)
  var state=GardenMoon.at(g.day,g.clock_time)
  g.camera.position=g.player.position+Vector3(0,1.62,0)
  g.camera.fov=74.
  g.camera.look_at(g.camera.position+state.direction)
  for frame in range(3):await g.get_tree().process_frame
  await RenderingServer.frame_post_draw
  g.get_viewport().get_texture().get_image().save_png("/tmp/zend-moon-"+view[2]+".png")
 # Inspect the phone's normal HUD with the extra phase line.
 g.ui.show();g.get_window().size=Vector2i(390,844)
 g.settings.controls="touch";g.touch.configure();g.touch._process(.1)
 g.update_hud();g.touch._process(.1)
 await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 check(g.touch.status_text.text.contains(GardenMoon.phase_name(g.day,g.clock_time)),failures,"Touch HUD has no moon phase")
 g.get_viewport().get_texture().get_image().save_png("/tmp/zend-moon-phone.png")
 g.get_window().size=Vector2i(820,1180);g.touch.configure();g.touch._process(.1)
 for frame in range(3):await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 check(g.touch.status_text.get_line_count()<=g.touch.status_text.max_lines_visible,failures,"Tablet moon readout wraps outside its panel")
 g.get_viewport().get_texture().get_image().save_png("/tmp/zend-moon-tablet.png")
