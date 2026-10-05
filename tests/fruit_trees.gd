extends SceneTree
# Exercise actual imported attachment data, growth, previews and batch materials.

class TestGarden:
 extends "res://scripts/garden.gd"
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass
 func refresh_ui() -> void:pass
 func refresh_wildlife() -> void:pass
 func update_hud() -> void:pass
 func resume_controls() -> void:pass
 func toast(_message: String) -> void:pass

var failures=[]
var attachment_count=0

func check(condition: bool, note: String) -> void:
 if not condition:failures.append(note)

func _initialize() -> void:
 call_deferred("verify")

func attachments(mesh_node: MeshInstance3D) -> Dictionary:
 var sites={}
 for surface in range(mesh_node.mesh.get_surface_count()):
  var arrays=mesh_node.mesh.surface_get_arrays(surface)
  var positions: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var uv2=arrays[Mesh.ARRAY_TEX_UV2]
  var colors=arrays[Mesh.ARRAY_COLOR]
  check(uv2!=null and colors!=null,"Missing imported attachment channels: "+str(mesh_node.name))
  if uv2==null or colors==null:continue
  for i in range(positions.size()):
   var depth: Color=colors[i]
   var anchor=Vector3(uv2[i].x,1.0-uv2[i].y,(depth.r*256.0+depth.g)*255.0/65535.0*16.0-8.0)
   # Imported surface compression can round the same UV slightly differently.
   var key=anchor
   for previous in sites:
    if previous.distance_squared_to(anchor)<.000004:
     key=previous
     break
   if not sites.has(key):sites[key]={"anchor":anchor,"near":INF,"far":0.0}
   var distance=positions[i].distance_to(anchor)
   sites[key].near=minf(sites[key].near,distance)
   sites[key].far=maxf(sites[key].far,distance)
 for site in sites.values():
  check(site.near<.006,"Fruit stalk detached from encoded branch anchor: "+str(mesh_node.name))
 return sites

func check_materials(node: MeshInstance3D, amount: float) -> void:
 for surface in range(node.mesh.get_surface_count()):
  var material=node.get_active_material(surface)
  check(material is ShaderMaterial,"Fruit lost its growth shader")
  check(material.get_shader_parameter("fruit_anchors")==true,"Fruit attachment shader disabled")
  check(is_equal_approx(float(material.get_shader_parameter("fruit_growth")),roundf(amount*32.0)/32.0),"Incorrect local fruit size")
  check(is_zero_approx(float(material.get_shader_parameter("wind_strength"))),"Fruit attachment sways away from its branch")

func verify() -> void:
 var catalogue=GardenCatalogue.plants()
 for id in GardenPlantGrowth.FRUIT_TREES:
  var model=GardenArt.plant(catalogue[id]);root.add_child(model)
  var fruit=model.find_child("BloomFruit*",true,false) as MeshInstance3D
  check(fruit!=null,"Missing locally growing fruit: "+catalogue[id].name)
  if not fruit:model.free();continue
  var sites=attachments(fruit)
  attachment_count+=sites.size()
  check(sites.size()>=15,"Tree lost most of its fruit: "+catalogue[id].name)
  var smallest=INF;var largest=0.0
  for site in sites.values():
   smallest=minf(smallest,site.far);largest=maxf(largest,site.far)
  check(largest>smallest*1.2,"Fruit sizes are still uniform: "+catalogue[id].name)
  for fraction in [.52,.77,.78,.85,.9,1.0,.6,.9]:
   var size=Vector3(.85,1.1,.85)*(.12+.88*fraction)
   model.scale=size
   GardenPlantGrowth.apply(model,catalogue[id],fraction,8123,size)
   check(model.get_node("Bloom").scale.is_equal_approx(Vector3.ONE),"Fruit positions scaled around the tree origin")
   check_materials(fruit,lerpf(.48,1.0,clampf((fraction-.78)/.22,0,1)))
   var buds=model.find_child("BudsFruit*",true,false) as MeshInstance3D
   check(buds!=null,"Missing branch-attached young fruit")
   if buds:
    check(buds.scale.is_equal_approx(Vector3.ONE),"Young fruit positions scaled around the tree origin")
    check_materials(buds,lerpf(.65,1.0,clampf((fraction-.52)/.26,0,1)))
   GardenPlantInspector.highlight(model,true)
   var outline=fruit.get_active_material(0).next_pass
   check(outline.get_shader_parameter("fruit_anchors")==true,"Outline lost fruit attachments")
   check(outline.get_shader_parameter("fruit_growth")==fruit.get_active_material(0).get_shader_parameter("fruit_growth"),"Outline does not fit growing fruit")
   GardenPlantInspector.highlight(model,false)
  # Preview must preserve local fruit growth and use private ghost materials.
  var g=TestGarden.new()
  g.ghost_material(model)
  check(fruit.get_active_material(0).shader.resource_path.ends_with("leaf_preview.gdshader"),"Fruit preview lost shader")
  check_materials(fruit,lerpf(.48,1.0,(.9-.78)/.22))
  g.free();model.free()
 var g=TestGarden.new();root.add_child(g)
 g.smoke=true;g.expansions={"0":100}
 g.side_panel=PanelContainer.new();g.add_child(g.side_panel)
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.object_root=Node3D.new();g.add_child(g.object_root)
 g.loaded_data={"plants":range(220)}
 g.plant_batches=GardenPlantBatches.new();g.add_child(g.plant_batches);g.plant_batches.setup(g)
 var p=g.add_plant(35,Vector3.ZERO,0,g.catalogue[35].days*.85,1.1,.7,8123)
 var other=g.add_plant(35,Vector3(2,0,0),0,g.catalogue[35].days,1.0,.2,431)
 g.plant_batches.rebuild()
 p.age=g.catalogue[35].days*.93;g.refresh_plant(p,false)
 check(g.plant_batches.dirty,"Batched fruit retained its previous size material")
 g.plant_batches.rebuild()
 for specimen in [p,other]:
  var matched=false
  for member in g.plant_batches.members[specimen.node.get_instance_id()]:
   if str(member.node.name).begins_with("BloomFruit"):
    matched=true
    var material=member.renderer.multimesh.mesh.surface_get_material(0)
    check(material.get_shader_parameter("fruit_growth")==member.node.get_active_material(0).get_shader_parameter("fruit_growth"),"Batch draws fruit at another tree's ripeness")
  check(matched,"Fruit missing from dense-garden batches")
 var flower=GardenArt.plant(catalogue[0]);root.add_child(flower)
 GardenPlantGrowth.apply(flower,catalogue[0],.9,41,Vector3.ONE)
 check(is_equal_approx(flower.get_node("Bloom").scale.x,lerpf(.48,1.0,(.9-.78)/.22)),"Fruit correction changed flower growth")
 flower.free();g.free()
 await process_frame
 print("FRUIT_TREES_RESULT: ",JSON.stringify(failures)," (",attachment_count," attachments)")
 quit(0 if failures.is_empty() else 1)
