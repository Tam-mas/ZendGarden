class_name GardenAreaFlora
extends RefCounted

# Detailed botanical meshes share GPU instances per habitat and canopy switch.
# The empty authoring anchors remain the source of positions and terrain edits.
static var parts_cache: Dictionary={}

static func growth(model: Node3D,fraction: float,flowers_open: bool=true) -> void:
 var stage="Seedling" if fraction<.20 else "Juvenile" if fraction<.52 else "Buds" if fraction<.78 else "Mature"
 var start=.0 if stage=="Seedling" else .20 if stage=="Juvenile" else .52 if stage=="Buds" else .78
 var end=.20 if stage=="Seedling" else .52 if stage=="Juvenile" else .78 if stage=="Buds" else 1.0
 var minimum=.35 if stage=="Seedling" else .48 if stage=="Juvenile" else .65 if stage=="Buds" else .80
 model.scale=Vector3.ONE*lerpf(minimum,1.0,clampf((fraction-start)/(end-start),0,1))
 for key in ["Seedling","Juvenile","Buds"]:
  var n=GardenAreas.find(model,key)
  if n:n.visible=key==stage
 for key in ["Leaves","Flowers"]:
  var n=GardenAreas.find(model,key)
  if n:n.visible=stage=="Mature" and (key!="Flowers" or flowers_open)

static func parts(g,key: String,species: String,id: int) -> Array:
 if parts_cache.has(key):return parts_cache[key]
 var model: Node3D=GardenAreas.instantiate("res://assets/areas/plants/"+species+".glb") if id<0 else g.Art.plant(g.catalogue[id],true)
 if not model:return []
 if id<0:growth(model,1);g.Art.add_leaf_wind(model)
 var result=[];collect(model,Transform3D.IDENTITY,result)
 model.free();parts_cache[key]=result
 return result

static func collect(node: Node,transform: Transform3D,result: Array) -> void:
 if node is Node3D:
  if not node.visible:return
  transform=transform*node.transform
 if node is MeshInstance3D:
  # Keep imported LODs, vertex formats and shadow geometry intact. Rebuilding
  # from surface arrays silently discards the lower-detail index buffers.
  var mesh=node.mesh.duplicate()
  for surface in range(node.mesh.get_surface_count()):
   mesh.surface_set_material(surface,node.get_active_material(surface))
  result.append({"mesh":mesh,"transform":transform,"shadow":node.cast_shadow})
 for child in node.get_children():collect(child,transform,result)

static func build(g,root: Node3D) -> void:
 var groups={};scan(g,root,root,groups)
 var batches=[]
 for key in groups:
  var group=groups[key];var organs=parts(g,group.key,group.species,group.id)
  for organ in organs:
   var instance=MultiMeshInstance3D.new();instance.name="BotanicalInstances"
   var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=organ.mesh;mm.instance_count=group.anchors.size()
   instance.multimesh=mm;instance.cast_shadow=organ.shadow
   instance.set_meta("full_shadow",organ.shadow)
   instance.set_meta("low_plant",group.id>=0 and int(g.catalogue[group.id].layer)<2)
   instance.add_to_group("habitat_flora")
   group.parent.add_child(instance);instance.visibility_range_end=80
   batches.append({"node":instance,"anchors":group.anchors,"organ":organ.transform})
 root.set_meta("flora_batches",batches);refresh(root)

static func scan(g,node: Node,parent: Node3D,groups: Dictionary) -> void:
 if str(node.name).begins_with("Canopy") or str(node.name).begins_with("DuskFlowers"):parent=node
 var extras: Dictionary=node.get_meta("extras",{})
 if node is Node3D and extras.has("area_species"):
  var species=str(extras.area_species);var id=int(extras.get("area_plant_id",-1));var plant_key=species if id<0 else str(id)
  var key=str(parent.get_instance_id())+":"+plant_key
  if not groups.has(key):groups[key]={"key":plant_key,"species":species,"id":id,"parent":parent,"anchors":[]}
  groups[key].anchors.append(node);node.set_meta("terrain_anchor",true)
  if species=="treefern":
   GardenLandscape.trunk_collision(node,.16,1.8)
   for child in node.get_children():
    if child is StaticBody3D:child.set_meta("area_obstacle",true)
 for child in node.get_children():
  if child is Node3D and not child is StaticBody3D:scan(g,child,parent,groups)

static func refresh(root: Node3D) -> void:
 for batch in root.get_meta("flora_batches",[]):
  var inverse=batch.node.global_transform.affine_inverse()
  var bounds: AABB
  for j in range(batch.anchors.size()):
   var world: Transform3D=batch.anchors[j].global_transform*batch.organ
   batch.node.multimesh.set_instance_transform(j,inverse*world)
   var box: AABB=world*batch.node.multimesh.mesh.get_aabb()
   bounds=box if j==0 else bounds.merge(box)
  batch.node.set_meta("world_bounds",bounds.grow(.4))

static func update_detail(g) -> void:
 if not is_instance_valid(g.camera):return
 var balanced=g.settings.graphics=="auto" and not g.touch_active()
 var position: Vector3=g.camera.global_position
 for renderer in g.get_tree().get_nodes_in_group("habitat_flora"):
  renderer.lod_bias=.5 if balanced else 1.0
  var bounds: AABB=renderer.get_meta("world_bounds",AABB())
  var gap=position.distance_to(position.clamp(bounds.position,bounds.end))
  var lighter=balanced and renderer.get_meta("low_plant",false) and gap>4.0
  renderer.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if lighter else int(renderer.get_meta("full_shadow"))
