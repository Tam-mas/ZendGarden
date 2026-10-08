class_name GardenExpansion
extends RefCounted

static func opening_day(index: int) -> int:
 return [1,7,18,36][index] if index<4 else 48+(index-4)*12

static func prepare(g) -> void:
 # Ten habitats have stable indices; legacy expansion rows keep their positions.
 while g.plots.size()<14:
  var index=g.plots.size()-4
  var info=GardenAreaCatalogue.entry(index)
  g.plots.append({"name":info.name,"subtitle":info.description,"center":GardenAreaCatalogue.center(index),"condition":info.condition,"cap":120,"cost":0})
 var target=maxi(4,g.unlocked_plots+2)
 if target%2:target+=1
 while g.plots.size()<target+10:
  var old=g.plots.size()-10
  g.plots.append({"name":["Meadow","Orchard","Wildflower","Woodland"][(old-4)%4]+" garden "+str(old+1),"subtitle":"A new corner to make your own","center":Vector3((old%2)*17,0,-int(old/2)*17),"condition":["sun","shade","any"][(old-4)%3],"cap":85,"cost":380+(old-3)*40})

static func build_row(g, index: int) -> void:
 if index*2+10>=g.plots.size():return
 var root=Node3D.new()
 root.name="GrowingRow%d" % index
 if g.world_root.has_node(NodePath(root.name)): root.free(); return
 g.world_root.add_child(root)
 var center_z=-index*17.0
 # A continuous rolling meadow and solid earth banks join the previous row.
 var grass=SurfaceTool.new()
 grass.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(34):
  for z in range(17):
   var a=Vector3(x-8.5,0,center_z+z-8.5)
   var b=a+Vector3.RIGHT
   var c=a+Vector3(1,0,1)
   var d=a+Vector3.BACK
   for v in [a,b,c,a,c,d]:
    grass.set_uv(Vector2(v.x,v.z)*.35)
    grass.add_vertex(GardenTerrain.point(v)-Vector3(0,.05,0))
 grass.generate_normals()
 grass.generate_tangents()
 var ground=MeshInstance3D.new()
 ground.mesh=grass.commit()
 ground.set_meta("editable_ground",true)
 var mat=StandardMaterial3D.new()
 mat.albedo_texture=load("res://assets/textures/Meadow_earth.webp")
 mat.roughness=1.0
 ground.material_override=GardenGroundFinish.material(false)
 root.add_child(ground)
 ground.create_trimesh_collision()
 for side in [-7.5,24.5]:
  var tree=g.Art.plant(g.catalogue[29 if index%2 else 31],true)
  tree.position=GardenTerrain.point(Vector3(side,0,center_z))
  root.add_child(tree)
 for i in range(index*2+10,index*2+12):
  var center: Vector3=g.plots[i].center
  var soil=SurfaceTool.new()
  soil.begin(Mesh.PRIMITIVE_TRIANGLES)
  for x in range(20):
   for z in range(20):
    var a=center+Vector3(-4.7+x*.47,0,-4.7+z*.47)
    for v in [a,a+Vector3(.47,0,0),a+Vector3(.47,0,.47),a,a+Vector3(.47,0,.47),a+Vector3(0,0,.47)]:
     soil.set_uv(Vector2(v.x,v.z)*.7)
     soil.add_vertex(GardenTerrain.point(v))
  soil.generate_normals()
  soil.generate_tangents()
  var bed=MeshInstance3D.new()
  bed.mesh=soil.commit()
  bed.set_meta("editable_ground",true)
  var loam=StandardMaterial3D.new()
  loam.albedo_texture=load("res://assets/textures/Garden_loam.webp")
  loam.roughness=1.0
  bed.material_override=GardenGroundFinish.material(true)
  root.add_child(bed)
  bed.create_trimesh_collision()
  for edge in range(20):
   for side in [-1,1]:
    var p=center+Vector3(-4.6+edge*.48,0,side*4.9)
    var stone=g.Art.ball(root,GardenTerrain.point(p),Vector3(.5,.18,.33),Color("a3a087"))
    stone.set_meta("terrain_anchor",true)
  if g.plot_signs.size()<=i:
   var sign=g.Art.sign_board()
   sign.set_meta("terrain_anchor",true)
   sign.position=GardenTerrain.point(center+Vector3(-3.4,0,5.2))
   root.add_child(sign)
   g.plot_signs.append(sign)

 if g.terrain_ready:
  GardenSculpt.scan(g,root)
  GardenBoundary.build(g)
