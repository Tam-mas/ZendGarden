class_name GardenWorkshop
extends RefCounted

static func initial_state() -> Dictionary:
 return {"resources":{},"jobs":[],"nursery":[],"use_starter":false,"sequence":0}

static func restore(g, data: Dictionary) -> void:
 g.workshop_state=initial_state()
 g.workshop_state.merge(data.get("workshop",{}),true)

static func target(g) -> Dictionary:
 if g.mode!="walk" or g.photo_mode or g.day_transition:return {}
 var best={};var nearest=3.2
 var forward=Vector3(-sin(g.yaw),0,-cos(g.yaw))
 for obj in g.objects:
  if obj.kind not in GardenEquipment.KINDS and obj.kind not in GardenContainers.SPECS:continue
  var direction=obj.pos-g.player.position;direction.y=0
  if direction.length()>nearest:continue
  if direction.length()>.8 and direction.normalized().dot(forward)<.25:continue
  nearest=direction.length();best=obj
 return best

static func interact(g) -> bool:
 var obj=target(g)
 if obj.is_empty():return false
 open(g,obj.uid)
 return true

static func note(g, column: Control, text: String, size: int=15) -> void:
 var label=g.label(text,size)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 column.add_child(label)

static func action(g, column: Control, text: String, callback: Callable, enabled: bool=true) -> Button:
 var button=g.button(text,func():
  g.workshop_notice=""
  callback.call()
  for obj in g.objects:GardenEquipment.visual(g,obj)
  g.save_game();g.refresh_ui()
  if g.workshop_open:open(g,g.workshop_uid),Vector2(0,48))
 button.disabled=not enabled
 button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(button)
 return button

static func open(g, uid: String="") -> void:
 if is_instance_valid(g.welcome) and not g.workshop_open:return
 if not g.workshop_open:
  g.workshop_return_to_game=not g.side_panel.visible;g.workshop_notice=""
 if is_instance_valid(g.welcome):g.welcome.queue_free()
 if is_instance_valid(g.welcome_backdrop):g.welcome_backdrop.queue_free()
 g.workshop_open=true;g.workshop_uid=uid
 if is_instance_valid(g.touch):g.touch.reset_gestures()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.welcome_backdrop=ColorRect.new()
 g.welcome_backdrop.color=Color(.04,.08,.06,.45)
 g.welcome_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 g.welcome_backdrop.z_index=29;g.ui.add_child(g.welcome_backdrop)
 var viewport=g.get_viewport().get_visible_rect().size
 g.welcome=g.panel_at(Vector2.ZERO,Vector2(minf(560,viewport.x-24),minf(660,viewport.y-24)))
 g.welcome.name="GardenWorkshop";g.welcome.z_index=30
 var frame=VBoxContainer.new();frame.add_theme_constant_override("separation",10)
 g.welcome.add_child(frame)
 var obj=GardenContainers.object(g,uid)
 note(g,frame,"Working garden" if obj.is_empty() else GardenEquipment.name_of(g,obj.kind),23)
 var scroll=ScrollContainer.new();scroll.name="WorkshopScroll"
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 frame.add_child(scroll)
 var column=VBoxContainer.new();column.name="WorkshopContent"
 column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10)
 scroll.add_child(column)
 if not g.workshop_notice.is_empty():note(g,column,g.workshop_notice,16)
 if obj.is_empty():overview(g,column)
 elif obj.kind in GardenContainers.SPECS:planter(g,column,obj)
 else:equipment(g,column,obj)
 if not obj.is_empty():frame.add_child(g.button("Equipment & stored plants",func():open(g),Vector2(0,48)))
 frame.add_child(g.button("Back to garden" if g.workshop_return_to_game else "Done",func():close(g),Vector2(0,48)))
 fit(g)

static func fit(g) -> void:
 if not g.workshop_open or not is_instance_valid(g.welcome):return
 var size=g.get_viewport().get_visible_rect().size
 g.welcome.scale=Vector2.ONE
 g.welcome.size=Vector2(minf(560,size.x-24),minf(660,size.y-24))
 g.welcome.position=(size-g.welcome.size)*.5

static func close(g) -> void:
 if not g.workshop_open:return
 if is_instance_valid(g.welcome):g.welcome.queue_free()
 if is_instance_valid(g.welcome_backdrop):g.welcome_backdrop.queue_free()
 g.welcome=null;g.welcome_backdrop=null;g.workshop_open=false;g.workshop_uid=""
 if g.workshop_return_to_game:g.resume_controls()

static func supplies(g, column: Control) -> void:
 note(g,column,"YOUR GARDEN SUPPLIES",16)
 for key in GardenEquipment.RECIPES:
  note(g,column,"%s · %d portions\n%s"%[GardenEquipment.RECIPES[key].name,int(g.workshop_state.resources.get(key,0)),GardenEquipment.RECIPES[key].hint],14)
 var starter=CheckButton.new()
 starter.name="UseStarterMix";starter.text="Starter mix for new plants"
 starter.add_theme_font_size_override("font_size",14)
 starter.custom_minimum_size.y=48;starter.button_pressed=g.workshop_state.use_starter
 starter.toggled.connect(func(value):g.workshop_state.use_starter=value;g.save_game())
 column.add_child(starter)

static func overview(g, column: Control) -> void:
 note(g,column,"Make useful supplies, tend container displays and keep lifted plants in the nursery. In Wander, face equipment or a planter and press E, or use Interact on touch.",15)
 supplies(g,column)
 note(g,column,"TEND "+g.plots[g.current_plot].name.to_upper(),16)
 note(g,column,"Apply one portion per plant in this garden bed. Plants already benefiting are skipped.",14)
 for key in ["compost","castings","mulch"]:
  var selected=key
  action(g,column,"Apply "+GardenEquipment.RECIPES[key].name+" to bed",func():
   var treated=0
   for p in g.planted:
    if int(p.plot)==g.current_plot and not GardenContainers.is_contained(p) and GardenEquipment.treat(g,p,selected):treated+=1
   g.toast("Tended %d plants with %s."%[treated,GardenEquipment.RECIPES[selected].name]),int(g.workshop_state.resources.get(key,0))>0)
 note(g,column,"PLACED EQUIPMENT & PLANTERS",16)
 var count=0
 for obj in g.objects:
  if obj.kind not in GardenEquipment.KINDS and obj.kind not in GardenContainers.SPECS:continue
  var object_uid=obj.uid
  var status=GardenEquipment.status(g,obj) if obj.kind in GardenEquipment.KINDS else "%d planting pockets"%GardenContainers.SPECS[obj.kind].slots.size()
  column.add_child(g.button(GardenEquipment.name_of(g,obj.kind)+"\n"+status,func():open(g,object_uid),Vector2(0,60)))
  count+=1
 if count==0:note(g,column,"Find working equipment and containers in the garden shed.")
 if not g.workshop_state.jobs.is_empty():
  note(g,column,"RESTING BATCHES",16)
  for job in g.workshop_state.jobs:note(g,column,"%s · %d portions on morning %d"%[GardenEquipment.RECIPES[job.recipe].name,int(job.amount),int(job.ready_day)],14)
 note(g,column,"STORED PLANTS · %d"%g.workshop_state.nursery.size(),16)
 note(g,column,"Packing a planted container keeps its plants here, with their growth and care. Replant into a suitable pocket or choose a new spot on open ground.",14)
 for i in range(g.workshop_state.nursery.size()):
  var index=i;var saved=g.workshop_state.nursery[i]
  action(g,column,"Place %s · %d%% grown"%[g.catalogue[int(saved.id)].name,roundi(float(saved.age)/float(g.catalogue[int(saved.id)].days)*100)],func():
   close(g);g.selected=int(saved.id);g.selected_layer=g.catalogue[g.selected].layer
   g.set_mode("plant");g.nursery_placing=index;g.side_panel.hide();g.resume_controls()
   g.toast("Choose open soil, or a suitable container pocket, for your stored plant."))

static func equipment(g, column: Control, obj: Dictionary) -> void:
 note(g,column,GardenEquipment.status(g,obj),16)
 var recipe_key=GardenEquipment.recipe_for(obj.kind)
 if not recipe_key.is_empty():
  var recipe=GardenEquipment.RECIPES[recipe_key]
  note(g,column,"%d spare %s%s → %d portions after %d morning%s.\n%s."%[int(recipe.input),"produce items" if recipe_key=="castings" else "harvest items"," + %d petals"%int(recipe.cost) if int(recipe.cost)>0 else "",int(recipe.output),int(recipe.days),"s" if int(recipe.days)>1 else "",recipe.hint],15)
  note(g,column,"Available spare material: %d. Neighbour request items are kept aside."%GardenEquipment.spare_count(g,recipe_key=="castings"),14)
  action(g,column,"Prepare "+recipe.name,func():GardenEquipment.start(g,obj),GardenEquipment.jobs(g,obj.uid).size()<(2 if obj.work.get("upgraded",false) else 1))
 if obj.kind=="rain_barrel":
  note(g,column,"Rain fills the barrel. Each stored drink waters one plant in a container within 4 metres at the next morning. Irrigation uses ordinary water; hand watering keeps its own growth bonus.")
  action(g,column,"Pause planter irrigation" if obj.work.irrigating else "Water nearby planters each morning",func():obj.work.irrigating=not obj.work.irrigating)
 elif obj.kind=="shade_canopy":
  note(g,column,"An open canopy gives shade within 1.8 metres. Shade-loving plants become comfortable here; sunlight-loving plants prefer a spot beyond its edge.")
  action(g,column,"Fold shade away" if obj.work.shade_on else "Open shade cloth",func():obj.work.shade_on=not obj.work.shade_on)
 elif obj.kind=="cold_frame":
  note(g,column,"A closed lid shelters groundcover and flowers within 1.2 metres. They grow at 60% pace outside their usual season. Larger plants still follow their normal seasons.")
  action(g,column,"Open lid" if obj.work.closed else "Close lid",func():obj.work.closed=not obj.work.closed)
 elif obj.kind=="bird_feeder":
  note(g,column,"Three spare harvest items welcome two extra songbirds for three garden days. Watch them visit the table; no daily feeding is required.")
  action(g,column,"Set out food · 3 spare items",func():GardenEquipment.feed(g,obj),int(obj.work.feed_until)<=g.day)
 elif obj.kind=="hive":
  note(g,column,"Daytime bees visit the hive. Produce within four metres gains a gentle 5% growth bonus. Care bonuses combine up to 30%.")
 elif obj.kind=="insect_hotel":
  note(g,column,"Blue-banded bees and hoverflies visit this shelter. Flowers and produce within three metres accumulate less care stress each morning.")
 if obj.kind=="rain_barrel" or not recipe_key.is_empty():
  action(g,column,"Upgraded" if obj.work.get("upgraded",false) else "Upgrade equipment · 40 petals",func():GardenEquipment.upgrade(g,obj),not obj.work.get("upgraded",false))
 supplies(g,column)

static func planter(g, column: Control, obj: Dictionary) -> void:
 var spec=GardenContainers.SPECS[obj.kind]
 note(g,column,"%d planting pocket%s. Plant, gather and tend each pocket here, or aim your usual tools at it. Move carries the whole display; Remove keeps the contents in stored plants."%[spec.slots.size(),"s" if spec.slots.size()>1 else ""],15)
 for slot in range(spec.slots.size()):
  var pocket=slot
  var index=GardenContainers.occupant(g,obj,slot)
  note(g,column,"POCKET %d"%(slot+1),16)
  if index>=0:
   var p=g.planted[index]
   note(g,column,"\n".join(GardenPlantInspector.lines(g,p).slice(0,6)),14)
   action(g,column,"Gather "+g.catalogue[p.id].name,func():
    if g.collect_plant(p):g.toast("Gathered one item for your basket.")
    else:g.toast("This plant is still growing."),float(p.age)>=float(g.catalogue[p.id].days))
   action(g,column,"Water this pocket",func():GardenEquipment.water_pocket(g,p);g.toast("Watered this planting pocket."))
   var treatments=OptionButton.new();treatments.custom_minimum_size.y=48
   for key in ["compost","castings","mulch"]:treatments.add_item("%s · %d"%[GardenEquipment.RECIPES[key].name,int(g.workshop_state.resources.get(key,0))])
   column.add_child(treatments)
   action(g,column,"Apply selected care",func():
    var key=["compost","castings","mulch"][treatments.selected]
    g.toast("Applied "+GardenEquipment.RECIPES[key].name+"." if GardenEquipment.treat(g,p,key) else "Prepare more supplies, or wait until this treatment has finished."))
   action(g,column,"Keep this plant in the nursery",func():GardenContainers.store(g,p);g.refresh_wildlife())
  else:
   var choice=OptionButton.new();choice.name="Pocket%dSeeds"%slot;choice.custom_minimum_size.y=48
   var choices=[]
   for id in g.unlocked_plants:
    if GardenContainers.can_plant(g,obj,slot,int(id)).is_empty():
     choice.add_item(g.catalogue[int(id)].name);choices.append({"id":int(id),"nursery":-1})
   for i in range(g.workshop_state.nursery.size()):
    var saved=g.workshop_state.nursery[i]
    if GardenContainers.can_plant(g,obj,slot,int(saved.id)).is_empty():
     choice.add_item("Stored · "+g.catalogue[int(saved.id)].name);choices.append({"id":int(saved.id),"nursery":i})
   if choices.is_empty():choice.add_item("Unlock a compact plant in Seeds");choice.disabled=true
   column.add_child(choice)
   action(g,column,"Plant in pocket %d"%(slot+1),func():
    var selected=choices[choice.selected]
    if int(selected.nursery)>=0:GardenContainers.replant(g,int(selected.nursery),obj,pocket)
    else:GardenContainers.plant(g,obj,pocket,int(selected.id))
    g.refresh_wildlife();g.toast("A little planting takes its place."),not choices.is_empty())
 supplies(g,column)

static func valid_save(data: Dictionary, plant_count: int) -> bool:
 var state=data.get("workshop",{})
 if not state is Dictionary:return false
 if not state.get("resources",{}) is Dictionary or not state.get("jobs",[]) is Array or not state.get("nursery",[]) is Array:return false
 if state.has("use_starter") and not state.use_starter is bool:return false
 if not GardenSaveFormat.integer(state.get("sequence",0),0):return false
 for key in state.get("resources",{}):
  if key not in GardenEquipment.RECIPES or not GardenSaveFormat.integer(state.resources[key],0):return false
 for job in state.get("jobs",[]):
  if not job is Dictionary or job.get("recipe") not in GardenEquipment.RECIPES or not job.get("station") is String:return false
  if not GardenSaveFormat.integer(job.get("ready_day"),1) or not GardenSaveFormat.integer(job.get("amount"),1,100):return false
 var objects={};var slots={}
 for obj in data.get("objects",[]):
  if obj.has("uid"):
   if not obj.uid is String or obj.uid.is_empty() or objects.has(obj.uid):return false
   objects[obj.uid]=obj
  if obj.has("work"):
   if not obj.work is Dictionary:return false
   if not GardenSaveFormat.fields(obj.work,["water","feed_until"],["upgraded","irrigating","shade_on","closed"]):return false
   if obj.work.has("water") and (float(obj.work.water)<0 or float(obj.work.water)>24):return false
   if obj.work.has("feed_until") and not GardenSaveFormat.integer(obj.work.feed_until,0):return false
 var plot_count=maxi(4,int(data.get("unlocked_plots",1))+2)
 if plot_count%2:plot_count+=1
 if data.has("areas"):plot_count+=10
 for p in data.plants+state.get("nursery",[]):
  if not p is Dictionary or not GardenSaveFormat.integer(p.get("id"),0,plant_count-1):return false
  if not GardenSaveFormat.vector(p.get("pos")) or not GardenSaveFormat.integer(p.get("plot"),0,plot_count-1):return false
  for key in ["age","water","stress"]:
   if not GardenSaveFormat.number(p.get(key)):return false
  if not GardenSaveFormat.fields(p,["height_factor","orientation","shape_seed","pruned","prune_cuts","watered_until"],[],["storage_source"]):return false
  if p.has("area_training") and p.area_training not in ["open","fan","espalier"]:return false
  if p.has("area_graft") and (not GardenSaveFormat.integer(p.area_graft,0,plant_count-1) or int(p.area_graft) not in GardenAreas.compatible_grafts(int(p.id))):return false
  if p.has("area_offset_day") and not GardenSaveFormat.integer(p.area_offset_day,0):return false
  if p.has("storage_slot") and not GardenSaveFormat.integer(p.storage_slot,-1,5):return false
  if p.has("container_slot") and not p.has("container_uid"):return false
  if p.has("treatments"):
   if not p.treatments is Dictionary:return false
   for key in p.treatments:
    if key not in ["compost","castings","mulch"] or not GardenSaveFormat.integer(p.treatments[key],0):return false
  if p.has("container_uid"):
   if not p.container_uid is String or not objects.has(p.container_uid):return false
   var obj=objects[p.container_uid]
   if obj.kind not in GardenContainers.SPECS or not GardenSaveFormat.integer(p.get("container_slot"),0,GardenContainers.SPECS[obj.kind].slots.size()-1):return false
   var key=p.container_uid+":"+str(int(p.container_slot))
   if slots.has(key):return false
   slots[key]=true
 return true
