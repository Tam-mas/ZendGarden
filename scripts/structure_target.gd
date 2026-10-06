class_name GardenStructureTarget
extends RefCounted

# Picking uses the authored surfaces, including roofs and rotated structures.
# Layer 2 is only queried by the tool and does not change walking collision.
static var shapes: Dictionary={}
static var tinted_materials: Dictionary={}

static func setup(root: Node3D) -> void:
 var body=StaticBody3D.new()
 body.name="StructureTarget"
 body.collision_layer=2
 body.collision_mask=0
 body.set_meta("structure",root)
 collect_shapes(root,root,body)
 root.add_child(body)

static func refresh(root: Node3D) -> void:
 var body=root.get_node_or_null("StructureTarget")
 if body:
  root.remove_child(body)
  body.queue_free()
 setup(root)

static func collect_shapes(node: Node, root: Node3D, body: StaticBody3D) -> void:
 if node is Node3D and not node.visible:return
 if node is MeshInstance3D and node.mesh:
  var key=node.mesh.get_instance_id()
  if not shapes.has(key):
   var shape=node.mesh.create_trimesh_shape()
   shape.backface_collision=true
   shapes[key]=shape
  var collision=CollisionShape3D.new()
  collision.shape=shapes[key]
  collision.transform=root.global_transform.affine_inverse()*node.global_transform
  body.add_child(collision)
 for child in node.get_children():collect_shapes(child,root,body)

static func ray(g, origin: Vector3, direction: Vector3, ground: Vector3) -> Dictionary:
 var query=PhysicsRayQueryParameters3D.create(origin,origin+direction*20,2)
 query.hit_back_faces=true
 var hit=g.get_world_3d().direct_space_state.intersect_ray(query)
 if hit.is_empty():return {}
 var root=hit.collider.get_meta("structure",null)
 if not is_instance_valid(root) or not root.is_visible_in_tree() or root.is_queued_for_deletion():return {}
 if ground.is_finite() and origin.distance_to(hit.position)>origin.distance_to(ground)+.05:return {}
 if g.player.position.distance_to(hit.position)>7:return {}
 return {"node":root,"position":hit.position}

static func highlight(node: Node, enabled: bool) -> void:
 if node is MeshInstance3D:
  if enabled and not node.has_meta("structure_materials"):
   var originals=[]
   for surface in range(node.mesh.get_surface_count()):
    var material=node.get_active_material(surface)
    originals.append(node.get_surface_override_material(surface))
    if material is StandardMaterial3D:
     var key=material.get_instance_id()
     if not tinted_materials.has(key):
      var tinted=material.duplicate()
      tinted.albedo_color=material.albedo_color.lerp(Color("ff8270"),.72)
      tinted.albedo_color.a=material.albedo_color.a if material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED else maxf(.5,material.albedo_color.a)
      tinted.emission_enabled=true
      tinted.emission=Color("ff6655")
      tinted.emission_energy_multiplier=.22
      tinted_materials[key]=tinted
     node.set_surface_override_material(surface,tinted_materials[key])
   node.set_meta("structure_materials",originals)
  elif not enabled and node.has_meta("structure_materials"):
   var originals: Array=node.get_meta("structure_materials")
   for surface in range(originals.size()):node.set_surface_override_material(surface,originals[surface])
   node.remove_meta("structure_materials")
 for child in node.get_children():highlight(child,enabled)

static func clear(g) -> void:
 if is_instance_valid(g.highlighted_structure):highlight(g.highlighted_structure,false)
 g.highlighted_structure=null

static func update(g) -> Array:
 var index=g.aimed_object() if g.mode=="remove" and g.hover_valid else -1
 var target: Node3D=g.objects[index].node if index>=0 else null
 if g.highlighted_structure!=target:
  clear(g)
  g.highlighted_structure=target
  if is_instance_valid(target):highlight(target,true)
 if index<0:return []
 var obj=g.objects[index]
 var title=obj.kind.capitalize()
 for item in g.furniture:
  if item.kind==obj.kind:title=item.name;break
 if not GardenAreaProgression.allowed(g,obj.pos):return [title,"Milestone reward",GardenAreaProgression.requirement(GardenAreaCatalogue.index_at(obj.pos)),GardenAreaProgression.progress(g,GardenAreaCatalogue.index_at(obj.pos))]
 return [title,"Selected for removal","Returns %d petals"%int(obj.price),"Tap Remove to pack away" if g.touch_active() else "Click to pack away"]
