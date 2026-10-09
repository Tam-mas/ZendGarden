class_name GardenLandscape
extends RefCounted
const Art=preload("res://scripts/garden_art.gd")

static func build(g) -> void:
 var scene=load("res://assets/environment/lake_garden.glb").instantiate()
 g.world_root.add_child(scene)
 recede_landscape(scene)
 # Real three-dimensional lake continues down the modelled valley.
 # The exported lake follows the mountain basin contour on every shore.
 water(g,Vector3(8.5,-0.03,0),Vector2(3.3,14),false)
 water(g,Vector3(17,-0.03,-8.5),Vector2(14,2.8),false)
 # Retain original accessible bridge routes and bed coordinates for saved gardens.
 g.make_bridge(Vector3(8.5,0,5.9),false)
 g.make_bridge(Vector3(17,0,-8.5),true)
 # Collision follows the exported rolling meadow and subdivided loam.
 for name in ["HilltopMeadow","PlantableLoam","LimestonePathsAndWalls"]:
  var ground_mesh=scene.find_child(name,true,false)
  if ground_mesh: ground_mesh.create_trimesh_collision()
 var r=RandomNumberGenerator.new()
 r.seed=309
 # Varied canopy silhouettes frame the vista; the centre remains open to the lake.
 var tree_positions=[Vector3(-9,0,1),Vector3(-10,0,-10),Vector3(-8,0,-23),Vector3(24.1,0,3.4),Vector3(25,0,-14),Vector3(22,0,-24),Vector3(13,0,-25),Vector3(-12,0,8)]
 for i in range(tree_positions.size()):
  var species=[29,31,30,45,32,29,33,31][i]
  var tree=Art.plant(g.catalogue[species],true)
  tree.position=GardenTerrain.point(tree_positions[i])
  tree.scale=Vector3.ONE*r.randf_range(.9,1.25)
  g.world_root.add_child(tree)
  trunk_collision(tree,.18,2.0)
 # Permanent border planting adds rich ground-level habitat without using player capacity.
 for j in range(128):
  var p=Vector3(r.randf_range(-11,28),0.04,r.randf_range(-26,8))
  if GardenConnectedLand.on_trail(p):continue
  if g.bed_at(p)>=0: continue
  if p.x>6.2 and p.x<10.8 and p.z>-7.2 and p.z<7: continue
  if p.z>-10.5 and p.z<-6.7 and p.x>10: continue
  var path=false
  for plot in g.plots:
   if abs(p.z-plot.center.z-6)<.8: path=true
  if abs(p.x+6)<.85: path=true
  if path: continue
  var id=[20,1,2,3,14,15,21,26,36,37,44,12][j%12]
  var plant=Art.plant(g.catalogue[id],true)
  plant.position=GardenTerrain.point(p)
  plant.rotation.y=r.randf()*TAU
  plant.scale=Vector3.ONE*r.randf_range(.75,1.3)
  g.world_root.add_child(plant)
  GardenCare.register_wild(g,plant,"border:%d" % j,id)
 for plot in g.plots:
  if g.plots.find(plot)>=4 and g.plots.find(plot)<14:continue
  for j in range(24):
   var side=-1.0 if j%2==0 else 1.0
   var p=plot.center+Vector3(-4.2+float(j/2)*.72,0.04,side*5.25)
   var id=[1,2,20,37,14,0][j%6]
   var border=Art.plant(g.catalogue[id],true)
   border.position=GardenTerrain.point(p)
   border.scale=Vector3.ONE*r.randf_range(.7,1.05)
   g.world_root.add_child(border)
   GardenCare.register_wild(g,border,"edge:%d:%d" % [g.plots.find(plot),j],id)
 # Bed names belong on small physical labels, not floating across the horizon.
 for i in range(g.plots.size()):
  if i>=4 and i<14:g.plot_signs.append(null);continue
  var plot=g.plots[i]
  var sign=Art.sign_board()
  sign.set_meta("terrain_anchor",true)
  sign.position=GardenTerrain.point(plot.center+Vector3(-4.1,0,5.15))
  g.world_root.add_child(sign)
  g.plot_signs.append(sign)
 # Small collision box for the permanent pavilion.
 var wall=StaticBody3D.new()
 var collider=CollisionShape3D.new()
 var bounds=BoxShape3D.new()
 bounds.size=Vector3(3.2,3,3)
 collider.shape=bounds
 collider.position=GardenTerrain.point(Vector3(-7.4,0,-18))+Vector3(0,1.5,0)
 wall.add_child(collider)
 g.world_root.add_child(wall)
 meadow(g)

static func trunk_collision(parent: Node3D, radius: float, height: float) -> void:
 var body=StaticBody3D.new()
 body.set_meta("planting_obstacle",true)
 var collision=CollisionShape3D.new()
 var shape=CylinderShape3D.new()
 shape.radius=radius
 shape.height=height
 collision.shape=shape
 collision.position.y=height*.5
 body.add_child(collision)
 parent.add_child(body)

static func water(g,position: Vector3,size: Vector2,lake: bool) -> void:
 var mesh=MeshInstance3D.new()
 var plane=PlaneMesh.new()
 plane.size=size
 plane.subdivide_width=12;plane.subdivide_depth=40
 mesh.mesh=plane
 mesh.position=position
 var material=ShaderMaterial.new()
 material.shader=load("res://shaders/lake.gdshader")
 if lake:
  material.set_shader_parameter("deep_color",Color("416d80"))
  material.set_shader_parameter("edge_color",Color("91adb3"))
 mesh.material_override=material
 g.world_root.add_child(mesh)
 material.set_shader_parameter("wave_height",.012)
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 GardenWater.register(mesh,{"kind":"plane","size":size})

static func meadow(g) -> void:
 var r=RandomNumberGenerator.new()
 r.seed=913
 var st=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 # Curved blade clusters, not upright triangular spikes.
 for j in range(7):
  var angle=j*2.39996
  var start=Vector3(cos(angle)*.06,0,sin(angle)*.06)
  var side=Vector3(cos(angle),0,sin(angle))*.009
  var tip=start+Vector3(cos(angle)*.065,.14+j*.009,sin(angle)*.065)
  var mid=start.lerp(tip,.55)+Vector3(0,.025,0)
  for v in [start-side,mid-side,mid+side,start-side,mid+side,start+side,mid-side,tip,mid+side]: st.add_vertex(v)
 st.generate_normals()
 var positions: Array=[]
 for j in range(16000):
  var p=Vector3(r.randf_range(-13,30),.04,r.randf_range(-25.5,10))
  if GardenConnectedLand.contains(p) and not GardenRavine.grass_allowed(p):continue
  if GardenConnectedLand.on_trail(p):continue
  if g.bed_at(p)>=0: continue
  if p.x>6.5 and p.x<10.5 and p.z>-7 and p.z<7: continue
  if p.z>-10 and p.z<-7 and p.x>10 and p.x<24: continue
  var path=false
  for plot in g.plots:
   if abs(p.z-plot.center.z-6)<.72: path=true
  if abs(p.x+6)<.65: path=true
  p.y=GardenConnectedLand.surface(p).y if GardenConnectedLand.contains(p) else GardenTerrain.point(p).y-.02
  positions.append({"pos":p,"short":path})
 var original=positions
 positions=[]
 # Match the meadow's density and mixed heights, without double-scattering
 # over the part already covered by the original lawn.
 for j in range(22000):
  var p=Vector3(r.randf_range(25.7,43.8),0,r.randf_range(-107.8,9))
  if p.x<30 and p.z> -25.5:continue
  if GardenConnectedLand.contains(p) and not GardenRavine.grass_allowed(p):continue
  p=GardenConnectedLand.surface(p)
  positions.append({"pos":p,"short":false})
 var blade_mesh=st.commit()
 var mat=StandardMaterial3D.new()
 mat.vertex_color_use_as_albedo=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mat.roughness=1;mat.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
 grass_chunk(g,"MeadowGrass",original,blade_mesh,mat,r)
 # Small culling cells keep the longer grass inexpensive as the land grows.
 var chunks: Dictionary={}
 for entry in positions:
  var key=Vector2i(floori(entry.pos.x/8),floori(entry.pos.z/8))
  if not chunks.has(key):chunks[key]=[]
  chunks[key].append(entry)
 for key in chunks:
  grass_chunk(g,"JoiningGrass_%d_%d"%[key.x,key.y],chunks[key],blade_mesh,mat,r)

static func grass_chunk(g,title: String,positions: Array,blade_mesh: Mesh,mat: Material,r: RandomNumberGenerator) -> void:
 var mm=MultiMesh.new()
 mm.transform_format=MultiMesh.TRANSFORM_3D
 mm.use_colors=true
 mm.mesh=blade_mesh
 mm.instance_count=positions.size()
 for i in range(positions.size()):
  var entry=positions[i]
  var patch=(sin(entry.pos.x*.65)+cos(entry.pos.z*.51))*.5
  var height_scale=r.randf_range(.25,.5) if entry.short else (r.randf_range(2.0,4.2) if patch>.25 else r.randf_range(.7,1.6))
  mm.set_instance_transform(i,Transform3D(Basis(Vector3.UP,r.randf()*TAU).scaled(Vector3(1,height_scale,1)),entry.pos))
  mm.set_instance_color(i,Color("4e6b30").lerp(Color("81954b"),r.randf()))
 var n=MultiMeshInstance3D.new()
 n.name=title
 n.multimesh=mm
 n.material_override=mat
 n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 if title!="MeadowGrass":n.visibility_range_end=65
 g.world_root.add_child(n)
 n.add_to_group("meadow_grass")

static func recede_landscape(node: Node) -> void:
 if node is MeshInstance3D and str(node.name) in ["HilltopMeadow","PlantableLoam"]:
  node.material_override=GardenGroundFinish.material(str(node.name)=="PlantableLoam")
 if node is MeshInstance3D and str(node.name)=="LimestonePathsAndWalls":
  # Replace the entire old rear fence with the continuous, growing perimeter.
  # This also clears its last stones out of the new west-bank trail.
  var opened=ArrayMesh.new()
  for surface in range(node.mesh.get_surface_count()):
   var arrays=node.mesh.surface_get_arrays(surface)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
   var kept=PackedInt32Array()
   for i in range(0,indices.size(),3):
    var center=(vertices[indices[i]]+vertices[indices[i+1]]+vertices[indices[i+2]])/3
    if absf(center.z+24.5)<.65: continue
    kept.append_array(indices.slice(i,i+3))
   arrays[Mesh.ARRAY_INDEX]=kept
   opened.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   opened.surface_set_material(surface,node.mesh.surface_get_material(surface))
  node.mesh=opened
 if node is MeshInstance3D and str(node.name)=="HilltopMeadow":
  # Keep the playable plateau fixed; carry the outer slope below the lake surface.
  var original: Mesh=node.mesh
  var lowered=ArrayMesh.new()
  for surface in range(original.get_surface_count()):
   var arrays=original.surface_get_arrays(surface)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
   for i in range(vertices.size()):
    if vertices[i].y<-.05 and (vertices[i].x < -17 or vertices[i].x > 33 or vertices[i].z < -26 or vertices[i].z > 10):
     vertices[i].y*=2.1
     if normals.size()==vertices.size():
      normals[i].y/=2.1
      normals[i]=normals[i].normalized()
   arrays[Mesh.ARRAY_VERTEX]=vertices
   arrays[Mesh.ARRAY_NORMAL]=normals
   lowered.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   lowered.surface_set_material(surface,original.surface_get_material(surface))
  node.mesh=lowered
 if node is Node3D and str(node.name) in ["AlpineLakeValley","ForestedMountainSlopes","DistantLakesideHamlets","ContourLake","ShorelineRocks","OuterMountainRidges"]:
  node.scale=Vector3(3.0,1.6,3.0)
 if node is MeshInstance3D and str(node.name) in ["AlpineLakeValley","OuterMountainRidges"]:
  var material=ShaderMaterial.new()
  material.shader=load("res://shaders/mountain.gdshader")
  material.set_shader_parameter("strata",load("res://assets/textures/Mountain_strata.webp"))
  material.set_shader_parameter("rock_normal",load("res://assets/textures/Mountain_strata_normal.webp"))
  node.material_override=material
 if node is MeshInstance3D and str(node.name)=="ContourLake":
  var material=ShaderMaterial.new()
  material.shader=load("res://shaders/lake.gdshader")
  material.set_shader_parameter("deep_color",Color("416d80"))
  material.set_shader_parameter("edge_color",Color("91adb3"))
  node.material_override=material
  node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  GardenWater.subdivide_lake(node)
  GardenWater.register(node,{"kind":"lake"})
 if node is MeshInstance3D and str(node.name).begins_with("ForestChunk_"):
  node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  # Small sections retain woodland coverage while reducing distant geometry.
  node.lod_bias=.5
  # Use restrained foliage colours instead of the bright imported canopy palette.
  var shades=[Color("30452f"),Color("3b5135"),Color("506047")]
  for surface in range(node.mesh.get_surface_count()):
   node.set_surface_override_material(surface,Art.mat(shades[surface%shades.size()],1.0))
 for child in node.get_children(): recede_landscape(child)
