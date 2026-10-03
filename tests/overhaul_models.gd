extends SceneTree

class VisitorGarden extends Node3D:
 var player=Node3D.new()
 var welcome: Node
 var settings={"pause_menus":false}
 var smoke=true
 var clock_time=.72
 var unlocked_plots=4
 func gameplay_active() -> bool:return true
 func plantable_ground(_p: Vector3) -> bool:return true
 func bed_at(_p: Vector3) -> int:return -1
 func nearest_plot(_p: Vector3) -> int:return 0

func _initialize() -> void:call_deferred("run")

func run() -> void:
 var failures=[]
 var kinds=["cat","dog","rabbit","kangaroo","kangaroo_joey","echidna","wombat","fox","songbird","native_bird","fairy_wren","kookaburra","lorikeet","magpie","frog","fish","bee","butterfly","dragonfly","firefly","lady_beetle","blue_banded_bee","hoverfly","mantis","leaf_insect","emperor_gum_moth"]
 for kind in kinds:
  var model=GardenArt.detailed_model("companions" if kind in ["cat","dog"] else "wildlife",kind)
  root.add_child(model)
  model.position=Vector3(13,2,-7)
  var player=GardenAnimalMotion.player(model)
  if not player:
   failures.append(kind+" has no imported animations")
   model.free()
   continue
  for clip in player.get_animation_list():
   var animation=player.get_animation(clip)
   for track in range(animation.get_track_count()):
    var path=animation.track_get_path(track)
    if not model.get_node_or_null(NodePath(path.get_concatenated_names())):failures.append(kind+" unresolved animation target: "+str(path))
   for frame in range(12):GardenAnimalMotion.advance(model,clip,.1)
   if not model.position.is_equal_approx(Vector3(13,2,-7)):failures.append(kind+" animation changed navigation position")
  if kind in ["cat","dog","wombat","fox","echidna"]:
   var knee=model.find_child("LowerFrontL*",true,false) as Node3D
   player.stop()
   GardenAnimalMotion.advance(model,"walk",0)
   player.seek(.15,true)
   var first=knee.rotation
   player.seek(.40,true)
   if knee.rotation.distance_to(first)<.01:failures.append(kind+" has no knee articulation")
   var paw=model.find_child("PawFrontL*",true,false) as Node3D
   if not paw:failures.append(kind+" has no ankle articulation")
   else:
    var duration=player.get_animation("walk").length
    for sample in [0.0,.125,.25,.375]:
     player.seek(duration*sample,true)
     var low=INF
     for mesh in paw.get_children():
      if mesh is MeshInstance3D:
       var box=mesh.get_aabb()
       for x in [0,1]:
        for y in [0,1]:
         for z in [0,1]:low=minf(low,(mesh.global_transform*(box.position+box.size*Vector3(x,y,z))).y-model.global_position.y)
     if low<-.025 or low>.035:failures.append(kind+" planted paw misses ground: "+str(low))
  model.free()
 var g=VisitorGarden.new()
 root.add_child(g)
 g.add_child(g.player)
 var visitors=GardenVisitors.new()
 g.add_child(visitors)
 visitors.setup(g)
 visitors.random.seed=41
 for kind in ["wombat","echidna","fox"]:
  visitors.spawn_kind(kind)
  if visitors.guests.size()!=1:failures.append(kind+" single visit missing")
  else:
   var guest=visitors.guests[0]
   if kind=="wombat" and guest.speed>.3:failures.append("Wombat pace too fast")
   if kind=="fox" and guest.pos.distance_to(g.player.position)<14:failures.append("Fox spawned close to player")
   guest.wait=0
   guest.target=guest.pos+Vector3(1,0,0)
   visitors._process(.25)
   if guest.node.position.distance_to(guest.pos)>.001:failures.append(kind+" root floats above terrain")
   if kind=="echidna":
    g.player.position=guest.pos+Vector3(1,0,0)
    var previous=guest.pos
    visitors._process(.25)
    if guest.pos.distance_to(previous)>.001:failures.append("Echidna did not stop for approaching player")
    g.player.position=Vector3.ZERO
  for guest in visitors.guests:guest.node.free()
  visitors.guests.clear()
 g.free()
 print("OVERHAUL_MODELS_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)
