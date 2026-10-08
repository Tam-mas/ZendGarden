class_name GardenRavine
extends RefCounted

const BRIDGES=[6.,-48.,-102.]
static var cached: Dictionary={}

static func data() -> Dictionary:
 if cached.is_empty():cached=JSON.parse_string(FileAccess.get_file_as_string("res://assets/areas/ravine.json"))
 return cached

static func ground(x: float,z: float) -> float:
 var u=clampf((x-25.5)*4.,0.,74.);var v=clampf((z+108.)*4.,0.,480.)
 var ix=mini(73,floori(u));var iz=mini(479,floori(v));var rows: Array=data().ground
 return lerpf(lerpf(rows[iz][ix],rows[iz][ix+1],u-ix),lerpf(rows[iz+1][ix],rows[iz+1][ix+1],u-ix),v-iz)

static func stream(z: float) -> Vector4:
 var t=clampf((z+108.)*4.,0.,480.);var i=mini(479,floori(t));var a: Array=data().stream[i];var b: Array=data().stream[i+1]
 return Vector4(a[0],a[1],a[2],a[3]).lerp(Vector4(b[0],b[1],b[2],b[3]),t-i)

static func deck(x: float,z: float) -> float:
 var t=(x-25.5)/18.5
 return lerpf(GardenTerrain.original_rise(25.5,z)+.38,1.325,t)+.72*pow(sin(PI*t),2.)

static func bridge_at(p: Vector3,margin: float=1.4) -> int:
 if p.x<25.5 or p.x>44.:return -1
 for j in range(3):
  if absf(p.z-BRIDGES[j])<=margin:return j
 return -1

static func walkable(p: Vector3) -> bool:
 return p.x<=28.35 or p.x>=41.65 or bridge_at(p,1.22)>=0

static func walk_point(p: Vector3) -> Vector3:
 var crossing=bridge_at(p)
 if crossing>=0:return Vector3(p.x,deck(p.x,BRIDGES[crossing]),p.z)
 return Vector3(p.x,GardenAreaTransitions.trail_height(p) if absf(p.x-27.)<1.05 else ground(p.x,p.z),p.z)

static func safe_player(p: Vector3) -> Vector3:
 if not GardenConnectedLand.contains(p):return GardenTerrain.point(p)
 if not walkable(p):p.x=27. if p.x<34.75 else 42.7
 return walk_point(p)

static func grass_allowed(p: Vector3) -> bool:
 return not GardenConnectedLand.on_trail(p) and (p.x<28.6 or p.x>41.3)

static func prepare(node: Node,solid: bool=false) -> void:
 solid=solid or str(node.name).begins_with("StoneBridge")
 if node is MeshInstance3D:
  if solid:
   node.create_trimesh_collision()
   for body in node.get_children():
    if body is StaticBody3D:body.set_meta("planting_obstacle",true)
  elif str(node.name).begins_with("Ravine escarpment"):
   node.visibility_range_end=0
   node.create_trimesh_collision()
  else:node.visibility_range_end=110
 for child in node.get_children():prepare(child,solid)

static func prepare_cliff(node: Node) -> void:
 if node is MeshInstance3D and str(node.name).begins_with("Ravine escarpment"):
  var mat=ShaderMaterial.new();mat.shader=load("res://shaders/mountain.gdshader")
  mat.set_shader_parameter("rock_scale",.38)
  mat.set_shader_parameter("strata",load("res://assets/textures/Mountain_strata.webp"))
  mat.set_shader_parameter("rock_normal",load("res://assets/textures/Mountain_strata_normal.webp"))
  node.material_override=mat
 for child in node.get_children():prepare_cliff(child)

static func build(g,root: Node3D) -> void:
 var model=GardenAreas.instantiate("res://assets/environment/alpine_ravine.glb")
 if model:
  root.add_child(model);prepare(model);GardenAreaMaterials.prepare(model)
  prepare_cliff(model)
  GardenAreaFlora.build(g,model)
 for j in range(3):
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for k in range(74):
   var x=25.5+k*.25;var z: float=BRIDGES[j]
   for p in [Vector2(x,z-1.4),Vector2(x+.25,z-1.4),Vector2(x+.25,z+1.4),Vector2(x,z-1.4),Vector2(x+.25,z+1.4),Vector2(x,z+1.4)]:
    st.set_uv(p);st.add_vertex(Vector3(p.x,deck(p.x,z),p.y))
  st.generate_normals();st.generate_tangents();st.index()
  var mesh=MeshInstance3D.new();mesh.name="BridgeDeck%d"%j;mesh.mesh=st.commit();mesh.material_override=GardenAreaTransitions.bluestone()
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  root.add_child(mesh);mesh.create_trimesh_collision()
 for reach in range(10):build_water(root,reach)
 build_fall(root)

static func build_water(root: Node3D,reach: int) -> void:
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var origin=Vector3(34.8,0,-108.+reach*12.+6.)
 var points=[]
 for k in range(49):
  var z=-108.+reach*12.+k*.25;var p=stream(z)
  points.append(Vector3(p.x,p.y,z)-origin)
 for k in range(48):
  for lane in range(8):
   for corner in [Vector2i(k,lane),Vector2i(k+1,lane),Vector2i(k+1,lane+1),Vector2i(k,lane),Vector2i(k+1,lane+1),Vector2i(k,lane+1)]:
    var z=-108.+reach*12.+corner.x*.25;var p=stream(z);var across=corner.y/8.
    st.set_uv(Vector2(across,z));st.add_vertex(Vector3(p.x+(across-.5)*p.w*2.,p.y,z)-origin)
 st.generate_normals();st.generate_tangents();st.index()
 var mesh=MeshInstance3D.new();mesh.name="AlpineCurrent%d"%reach;mesh.mesh=st.commit();mesh.position=origin
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var mat=ShaderMaterial.new();mat.shader=load("res://shaders/ravine_water.gdshader")
 mat.set_shader_parameter("deep_color",Color("254f50"));mat.set_shader_parameter("edge_color",Color("688779"))
 mesh.material_override=mat;root.add_child(mesh)
 GardenWater.register(mesh,{"kind":"stream","points":points,"width":4.7})

static func cliff_outset(x: float,z: float,level: float) -> float:
 return level*.18+(1.4+1.2*sin(z*.31+x*.23)+.7*sin(z*.79+x*.48))*minf(1.,level/7.)

static func build_fall(root: Node3D) -> void:
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var s=stream(12.)
 for row in range(80):
  for lane in range(8):
   for corner in [Vector2i(row,lane),Vector2i(row+1,lane),Vector2i(row+1,lane+1),Vector2i(row,lane),Vector2i(row+1,lane+1),Vector2i(row,lane+1)]:
    var t=corner.x/80.;var across=corner.y/8.
    var x=s.x+(across-.5)*lerpf(s.w*2.,2.8,t);var y=lerpf(s.y,-63.,t)
    var top=ground(x,12.);var level=maxf(0.,(top-y)/(top+66.)*66.)
    st.set_uv(Vector2(across,t*60.));st.add_vertex(Vector3(x,y,12.+cliff_outset(x,12.,level)+.065))
 st.generate_normals();st.generate_tangents();st.index()
 var mesh=MeshInstance3D.new();mesh.name="RavineOutletFall";mesh.mesh=st.commit()
 var mat=ShaderMaterial.new();mat.shader=load("res://shaders/ravine_fall.gdshader")
 mesh.material_override=mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 root.add_child(mesh);GardenWater.register(mesh,{"kind":"fall"})

static func furniture_radius(kind: String) -> float:
 return float({"greenhouse":5.,"gazebo":3.,"pergola":3.,"nursery_shelf":4.4,"pond":2.5,"bench":1.8,"raised_bed":1.5,"harvest_table":2.2}.get(kind,1.0))

static func recover_arrangements(g) -> void:
 # The former joining lawn was plantable. Lift its plants with their complete
 # care records, and keep furnishings (including jobs and planter contents)
 # together on a clear patch of adjacent land. This is naturally idempotent.
 var lifted=0;var moved=0
 for plant in g.planted.duplicate():
  if GardenConnectedLand.contains(plant.pos) and not GardenContainers.is_contained(plant):
   GardenContainers.store(g,plant,"Former joining slope");lifted+=1
 for obj in g.objects:
  if not GardenConnectedLand.contains(obj.pos):continue
  var radius=furniture_radius(obj.kind)
  var candidates=[]
  for x in range(-6,66,2):
   if x>24 and x<46:continue
   for z in range(-104,9,2):
    var p=Vector3(x,0,z)
    if not g.accessible(p) or GardenAreaCatalogue.index_at(p)>=0 and not GardenAreaCatalogue.plot_open(g,g.nearest_plot(p)):continue
    candidates.append(p)
  candidates.sort_custom(func(a,b):return a.distance_squared_to(obj.pos)<b.distance_squared_to(obj.pos))
  for p in candidates:
   var clear=true;var base=GardenTerrain.point(p)
   for other in g.objects:
    if other!=obj and Vector2(p.x-other.pos.x,p.z-other.pos.z).length()<radius+furniture_radius(other.kind)+.2:clear=false;break
   if not clear:continue
   for plant in g.planted:
    if plant.get("container_uid","")!=obj.uid and Vector2(p.x-plant.pos.x,p.z-plant.pos.z).length()<radius+.3:clear=false;break
   if not clear:continue
   for step in range(9):
    var probe=p+Vector3(cos(step*TAU/8.),0,sin(step*TAU/8.))*(radius if step<8 else 0.)
    if not g.plantable_ground(probe) or absf(GardenTerrain.point(probe).y-base.y)>.4:clear=false;break
   if not clear:continue
   var supports=GardenAreaFurnishings.removal_snapshot(g,obj)
   var offset=base-obj.pos
   obj.pos=base;obj.node.position=base;obj.elevation=0.
   for uid in supports:
    var pot=GardenContainers.object(g,uid)
    if not pot.is_empty():
     pot.pos+=offset;pot.node.position=pot.pos;pot.elevation=pot.pos.y-GardenTerrain.point(pot.pos).y
   GardenContainers.sync(g);moved+=1;break
  # In a fully occupied garden, keep the original item available on the east
  # bank. Its persistent record and contents are never discarded or refunded.
  if GardenConnectedLand.contains(obj.pos):
   obj.pos=GardenTerrain.point(Vector3(46.5,0,obj.pos.z));obj.node.position=obj.pos;obj.elevation=0.
   GardenContainers.sync(g);moved+=1
 if lifted>0 or moved>0:
  GardenSaveFiles.arrival_notice="The mountain stream is ready. %d plants from the old slope are safe in Stored plants; %d ornaments moved onto dry ground."%[lifted,moved]
