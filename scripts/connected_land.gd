class_name GardenConnectedLand
extends RefCounted

# Join the gardens in place: saved plants, furniture and plot centres retain
# their coordinates. The half-metre grid also carries saved hoe offsets.
const WEST=25.5
const EAST=44.0
const NORTH=-108.0
const SOUTH=12.0

static func contains(pos: Vector3) -> bool:
 return pos.x>=WEST and pos.x<=EAST and pos.z>=NORTH and pos.z<=SOUTH

static func on_trail(pos: Vector3) -> bool:
 return pos.x>=25 and pos.x<=EAST and pos.z>=4.5 and pos.z<=7.5

static func surface(pos: Vector3) -> Vector3:
 # Match the original meadow's 2 cm reveal and the habitats' 3.5 cm reveal.
 return GardenTerrain.point(pos)-Vector3.UP*lerpf(.05,.035,smoothstep(WEST,EAST,pos.x))

static func build(g) -> void:
 var root=Node3D.new();root.name="ConnectedGardenLand";g.world_root.add_child(root)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(37):
  for z in range(240):
   var a=Vector3(WEST+x*.5,0,NORTH+z*.5)
   for p in [a,a+Vector3(.5,0,0),a+Vector3(.5,0,.5),a,a+Vector3(.5,0,.5),a+Vector3(0,0,.5)]:
    st.set_uv(Vector2(p.x,p.z));st.add_vertex(surface(p))
 st.generate_normals();st.generate_tangents();st.index()
 var meadow=MeshInstance3D.new();meadow.name="JoiningMeadow";meadow.mesh=st.commit()
 meadow.set_meta("editable_ground",true)
 var mat=ShaderMaterial.new();mat.shader=load("res://shaders/connected_ground.gdshader")
 mat.set_shader_parameter("earth",load("res://assets/textures/Meadow_earth.webp"))
 mat.set_shader_parameter("relief",load("res://assets/textures/Meadow_earth_normal.webp"))
 meadow.material_override=mat;root.add_child(meadow)

static func trim_habitat_bank(node: MeshInstance3D) -> bool:
 # Former western island faces now lie inside the joined land. Remove these
 # faces from the mesh itself, so sculpting cannot reveal a buried cliff.
 var joined=ArrayMesh.new()
 var changed=false
 for surface_index in range(node.mesh.get_surface_count()):
  var arrays=node.mesh.surface_get_arrays(surface_index)
  var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
  var kept=PackedInt32Array()
  for i in range(0,indices.size(),3):
   var a=node.global_transform*vertices[indices[i]]
   var b=node.global_transform*vertices[indices[i+1]]
   var c=node.global_transform*vertices[indices[i+2]]
   if absf(a.x-EAST)<.001 and absf(b.x-EAST)<.001 and absf(c.x-EAST)<.001:
    changed=true;continue
   kept.append_array(indices.slice(i,i+3))
  if kept.is_empty():continue
  arrays[Mesh.ARRAY_INDEX]=kept
  joined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  joined.surface_set_material(joined.get_surface_count()-1,node.mesh.surface_get_material(surface_index))
 if not changed:return true
 if joined.get_surface_count()>0:
  node.mesh=joined;return true
 node.get_parent().remove_child(node);node.queue_free()
 return false

static func outside_meadow(points: Array) -> Array:
 # Subtract the joined extension with exact cuts. Centroid filtering left
 # long triangles sticking into the lawn and overlapping the new surface.
 var fragments=[]
 for edge in [[0,WEST,1.],[2,NORTH,1.],[2,SOUTH,-1.]]:
  var inside=[];var outside=[]
  for i in range(points.size()):
   var a: Array=points[i];var b: Array=points[(i+1)%points.size()]
   var da=(a[0][edge[0]]-edge[1])*edge[2]
   var db=(b[0][edge[0]]-edge[1])*edge[2]
   if da>=0:inside.append(a)
   else:outside.append(a)
   if (da>=0)!=(db>=0):
    var t=da/(da-db)
    var cut=[a[0].lerp(b[0],t),a[1].lerp(b[1],t)]
    inside.append(cut);outside.append(cut)
  if outside.size()>=3:fragments.append(outside)
  points=inside
  if points.size()<3:break
 return fragments
