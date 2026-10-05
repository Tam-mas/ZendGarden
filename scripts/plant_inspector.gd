class_name GardenPlantInspector
extends RefCounted

static var target_materials: Dictionary={}

static func growth_context(g, p: Dictionary) -> Dictionary:
 var data: Dictionary=g.catalogue[p.id]
 for obj in g.objects:
  if obj.kind=="greenhouse" and obj.pos.distance_to(p.pos)<=4:
   return {"rate":1.0,"reason":"Protected by the greenhouse · grows year-round"}
 var habitat=GardenAreas.context(g,p,g.plots[p.plot].condition)
 if not data.seasons.is_empty() and GardenClimate.season(g.day) not in data.seasons and not habitat.protected:
  var frame=GardenEquipment.near(g,p,"cold_frame",1.2,"closed")
  if int(data.layer)<2 and not frame.is_empty() and frame.work.get("closed",true):return {"rate":.6,"reason":"Sheltered by the cold frame · grows gently out of season"}
  return {"rate":0.0,"reason":"Resting until "+GardenCatalogue.growing_seasons(p.id)}
 var actual: String=habitat.actual
 var shaded_by=""
 var canopy=GardenEquipment.near(g,p,"shade_canopy",1.8,"shade_on")
 if not canopy.is_empty() and canopy.work.get("shade_on",true):actual="shade";shaded_by="shade cloth"
 for index in g.plant_index.nearby(g.planted,p.pos,2.3):
  var other: Dictionary=g.planted[index]
  if int(g.catalogue[other.id].layer)==3 and other.pos.distance_to(p.pos)<2.3 and other.age/float(g.catalogue[other.id].days)>=.52 and int(data.layer)<3:
   actual="shade"
   shaded_by=g.catalogue[other.id].name
 var rate=1.0 if data.condition=="any" or data.condition==actual else .6
 var reason="Growing happily here"
 if rate<1:
  if not shaded_by.is_empty() and data.condition=="sun": reason="Slower growth · shaded by "+shaded_by
  else: reason="Slower growth · prefers "+{"sun":"sunlight","shade":"shade","water":"a waterside bed"}.get(data.condition,data.condition)
 elif not shaded_by.is_empty(): reason="Comfortable in the shade of "+shaded_by
 if habitat.protected:rate=1.0
 rate*=float(habitat.bonus)
 if not str(habitat.reason).is_empty() and rate>=1:reason=habitat.reason
 return {"rate":rate,"reason":reason}

static func lines(g, p: Dictionary) -> Array:
 var data: Dictionary=g.catalogue[p.id]
 var fraction=clampf(p.age/float(data.days),0,1)
 var text=[data.name+" · "+["Groundcover","Flowers","Shrubs","Canopy"][data.layer],"%s · %d%% grown"%[GardenPlantGrowth.stage(fraction,data),roundi(fraction*100)]]
 if GardenContainers.is_contained(p):text.append("Container pocket %d"%(int(p.container_slot)+1))
 text.append("Thirsty · watering helps" if p.water<=0 else "Watered")
 var care=growth_context(g,p)
 if fraction<1: text.append(care.reason)
 if (float(p.get("watered_until",0))>GardenTools.now(g) if GardenContainers.is_contained(p) else GardenTools.growth_multiplier(g,p.pos,GardenTools.now(g))>1): text.append("Watering boost · +20% growth")
 if float(p.get("stress",0))>.2: text.append("Pruning would ease its stress")
 for key in ["compost","castings","mulch"]:
  if GardenEquipment.active(p,key,g.day):text.append(GardenEquipment.RECIPES[key].name+" · %d mornings"%(int(p.treatments[key])-g.day))
 var overlap=0
 for index in g.plant_index.nearby(g.planted,p.pos,g.GRID*.75):
  var other: Dictionary=g.planted[index]
  if GardenContainers.is_contained(p) or GardenContainers.is_contained(other):continue
  if Vector2(other.pos.x-p.pos.x,other.pos.z-p.pos.z).length()<g.GRID*.75: overlap+=1
 if overlap>1: text.append("%d layers here · %s to switch"%[overlap,"Layer" if g.touch_active() else "L"])
 var actions={"move":"Click to pick up this plant","remove":"Click to remove this plant","prune":"Prune this square","water":"Water this area","harvest":"Gather ready plants in this square"}
 if g.mode=="walk":text.append("Choose a tool to tend this plant")
 elif actions.has(g.mode):text.append(actions[g.mode])
 return text

static func highlight(node: Node, enabled: bool) -> void:
 if node is MeshInstance3D:
  if enabled and not node.has_meta("target_materials"):
   var originals=[]
   for surface in range(node.mesh.get_surface_count()):
    var original=node.get_active_material(surface)
    originals.append(node.get_surface_override_material(surface))
    if original:
     var key=original.get_instance_id()
     if not target_materials.has(key):
      var chosen=original.duplicate()
      var outline=ShaderMaterial.new()
      outline.shader=load("res://shaders/plant_outline.gdshader")
      if original is ShaderMaterial:
       outline.set_shader_parameter("wind_strength",original.get_shader_parameter("wind_strength"))
       outline.set_shader_parameter("fruit_anchors",original.get_shader_parameter("fruit_anchors"))
       outline.set_shader_parameter("fruit_growth",original.get_shader_parameter("fruit_growth"))
       if RenderingServer.get_current_rendering_method()=="gl_compatibility":
        outline.set_shader_parameter("plant_shape",original.get_shader_parameter("plant_shape"))
        outline.set_shader_parameter("plant_height",original.get_shader_parameter("plant_height"))
      chosen.next_pass=outline
      target_materials[key]=chosen
     node.set_surface_override_material(surface,target_materials[key])
   node.set_meta("target_materials",originals)
  elif not enabled and node.has_meta("target_materials"):
   var originals: Array=node.get_meta("target_materials")
   for surface in range(originals.size()): node.set_surface_override_material(surface,originals[surface])
   node.remove_meta("target_materials")
 for child in node.get_children(): highlight(child,enabled)

static func update(g) -> void:
 var structure_lines=GardenStructureTarget.update(g)
 var target: Node3D=null
 var allowed=structure_lines.is_empty() and g.hover_valid and g.hover_target>=0 and g.hover_target<g.planted.size() and g.mode in ["walk","water","prune","harvest","remove","move"] and not (g.mode=="move" and (g.moved_index>=0 or g.moved_object>=0))
 if allowed: target=g.planted[g.hover_target].node
 if g.highlighted_plant!=target:
  if is_instance_valid(g.highlighted_plant): highlight(g.highlighted_plant,false)
  if is_instance_valid(g.plant_batches):g.plant_batches.select(target)
  g.highlighted_plant=target
  if is_instance_valid(target): highlight(target,true)
 if not is_instance_valid(g.inspector_panel): return
 g.inspector_panel.visible=(allowed or not structure_lines.is_empty()) and not g.touch_active()
 g.inspector_lines=[]
 if allowed:
  g.inspector_lines=lines(g,g.planted[g.hover_target])
 elif not structure_lines.is_empty():g.inspector_lines=structure_lines
 if not g.inspector_lines.is_empty():
  g.inspector_label.text="\n".join(g.inspector_lines)
