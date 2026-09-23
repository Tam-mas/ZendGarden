class_name GardenCare
extends RefCounted

static func register_wild(g, node: Node3D, key: String) -> void:
 g.wild_plants.append({"node":node,"key":key,"pos":node.position,"scale":node.scale})

static func restore_wild(g) -> void:
 for plant in g.wild_plants:
  var cuts=int(g.wild_pruning.get(plant.key,0))
  plant.node.visible=cuts<3
  plant.node.scale=plant.scale*maxf(.1,1.0-cuts*.3)

static func prune_wild(g, pos: Vector3, radius: float) -> int:
 var count=0
 for plant in g.wild_plants:
  if not plant.node.visible or plant.pos.distance_to(pos)>radius: continue
  g.wild_pruning[plant.key]=mini(3,int(g.wild_pruning.get(plant.key,0))+1)
  count+=1
 restore_wild(g)
 return count

static func rake(g) -> void:
 var center=Vector3(round(g.hover_cell.x),0,round(g.hover_cell.z))
 var width=1.1+int(g.upgrades.rake)*.4
 # Check the whole footprint, not just the centre, before changing the ground.
 for dx in [-.5,0,.5]:
  for dz in [-.5,0,.5]:
   var point=center+Vector3(dx*width,0,dz*width)
   if g.bed_at(point)>=0 or not g.plantable_ground(point):
    g.toast("Choose open lawn or a path, away from beds, bridges and ornaments.")
    return
 for plant in g.planted:
  if absf(plant.pos.x-center.x)<width*.5+.15 and absf(plant.pos.z-center.z)<width*.5+.15:
   g.toast("Move or prune away the plant before raking underneath it.")
   return
 for plant in g.wild_plants:
  if plant.node.visible and absf(plant.pos.x-center.x)<width*.5+.15 and absf(plant.pos.z-center.z)<width*.5+.15:
   g.toast("Prune the border planting away before raking here.")
   return
 var key="%d:%d" % [center.x,center.z]
 var fresh=key not in g.clean_paths
 if not fresh and float(g.path_widths.get(key,.95))>=width:
  g.toast("This path is already raked. Aim beside it to extend it.")
  return
 if fresh: g.clean_paths.append(key)
 g.path_widths[key]=width
 GardenGroundFinish.path(g,center,width)
 var found=mini(1+int(g.upgrades.rake),maxi(0,4-g.rake_petals)) if fresh else 0
 g.coins+=found
 g.rake_petals+=found
 g.action_cooldown=.3
 g.care_effect(GardenTerrain.point(center),Color("bda078"))
 g.toast(("Cleared grass and raked a grooved path." if fresh else "Widened this path with your upgraded rake.")+(" Found %d petals." % found if found>0 else ""))
