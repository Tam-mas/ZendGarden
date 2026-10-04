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
 for kind in ["cat","dog","fox","echidna","rabbit"]:
  var model=GardenArt.detailed_model("companions" if kind in ["cat","dog"] else "wildlife",kind)
  root.add_child(model)
  model.position=Vector3(13,2,-7)
  var skeleton=model.find_child("Skeleton3D*",true,false) as Skeleton3D
  var animation=GardenAnimalMotion.player(model)
  if model.get_meta("supplied_animal","")!=kind or not skeleton or not animation:
   failures.append(kind+" approved rig missing")
   model.free()
   continue
  var head=skeleton.find_bone("Head")
  var pelvis=skeleton.find_bone("Pelvis")
  var nose=skeleton.global_transform*skeleton.get_bone_global_pose(head).origin
  var rear=skeleton.global_transform*skeleton.get_bone_global_pose(pelvis).origin
  if nose.z>=rear.z:failures.append(kind+" faces away from -Z navigation")
  var required=["idle","pet","settle","stretch","walk"] if kind=="cat" else ["idle","pet","settle","sniff","walk"] if kind=="dog" else ["idle","graze","alert","hop" if kind=="rabbit" else "walk"]
  for clip in required:
   animation.stop()
   if not GardenAnimalMotion.advance(model,clip,0):failures.append(kind+" gameplay clip missing: "+clip);continue
   var duration=animation.current_animation_length
   for fraction in [0.0,.125,.25,.5,.75,1.0]:
    animation.seek(duration*fraction,true)
    for bone in range(skeleton.get_bone_count()):
     var pose=skeleton.get_bone_global_pose(bone)
     if not pose.origin.is_finite() or not pose.basis.x.is_finite():failures.append(kind+" invalid pose in "+clip)
    if not model.position.is_equal_approx(Vector3(13,2,-7)):failures.append(kind+" animation moved navigation root")
  animation.stop()
  var gait="hop" if kind=="rabbit" else "walk"
  GardenAnimalMotion.advance(model,gait,0)
  var knee=skeleton.find_bone("FrontL_Lower")
  animation.seek(animation.current_animation_length*.15,true)
  var first=skeleton.get_bone_pose_rotation(knee)
  animation.seek(animation.current_animation_length*.4,true)
  if absf(first.dot(skeleton.get_bone_pose_rotation(knee)))>.99999:failures.append(kind+" gait does not articulate its knee")
  if kind!="rabbit":
   var foot=skeleton.find_bone("FrontL_Paw")
   var rest=skeleton.get_bone_global_rest(foot).origin.y
   var duration=animation.current_animation_length
   var lowest=INF
   for sample in range(48):
    animation.seek(duration*sample/48.0,true)
    lowest=minf(lowest,skeleton.get_bone_global_pose(foot).origin.y)
   if absf(lowest-rest)>.012:failures.append(kind+" contact ankle drifts from ground")
  model.free()
 # Integrated hop travel is independent of frame rate and stays still on land.
 if absf(GardenAnimalMotion.hop_progress(.17))>.00001 or absf(GardenAnimalMotion.hop_progress(.8)-1)>.00001:failures.append("Rabbit slides during crouch or landing")
 var reference=-1.0
 for fps in [30,60,144]:
  var g=VisitorGarden.new()
  root.add_child(g);g.add_child(g.player)
  var visitors=GardenVisitors.new();g.add_child(visitors);visitors.setup(g)
  visitors.random.seed=41;visitors.spawn_kind("rabbit")
  var guest=visitors.guests[0]
  guest.pos=GardenTerrain.point(Vector3.ZERO)
  guest.target=GardenTerrain.point(Vector3(4,0,0));guest.wait=0
  for frame in range(fps*3):
   visitors._process(1.0/fps)
   if frame==0 and guest.pos.x>.00001:failures.append("Rabbit travelled before takeoff")
  if reference<0:reference=guest.pos.x
  if guest.pos.x<.8 or absf(guest.pos.x-reference)>.002:failures.append("Rabbit actual travel changes with frame rate: "+str(guest.pos.x))
  if (-guest.node.basis.z).dot(Vector3.RIGHT)<.99:failures.append("Rabbit turns away during its grounded hop pause")
  g.free()
 print("SUPPLIED_ANIMALS_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)
