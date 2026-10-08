class_name GardenCultivarAppearance
extends RefCounted

static var materials: Dictionary={}
const PARAMETERS=["cultivar_role","cultivar_pattern","cultivar_primary","cultivar_secondary","cultivar_seed"]

static func role(original: Material) -> int:
 var name=str(original.resource_name).to_lower()
 if name.begins_with("leaf"):return 1
 if name.contains("flower lip"):return 3
 if name.contains("petals") or name.contains(" cream"):return 2
 return 0

static func apply(g, node: Node, f: Dictionary, batched: bool=false) -> void:
 if f.is_empty():return
 if int(f.foliage)==0 and f.genes.bloom==[0,0] and f.genes.pattern==[0,0]:return
 batched=batched or bool(node.get_meta("batch_shape",false))
 if node is MeshInstance3D:
  var anchored=str(node.name).begins_with("BloomFlower") or str(node.name).begins_with("BudsFlower")
  var growth=float(node.get_meta("fruit_growth",1.0)) if anchored else 1.0
  for surface in range(node.mesh.get_surface_count()):
   var original=node.mesh.surface_get_material(surface)
   if not original is StandardMaterial3D:continue
   var organ=role(original)
   if organ==0:continue
   var base_key=str(original.get_instance_id())+":"+str(anchored)+":"+str(growth)
   var base=GardenArt.leaf_materials.get(base_key)
   if not base is ShaderMaterial:continue
   var pattern=int(f.foliage) if organ==1 else maxi(int(f.genes.pattern[0]),int(f.genes.pattern[1]))
   if organ==1 and pattern==0:continue
   var pigments=GardenPlantBreeding.palette(f)
   var primary=g.catalogue[int(f.species)].color if int(f.genes.bloom[0])==0 else Color(pigments[int(f.genes.bloom[0])])
   var secondary=g.catalogue[int(f.species)].color if int(f.genes.bloom[1])==0 else Color(pigments[int(f.genes.bloom[1])])
   if organ==1:secondary=Color("e8dfbf")
   elif pattern>0 and f.genes.bloom[0]==f.genes.bloom[1]:secondary=Color("eee2cf")
   if organ==3 and f.genes.bloom[0]==f.genes.bloom[1]:secondary=Color("e9d4a9")
   # Markings vary within a small set of tissue layouts, not one material per
   # specimen. Identical cloned forms therefore keep the dense-garden batches.
   var seed_value=int(f.seed)%16
   var key=base_key+":"+str(organ)+":"+str(pattern)+":"+primary.to_html()+":"+secondary.to_html()+":"+str(seed_value)
   if not materials.has(key):
    var material=base.duplicate()
    material.set_shader_parameter("cultivar_role",organ)
    material.set_shader_parameter("cultivar_pattern",pattern)
    material.set_shader_parameter("cultivar_primary",primary)
    material.set_shader_parameter("cultivar_secondary",secondary)
    material.set_shader_parameter("cultivar_seed",float(seed_value))
    materials[key]=material
   var material=materials[key]
   if RenderingServer.get_current_rendering_method()=="gl_compatibility" and not batched:
    var private: Dictionary=node.get_meta("cultivar_shape_materials",{})
    if not private.has(key):private[key]=material.duplicate()
    material=private[key]
    material.set_shader_parameter("plant_shape",node.get_meta("plant_shape",Vector4.ZERO))
    material.set_shader_parameter("plant_height",node.get_meta("plant_height",1.0))
    node.set_meta("cultivar_shape_materials",private)
   node.set_surface_override_material(surface,material)
  node.remove_meta("preview_materials")
 for child in node.get_children():apply(g,child,f,batched)
