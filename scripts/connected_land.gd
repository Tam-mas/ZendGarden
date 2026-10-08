class_name GardenConnectedLand
extends RefCounted

# Fixed garden coordinates flank a carved stream valley and three stone crossings.
const WEST=25.5
const EAST=44.0
const NORTH=-108.0
const SOUTH=12.0

static func contains(pos: Vector3) -> bool:
 return pos.x>=WEST and pos.x<=EAST and pos.z>=NORTH and pos.z<=SOUTH

static func on_trail(pos: Vector3) -> bool:
 return (pos.x>=22.9 and pos.x<25.5 and absf(pos.z-6.)<1.55) or (contains(pos) and (absf(pos.x-27.)<1.05 or GardenRavine.bridge_at(pos,1.9)>=0))

static func surface(pos: Vector3) -> Vector3:
 return Vector3(pos.x,GardenRavine.ground(pos.x,pos.z),pos.z)

static func build(g) -> void:
 var root=Node3D.new();root.name="ConnectedGardenLand";g.world_root.add_child(root)
 # Separate reaches keep collision and rendering bounds local to the camera.
 for reach in range(10):
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for x in range(74):
   for z in range(48):
    var a=Vector3(WEST+x*.25,0,NORTH+reach*12.+z*.25)
    for p in [a,a+Vector3(.25,0,0),a+Vector3(.25,0,.25),a,a+Vector3(.25,0,.25),a+Vector3(0,0,.25)]:
     st.set_uv(Vector2(p.x,p.z));st.add_vertex(surface(p))
  st.generate_normals();st.generate_tangents();st.index()
  var bank=MeshInstance3D.new();bank.name="RavineBank%d"%reach;bank.mesh=st.commit()
  var mat=ShaderMaterial.new();mat.shader=load("res://shaders/connected_ground.gdshader")
  mat.set_shader_parameter("earth",load("res://assets/textures/Meadow_earth.webp"))
  mat.set_shader_parameter("relief",load("res://assets/textures/Meadow_earth_normal.webp"))
  mat.set_shader_parameter("rock",load("res://assets/textures/garden-path/split-sandstone.webp"))
  mat.set_shader_parameter("rock_normal",load("res://assets/textures/garden-path/split-sandstone-normal.webp"))
  bank.material_override=mat;root.add_child(bank);bank.create_trimesh_collision()
 GardenRavine.build(g,root)

static func trim_habitat_bank(node: MeshInstance3D) -> bool:
 # Shallow island skirts are replaced by the complete rock foundation.
 # Remove both old side sheets instead of leaving overlapping stone faces.
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
   if (absf(a.x-EAST)<.001 and absf(b.x-EAST)<.001 and absf(c.x-EAST)<.001) or (absf(a.x-92.)<.001 and absf(b.x-92.)<.001 and absf(c.x-92.)<.001):
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
 for edge in [[0,WEST,1.]]:
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
