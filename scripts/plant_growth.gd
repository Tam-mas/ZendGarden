class_name GardenPlantGrowth
extends RefCounted

static var scenes: Dictionary={}

static func stage(fraction: float, data: Dictionary) -> String:
 if fraction<.20: return "Seedling"
 if fraction<.52: return "Developing leaves"
 if fraction<.78:
  if data.id in [13,14,15,16,17,18,25,29,30,32,44,45,68,69,70,71,72,78,79,80,81]: return "New growing tips"
  return "Developing harvest" if data.category=="Produce" or data.id in [27,31,34,35,42,82,83,84,85,86,87,88,89,90,91] else "Budding"
 if fraction<1.0:
  if data.id in [13,14,15,16,17,18,25,29,30,32,44,45,68,69,70,71,72,78,79,80,81]: return "Filling out"
  return "Ripening" if data.category=="Produce" or data.id in [27,31,34,35,42,82,83,84,85,86,87,88,89,90,91] else "Flowering"
 return "Ready to gather"

static func ensure_stages(node: Node3D, id: int) -> Node3D:
 var stages=node.get_node_or_null("GrowthStages")
 if stages: return stages
 var path="res://assets/plants/growth/growth_%02d.glb" % id
 if not ResourceLoader.exists(path): return null
 if not scenes.has(path): scenes[path]=load(path)
 stages=scenes[path].instantiate()
 stages.name="GrowthStages"
 node.add_child(stages)
 GardenArt.add_leaf_wind(stages)
 return stages

static func apply(node: Node3D, data: Dictionary, fraction: float, shape_seed: int, root_scale: Vector3) -> void:
 var mature=node.get_node_or_null("MatureFoliage")
 if mature==null: return
 mature.visible=fraction>=.52
 var bloom=node.get_node("Bloom")
 bloom.visible=fraction>=.78
 bloom.scale=Vector3.ONE*lerpf(.48,1.0,clampf((fraction-.78)/.22,0,1))
 var stages=node.get_node_or_null("GrowthStages")
 if fraction<.78: stages=ensure_stages(node,int(data.id))
 if stages:
  var seedling=stages.find_child("Seedling*",true,false)
  var juvenile=stages.find_child("Juvenile*",true,false)
  var buds=stages.find_child("Buds*",true,false)
  seedling.visible=fraction<.20
  juvenile.visible=fraction>=.20 and fraction<.52
  buds.visible=fraction>=.52 and fraction<.78
  # Early organs are authored at their own size, independent of mature-model scaling.
  var early=lerpf(.70,1.15,fraction/.20) if fraction<.20 else lerpf(.65,1.25,clampf((fraction-.20)/.32,0,1))
  for organ in [seedling,juvenile]: organ.scale=Vector3.ONE*early/root_scale
  buds.scale=Vector3.ONE*lerpf(.65,1.0,clampf((fraction-.52)/.26,0,1))
 node.set_meta("growth_fraction",fraction)
 node.set_meta("shape_seed",shape_seed)
 variation(node,shape_seed,float(data.get("height",1.0)))

static func variation(node: Node, seed_value: int, height: float) -> void:
 var rng=RandomNumberGenerator.new()
 rng.seed=seed_value
 var shape=Vector4(rng.randf_range(-.045,.045),rng.randf_range(-.045,.045),rng.randf_range(-.12,.12),rng.randf_range(0,TAU))
 set_shape(node,shape,maxf(.1,height))

static func set_shape(node: Node, shape: Vector4, height: float) -> void:
 if node is MeshInstance3D:
  if RenderingServer.get_current_rendering_method()=="gl_compatibility":
   # WebGL's small uniform buffer cannot reserve an instance block per mesh.
   # Only planted specimens need private shape values; border plants share zero.
   var owned: Dictionary=node.get_meta("shape_materials",{})
   for surface in range(node.mesh.get_surface_count()):
    var material=node.get_active_material(surface)
    if material is ShaderMaterial:
     if material.get_shader_parameter("plant_shape")==shape and material.get_shader_parameter("plant_height")==height:continue
     var individual=material if owned.get(surface)==material else material.duplicate()
     individual.set_shader_parameter("plant_shape",shape)
     individual.set_shader_parameter("plant_height",height)
     node.set_surface_override_material(surface,individual)
     owned[surface]=individual
   node.set_meta("shape_materials",owned)
  else:
   node.set_instance_shader_parameter("plant_shape",shape)
   node.set_instance_shader_parameter("plant_height",height)
 for child in node.get_children(): set_shape(child,shape,height)
