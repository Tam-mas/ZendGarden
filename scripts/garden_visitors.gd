class_name GardenVisitors
extends Node

var g
var guests: Array=[]
var countdown=25.0
var random=RandomNumberGenerator.new()

func setup(game) -> void:
 g=game
 random.randomize()

func spawn_group(kangaroos: bool) -> void:
 if not guests.is_empty(): return
 var start=Vector3.ZERO
 var found=false
 for attempt in range(80):
  var angle=random.randf()*TAU
  var candidate=g.player.position+Vector3(cos(angle)*12,0,sin(angle)*12)
  if g.plantable_ground(candidate) and g.bed_at(candidate)<0 and g.nearest_plot(candidate)<g.unlocked_plots:
   start=GardenTerrain.point(candidate)
   found=true
   break
 if not found: return
 for i in range(2 if kangaroos else 3):
  var n=model("kangaroo" if kangaroos else "rabbit",kangaroos and i==0)
  g.add_child(n)
  var pos=start+Vector3(i*.75,0,0)
  if not safe(pos): pos=start
  pos=GardenTerrain.point(pos)
  n.position=pos
  guests.append({"node":n,"pos":pos,"home":pos,"target":pos,"age":0.0,"wait":float(i),"phase":float(i)*1.5,"kangaroo":kangaroos})

func safe(pos: Vector3) -> bool:
 return g.plantable_ground(pos) and g.bed_at(pos)<0 and g.nearest_plot(pos)<g.unlocked_plots

func _process(delta: float) -> void:
 if not is_instance_valid(g) or is_instance_valid(g.welcome) or (g.settings.pause_menus and not g.gameplay_active() and not g.smoke): return
 if guests.is_empty():
  countdown-=delta
  if countdown<=0:
   spawn_group(false)
   countdown=random.randf_range(85,150)
  return
 for guest in guests.duplicate():
  guest.age+=delta
  if guest.age>65:
   guest.node.queue_free()
   guests.erase(guest)
   continue
  guest.wait-=delta
  if guest.wait<=0 and guest.pos.distance_to(guest.target)<.1:
   for attempt in range(12):
    var target=guest.home+Vector3(random.randf_range(-3,3),0,random.randf_range(-3,3))
    if safe(target):
     guest.target=GardenTerrain.point(target)
     break
   guest.wait=random.randf_range(2,5)
  var moving=guest.wait<=0 and guest.pos.distance_to(guest.target)>.1
  if moving:
   var next=guest.pos.move_toward(guest.target,delta*(1.4 if guest.kangaroo else .85))
   if safe(next):
    var direction=next-guest.pos
    guest.node.rotation.y=atan2(-direction.x,-direction.z)
    guest.pos=GardenTerrain.point(next)
   else:
    guest.target=guest.pos
    guest.wait=1.0
  var hop=absf(sin(guest.age*(7 if guest.kangaroo else 11)+guest.phase))*(.15 if guest.kangaroo else .08) if moving else 0.0
  guest.node.position=guest.pos+Vector3(0,hop,0)
  guest.node.get_node("Head").rotation.x=.3*sin(guest.age*1.5) if not moving else 0.0

static func model(kind: String, joey: bool = false) -> Node3D:
 var n=GardenArt.detailed_model("wildlife","kangaroo_joey" if kind=="kangaroo" and joey else kind)
 var head=n.find_child("Head*",true,false) as Node3D
 if head:
  if head.get_parent()!=n:
   head.owner=null
   head.reparent(n,false)
  head.name="Head"
 return n
