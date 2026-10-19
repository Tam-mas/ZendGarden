extends SceneTree

class TestGarden:
 extends "res://scripts/garden.gd"
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass

var failures: Array=[]
func _initialize() -> void:call_deferred("verify")
func check(ok: bool, message: String) -> void:
 if not ok:failures.append(message)

func verify() -> void:
 var g=TestGarden.new();root.add_child(g)
 var data=g.catalogue[GardenCatalogue.GARLIC_ID]
 check(data.name=="Garlic" and data.botanical_name=="Allium sativum","Garlic identity changed")
 check(data.category=="Produce" and data.collection_group=="Fruit & vegetables","Missing produce category")
 check(data.days==12 and is_equal_approx(data.height,.62),"Incorrect garlic growth profile")
 check(data.seasons==["Autumn","Winter","Spring"],"Missing cool-season profile")
 g.category="Produce";g.collection_query="Allium sativum"
 check(GardenSeedCollection.matching(g).size()==1,"Scientific-name search missed garlic")
 var model=GardenArt.plant(data);root.add_child(model)
 var fractions=[.1,.35,.65,.85,1.0]
 var labels=["Seedling","Developing leaves","Bulb forming","Bulb swelling","Ready to gather"]
 for i in range(fractions.size()):
  var fraction=float(fractions[i])
  GardenPlantGrowth.apply(model,data,fraction,812,Vector3.ONE)
  check(GardenPlantGrowth.stage(fraction,data)==labels[i],"Incorrect garlic stage label")
  var stages=model.get_node_or_null("GrowthStages")
  check(stages!=null,"Missing garlic growth models")
  if stages:
   check(stages.find_child("Seedling*",true,false).visible==(fraction<.2),"Incorrect shoot visibility")
   check(stages.find_child("Juvenile*",true,false).visible==(fraction>=.2 and fraction<.52),"Incorrect young foliage visibility")
   check(stages.find_child("Buds*",true,false).visible==(fraction>=.52 and fraction<.78),"Incorrect forming bulb visibility")
  check(model.get_node("Bloom").visible==(fraction>=.78),"Incorrect mature bulb visibility")
  check(model.get_node("Bloom").scale==Vector3.ONE,"Bulb detached from soil-level anchor")
 model.free()
 g.SAVE_PATH="user://garlic-test.json"
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.climate=GardenClimate.new();g.add_child(g.climate)
 g.player=CharacterBody3D.new();g.add_child(g.player)
 for i in range(3):g.add_plant([0,297,298][i],Vector3(i,0,0),0,1,1,.35,1200+i)
 var garlic=g.planted.back();garlic.age=data.days
 check(g.collect_plant(garlic),"Mature garlic cannot be gathered")
 check(int(g.inventory.get("298",0))==1,"Garlic harvest missing from basket")
 g.favourite_plants=[298];g.recent_plants=[298,0]
 check(g.save_game(),"Garlic save failed")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(saved.plants.map(func(p):return int(p.id))==[0,297,298],"Existing or new plant IDs changed")
 g.loaded_data={"version":3,"plants":saved.plants};g.restore_garden()
 check(g.planted.size()==6 and g.planted.back().id==298 and g.planted.back().shape_seed==1202,"Garlic did not restore")
 check(g.valid_plant_ids([0,297,298,299])==[0,297,298],"Catalogue boundary rejected garlic")
 g.free()
 print("GARLIC_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
