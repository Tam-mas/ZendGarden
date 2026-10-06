class_name GardenSculpt
extends RefCounted

# Source meshes remain immutable. Editable ground gets local copies and matching
# collision; offsets are shared with the ray, planting and walking height queries.
static func setup(g) -> void:
 g.terrain_meshes.clear()
 g.terrain_anchors.clear()
 scan(g,g.world_root)

static func scan(g,node: Node) -> void:
 if node is Node3D and node.get_meta("terrain_anchor",false):
  var p: Vector3=node.global_position
  p.y-=GardenTerrain.offset_at(p.x,p.z)
  g.terrain_anchors.append({"node":node,"base":p})
  if is_instance_valid(g.plant_batches):g.plant_batches.invalidate()
  return
 if node is MeshInstance3D and str(node.name)=="HilltopMeadow":
  split_meadow(g,node)
 elif node is MeshInstance3D and (str(node.name) in ["PlantableLoam","LimestonePathsAndWalls"] or node.get_meta("editable_ground",false)):
  register(g,node)
 for child in node.get_children():scan(g,child)

static func triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,ua: Vector2,ub: Vector2,uc: Vector2,depth: int) -> void:
 if depth>0:
  var ab=(a+b)*.5;var bc=(b+c)*.5;var ca=(c+a)*.5
  var uab=(ua+ub)*.5;var ubc=(ub+uc)*.5;var uca=(uc+ua)*.5
  triangle(st,a,ab,ca,ua,uab,uca,depth-1)
  triangle(st,ab,b,bc,uab,ub,ubc,depth-1)
  triangle(st,ca,bc,c,uca,ubc,uc,depth-1)
  triangle(st,ab,bc,ca,uab,ubc,uca,depth-1)
  return
 for pair in [[a,ua],[b,ub],[c,uc]]:
  st.set_uv(pair[1]);st.add_vertex(pair[0])

static func split_meadow(g,node: MeshInstance3D) -> void:
 var outside=ArrayMesh.new()
 var editable=ArrayMesh.new()
 var inverse=node.global_transform.affine_inverse()
 for surface in range(node.mesh.get_surface_count()):
  var arrays=node.mesh.surface_get_arrays(surface)
  var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
  var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
  var outer=SurfaceTool.new();outer.begin(Mesh.PRIMITIVE_TRIANGLES)
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  for i in range(0,indices.size(),3):
   var a=indices[i];var b=indices[i+1];var c=indices[i+2]
   var fragments=GardenConnectedLand.outside_meadow([[node.global_transform*verts[a],uv[a]],[node.global_transform*verts[b],uv[b]],[node.global_transform*verts[c],uv[c]]])
   for fragment in fragments:
    for j in range(1,fragment.size()-1):
     var p=fragment[0];var q=fragment[j];var r=fragment[j+1]
     var center=(p[0]+q[0]+r[0])/3
     var near=center.x>-12 and center.x<29 and center.z>-29 and center.z<12
     triangle(st if near else outer,inverse*p[0],inverse*q[0],inverse*r[0],p[1],q[1],r[1],2 if near else 0)
  outer.generate_normals();outer.generate_tangents();outer.index()
  outer.set_material(node.mesh.surface_get_material(surface));outer.commit(outside)
  st.generate_normals();st.generate_tangents();st.index()
  st.set_material(node.mesh.surface_get_material(surface));st.commit(editable)
 node.mesh=outside
 collision(node)
 var patch=MeshInstance3D.new()
 patch.name="SculptableMeadow"
 patch.mesh=editable
 patch.material_override=node.material_override
 node.get_parent().add_child(patch)
 patch.transform=node.transform
 register(g,patch)

static func register(g,node: MeshInstance3D,partition: bool=true) -> void:
 if node.get_meta("sculpt_registered",false):return
 node.set_meta("sculpt_registered",true)
 var count=0
 for surface in range(node.mesh.get_surface_count()):count+=node.mesh.surface_get_array_len(surface)
 if partition and count>3000:
  chunks(g,node)
  return
 var inverse=node.global_transform.affine_inverse()
 var base=ArrayMesh.new()
 for surface in range(node.mesh.get_surface_count()):
  var arrays=node.mesh.surface_get_arrays(surface)
  var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  for i in range(vertices.size()):
   var world=node.global_transform*vertices[i]
   world.y-=GardenTerrain.offset_at(world.x,world.z)
   vertices[i]=inverse*world
  arrays[Mesh.ARRAY_VERTEX]=vertices
  base.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  base.surface_set_material(surface,node.mesh.surface_get_material(surface))
 g.terrain_meshes.append({"node":node,"base":base})
 collision(node)

static func chunks(g,node: MeshInstance3D) -> void:
 # Only rebuild the nearby eight-metre tiles during a brush stroke.
 for surface in range(node.mesh.get_surface_count()):
  var arrays=node.mesh.surface_get_arrays(surface)
  var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
  var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
  var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
  var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
  if indices.is_empty():
   for i in range(verts.size()):indices.append(i)
  var tiles={}
  for i in range(0,indices.size(),3):
   var center=node.global_transform*((verts[indices[i]]+verts[indices[i+1]]+verts[indices[i+2]])/3)
   var key=Vector2i(floori(center.x/8),floori(center.z/8))
   if not tiles.has(key):
    var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tiles[key]=tool
   var st: SurfaceTool=tiles[key]
   for j in range(3):
    var id=indices[i+j]
    st.set_normal(normals[id]);st.set_uv(uv[id])
    if tangents.size()>id*4+3:st.set_tangent(Plane(Vector3(tangents[id*4],tangents[id*4+1],tangents[id*4+2]),tangents[id*4+3]))
    st.add_vertex(verts[id])
  for key in tiles:
   var st: SurfaceTool=tiles[key];st.index()
   # The shared paving has a prepared stone finish on its surface override.
   # Carry it into the chunks without changing other terrain material paths.
   st.set_material(node.get_active_material(surface) if node.get_meta("fitted_paving",false) else node.mesh.surface_get_material(surface))
   var patch=MeshInstance3D.new();patch.name="GroundTile_%d_%d"%[key.x,key.y]
   patch.mesh=st.commit();patch.material_override=node.material_override
   if node.has_meta("area_bed_plot"):patch.set_meta("area_bed_plot",node.get_meta("area_bed_plot"))
   node.get_parent().add_child(patch);patch.transform=node.transform
   register(g,patch,false)
 node.hide()
 for child in node.get_children():
  if child is StaticBody3D:node.remove_child(child);child.free()

static func collision(node: MeshInstance3D) -> void:
 for child in node.get_children():
  if child is StaticBody3D:
   node.remove_child(child);child.free()
 node.create_trimesh_collision()

static func restore(g,saved: Dictionary) -> void:
 var had_edits=not GardenTerrain.offsets.is_empty()
 GardenTerrain.offsets.clear()
 for key in saved:
  var parts=str(key).split(":")
  if parts.size()!=2 or not str(parts[0]).is_valid_int() or not str(parts[1]).is_valid_int():continue
  var x=int(parts[0]);var z=int(parts[1]);var value=float(saved[key])
  var legacy=x>= -10 and x<=27 and z<=11 and z>=-(GardenAreaCatalogue.legacy_plot_count(g)/2)*17-12
  var habitat=GardenAreaCatalogue.index_at(Vector3(x,0,z))>=0
  var connection=GardenConnectedLand.contains(Vector3(x,0,z))
  if (not legacy and not habitat and not connection) or not is_finite(value):continue
  GardenTerrain.offsets[str(key)]=clampf(value,maxf(-3.0,.08-GardenTerrain.base_rise(x,z)),3.0)
 if had_edits or not GardenTerrain.offsets.is_empty():rebuild(g)

static func allowed(g,p: Vector3) -> bool:
 if not g.plantable_ground(p) or not GardenAreaCatalogue.plot_open(g,g.nearest_plot(p)) or not GardenAreas.can_sculpt(p):return false
 # Keep water crossings and fixed masonry foundations intact, including the
 # interpolation apron surrounding each edited lattice point.
 if p.x>5.3 and p.x<11.7 and p.z>-8.3 and p.z<8.3:return false
 if p.z>-11.3 and p.z<-5.7 and p.x>9 and p.x<25:return false
 if absf(p.x+7.4)<3.1 and absf(p.z+18)<3.1:return false
 if absf(p.z+24.5)<1.7:return false
 for obj in g.objects:
  var radius=float({"greenhouse":3.8,"pergola":2.4,"arbor":1.7,"pond":2.1,"bench":1.6}.get(obj.kind,1.0))
  if Vector2(p.x-obj.pos.x,p.z-obj.pos.z).length()<radius+1.0:return false
 return true

static func apply_hoe(g) -> void:
 var center: Vector3=g.hover_cell
 if not allowed(g,center):
  g.toast("Use the hoe on unlocked dry ground, away from water, bridges and structures.");return
 var changed=false
 for x in range(floori(center.x-1.5),ceili(center.x+1.5)+1):
  for z in range(floori(center.z-1.5),ceili(center.z+1.5)+1):
   var p=Vector3(x,0,z)
   var distance=Vector2(x-center.x,z-center.z).length()
   if distance>1.5 or not allowed(g,p):continue
   var key="%d:%d"%[x,z]
   var old=float(GardenTerrain.offsets.get(key,0.0))
   var amount=.16*(1.0-smoothstep(.6,1.5,distance))*(1 if g.hoe_raise else -1)
   var value=clampf(old+amount,maxf(-3.0,.08-GardenTerrain.base_rise(x,z)),3.0)
   if absf(value-old)<.0001:continue
   if absf(value)<.0001:GardenTerrain.offsets.erase(key)
   else:GardenTerrain.offsets[key]=value
   changed=true
 if not changed:g.toast("This ground has reached its height limit.");return
 rebuild(g,center)
 g.action_cooldown=.35
 g.care_effect(GardenTerrain.point(center),Color("ae9270"))
 g.toast(("Raised" if g.hoe_raise else "Lowered")+" ground · R switches direction. Hold to keep shaping.")

static func rebuild(g,center: Vector3=Vector3.INF) -> void:
 g.terrain_revision+=1
 g.plant_index.invalidate()
 if is_instance_valid(g.plant_batches):g.plant_batches.invalidate()
 for entry in g.terrain_meshes:
  var node: MeshInstance3D=entry.node
  var bounds: AABB=node.global_transform*entry.base.get_aabb()
  if center.is_finite() and (center.x<bounds.position.x-3 or center.x>bounds.end.x+3 or center.z<bounds.position.z-3 or center.z>bounds.end.z+3):continue
  var inverse=node.global_transform.affine_inverse()
  var revised=ArrayMesh.new()
  for surface in range(entry.base.get_surface_count()):
   var arrays=entry.base.surface_get_arrays(surface)
   var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
   for i in range(vertices.size()):
    var p=node.global_transform*vertices[i]
    p.y+=GardenTerrain.offset_at(p.x,p.z)
    vertices[i]=inverse*p
   arrays[Mesh.ARRAY_VERTEX]=vertices
   var temporary=ArrayMesh.new();temporary.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   var st=SurfaceTool.new();st.create_from(temporary,0);st.generate_normals();st.generate_tangents()
   st.set_material(entry.base.surface_get_material(surface));st.commit(revised)
  node.mesh=revised
  collision(node)
 for anchor in g.terrain_anchors:
  if center.is_finite() and Vector2(anchor.base.x-center.x,anchor.base.z-center.z).length()>3:continue
  if is_instance_valid(anchor.node):anchor.node.global_position=anchor.base+Vector3(0,GardenTerrain.offset_at(anchor.base.x,anchor.base.z),0)
 for plant in g.wild_plants:plant.pos=plant.node.position
 for plant in g.planted:
  if GardenContainers.is_contained(plant):continue
  if center.is_finite() and Vector2(plant.pos.x-center.x,plant.pos.z-center.z).length()>3:continue
  plant.pos=GardenTerrain.point(plant.pos);plant.node.position=plant.pos;plant.marker.position=plant.pos
 var grass=g.world_root.get_node_or_null("MeadowGrass")
 if grass:
  for i in range(grass.multimesh.instance_count):
   var transform=grass.multimesh.get_instance_transform(i)
   if center.is_finite() and Vector2(transform.origin.x-center.x,transform.origin.z-center.z).length()>3:continue
   transform.origin.y=GardenConnectedLand.surface(transform.origin).y if GardenConnectedLand.contains(transform.origin) else GardenTerrain.point(transform.origin).y-.02
   grass.multimesh.set_instance_transform(i,transform)
 for key in g.clean_paths:
  var parts=key.split(":")
  var pos=Vector3(float(parts[0]),0,float(parts[1]))
  var width=float(g.path_widths.get(key,.95))
  if center.is_finite() and Vector2(pos.x-center.x,pos.z-center.z).length()>3+width:continue
  GardenGroundFinish.path(g,pos,width)
 for key in g.watered_ground:
  var patch=g.watered_ground[key]
  if center.is_finite() and Vector2(patch.x-center.x,patch.z-center.z).length()>3+patch.radius:continue
  GardenTools.water_patch(g,key)
 if is_instance_valid(g.player):g.player.position.y=maxf(g.player.position.y,GardenTerrain.point(g.player.position).y+.12)
 for entry in g.wildlife:
  if not entry.get("hive",false):entry.target=GardenTerrain.point(entry.target)
 for habitat in g.area_roots:GardenAreaFlora.refresh(habitat)
 GardenBedSurfaces.rebuild(g,center)
 GardenContainers.sync(g)
 GardenClimbingSupport.refresh(g)
