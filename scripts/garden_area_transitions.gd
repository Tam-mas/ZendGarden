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
 for route in route_data().bridge_links:
  if near_route(route,Vector2(pos.x,pos.z),1.1):return true
 var p=pos-GardenAreaCatalogue.center(index)
 if absf(p.x-(12 if index%2==0 else -12))<1.03:return true
 if index==0 and near_route(route_data().eastern_link,Vector2(pos.x,pos.z),1.10):return true
 if p.z>=-9. and p.z<=float(route_data().approaches[index][-1][1]):
  if index==1 and absf(p.x-(sin(p.z*.42)+.30*sin(p.z*.83)+1.55))<.68:return true
  if index==3 and absf(p.x-3.*sin(p.z*.4))<.94:return true
  if index==8 and absf(p.x-2.4*sin(p.z*.45))<.84:return true
 return near_route(route_data().approaches[index],Vector2(p.x,p.z),1.03)

static func bluestone() -> ShaderMaterial:
 if not blue_material:
  blue_material=ShaderMaterial.new();blue_material.shader=load("res://shaders/bluestone.gdshader")
  blue_material.set_shader_parameter("stone",load("res://assets/textures/garden-path/split-sandstone.webp"))
  blue_material.set_shader_parameter("relief",load("res://assets/textures/garden-path/split-sandstone-normal.webp"))
  blue_material.set_shader_parameter("stone_tint",Color(.54,.55,.51))
  blue_material.set_shader_parameter("joint_tint",Color(.24,.215,.17).linear_to_srgb())
 return blue_material

static func trail_clearance(x: float) -> float:
 return lerpf(.12,.055,smoothstep(40.,44.,x))

static func trail_height(p: Vector3) -> float:
 var y=GardenTerrain.point(p).y+(.17 if p.x<28. else trail_clearance(p.x))
 for z in GardenRavine.BRIDGES:
  var weight=1.-smoothstep(1.4,3.5,absf(p.z-z))
  if p.x<29.:
   weight*=smoothstep(23.,25.5,p.x)
  elif p.x>40.:
   weight*=1.-smoothstep(44.,46.,p.x)
  else:continue
  if weight>0.:y=lerpf(y,GardenRavine.deck(clampf(p.x,25.5,44.),z),weight)
 return y

static func build(g) -> void:
 var root=Node3D.new();root.name="GardenConnectingTrail";g.world_root.add_child(root)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var base=SurfaceTool.new();base.begin(Mesh.PRIMITIVE_TRIANGLES)
 var footprint: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/areas/connecting_trail.json"))
 for polygon in footprint.polygons:
  for edge in range(polygon.size()):
   var a=Vector3(polygon[edge][0],0,polygon[edge][1]);var b=Vector3(polygon[(edge+1)%polygon.size()][0],0,polygon[(edge+1)%polygon.size()][1])
   var top_a=Vector3(a.x,trail_height(a)-.002,a.z);var top_b=Vector3(b.x,trail_height(b)-.002,b.z)
   var low_a=Vector3(a.x,GardenTerrain.point(a).y-.18,a.z);var low_b=Vector3(b.x,GardenTerrain.point(b).y-.18,b.z)
   for v in [top_a,low_a,low_b,top_a,low_b,top_b]:
    base.set_uv(Vector2(v.x+v.z,v.y));base.add_vertex(v)
  for k in range(1,polygon.size()-1):
   for corner in [polygon[0],polygon[k],polygon[k+1]]:
    var p=Vector3(corner[0],0,corner[1])
    st.set_uv(Vector2(p.x,p.z));st.add_vertex(Vector3(p.x,trail_height(p),p.z))
 st.generate_normals();st.generate_tangents()
 var mesh=MeshInstance3D.new();mesh.name="Shared garden trail";mesh.mesh=st.commit()
 mesh.set_meta("editable_ground",true)
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 mesh.material_override=bluestone();root.add_child(mesh)
 base.generate_normals();base.generate_tangents();base.index()
 var footing=MeshInstance3D.new();footing.name="Trail stone foundation";footing.mesh=base.commit()
 var footing_mat=GardenBoundary.material();footing_mat.albedo_color=Color("777466")
 footing.material_override=footing_mat;footing.set_meta("editable_ground",true);root.add_child(footing)
 for j in range(5):
  var sign=g.Art.furnishing("sign");root.add_child(sign)
  sign.position=GardenTerrain.point(Vector3(69.7,0,6-j*24))+Vector3(0,.02,0)
  sign.rotation.y=-PI/2;sign.set_meta("terrain_anchor",true)
  g.Art.set_sign_text(sign,GardenAreaCatalogue.entry(j*2).name+"\n"+GardenAreaCatalogue.entry(j*2+1).name)
  GardenAreaMaterials.prepare(sign)
