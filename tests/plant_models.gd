extends SceneTree
var failures: Array=[]
var leaf_surfaces=0

func _initialize() -> void:
 call_deferred("verify")

func inspect(node: Node) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var material=node.get_surface_override_material(surface)
   if material is ShaderMaterial and material.shader.resource_path.ends_with("leaf_wind.gdshader"):
    leaf_surfaces+=1
    if material.get_shader_parameter("leaf_texture")==null: failures.append("Leaf colour map missing")
    if material.get_shader_parameter("leaf_normal")==null or not material.get_shader_parameter("has_normal_map"): failures.append("Leaf normal map lost during wind override")
    if material.get_shader_parameter("leaf_roughness")==null or not material.get_shader_parameter("has_roughness_map"): failures.append("Leaf roughness map lost during wind override")
 for child in node.get_children(): inspect(child)

func verify() -> void:
 if GardenCatalogue.ROWS.size()!=218 or GardenCatalogue.GROWTH_DAYS.size()!=218: failures.append("Incomplete expanded catalogue")
 for data in GardenCatalogue.plants():
  var before=leaf_surfaces
  var model=GardenArt.plant(data)
  root.add_child(model)
  if model.get_node_or_null("Bloom")==null: failures.append("Missing growth/harvest bloom group: "+str(data.id))
  inspect(model)
  if leaf_surfaces==before: failures.append("Missing wind foliage for plant "+str(data.id))
  model.free()
 if leaf_surfaces<GardenCatalogue.ROWS.size(): failures.append("Catalogue has missing leaf materials")
 print("PLANT_MODELS_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
