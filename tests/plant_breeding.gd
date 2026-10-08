extends SceneTree

class TestGarden:
 extends "res://scripts/garden.gd"
 var messages=[]
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass
 func refresh_ui() -> void:pass
 func refresh_sidebar() -> void:pass
 func update_hud() -> void:pass
 func refresh_wildlife() -> void:pass
 func resume_controls() -> void:pass
 func toast(message: String) -> void:
  messages.append(message)
  if workshop_open:workshop_notice=message
 func set_mode(value: String, _capture: bool=true) -> void:mode=value

var failures=[]

func _initialize() -> void:
 create_timer(180).timeout.connect(func():push_error("Breeding regression timed out");quit(1))
 call_deferred("verify")
func check(value: bool, message: String) -> void:
 if not value:failures.append(message)

func material_roles(g, node: Node, f: Dictionary, counts: Dictionary) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var original=node.mesh.surface_get_material(surface)
   var material=node.get_active_material(surface)
   var role=GardenCultivarAppearance.role(original)
   if not material is ShaderMaterial:continue
   if role>0 and (role!=1 or int(f.foliage)>0):
    counts["changed"]+=1
    check(int(material.get_shader_parameter("cultivar_role"))==role,"Cultivar did not reach a leaf or flower surface")
    for key in ["leaf_texture","leaf_normal","leaf_roughness"]:
     if key=="leaf_texture":check(material.get_shader_parameter(key)==original.albedo_texture,"Cultivar erased colour texture")
     elif key=="leaf_normal":check(material.get_shader_parameter(key)==original.normal_texture,"Cultivar erased normal texture")
     else:check(material.get_shader_parameter(key)==original.roughness_texture,"Cultivar erased roughness texture")
   else:
    counts["unchanged"]+=1
    check(material.get_shader_parameter("cultivar_role")==null or material.get_shader_parameter("cultivar_role")==0,"Cultivar recoloured stems, roots or pollen")
 for child in node.get_children():material_roles(g,child,f,counts)

func verify() -> void:
 var g=TestGarden.new();root.add_child(g)
 g.SAVE_PATH="user://plant-breeding-test.json"
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.object_root=Node3D.new();g.add_child(g.object_root)
 g.ui=CanvasLayer.new();g.add_child(g.ui)
 g.side_panel=PanelContainer.new();g.ui.add_child(g.side_panel);g.side_panel.hide()
 g.player=CharacterBody3D.new();g.add_child(g.player)
 g.climate=GardenClimate.new();g.add_child(g.climate)
 g.coins=200;g.unlocked_plants=range(g.catalogue.size())
 g.settings.reduced_motion=true;g.workshop_state.resources.starter_mix=20
 g.add_object("potting_bench",Vector3(-4,0,1),75)
 var bench=g.objects.back()
 check(GardenPlantBreeding.PROFILES.size()==28,"First collection must support 28 species")
 # A guaranteed discovery, exactly one admission per growing specimen.
 var p=g.add_plant(148,Vector3.ZERO,0,5,1.0,0,293)
 GardenPlantBreeding.observe(g,p)
 check(p.has("form_uid"),"First eligible specimen did not reveal a discovery")
 var uid=str(p.get("form_uid",""));var f=GardenPlantBreeding.form(g,uid)
 if f.is_empty():quit(1);return
 check(int(f.foliage)>0 and int(g.breeding_state.discoveries)==1,"First discovery is not a visible foliage variation")
 var before=JSON.stringify(g.breeding_state)
 for i in range(12):GardenPlantBreeding.observe(g,p)
 check(JSON.stringify(g.breeding_state)==before,"Repeated mornings rerolled a specimen")
 check(not GardenPlantBreeding.propagate(g,bench,uid),"An unobserved flower form was propagated")
 p.age=14;GardenPlantBreeding.observe(g,p)
 check(f.observed,"Flowering did not reveal the full selection")
 # Attached flowers and materials retain all source maps through every stage.
 for amount in [0.0,.35,.65,.85,1.0]:
  p.age=14*amount;g.refresh_plant(p,false)
  var counts={"changed":0,"unchanged":0}
  material_roles(g,p.node,f,counts)
  check(counts.changed>0 and counts.unchanged>0,"Stage has no marked organs or no unaffected organs")
 p.age=14;g.refresh_plant(p,false)
 # Every supported species must keep its tissue maps and unaffected structural
 # organs as its leaf/flower markings pass through all five growth stages.
 for species in GardenPlantBreeding.PROFILES:
  var record=GardenPlantBreeding.create(g,species,{"bloom":[1,2],"pattern":[GardenPlantBreeding.PROFILES[species][2][0],0],"habit":[1,1]},0 if GardenPlantBreeding.PROFILES[species][0]=="Seed-grown selection" else 2,31)
  var sample=g.add_plant(species,Vector3(8,0,0),0,0,1.0,0,31,record)
  for amount in [0.0,.35,.65,.85,1.0]:
   sample.age=float(g.catalogue[species].days)*amount;g.refresh_plant(sample,false)
   var counts={"changed":0,"unchanged":0}
   material_roles(g,sample.node,GardenPlantBreeding.form(g,record),counts)
   check(counts.changed>0,"Missing cultivar tissues at stage "+str(amount)+" for "+g.catalogue[species].name)
  g.planted.erase(sample);sample.node.free();sample.marker.free()
 var parent_record=GardenContainers.record(p)
 var balance=g.coins
 check(GardenPlantBreeding.propagate(g,bench,uid),"Propagation did not start")
 check(g.coins==balance and int(g.workshop_state.resources.starter_mix)==19,"Propagation charged the wrong supplies")
 check(p.age==parent_record.age and p.water==parent_record.water,"Propagation consumed or reset the parent")
 g.day=2;GardenPlantBreeding.morning(g)
 check(g.breeding_state.nursery.is_empty(),"Propagation completed before its due morning")
 # Packing/removing a station must not orphan its growing selections.
 g.objects.erase(bench);g.day=3;GardenPlantBreeding.morning(g)
 check(g.breeding_state.nursery.size()==1,"Removing a bench lost an experiment")
 check(not GardenPlantBreeding.register(g,0,"   "),"Empty cultivar name accepted")
 check(GardenPlantBreeding.register(g,0,"Silver Lantern"),"Established form could not be registered")
 check(f.registered and f.name=="Silver Lantern","Registration lost the name or permanent unlock")
 g.objects.append(bench)
 var b=g.add_plant(148,Vector3(2,0,0),0,14,1.0,0,938)
 var b_uid=GardenPlantBreeding.snapshot(g,b)
 check(not GardenPlantBreeding.breed(g,bench,uid,uid),"A specimen was crossed with itself")
 var other=g.add_plant(198,Vector3(4,0,0),0,float(g.catalogue[198].days),1.0,0,833)
 var other_uid=GardenPlantBreeding.snapshot(g,other)
 check(not GardenPlantBreeding.breed(g,bench,uid,other_uid),"Different species crossed")
 check(GardenPlantBreeding.breed(g,bench,uid,b_uid),"Compatible same-species cross failed")
 var job=g.breeding_state.jobs.back()
 check(job.forms.size()==4,"Cross did not produce a four-seedling tray")
 var genes=[]
 for child_uid in job.forms:
  var child=GardenPlantBreeding.form(g,child_uid);genes.append(child.genes.duplicate(true))
  check(child.parents==[uid,b_uid] and child.generation==1,"Parentage or generation was lost")
  check(child.foliage==0 and not child.observed,"Seed offspring inherited a propagation-only sport or revealed flowers early")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 var kinds=g.furniture.map(func(item):return str(item.kind))
 check(GardenSaveFormat.valid(saved,g.catalogue.size(),kinds),"Valid breeding save rejected")
 check(GardenSaveFormat.read(JSON.stringify(saved).to_utf8_buffer(),g.catalogue.size(),kinds).has("data"),"Downloaded cultivar save cannot be uploaded")
 GardenPlantBreeding.restore(g,saved)
 for i in range(job.forms.size()):check(GardenPlantBreeding.form(g,job.forms[i]).genes==genes[i],"Reload rerolled a breeding outcome")
 # Reloaded dictionaries are fresh, not the old references.
 f=GardenPlantBreeding.form(g,uid)
 g.day=6;GardenPlantBreeding.morning(g)
 check(g.breeding_state.nursery.size()==4,"Tray did not complete on its due morning")
 check(not GardenPlantBreeding.register(g,0,"Too early"),"Unflowered seedling was registered directly")
 GardenPlantBreeding.place_nursery(g,0)
 check(g.workshop_state.nursery.size()==1 and g.nursery_placing==0,"Ready seedling did not enter safe stored placement")
 var stored=g.workshop_state.nursery[0].duplicate(true)
 stored.pos=[3,0]
 var grown=GardenContainers.restore_record(g,stored)
 check(grown.form_uid==stored.form_uid and grown.breeding_checked,"Restoring a seedling lost its inheritance")
 grown.age=float(g.catalogue[grown.id].days);GardenPlantBreeding.observe(g,grown)
 var descendant=GardenPlantBreeding.of_plant(g,grown)
 check(descendant.observed,"Grown offspring did not reveal its flowers")
 check(GardenPlantBreeding.propagate(g,bench,descendant.uid),"Selected offspring could not be preserved")
 g.day=8;GardenPlantBreeding.morning(g)
 check(GardenPlantBreeding.register(g,g.breeding_state.nursery.size()-1,"Morning Mist"),"Next-generation cultivar could not be named")
 GardenContainers.store(g,grown)
 var packed=g.workshop_state.nursery.back()
 check(packed.form_uid==descendant.uid,"Packing lost a cultivar")
 # Clones keep their height and genotype, but a fresh shape arrangement.
 g.selected_cultivar=uid
 var clone=g.add_plant(148,Vector3(-2,0,0),0,0,0,0,103)
 GardenPlantBreeding.apply_selection(g,clone)
 check(clone.form_uid==uid and clone.height_factor==1.0,"Custom planting lost a form or added random height drift")
 clone.age=14;g.refresh_plant(clone,false)
 check(is_equal_approx(clone.node.scale.y,GardenPlantBreeding.height_factor(f)),"Cultivar height does not match the collection")
 # Clone tissues must share a material when dense batching is enabled.
 for plant in [p,clone]:
  plant.node.set_meta("batch_shape",true);GardenArt.add_leaf_wind(plant.node);g.refresh_plant(plant,false)
 var left=p.node.get_node("MatureFoliage").find_children("*","MeshInstance3D",true,false)
 var right=clone.node.get_node("MatureFoliage").find_children("*","MeshInstance3D",true,false)
 for i in range(left.size()):
  for surface in range(left[i].mesh.get_surface_count()):
   check(left[i].get_active_material(surface)==right[i].get_active_material(surface),"Cloned cultivar tissues broke dense rendering batches")
 var batches=GardenPlantBatches.new();g.add_child(batches);batches.garden=g;batches.active=true
 batches.select(p.node);batches.select(clone.node);batches.select(null)
 var marked={"changed":0,"unchanged":0};material_roles(g,p.node,f,marked)
 check(marked.changed>0,"Dense garden selection erased cultivar markings")
 batches.free()
 var before_count=g.catalogue.size()
 g.category="All";g.collection_filters.group="My cultivars"
 var entries=GardenSeedCollection.matching(g)
 check(entries.size()==2 and g.catalogue.size()==before_count,"Cultivars altered numeric species IDs or vanished from their collection")
 f.favourite=true;g.collection_filters.view="Favourites"
 check(GardenSeedCollection.matching(g).size()==1,"Cultivar favourites use base-species favourites")
 g.collection_filters.view="All plants";g.collection_filters.sort="Height: high to low"
 entries=GardenSeedCollection.matching(g)
 check(float(entries[0].height)>=float(entries[1].height),"Cultivars do not sort by their actual mature height")
 f.archived=true;check(GardenSeedCollection.matching(g).size()==1,"Archiving did not hide a cultivar")
 f.archived=false;g.save_game();saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 check(GardenSaveFormat.valid(saved,g.catalogue.size(),kinds),"Cultivar packing save failed")
 var broken=saved.duplicate(true);broken.breeding.forms[uid].genes.bloom=[999,0]
 check(not GardenSaveFormat.valid(broken,g.catalogue.size(),kinds),"Unsafe pigment index accepted")
 broken=saved.duplicate(true);broken.breeding.forms[uid].parents=[uid,uid]
 check(not GardenSaveFormat.valid(broken,g.catalogue.size(),kinds),"Cyclic ancestry accepted")
 broken=saved.duplicate(true);broken.plants[0].form_uid="missing"
 check(not GardenSaveFormat.valid(broken,g.catalogue.size(),kinds),"Dangling plant cultivar accepted")
 broken=saved.duplicate(true);broken.plants[0].id=198
 check(not GardenSaveFormat.valid(broken,g.catalogue.size(),kinds),"Cultivar attached to wrong species accepted")
 var legacy=saved.duplicate(true);legacy.erase("breeding");legacy.version=2
 for plant in legacy.plants:plant.erase("form_uid");plant.erase("breeding_checked")
 legacy.workshop.nursery=[]
 check(GardenSaveFormat.valid(legacy,g.catalogue.size(),kinds),"Legacy gardens became incompatible")
 # Real modal controls at desktop, portrait phone and short landscape sizes.
 for size in [Vector2i(1280,800),Vector2i(390,844),Vector2i(320,568),Vector2i(667,375)]:
  root.size=size
  root.content_scale_size=size
  for tab in GardenBreedingUI.TABS:
   g.breeding_tab=tab;GardenWorkshop.open(g,bench.uid)
   for frame in range(3):await process_frame
   GardenWorkshop.fit(g)
   check(Rect2(Vector2.ZERO,Vector2(size)).grow(1).encloses(g.welcome.get_global_rect()),"Breeding modal exceeds viewport at "+str(size)+" / "+tab)
   check(g.welcome.find_child("BreedingTabs",true,false)!=null,"Bench tabs missing")
   if tab=="Breed":check(g.welcome.find_child("BreedingParentA",true,false)!=null,"Parent selector missing")
   if tab=="My cultivars":
    var picker=g.welcome.find_child("CultivarPicker",true,false) as OptionButton
    check(picker!=null and picker.item_count==2,"Empty library search hides registered cultivars")
   GardenWorkshop.close(g)
 g.breeding_query="No cultivar has this name"
 GardenBreedingUI.open_library(g)
 await process_frame
 var empty_picker=g.welcome.find_child("CultivarPicker",true,false) as OptionButton
 check(empty_picker.disabled and empty_picker.get_item_text(0)=="No matching cultivars","Empty cultivar search uses an unrelated species hint")
 check(g.welcome.find_child("CultivarPreview",true,false)==null,"Empty search still displays a previously selected cultivar")
 GardenWorkshop.close(g)
 g.free()
 await process_frame
 print("PLANT_BREEDING_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
