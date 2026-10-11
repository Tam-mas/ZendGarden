class_name GardenMenus
extends RefCounted

static var plant_previews: Dictionary={}

# Crop transparent portrait margins at display time, keeping original assets and
# making short plants as readable as tall ones. Height is stated on every card.
static func plant_texture(id: int) -> Texture2D:
 if plant_previews.has(id):return plant_previews[id]
 var original: Texture2D=load(GardenArt.card_path("res://assets/ui/plants/%02d"%id))
 var pixels=original.get_image()
 var used=pixels.get_used_rect()
 var atlas=AtlasTexture.new()
 atlas.atlas=original
 atlas.region=used.grow(4).intersection(Rect2i(Vector2i.ZERO,pixels.get_size())) if used.has_area() else Rect2i(Vector2i.ZERO,pixels.get_size())
 plant_previews[id]=atlas
 return atlas

# Navigation is session-only; garden saves and game rules keep their existing shape.
static func visit(g, page: String) -> void:
 g.menu_scroll[g.active_tab]=g.list_box.get_parent().scroll_vertical
 if page=="Shop" and g.active_tab!="Shop":g.surface_shop_plot=g.current_plot
 g.active_tab=page
 g.side_panel.show()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if g.touch_active():g.touch.reset_gestures()
 g.refresh_sidebar()
 restore_scroll(g,page,int(g.menu_scroll.get(page,0)))

static func restore_scroll(g, page: String, amount: int) -> void:
 await g.get_tree().process_frame
 await g.get_tree().process_frame
 if g.active_tab==page:g.list_box.get_parent().scroll_vertical=amount

static func close(g) -> void:
 g.menu_scroll[g.active_tab]=g.list_box.get_parent().scroll_vertical
 g.side_panel.hide()
 g.get_viewport().gui_release_focus()
 if g.touch_active():g.touch.reset_gestures()
 g.resume_controls()

static func note(g, parent: Node, text: String, font_size: int=14) -> Label:
 var label=g.label(text,font_size)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(label)
 return label

static func row(parent: Node) -> HBoxContainer:
 var box=HBoxContainer.new()
 box.add_theme_constant_override("separation",6)
 box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(box)
 return box

static func sections(g, options: Array, key: String) -> void:
 var box=HFlowContainer.new()
 box.add_theme_constant_override("h_separation",5)
 box.add_theme_constant_override("v_separation",5)
 g.list_box.add_child(box)
 for title in options:
  var chosen=title
  var button=g.button(title,func():g.menu_sections[key]=chosen;g.refresh_sidebar();g.list_box.get_parent().set_deferred("scroll_vertical",0),Vector2(0,34))
  button.custom_minimum_size.x=button.get_theme_font("font").get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x+24
  button.name=title.replace(" ","")+"Section"
  GardenTheme.choose(button,g.menu_sections[key]==title)
  box.add_child(button)

static func disclosure(g, parent: Node, title: String, text: String) -> void:
 var body=g.label(text,14)
 body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 body.hide()
 var toggle=g.button(title,func():body.visible=not body.visible)
 toggle.pressed.connect(func():GardenTheme.disclosure(toggle,body.visible))
 GardenTheme.disclosure(toggle)
 parent.add_child(toggle)
 parent.add_child(body)

# Each card grows only to fit its preview and text. No fixed blank card height.
static func card_content(button: Button) -> VBoxContainer:
 var content=VBoxContainer.new()
 content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 content.offset_left=8;content.offset_right=-8;content.offset_top=8;content.offset_bottom=-8
 content.add_theme_constant_override("separation",3)
 content.mouse_filter=Control.MOUSE_FILTER_IGNORE
 button.add_child(content)
 content.minimum_size_changed.connect(func():button.custom_minimum_size.y=content.get_combined_minimum_size().y+16)
 return content

static func portrait(parent: Node, path: String, height: float=108) -> TextureRect:
 var image=TextureRect.new()
 image.texture=load(GardenArt.card_path(path))
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size=Vector2(64,height)
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(image)
 return image

static func stat(g, parent: Node, kind: String, text: String, description: String) -> void:
 var box=row(parent)
 box.alignment=BoxContainer.ALIGNMENT_CENTER
 box.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var image=TextureRect.new()
 image.texture=load("res://assets/ui/menu-"+kind+".svg")
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.custom_minimum_size=Vector2(16,16)
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 box.add_child(image)
 var label=g.label(text,14)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 box.add_child(label)
 box.tooltip_text=description

static func shop(g) -> void:
 g.side_title.text="Shop · %d petals"%g.coins
 sections(g,["Decor","Tools","Bed care","Equipment","Owned"],"shop")
 var section=str(g.menu_sections.shop)
 if section in ["Decor","Equipment"]:
  if section=="Equipment":
   g.list_box.add_child(g.button("My equipment, supplies & nursery",func():GardenWorkshop.open(g)))
  var grid=GridContainer.new()
  grid.name="OrnamentCards"
  grid.columns=2
  grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  grid.add_theme_constant_override("h_separation",8)
  grid.add_theme_constant_override("v_separation",8)
  g.list_box.add_child(grid)
  for index in range(g.furniture.size()):
   var item=g.furniture[index]
   var equipment=item.kind in GardenEquipment.KINDS or item.kind in GardenContainers.SPECS
   if equipment!=(section=="Equipment"):continue
   var id=index
   var button=g.button("",func():g.choose_furnishing(id),Vector2(120,0))
   button.name="Shop_"+item.kind
   button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   button.tooltip_text=item.name+" · "+item.hint+"\nChoose a place in the garden."
   grid.add_child(button)
   var content=card_content(button)
   portrait(content,"res://assets/ui/shop/"+item.kind)
   for text in [item.name,"%d petals"%item.price]:
    var caption=note(g,content,text)
    caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 elif section=="Tools":
  var names={"can":"Watering can","shears":"Pruning shears","trowel":"Planting trowel","rake":"Garden rake","gather":"Gather reach"}
  var benefits={"can":"Wider watering; the water lasts longer.","shears":"A 10% wider pruning square per upgrade.","trowel":"Less waiting between planting clicks.","rake":"Wider paths and more found petals.","gather":"A %.1f m square → %.1f m square."}
  for kind in names:
   var k=kind
   var level=int(g.upgrades[k])
   g.add_note(names[k]+" · "+("fully upgraded" if level>=2 else "level %d → %d"%[level,level+1]),17)
   g.add_note(benefits[k]%[1.3+level*.8,1.3+(level+1)*.8] if k=="gather" and level<2 else "Maximum gathering reach." if k=="gather" else benefits[k])
   if level<2:
    var day=3 if level==0 else 18
    var action=g.button("Upgrade · %d petals"%(45+level*45) if g.day>=day else "Available day %d"%day,func():g.buy_tool(k))
    action.disabled=g.day<day or g.coins<45+level*45
    g.list_box.add_child(action)
  disclosure(g,g.list_box,"Using your tools","The hoe is included. Choose it from the tool tray or press 9. R switches raise/lower; [ / ] adjust the pruning square within your upgrades.")
 elif section=="Bed care":
  g.add_note("CARE FOR · "+g.plots[g.current_plot].name,16)
  g.add_note("Care systems and extra capacity apply to the bed you are standing in.")
  for kind in ["water","prune"]:
   var k=kind
   var owned=g.automation.has(str(g.current_plot)+k)
   var name="Soaker system" if k=="water" else "Gentle auto-pruner"
   var action=g.button(name+(" · owned" if owned else " · 45 petals"),func():g.buy_automation(k))
   action.disabled=owned or g.day<7 or g.coins<45
   g.list_box.add_child(action)
  if g.day<7:g.add_note("Care systems arrive on day 7.")
  g.list_box.add_child(g.button("Add 80 capacity · 65 petals",g.expand_bed))
  GardenBedSurfaces.shop(g)
  g.list_box.add_child(g.button("More garden space & milestones",func():
   g.menu_sections.guide="";g.menu_scroll.Guide=0
   visit(g,"Guide")
   g.list_box.get_node("MoregardenspaceSection").pressed.emit()))
 else:
  g.list_box.add_child(g.button("Equipment, containers & stored plants",func():GardenWorkshop.open(g)))
  var signs=0
  for index in range(g.objects.size()):
   if g.objects[index].kind!="sign":continue
   signs+=1
   var id=index
   g.list_box.add_child(g.button("Edit sign: "+str(g.objects[index].get("text","My garden")),func():g.open_sign_editor(id)))
  if signs==0:g.add_note("Your placed signs will appear here for editing.")
  g.add_note("PONDS · "+g.plots[g.current_plot].name,16)
  g.list_box.add_child(g.button("Stock a pond with fish · 20 petals",g.stock_fish))
  disclosure(g,g.list_box,"Moving and arranging","Use Move in the garden to rearrange an object. Rotate while placing or moving: Q/E on keyboard, Turn left/right on touch.")

static func reserved(g, id: int) -> int:
 var total=0
 for order in g.orders:
  if not order.get("pending",false) and int(order.plant)==id:total+=int(order.count)
 return total

static func orders(g) -> void:
 g.side_title.text="Orders"
 g.request_unread=false
 g.request_popup_time=0
 sections(g,["Requests","Basket"],"orders")
 if g.menu_sections.orders=="Basket":
  g.add_note("%d harvested items"%g.basket_total(),17)
  var spare_count=0
  var spare_value=0
  for plant in g.catalogue:
   var amount=int(g.inventory.get(str(plant.id),0))
   if amount==0:continue
   var kept=mini(amount,reserved(g,plant.id))
   var spare=amount-kept
   spare_count+=spare
   spare_value+=spare*maxi(1,int(plant.value)/2)
   var line=row(g.list_box)
   portrait(line,"res://assets/ui/plants/%02d"%plant.id,54)
   var words=VBoxContainer.new()
   words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   line.add_child(words)
   note(g,words,"%s × %d"%[plant.name,amount],16)
   note(g,words,"%d kept for requests · %d spare"%[kept,spare] if kept else "%d spare"%spare)
  if g.basket_total()==0:g.add_note("Gather or prune a mature plant to start your basket.")
  var sell=g.button("Sell %d spare · +%d petals"%[spare_count,GardenEconomy.preview(g,spare_value)],g.sell_harvest)
  sell.disabled=spare_count==0
  g.list_box.add_child(sell)
  g.add_note("Items needed for current requests stay in your basket.")
 else:
  g.add_note("No deadlines. A thank-you whenever you're ready.")
  var indices=range(g.orders.size())
  indices.sort_custom(func(a,b):return ready(g,g.orders[a]) and not ready(g,g.orders[b]))
  var notes=[]
  for index in indices:
   var order=g.orders[index]
   if order.get("pending",false):
    if not order.get("welcome",false):notes.append(order.person+" · next note on day %d"%order.ready_day)
    continue
   var id=index
   var plant=g.catalogue[int(order.plant)]
   var amount=int(g.inventory.get(str(int(order.plant)),0))
   var line=row(g.list_box)
   portrait(line,"res://assets/ui/plants/%02d"%int(order.plant),72)
   var words=VBoxContainer.new()
   words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   line.add_child(words)
   note(g,words,order.person,17)
   note(g,words,"%s · %d / %d gathered"%[plant.name,mini(amount,int(order.count)),order.count])
   note(g,words,"Thank-you: %d petals"%GardenEconomy.preview(g,int(order.reward)))
   if ready(g,order):g.list_box.add_child(g.button("Deliver request",func():g.fulfill_order(id)))
   else:
    var name=plant.name
    g.list_box.add_child(g.button("Need %d more · Find seeds"%maxi(0,int(order.count)-amount),func():
     g.collection_filters=g.default_collection_filters();g.category="All";g.collection_query=name;visit(g,"Seeds")))
  if not notes.is_empty():disclosure(g,g.list_box,"Neighbour notes", "\n".join(notes))
 disclosure(g,g.list_box,"How to gather for orders","Prune or gather a mature plant to collect one item and start its next bloom. Border plants give one item per day. Hold Gather and sweep to collect ready plants across all layers.")

static func ready(g, order: Dictionary) -> bool:
 return not order.get("pending",false) and int(g.inventory.get(str(int(order.plant)),0))>=int(order.count)

static func toggle(g, parent: Node, key: String, title: String) -> void:
 var control=CheckButton.new()
 control.text=title
 control.name=key
 control.clip_text=true
 control.tooltip_text=title
 control.custom_minimum_size.y=48 if g.touch_active() else 36
 control.button_pressed=g.settings[key]
 control.toggled.connect(func(value):g.settings[key]=value;g.apply_settings();g.touch.last_size=Vector2.ZERO;g.save_game())
 parent.add_child(control)

static func slider(g, parent: Node, key: String, title: String, low: float, high: float, step: float, unit: String="") -> void:
 var caption=note(g,parent,"",14)
 var control=HSlider.new()
 control.name=key
 control.min_value=low;control.max_value=high;control.step=step
 control.value=g.settings.get(key,0)
 caption.text=title+" · "+str(control.value)+unit
 control.custom_minimum_size.y=44 if g.touch_active() else 28
 control.value_changed.connect(func(value):
  g.settings[key]=value;caption.text=title+" · "+str(value)+unit
  g.apply_settings();g.touch.last_size=Vector2.ZERO)
 control.drag_ended.connect(func(_changed):g.save_game())
 parent.add_child(control)

static func choice(g, parent: Node, key: String, title: String, values: Array, labels: Array) -> void:
 note(g,parent,title)
 var control=OptionButton.new()
 control.name=key
 control.fit_to_longest_item=false
 control.clip_text=true
 control.custom_minimum_size.y=48 if g.touch_active() else 36
 for text in labels:control.add_item(text)
 control.select(maxi(0,values.find(g.settings[key])))
 control.item_selected.connect(func(index):
  g.settings[key]=values[index]
  g.touch.configure();g.save_game()
  if key=="controls":g.call_deferred("refresh_sidebar"))
 parent.add_child(control)

static func settings(g) -> void:
 g.side_title.text="Settings"
 var bodies={}
 var headers={}
 for title in ["Sound","Controls","Display","Comfort & play","Save files","About"]:
  var section=title
  var header=g.button(title,func():
   g.menu_sections.settings="" if g.menu_sections.settings==section else section
   for name in bodies:
    bodies[name].visible=g.menu_sections.settings==name
    GardenTheme.disclosure(headers[name],bodies[name].visible)
    GardenTheme.choose(headers[name],bodies[name].visible))
  header.name="Settings"+title.replace(" ","").replace("&","")
  header.alignment=HORIZONTAL_ALIGNMENT_LEFT
  g.list_box.add_child(header)
  var body=VBoxContainer.new()
  body.name=title.replace(" ","").replace("&","")+"Options"
  body.add_theme_constant_override("separation",7)
  g.list_box.add_child(body)
  body.visible=g.menu_sections.settings==title
  bodies[title]=body;headers[title]=header
  GardenTheme.disclosure(header,body.visible)
  GardenTheme.choose(header,body.visible)
  match title:
   "Sound":
    slider(g,body,"volume","Master volume",0,100,1,"%")
    slider(g,body,"music_volume","Music volume",0,100,1,"%")
    slider(g,body,"nature_volume","Nature sounds",0,100,1,"%")
   "Controls":
    choice(g,body,"controls","Input method",["auto","touch","keyboard"],["Auto","Touch","Keyboard & mouse"])
    toggle(g,body,"invert_x","Invert look left / right")
    toggle(g,body,"invert_y","Invert look up / down")
    slider(g,body,"sensitivity","Look sensitivity",.3,2,.1)
    if g.touch_active():
     toggle(g,body,"left_handed","Left-handed controls")
     slider(g,body,"control_size","Touch control size",80,120,10,"%")
     slider(g,body,"touch_inset","Spacing from edges",0,100,10)
     slider(g,body,"touch_height","Raise controls",0,120,10)
     note(g,body,"Control position applies on tablets and unfolded phones.")
   "Display":
    choice(g,body,"graphics","Graphics quality",["auto","mobile","standard"],["Auto","Lighter","Standard"])
    note(g,body,"Auto balances detail in fuller gardens. Standard keeps full plant shadows.")
    choice(g,body,"render_scale","3D resolution",[0,50,70,85,100],["Auto","50%","70%","85%","100%"])
    slider(g,body,"fov","Field of view",55,90,1,"°")
   "Comfort & play":
    toggle(g,body,"reduced_motion","Reduced motion")
    note(g,body,"Skip time-lapse and menu fades; keep water still.")
    toggle(g,body,"pause_menus","Pause time in menus")
    toggle(g,body,"request_notifications","Neighbour request pop-ups")
    choice(g,body,"petal_rate","Petal earnings",GardenEconomy.MODES,GardenEconomy.LABELS)
    note(g,body,"Changes earnings from harvest, requests and raking. Prices and growth stay the same.")
   "Save files":
    note(g,body,"Your garden saves as you play. Download a copy to keep a backup or move devices.")
    body.add_child(g.button("Save garden now",func():g.toast("Your garden is saved." if g.save_game() else "Could not save. Please try again.")))
    body.add_child(g.button("Download save file",func():g.save_files.download()))
    body.add_child(g.button("Upload save file…",func():g.save_files.upload()))
    if FileAccess.file_exists(g.save_files.backup_path()):body.add_child(g.button("Download previous garden",func():g.save_files.download(true)))
    note(g,body,"Upload asks before replacing your garden.")
    body.add_child(HSeparator.new())
    body.add_child(g.button("Start a new garden…",func():GardenExperience.confirm_restart(g)))
   "About":
    note(g,body,"Zend Garden · Update %d"%GardenUpdates.CURRENT_VERSION,17)
    body.add_child(g.button("What’s new",func():GardenUpdates.show(g)))

static func guide_group(g, title: String) -> VBoxContainer:
 var body=VBoxContainer.new()
 body.name=title.replace(" ","")+"Options"
 body.add_theme_constant_override("separation",7)
 body.hide()
 var header=g.button(title,func():body.visible=not body.visible)
 header.name=title.replace(" ","")+"Section"
 header.alignment=HORIZONTAL_ALIGNMENT_LEFT
 header.pressed.connect(func():GardenTheme.disclosure(header,body.visible))
 GardenTheme.disclosure(header)
 g.list_box.add_child(header)
 g.list_box.add_child(body)
 return body

static func garden_actions(g) -> void:
 g.list_box.add_child(g.button("Garden atlas · milestones & trails",func():GardenAreaAtlas.open(g)))
 var actions=guide_group(g,"Garden actions")
 actions.add_child(g.button("Next morning",func():close(g);g.next_day()))
 actions.add_child(g.button("Photo mode",func():close(g);g.toggle_photo()))
 actions.add_child(g.button("Enjoy the view",func():GardenClearView.enter(g)))
 var companions=guide_group(g,"Companions")
 for index in range(g.companion_names.size()):
  var id=index
  note(g,companions,"Cat" if id==0 else "Dog")
  var field=LineEdit.new()
  field.text=g.companion_names[id]
  field.placeholder_text="Name your "+("cat" if id==0 else "dog")
  field.max_length=24
  field.custom_minimum_size.y=44 if g.touch_active() else 36
  field.text_changed.connect(func(value):g.companion_names[id]=value)
  field.focus_exited.connect(func():g.save_game())
  companions.add_child(field)
  companions.add_child(g.button("Call companion",func():close(g);GardenLeisure.call_pet(g,id)))
  if not g.rest_kind.is_empty():companions.add_child(g.button("Invite to settle",func():close(g);GardenLeisure.call_pet(g,id,true)))
 if not g.rest_kind.is_empty():companions.add_child(g.button("Stand up",func():close(g);GardenLeisure.leave(g)))
 if g.pets.any(func(p):return p.position.distance_to(g.player.position)<4):companions.add_child(g.button("Pet companion",func():close(g);g.greet_pet()))
 var space=guide_group(g,"More garden space")
 var next=GardenAreaCatalogue.next_plot(g)
 if next<g.plots.size():space.add_child(g.button("Open "+g.plots[next].name+" · %d petals"%g.plots[next].cost,g.buy_plot))
 note(g,space,"New beds open freely as the days pass. After day 36, another opens every 12 days. The atlas shows the ten garden milestones and your progress.")

const GUIDE={
 "Getting started":["Choose a seed, find a spot in an open bed and plant it. Water and gather as it grows. Your garden has no deadlines and plants never die.","Use the tool bar or touch tool tray to choose an action. Seeds keeps your collection, Shop holds upgrades and objects, and Orders shows neighbours’ requests."],
 "Plants, seasons & layers":["Groundcover, flowers and shrubs share planting rows. Trees sit between rows, above the underplanting. Each uses 1, 2, 4 or 7 capacity. Switch target layers with L or the Layer control. Trees shade nearby plants; leave sunny flowers at the edges.","A day lasts 10 minutes and a season lasts 12 days. Plants take 2–28 ideal growing days. Plants resting outside their season keep all progress; greenhouses allow year-round growth. Rain gently waters plants.","On seed cards: the sun, shade or water symbol shows preferred light or habitat; the clock shows ideal growing days, the ruler shows mature height, and the stacked squares show capacity. Open a plant’s information button for seasons and wildlife."],
 "Tools & landscaping":["Hold Water and sweep across the ground. Manual watering gives +20% growth for one game day; rewatering refreshes the timer. Rain and soakers do not apply this bonus.","Bed plants are safe to prune repeatedly. Outside beds, three cuts clear a plant; planted varieties recover one cut per morning. [ / ] resize the pruning square within your upgrades.","Rake open ground to remove grass and leave a path. Move or prune plants first. Upgrades widen existing patches; new patches can reveal up to four petals per day.","The hoe reshapes unlocked dry ground. R switches raise/lower, or use the touch action control."],
 "Gathering & requests":["Hold Gather and sweep across plants. Every ready plant in the square is collected, on every layer; unready plants stay growing. Gather upgrades widen its square from 1.3 m to 2.1 m, then 2.9 m. Border plants yield once per day.","Requests show what you have and what is missing. Deliver whenever you like. The Basket section keeps harvest needed for current requests when you sell spare items."],
 "Cultivars & nursery":["Preserve a flowering selection at a potting bench, name it and keep it in My cultivars. Cross two forms of the same species, grow a tray of four seedlings and choose the next generation.","Open My cultivars from Seeds for traits, parentage and your library. Equipment and nursery management is under Shop → Equipment. Planted containers keep their plants when moved; packed-away plants are kept in the nursery."],
 "Wildlife & companions":["Native plants welcome native birds. Two flowering plants or produce welcome lady beetles; three flowering plants welcome bees and butterflies. Trees or bird baths welcome songbirds; ponds welcome frogs and dragonflies. Moss and dusk bring fireflies. A beehive brings daytime bees; rabbits occasionally visit open ground.","Stock a placed pond from Shop → Owned. Name and call companions under Guide → Companions. E rests near a bench, pergola or pond; F pets a nearby companion and C calls both. While resting, invite them to settle beside you."],
 "Structures & photos":["Rotate a structure in 15° steps while placing or moving it: Q/E on keyboard or Turn left/right on touch. Tab releases the pointer for rotation buttons. Edit placed signs in Shop → Owned.","P opens photo mode. WASD flies, Q/E moves down/up, right-drag looks around and F12 captures a photo. Use the touch photo controls on a tablet. Return with P or Done.","Enjoy the view hides the interface and held tool. Mouse look still works. Press any key or click/tap to return."],
 "Controls & saving":["Keyboard: WASD or arrows walk, Shift strolls faster, mouse looks, 1–9 selects tools, Tab opens/closes menus, and Escape opens Settings. G welcomes the next morning; H hides the interface.","Touch: left thumb walks and right thumb looks. Tap the current tool to open the tool tray. Hold Water, Gather, Rake or the hoe action and drag the same thumb to look; release to stop.","Your garden saves on this device. Settings → Save files lets you download a copy or upload it elsewhere. Upload asks before replacement, and the previous garden is kept as a backup."]
}

static func guide(g) -> void:
 g.side_title.text="Guide"
 var topic=str(g.menu_sections.guide)
 if GUIDE.has(topic):
  g.list_box.add_child(g.button("Back to guide",func():g.menu_sections.guide="";g.refresh_sidebar();g.list_box.get_parent().set_deferred("scroll_vertical",0)))
  g.add_note(topic,18)
  for paragraph in GUIDE[topic]:g.add_note(paragraph,15)
  return
 garden_actions(g)
 g.add_note("HELP TOPICS",14)
 var search=LineEdit.new()
 search.name="GuideSearch"
 search.placeholder_text="Find a topic…"
 search.clear_button_enabled=true
 search.custom_minimum_size.y=44 if g.touch_active() else 36
 g.list_box.add_child(search)
 var topics=VBoxContainer.new()
 g.list_box.add_child(topics)
 for title in GUIDE:
  var chosen=title
  topics.add_child(g.button(title,func():g.menu_sections.guide=chosen;g.refresh_sidebar();g.list_box.get_parent().set_deferred("scroll_vertical",0)))
 search.text_changed.connect(func(value):
  for button in topics.get_children():button.visible=(button.text+" "+" ".join(GUIDE[button.text])).to_lower().contains(value.to_lower()))
 g.list_box.add_child(g.button("Replay the welcome walk",g.show_welcome))
