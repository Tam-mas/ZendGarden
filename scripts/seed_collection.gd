class_name GardenSeedCollection
extends RefCounted

static func tablet(g) -> bool:
 return g.touch_active() and g.touch is Object and bool(g.touch.get("tablet_layout"))

static func colour_group(color: Color) -> String:
 if color.s<.18 and color.v>.75: return "Cream / white"
 if color.v<.25: return "Dark"
 if color.h<.06 or color.h>.94: return "Red / pink"
 if color.h<.18: return "Yellow / orange"
 if color.h<.48: return "Green"
 if color.h<.70: return "Blue"
 return "Purple / pink"

static func matching(g) -> Array:
 var found: Array=[]
 var filters: Dictionary=g.collection_filters
 var group=str(filters.get("group","All collections"))
 var entries=g.catalogue.duplicate()
 for f in g.breeding_state.forms.values():
  if not f.registered or f.archived:continue
  var p=g.catalogue[int(f.species)].duplicate(true)
  p["form_uid"]=f.uid;p["name"]=GardenPlantBreeding.title(g,f);p["height"]=float(p.height)*GardenPlantBreeding.height_factor(f)
  p["collection_group"]="My cultivars"
  if int(f.genes.bloom[0])!=0:p["color"]=Color(GardenPlantBreeding.palette(f)[int(f.genes.bloom[0])])
  entries.append(p)
 for p in entries:
  if g.category!="All" and p.category!=g.category: continue
  if group!="All collections" and group in GardenCatalogue.COLLECTION_GROUPS+["My cultivars"] and p.get("collection_group","")!=group: continue
  if not g.collection_query.strip_edges().is_empty() and not (p.name+" "+p.get("botanical_name","")).to_lower().contains(g.collection_query.strip_edges().to_lower()): continue
  if filters.view=="Favourites" and (not GardenPlantBreeding.form(g,p.form_uid).favourite if p.has("form_uid") else p.id not in g.favourite_plants):continue
  if filters.view=="Recently planted" and (p.form_uid not in g.breeding_state.recent if p.has("form_uid") else p.id not in g.recent_plants):continue
  if filters.view=="My cultivars" and not p.has("form_uid"):continue
  if filters.view=="Discovered" and not p.has("form_uid") and p.id not in g.unlocked_plants:continue
  var season=GardenClimate.season(g.day) if filters.season=="Growing now" else str(filters.season)
  if season!="Any season" and not p.seasons.is_empty() and season not in p.seasons: continue
  if filters.light!="Any light" and p.condition!="any" and p.condition!=filters.light.to_lower(): continue
  var height=float(p.get("height",1))
  if filters.height=="Low (under 0.6 m)" and height>=.6: continue
  if filters.height=="Medium (0.6–2 m)" and (height<.6 or height>=2): continue
  if filters.height=="Tall (2 m+)" and height<2: continue
  if filters.colour!="Any colour" and colour_group(p.color)!=filters.colour: continue
  if filters.wildlife!="Any wildlife" and p.animal!=filters.wildlife.to_lower(): continue
  found.append(p)
 var order=str(filters.get("sort","Catalogue"))
 if order=="Name": found.sort_custom(name_before)
 elif order in ["Height","Height: low to high","Height: high to low"]:
  found.sort_custom(func(a,b):
   var left=float(a.get("height",1))
   var right=float(b.get("height",1))
   if left==right:return name_before(a,b)
   return left>right if order=="Height: high to low" else left<right)
 elif order=="Growing days": found.sort_custom(func(a,b):return name_before(a,b) if a.days==b.days else a.days<b.days)
 elif filters.view=="Recently planted": found.sort_custom(func(a,b):
  var left=g.breeding_state.recent.find(a.form_uid) if a.has("form_uid") else g.recent_plants.find(a.id)
  var right=g.breeding_state.recent.find(b.form_uid) if b.has("form_uid") else g.recent_plants.find(b.id)
  return name_before(a,b) if left==right else left<right)
 return found

static func name_before(a, b) -> bool:
 var comparison=a.name.naturalnocasecmp_to(b.name)
 return int(a.id)<int(b.id) if comparison==0 else comparison<0

static func selector(g, parent: Node, key: String, options: Array, caption: String="") -> void:
 var row=VBoxContainer.new()
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(row)
 row.add_child(g.label(key.capitalize() if caption.is_empty() else caption,14))
 var choices=OptionButton.new()
 choices.name="Filter"+key.capitalize()
 choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 choices.fit_to_longest_item=false
 choices.clip_text=true
 choices.custom_minimum_size.y=44 if g.touch_active() else 34
 for option in options:choices.add_item(option)
 choices.select(maxi(0,options.find(g.collection_filters.get(key,options[0]))))
 choices.item_selected.connect(func(index):
  g.collection_filters[key]=options[index]
  if key=="group":g.category="All";update_categories(g)
  update_cards(g))
 row.add_child(choices)

static func build(g) -> void:
 g.side_title.text="Seeds"
 var search=LineEdit.new()
 search.name="SeedSearch"
 search.placeholder_text="Search plants…"
 search.text=g.collection_query
 search.clear_button_enabled=true
 search.custom_minimum_size.y=44 if g.touch_active() else 36
 search.text_changed.connect(func(value):
  g.collection_query=value
  if not value.is_empty():
   g.category="All"
   g.collection_filters.group="All collections"
   g.list_box.find_child("FilterGroup",true,false).select(0)
  update_categories(g)
  update_cards(g))
 g.list_box.add_child(search)
 var browse=HBoxContainer.new()
 browse.name="SeedBrowse"
 g.list_box.add_child(browse)
 var views=OptionButton.new()
 views.name="CollectionView"
 views.fit_to_longest_item=false
 views.clip_text=true
 views.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 views.custom_minimum_size.y=44 if g.touch_active() else 36
 for type in ["All plants"]+GardenCatalogue.CATEGORIES:
  views.add_item(type)
  views.set_item_metadata(views.item_count-1,{"category":"All" if type=="All plants" else type})
 views.add_separator("My collection")
 for entry in [["My seeds","Discovered"],["Favourites","Favourites"],["Recently planted","Recently planted"],["My cultivars","My cultivars"]]:
  views.add_item(entry[0])
  views.set_item_metadata(views.item_count-1,{"view":entry[1]})
 views.item_selected.connect(func(index):
  var choice=views.get_item_metadata(index)
  if choice==null:return
  g.category=choice.get("category","All")
  g.collection_filters.view=choice.get("view","All plants")
  if choice.has("category"):
   g.collection_filters.group="All collections"
   g.list_box.find_child("FilterGroup",true,false).select(0)
  update_categories(g)
  update_cards(g))
 browse.add_child(views)
 update_categories(g)
 var toggle=g.button("Filters & sort",func():
  g.collection_filters_open=not g.collection_filters_open
  g.list_box.get_node("SeedFilters").visible=g.collection_filters_open
  GardenTheme.disclosure(g.list_box.get_node("SeedBrowse/FilterToggle"),g.collection_filters_open),Vector2(150,36))
 toggle.name="FilterToggle"
 GardenTheme.disclosure(toggle,g.collection_filters_open)
 browse.add_child(toggle)
 var manage=g.button("Manage cultivars & nursery",func():GardenBreedingUI.open_library(g))
 manage.name="ManageCultivars"
 manage.visible=g.collection_filters.view=="My cultivars"
 g.list_box.add_child(manage)
 var filters=VBoxContainer.new()
 filters.name="SeedFilters"
 filters.visible=g.collection_filters_open
 filters.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 g.list_box.add_child(filters)
 var navigation=VBoxContainer.new()
 navigation.name="CollectionNavigation"
 filters.add_child(navigation)
 var groups=["All collections"]+GardenCatalogue.COLLECTION_GROUPS+["My cultivars"]
 if g.collection_filters.get("group","All collections") not in groups:g.collection_filters.group="All collections"
 var sorts=["Catalogue","Name","Height: low to high","Height: high to low","Growing days"]
 if g.collection_filters.get("sort","")=="Height":g.collection_filters.sort="Height: low to high"
 if g.collection_filters.get("sort","") not in sorts:g.collection_filters.sort="Catalogue"
 selector(g,navigation,"group",groups,"Collection")
 selector(g,navigation,"sort",sorts)
 selector(g,filters,"season",["Any season","Growing now","Spring","Summer","Autumn","Winter"])
 selector(g,filters,"light",["Any light","Sun","Shade","Water"])
 selector(g,filters,"height",["Any height","Low (under 0.6 m)","Medium (0.6–2 m)","Tall (2 m+)"])
 selector(g,filters,"colour",["Any colour","Cream / white","Red / pink","Yellow / orange","Green","Blue","Purple / pink","Dark"])
 selector(g,filters,"wildlife",["Any wildlife","Bees","Butterflies","Birds","Native birds","Frogs","Fireflies","Moths"])
 filters.add_child(g.button("Clear all filters",func():g.collection_query="";g.category="All";g.collection_filters=g.default_collection_filters();g.refresh_sidebar()))
 var active=HFlowContainer.new()
 active.name="ActiveFilters"
 g.list_box.add_child(active)
 var count=g.label("",14)
 count.name="SeedResults"
 count.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 g.list_box.add_child(count)
 var cards=GridContainer.new()
 cards.name="PlantCards"
 cards.columns=2
 cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 cards.add_theme_constant_override("h_separation",8)
 cards.add_theme_constant_override("v_separation",8)
 g.list_box.add_child(cards)
 update_cards(g)

static func update_categories(g) -> void:
 var picker=g.list_box.find_child("CollectionView",true,false)
 if not picker:return
 for index in range(picker.item_count):
  var choice=picker.get_item_metadata(index)
  if choice==null:continue
  if (choice.get("category","")==g.category and g.collection_filters.view=="All plants") or (choice.get("view","")==g.collection_filters.view):
   picker.select(index)
   return
 picker.select(0)

static func layout_cards(g, _available_width: float) -> void:
 var cards=g.list_box.get_node_or_null("PlantCards")
 if cards:cards.columns=2

static func active_filters(g) -> void:
 var box=g.list_box.get_node("ActiveFilters")
 for child in box.get_children():box.remove_child(child);child.queue_free()
 var defaults=g.default_collection_filters()
 var applied={}
 if g.category!="All":applied["category"]=g.category
 for key in ["group","season","light","height","colour","wildlife"]:
  if g.collection_filters[key]!=defaults[key]:applied[key]=g.collection_filters[key]
 for key in applied:
  var name=key
  var remove=g.button(str(applied[key])+" ×",func():
   if name=="category":g.category="All"
   else:g.collection_filters[name]=defaults[name]
   g.refresh_sidebar(),Vector2(0,28))
  remove.tooltip_text="Remove filter: "+str(applied[key])
  remove.custom_minimum_size.x=minf(260,remove.get_theme_font("font").get_string_size(remove.text,HORIZONTAL_ALIGNMENT_LEFT,-1,remove.get_theme_font_size("font_size")).x+24)
  box.add_child(remove)
 box.visible=not applied.is_empty()
 g.list_box.get_node("ManageCultivars").visible=g.collection_filters.view=="My cultivars"

static func details(g, plant: Dictionary) -> void:
 if plant.is_empty():return
 var id=int(plant.id)
 var uid=str(plant.get("form_uid",""))
 var custom=not uid.is_empty()
 var unlocked=custom or id in g.unlocked_plants
 g.side_title.text="Plant details"
 g.list_box.add_child(g.button("Back to seeds",g.touch.back_to_seeds))
 g.add_note(plant.name,18)
 var select_plant=func():
  if custom:GardenPlantBreeding.choose(g,uid)
  else:g.choose_plant(id)
 var can_plant=unlocked or g.coins>=int(plant.price)
 var action="Plant this" if unlocked else "Discover & plant · %d petals"%plant.price
 var image_button=g.button("",select_plant,Vector2(160,190))
 image_button.name="PlantPortrait"
 image_button.tooltip_text=action
 image_button.disabled=not can_plant
 g.list_box.add_child(image_button)
 var portrait: TextureRect
 if custom:
  portrait=GardenCultivarThumbnail.new()
  portrait.setup(g,GardenPlantBreeding.form(g,uid))
 else:
  portrait=TextureRect.new()
  portrait.texture=GardenMenus.plant_texture(id)
 portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
 portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 portrait.offset_left=8;portrait.offset_top=8;portrait.offset_right=-8;portrait.offset_bottom=-8
 image_button.add_child(portrait)
 var choose=g.button(action,select_plant)
 choose.name="PlantThisSeed"
 choose.disabled=not can_plant
 g.list_box.add_child(choose)
 if not unlocked:g.add_note("Discover once to keep unlimited seeds. You have %d petals."%g.coins,16)
 if not plant.get("botanical_name","").is_empty():g.add_note(plant.botanical_name,18)
 g.add_note("%s layer · %.1f m at maturity · %d capacity"%[["Groundcover","Flowers","Shrubs","Canopy"][plant.layer],float(plant.height),plant.capacity],17)
 if GardenChallenge.active(g):g.add_note(GardenChallenge.water_label(plant)+" · mulch and irrigation help with care",15)
 g.add_note("%d growing days · Likes %s\nGrows: %s\nWelcomes %s"%[plant.days,plant.condition,GardenCatalogue.growing_seasons(id),plant.animal],17)
 if plant.climber:g.add_note("Climbs nearby arbors and pergolas.",17)
 if custom:g.add_note(GardenPlantBreeding.traits(GardenPlantBreeding.form(g,uid)),17)
 var favourite=GardenPlantBreeding.form(g,uid).get("favourite",false) if custom else id in g.favourite_plants
 var favourite_button=g.button("Saved favourite" if favourite else "Save favourite",func():
  if custom:GardenPlantBreeding.form(g,uid).favourite=not favourite;g.save_game()
  else:toggle_favourite(g,id)
  g.refresh_sidebar())
 GardenTheme.favourite(favourite_button,favourite)
 g.list_box.add_child(favourite_button)
 g.add_note("Aim at soil or a planter pocket, then plant. Your seeds can be used again and again.")

static func update_cards(g) -> void:
 var cards=g.list_box.get_node_or_null("PlantCards")
 if cards==null: return
 for child in cards.get_children(): cards.remove_child(child); child.queue_free()
 var plants=matching(g)
 active_filters(g)
 g.list_box.get_node("SeedResults").text="%d varieties" % plants.size()
 if plants.is_empty():
  var empty=g.label("No plants match. Try another collection, category or clear your filters.",15)
  empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  empty.custom_minimum_size.x=240
  cards.add_child(empty)
  return
 for p in plants:
  var id: int=p.id
  var uid=str(p.get("form_uid",""))
  var custom=not uid.is_empty()
  var favourite=GardenPlantBreeding.form(g,uid).get("favourite",false) if custom else id in g.favourite_plants
  var unlocked=custom or id in g.unlocked_plants
  var b=g.button("",func():
   if g.touch_active():g.touch.open_seed_details(p)
   elif custom:GardenPlantBreeding.choose(g,uid)
   else:g.choose_plant(id),Vector2(120,0))
  b.name="CultivarCard"+uid if custom else "PlantCard%02d" % id
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  b.tooltip_text="%s · %.1f m at maturity · %d growing days\nGrows: %s · welcomes %s\n%s" % [p.name,float(p.get("height",1)),p.days,GardenCatalogue.growing_seasons(id),p.animal,"Discovered · unlimited seeds" if unlocked else "Discover for %d petals" % p.price]
  if not p.get("botanical_name","").is_empty():b.tooltip_text=p.botanical_name+"\n"+b.tooltip_text
  if p.climber: b.tooltip_text+="\nClimbs nearby arbors and pergolas."
  GardenTheme.choose(b,uid==g.selected_cultivar if custom else id==g.selected and g.selected_cultivar.is_empty())
  var content=GardenMenus.card_content(b)
  var portrait: TextureRect
  if custom:
   portrait=GardenCultivarThumbnail.new()
   portrait.setup(g,GardenPlantBreeding.form(g,uid))
  else:
   portrait=TextureRect.new()
   portrait.texture=GardenMenus.plant_texture(id)
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  portrait.custom_minimum_size=Vector2(96,108)
  portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
  portrait.modulate=Color.WHITE
  content.add_child(portrait)
  var title=g.label(p.name,16)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  title.mouse_filter=Control.MOUSE_FILTER_IGNORE
  content.add_child(title)
  var growing=GardenMenus.row(content)
  growing.alignment=BoxContainer.ALIGNMENT_CENTER
  growing.mouse_filter=Control.MOUSE_FILTER_IGNORE
  GardenMenus.stat(g,growing,p.condition,p.condition.capitalize(),"Preferred light or habitat")
  GardenMenus.stat(g,growing,"clock","%dd"%p.days,"Ideal growing days")
  if GardenChallenge.active(g):
   b.tooltip_text+="\n"+GardenChallenge.water_label(p)
   var water=g.label(["Low water","Moderate water","High water"][GardenChallenge.water_class(p)],12)
   water.mouse_filter=Control.MOUSE_FILTER_IGNORE
   content.add_child(water)
  var size_row=GardenMenus.row(content)
  size_row.alignment=BoxContainer.ALIGNMENT_CENTER
  size_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
  GardenMenus.stat(g,size_row,"height","%.1fm"%float(p.get("height",1)),"Mature height")
  GardenMenus.stat(g,size_row,"capacity",str(p.capacity),"Bed capacity")
  var availability=g.label("Ready to plant" if unlocked else "%d petals · Discover"%p.price,14)
  availability.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  availability.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  availability.mouse_filter=Control.MOUSE_FILTER_IGNORE
  content.add_child(availability)
  var info=g.button("",func():g.touch.open_seed_details(p),Vector2(30,30))
  info.name="PlantInfo"
  info.icon=preload("res://assets/ui/menu-info.svg")
  info.add_theme_constant_override("icon_max_width",18)
  info.tooltip_text="Growing details: "+p.name
  info.position=Vector2(4,4)
  b.add_child(info)
  var star=g.button("",func():
   if custom:GardenPlantBreeding.form(g,uid).favourite=not favourite;g.save_game();update_cards(g)
   else:toggle_favourite(g,id),Vector2(34,34))
  star.name="Favourite"
  GardenTheme.choose(star,favourite)
  GardenTheme.favourite(star,favourite)
  star.tooltip_text="Remove favourite" if favourite else "Save favourite"
  star.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
  star.offset_left=-48 if g.touch_active() else -38
  star.offset_right=-4
  star.offset_top=4
  star.offset_bottom=48 if g.touch_active() else 38
  b.add_child(star)
  cards.add_child(b)

static func toggle_favourite(g, id: int) -> void:
 if id in g.favourite_plants: g.favourite_plants.erase(id)
 else:g.favourite_plants.append(id)
 g.save_game()
 update_cards(g)

static func record_planting(g, id: int) -> void:
 g.recent_plants.erase(id)
 g.recent_plants.push_front(id)
 g.recent_plants.resize(mini(20,g.recent_plants.size()))
