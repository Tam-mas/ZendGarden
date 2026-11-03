# Regenerate the GitHub plant list from the in-game catalogue:
# Godot --headless --path . --script tools/plant_list.gd
extends SceneTree
func _initialize() -> void:
 var plants=GardenCatalogue.plants()
 var output="# Plant list\n\nAll %d plants available in Seeds, grouped by the collection shown in the game. Mushrooms are included as their own collection.\n\nThis list is generated from the game catalogue. Regenerate it with `Godot --headless --path . --script tools/plant_list.gd` after changing the catalogue.\n\n" % plants.size()
 for group in GardenCatalogue.COLLECTION_GROUPS:
  var names: Array=[]
  for plant in plants:
   if plant.collection_group==group:names.append(plant.name)
  names.sort_custom(func(a,b):return a.naturalnocasecmp_to(b)<0)
  output+="## %s (%d)\n\n" % [group,names.size()]
  for name in names:output+="- "+name+"\n"
  output+="\n"
 var file=FileAccess.open("res://PLANTS.md",FileAccess.WRITE)
 file.store_string(output.strip_edges()+"\n")
 quit()
