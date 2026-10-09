extends SceneTree

class TestGarden extends "res://scripts/garden.gd":
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass

var failures=[]
func check(ok: bool,note: String) -> void:
 if not ok:failures.append(note)

func _initialize() -> void:
 call_deferred("run")

# Original targeting rules are the oracle for the new broad phase and lookup.
func reference_ray(g,origin: Vector3,direction: Vector3,ground: Vector3) -> Dictionary:
 var best={};var closest=8.0
 for obj in g.objects:
  for slot in range(GardenContainers.SPECS[obj.kind].slots.size()):
   var index=-1
   for i in range(g.planted.size()):
    if g.planted[i].get("container_uid","")==obj.uid and int(g.planted[i].get("container_slot",-1))==slot:index=i;break
   var center=GardenContainers.position(obj,slot)+Vector3(0,.12,0)
   if index>=0:center.y+=minf(.32,float(g.catalogue[g.planted[index].id].height)*.35)
   var along=(center-origin).dot(direction)
   if along<0 or along>closest:continue
   if (origin+direction*along).distance_to(center)>.23:continue
   if ground.is_finite() and along>origin.distance_to(ground)+.15:continue
   if g.player.position.distance_to(center)>7:continue
   closest=along;best={"object":obj,"slot":slot,"plant":index,"position":GardenContainers.position(obj,slot)}
 return best

func run() -> void:
 var g=TestGarden.new();root.add_child(g)
 g.player=CharacterBody3D.new();g.add_child(g.player)
 g.camera=Camera3D.new();g.add_child(g.camera)
 for kind in GardenContainers.SPECS:
  var node=Node3D.new();g.add_child(node)
  node.position=Vector3(g.objects.size()*2.,1.4,-2)
  node.rotation.y=.73
  var obj={"uid":kind,"kind":kind,"node":node,"pos":node.position}
  g.objects.append(obj)
  for slot in range(GardenContainers.SPECS[kind].slots.size()):
   if slot%2==0:g.planted.append({"id":28,"container_uid":kind,"container_slot":slot})
 var rays=0
 for obj in g.objects:
  for slot in range(GardenContainers.SPECS[obj.kind].slots.size()):
   var center=GardenContainers.position(obj,slot)+Vector3(0,.12,0)
   for lift in [0.,.32]:
    for gap in [2.,6.8,7.05,8.1]:
     for edge in [-.24,0.,.22]:
      var origin=center+Vector3(edge,.2,gap)
      g.player.position=center+Vector3(0,0,gap)
      var direction=(center+Vector3(0,lift,0)-origin).normalized()
      for ground in [Vector3.INF,origin+direction*1.0]:
       var expected=reference_ray(g,origin,direction,ground)
       var actual=GardenContainers.ray(g,origin,direction,ground)
       check(actual==expected,"Target changed: %s/%d lift %.2f gap %.2f edge %.2f"%[obj.kind,slot,lift,gap,edge])
       rays+=1
 var first=g.objects[0]
 var original=GardenContainers.occupant(g,first,0)
 check(original>=0 and GardenContainers.occupant(g,first,0,original)==-1,"Moving within the same pocket is blocked")
 g.planted.remove_at(original)
 check(GardenContainers.occupant(g,first,0)==-1,"Removed occupant remains indexed")
 # Same-sized restored arrays must not reuse indices from the previous garden.
 g.planted=[{"container_uid":first.uid,"container_slot":0}]
 check(GardenContainers.occupant(g,first,0)==0,"Reload did not rebuild pocket index")
 g.planted[0].container_slot=1;g.plant_index.invalidate()
 check(GardenContainers.occupant(g,first,0)==-1 and GardenContainers.occupant(g,first,1)==0,"Moving pockets left stale occupancy")
 g.planted[0].erase("container_uid");g.plant_index.invalidate()
 check(GardenContainers.occupant(g,first,1)==-1,"Detached plant left stale occupancy")
 # Isolate targeting cost with the same 1,739 plants / 120 distant pockets
 # used during review. Print timings without hardware-dependent pass limits.
 for obj in g.objects:obj.node.free()
 g.objects.clear();g.planted.clear();g.plant_index.invalidate()
 for j in range(20):
  var node=Node3D.new();g.add_child(node);node.position=Vector3(100+j,0,100)
  g.objects.append({"kind":"raised_bed","uid":str(j),"node":node})
 for i in range(1739):g.planted.append({"container_uid":""})
 g.player.position=Vector3.ZERO
 var timings=[]
 for sample in range(15):
  var start=Time.get_ticks_usec()
  GardenContainers.ray(g,Vector3(0,1,0),Vector3.FORWARD,Vector3.INF)
  timings.append((Time.get_ticks_usec()-start)/1000.)
 timings.sort()
 print("PLANTER_TARGET_MEDIAN_MS: ",timings[7])
 for id in [20,66,207,210]:
  var model=g.Art.plant(g.catalogue[id],true)
  inspect_meshes(model)
  model.free()
 # Exercise the actual batch builder, transformed anchors and graphics changes.
 var habitat=Node3D.new();g.add_child(habitat)
 habitat.position=Vector3(3,2,-8);habitat.rotation.y=.4
 for x in [0.,2.]:
  var anchor=Node3D.new();habitat.add_child(anchor);anchor.position.x=x
  anchor.set_meta("extras",{"area_species":"test","area_plant_id":0})
 GardenAreaFlora.build(g,habitat)
 var batch=habitat.get_meta("flora_batches")[0].node
 var bounds: AABB=batch.get_meta("world_bounds")
 g.settings.graphics="auto";g.camera.position=bounds.get_center()
 GardenAreaFlora.update_detail(g)
 check(batch.cast_shadow==batch.get_meta("full_shadow"),"Nearby habitat shadows lost")
 g.camera.position=bounds.end+Vector3(20,0,0);GardenAreaFlora.update_detail(g)
 check(batch.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"Distant small-plant shadows remain in Auto")
 g.settings.graphics="standard";GardenAreaFlora.update_detail(g)
 check(batch.cast_shadow==batch.get_meta("full_shadow") and is_equal_approx(batch.lod_bias,1.),"Standard did not restore habitat shadows/detail")
 habitat.position.x+=40;GardenAreaFlora.refresh(habitat)
 check(is_equal_approx(batch.get_meta("world_bounds").position.x,bounds.position.x+40),"Terrain refresh left stale shadow bounds")
 g.queue_free();await process_frame
 print("GARDEN_PERFORMANCE_RESULT: ",JSON.stringify({"rays":rays,"failures":failures}))
 quit(0 if failures.is_empty() else 1)

func inspect_meshes(node: Node) -> void:
 if node is MeshInstance3D:
  var parts=[];GardenAreaFlora.collect(node,Transform3D.IDENTITY,parts)
  check(parts.size()==1,"Organ split into redundant render nodes")
  var original=node.mesh.get("_surfaces");var copied=parts[0].mesh.get("_surfaces")
  check(original.size()==copied.size(),"Surface count changed")
  for i in range(original.size()):
   for key in original[i]:
    if key=="material":continue
    check(original[i][key]==copied[i].get(key),"Imported geometry or LOD changed: "+str(key))
   check(parts[0].mesh.surface_get_material(i)==node.get_active_material(i),"Plant shader or tissue material lost")
  check(parts[0].mesh.shadow_mesh==node.mesh.shadow_mesh,"Imported shadow geometry lost")
 for child in node.get_children():inspect_meshes(child)
