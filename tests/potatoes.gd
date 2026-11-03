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
 g.SAVE_PATH=OS.get_environment("TMPDIR").path_join("zend-garden-potato-test.json")
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.climate=GardenClimate.new();g.add_child(g.climate)
 g.player=CharacterBody3D.new();g.add_child(g.player)
 g.category="Produce";g.collection_query="potato"
 check(GardenSeedCollection.matching(g).size()==3,"Potato search should return three varieties")
 for id in GardenCatalogue.POTATO_IDS:
  var data=g.catalogue[id]
  check(data.category=="Produce" and data.collection_group=="Fruit & vegetables" and data.botanical_name=="Solanum tuberosum","Potato identity")
  var model=GardenArt.plant(data);root.add_child(model)
  for fraction in [.1,.35,.65,.85,1.0]:
   GardenPlantGrowth.apply(model,data,fraction,812,Vector3.ONE)
   check(model.get_node_or_null("GrowthStages")!=null,"Missing growth stages")
   check(model.get_node("Bloom").visible==(fraction>=.78),"Incorrect tuber visibility")
  check(GardenPlantGrowth.stage(.65,data)=="Tubers forming" and GardenPlantGrowth.stage(.85,data)=="Tubers swelling","Incorrect growth labels")
  model.free()
  g.add_plant(id,Vector3(id-299,0,0),0,1,1,.35,1200+id)
  var plant=g.planted.back();plant.age=data.days
  check(g.collect_plant(plant) and int(g.inventory.get(str(id),0))==1,"Potato harvest failed")
 check(g.save_game(),"Save failed")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(saved.plants.map(func(p):return int(p.id))==[299,300,301],"Potato IDs not saved")
 g.loaded_data={"version":3,"plants":saved.plants};g.restore_garden()
 check(g.planted.size()==6 and g.planted.back().id==301,"Potato restore failed")
 check(g.valid_plant_ids([0,298,299,300,301,302])==[0,298,299,300,301],"Catalogue boundary")
 g.free();print("POTATO_RESULT: ",JSON.stringify(failures));quit(0 if failures.is_empty() else 1)
