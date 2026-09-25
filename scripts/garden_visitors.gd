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
 var art=GardenArt
 var n=Node3D.new()
 n.name="KangarooWithJoey" if joey else kind.capitalize()
 var kangaroo=kind=="kangaroo"
 var fur=Color("a48766") if kangaroo else Color("b9afa1")
 var dark=Color("302820")
 var body_height=.87 if kangaroo else .25
 art.ball(n,Vector3(0,body_height,0),Vector3(.47,1.1,.53) if kangaroo else Vector3(.31,.36,.55),fur)
 var head=Node3D.new()
 head.name="Head"
 head.position=Vector3(0,1.46,-.28) if kangaroo else Vector3(0,.42,-.27)
 n.add_child(head)
 art.ball(head,Vector3.ZERO,Vector3(.29,.35,.34) if kangaroo else Vector3(.27,.25,.26),fur)
 art.ball(head,Vector3(0,-.06,-.17),Vector3(.19,.16,.27) if kangaroo else Vector3(.14,.10,.10),fur.lightened(.12))
 for side in [-1,1]:
  var ear=art.ball(head,Vector3(side*.095,.25,.025),Vector3(.095,.40,.09) if kangaroo else Vector3(.075,.36,.075),fur)
  ear.rotation.z=-side*.18
  art.ball(head,Vector3(side*.095,.25,-.024),Vector3(.039,.25,.012),Color("cba394"))
  art.ball(head,Vector3(side*.116,.02,-.12),Vector3.ONE*.035,dark)
  art.ball(n,Vector3(side*.20,.35,.13),Vector3(.27,.58,.36) if kangaroo else Vector3(.18,.24,.23),fur.darkened(.08))
  art.ball(n,Vector3(side*.18,.09,-.09),Vector3(.17,.14,.52) if kangaroo else Vector3(.12,.10,.25),fur)
  if kangaroo: art.branch(n,Vector3(side*.2,1.12,-.12),Vector3(side*.17,.79,-.36),.055,fur)
 art.ball(head,Vector3(0,-.045,-.31 if kangaroo else -.23),Vector3(.075,.045,.055),dark)
 if kangaroo:
  art.branch(n,Vector3(0,.48,.19),Vector3(0,.12,.90),.13,fur)
  art.branch(n,Vector3(0,.12,.9),Vector3(0,.04,1.35),.055,fur)
  if joey:
   art.ball(n,Vector3(0,.83,-.27),Vector3(.34,.42,.16),fur.lightened(.23))
   art.ball(n,Vector3(0,1.01,-.33),Vector3(.21,.07,.10),fur.darkened(.3))
   art.ball(n,Vector3(0,1.09,-.34),Vector3(.16,.19,.19),fur.lightened(.1))
   for side in [-1,1]:
    art.ball(n,Vector3(side*.055,1.22,-.31),Vector3(.043,.18,.045),fur)
    art.ball(n,Vector3(side*.065,1.11,-.41),Vector3.ONE*.021,dark)
 else: art.ball(n,Vector3(0,.3,.31),Vector3.ONE*.15,Color("ece3d2"))
 return n
