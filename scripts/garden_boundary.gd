class_name GardenBoundary
extends RefCounted

# The two garden rims include the banks; only the three bridge mouths interrupt
# the river-facing walls. The legacy outline grows with the existing plot rows.
static func outlines(g) -> Array:
 var north=-float(GardenAreaCatalogue.legacy_plot_count(g)/2-1)*17.-8.5
 var west=[Vector2(-11.5,10),Vector2(25.5,10),Vector2(25.5,12),Vector2(28.6,12),Vector2(28.6,-108)]
 west.append_array([Vector2(25.5,-108),Vector2(25.5,north)])
 if north< -25.5:west.append_array([Vector2(-8.5,north),Vector2(-8.5,-25.5)])
 west.append_array([Vector2(-11.5,-25.5)])
 return [west,[Vector2(41.1,12),Vector2(92,12),Vector2(92,-108),Vector2(41.1,-108)]]

static func segments(g) -> Array:
 var result=[]
 for outline in outlines(g):
  for j in range(outline.size()):
   var a: Vector2=outline[j];var b: Vector2=outline[(j+1)%outline.size()]
   if absf(a.x-b.x)<.001 and (absf(a.x-28.6)<.001 or absf(a.x-41.1)<.001):
    var lo=minf(a.y,b.y);var hi=maxf(a.y,b.y)
    for z in [-102.,-48.,6.]:
     result.append([Vector2(a.x,lo),Vector2(a.x,z-1.9)])
     lo=z+1.9
    result.append([Vector2(a.x,lo),Vector2(a.x,hi)])
   else:result.append([a,b])
 return result

static func ground(p: Vector2) -> float:
 # Sample the supported side of the rim, including coping overhangs. Outside
 # the habitat rectangle the terrain query intentionally returns legacy hills.
 if p.x>40.7:p=Vector2(minf(p.x,91.999),clampf(p.y,-107.999,11.999))
 elif p.x>=25.5:p.y=clampf(p.y,-108.,12.)
 return GardenTerrain.point(Vector3(p.x,0,p.y)).y-.045

static func material() -> StandardMaterial3D:
 var mat=StandardMaterial3D.new()
 mat.albedo_texture=load("res://assets/textures/garden-path/split-sandstone.webp")
 mat.normal_enabled=true;mat.normal_texture=load("res://assets/textures/garden-path/split-sandstone-normal.webp")
 mat.normal_scale=.45;mat.roughness=.96;mat.vertex_color_use_as_albedo=true
 return mat

static func face(st: SurfaceTool,points: Array,uv_axis: int) -> void:
 for j in range(1,points.size()-1):
  for p in [points[0],points[j],points[j+1]]:
   st.set_uv(Vector2(p.x if uv_axis!=0 else p.z,p.y if uv_axis!=1 else p.z)*1.2)
   st.add_vertex(p)

static func stone(st: SurfaceTool,a: Vector2,b: Vector2,bottom: float,height: float,width: float,seed: int) -> void:
 var d=(b-a).normalized();var side=Vector2(-d.y,d.x)*width*.5
 # Chamfered, slightly varied fieldstones have closed sides and bed into a
 # continuous foundation. Each course follows the land, including saved edits.
 var rings=[]
 for layer in [[0.,.91],[.024,1.],[height-.024,1.],[height,.91]]:
  var end=d*(1.-layer[1])*.09
  var corners=[a+end-side*layer[1],b-end-side*layer[1],b-end+side*layer[1],a+end+side*layer[1]]
  var ring=[]
  for p in corners:ring.append(Vector3(p.x,ground(p)+bottom+layer[0],p.y))
  rings.append(ring)
 st.set_color(Color("d3cdbb").lerp(Color("a39e8e"),float(posmod(seed*73,101))/101.))
 face(st,[rings[0][3],rings[0][2],rings[0][1],rings[0][0]],1)
 face(st,rings[3],1)
 for level in range(3):
  for j in range(4):
   var next=(j+1)%4
   face(st,[rings[level][j],rings[level][next],rings[level+1][next],rings[level+1][j]],0 if absf(d.y)>absf(d.x) else 2)

static func build(g) -> void:
 var old=g.world_root.get_node_or_null("GardenBoundary")
 if old:
  g.terrain_meshes=g.terrain_meshes.filter(func(e):return is_instance_valid(e.node) and not old.is_ancestor_of(e.node))
  g.world_root.remove_child(old);old.free()
 var root=Node3D.new();root.name="GardenBoundary";g.world_root.add_child(root)
 legacy_foundation(g,root)
 var mat=material();var number=0
 for segment in segments(g):
  var a: Vector2=segment[0];var b: Vector2=segment[1];var length=a.distance_to(b)
  var chunks=ceili(length/8.)
  for chunk in range(chunks):
   var start=a.lerp(b,float(chunk)/chunks);var finish=a.lerp(b,float(chunk+1)/chunks)
   var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
   stone(st,start,finish,-.30,1.08,.39,number)
   for course in range(4):
    var pitch=.82 if course<3 else .68
    var count=ceili(start.distance_to(finish)/pitch)
    var step=start.distance_to(finish)/count;var shift=step*.5 if course%2 else 0.
    for i in range(-1,count):
     var lo=maxf(0.,i*step+shift);var hi=minf(start.distance_to(finish),(i+1)*step+shift)
     if hi-lo<.03:continue
     var axis=(finish-start).normalized()
     stone(st,start+axis*(lo+.004),start+axis*(hi-.004),.02+course*.225,.214 if course<3 else .145,.53 if course<3 else .61,number+course*29+i)
   st.generate_normals();st.generate_tangents();st.index()
   var mesh=MeshInstance3D.new();mesh.name="BoundaryStone%d"%number;mesh.mesh=st.commit();mesh.material_override=mat
   mesh.set_meta("editable_ground",true);root.add_child(mesh)
   # Closed foundations and coping remain a physical garden edge.
   mesh.create_trimesh_collision()
   for child in mesh.get_children():child.set_meta("planting_obstacle",true)
   number+=1
 if g.terrain_ready:GardenSculpt.scan(g,root)

static func legacy_foundation(g,root: Node3D) -> void:
 var north=-float(GardenAreaCatalogue.legacy_plot_count(g)/2-1)*17.-8.5
 if north>=-25.5:return
 var edges=[[Vector2(-8.5,-25.5),Vector2(-8.5,north)],[Vector2(-8.5,north),Vector2(25.5,north)]]
 if north< -108.:edges.append([Vector2(25.5,north),Vector2(25.5,-108.)])
 var mat=ShaderMaterial.new();mat.shader=load("res://shaders/mountain.gdshader")
 mat.set_shader_parameter("rock_scale",.38)
 mat.set_shader_parameter("strata",load("res://assets/textures/Mountain_strata.webp"))
 mat.set_shader_parameter("rock_normal",load("res://assets/textures/Mountain_strata_normal.webp"))
 for index in range(edges.size()):
  var a: Vector2=edges[index][0];var b: Vector2=edges[index][1]
  var count=ceili(a.distance_to(b)*2.)
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for j in range(count):
   var p=a.lerp(b,float(j)/count);var q=a.lerp(b,float(j+1)/count)
   var top_a=Vector3(p.x,ground(p)-.005,p.y);var top_b=Vector3(q.x,ground(q)-.005,q.y)
   var low_a=Vector3(p.x,-66.,p.y);var low_b=Vector3(q.x,-66.,q.y)
   face(st,[top_a,low_a,low_b,top_b],0 if index!=1 else 2)
  st.generate_normals();st.generate_tangents();st.index()
  var mesh=MeshInstance3D.new();mesh.name="GrowingGardenRock%d"%index;mesh.mesh=st.commit();mesh.material_override=mat
  mesh.set_meta("editable_ground",true);root.add_child(mesh);mesh.create_trimesh_collision()
