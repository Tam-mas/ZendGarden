class_name GardenCompanion
extends Node3D
var is_cat=true
var model: Node3D
var body: Node3D
var head: Node3D
var tail: Node3D
var legs: Array=[]
var body_rest=Vector3.ZERO
var phase=0.0
var idle=0.0
var gait=0.0
var path=PackedVector3Array()
var route_timer=0.0
var routine_time=0.0
var destination=Vector3.ZERO
var visiting=false
var wander_cycle=-1
static var navigation: AStarGrid2D
static var open_plots=-1

func _ready() -> void:
 model=load("res://assets/companions/%s.glb" % ("cat" if is_cat else "dog")).instantiate()
 add_child(model)
 body=model.find_child("Body*",true,false)
 head=model.find_child("Head*",true,false)
 tail=model.find_child("Tail*",true,false)
 body_rest=body.position
 for name in ["FrontL","FrontR","BackL","BackR"]: legs.append(model.find_child(name+"*",true,false))

static func prepare_navigation(g) -> void:
 if open_plots==g.unlocked_plots: return
 open_plots=g.unlocked_plots
 navigation=AStarGrid2D.new()
 var north=-int(g.plots.size()/2)*34+16
 navigation.region=Rect2i(-17,north,69,19-north)
 navigation.cell_size=Vector2(.5,.5)
 navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 navigation.update()
 for x in range(-17,52):
  for z in range(north,19):
   var p=Vector3(x*.5,0,z*.5)
   var pavilion=absf(p.x+7.4)<1.9 and absf(p.z+18)<1.8
   navigation.set_point_solid(Vector2i(x,z),not g.accessible(p) or pavilion)

func animate(g, delta: float, index: int) -> void:
 prepare_navigation(g)
 routine_time+=delta
 route_timer-=delta
 # Shared visits occasionally overlap; independent offsets make solo visits too.
 var shared=fmod(routine_time,150.0)>130.0
 visiting=shared or fmod(routine_time+index*39.0,94.0)<17.0
 var cycle=int((routine_time+index*11)/24.0)
 if visiting:
  destination=g.player.position
 elif cycle!=wander_cycle:
  wander_cycle=cycle
  # Choose safe path-side resting spots within the unlocked plots.
  var plot_index=(cycle+index*2)%g.unlocked_plots
  var center: Vector3=g.plots[plot_index].center
  var angle=cycle*2.399+index*1.8
  destination=center+Vector3(cos(angle)*5.6,0,sin(angle)*5.6)
 var distance=Vector2(position.x-destination.x,position.z-destination.z).length()
 if route_timer<=0:
  route_timer=1.2+index*.2
  path.clear()
  if distance>(2.3 if visiting else .4):
   var start=Vector2i(round(position.x*2),round(position.z*2))
   var end=Vector2i(round(destination.x*2),round(destination.z*2))
   if navigation.is_in_boundsv(start) and navigation.is_in_boundsv(end) and not navigation.is_point_solid(start) and not navigation.is_point_solid(end):
    for p in navigation.get_point_path(start,end): path.append(Vector3(p.x,0,p.y))
 var moving=false
 if path.size()>0 and distance>(1.8 if visiting else .3):
  var direction=path[0]-position
  direction.y=0
  if direction.length()<.18: path.remove_at(0)
  else:
   direction=direction.normalized()
   position+=direction*minf(delta*(1.2 if is_cat else 1.4),.14)
   rotation.y=lerp_angle(rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*6))
   moving=true
 position.y=GardenTerrain.point(position).y
 if absf(position.x-8.5)<2.25 and absf(position.z-5.9)<.92: position.y=.155
 if absf(position.x-17)<.92 and absf(position.z+8.5)<2.25: position.y=.155
 idle=0.0 if moving else idle+delta
 gait=move_toward(gait,1.0 if moving else 0.0,delta*4)
 phase+=delta*(8.0 if is_cat else 7.0)
 var sit=smoothstep(4,6,idle)
 body.position=body_rest+Vector3(0,sin(phase*2)*.012*gait-sit*.08+sin(phase*.24)*.007,0)
 body.rotation.x=sit*.22
 for j in range(legs.size()):
  legs[j].rotation.x=sin(phase+(PI if j in [1,2] else 0.0))*.48*gait+(sit*.65 if j>=2 else -sit*.2)
 tail.rotation.y=sin(phase*(.6 if is_cat else 1.7))*(.16 if is_cat else .48)
 head.rotation.x=sin(phase*.3)*.07-sit*.2
 var look=to_local((g.player.position if visiting else destination)+Vector3(0,1,0))
 head.rotation.y=clampf(atan2(-look.x,-look.z),-.5,.5)*(1-gait*.7)
 for name in ["EarL","EarR"]:
  var ear=model.find_child(name+"*",true,false)
  ear.rotation.z=sin(phase*.31)*.055+maxf(0,sin(phase*.12))**12*.13
