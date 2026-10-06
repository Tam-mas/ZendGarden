class_name GardenAreaAtlas
extends RefCounted

static func note(g,column: Control,text: String,size: int=15) -> void:
 GardenWorkshop.note(g,column,text,size)

static func action(g,column: Control,text: String,callback: Callable,enabled: bool=true) -> Button:
 var button=g.button(text,func():
  g.area_notice="";callback.call()
  if g.area_atlas_open:
   if g.area_atlas_index>=0:GardenAreas.visual(g,g.area_atlas_index)
   g.refresh_wildlife();g.refresh_ui();g.save_game();open(g,g.area_atlas_index),Vector2(0,48))
 button.disabled=not enabled;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(button);return button

static func toggle(g,column: Control,text: String,values: Array,index: int) -> void:
 action(g,column,text+" · "+("On" if values[index] else "Off"),func():values[index]=not values[index])

static func preview(g,column: Control,index: int) -> void:
 var path="res://assets/ui/areas/"+GardenAreaCatalogue.entry(index).kind+".webp"
 if ResourceLoader.exists(path):
  var texture=TextureRect.new();texture.name="AreaPreview"
  texture.texture=load(path);texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  texture.custom_minimum_size=Vector2(0,180);texture.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  column.add_child(texture)

static func open(g,index: int=-1) -> void:
 if is_instance_valid(g.welcome) and not g.area_atlas_open:return
 if not g.area_atlas_open:
  g.area_atlas_return=not g.side_panel.visible;g.area_notice=""
 if is_instance_valid(g.welcome):g.welcome.queue_free()
 if is_instance_valid(g.welcome_backdrop):g.welcome_backdrop.queue_free()
 g.area_atlas_open=true;g.area_atlas_index=index
 if is_instance_valid(g.touch):g.touch.reset_gestures()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.welcome_backdrop=ColorRect.new();g.welcome_backdrop.color=Color(.035,.065,.045,.6)
 g.welcome_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 g.welcome_backdrop.z_index=29;g.ui.add_child(g.welcome_backdrop)
 var size=g.get_viewport().get_visible_rect().size
 g.welcome=g.panel_at(Vector2.ZERO,Vector2(minf(620,size.x-24),minf(720,size.y-24)))
 g.welcome.name="GardenAtlas";g.welcome.z_index=30
 var frame=VBoxContainer.new();frame.add_theme_constant_override("separation",10);g.welcome.add_child(frame)
 note(g,frame,"Garden atlas" if index<0 else GardenAreaCatalogue.entry(index).name,23)
 var scroll=ScrollContainer.new();scroll.name="AtlasScroll";scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;frame.add_child(scroll)
 var col=VBoxContainer.new();col.name="AtlasContent";col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 col.add_theme_constant_override("separation",10);scroll.add_child(col)
 if not g.area_notice.is_empty():note(g,col,g.area_notice,16)
 if index<0:
  note(g,col,"Ten new trails beyond the eastern path. Each has its own planting choices and gentle activities. Visit any of them now; your original beds keep their own progression.")
  for j in range(10):
   var selected=j;var info=GardenAreaCatalogue.entry(j)
   action(g,col,info.name+" · "+("Visited" if GardenAreas.state(g,j).visited else "New trail"),func():open(g,selected))
   note(g,col,info.description,14)
  action(g,col,"Return to the beginning",func():
   close(g);g.player.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.15,0)
   g.player.velocity=Vector3.ZERO;g.yaw=0;g.pitch=.1;g.current_plot=0;g.side_panel.hide();g.resume_controls())
 else:
  var info=GardenAreaCatalogue.entry(index);var s=GardenAreas.state(g,index)
  preview(g,col,index);note(g,col,info.description,16)
  action(g,col,"Visit "+info.name,func():GardenAreas.visit(g,index))
  if not s.initialized:note(g,col,"Visit to receive its starter collection and begin the garden activities. All ten trails are open.")
  else:
   note(g,col,"Make this garden your own: use Seeds and Plant on clear ground, and Move or Remove for your ordinary plants and starter equipment. Keep water, paths, rocks and buildings clear. Specialist collection plants use the planting and clearing buttons in Activities; the surrounding landscape planting stays in place.",14)
   activities(g,col,index)
 if index>=0:frame.add_child(g.button("All ten garden trails",func():open(g),Vector2(0,48)))
 frame.add_child(g.button("Back to garden" if g.area_atlas_return else "Done",func():close(g),Vector2(0,48)))
 fit(g)

static func fit(g) -> void:
 if not g.area_atlas_open or not is_instance_valid(g.welcome):return
 var size=g.get_viewport().get_visible_rect().size
 g.welcome.scale=Vector2.ONE;g.welcome.size=Vector2(minf(620,size.x-24),minf(720,size.y-24))
 g.welcome.position=(size-g.welcome.size)*.5

static func close(g) -> void:
 if not g.area_atlas_open:return
 if is_instance_valid(g.welcome):g.welcome.queue_free()
 if is_instance_valid(g.welcome_backdrop):g.welcome_backdrop.queue_free()
 g.welcome=null;g.welcome_backdrop=null;g.area_atlas_open=false
 if g.area_atlas_return:g.resume_controls()

static func activities(g,column: Control,index: int) -> void:
 var s=GardenAreas.state(g,index)
 match index:
  0:
   note(g,column,"INLET SLUICE · "+["Low water","Balanced water","High water"][int(s.sluice)],17)
   note(g,column,"Deep shelves support water lilies and hawthorn. Marginal shelves support iris and rush. Banks suit mint. A matching depth gives +20% growth; other depths grow gently.")
   for level in range(3):
    var choice=level
    action(g,column,["Lower inlet","Balance inlet","Raise inlet"][level],func():s.sluice=choice,int(s.sluice)!=level)
   collection(g,column,index)
  1:
   note(g,column,"THREE LITTLE CLEARINGS",17)
   note(g,column,"Closed canopies favour ferns and shade plants; an open clearing admits sunlight. Walk close to the hidden groves to discover new fern collections.")
   for j in range(3):toggle(g,column,"Open "+["western","middle","eastern"][j]+" clearing",s.clearings,j)
   note(g,column,"Discoveries: "+(", ".join(s.discoveries) if not s.discoveries.is_empty() else "Walk to the mossy hollow, old fern grove and spring clearing."))
   collection(g,column,index)
  2:
   note(g,column,"FREE-DRAINING TERRACES",17)
   note(g,column,"Succulents grow 15% faster and use water more slowly in these mineral pockets. Unfold rain shelters to keep selected displays dry. Mature plants yield an offset for your stored nursery every four mornings.")
   for j in range(3):toggle(g,column,"Rain shelter · terrace %d"%(j+1),s.shelters,j)
   var found=false
   for p in g.planted:
    if int(p.plot)!=6 or g.catalogue[int(p.id)].category!="Cacti & succulents":continue
    var plant=p;found=true
    action(g,column,"Lift offset · "+g.catalogue[int(p.id)].name,func():GardenAreas.offsets(g,plant),float(p.age)>=float(g.catalogue[int(p.id)].days) and int(p.get("area_offset_day",0))<=g.day)
   if not found:note(g,column,"Plant succulents from Seeds, then return when they are mature.")
   action(g,column,"Equipment & stored plants",func():close(g);GardenWorkshop.open(g))
  3:
   note(g,column,"LIVING HABITAT JOURNAL · %d / %d"%[s.journal.size(),GardenAreas.JOURNAL.size()],17)
   note(g,column,"Visits depend on your own mature flowers and native plants. Mix varieties, include natives and return after dusk. Each first sighting gives a permanent seed gift.")
   action(g,column,"Observe the meadow",func():
    var found=GardenAreas.observe_meadow(g)
    if found.is_empty():g.toast("No new sightings yet. Let your flowers mature, add variety, or return at another time."))
   for kind in GardenAreas.JOURNAL:
    var rule=GardenAreas.JOURNAL[kind]
    note(g,column,("✓ " if kind in s.journal else "○ ")+rule.name+" · %d flowering plants, %d varieties%s%s"%[int(rule.flowers),int(rule.types),", include a native" if rule.get("native",false) else "",", after dusk" if rule.get("night",false) else ", in daylight"],14)
   var coverage=GardenAreas.season_coverage(g)
   note(g,column,"FLOWER CALENDAR · "+(", ".join(coverage) if not coverage.is_empty() else "Plant a mixture for a changing year."),15)
  4:
   note(g,column,"TRAINING & GRAFTING",17)
   note(g,column,"Open crowns ease care stress. Fans and espalier forms make flatter trees for underplanting. Graft a compatible fruit using two spare donor items; gathering a mature tree brings its own fruit and its grafted variety.")
   for p in g.planted:
    if int(p.plot)!=8 or int(p.id) not in GardenPlantGrowth.FRUIT_TREES:continue
    var plant=p
    note(g,column,g.catalogue[int(p.id)].name+" · "+str(p.get("area_training","natural crown")),16)
    for style in ["open","fan","espalier"]:
     var chosen=style
     action(g,column,"Train as "+style,func():GardenAreas.train(g,plant,chosen),str(p.get("area_training",""))!=style)
    if p.has("area_graft"):note(g,column,"Grafted branch: "+g.catalogue[int(p.area_graft)].name)
    else:
     for donor in GardenAreas.compatible_grafts(int(p.id)):
      var chosen=int(donor)
      action(g,column,"Graft "+g.catalogue[chosen].name+" · 2 spare fruit",func():GardenAreas.graft(g,plant,chosen),float(p.age)>=float(g.catalogue[int(p.id)].days)*.78 and GardenEquipment.spare_count_for(g,chosen)>=2)
   note(g,column,"SEASONAL ORCHARD BASKET",17)
   note(g,column,"Three different spare fruit items become petals and two compost portions. One basket per morning; neighbour request items are kept aside.")
   action(g,column,"Prepare orchard basket",func():GardenAreas.orchard_basket(g),int(s.basket_day)!=g.day)
  5:
   note(g,column,"COMPANIONS & CROP ROTATION",17)
   note(g,column,"Flowers or herbs within 1.8 metres help produce grow 15% faster. After harvest, sow another crop family in that quarter for a further 10% growth. Container pockets support vertical growing along the wall.")
   for j in range(4):note(g,column,"Bed %d · previous harvest: %s"%[j+1,str(s.rotation.get(str(j),"Fresh soil"))],14)
   note(g,column,"KITCHEN BASKETS",17)
   note(g,column,"Use one of each listed ingredient. Prepare one basket per morning for petals and two useful supply portions; reserved neighbour items are kept aside.")
   for key in GardenAreas.KITCHEN_RECIPES:
    var recipe=GardenAreas.KITCHEN_RECIPES[key];var chosen=key
    note(g,column,recipe.name+" · "+", ".join(recipe.items.map(func(id):return g.catalogue[int(id)].name)),14)
    action(g,column,"Prepare "+recipe.name,func():GardenAreas.kitchen_basket(g,chosen),int(s.basket_day)!=g.day)
   action(g,column,"Vertical containers & equipment",func():close(g);GardenWorkshop.open(g))
  6:
   note(g,column,"RESTORE THE CONSERVATORY",17)
   note(g,column,"Each repaired bay costs 30 petals and becomes a year-round growing zone. Mist and shade favour moth orchids and wax flowers; open vents and clear light favour cymbidiums. Small plants outside their preferred conditions still grow gently.")
   for bay in range(3):
    var selected=bay;note(g,column,"BAY %d · %s"%[bay+1,"Restored" if s.restored[bay] else "Weathered panes"],16)
    if not s.restored[bay]:action(g,column,"Restore bay %d · 30 petals"%(bay+1),func():GardenAreas.restore_bay(g,selected),g.coins>=30)
    else:
     toggle(g,column,"Open roof vent",s.vents,bay);toggle(g,column,"Unfold shade cloth",s.shade,bay);toggle(g,column,"Gentle misting",s.mist,bay)
   collection(g,column,index)
  7:
   note(g,column,"STREAM GATES",17)
   note(g,column,"Choose the western or eastern growing strip, or both. Open gates carry visible water along the channel and give plants within 1.5 metres a morning drink and +10% growth. The bridge and stepping stones keep the walking route open.")
   for j in range(2):toggle(g,column,["Western growing strip","Eastern growing strip"][j],s.gates,j)
  8:
   note(g,column,"SHELTERED ROCK POCKETS",17)
   note(g,column,"Windbreaks help low plants grow 15% faster and ease care stress. Alpine collections rest gently in winter. The first spring morning brings three mornings of snowmelt watering.")
   for j in range(3):toggle(g,column,"Stone windbreak · pocket %d"%(j+1),s.windbreaks,j)
   note(g,column,"Snowmelt watering · %d mornings"%int(s.melt),14)
   collection(g,column,index)
  9:
   note(g,column,"DUSK FLOWERS & LANTERNS",17)
   note(g,column,"The collection’s flowers open from dusk to dawn. Bright lanterns draw moths; soft light welcomes fireflies too. Capture three mature dusk flowers in soft light to collect your Moon Garden memory.")
   for level in range(3):
    var selected=level
    action(g,column,["Extinguish lanterns","Soft lantern light","Bright lantern light"][level],func():s.lanterns=selected,int(s.lanterns)!=level)
   action(g,column,"Rest until twilight",func():
    g.clock_time=.77;g.update_lighting();g.climate.apply(g);g.toast("Twilight settles over the Moon Garden."),not GardenAreas.dusk(g))
   note(g,column,"Moon Garden memory · "+("Collected" if s.photo else "Awaiting a night photo with three mature dusk flowers"),14)
   action(g,column,"Compose a night photograph",func():close(g);g.toggle_photo())
   collection(g,column,index)

static func collection(g,column: Control,index: int) -> void:
 var info=GardenAreaCatalogue.entry(index);var s=GardenAreas.state(g,index)
 if info.slots.is_empty():return
 note(g,column,"LIVING COLLECTION · %d POCKETS"%info.slots.size(),17)
 note(g,column,"Plant these specialist pockets here, or use Seeds and your regular tools on the open soil. Collection plants retain their growth and watering when you return.",14)
 for slot in range(info.slots.size()):
  var chosen=slot;var spec=info.slots[slot];var key=str(slot)
  var band=" · "+str(spec.depth).capitalize() if spec.has("depth") else " · Bay %d"%(int(spec.bay)+1) if spec.has("bay") else ""
  if s.beds.has(key):
   var p: Dictionary=s.beds[key];var species=GardenAreaCatalogue.data().specialties[p.species]
   note(g,column,"Pocket %d%s · %s\n%d%% grown · %s · %.0f%% growing rate"%[slot+1,band,species.name,roundi(float(p.age)/float(species.days)*100),"Watered" if float(p.water)>0 else "Thirsty",GardenAreas.pocket_rate(g,index,slot,p)*100],15)
   action(g,column,"Water pocket %d"%(slot+1),func():s.beds[str(chosen)].water=4.0;g.toast("A drink for pocket %d."%(chosen+1)),index!=0 and float(p.water)<4)
   action(g,column,"Clear pocket %d"%(slot+1),func():s.beds.erase(str(chosen));g.toast("The pocket is ready for another plant."))
  else:
   note(g,column,"Pocket %d%s · ready to plant"%[slot+1,band],15)
   var choices=GardenAreas.choices(g,index,slot)
   if choices.is_empty():note(g,column,"Restore this bay to open its collection pocket.",14);continue
   var row=VBoxContainer.new();column.add_child(row)
   var select=OptionButton.new();select.name="PocketChoice%d"%slot;select.custom_minimum_size.y=44
   for species in choices:select.add_item(GardenAreaCatalogue.data().specialties[species].name)
   row.add_child(select)
   action(g,row,"Plant pocket %d"%(slot+1),func():GardenAreas.plant_collection(g,index,chosen,str(choices[select.selected])))
