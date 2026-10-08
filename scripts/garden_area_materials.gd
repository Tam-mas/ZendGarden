class_name GardenAreaMaterials
extends RefCounted

# Shared profiles retain imported albedo, normal and roughness maps. UV metres
# are authored in Blender; gentle foot staining remains local to each mesh.
static var cache: Dictionary={}

static func family(name: String) -> int:
 var n=name.to_lower()
 if "glass" in n:return 7
 if "shadecloth" in n or "fallen leaf" in n:return 6
 if "bark" in n or "endgrain" in n or "cedar" in n or "oak" in n:return 0
 if "terracotta" in n:return 2
 if "iron" in n or "zinc" in n or "bronze" in n:return 3
 if "paving" in n or "brick" in n:return 4
 if "loam" in n or "soil" in n:return 5
 return 1

static func prepare(node: Node) -> void:
 if node is MeshInstance3D:
  if node.get_meta("ground_detail",false):node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  for surface in range(node.mesh.get_surface_count()):
   var original=node.get_active_material(surface)
   if not original is StandardMaterial3D:continue
   var kind=family(original.resource_name)
   if kind in [6,7]:
    var key=str(original.get_instance_id())+":standard"
    if not cache.has(key):
     var mat=original.duplicate()
     mat.roughness=.16 if kind==7 else .94;mat.metallic_specular=.48 if kind==7 else .20
     if kind==7:mat.albedo_color=Color(.88,.94,.92,original.albedo_color.a)
     cache[key]=mat
    node.set_surface_override_material(surface,cache[key])
    continue
   var bounds=node.mesh.get_aabb()
   var low=bounds.position.y
   var stain=minf(.30,maxf(.055,bounds.size.y*.28))
   var key="%s:%s:%.3f:%.3f"%[original.get_instance_id(),kind,low,stain]
   if not cache.has(key):
    var mat=ShaderMaterial.new();mat.shader=load("res://shaders/habitat_surface.gdshader")
    for pair in [["pigment",original.albedo_texture],["relief",original.normal_texture],["finish_map",original.roughness_texture]]:
     if pair[1]:mat.set_shader_parameter(pair[0],pair[1])
    mat.set_shader_parameter("has_pigment",original.albedo_texture!=null)
    mat.set_shader_parameter("has_relief",original.normal_enabled and original.normal_texture!=null)
    mat.set_shader_parameter("has_finish",original.roughness_texture!=null)
    var tone=original.albedo_color
    var label=original.resource_name.to_lower()
    if "weathered limestone" in label:tone*=Color(.48,.46,.40)
    if "cut garden flagstone" in label:tone*=Color(.54,.55,.51)
    if "bank mossrock" in label:tone*=Color(.27,.31,.25)
    if "alpine granite" in label:tone*=Color(.36,.39,.36)
    mat.set_shader_parameter("tint",tone)
    mat.set_shader_parameter("finish_factor",original.roughness)
    mat.set_shader_parameter("roughness_min",[.72,.79,.82,.34,.78,.96][kind])
    mat.set_shader_parameter("roughness_max",[.94,.97,.98,.60,.96,1.][kind])
    mat.set_shader_parameter("metal",original.metallic if kind==3 else 0.)
    mat.set_shader_parameter("surface_specular",.42 if kind==3 else .25)
    mat.set_shader_parameter("relief_depth",.40 if kind in [0,3] else .52)
    mat.set_shader_parameter("base_height",low);mat.set_shader_parameter("stain_height",stain)
    mat.set_shader_parameter("family",kind);cache[key]=mat
    mat.set_shader_parameter("is_flagstone","cut garden flagstone" in original.resource_name.to_lower())
   node.set_surface_override_material(surface,cache[key])
 for child in node.get_children():prepare(child)
