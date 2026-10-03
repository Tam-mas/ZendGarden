extends RefCounted

static func run(g,failures: Array) -> void:
 var old=g.wildlife.duplicate()
 var clock=g.clock_time
 var world=Node3D.new()
 g.add_child(world)
 g.clock_time=.42
 g.wildlife=[]
 for kind in ["native bird","lorikeet"]:
  for slot in range(2):
   var node=GardenArt.visitor(kind)
   world.add_child(node)
   g.wildlife.append({"node":node,"kind":kind,"target":Vector3.ZERO,"phase":(slot+4)*1.73,"bird_slot":slot,"bird_count":2})
 for sample in range(560):
  var time=sample*.1
  for entry in g.wildlife:GardenWildlifeMotion.animate(g,entry,.1,time)
  for pair in [0,2]:
   var a=g.wildlife[pair];var b=g.wildlife[pair+1]
   if a.node.visible and b.node.visible and a.node.position.distance_to(b.node.position)<.45:
    failures.append(a.kind+" pair overlaps in normal visitor animation at "+str(time));break
 # Two lorikeets have separate wingbeat phases while both are airborne.
 for entry in g.wildlife:entry.erase("pose_clip")
 for entry in g.wildlife:GardenWildlifeMotion.animate(g,entry,.016,1.0)
 var left=GardenAnimalMotion.player(g.wildlife[2].node)
 var right=GardenAnimalMotion.player(g.wildlife[3].node)
 if left and right and absf(left.current_animation_position-right.current_animation_position)<.02:failures.append("Paired birds have identical wingbeat phases")
 g.wildlife=old
 g.clock_time=clock
 world.free()
