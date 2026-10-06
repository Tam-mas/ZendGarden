class_name GardenAreaTransitions
extends RefCounted

static var routes: Dictionary={}
static var blue_material: ShaderMaterial

static func route_data() -> Dictionary:
 if routes.is_empty():routes=JSON.parse_string(FileAccess.get_file_as_string("res://assets/areas/routes.json"))
 return routes

static func approach(index: int,t: float) -> Vector2:
 var points: Array=route_data().approaches[index]
 var fraction=clampf(t,0,1)*(points.size()-1)
 var i=mini(points.size()-2,floori(fraction))
 return Vector2(points[i][0],points[i][1]).lerp(Vector2(points[i+1][0],points[i+1][1]),fraction-i)

static func near_route(points: Array,p: Vector2,margin: float) -> bool:
 for j in range(points.size()-1):
  var a=Vector2(points[j][0],points[j][1]);var b=Vector2(points[j+1][0],points[j+1][1])
  if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))<margin:return true
 return false

static func on_path(index: int,pos: Vector3) -> bool:
 var p=pos-GardenAreaCatalogue.center(index)
 if absf(p.x-(12 if index%2==0 else -12))<1.03:return true
 if index==0 and near_route(route_data().eastern_link,Vector2(pos.x,pos.z),1.10):return true
 return near_route(route_data().approaches[index],Vector2(p.x,p.z),1.03)

static func bluestone() -> ShaderMaterial:
 if not blue_material:
  blue_material=ShaderMaterial.new();blue_material.shader=load("res://shaders/bluestone.gdshader")
  blue_material.set_shader_parameter("stone",load("res://assets/textures/bluestone/stone.webp"))
  blue_material.set_shader_parameter("relief",load("res://assets/textures/bluestone/normal.webp"))
 return blue_material

static func eastern_link(root: Node3D) -> void:
 var points: Array=route_data().eastern_link
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for j in range(points.size()-1):
  var quad=[]
  for k in [j,j+1]:
   var a=Vector2(points[maxi(0,k-1)][0],points[maxi(0,k-1)][1])
   var b=Vector2(points[mini(points.size()-1,k+1)][0],points[mini(points.size()-1,k+1)][1])
   var tangent=(b-a).normalized();var normal=Vector2(-tangent.y,tangent.x)
   for edge in [-1.,0.,1.]:
    var p=Vector2(points[k][0],points[k][1])+normal*edge
    quad.append(Vector3(p.x,0,p.y))
  for lane in range(2):
   for k in [lane,lane+3,lane+4,lane,lane+4,lane+1]:
    var p: Vector3=quad[k];st.set_uv(Vector2(p.x,p.z));st.add_vertex(GardenTerrain.point(p)+Vector3(0,.055,0))
 st.generate_normals();st.generate_tangents()
 var mesh=MeshInstance3D.new();mesh.name="Reedwater perimeter link";mesh.mesh=st.commit()
 mesh.set_meta("editable_ground",true);mesh.material_override=bluestone();root.add_child(mesh)

static func build(g) -> void:
 var root=Node3D.new();root.name="GardenConnectingTrail";g.world_root.add_child(root)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 # The shared boundary is flat in the original height field. Retain that field
 # for saves, planting rays and sculpting, and grade each surface to it.
 for k in range(236):
  var z=-106+k*.5
  var width=.94+.035*sin(z*.38);var next_width=.94+.035*sin((z+.5)*.38)
  # A centre vertex and half-metre cross sections follow both banks and carry
  # sparse metre-grid terrain edits through the middle of the walking surface.
  for lane in range(4):
   var a=lane/2.-1.;var b=(lane+1)/2.-1.
   var quad=[Vector3(68+width*a,0,z),Vector3(68+next_width*a,0,z+.5),Vector3(68+next_width*b,0,z+.5),Vector3(68+width*b,0,z)]
   for points in [[quad[0],quad[2],quad[1]],[quad[0],quad[3],quad[2]]]:
    for p in points:st.set_uv(Vector2(p.x,p.z));st.add_vertex(GardenTerrain.point(p)+Vector3(0,.055,0))
 st.generate_normals();st.generate_tangents()
 var mesh=MeshInstance3D.new();mesh.name="Shared garden trail";mesh.mesh=st.commit()
 mesh.set_meta("editable_ground",true)
 mesh.material_override=bluestone();root.add_child(mesh)
 eastern_link(root)
 for j in range(5):
  var sign=g.Art.furnishing("sign");root.add_child(sign)
  sign.position=GardenTerrain.point(Vector3(69.7,0,6-j*24))+Vector3(0,.02,0)
  sign.rotation.y=-PI/2;sign.set_meta("terrain_anchor",true)
  g.Art.set_sign_text(sign,GardenAreaCatalogue.entry(j*2).name+"\n"+GardenAreaCatalogue.entry(j*2+1).name)
  GardenAreaMaterials.prepare(sign)
