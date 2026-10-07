extends RefCounted

static func check(value: bool,failures: Array,message: String) -> void:
 if not value:failures.append(message)

static func events(water) -> int:
 var count=0
 for entry in water.surfaces:count+=entry.events.size()
 return count

static func run(g,failures: Array) -> void:
 var water=g.get_node("GardenWater");water.set_process(false)
 var reduced=g.settings.reduced_motion;var weather=g.climate.current
 g.settings.reduced_motion=false;g.climate.current=Vector3.ZERO
 check(water.surfaces.size()==9,failures,"A lake, pool or stream was left on the old water system")
 var point=GardenAreaCatalogue.center(9)+Vector3(-1,1,0)
 var before=events(water)
 GardenWater.disturb(g,point)
 check(events(water)==before+1,failures,"Water disturbance did not reach the Moon pool")
 GardenWater.disturb(g,Vector3(35,1,-40))
 check(events(water)==before+1,failures,"Dry ground sends a ripple into another water body")
 water.splash(GardenAreaCatalogue.center(7)+Vector3(0,1.6,3),.5,true)
 check(events(water)==before+1,failures,"Walking on a bridge splashes the water underneath")
 for i in range(20):GardenWater.disturb(g,point,.5)
 check(water.surfaces.all(func(entry):return entry.events.size()<=6),failures,"Water ripple work grows without a limit")
 var time=water.elapsed
 g.settings.reduced_motion=true;water._process(.5);GardenWater.disturb(g,point)
 check(is_equal_approx(water.elapsed,time),failures,"Reduced motion keeps advancing water waves")
 g.settings.reduced_motion=false;water._process(6.)
 check(events(water)==0,failures,"Old water disturbances are never retired")
 var state=GardenAreas.state(g,7);var gates=state.gates.duplicate()
 state.gates=[false,false];GardenAreas.visual(g,7)
 for j in range(2):
  var channel=g.area_roots[7].get_node("Flow%d/ContinuousWater"%j)
  check(not channel.is_visible_in_tree() and channel.material_override.get_shader_parameter("flow_speed")==0.,failures,"Closed stream gate still sends water along its branch")
 state.gates=[true,true];GardenAreas.visual(g,7)
 for j in range(2):
  var channel=g.area_roots[7].get_node("Flow%d/ContinuousWater"%j)
  check(channel.is_visible_in_tree() and channel.material_override.get_shader_parameter("flow_direction")==1. and channel.material_override.get_shader_parameter("flow_speed")>0.,failures,"Open stream gate has no outward current")
 check(events(water)>=2,failures,"Opening a stream gate has no water response")
 state.gates=gates;GardenAreas.visual(g,7)
 water._process(6.)
 g.climate.current=Vector3(1,0,1);g.camera.global_position=GardenAreaCatalogue.center(9)+Vector3(0,3,0)
 water.rain_timer=0.;water._process(.5)
 check(events(water)==0,failures,"Mist makes rain ripples without rainfall")
 g.climate.current=Vector3(1,1,.35);water.rain_timer=0.
 water._process(.5)
 check(events(water)>0,failures,"Rain does not disturb nearby water")
 g.climate.current=weather;g.settings.reduced_motion=reduced
 water.set_process(true)
 print("WATER_SURFACES_RESULT: ",failures)
