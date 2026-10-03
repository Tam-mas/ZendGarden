class_name GardenWildlifeMotion
extends RefCounted

const BIRDS=["songbird","native bird","fairy wren","kookaburra","lorikeet","magpie"]
const POLLINATORS=["bee","butterfly","blue banded bee","hoverfly"]

static func foot_clearance(kind: String) -> float:
 return {"songbird":.061,"native bird":.062,"fairy wren":.042,"kookaburra":.097,"lorikeet":.069,"magpie":.083}.get(kind,.06)

static func perch(g, entry: Dictionary) -> Vector3:
 var nearest=INF
 var point=GardenTerrain.point(entry.target)+Vector3(0,foot_clearance(entry.kind),0)
 for obj in g.objects:
  if obj.get("kind","") not in ["bench","arbor","pergola","trellis_screen","gazebo","bath"]:continue
  var distance=obj.pos.distance_to(entry.target)
  if distance<nearest:
   nearest=distance
   var lateral=sin(entry.phase)*.42
   var rests={"bench":Vector3(lateral,1.12,.31),"arbor":Vector3(lateral,2.735,.50),"pergola":Vector3(lateral,2.735,.50),"trellis_screen":Vector3(lateral,1.95,0),"gazebo":Vector3(lateral,.523,1.14),"bath":Vector3(.3,1.07,.3)}
   point=obj.node.to_global(rests[obj.kind]+Vector3(0,foot_clearance(entry.kind),0))
 return point

static func flight_pose(entry: Dictionary, pos: Vector3, direction: Vector3, delta: float, clip: String="flight") -> void:
 entry.node.position=pos
 if direction.length_squared()>.00001:entry.node.rotation.y=atan2(-direction.x,-direction.z)
 if not GardenAnimalMotion.advance(entry.node,clip,delta) and entry.kind=="bee":
  for wing in entry.node.get_children():
   if str(wing.name).begins_with("Wing"):
    wing.rotation.z=sin(float(entry.get("motion_time",0))*35+entry.phase)*.8*float(wing.get_meta("side",1))

static func animate(g, entry: Dictionary, delta: float, time: float) -> bool:
 var kind: String=entry.kind
 var phase=time+entry.phase
 entry.motion_time=time
 var daylight=g.clock_time>.2 and g.clock_time<.8
 if kind in BIRDS:
  # Paired lorikeets share arrival times, with a small spatial separation.
  var cycle=fposmod(time+(0 if kind=="lorikeet" else entry.phase*5),92.0 if kind=="kookaburra" else 56.0)
  var home=perch(g,entry)
  if kind=="magpie":home=GardenTerrain.point(entry.target)+Vector3(0,foot_clearance(kind),0)
  if kind=="lorikeet":home.x+=.28*sin(entry.phase)
  var away=home+Vector3(7,3,-5)
  entry.node.visible=daylight and cycle<36 and (kind!="kookaburra" or g.clock_time<.40)
  if not entry.node.visible:return true
  if cycle<5:
   var p=away.lerp(home,smoothstep(0,5,cycle))
   flight_pose(entry,p,home-away,delta)
  elif cycle>30:
   flight_pose(entry,home.lerp(away,smoothstep(30,36,cycle)),away-home,delta)
  else:
   var ground=kind=="magpie" or kind=="fairy wren" and home.y<GardenTerrain.point(entry.target).y+.20
   var crawl=(cycle-5)*(.16 if kind=="magpie" else .08)
   var p=home+Vector3(sin(crawl)*.32,0,cos(crawl)*.22) if ground else home
   if ground:p.y=GardenTerrain.point(p).y+foot_clearance(kind)
   flight_pose(entry,p,Vector3(cos(crawl),0,-sin(crawl)) if ground else Vector3(-1,0,-1),delta,"forage" if ground else "perch")
  return true
 if kind in ["mantis","leaf insect"]:
  entry.node.visible=daylight
  entry.node.position=GardenTerrain.point(entry.target)+Vector3(.11,entry.get("height",.7),.02)
  entry.node.rotation.y=entry.phase
  GardenAnimalMotion.advance(entry.node,"idle",delta)
  return true
 if kind=="frog":
  var cycle=fposmod(phase,12.0)
  var index=floor(phase/12.0)
  var a=Vector3(cos(index*.9),0,sin(index*.9))*.8
  var b=Vector3(cos((index+1)*.9),0,sin((index+1)*.9))*.8
  var p=entry.target+a.lerp(b,smoothstep(0,1,cycle))
  p.y=GardenTerrain.point(p).y
  if cycle<1 and not GardenAnimalMotion.player(entry.node):p.y+=sin(cycle*PI)*.10
  flight_pose(entry,p,b-a,delta,"hop" if cycle<1 else "idle")
  return true
 if kind in POLLINATORS or kind in ["emperor gum moth","dragonfly","firefly"]:
  entry.node.visible=not daylight if kind in ["emperor gum moth","firefly"] else daylight
  if not entry.node.visible:return true
  var center: Vector3=entry.target+Vector3(0,entry.get("height",.75),0)
  if kind=="emperor gum moth":
   for obj in g.objects:
    if obj.kind=="lantern":center=obj.pos+Vector3(0,1,0);break
  var cycle=fposmod(phase,14.0)
  if kind=="hoverfly":
   var jump=floor(phase/4.0)
   var a=Vector3(sin(jump*2.4),0,cos(jump*2.4))*.28
   var b=Vector3(sin((jump+1)*2.4),0,cos((jump+1)*2.4))*.28
   var mix=smoothstep(3.5,4.0,fposmod(phase,4.0))
   flight_pose(entry,center+a.lerp(b,mix)+Vector3(0,sin(phase*3)*.008,0),b-a,delta)
  elif cycle>10 and kind in POLLINATORS:
   flight_pose(entry,center,Vector3(sin(entry.phase),0,-1),delta,"pollinate" if kind!="butterfly" else "perch")
  else:
   # A loose figure eight slows toward flowers, with a four-second feeding stop.
   var angle=(cycle/10.0)*TAU if kind in POLLINATORS else phase*.65
   var radius=.42 if kind in POLLINATORS else .9
   var p=center+Vector3(sin(angle)*radius,sin(angle*2)*.12,(1-cos(angle*2))*radius*.38)
   var direction=Vector3(cos(angle),0,sin(angle*2)*.76)
   flight_pose(entry,p,direction,delta)
  return true
 return false
