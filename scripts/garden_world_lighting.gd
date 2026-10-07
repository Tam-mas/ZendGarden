class_name GardenWorldLighting
extends RefCounted

# One exposure and white balance for the complete world. Habitat atmosphere
# blends spatially at the boundaries rather than changing on atlas indices.
const MIST=[.00030,.00085,.00010,.00020,.00018,.00012,.00010,.00042,.00014,.00034]
const COOL=[.12,.32,.0,.03,.02,.0,.03,.18,.13,.15]

static func configure(g) -> void:
 var env=g.environment.environment
 env.tonemap_mode=Environment.TONE_MAPPER_AGX
 env.tonemap_exposure=1.12
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ssao_enabled=true;env.ssao_radius=.45;env.ssao_intensity=.70
 env.ssao_light_affect=.08
 g.sun.light_angular_distance=1.1
 # Retain the garden's cascade coverage and blend its borders. Stationary
 # camera comparisons favour the higher sample filter over tighter cascades.
 g.sun.directional_shadow_max_distance=90
 g.sun.directional_shadow_split_1=.1;g.sun.directional_shadow_split_2=.2;g.sun.directional_shadow_split_3=.5
 g.sun.directional_shadow_blend_splits=true
 g.sun.shadow_blur=1.;g.sun.shadow_normal_bias=2.
 RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW if OS.has_feature("mobile") else RenderingServer.SHADOW_QUALITY_SOFT_HIGH)

static func atmosphere(position: Vector3) -> Vector2:
 var result=Vector2.ZERO;var total=0.
 for j in range(10):
  var p=position-GardenAreaCatalogue.center(j)
  var weight=(1.-smoothstep(7.0,14.,absf(p.x)))*(1.-smoothstep(7.0,14.,absf(p.z)))
  result+=Vector2(MIST[j],COOL[j])*weight;total+=weight
 return result/maxf(1.,total)

static func update(g) -> void:
 var angle=(g.clock_time-.25)*TAU
 var direction=Vector3(cos(angle)*.45,sin(angle),cos(angle)*.89).normalized()
 var daylight=clampf(smoothstep(-.12,.30,direction.y),.025,1)
 var twilight=exp(-pow(direction.y/.19,2))
 var position=g.camera.global_position if g.photo_mode else g.player.global_position
 var regional=atmosphere(position)
 g.environment.set_meta("habitat_mist",regional.x)
 g.sun.light_energy=.04+daylight*1.10
 g.sun.light_color=Color("f0b88e").lerp(Color("fff1df"),daylight)
 g.sun.quaternion=Quaternion(Vector3.FORWARD,-direction)
 var horizon=Color("202b47").lerp(Color("c3d4dc"),daylight).lerp(Color("dca687"),twilight*.36)
 var env=g.environment.environment
 env.background_color=horizon;env.fog_light_color=horizon.lerp(Color("becbca"),regional.y*daylight*.24)
 env.ambient_light_color=Color("98acd0").lerp(Color("e1e9f0"),daylight).lerp(Color("ccdfdd"),regional.y*.16)
 env.ambient_light_energy=.22+daylight*.41
 env.fog_sky_affect=.06
 var sky=env.sky.sky_material
 sky.set_shader_parameter("daylight",daylight);sky.set_shader_parameter("sun_direction",direction)
 sky.set_shader_parameter("day_phase",g.clock_time);sky.set_shader_parameter("sky_motion",float(g.day)+g.clock_time)
 sky.set_shader_parameter("twilight",twilight)
 if is_instance_valid(g.ambient):
  g.ambient.daylight=daylight;g.ambient.update_location(g.player.position,g.plots)

static func weather(g) -> void:
 var cloud=clampf(g.climate.current.x,0,1)
 g.sun.light_energy*=1.-cloud*.48
 var env=g.environment.environment
 env.fog_density=.00010+float(g.environment.get_meta("habitat_mist",0.))+g.climate.current.z*.0019
 env.ambient_light_color=env.ambient_light_color.lerp(Color("c7d1da"),cloud*.30)
 env.sky.sky_material.set_shader_parameter("overcast",cloud)
