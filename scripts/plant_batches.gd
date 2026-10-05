class_name GardenPlantBatches
extends Node3D

# Preserve the original models and per-plant nodes for care and selection. Only
# rendering is grouped, in small world cells so off-screen beds can be culled.
const MIN_PLANTS=180
const CELL_SIZE=6.0
var garden
var active=false
var dirty=true
var last_count=-1
var members: Dictionary={}
var hidden: Dictionary={}
var meshes: Dictionary={}
var tweening: Dictionary={}
var selected: Node3D
var borders: Array=[]
var detail_timer=0.0

func setup(g) -> void:
 garden=g
 active=g.loaded_data.get("plants",[]).size()>=MIN_PLANTS
 for anchor in g.terrain_anchors:
  if is_instance_valid(anchor.node) and anchor.node.has_node("MatureFoliage"):borders.append(anchor.node)

func invalidate() -> void:
 dirty=true

func restore(node: Node3D) -> void:
 if not is_instance_valid(node): return
 for mesh_node in hidden.get(node.get_instance_id(),[]):
  if is_instance_valid(mesh_node): mesh_node.visible=true
 hidden.erase(node.get_instance_id())

func changing(p: Dictionary) -> void:
 if not active: return
 var previous=float(p.node.get_meta("growth_fraction",-1.0))
 var next=clampf(float(p.age)/float(garden.catalogue[p.id].days),0,1)
 if previous<0 or stage_key(previous)!=stage_key(next):
  restore(p.node)
  dirty=true
 elif int(p.id) in GardenPlantGrowth.FRUIT_TREES and fruit_size_key(previous)!=fruit_size_key(next):
  # Local fruit growth selects a shared size material; refresh its batch group.
  restore(p.node)
  dirty=true
 tweening[p.node.get_instance_id()]=p

func stage_key(fraction: float) -> int:
 return 0 if fraction<.20 else 1 if fraction<.52 else 2 if fraction<.78 else 3

func fruit_size_key(fraction: float) -> int:
 if fraction<.52:return 0
 var size=lerpf(.65,1.0,clampf((fraction-.52)/.26,0,1)) if fraction<.78 else lerpf(.48,1.0,clampf((fraction-.78)/.22,0,1))
 return roundi(size*32.0)

func _process(delta: float) -> void:
 if not active and garden.planted.size()>=MIN_PLANTS:
  active=true
  for p in garden.planted:
   p.node.set_meta("batch_shape",true)
   GardenArt.add_leaf_wind(p.node)
   GardenPlantGrowth.variation(p.node,int(p.shape_seed),float(garden.catalogue[p.id].height),.15 if garden.catalogue[p.id].category=="Cacti & succulents" else 1.0)
  dirty=true
  if is_instance_valid(garden.touch):garden.touch.apply_graphics()
 if not active: return
 if dirty or last_count!=garden.planted.size():
  if last_count!=garden.planted.size() and is_instance_valid(garden.touch):garden.touch.apply_graphics()
  rebuild()
 detail_timer-=delta
 if detail_timer<=0:
  update_detail()
  detail_timer=.25
 for key in tweening.keys():
  var p: Dictionary=tweening[key]
  if not is_instance_valid(p.node) or p.node.is_queued_for_deletion():
   tweening.erase(key)
   continue
  sync(p.node)
  if not p.has("shape_tween") or not is_instance_valid(p.shape_tween) or not p.shape_tween.is_running(): tweening.erase(key)

func batch_mesh(node: MeshInstance3D) -> Mesh:
 var height=float(node.get_meta("plant_height",1.0))
 var material_keys=[]
 for surface in range(node.mesh.get_surface_count()): material_keys.append(node.get_active_material(surface).get_instance_id())
 var key=str(node.mesh.get_instance_id())+":"+str(material_keys)+":"+str(height)
 if meshes.has(key): return meshes[key]
 var mesh=node.mesh.duplicate()
 for surface in range(mesh.get_surface_count()):
  var material=node.get_active_material(surface)
  if material is ShaderMaterial:
   material=material.duplicate()
   material.set_shader_parameter("batched_plant",true)
   material.set_shader_parameter("batch_plant_height",height)
  mesh.surface_set_material(surface,material)
 meshes[key]=mesh
 return mesh

func collect(node: Node3D, owner_node: Node3D, groups: Dictionary) -> void:
 if not node.visible: return
 if node.name=="Vines": return # These grow around a support in world coordinates.
 if node is MeshInstance3D and node.mesh:
  var mesh=batch_mesh(node)
  var cell=Vector2i(floori(owner_node.global_position.x/CELL_SIZE),floori(owner_node.global_position.z/CELL_SIZE))
  var key=str(mesh.get_instance_id())+":"+str(cell)
  if not groups.has(key): groups[key]={"mesh":mesh,"cell":cell,"entries":[],"shadow":node.cast_shadow,"range":node.visibility_range_end,"groundcover":owner_node.get_meta("batch_groundcover",false),"low_plant":owner_node.get_meta("batch_low_plant",false)}
  groups[key].entries.append({"node":node,"owner":owner_node})
  var owner_id=owner_node.get_instance_id()
  if not hidden.has(owner_id): hidden[owner_id]=[]
  hidden[owner_id].append(node)
  node.visible=false
 for child in node.get_children():
  if child is Node3D: collect(child,owner_node,groups)

func rebuild() -> void:
 if is_instance_valid(selected):
  GardenPlantInspector.highlight(selected,false)
  GardenArt.add_leaf_wind(selected)
 # Restore flags before examining stage visibility; never batch dormant organs.
 for p in garden.planted:
  restore(p.node)
  restore(p.marker)
 for border in borders:restore(border)
 borders.clear()
 for anchor in garden.terrain_anchors:
  if is_instance_valid(anchor.node) and anchor.node.has_node("MatureFoliage"):borders.append(anchor.node)
 for child in get_children():
  remove_child(child)
  child.queue_free()
 members.clear()
 hidden.clear()
 var groups={}
 for p in garden.planted:
  if not is_instance_valid(p.node) or p.node.is_queued_for_deletion(): continue
  collect(p.node,p.node,groups)
  collect(p.marker,p.marker,groups)
 for border in borders:
  if is_instance_valid(border) and not border.is_queued_for_deletion():collect(border,border,groups)
 for group in groups.values():
  var multi=MultiMesh.new()
  multi.transform_format=MultiMesh.TRANSFORM_3D
  multi.use_custom_data=true
  multi.mesh=group.mesh
  multi.instance_count=group.entries.size()
  var renderer=MultiMeshInstance3D.new()
  renderer.multimesh=multi
  renderer.position=Vector3(group.cell.x*CELL_SIZE,0,group.cell.y*CELL_SIZE)
  renderer.cast_shadow=group.shadow
  renderer.set_meta("full_shadow",group.shadow)
  renderer.set_meta("groundcover",group.groundcover)
  renderer.set_meta("low_plant",group.low_plant)
  renderer.visibility_range_end=group.range
  renderer.visibility_range_end_margin=8
  renderer.extra_cull_margin=.4 # Include shader lean and wind at cell edges.
  add_child(renderer)
  for i in range(group.entries.size()):
   var entry: Dictionary=group.entries[i]
   var shape: Vector4=entry.node.get_meta("plant_shape",Vector4.ZERO)
   multi.set_instance_custom_data(i,Color(shape.x,shape.y,shape.z,shape.w))
   var key=entry.owner.get_instance_id()
   if not members.has(key): members[key]=[]
   members[key].append({"renderer":renderer,"slot":i,"node":entry.node})
 for p in garden.planted:
  sync(p.node)
  sync(p.marker)
 for border in borders:
  if is_instance_valid(border):sync(border)
 if is_instance_valid(selected):
  individual_shape(selected)
  show_selected(selected,true)
  GardenPlantInspector.highlight(selected,true)
 last_count=garden.planted.size()
 dirty=false
 update_detail()

func update_detail() -> void:
 var balanced=garden.planted.size()>=MIN_PLANTS and garden.settings.graphics=="auto" and not garden.touch_active()
 var position=garden.camera.global_position if is_instance_valid(garden.camera) else Vector3.ZERO
 for renderer in get_children():
  renderer.lod_bias=.5 if balanced else 1.0
  var gap=(Vector2(renderer.position.x+CELL_SIZE*.5-position.x,renderer.position.z+CELL_SIZE*.5-position.z).abs()-Vector2.ONE*CELL_SIZE*.5).max(Vector2.ZERO).length()
  var lighter=balanced and (renderer.get_meta("groundcover",false) or (renderer.get_meta("low_plant",false) and gap>4.0))
  renderer.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if lighter else int(renderer.get_meta("full_shadow"))

func sync(node: Node3D) -> void:
 for entry in members.get(node.get_instance_id(),[]):
  var renderer: MultiMeshInstance3D=entry.renderer
  var transform=renderer.global_transform.affine_inverse()*entry.node.global_transform
  if node==selected: transform.basis=Basis().scaled(Vector3.ZERO)
  renderer.multimesh.set_instance_transform(entry.slot,transform)

func show_selected(node: Node3D, visible: bool) -> void:
 if not is_instance_valid(node): return
 for mesh_node in hidden.get(node.get_instance_id(),[]):
  if is_instance_valid(mesh_node): mesh_node.visible=visible
 sync(node)

func select(node: Node3D) -> void:
 if not active or selected==node: return
 var old=selected
 selected=node
 show_selected(old,false)
 if is_instance_valid(old):GardenArt.add_leaf_wind(old)
 if is_instance_valid(node):individual_shape(node)
 show_selected(node,true)

func individual_shape(node: Node3D) -> void:
 node.set_meta("batch_shape",false)
 GardenPlantGrowth.set_shape(node,node.get_meta("plant_shape",Vector4.ZERO),float(node.get_meta("plant_height",1.0)))
 node.set_meta("batch_shape",true)
