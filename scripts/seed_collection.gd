class_name GardenSeedCollection
extends RefCounted

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
 for p in g.catalogue:
  if g.category!="All" and p.category!=g.category: continue
  if not g.collection_query.strip_edges().is_empty() and not p.name.to_lower().contains(g.collection_query.strip_edges().to_lower()): continue
  if filters.view=="Favourites" and p.id not in g.favourite_plants: continue
  if filters.view=="Recently planted" and p.id not in g.recent_plants: continue
  if filters.view=="Discovered" and p.id not in g.unlocked_plants: continue
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
 if filters.view=="Recently planted": found.sort_custom(func(a,b): return g.recent_plants.find(a.id)<g.recent_plants.find(b.id))
 elif filters.sort=="Name": found.sort_custom(func(a,b): return a.name.naturalnocasecmp_to(b.name)<0)
 elif filters.sort=="Height": found.sort_custom(func(a,b): return float(a.get("height",1))<float(b.get("height",1)))
 elif filters.sort=="Growing days": found.sort_custom(func(a,b): return a.days<b.days)
 return found

static func selector(g, parent: Node, key: String, options: Array) -> void:
 var row=HBoxContainer.new()
 parent.add_child(row)
 row.add_child(g.label(key.capitalize(),13))
 var choices=OptionButton.new()
 choices.name="Filter"+key.capitalize()
 choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 choices.fit_to_longest_item=false
 choices.clip_text=true
 choices.custom_minimum_size.y=42 if g.touch_active() else 32
 for option in options: choices.add_item(option)
 choices.select(maxi(0,options.find(g.collection_filters[key])))
 choices.item_selected.connect(func(index):
  g.collection_filters[key]=options[index]
  update_cards(g))
 row.add_child(choices)

static func build(g) -> void:
 g.side_title.text="The seed collection"
 var search=LineEdit.new()
 search.name="SeedSearch"
 search.placeholder_text="Search all plants…"
 search.text=g.collection_query
 search.clear_button_enabled=true
 search.custom_minimum_size.y=44 if g.touch_active() else 36
 search.text_changed.connect(func(value):
  g.collection_query=value
  if not value.is_empty(): g.category="All"
  update_categories(g)
  update_cards(g))
 g.list_box.add_child(search)
 if g.get_viewport().get_visible_rect().size.y<700:
  var picker=g.button("Category: "+g.category+" ▾",func():
   var categories=g.list_box.get_node("SeedCategories")
   categories.visible=not categories.visible
   update_categories(g),Vector2(0,42))
  picker.name="CategoryPicker"
  g.list_box.add_child(picker)
 var cats=GridContainer.new()
 cats.name="SeedCategories"
 cats.columns=3
 cats.visible=g.get_viewport().get_visible_rect().size.y>=700
 g.list_box.add_child(cats)
 for category in ["All"]+GardenCatalogue.CATEGORIES:
  var chosen=category
  var b=g.button(category,func(): g.category=chosen; update_categories(g); update_cards(g),Vector2(81,40 if g.touch_active() else 30))
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  b.add_theme_font_size_override("font_size",14)
  cats.add_child(b)
 update_categories(g)
 var browse=HBoxContainer.new()
 g.list_box.add_child(browse)
 var views=OptionButton.new()
 views.name="CollectionView"
 views.fit_to_longest_item=false
 views.clip_text=true
 views.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 views.custom_minimum_size.y=42 if g.touch_active() else 34
 var modes=["All plants","Discovered","Favourites","Recently planted"]
 for name in modes: views.add_item(name)
 views.select(maxi(0,modes.find(g.collection_filters.view)))
 views.item_selected.connect(func(index): g.collection_filters.view=modes[index]; update_cards(g))
 browse.add_child(views)
 var filter_toggle=g.button("Filters ▴" if g.collection_filters_open else "Filters ▾",func():
  g.collection_filters_open=not g.collection_filters_open
  g.list_box.get_node("SeedFilters").visible=g.collection_filters_open
  g.list_box.get_node("FilterToggle").text="Filters ▴" if g.collection_filters_open else "Filters ▾",Vector2(85,34))
 filter_toggle.name="FilterToggle"
 browse.add_child(filter_toggle)
 var filters=VBoxContainer.new()
 filters.name="SeedFilters"
 filters.visible=g.collection_filters_open
 filters.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 g.list_box.add_child(filters)
 selector(g,filters,"season",["Any season","Growing now","Spring","Summer","Autumn","Winter"])
 selector(g,filters,"light",["Any light","Sun","Shade","Water"])
 selector(g,filters,"height",["Any height","Low (under 0.6 m)","Medium (0.6–2 m)","Tall (2 m+)"])
 selector(g,filters,"colour",["Any colour","Cream / white","Red / pink","Yellow / orange","Green","Blue","Purple / pink","Dark"])
 selector(g,filters,"wildlife",["Any wildlife","Bees","Butterflies","Birds","Native birds","Frogs","Fireflies","Moths"])
 selector(g,filters,"sort",["Catalogue","Name","Height","Growing days"])
 filters.add_child(g.button("Clear filters",func():
  g.collection_query=""
  g.category="All"
  g.collection_filters=g.default_collection_filters()
  g.refresh_sidebar()))
 var count=g.label("",13)
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
 g.detail_label.text="%s\n%s layer · %d capacity · %d growing days\nLikes %s · welcomes %s\nGrows: %s" % [g.catalogue[g.selected].name,["Ground","Flower","Shrub","Canopy"][g.catalogue[g.selected].layer],g.catalogue[g.selected].capacity,g.catalogue[g.selected].days,g.catalogue[g.selected].condition,g.catalogue[g.selected].animal,GardenCatalogue.growing_seasons(g.selected)]
 if g.catalogue[g.selected].climber:g.detail_label.text+="\nClimbs nearby arbors & pergolas."

static func update_categories(g) -> void:
 var picker=g.list_box.get_node_or_null("CategoryPicker")
 if picker:picker.text="Category: "+g.category+(" ▴" if g.list_box.get_node("SeedCategories").visible else " ▾")
 for b in g.list_box.get_node("SeedCategories").get_children():
  GardenTheme.choose(b,b.text==g.category)

static func update_cards(g) -> void:
 var cards=g.list_box.get_node_or_null("PlantCards")
 if cards==null: return
 for child in cards.get_children(): cards.remove_child(child); child.queue_free()
 var plants=matching(g)
 g.list_box.get_node("SeedResults").text="%d varieties · ★ to save a favourite" % plants.size()
 if plants.is_empty():
  var empty=g.label("No plants match. Try another category or clear your filters.",15)
  empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  empty.custom_minimum_size.x=240
  cards.add_child(empty)
  return
 for p in plants:
  var id: int=p.id
  var unlocked=id in g.unlocked_plants
  var b=g.button("",func(): g.choose_plant(id),Vector2(120,300 if g.touch_active() else 210))
  b.name="PlantCard%02d" % id
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  b.tooltip_text="%s · %.1f m mature model · %d growing days\nGrows: %s · welcomes %s\n%s" % [p.name,float(p.get("height",1)),p.days,GardenCatalogue.growing_seasons(id),p.animal,"Discovered · unlimited seeds" if unlocked else "Discover for %d petals" % p.price]
  if p.climber: b.tooltip_text+="\nClimbs nearby arbors and pergolas."
  GardenTheme.choose(b,id==g.selected)
  var content=VBoxContainer.new()
  content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  content.offset_left=6;content.offset_right=-6;content.offset_top=6;content.offset_bottom=-6
  content.add_theme_constant_override("separation",1)
  content.mouse_filter=Control.MOUSE_FILTER_IGNORE
  b.add_child(content)
  var minimum_height=300 if g.touch_active() else 210
  content.minimum_size_changed.connect(func():
   b.custom_minimum_size.y=maxf(minimum_height,content.get_combined_minimum_size().y+12))
  var portrait=TextureRect.new()
  portrait.texture=load("res://assets/ui/plants/%02d.png" % id)
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  portrait.custom_minimum_size=Vector2(96,106)
  portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
  portrait.modulate=Color.WHITE if unlocked else Color(.65,.61,.52)
  content.add_child(portrait)
  var name_size=18 if g.touch_active() else 16
  var detail_size=15 if g.touch_active() else 14
  var timing="%d days%s%s"%[p.days," · " if g.touch_active() else "\n","Year-round" if p.seasons.is_empty() else "/".join(p.seasons)]
  for line in [[p.name,name_size],["Likes "+p.condition+" · %.1f m"%float(p.get("height",1)),detail_size],[timing,detail_size],["Capacity %d"%p.capacity if unlocked else "Discover: %d petals"%p.price,detail_size]]:
   var text=g.label(line[0],line[1])
   text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
   text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   text.mouse_filter=Control.MOUSE_FILTER_IGNORE
   text.add_theme_color_override("font_color",GardenTheme.TEXT if line[1]==name_size else GardenTheme.MUTED)
   content.add_child(text)
  var star=g.button("★" if id in g.favourite_plants else "☆",func(): toggle_favourite(g,id),Vector2(34,34))
  star.name="Favourite"
  GardenTheme.choose(star,id in g.favourite_plants)
  star.tooltip_text="Remove favourite" if id in g.favourite_plants else "Save favourite"
  star.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
  star.offset_left=-54 if g.touch_active() else -38
  star.offset_right=-4
  star.offset_top=4
  star.offset_bottom=54 if g.touch_active() else 38
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
