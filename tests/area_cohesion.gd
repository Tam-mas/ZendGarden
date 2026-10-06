extends RefCounted

static func run(g,failures: Array) -> void:
 var walker=preload("res://tests/walking.gd")
 # Traverse the new entrances with the player's real capsule, gravity and
 # step-up movement. Include the long kitchen and glasshouse door approaches.
 for index in range(10):
  var stops=[.06,.5,1.] if index not in [5,6] else [.06,.35,.64,.82,1.]
  var center=GardenAreaCatalogue.center(index)
  for j in range(stops.size()-1):
   var a=GardenAreaTransitions.approach(index,stops[j])
   var b=GardenAreaTransitions.approach(index,stops[j+1])
   await walker.cross(g,center+Vector3(a.x,0,a.y),center+Vector3(b.x,0,b.y),failures,"Entrance "+GardenAreaCatalogue.entry(index).name)
  var p=GardenAreaTransitions.approach(index,.5)
  if g.plantable_ground(center+Vector3(p.x,0,p.y)):
   failures.append("Planting can block the entrance to "+GardenAreaCatalogue.entry(index).name)
 # Cross shared seams instead of teleporting between atlas entries.
 for row in range(4):
  var z=-12-row*24
  await walker.cross(g,Vector3(68,0,z+2),Vector3(68,0,z-2),failures,"Connected trail seam "+str(row))
 for row in range(5):
  var pos=Vector3(68,0,6-row*24)
  var ray=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*8,pos+Vector3.DOWN*3)
  ray.exclude=[g.player.get_rid()]
  var hit=g.get_world_3d().direct_space_state.intersect_ray(ray)
  if hit.is_empty() or hit.normal.y<.95 or absf(hit.position.y-GardenTerrain.point(pos).y-.055)>.02:
   print("COHESION_TRAIL_RAY: ",pos," expected ",GardenTerrain.point(pos).y+.055," actual ",hit)
   failures.append("Connected trail has no correctly facing collision at "+str(pos))
 # Existing terrain edits must move the new paving and its collider together.
 var ray=PhysicsRayQueryParameters3D.create(Vector3(68,8,-12),Vector3(68,-3,-12))
 ray.exclude=[g.player.get_rid()]
 var before=g.get_world_3d().direct_space_state.intersect_ray(ray)
 GardenSculpt.restore(g,{"68:-12":.22})
 await g.get_tree().physics_frame
 var after=g.get_world_3d().direct_space_state.intersect_ray(ray)
 if before.is_empty() or after.is_empty() or absf(after.position.y-before.position.y-.22)>.02:
  print("COHESION_SCULPT_RAY: ",before," -> ",after," offsets ",GardenTerrain.offsets)
  failures.append("Sculpting detached the connected trail from its collision")
 GardenSculpt.restore(g,{})
 await g.get_tree().physics_frame
 print("COHESION_ROUTES_RESULT: ",failures)
