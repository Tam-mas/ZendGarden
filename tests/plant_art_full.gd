extends "res://tests/plant_art_sample.gd"

# Reuse the sample's material and save/restore assertions. This fixture loads
# actual imported assets without changing the renderer or starting a garden UI.
const CULTIVAR_IDS=[148,153,158,177,190,199,209]
var checked_attachment_vertices=0
var checked_succulents=0

func _initialize() -> void:
 create_timer(180).timeout.connect(func():push_error("Full plant art regression timed out");quit(1))
 call_deferred("verify")

func set_stage(model: Node3D, data: Dictionary, fraction: float) -> void:
 var size=Vector3(.92,1.1,.96)*lerpf(.12,1.0,fraction)
 model.scale=size
 GardenPlantGrowth.apply(model,data,fraction,1667,size)

func verify_imported_attachments(node: Node, label: String) -> void:
 for organ in meshes(node):
  for surface in range(organ.mesh.get_surface_count()):
   var arrays=organ.mesh.surface_get_arrays(surface)
   var positions=arrays[Mesh.ARRAY_VERTEX]
   var uv=arrays[Mesh.ARRAY_TEX_UV2]
   var colors=arrays[Mesh.ARRAY_COLOR]
   check(uv!=null and uv.size()==positions.size(),label+": incomplete imported attachment UVs")
   check(colors!=null and colors.size()==positions.size(),label+": incomplete imported attachment depths")
   if uv==null or colors==null or uv.size()!=positions.size() or colors.size()!=positions.size():continue
   for i in range(positions.size()):
    var depth=(roundf(colors[i].r*255.0)*256.0+roundf(colors[i].g*255.0))/65535.0*16.0-8.0
    var anchor=Vector3(uv[i].x,1.0-uv[i].y,depth)
    if not positions[i].is_finite() or not anchor.is_finite():
     check(false,label+": non-finite imported attachment")
     break
    checked_attachment_vertices+=1

func verify_growth_amount(node: Node, expected: float, label: String) -> void:
 for organ in meshes(node):
  for surface in range(organ.mesh.get_surface_count()):
   var material=organ.get_active_material(surface)
   if not material is ShaderMaterial:continue # The inherited check reports this.
   var actual=float(material.get_shader_parameter("fruit_growth"))
   # Growth uses shared discrete sizes; allow half a step of quantization.
   check(absf(actual-expected)<=1.0/64.0+.00001,label+": local organ growth does not track its age")

func verify_authored_stages(model: Node3D, label: String) -> void:
 var stages=model.get_node_or_null("GrowthStages")
 if stages==null:return
 var seedling=stages.find_child("Seedling*",true,false)
 var juvenile=stages.find_child("Juvenile*",true,false)
 if seedling==null or juvenile==null:return
 var young_meshes=meshes(seedling)
 var older_meshes=meshes(juvenile)
 check(not young_meshes.is_empty() and not older_meshes.is_empty(),label+": authored early foliage is empty")
 if young_meshes.is_empty() or older_meshes.is_empty():return
 check(young_meshes[0].mesh!=older_meshes[0].mesh,label+": both early stages share one mesh")
 var mature_meshes=meshes(model.get_node("MatureFoliage"))
 check(not mature_meshes.is_empty(),label+": mature foliage is empty")
 for early in young_meshes+older_meshes:
  for mature in mature_meshes:
   check(early.mesh!=mature.mesh,label+": early foliage reuses the mature mesh")
 var buds=stages.find_child("Buds*",true,false)
 if buds!=null:verify_imported_attachments(buds,label+" buds")
 verify_imported_attachments(model.get_node("Bloom"),label+" flowers/fruit")

func verify_stage(model: Node3D, data: Dictionary, fraction: float) -> void:
 var label=str(data.name)+" at "+str(fraction)
 var stages=model.get_node_or_null("GrowthStages")
 check(stages!=null,label+": growth assets missing")
 if stages==null:return
 var seedling=stages.find_child("Seedling*",true,false)
 var juvenile=stages.find_child("Juvenile*",true,false)
 var buds=stages.find_child("Buds*",true,false)
 check(seedling!=null and juvenile!=null and buds!=null,label+": an authored stage is missing")
 if seedling==null or juvenile==null or buds==null:return
 check(seedling.visible==(fraction<.20),label+": incorrect seedling visibility")
 check(juvenile.visible==(fraction>=.20 and fraction<.52),label+": incorrect juvenile visibility")
 check(buds.visible==(fraction>=.52 and fraction<.78),label+": incorrect bud visibility")
 check(not meshes(buds).is_empty(),label+": bud stage has no organs")
 check(buds.scale.is_equal_approx(Vector3.ONE),label+": buds shrink around the ground origin")
 verify_attachments(buds,label+" buds",fraction>=.52 and fraction<.78)
 verify_growth_amount(buds,lerpf(.65,1.0,clampf((fraction-.52)/.26,0,1)),label+" buds")
 var mature=model.get_node("MatureFoliage")
 var bloom=model.get_node("Bloom")
 check(mature.visible==(fraction>=.52),label+": incorrect mature foliage visibility")
 check(bloom.visible==(fraction>=.78),label+": incorrect bloom visibility")
 check(bloom.scale.is_equal_approx(Vector3.ONE),label+": flowers shrink around the ground origin")
 # Foliage-only species intentionally have an empty Bloom container.
 verify_attachments(bloom,label+" flowers/fruit",fraction>=.78 and fraction<1.0)
 verify_growth_amount(bloom,lerpf(.48,1.0,clampf((fraction-.78)/.22,0,1)),label+" flowers/fruit")
 var early=lerpf(.70,1.15,fraction/.20) if fraction<.20 else lerpf(.65,1.25,clampf((fraction-.20)/.32,0,1))
 for organ in [seedling,juvenile]:
  check((organ.scale*model.scale).is_equal_approx(Vector3.ONE*early),label+": early foliage no longer keeps its authored proportions")
 if int(data.id)>=116 and int(data.id)<=135:verify_rigid(model,label)
 checked_stages+=1

func verify() -> void:
 var garden=GardenFixture.new()
 check(garden.catalogue.size()==218,"Full collection no longer contains 218 species")
 for id in range(garden.catalogue.size()):
  var data=garden.catalogue[id]
  check(bool(data.get("attached_bloom",false)),str(data.name)+": catalogue omits attached growth")
  var model=GardenArt.plant(data)
  root.add_child(model)
  for fraction in FRACTIONS:
   set_stage(model,data,fraction)
   verify_stage(model,data,fraction)
   if fraction==0.0:verify_authored_stages(model,str(data.name))
  if id>=116 and id<=135:checked_succulents+=1
  model.free()
  await process_frame

 # Saved orchid, wildflower, bulb and shrub cultivars retain tissue roles,
 # patterns and maps while their independently attached buds/flowers grow.
 for id in CULTIVAR_IDS:
  var profile=GardenPlantBreeding.PROFILES[id]
  var foliage=0 if profile[0]=="Seed-grown selection" else 2
  var uid=GardenPlantBreeding.create(garden,id,{"bloom":[1,2],"pattern":[profile[2][0],0],"habit":[1,1]},foliage,317)
  var form=GardenPlantBreeding.form(garden,uid)
  form.registered=true;form.name="Full art selection"
  var saved=JSON.parse_string(JSON.stringify({"breeding":garden.breeding_state}))
  check(GardenPlantBreeding.valid_save(saved),str(id)+": registered cultivar fixture is not a valid save")
  var restored=GardenFixture.new()
  GardenPlantBreeding.restore(restored,saved)
  var saved_form=GardenPlantBreeding.form(restored,uid)
  check(saved_form.name==form.name and saved_form.registered,str(id)+": registered identity lost")
  var model=GardenArt.plant(garden.catalogue[id])
  var loaded_model=GardenArt.plant(restored.catalogue[id])
  root.add_child(model);root.add_child(loaded_model)
  for fraction in FRACTIONS:
   set_stage(model,garden.catalogue[id],fraction)
   set_stage(loaded_model,restored.catalogue[id],fraction)
   GardenCultivarAppearance.apply(garden,model,form)
   GardenCultivarAppearance.apply(restored,loaded_model,saved_form)
   var label=str(id)+" saved cultivar at "+str(fraction)
   var before=verify_cultivar(model,form,label)
   var after=verify_cultivar(loaded_model,saved_form,label+" reloaded")
   check(not before.is_empty() and not after.is_empty(),label+": appearance verification did not complete")
   check(before==after,label+": reloading changes colour, pattern or attached growth")
   verify_stage(loaded_model,restored.catalogue[id],fraction)
   checked_cultivar_stages+=1
  var roles=bloom_roles(loaded_model)
  check(not roles[2].is_empty() or not roles[3].is_empty(),str(id)+": cultivar has no flower-colour tissue")
  if id in [148,153]:check(not roles[3].is_empty(),str(id)+": orchid lip lost its cultivar role")
  if foliage>0:
   var leaf_found=false
   for organ in meshes(loaded_model.get_node("MatureFoliage")):
    for surface in range(organ.mesh.get_surface_count()):
     leaf_found=leaf_found or GardenCultivarAppearance.role(organ.mesh.surface_get_material(surface))==1
   check(leaf_found,str(id)+": cultivar has no marked leaf tissue")
  model.free();loaded_model.free()
  await process_frame
 check(checked_stages==218*5+CULTIVAR_IDS.size()*5,"Some plant growth cases did not complete")
 check(checked_succulents==20,"Some succulent rigidity cases were skipped")
 print("PLANT_ART_FULL_RESULT: ",JSON.stringify({"plants":garden.catalogue.size(),"growth_stages":checked_stages,"cultivar_reload_stages":checked_cultivar_stages,"succulents":checked_succulents,"attachment_vertices":checked_attachment_vertices,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
