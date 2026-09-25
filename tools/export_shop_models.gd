extends SceneTree

func _initialize() -> void:
 var directory="res://assets/shop"
 DirAccess.make_dir_recursive_absolute(directory)
 for item in GardenCatalogue.furnishings():
  var model=GardenArt.furnishing(item.kind)
  model.name=item.kind.capitalize()
  own_children(model,model)
  var scene=PackedScene.new()
  scene.pack(model)
  ResourceSaver.save(scene,directory+"/"+item.kind+".tscn")
  var document=GLTFDocument.new()
  var state=GLTFState.new()
  if document.append_from_scene(model,state)==OK:
   document.write_to_filesystem(state,directory+"/"+item.kind+".glb")
  model.free()
 print("SHOP_MODELS: exported ",GardenCatalogue.furnishings().size()," inspectable scenes")
 quit()

func own_children(node: Node, owner_node: Node) -> void:
 for child in node.get_children():
  child.owner=owner_node
  own_children(child,owner_node)
