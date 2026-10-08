extends SceneTree

# Exercise the real collection matcher and controls without constructing a garden
# world or loading models. An empty search keeps UI checks independent of artwork.
class CollectionGarden:
 extends Node
 var catalogue=GardenCatalogue.plants()
 var category="All"
 var collection_query=""
 var collection_filters=defaults()
 var collection_filters_open=false
 var favourite_plants=[]
 var recent_plants=[]
 var unlocked_plants=[]
 var day=1
 var selected=0
 var touch=false
 var side_title=Label.new()
 var list_box=VBoxContainer.new()
 var detail_label=Label.new()

 static func defaults() -> Dictionary:
  return {"group":"All collections","view":"All plants","season":"Any season","light":"Any light","height":"Any height","colour":"Any colour","wildlife":"Any wildlife","sort":"Catalogue"}

 func touch_active() -> bool:return touch
 func label(text: String, font_size: int=16) -> Label:
  var result=Label.new()
  result.text=text
  result.add_theme_font_size_override("font_size",font_size)
  return result
 func button(text: String, action: Callable, minimum: Vector2=Vector2.ZERO) -> Button:
  var result=Button.new()
  result.text=text
  result.custom_minimum_size=minimum
  result.pressed.connect(action)
  return result
 func choose_plant(_id: int) -> void:pass
 func save_game() -> void:pass
 func default_collection_filters() -> Dictionary:return defaults()
 func refresh_sidebar() -> void:
  for child in list_box.get_children():
   list_box.remove_child(child)
   child.queue_free()
  GardenSeedCollection.build(self)

var failures: Array=[]

func check(condition: bool, note: String) -> void:
 if not condition:failures.append(note)

func ids(plants: Array) -> Array:
 var result=[]
 for plant in plants:result.append(plant.id)
 return result

func _initialize() -> void:call_deferred("verify")

func verify() -> void:
 var g=CollectionGarden.new()
 root.add_child(g)
 # Every legacy entry and every new entry must be reachable through a section.
 for plant in g.catalogue:
  check(plant.get("collection_group","") in GardenCatalogue.COLLECTION_GROUPS,"Missing collection: "+plant.name)
  check(float(plant.get("height",0))>0,"Missing mature height: "+plant.name)
 var section_total=0
 for section in GardenCatalogue.COLLECTION_GROUPS:
  g.collection_filters.group=section
  var plants=GardenSeedCollection.matching(g)
  check(not plants.is_empty(),"Empty collection section: "+section)
  section_total+=plants.size()
  for plant in plants:check(plant.collection_group==section,"Section includes wrong plant: "+plant.name)
 check(section_total==g.catalogue.size(),"Collection sections do not cover the catalogue exactly once")
 g.collection_filters=CollectionGarden.defaults()
 for direction in ["Height: low to high","Height: high to low"]:
  g.collection_filters.sort=direction
  var plants=GardenSeedCollection.matching(g)
  check(plants.size()==g.catalogue.size(),"Height sort hides catalogue entries")
  for i in range(1,plants.size()):
   var previous=plants[i-1]
   var current=plants[i]
   check(previous.height<=current.height if direction=="Height: low to high" else previous.height>=current.height,"Height ordering wrong: "+direction)
   if previous.height==current.height:check(previous.name.naturalnocasecmp_to(current.name)<=0,"Equal heights lack stable alphabetical order")
 # Equal-height and equal-name ties must be reproducible even with mixed IDs.
 var full_catalogue=g.catalogue
 g.catalogue=[]
 for data in [[151,"Zinnia",1.0],[0,"Cosmos",1.0],[200,"Abelia",2.0],[150,"Columbine",1.0],[152,"Columbine",1.0]]:
  g.catalogue.append({"id":data[0],"name":data[1],"height":data[2],"category":"Flowers","collection_group":"Cottage flowers","days":5,"seasons":[],"condition":"sun","color":Color.WHITE,"animal":"bees"})
 g.collection_filters.sort="Height: low to high"
 check(ids(GardenSeedCollection.matching(g))==[150,152,0,151,200],"Ascending height sort or ties fail for old/new plants")
 g.collection_filters.sort="Height: high to low"
 check(ids(GardenSeedCollection.matching(g))==[200,150,152,0,151],"Descending height sort or ties fail for old/new plants")
 g.collection_filters.view="Recently planted"
 g.recent_plants=[151,200,0]
 check(ids(GardenSeedCollection.matching(g))==[200,0,151],"Explicit height sort fails in recent planting view")
 g.collection_filters.sort="Catalogue"
 check(ids(GardenSeedCollection.matching(g))==[151,200,0],"Default recent planting order changed")
 g.collection_filters=CollectionGarden.defaults()
 g.collection_filters.sort="Height"
 check(ids(GardenSeedCollection.matching(g))==[150,152,0,151,200],"Legacy Height sort preference no longer works")
 g.collection_filters.group="Removed section"
 check(GardenSeedCollection.matching(g).size()==5,"Unknown collection preference hides plants")
 g.collection_filters=CollectionGarden.defaults()
 g.collection_filters.height="Tall (2 m+)"
 check(ids(GardenSeedCollection.matching(g))==[200],"Height bands no longer work alongside ordering")
 g.catalogue=full_catalogue
 g.collection_query="no-such-plant"
 g.add_child(g.side_title)
 g.add_child(g.list_box)
 g.add_child(g.detail_label)
 g.list_box.size=Vector2(330,600)
 for touch_mode in [false,true]:
  g.touch=touch_mode
  g.collection_filters=CollectionGarden.defaults()
  g.collection_filters.group="Removed section"
  g.collection_filters.sort="Removed sort"
  g.refresh_sidebar()
  await process_frame
  await process_frame
  var group_picker=g.list_box.find_child("FilterGroup",true,false)
  var sort_picker=g.list_box.find_child("FilterSort",true,false)
  check(group_picker!=null and sort_picker!=null,"Persistent collection or sort control missing")
  if group_picker==null or sort_picker==null:continue
  check(group_picker.is_visible_in_tree() and sort_picker.is_visible_in_tree() and not g.list_box.get_node("SeedFilters").visible,"Collection/sort controls hidden with detailed filters")
  check(group_picker.get_parent().get_parent().name=="CollectionNavigation" and sort_picker.get_parent().get_parent().name=="CollectionNavigation","Navigation still lives inside expanded filters")
  check(group_picker.size.x>100 and sort_picker.size.x>100,"Navigation leaves too little room for readable choices")
  if touch_mode:
   check(group_picker.size.y>=42 and sort_picker.size.y>=42,"Touch navigation controls too small")
   check(g.list_box.has_node("CategoryPicker") and not g.list_box.get_node("SeedCategories").visible,"Phone categories crowd out collection navigation")
  check(g.collection_filters.group=="All collections" and g.collection_filters.sort=="Catalogue","Invalid preferences not restored to visible defaults")
  group_picker.item_selected.emit(1)
  check(g.collection_filters.group==GardenCatalogue.COLLECTION_GROUPS[0] and g.category=="All","Section chooser does not browse across categories")
  sort_picker.item_selected.emit(3)
  check(g.collection_filters.sort=="Height: high to low","Descending height option not connected")
  var search=g.list_box.get_node("SeedSearch")
  search.grab_focus()
  search.text="another-missing-plant"
  search.text_changed.emit(search.text)
  check(g.category=="All" and g.collection_filters.group=="All collections" and group_picker.selected==0,"Search all plants is restricted by a section")
  check(search.has_focus(),"Search lost focus while updating cards")
  for b in g.list_box.get_node("SeedCategories").get_children():
   if b.get_meta("category","")=="Flowers":
    group_picker.item_selected.emit(1)
    b.pressed.emit()
    check(g.category=="Flowers" and g.collection_filters.group=="All collections" and group_picker.selected==0,"Category selection retains a conflicting section")
 g.queue_free()
 await process_frame
 print("FLOWER_COLLECTION_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
