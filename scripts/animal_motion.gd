class_name GardenAnimalMotion
extends RefCounted

# Imported clips animate local joints. Navigation retains control of the animal's
# world transform, and advances animations only while garden time is running.
static func player(model: Node3D) -> AnimationPlayer:
 if model.has_meta("motion_player"):
  return model.get_meta("motion_player") as AnimationPlayer
 var animation=model.find_child("*",true,false) as AnimationPlayer
 for child in model.get_children():
  if child is AnimationPlayer:
   animation=child
   break
 if animation:
  animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 model.set_meta("motion_player",animation)
 return animation

static func advance(model: Node3D, clip: String, delta: float, speed: float=1.0) -> bool:
 var animation=player(model)
 if not animation or not animation.has_animation(clip):return false
 if animation.current_animation!=clip:
  animation.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
  animation.play(clip,.18,1.0)
 animation.speed_scale=speed
 animation.advance(maxf(0,delta))
 return true
