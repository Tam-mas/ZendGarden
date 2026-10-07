class_name GardenWater
extends Node

# Bounded analytic waves and radial disturbances work in WebGL2. Garden water
# levels and gate bonuses remain the authority for growth and saved progress.
var garden
var surfaces: Array=[]
var elapsed=0.
var rain_timer=0.
var footstep_timer=0.
var last_position=Vector3.ZERO
var random=RandomNumberGenerator.new()

static func register(node: MeshInstance3D,shape: Dictionary) -> void:
 node.add_to_group("garden_water")
 node.set_meta("water_shape",shape)
 node.extra_cull_margin=.18

static func setup(g) -> void:
 var water=GardenWater.new();water.name="GardenWater";water.garden=g;g.add_child(water)
 water.last_position=g.player.position;water.random.seed=7493
 for node in g.get_tree().get_nodes_in_group("garden_water"):
  water.surfaces.append({"node":node,"material":node.material_override,"events":[]})

static func disturb(g,pos: Vector3,strength: float=1.) -> void:
 var water=g.get_node_or_null("GardenWater")
 if water:water.splash(pos,strength)

func contains(node: MeshInstance3D,pos: Vector3,margin: float=0.) -> bool:
 if not node.is_visible_in_tree():return false
 var p=node.to_local(pos);var shape: Dictionary=node.get_meta("water_shape",{})
 match shape.get("kind",""):
  "ellipse":return Vector2((p.x-shape.x)/(shape.rx+margin),(p.z-shape.z)/(shape.rz+margin)).length()<1.
  "stream":
   var points: Array=shape.points
   for k in range(points.size()-1):
    var a=Vector2(points[k].x,points[k].z);var b=Vector2(points[k+1].x,points[k+1].z)
    if Vector2(p.x,p.z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),a,b))<shape.width*.5+margin:return true
  "plane":return absf(p.x)<shape.size.x*.5+margin and absf(p.z)<shape.size.y*.5+margin
 return false

func splash(pos: Vector3,strength: float=1.,footstep: bool=false) -> void:
 if garden.settings.reduced_motion:return
 for entry in surfaces:
  if not contains(entry.node,pos):continue
  if footstep:
   var surface_y=entry.node.to_global(entry.node.mesh.get_aabb().get_center()).y
   if absf(pos.y-surface_y)>.38:continue # Walking on a bridge stays dry.
  entry.events.append(Vector4(pos.x,pos.z,elapsed,clampf(strength,.1,1.5)))
  if entry.events.size()>6:entry.events.pop_front()
  sync_events(entry)

func sync_events(entry: Dictionary) -> void:
 var buffer=PackedVector4Array()
 for event in entry.events:buffer.append(event)
 while buffer.size()<6:buffer.append(Vector4.ZERO)
 entry.material.set_shader_parameter("ripple_events",buffer)
 entry.material.set_shader_parameter("ripple_count",entry.events.size())

func _process(delta: float) -> void:
 if garden.settings.reduced_motion:return
 elapsed+=delta;rain_timer-=delta;footstep_timer-=delta
 for entry in surfaces:
  entry.material.set_shader_parameter("water_time",elapsed)
  entry.material.set_shader_parameter("wind_strength",.8+garden.climate.current.x*.5)
  var expired=false
  while not entry.events.is_empty() and elapsed-entry.events[0].z>5.:
   entry.events.pop_front();expired=true
  if expired:sync_events(entry)
 var distance=Vector2(garden.player.position.x-last_position.x,garden.player.position.z-last_position.z).length()
 if footstep_timer<=0 and distance>.3:
  splash(garden.player.position,.45,true);last_position=garden.player.position;footstep_timer=.35
 if rain_timer<=0 and garden.climate.current.y>.15:
  rain_timer=.22/maxf(.2,garden.climate.current.y)
  for entry in surfaces:
   if not entry.node.is_visible_in_tree() or entry.node.global_position.distance_to(garden.camera.global_position)>40:continue
   var shape: Dictionary=entry.node.get_meta("water_shape",{})
   var local=Vector3.ZERO
   if shape.kind=="ellipse":
    var angle=random.randf()*TAU;var radius=sqrt(random.randf())*.86
    local=Vector3(shape.x+cos(angle)*radius*shape.rx,0,shape.z+sin(angle)*radius*shape.rz)
   elif shape.kind=="stream":local=shape.points[random.randi_range(0,shape.points.size()-1)]
   elif shape.kind=="plane":local=Vector3(random.randf_range(-.4,.4)*shape.size.x,0,random.randf_range(-.4,.4)*shape.size.y)
   else:continue
   splash(entry.node.to_global(local),.25)

static func subdivide_lake(node: MeshInstance3D) -> void:
 # Retain the authored shoreline; subdivide only to let the broad waves bend.
 var faces=node.mesh.get_faces();var stack: Array=[]
 for k in range(0,faces.size(),3):stack.append([faces[k],faces[k+1],faces[k+2],0])
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 while not stack.is_empty():
  var tri=stack.pop_back();var longest=0;var length=0.
  for edge in range(3):
   var size=(node.global_basis*(tri[(edge+1)%3]-tri[edge])).length()
   if size>length:longest=edge;length=size
  if length>8. and tri[3]<10:
   var a=tri[longest];var b=tri[(longest+1)%3];var c=tri[(longest+2)%3];var mid=(a+b)*.5
   stack.append([a,mid,c,tri[3]+1]);stack.append([mid,b,c,tri[3]+1])
  else:
   for k in range(3):st.add_vertex(tri[k])
 st.generate_normals();st.index();node.mesh=st.commit()
