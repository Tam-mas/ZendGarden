class_name GardenAnimalMotion
extends RefCounted

const SUPPLIED={
 "cat":{"speed":.30,"contact_speed":.13/(.65*1.2)},
 "dog":{"speed":.34,"contact_speed":.15/(.65*1.2)},
 "fox":{"speed":.24,"contact_speed":.15/(.72*1.5)},
 "echidna":{"speed":.042,"contact_speed":.035/(.78*2.4)},
 "rabbit":{"speed":.4/1.2,"contact_speed":.4/1.2}
}

static func travel_speed(model: Node3D, fallback: float) -> float:
 return float(SUPPLIED.get(str(model.get_meta("supplied_animal","")),{}).get("speed",fallback))

static func gait_rate(model: Node3D, speed: float, fallback: float) -> float:
 var profile: Dictionary=SUPPLIED.get(str(model.get_meta("supplied_animal","")),{})
 return speed/float(profile.contact_speed) if not profile.is_empty() else fallback

# A rabbit advances during its airborne phase, with pauses for crouch/landing.
# Integrating over the cycle keeps travel stable across frame rates and wrap.
static func hop_progress(cycles: float) -> float:
 var whole=floorf(cycles)
 var phase=cycles-whole
 var flight=clampf((phase-.18)/.46,0,1)
 return whole+(1-cos(PI*flight))*.5

static func travel_distance(model: Node3D, clip: String, delta: float, speed: float) -> float:
 if str(model.get_meta("supplied_animal",""))!="rabbit" or clip!="hop":return delta*speed
 var animation=player(model)
 var time=animation.current_animation_position if animation and animation.current_animation==clip else 0.0
 var rate=gait_rate(model,speed,1.0)
 return .4*(hop_progress((time+delta*rate)/1.2)-hop_progress(time/1.2))

# Imported clips animate local joints. Navigation retains control of the animal's
# world transform, and advances animations only while garden time is running.
static func player(model: Node3D) -> AnimationPlayer:
 if model.has_meta("motion_player"):
  return model.get_meta("motion_player") as AnimationPlayer
 var players=model.find_children("*","AnimationPlayer",true,false)
 var animation=players[0] as AnimationPlayer if not players.is_empty() else null
 if animation:
  animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 model.set_meta("motion_player",animation)
 return animation

static func advance(model: Node3D, clip: String, delta: float, speed: float=1.0) -> bool:
 var animation=player(model)
 if model.has_meta("supplied_animal"):
  if clip=="alert":clip="look"
  elif clip=="graze":clip="forage" if animation and animation.has_animation("forage") else "look"
 if not animation or not animation.has_animation(clip):return false
 if animation.current_animation!=clip:
  animation.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
  animation.play(clip,.18,1.0)
 animation.speed_scale=speed
 animation.advance(maxf(0,delta))
 return true
