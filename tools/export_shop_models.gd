extends SceneTree

func _initialize() -> void:
 var directory="res://assets/shop"
 DirAccess.make_dir_recursive_absolute(directory)
 var exported=0
 for item in GardenCatalogue.furnishings():
  if "--working-garden" in OS.get_cmdline_user_args() and item.kind not in ["worm_farm","mulch_bin","shade_canopy","cold_frame","bird_feeder","wide_bowl","large_planter","herb_trough","hanging_basket","vertical_planter","tiered_planter"]:continue
  var model=Node3D.new()
  model.name=item.kind.capitalize()
  # Keep a GLB scene instance so textures stay in the imported resource.
  # Deep-packing PortableCompressedTexture2D loses its internal binary buffer.
  var imported=load(directory+"/"+item.kind+".glb").instantiate()
  imported.name="Model"
  model.add_child(imported)
  imported.owner=model
  var runtime=GardenArt.furnishing(item.kind)
  for child in runtime.get_children():
   if child is Label3D or child is OmniLight3D:
    var extra=child.duplicate()
    model.add_child(extra)
    extra.owner=model
  runtime.free()
  var scene=PackedScene.new()
  scene.pack(model)
  ResourceSaver.save(scene,directory+"/"+item.kind+".tscn")
  exported+=1
  model.free()
 print("SHOP_MODELS: exported ",exported," inspectable scenes (Blender GLB sources preserved)")
 quit()
