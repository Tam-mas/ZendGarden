extends SceneTree

class SaveGarden:
 extends "res://scripts/garden.gd"
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass

var failures: Array=[]

func _initialize() -> void:call_deferred("verify")

func check(condition: bool, note: String) -> void:
 if not condition:failures.append(note)

func inspect_attachments(node: Node, expected: float) -> void:
 if node is MeshInstance3D and (str(node.name).begins_with("BloomFlower") or str(node.name).begins_with("BudsFlower")):
  for surface in range(node.mesh.get_surface_count()):
   var material=node.get_active_material(surface)
   check(material is ShaderMaterial,"Attached flower lost its botanical shader")
   if material is ShaderMaterial:
    check(bool(material.get_shader_parameter("fruit_anchors")),"Flower attachments disabled")
    check(is_equal_approx(float(material.get_shader_parameter("fruit_growth")),expected),"Flower opening fraction lost")
    check(material.get_shader_parameter("leaf_normal")!=null,"Flower normal texture missing")
    check(material.get_shader_parameter("leaf_roughness")!=null,"Flower roughness texture missing")
 for child in node.get_children():inspect_attachments(child,expected)

func verify() -> void:
 var catalogue=GardenCatalogue.plants()
 check(catalogue.size()==218,"Catalogue must contain 218 plants")
 var counts={"Orchids":0,"Wildflowers":0,"Cottage flowers":0,"Flowering bushes":0}
 for id in range(148,218):
  var data=catalogue[id]
  check(not str(data.botanical_name).is_empty(),"Botanical identity missing: "+data.name)
  check(data.attached_bloom,"New flowers must open around their own stems")
  counts[data.collection_group]+=1
  var model=GardenArt.plant(data)
  root.add_child(model)
  for fraction in [0.0,.35,.65,.85,1.0]:
   GardenPlantGrowth.apply(model,data,fraction,812+id,Vector3.ONE)
   var growth=model.get_node_or_null("GrowthStages")
   check(growth!=null,"Growth assets missing: "+data.name)
   if growth==null:continue
   var seedling=growth.find_child("Seedling*",true,false)
   var juvenile=growth.find_child("Juvenile*",true,false)
   var buds=growth.find_child("Buds*",true,false)
   check(seedling!=null and juvenile!=null and buds!=null,"Growth organs missing: "+data.name)
   if seedling==null or juvenile==null or buds==null:continue
   check(seedling.visible==(fraction<.20),"Seedling stage wrong: "+data.name)
   check(juvenile.visible==(fraction>=.20 and fraction<.52),"Juvenile stage wrong: "+data.name)
   check(buds.visible==(fraction>=.52 and fraction<.78),"Bud stage wrong: "+data.name)
   check(model.get_node("MatureFoliage").visible==(fraction>=.52),"Mature foliage stage wrong: "+data.name)
   check(model.get_node("Bloom").visible==(fraction>=.78),"Flowering stage wrong: "+data.name)
   check(model.get_node("Bloom").scale==Vector3.ONE,"Flower cluster scaled away from its stem")
   if fraction>=.78:inspect_attachments(model.get_node("Bloom"),roundf(lerpf(.48,1.0,clampf((fraction-.78)/.22,0,1))*32)/32)
   if fraction>=.52 and fraction<.78:inspect_attachments(buds,roundf(lerpf(.65,1.0,clampf((fraction-.52)/.26,0,1))*32)/32)
  # Dense gardens must refresh batches when a flower opens within one stage.
  for fraction in [.58,.83]:
   model.set_meta("growth_fraction",fraction)
   var batches=GardenPlantBatches.new()
   batches.garden={"catalogue":catalogue}
   batches.active=true
   batches.dirty=false
   batches.changing({"id":id,"node":model,"age":(fraction+.04)*data.days})
   check(batches.dirty,"Dense garden retained a stale flower/bud size: "+data.name)
   batches.free()
  model.free()
 check(counts=={"Orchids":10,"Wildflowers":15,"Cottage flowers":25,"Flowering bushes":20},"Approved flower group counts changed")
 # Exercise the existing save format with both legacy and boundary new IDs.
 var garden=SaveGarden.new()
 root.add_child(garden)
 garden.SAVE_PATH="user://flower-additions-test.json"
 garden.plant_root=Node3D.new()
 garden.add_child(garden.plant_root)
 garden.climate=GardenClimate.new()
 garden.add_child(garden.climate)
 garden.player=CharacterBody3D.new()
 garden.add_child(garden.player)
 var selected_ids=[0,148,190,217]
 for index in range(selected_ids.size()):garden.add_plant(selected_ids[index],Vector3(index*2,0,0),0,1,1.0,.35,921+index)
 garden.favourite_plants=[148,217]
 garden.recent_plants=[217,0,190]
 garden.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(garden.SAVE_PATH))
 check(saved.plants.map(func(p):return int(p.id))==selected_ids,"New and legacy plant IDs changed during save")
 check(garden.valid_plant_ids([0,148,217,218])==[0,148,217],"Catalogue boundary validation rejects new plants")
 garden.loaded_data={"version":2,"plants":saved.plants}
 garden.restore_garden()
 check(garden.planted.size()==8,"New and legacy plants failed to restore")
 for index in range(selected_ids.size()):
  var restored=garden.planted[4+index]
  check(restored.id==selected_ids[index] and restored.shape_seed==921+index,"Restored identity or plant appearance changed")
 garden.free()
 print("FLOWER_ADDITIONS_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
