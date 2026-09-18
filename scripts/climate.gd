class_name GardenClimate
extends Node3D
const SEASONS=["Spring","Summer","Autumn","Winter"]
const SEASON_DAYS=12
const TYPES={"Clear":Vector3(.0,.0,.0),"Cloudy":Vector3(.8,.0,.15),"Rain":Vector3(1,1,.35),"Mist":Vector3(.6,0,1),"Snow":Vector3(.85,.0,.55)}
var current=Vector3.ZERO
var target="Clear"
var snow=0.0
var slot=-1
var rain_particles: CPUParticles3D
var snow_particles: CPUParticles3D

static func season(day: int) -> String:
 return SEASONS[posmod(int((day-1)/SEASON_DAYS),4)]

func _ready() -> void:
 rain_particles=precipitation(false)
 snow_particles=precipitation(true)

func precipitation(flakes: bool) -> CPUParticles3D:
 var p=CPUParticles3D.new()
 p.amount=420 if flakes else 700
 p.lifetime=5 if flakes else 1.4
 p.local_coords=false
 p.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX
 p.emission_box_extents=Vector3(9,.1,9)
 p.direction=Vector3(.15,-1,0)
 p.spread=8 if flakes else 2
 p.gravity=Vector3(.1,-.12,0) if flakes else Vector3(0,-4,0)
 p.initial_velocity_min=.65 if flakes else 9
 p.initial_velocity_max=1.3 if flakes else 12
 var mesh=SphereMesh.new() if flakes else BoxMesh.new()
 if flakes: mesh.radius=.022; mesh.height=.044; mesh.radial_segments=4; mesh.rings=2
 else: mesh.size=Vector3(.008,.19,.008)
 p.mesh=mesh
 var material=StandardMaterial3D.new()
 material.albedo_color=Color(.92,.96,1,.8) if flakes else Color(.65,.79,.85,.45)
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 p.material_override=material
 p.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 p.emitting=false
 add_child(p)
 return p

func update(g, delta: float) -> void:
 var next_slot=(g.day-1)*3+int(g.clock_time*3)
 if slot!=next_slot:
  slot=next_slot
  var sequence=["Clear","Cloudy","Rain","Cloudy","Clear","Mist","Clear","Rain","Cloudy"]
  target=sequence[posmod(slot,sequence.size())]
  if season(g.day)=="Winter" and target=="Rain": target="Snow"
 current=current.move_toward(TYPES[target],delta/18.0)
 snow=move_toward(snow,1.0 if target=="Snow" else 0.0,delta/18.0)
 position=g.camera.position+Vector3(0,6,0)
 rain_particles.emitting=current.y>.03
 rain_particles.material_override.albedo_color.a=.45*current.y
 snow_particles.emitting=snow>.03
 snow_particles.material_override.albedo_color.a=.8*snow
 if not g.photo_mode:
  for plant in g.planted:
   plant.water=minf(4.0,plant.water+current.y*delta/24.0)

func apply(g) -> void:
 if is_instance_valid(g.ambient): g.ambient.rainfall=current.y
 g.sun.light_energy*=1.0-current.x*.55
 g.environment.environment.fog_density=.00012+current.z*.007
 g.environment.environment.sky.sky_material.set_shader_parameter("overcast",current.x)

func description() -> String:
 var settling=current.distance_to(TYPES[target])>.05 or absf(snow-(1.0 if target=="Snow" else 0.0))>.05
 return ("Turning "+target.to_lower()) if settling else target

func save_state() -> Dictionary:
 return {"values":[current.x,current.y,current.z],"target":target,"snow":snow,"slot":slot}

func restore(data: Dictionary) -> void:
 var values=data.get("values",[0,0,0])
 current=Vector3(values[0],values[1],values[2])
 target=data.get("target","Clear")
 if not TYPES.has(target): target="Clear"
 snow=float(data.get("snow",0))
 slot=int(data.get("slot",-1))
