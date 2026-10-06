extends SceneTree
# Run against the actual exported PCK, not the editor's import cache.
var failures=[]
var texture_count=0
func _initialize() -> void:
 var source=""
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--model-list="):source=argument.trim_prefix("--model-list=")
 var report=JSON.parse_string(FileAccess.get_file_as_string(source))
 if not report is Dictionary or not report.has("model_paths"):
  push_error("Supply the generated texture-sharing report with --model-list")
  quit(1)
  return
 for path in report.model_paths:
  var packed=load(path) as PackedScene
  if not packed:
   failures.append("Missing packed model: "+path)
   continue
  var instance=packed.instantiate()
  inspect(instance)
  instance.free()
 var layout=JSON.parse_string(FileAccess.get_file_as_string("res://assets/areas/layout.json"))
 if not layout is Dictionary or not layout.get("areas") is Array or layout.areas.size()!=10:failures.append("New garden trail layout missing from exported game")
 var transitions=load("res://scripts/garden_area_transitions.gd")
 var routes=transitions.route_data()
 if not routes.get("approaches") is Array or routes.approaches.size()!=10 or routes.get("eastern_link",[]).size()<2:failures.append("Garden entrance routes missing from exported game")
 var paving=transitions.bluestone()
 for channel in ["stone","relief"]:
  var texture=paving.get_shader_parameter(channel) as Texture2D
  if not texture or texture.get_width()==0:failures.append("Bluestone "+channel+" texture missing from exported game")
 if texture_count==0:failures.append("No exported textures found")
 print("EXPORTED_MODELS_CHECKED: ",report.model_paths.size()," models, ",texture_count," texture references")
 print("EXPORTED_MODELS_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)
func inspect(node: Node) -> void:
 if node is MeshInstance3D:
  for index in range(node.mesh.get_surface_count()):
   var material=node.mesh.surface_get_material(index)
   if not material is StandardMaterial3D:continue
   for property in material.get_property_list():
    var texture=material.get(property.name)
    if not texture is Texture2D:continue
    texture_count+=1
    if texture.get_width()==0 or texture.get_height()==0:
     failures.append("Empty texture on "+str(node.name))
    if not texture.resource_path.begins_with("res://assets/shared_textures/"):
     failures.append("Texture was not shared: "+texture.resource_path)
 for child in node.get_children():inspect(child)
