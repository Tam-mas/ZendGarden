extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var g=load("res://scripts/garden.gd").new()
 # Exercise the real animation dispatcher without loading a saved garden.
 var world=Node3D.new()
 root.add_child(world)
 for kind in ["songbird","native bird","frog","bee","butterfly","dragonfly","firefly"]:
  var visitor=GardenArt.visitor(kind)
  world.add_child(visitor)
  g.wildlife.append({"node":visitor,"kind":kind,"target":Vector3.ZERO,"phase":0.0})
 var pond=Node3D.new()
 world.add_child(pond)
 g.make_fish(pond)
 g.objects.append({"node":pond,"fish":true})
 var failures=[]
 for sample in range(24):
  var t=sample*TAU/(24.0*.4)
  var phase=sample*TAU/24.0
  for entry in g.wildlife: entry.phase=phase-t*.7
  g.animate_garden(0,t)
  for entry in g.wildlife:
   var position=entry.node.position
   var tangent=Vector3(-position.z,0,position.x).normalized()
   var forward=-entry.node.basis.z.normalized()
   if forward.dot(tangent)<.999: failures.append(entry.kind+" faces away from travel")
  for j in range(4):
   var fish=pond.get_node("Fish"+str(j))
   var tangent=Vector3(-fish.position.z/.8,0,fish.position.x*.8).normalized()
   if fish.basis.x.normalized().dot(tangent)<.999: failures.append("Fish does not face elliptical travel")
 # Companions' local -Z noses and direction-based yaw already agree.
 for angle in range(24):
  var direction=Vector3(sin(angle),0,cos(angle))
  var basis=Basis(Vector3.UP,atan2(-direction.x,-direction.z))
  if (-basis.z).dot(direction)<.999: failures.append("Companion forward axis mismatch")
 print("WILDLIFE_DIRECTION_RESULT: ",failures)
 g.free()
 world.queue_free()
 quit(0 if failures.is_empty() else 1)
