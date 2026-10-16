extends SceneTree

class TestGarden:
 extends "res://scripts/garden.gd"
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass

var failures: Array=[]
func _initialize() -> void:call_deferred("verify")
func check(ok: bool, message: String) -> void:
 if not ok:failures.append(message)

func inspect(node: Node, name: String) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var mat=node.get_active_material(surface)
   check(mat is ShaderMaterial,"Missing botanical material: "+name)
   if mat is ShaderMaterial:
    check(is_zero_approx(float(mat.get_shader_parameter("wind_strength"))),"Mushroom sways like foliage: "+name)
    check(mat.get_shader_parameter("leaf_normal")!=null and mat.get_shader_parameter("leaf_roughness")!=null,"Lost surface detail: "+name)
    if str(node.name).begins_with("Bloom") or str(node.name).begins_with("Buds"):
     check(bool(mat.get_shader_parameter("fruit_anchors")),"Lost cap attachment: "+name)
 for child in node.get_children():inspect(child,name)

func verify() -> void:
 var g=TestGarden.new()
 root.add_child(g)
 check(g.catalogue.size()==298,"Expected 298 catalogue entries")
 g.category="Mushrooms"
 check(GardenSeedCollection.matching(g).size()==20,"Mushroom category missing plants")
 g.category="All";g.collection_filters.group="Mushrooms"
 check(GardenSeedCollection.matching(g).size()==20,"Mushroom collection missing plants")
 g.collection_filters.group="All collections";g.collection_query="Pleurotus"
 check(GardenSeedCollection.matching(g).size()==2,"Scientific-name search missed oysters")
 g.collection_query=""
 var labels=["Pins emerging","Young mushrooms","Caps forming","Caps opening","Ready to gather"]
 var fractions=[.1,.35,.65,.85,1.0]
 for idx in range(278,298):
  var data=g.catalogue[idx]
  check(data.category=="Mushrooms" and data.collection_group=="Mushrooms" and data.condition=="shade","Missing mushroom metadata")
  var model=GardenArt.plant(data)
  root.add_child(model)
  for stage_index in range(fractions.size()):
   var fraction=float(fractions[stage_index])
   GardenPlantGrowth.apply(model,data,fraction,idx+51,Vector3.ONE)
   if idx<288 or stage_index in [0,1,4]:check(GardenPlantGrowth.stage(fraction,data)==labels[stage_index],"Incorrect fungi growth label")
   var stages=model.get_node_or_null("GrowthStages")
   check(stages!=null,"Missing young mushroom stages")
   if stages:
    check(stages.find_child("Seedling*",true,false).visible==(fraction<.2),"Wrong pin visibility")
    check(stages.find_child("Juvenile*",true,false).visible==(fraction>=.2 and fraction<.52),"Wrong young mushroom visibility")
    check(stages.find_child("Buds*",true,false).visible==(fraction>=.52 and fraction<.78),"Wrong forming-cap visibility")
   check(model.get_node("Bloom").visible==(fraction>=.78),"Wrong open-cap visibility")
   check(model.get_node("Bloom").scale==Vector3.ONE,"Caps scaled away from stems")
   inspect(model,data.name)
  if idx>=288:
   # A body must retain its size when forming organs become mature organs.
   var before=GardenPlantGrowth.organ_amount(.7799,data)
   var after=GardenPlantGrowth.organ_amount(.7801,data)
   check(after>=before and after-before<.001,"Fungal body shrinks at stage handoff")
   check(.30*1.25<=lerpf(.12,1.0,.52)*GardenPlantGrowth.organ_amount(.52,data)+.001,"Young fungus is larger than its next stage")
  var batches=GardenPlantBatches.new();batches.garden=g;batches.active=true;batches.dirty=false
  model.set_meta("growth_fraction",.82)
  batches.changing({"id":idx,"node":model,"age":.9*data.days})
  check(batches.dirty,"Cap growth did not refresh its batch")
  if idx>=288:
   check(batches.fruit_size_key(.83,data)==roundi(GardenPlantGrowth.organ_amount(.83,data)*32),"Batch uses a different fungal growth size")
  batches.free();model.free()
 check(GardenPlantGrowth.stage(.65,g.catalogue[288])=="Shelves forming","Turkey tails should form shelves")
 check(GardenPlantGrowth.stage(.85,g.catalogue[289])=="Cups opening","Elf cups should open cups")
 check(GardenPlantGrowth.stage(.65,g.catalogue[291])=="Rays unfolding","Earthstars should unfold rays")
 check(GardenPlantGrowth.stage(.85,g.catalogue[297])=="Branches filling out","Coral should fill out branches")
 # Mixed legacy/new IDs and appearance survive the existing garden save path.
 g.SAVE_PATH="user://mushrooms-test.json"
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.climate=GardenClimate.new();g.add_child(g.climate)
 g.player=CharacterBody3D.new();g.add_child(g.player)
 var ids=[0,277]+range(278,298)
 for i in range(ids.size()):g.add_plant(ids[i],Vector3((i%6)-4,0,floori(i/6.0)-4),0,1,1,.35,1234+i)
 g.favourite_plants=[278,297];g.recent_plants=[297,288,278,0]
 check(g.save_game(),"Could not save mushrooms fixture")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(saved.plants.map(func(p):return int(p.id))==ids,"Saved mushroom IDs changed")
 check(g.valid_plant_ids([0,277,278,287,288,297,298])==[0,277,278,287,288,297],"Catalogue boundary rejected mushrooms")
 g.loaded_data={"version":2,"plants":saved.plants};g.restore_garden()
 check(g.planted.size()==ids.size()*2,"Could not restore mixed garden")
 if g.planted.size()==ids.size()*2:
  for i in range(ids.size()):
   var restored=g.planted[ids.size()+i]
   check(restored.id==ids[i] and restored.shape_seed==1234+i,"Mushroom identity/appearance changed on restore")
 g.free()
 print("MUSHROOMS_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
