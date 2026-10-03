extends SceneTree

class ReviewGarden:
 extends "res://scripts/garden.gd"
 func _ready() -> void: pass
 func _process(_delta: float) -> void: pass

var failures: Array=[]

func check(condition: bool, note: String) -> void:
 if not condition: failures.append(note)

func shape_value(node: Node):
 if node is MeshInstance3D:
  if RenderingServer.get_current_rendering_method()=="gl_compatibility":return node.get_active_material(0).get_shader_parameter("plant_shape")
  return node.get_instance_shader_parameter("plant_shape")
 for child in node.get_children():
  var value=shape_value(child)
  if value!=null:return value
 return null

func _initialize() -> void:
 call_deferred("verify")

func verify() -> void:
 var g=ReviewGarden.new()
 root.add_child(g)
 g.SAVE_PATH="user://plant-improvements-test.json"
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.ui=CanvasLayer.new();g.add_child(g.ui)
 g.make_ui()
 g.climate=GardenClimate.new();g.add_child(g.climate)
 g.player=CharacterBody3D.new();g.add_child(g.player)
 g.day=1
 g.active_tab="Seeds"
 g.refresh_sidebar()
 var search: LineEdit=g.list_box.get_node("SeedSearch")
 search.grab_focus()
 search.text="jasmine";search.text_changed.emit("jasmine")
 check(g.category=="All" and GardenSeedCollection.matching(g).size()==3,"Cross-category search missed jasmine")
 check(search==g.list_box.get_node("SeedSearch") and search.has_focus(),"Search loses focus while typing")
 g.collection_query="";g.category="All"
 g.collection_filters.season="Winter"
 for data in GardenSeedCollection.matching(g):check(data.seasons.is_empty() or "Winter" in data.seasons,"Season filter includes dormant species")
 g.collection_filters=g.default_collection_filters()
 g.collection_filters.light="Shade"
 for data in GardenSeedCollection.matching(g):check(data.condition in ["shade","any"],"Light filter includes sun-only plants")
 g.collection_filters=g.default_collection_filters()
 g.collection_filters.height="Tall (2 m+)"
 for data in GardenSeedCollection.matching(g):check(data.height>=2,"Mature height filter incorrect")
 g.collection_filters=g.default_collection_filters()
 g.collection_filters.wildlife="Native birds"
 for data in GardenSeedCollection.matching(g):check(data.animal=="native birds","Wildlife filter incorrect")
 g.collection_filters=g.default_collection_filters()
 g.collection_filters.view="Favourites"
 GardenSeedCollection.toggle_favourite(g,60)
 check(GardenSeedCollection.matching(g).size()==1 and g.selected==0,"Favourite changes seed selection or fails filter")
 g.collection_filters.view="Recently planted"
 for id in [0,60,0]:GardenSeedCollection.record_planting(g,id)
 check(g.recent_plants==[0,60] and GardenSeedCollection.matching(g)[0].id==0,"Recent planting order or de-duplication incorrect")
 g.collection_query="not-a-plant";GardenSeedCollection.update_cards(g)
 check(g.list_box.get_node("PlantCards").get_child(0) is Label,"Empty search lacks recovery guidance")
 g.collection_query="";g.collection_filters=g.default_collection_filters()
 for data in g.catalogue:
  var model=GardenArt.plant(data);g.add_child(model)
  for fraction in [0.0,.3,.6,.85,1.0]:
   var size=Vector3.ONE*lerpf(.12,1,fraction)
   model.scale=size
   GardenPlantGrowth.apply(model,data,fraction,191,size)
   var stages=model.get_node_or_null("GrowthStages")
   check(stages!=null,"Growth assets missing: "+data.name)
   if stages:
    check(stages.find_child("Seedling*",true,false).visible==(fraction<.2),"Seedling visibility incorrect: "+data.name)
    check(stages.find_child("Juvenile*",true,false).visible==(fraction>=.2 and fraction<.52),"Juvenile visibility incorrect: "+data.name)
    check(stages.find_child("Buds*",true,false).visible==(fraction>=.52 and fraction<.78),"Bud visibility incorrect: "+data.name)
   check(model.get_node("MatureFoliage").visible==(fraction>=.52),"Mature foliage visibility incorrect: "+data.name)
   check(model.get_node("Bloom").visible==(fraction>=.78),"Flower/fruit visibility incorrect: "+data.name)
  model.queue_free()
  await process_frame
 var p=g.add_plant(0,Vector3.ZERO,0,1,1.1,.75,8123)
 var tree=g.add_plant(29,Vector3(.2,0,.2),0,100,1,0,431)
 var first_shape=shape_value(p.node)
 GardenPlantGrowth.variation(p.node,8124,g.catalogue[0].height)
 check(shape_value(p.node)!=first_shape,"Different seeds do not change plant shape")
 GardenPlantGrowth.variation(p.node,8123,g.catalogue[0].height)
 check(shape_value(p.node)==first_shape,"Shape variation is not repeatable")
 var neighbour=GardenArt.plant(g.catalogue[0])
 g.add_child(neighbour)
 GardenPlantGrowth.variation(neighbour,9991,g.catalogue[0].height)
 check(shape_value(p.node)==first_shape and shape_value(neighbour)!=first_shape,"Plant variation changed a neighbour's material")
 neighbour.queue_free()
 check(g.growth_conditions(p)==.6,"Tree shade stopped affecting sun plants")
 check("shaded by Silver birch" in GardenPlantInspector.growth_context(g,p).reason,"Shade explanation lacks tree identity")
 g.day=25
 check(g.growth_conditions(p)==0 and "Resting until" in GardenPlantInspector.growth_context(g,p).reason,"Dormancy explanation missing")
 g.objects.append({"kind":"greenhouse","pos":Vector3.ZERO})
 check(g.growth_conditions(p)==1 and "greenhouse" in GardenPlantInspector.growth_context(g,p).reason,"Greenhouse context incorrect")
 g.objects.clear()
 g.selected_layer=3
 check(g.target_plant(Vector3.ZERO)==g.planted.find(tree),"Layer targeting ignores canopy")
 g.selected_layer=1
 check(g.target_plant(Vector3.ZERO)==g.planted.find(p),"Layer targeting ignores flower")
 g.mode="move";g.hover_target=g.planted.find(p);g.hover_valid=true
 GardenPlantInspector.update(g)
 check(g.highlighted_plant==p.node and g.inspector_panel.visible,"Target highlight/card not shown")
 g.hover_valid=false;GardenPlantInspector.update(g)
 check(g.highlighted_plant==null and not g.inspector_panel.visible,"Target highlight persists after aim leaves plant")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(int(saved.plants[0].shape_seed)==8123 and is_equal_approx(float(saved.plants[0].orientation),.75),"Plant appearance missing from save")
 check(g.valid_plant_ids(saved.favourite_plants)==[60] and g.valid_plant_ids(saved.recent_plants)==[0,60],"Collection preferences missing from save")
 var before=g.planted.size()
 g.loaded_data={"version":2,"plants":[saved.plants[0]]}
 g.restore_garden()
 var restored=g.planted.back()
 check(g.planted.size()==before+1 and restored.shape_seed==p.shape_seed and is_equal_approx(restored.node.rotation.y,p.node.rotation.y),"Reload changes individual appearance")
 var legacy={"id":0,"pos":[0,0],"plot":0,"age":1,"water":2,"stress":0}
 g.loaded_data={"version":2,"plants":[legacy]}
 g.restore_garden()
 var old=g.planted.back()
 check(old.shape_seed==g.legacy_shape_seed(legacy),"Legacy save lacks stable variation")
 for plant in g.planted:
  plant.node.queue_free();plant.marker.queue_free()
 g.queue_free()
 await process_frame
 if "--review" in OS.get_cmdline_user_args(): await review()
 print("PLANT_IMPROVEMENTS_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)

func review() -> void:
 var stage=Node3D.new();root.add_child(stage)
 var environment=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("29362b")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color.WHITE
 environment.environment.ambient_light_energy=.7
 stage.add_child(environment)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-25,0);stage.add_child(sun)
 var camera=Camera3D.new();stage.add_child(camera)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true
 var directory="res://captures/plant-improvements"
 DirAccess.make_dir_recursive_absolute(directory)
 for id in [0,20,49,29,68,78,51,105]:
  var row=Node3D.new();stage.add_child(row)
  var data=GardenCatalogue.plants()[id]
  var spacing=maxf(1.0,data.height*.62)
  var fractions=[0.0,.35,.65,.87,1.0]
  for i in range(5):
   var model=GardenArt.plant(data)
   row.add_child(model)
   model.position=Vector3((i-2)*spacing,0,0)
   var size=Vector3.ONE*lerpf(.12,1,fractions[i])
   model.scale=size;model.rotation.y=.35
   GardenPlantGrowth.apply(model,data,fractions[i],137+i*17,size)
  camera.size=spacing*5.7
  camera.position=Vector3(0,maxf(1.2,data.height)*.85,maxf(1.2,data.height)*3)
  camera.look_at(Vector3(0,data.height*.42,0))
  for i in range(6): await process_frame
  await RenderingServer.frame_post_draw
  get_root().get_texture().get_image().save_png(directory+"/growth-%02d.png"%id)
  row.free()
 stage.free()
