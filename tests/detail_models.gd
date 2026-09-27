extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func mesh_count(node: Node) -> int:
 var count=1 if node is MeshInstance3D else 0
 for child in node.get_children(): count+=mesh_count(child)
 return count

func run() -> void:
 var failures=[]
 for item in GardenCatalogue.furnishings():
  var model=GardenArt.furnishing(item.kind)
  root.add_child(model)
  if mesh_count(model)==0: failures.append(item.kind+" has no imported meshes")
  if item.kind=="sign":
   GardenArt.set_sign_text(model,"Detailed garden",Color.CORAL)
   for face in ["FrontText","BackText"]:
    if model.get_node(face).text!="Detailed garden": failures.append("Sign label contract broken")
  if item.kind=="lantern" and not model.get_children().any(func(n):return n is OmniLight3D): failures.append("Lantern light missing")
  model.free()
  var inspection=load("res://assets/shop/"+item.kind+".tscn").instantiate()
  var textures=[]
  collect_textures(inspection,textures)
  if textures.is_empty() or textures.any(func(t):return t.get_width()==0): failures.append(item.kind+" inspection scene lost its textures")
  inspection.free()
 for kind in ["songbird","native bird","bee","butterfly","dragonfly","firefly"]:
  var model=GardenArt.visitor(kind)
  root.add_child(model)
  var wings=model.get_children().filter(func(n):return str(n.name).begins_with("Wing"))
  if wings.size()!=2: failures.append(kind+" missing direct wing pivots")
  for wing in wings:
   if not wing.has_meta("side") or mesh_count(wing)==0: failures.append(kind+" wing lost geometry or side")
   if absf(wing.position.x)<.001: failures.append(kind+" wing pivot transform lost")
   wing.rotation.z=.4*float(wing.get_meta("side",1))
  model.free()
 for kind in ["rabbit","kangaroo"]:
  for joey in [false,true]:
   var model=GardenVisitors.model(kind,joey)
   if not model.has_node("Head") or mesh_count(model.get_node("Head"))==0: failures.append(kind+" head animation contract broken")
   if model.get_node("Head").position.y<.3: failures.append(kind+" head transform lost")
   model.free()
 for is_cat in [true,false]:
  var model=GardenArt.companion(is_cat)
  root.add_child(model)
  if not model.body or not model.head or not model.tail or model.legs.size()!=4: failures.append("Companion joints missing")
  for leg in model.legs:
   if not is_instance_valid(leg) or mesh_count(leg)==0: failures.append("Companion leg missing geometry")
  model.free()
 print("DETAIL_MODELS_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)

func collect_textures(node: Node, target: Array) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var material=node.mesh.surface_get_material(surface)
   if material is StandardMaterial3D and material.albedo_texture: target.append(material.albedo_texture)
 for child in node.get_children(): collect_textures(child,target)
