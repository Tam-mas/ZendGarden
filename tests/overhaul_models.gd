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
 var preferences=JSON.parse_string(FileAccess.get_file_as_string("res://art_source/overhaul/model_choices.json"))
 var kinds=["cat","dog","rabbit","kangaroo","kangaroo_joey","echidna","wombat","fox","songbird","native_bird","fairy_wren","kookaburra","lorikeet","magpie","frog","fish","bee","butterfly","dragonfly","firefly","lady_beetle","blue_banded_bee","hoverfly","mantis","leaf_insect","emperor_gum_moth"]
 for kind in kinds:
  var model=GardenArt.detailed_model("companions" if kind in ["cat","dog"] else "wildlife",kind)
  root.add_child(model)
  model.position=Vector3(13,2,-7)
  var folder="companions" if kind in ["cat","dog"] else "wildlife"
  var retained=preferences is Dictionary and preferences.get("choices",{}).get(folder+"/"+kind,"new")=="old"
  var supplied=model.has_meta("supplied_animal")
  if not retained and not supplied and kind in ["cat","dog","rabbit","kangaroo","kangaroo_joey","echidna","wombat","fox","songbird","native_bird","fairy_wren","kookaburra","lorikeet","magpie"]:
   var skin=model.find_child("Skeleton3D*",true,false) as Skeleton3D
   if not skin or skin.find_bone("Skin_Head")<0 or skin.find_bone("Skin_Body")<0:failures.append(kind+" continuous skin skeleton missing")
   elif model.find_child("Head",true,false):
    var head=model.find_child("Head",true,false) as Node3D
    var origin=skin.global_transform*skin.get_bone_global_pose(skin.find_bone("Skin_Head")).origin
    if origin.distance_to(head.global_position)>.015:failures.append(kind+" neutral skin and head control disagree")
   if skin:
    for mesh in model.find_children("*","MeshInstance3D",true,false):
     if not mesh.skin:continue
     for index in range(mesh.skin.get_bind_count()):
      var bone=mesh.skin.get_bind_bone(index)
      if bone<0:bone=skin.find_bone(mesh.skin.get_bind_name(index))
      if bone<0:failures.append(kind+" unresolved neutral skin bind");break
      var deformation=skin.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(index)
      if deformation.origin.length()>.015 or (deformation.basis.x-Vector3.RIGHT).length()>.015 or (deformation.basis.y-Vector3.UP).length()>.015 or (deformation.basis.z-Vector3.BACK).length()>.015:
       failures.append(kind+" neutral skin bind disagrees with "+str(skin.get_bone_name(bone)));break
  if kind in ["cat","fox"] and not retained:
   var hair_count=0
   for instance in model.find_children("*","MeshInstance3D",true,false):
    for surface in range(instance.mesh.get_surface_count()):
     var material=instance.mesh.surface_get_material(surface)
     if material is StandardMaterial3D and str(material.resource_name).begins_with("Fur cards "):
      hair_count+=1
      var runtime_material=instance.get_surface_override_material(surface) as StandardMaterial3D
      var policy=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS if supplied else BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
      if not runtime_material or runtime_material.transparency!=policy or not runtime_material.albedo_texture:
       failures.append(kind+" fur lost its opacity texture or soft game shading")
      if instance.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:failures.append(kind+" fur casts dotted self-shadows")
   if hair_count==0:failures.append(kind+" coat strips missing")
  var player=GardenAnimalMotion.player(model)
  if not player:
   if not retained:failures.append(kind+" has no imported animations")
   model.free()
   continue
  for clip in player.get_animation_list():
   var animation=player.get_animation(clip)
   for track in range(animation.get_track_count()):
    var path=animation.track_get_path(track)
    if not model.get_node_or_null(NodePath(path.get_concatenated_names())):failures.append(kind+" unresolved animation target: "+str(path))
   for frame in range(12):GardenAnimalMotion.advance(model,clip,.1)
   if not model.position.is_equal_approx(Vector3(13,2,-7)):failures.append(kind+" animation changed navigation position")
   var skeleton=model.find_child("Skeleton3D*",true,false) as Skeleton3D
   var head=model.find_child("Head",true,false) as Node3D
   if skeleton and head and not supplied:
    var bone=skeleton.find_bone("Skin_Head")
    var origin=skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin
    if origin.distance_to(head.global_position)>.015:failures.append(kind+" head skin and control disagree in "+clip)
  if kind in ["cat","dog","wombat","fox","echidna"] and not supplied:
   var knee=model.find_child("LowerFrontL*",true,false) as Node3D
   player.stop()
   GardenAnimalMotion.advance(model,"walk",0)
   player.seek(.15,true)
   var first=knee.rotation
   player.seek(.40,true)
   if knee.rotation.distance_to(first)<.01:failures.append(kind+" has no knee articulation")
   var skeleton=model.find_child("Skeleton3D*",true,false) as Skeleton3D
   if skeleton:
    var bone=skeleton.find_bone("Skin_LowerFrontL")
    if bone<0:failures.append(kind+" lower limb skin bone missing")
    else:
     var origin=skeleton.global_transform*skeleton.get_bone_global_pose(bone).origin
     if origin.distance_to(knee.global_position)>.015:failures.append(kind+" skin and motion control disagree: "+str(origin.distance_to(knee.global_position)))
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
 check_retained_motion(failures)
 print("OVERHAUL_MODELS_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)

func check_retained_motion(failures: Array) -> void:
 var g=VisitorGarden.new()
 root.add_child(g)
 g.add_child(g.player)
 for kind in ["bee","frog"]:
  var model=GardenArt.visitor(kind)
  root.add_child(model)
  if GardenAnimalMotion.player(model):model.free();continue
  var entry={"kind":kind,"node":model,"phase":0.0,"target":Vector3.ZERO,"height":.75}
  GardenWildlifeMotion.animate(g,entry,.1,.10)
  if kind=="bee":
   var wing=model.find_child("WingL*",true,false) as Node3D
   var first=wing.rotation.z
   GardenWildlifeMotion.animate(g,entry,.1,.16)
   if absf(wing.rotation.z-first)<.05:failures.append("Retained bee lost its wingbeats")
  else:
   GardenWildlifeMotion.animate(g,entry,.1,.5)
   if model.position.y-GardenTerrain.point(model.position).y<.08:failures.append("Retained frog lost its hop")
  model.free()
 var visitors=GardenVisitors.new()
 g.add_child(visitors)
 visitors.setup(g)
 visitors.random.seed=41
 visitors.spawn_kind("rabbit")
 for guest in visitors.guests:
  if GardenAnimalMotion.player(guest.node):continue
  guest.wait=0
  guest.target=guest.pos+Vector3(1,0,0)
  var before: Vector3=guest.pos
  visitors._process(.05)
  if guest.pos.distance_to(before)<.001 or guest.node.position.y<=guest.pos.y:failures.append("Retained rabbit lost its travelling hop")
  guest.wait=1
  visitors._process(.1)
  if absf(guest.node.get_node("Head").rotation.x)<.001:failures.append("Retained rabbit lost its resting head motion")
 for guest in visitors.guests:guest.node.free()
 visitors.guests.clear()
 g.free()
