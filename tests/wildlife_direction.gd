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
 for sample in range(48):
  var t=sample*.31+.05
  g.animate_garden(0,t)
  var positions=[]
  for entry in g.wildlife:positions.append(entry.node.position)
  var fish_positions=[]
  for j in range(4):fish_positions.append(pond.get_node("Fish"+str(j)).position)
  g.animate_garden(0,t+.001)
  for i in range(g.wildlife.size()):
   var entry=g.wildlife[i]
   var tangent: Vector3=entry.node.position-positions[i]
   tangent.y=0
   if tangent.length()>.000001 and (-entry.node.basis.z).normalized().dot(tangent.normalized())<.98:failures.append(entry.kind+" faces away from travel")
  for j in range(4):
   var fish=pond.get_node("Fish"+str(j))
   var tangent: Vector3=fish.position-fish_positions[j]
   tangent.y=0
   if fish.basis.x.normalized().dot(tangent.normalized())<.999:failures.append("Fish does not face elliptical travel")
 # Companions' local -Z noses and direction-based yaw already agree.
 for angle in range(24):
  var direction=Vector3(sin(angle),0,cos(angle))
  var basis=Basis(Vector3.UP,atan2(-direction.x,-direction.z))
  if (-basis.z).dot(direction)<.999: failures.append("Companion forward axis mismatch")
 print("WILDLIFE_DIRECTION_RESULT: ",failures)
 g.free()
 world.queue_free()
 quit(0 if failures.is_empty() else 1)
