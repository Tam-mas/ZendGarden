extends SceneTree

# Exercise the exported sample through the same growth and cultivar paths as
# planted specimens. No world/UI fixture, save file, or renderer setting needed.
class GardenFixture:
 extends RefCounted
 var catalogue=GardenCatalogue.plants()
 var breeding_state=GardenPlantBreeding.initial_state()
 var selected_cultivar=""
 var day=1

const SAMPLE_IDS=[20,30,109,124,148,149,158,174,198,212]
const FRACTIONS=[0.0,.35,.65,.86,1.0]
var failures: Array=[]
var checked_stages=0
var checked_cultivar_stages=0

func _initialize() -> void:
 create_timer(90).timeout.connect(func():push_error("Plant art sample regression timed out");quit(1))
 call_deferred("verify")

func check(value: bool, message: String) -> void:
 if not value:failures.append(message)

func meshes(node: Node) -> Array:
 var result: Array=[]
 if node is MeshInstance3D:result.append(node)
 for child in node.get_children():result.append_array(meshes(child))
 return result

func verify_attachments(node: Node, label: String, partial: bool) -> void:
 for organ in meshes(node):
  for surface in range(organ.mesh.get_surface_count()):
   var arrays=organ.mesh.surface_get_arrays(surface)
   var positions=arrays[Mesh.ARRAY_VERTEX]
   var anchors=arrays[Mesh.ARRAY_TEX_UV2]
   var depth=arrays[Mesh.ARRAY_COLOR]
   check(anchors!=null and anchors.size()==positions.size(),label+": imported attachment coordinates missing")
   check(depth!=null and depth.size()==positions.size(),label+": imported attachment depth missing")
   var material=organ.get_active_material(surface)
   check(material is ShaderMaterial,label+": organ has no growth material")
   if not material is ShaderMaterial:continue
   check(bool(material.get_shader_parameter("fruit_anchors")),label+": attachment channels ignored by growth")
   var amount=float(material.get_shader_parameter("fruit_growth"))
   check(amount>0 and amount<=1,label+": invalid attached growth amount")
   if partial:check(amount<1,label+": developing organ skips attached growth")

func verify_rigid(node: Node, label: String) -> void:
 var surfaces=0
 for organ in meshes(node):
  for surface in range(organ.mesh.get_surface_count()):
   surfaces+=1
   var material=organ.get_active_material(surface)
   check(material is ShaderMaterial,label+": missing succulent material")
   if material is ShaderMaterial:
    check(is_zero_approx(float(material.get_shader_parameter("wind_strength"))),label+": succulent tissue moves like a grass leaf")
 check(surfaces>0,label+": succulent has no surfaces to verify")

func set_stage(model: Node3D, data: Dictionary, fraction: float) -> void:
 var size=Vector3.ONE*lerpf(.12,1.0,fraction)
 model.scale=size
 GardenPlantGrowth.apply(model,data,fraction,1667,size)

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
 var mature=model.get_node("MatureFoliage")
 var bloom=model.get_node("Bloom")
 check(mature.visible==(fraction>=.52),label+": incorrect mature foliage visibility")
 check(bloom.visible==(fraction>=.78),label+": incorrect flower visibility")
 check(bloom.scale.is_equal_approx(Vector3.ONE),label+": flowers shrink around the ground origin")
 if int(data.id)!=30:
  check(not meshes(bloom).is_empty(),label+": flower/panicle geometry missing")
 verify_attachments(bloom,label+" flowers",fraction>=.78 and fraction<1.0)
 if int(data.id)==124:verify_rigid(model,label)
 checked_stages+=1

func bloom_roles(model: Node3D) -> Dictionary:
 var result={1:{},2:{},3:{}}
 for organ in meshes(model.get_node("Bloom")):
  for surface in range(organ.mesh.get_surface_count()):
   var original=organ.mesh.surface_get_material(surface)
   var role=GardenCultivarAppearance.role(original)
   if result.has(role):result[role][original.get_instance_id()]=true
 return result

func verify_cultivar(model: Node3D, form: Dictionary, label: String) -> Array:
 var signature: Array=[]
 var changed=0
 var palette=GardenPlantBreeding.palette(form)
 for organ in meshes(model):
  for surface in range(organ.mesh.get_surface_count()):
   var original=organ.mesh.surface_get_material(surface)
   var material=organ.get_active_material(surface)
   check(material is ShaderMaterial,label+": cultivar lost the plant material")
   if not material is ShaderMaterial:continue
   var role=GardenCultivarAppearance.role(original)
   var role_parameter=material.get_shader_parameter("cultivar_role")
   var active_role=0 if role_parameter==null else int(role_parameter)
   var marked=role>0 and (role!=1 or int(form.foliage)>0)
   check(active_role==(role if marked else 0),label+": cultivar applied to the wrong tissue")
   if marked:
    changed+=1
    check(material.get_shader_parameter("leaf_texture")==original.albedo_texture,label+": cultivar erased the colour map")
    check(material.get_shader_parameter("leaf_normal")==original.normal_texture,label+": cultivar erased the normal map")
    check(material.get_shader_parameter("leaf_roughness")==original.roughness_texture,label+": cultivar erased the roughness map")
    var primary=Color(palette[int(form.genes.bloom[0])])
    var secondary=Color("e8dfbf") if role==1 else Color(palette[int(form.genes.bloom[1])])
    check(material.get_shader_parameter("cultivar_primary").is_equal_approx(primary),label+": saved primary colour changed")
    check(material.get_shader_parameter("cultivar_secondary").is_equal_approx(secondary),label+": saved secondary colour changed")
   signature.append([active_role,material.get_shader_parameter("cultivar_pattern"),
    material.get_shader_parameter("cultivar_primary"),material.get_shader_parameter("cultivar_secondary"),
    material.get_shader_parameter("cultivar_seed"),material.get_shader_parameter("fruit_anchors"),
    material.get_shader_parameter("fruit_growth")])
 check(changed>0,label+": no cultivar tissues were marked")
 return signature

func verify() -> void:
 var garden=GardenFixture.new()
 for id in SAMPLE_IDS:
  var data=garden.catalogue[id]
  var model=GardenArt.plant(data)
  root.add_child(model)
  for fraction in FRACTIONS:
   set_stage(model,data,fraction)
   verify_stage(model,data,fraction)
  if id in [148,149]:
   check(not bloom_roles(model)[3].is_empty(),str(data.name)+": orchid lip no longer accepts its cultivar colour")
  if id in [158,198]:
   check(bloom_roles(model)[2].size()>=2,str(data.name)+": secondary petals no longer accept cultivar colour")
  model.free()
  await process_frame

 # Reconstruct registered selections through the real JSON restoration path.
 # A fresh plant must preserve colours and attachments at every growth stage.
 for id in [148,149,158,198]:
  var uid=GardenPlantBreeding.create(garden,id,{"bloom":[1,2],"pattern":[1,0],"habit":[1,1]},0 if id==158 else 2,317)
  var form=GardenPlantBreeding.form(garden,uid)
  form.registered=true;form.name="Art sample selection"
  var restored=GardenFixture.new()
  GardenPlantBreeding.restore(restored,JSON.parse_string(JSON.stringify({"breeding":garden.breeding_state})))
  var saved_form=GardenPlantBreeding.form(restored,uid)
  check(saved_form.name==form.name and saved_form.registered,str(id)+": registered selection identity lost")
  var model=GardenArt.plant(garden.catalogue[id])
  var loaded_model=GardenArt.plant(restored.catalogue[id])
  root.add_child(model);root.add_child(loaded_model)
  for fraction in FRACTIONS:
   set_stage(model,garden.catalogue[id],fraction)
   set_stage(loaded_model,restored.catalogue[id],fraction)
   GardenCultivarAppearance.apply(garden,model,form)
   GardenCultivarAppearance.apply(restored,loaded_model,saved_form)
   var label=str(id)+" cultivar at "+str(fraction)
   var before=verify_cultivar(model,form,label)
   var after=verify_cultivar(loaded_model,saved_form,label+" after reload")
   check(not before.is_empty() and not after.is_empty(),label+": appearance verification did not complete")
   check(before==after,label+": reload changes tissue colour, pattern, or attached growth")
   verify_attachments(loaded_model.get_node("Bloom"),label+" flowers",fraction>=.78 and fraction<1)
   verify_attachments(loaded_model.get_node("GrowthStages").find_child("Buds*",true,false),label+" buds",fraction>=.52 and fraction<.78)
   checked_cultivar_stages+=1
  model.free();loaded_model.free()
  await process_frame
 print("PLANT_ART_SAMPLE_RESULT: ",JSON.stringify({"plants":SAMPLE_IDS.size(),"growth_stages":checked_stages,"cultivar_reload_stages":checked_cultivar_stages,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
