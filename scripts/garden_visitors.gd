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
 spawn_kind("kangaroo" if kangaroos else "rabbit")

func spawn_kind(kind: String) -> void:
 if not guests.is_empty():return
 var start=Vector3.ZERO
 var found=false
 if kind=="fox":
  # A brief silhouette beyond the garden, never a close companion.
  start=GardenTerrain.point(Vector3(-12.5 if random.randf()<.5 else 27,0,-25.5))
  found=start.distance_to(g.player.position)>14
 else:
  for attempt in range(80):
   var angle=random.randf()*TAU
   var candidate=g.player.position+Vector3(cos(angle)*12,0,sin(angle)*12)
   if safe(candidate):
    start=GardenTerrain.point(candidate)
    found=true
    break
 if not found:return
 for i in range(2 if kind=="kangaroo" else 3 if kind=="rabbit" else 1):
  var n=model(kind,kind=="kangaroo" and i==0)
  g.add_child(n)
  var pos=start+Vector3(i*.75,0,0)
  if kind!="fox" and not safe(pos):pos=start
  pos=GardenTerrain.point(pos)
  n.position=pos
  guests.append({"node":n,"pos":pos,"home":pos,"target":pos,"age":0.0,"wait":float(i),"phase":float(i)*1.5,"kangaroo":kind=="kangaroo","kind":kind,"speed":{"rabbit":.85,"kangaroo":1.4,"wombat":.28,"echidna":.22,"fox":.8}.get(kind,.6)})

func safe(pos: Vector3) -> bool:
 return g.plantable_ground(pos) and g.bed_at(pos)<0 and g.nearest_plot(pos)<g.unlocked_plots

func _process(delta: float) -> void:
 if not is_instance_valid(g) or is_instance_valid(g.welcome) or (g.settings.pause_menus and not g.gameplay_active() and not g.smoke): return
 if guests.is_empty():
  countdown-=delta
  if countdown<=0:
   var choice=random.randf()
   var dusk=g.clock_time>.65 or g.clock_time<.28
   spawn_kind("fox" if choice<.05 and dusk else "wombat" if choice<.25 and dusk else "echidna" if choice<.45 else "kangaroo" if choice<.60 else "rabbit")
   countdown=random.randf_range(85,150)
  return
 for guest in guests.duplicate():
  guest.age+=delta
  if guest.age>(22 if guest.kind=="fox" else 65):
   guest.node.queue_free()
   guests.erase(guest)
   continue
  guest.wait-=delta
  var shy=guest.kind in ["fox","echidna"] and guest.pos.distance_to(g.player.position)<(10.0 if guest.kind=="fox" else 3.5)
  if shy:
   if guest.kind=="echidna":
    guest.wait=1.0
   else:
    guest.target=GardenTerrain.point(guest.home+Vector3(-5 if guest.home.x<0 else 5,0,-2))
    guest.wait=0.0
  if guest.wait<=0 and guest.pos.distance_to(guest.target)<.1:
   for attempt in range(12):
    var target=guest.home+Vector3(random.randf_range(-3,3),0,random.randf_range(-3,3))
    if (guest.kind=="fox" and target.distance_to(g.player.position)>12) or (guest.kind!="fox" and safe(target)):
     guest.target=GardenTerrain.point(target)
     break
   guest.wait=random.randf_range(2,5)
  var moving=guest.wait<=0 and guest.pos.distance_to(guest.target)>.1
  if moving:
   var next=guest.pos.move_toward(guest.target,delta*guest.speed)
   if guest.kind=="fox" or safe(next):
    var direction=next-guest.pos
    guest.node.rotation.y=lerp_angle(guest.node.rotation.y,atan2(-direction.x,-direction.z),minf(1,delta*4))
    guest.pos=GardenTerrain.point(next)
   else:
    guest.target=guest.pos
    guest.wait=1.0
  guest.node.position=guest.pos
  var clip="hop" if moving and guest.kind in ["rabbit","kangaroo"] else "walk" if moving else "alert" if shy else "graze" if guest.age>5 else "idle"
  GardenAnimalMotion.advance(guest.node,clip,delta,{"wombat":1.66,"echidna":1.9,"fox":1.33}.get(guest.kind,1.0) if moving else 1.0)

static func model(kind: String, joey: bool = false) -> Node3D:
 var n=GardenArt.detailed_model("wildlife","kangaroo_joey" if kind=="kangaroo" and joey else kind)
 return n
