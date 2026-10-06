extends RefCounted

static func run(g,failures: Array) -> void:
 var walker=preload("res://tests/walking.gd")
 # Traverse the new entrances with the player's real capsule, gravity and
 # step-up movement. Include the long kitchen and glasshouse door approaches.
 for index in range(10):
  var stops=[0.,.16,.32,.48,.64,.80,1.]
  var center=GardenAreaCatalogue.center(index)
  var outer=GardenAreaTransitions.approach(index,0.)
  await walker.cross(g,center+Vector3(12 if index%2==0 else -12,0,outer.y),center+Vector3(outer.x,0,outer.y),failures,"Main trail junction "+GardenAreaCatalogue.entry(index).name)
  for j in range(stops.size()-1):
   var a=GardenAreaTransitions.approach(index,stops[j])
   var b=GardenAreaTransitions.approach(index,stops[j+1])
   await walker.cross(g,center+Vector3(a.x,0,a.y),center+Vector3(b.x,0,b.y),failures,"Entrance "+GardenAreaCatalogue.entry(index).name)
  # Go beyond the arrival ribbon onto the actual destination. Previously an
  # entrance could pass the test while stopping short of a path or doorway.
  var join=GardenAreaTransitions.approach(index,1.)
  var inner=[Vector2(5.8,5.1),Vector2(sin(7.5*.42)+.30*sin(7.5*.83)+1.55,7.5),Vector2(6.5,5.3),Vector2(3*sin(2.),5.),Vector2(6.,5.2),Vector2(0,4.9),Vector2(0,4.4),Vector2(-2.4,3.),Vector2(2.4*sin(2.25),5.),Vector2(-2.5,4.5)][index]
  await walker.cross(g,center+Vector3(join.x,0,join.y),center+Vector3(inner.x,0,inner.y),failures,"Inner join "+GardenAreaCatalogue.entry(index).name)
  for t in [0.,.5,1.]:
   var sample=GardenAreaTransitions.approach(index,t)
   var pos=center+Vector3(sample.x,0,sample.y)
   var ray=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*8,pos+Vector3.DOWN*3)
   ray.exclude=[g.player.get_rid()]
   var hit=g.get_world_3d().direct_space_state.intersect_ray(ray)
   if hit.is_empty() or hit.normal.y<=0:failures.append("Entrance has no upward facing floor: "+GardenAreaCatalogue.entry(index).name+" at "+str(pos))
  var p=GardenAreaTransitions.approach(index,.5)
  if g.plantable_ground(center+Vector3(p.x,0,p.y)):
   failures.append("Planting can block the entrance to "+GardenAreaCatalogue.entry(index).name)
 # Cross shared seams instead of teleporting between atlas entries.
 for row in range(4):
  var z=-12-row*24
  await walker.cross(g,Vector3(68,0,z+2),Vector3(68,0,z-2),failures,"Connected trail seam "+str(row))
 var entry: Array=GardenAreaTransitions.route_data().eastern_link
 for j in range(0,entry.size()-1,30):
  var end=mini(entry.size()-1,j+30)
  await walker.cross(g,Vector3(entry[j][0],0,entry[j][1]),Vector3(entry[end][0],0,entry[end][1]),failures,"Original garden to shared trail")
  var mid=(j+end)/2
  var pos=Vector3(entry[mid][0],0,entry[mid][1])
  var ray=PhysicsRayQueryParameters3D.create(pos+Vector3.UP*8,pos+Vector3.DOWN*3)
  ray.exclude=[g.player.get_rid()]
  var hit=g.get_world_3d().direct_space_state.intersect_ray(ray)
  if hit.is_empty() or hit.normal.y<.85 or absf(hit.position.y-GardenTerrain.point(pos).y-.055)>.02:
   failures.append("Eastern link collision does not match the visible paving at "+str(pos))
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
