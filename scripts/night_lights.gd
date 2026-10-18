class_name GardenNightLights
extends Node

# Keep the web renderer's limited local-light budget available near the player.
# Moon Garden fixtures retain their own brightness/activity controls.
const MAX_LOCAL_LIGHTS=8
const SPECS={
 "lantern":{"height":1.0,"range":5.0,"energy":1.5,"color":"ffda9f"},
 "path_lantern":{"height":.66,"range":5.5,"energy":2.0,"color":"ffdbab"},
 "garden_lamppost":{"height":2.4,"range":10.0,"energy":2.8,"color":"ffe3ba"},
 "garden_floodlight":{"height":1.5,"range":17.0,"energy":5.0,"color":"e9f3ed","spot":true}
}
var garden
var torch_on=false
var torch_model: Node3D
var torch_beam: SpotLight3D
var refresh_in=0.0

static func night_amount(clock_time: float) -> float:
 var altitude=sin((clock_time-.25)*TAU)
 return 1.0-smoothstep(-.16,.10,altitude)

static func glow_materials(node: Node, protect: bool=false) -> Array:
 var result: Array=[]
 if node is MeshInstance3D:
  if protect:node.set_meta("night_lighting_surface",true)
  for surface in range(node.mesh.get_surface_count()):
   var original=node.get_active_material(surface)
   if not original is StandardMaterial3D or not original.emission_enabled:continue
   var own=original.duplicate()
   own.set_meta("night_emission",own.emission_energy_multiplier)
   node.set_surface_override_material(surface,own)
   result.append(own)
 for child in node.get_children():result.append_array(glow_materials(child,protect))
 return result

static func set_glow(materials: Array, amount: float) -> void:
 for material in materials:
  material.emission_energy_multiplier=float(material.get_meta("night_emission",1.0))*amount

static func attach(root: Node3D, kind: String) -> void:
 if not SPECS.has(kind) or root.has_node("NightLight"):return
 var spec: Dictionary=SPECS[kind]
 var light: Light3D=SpotLight3D.new() if spec.get("spot",false) else OmniLight3D.new()
 light.name="NightLight"
 light.position=Vector3(0,float(spec.height),-.11 if spec.get("spot",false) else 0.)
 light.light_color=Color(spec.color)
 light.light_energy=0
 light.light_indirect_energy=0
 if light is SpotLight3D:
  light.spot_range=float(spec.range);light.spot_angle=52;light.spot_attenuation=1.25
  light.rotation.x=-.25
 else:
  light.omni_range=float(spec.range);light.omni_attenuation=1.35
 light.visible=false
 root.add_child(light)
 root.set_meta("night_light",light)
 root.set_meta("night_glow",glow_materials(root,kind!="lantern"))
 root.set_meta("night_kind",kind)

func setup(g) -> void:
 garden=g
 torch_model=GardenArt.detailed_model("tools","torch")
 torch_model.name="CarriedTorch"
 torch_model.position=Vector3(-.29,-.29,-.48)
 g.camera.add_child(torch_model)
 torch_model.set_meta("night_glow",glow_materials(torch_model))
 # The beam belongs to the camera rather than the hidden first-person model,
 # so menus and Enjoy the view can hide the prop without extinguishing it.
 torch_beam=SpotLight3D.new();torch_beam.name="TorchBeam"
 torch_beam.position=Vector3(-.25,-.22,-.66)
 torch_beam.rotation.x=-.09
 torch_beam.spot_range=21;torch_beam.spot_angle=36
 torch_beam.spot_attenuation=1.1;torch_beam.spot_angle_attenuation=1.4
 torch_beam.light_color=Color("fff1d3");torch_beam.light_energy=5.0
 torch_beam.light_indirect_energy=0
 torch_beam.shadow_enabled=true
 g.camera.add_child(torch_beam)
 # The carried prop remains visible in the camera but cannot block its beam.
 torch_model.set_meta("camera_prop",true)
 for node in torch_model.find_children("*","MeshInstance3D",true,false):
  node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 update_lights()

func toggle() -> void:
 if garden.photo_mode or garden.day_transition or garden.clear_view or is_instance_valid(garden.welcome):return
 torch_on=not torch_on
 refresh_in=0
 update_lights()
 garden.update_hud()
 garden.toast("Torch on · T to put it away" if torch_on else "Torch put away")

func update_carried() -> void:
 if not is_instance_valid(torch_beam):return
 torch_beam.visible=torch_on and not garden.photo_mode and not garden.day_transition
 torch_model.visible=torch_beam.visible and not garden.clear_view and garden.gameplay_active() and garden.rest_kind.is_empty() and not is_instance_valid(garden.welcome)
 set_glow(torch_model.get_meta("night_glow",[]),1.0 if torch_on else 0.0)

func _process(delta: float) -> void:
 if not is_instance_valid(garden) or not is_instance_valid(garden.camera):return
 update_carried()
 refresh_in-=delta
 if refresh_in<=0:
  refresh_in=.18
  update_lights()

func update_lights() -> void:
 update_carried()
 var amount=night_amount(garden.clock_time)
 var position=garden.camera.global_position
 var nearby: Array=[]
 var reserved=1 if is_instance_valid(torch_beam) and torch_beam.visible else 0
 for obj in garden.objects:
  var root=obj.node
  if not is_instance_valid(root) or root.is_queued_for_deletion():continue
  # The three Moon Garden lamps are controlled by their atlas activity.
  var moon=root.get_node_or_null("MoonLight")
  if moon and moon.light_energy>0.01 and root.global_position.distance_to(position)<35:reserved+=1
  if not root.has_meta("night_light"):continue
  var light: Light3D=root.get_meta("night_light")
  set_glow(root.get_meta("night_glow",[]),amount)
  var distance=light.global_position.distance_squared_to(position)
  var radius=maxf(32,float(SPECS[obj.kind].range)+12)
  if amount<.001 or not root.is_visible_in_tree() or distance>radius*radius:
   light.visible=false;light.light_energy=0;light.shadow_enabled=false
   continue
  nearby.append({"light":light,"kind":obj.kind,"distance":distance})
 nearby.sort_custom(func(a,b):return a.distance<b.distance)
 var count=mini(maxi(0,MAX_LOCAL_LIGHTS-reserved),nearby.size())
 var shadow_budget=1 if torch_beam.visible else 2
 for i in range(nearby.size()):
  var item=nearby[i];var light: Light3D=item.light
  var active=i<count
  light.visible=active;light.light_energy=float(SPECS[item.kind].energy)*amount if active else 0.0
  light.shadow_enabled=active and light is SpotLight3D and shadow_budget>0
  if light.shadow_enabled:shadow_budget-=1
