extends RefCounted

static func run(g, failures: Array) -> void:
 var specimens=[]
 for id in [12,1,20,45]:
  for factor in [.8,1.2]:
   var p=g.add_plant(id,Vector3(-4,0,-4),0,g.catalogue[id].days,factor)
   specimens.append(p)
   if not p.node.scale.is_equal_approx(Vector3(1,factor,1)): failures.append("Mature height or width incorrect")
   p.age=0
   if not g.plant_scale(p).is_equal_approx(Vector3.ONE*.12): failures.append("Height variation changed seed size")
   p.age=g.catalogue[id].days*.5
   if not is_equal_approx(g.plant_scale(p).y,.56*lerpf(1.0,factor,.5)): failures.append("Height growth discontinuity")
   p.age=g.catalogue[id].days
   p.pruned=1.0
   if not is_equal_approx(g.plant_scale(p).y,factor*.7): failures.append("Pruning ignored individual height")
   p.pruned=0.0
   p.pos+=Vector3(.4,0,0)
   g.refresh_plant(p)
   if not is_equal_approx(p.height_factor,factor): failures.append("Moving or refreshing rerolled height")
 var values={}
 for i in range(16):
  var p=g.add_plant(1,Vector3(-4+i*.4,0,-3),0,g.catalogue[1].days)
  specimens.append(p)
  values[p.height_factor]=true
  if p.height_factor<.8 or p.height_factor>1.2: failures.append("Random height out of range")
 if values.size()<12: failures.append("Neighbouring plants lack height variation")
 var legacy={"id":1,"pos":[1.15,-2.3]}
 var factor=g.legacy_height_factor(legacy)
 if factor<.8 or factor>1.2 or factor!=g.legacy_height_factor(legacy): failures.append("Legacy height migration unstable")
 var data={"id":1,"pos":[1.15,-2.3],"plot":0,"age":g.catalogue[1].days,"water":2.0,"stress":0.0}
 var old_data=g.loaded_data
 var before=g.planted.size()
 g.loaded_data={"version":2,"plants":[data]}
 g.restore_garden()
 var migrated=g.planted.back()
 specimens.append(migrated)
 if g.planted.size()!=before+1 or not is_equal_approx(migrated.height_factor,factor): failures.append("Legacy plant did not acquire stable height")
 g.loaded_data=old_data
 await g.get_tree().create_timer(1).timeout
 for p in specimens:
  if not p.node.scale.is_equal_approx(g.plant_scale(p)): failures.append("Rendered height differs from target")
  g.planted.erase(p)
  p.node.queue_free()
  p.marker.queue_free()
