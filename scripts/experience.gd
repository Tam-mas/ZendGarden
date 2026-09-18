class_name GardenExperience
extends RefCounted

const PAGES = [
 ["A hilltop of your own", "Breathe in. There is room here for a small beginning.", "WASD to wander · Mouse to look\nTab opens your garden menus. Nothing needs to be perfect.", [28,29,35]],
 ["Plant a little possibility", "Choose a colour. Find a patch of earth. Begin.", "Open Seeds with Tab, choose a plant, aim at soil and click.\nDiscovered seeds are endless. A small marker shows where life is waiting.", [0,1,2]],
 ["Find your gentle rhythm", "Some things bloom tomorrow. Others ask for a season.", "Press 3 to water · Press 4 to prune · Press G for morning\nCare helps growth. Read each plant’s seasons in Seeds. Plants never die.", [7,20,47]],
 ["A garden that gives back", "A handful of flowers can become a neighbour’s joy.", "Press 5 to gather mature plants, then open Orders to deliver your basket.\nRequests have no deadline. Earn petals for seeds, tools and the garden shed.", [48,50,0]],
 ["Let it become yours", "More paths, new seasons, and familiar little visitors.", "New beds and seeds open over time. There is always room to grow.\nPress 6 to move things · Press P to take a photo.", [36,32,34]]
]

static func welcome(g, page: int = 0) -> void:
 if is_instance_valid(g.welcome): g.welcome.queue_free()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if not is_instance_valid(g.welcome_backdrop):
  g.welcome_backdrop=ColorRect.new()
  g.welcome_backdrop.color=Color(.07,.12,.09,.65)
  g.welcome_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  g.welcome_backdrop.z_index=29
  g.ui.add_child(g.welcome_backdrop)
 g.welcome=g.panel_at(Vector2(375,120),Vector2(740,640))
 g.welcome.z_index=30
 var col=VBoxContainer.new()
 col.add_theme_constant_override("separation",16)
 g.welcome.add_child(col)
 var chapter=g.label("A LITTLE GROWTH, EVERY DAY    ·    %d / 5" % (page+1),13,Color("ccb47e"))
 chapter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 col.add_child(chapter)
 var art=HBoxContainer.new()
 art.alignment=BoxContainer.ALIGNMENT_CENTER
 col.add_child(art)
 for id in PAGES[page][3]:
  var frame=PanelContainer.new()
  frame.add_theme_stylebox_override("panel",GardenTheme.frame("button"))
  var portrait=TextureRect.new()
  portrait.texture=load("res://assets/ui/plants/%02d.png" % id)
  portrait.custom_minimum_size=Vector2(170,200)
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  frame.add_child(portrait)
  art.add_child(frame)
 for pair in [[PAGES[page][0],32],[PAGES[page][1],19],[PAGES[page][2],17]]:
  var text=g.label(pair[0],pair[1])
  text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  text.custom_minimum_size.x=690
  col.add_child(text)
 var nav=HBoxContainer.new()
 nav.alignment=BoxContainer.ALIGNMENT_CENTER
 col.add_child(nav)
 if page>0: nav.add_child(g.button("← Back",func(): welcome(g,page-1),Vector2(130,44)))
 nav.add_child(g.button("Let’s grow something" if page==4 else "Continue →",func():
  if page==4: finish(g)
  else: welcome(g,page+1),Vector2(250,44)))
 nav.add_child(g.button("Explore now",func(): finish(g),Vector2(150,44)))
 for control in nav.get_children(): control.focus_mode=Control.FOCUS_ALL
 nav.get_child(0).grab_focus()
 if not g.settings.reduced_motion:
  col.modulate.a=0
  g.create_tween().tween_property(col,"modulate:a",1.0,.45)

static func finish(g) -> void:
 if is_instance_valid(g.welcome): g.welcome.queue_free()
 g.welcome=null
 if is_instance_valid(g.welcome_backdrop): g.welcome_backdrop.queue_free()
 g.welcome_backdrop=null
 g.settings.intro_seen=true
 g.save_game()
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

static func settings_page(g) -> void:
 g.side_title.text="Make yourself at home"
 g.add_note("COMFORT & QUIET",15)
 for entry in [["request_notifications","Neighbour request pop-ups"],["reduced_motion","Reduced motion"],["invert_y","Invert vertical look"],["pause_menus","Pause time in menus"]]:
  var key=entry[0]
  var toggle=CheckButton.new()
  toggle.text=entry[1]
  toggle.button_pressed=g.settings[key]
  toggle.toggled.connect(func(value): g.settings[key]=value; g.apply_settings(); g.save_game())
  g.list_box.add_child(toggle)
 for entry in [["volume","Master volume",0,100,1],["music_volume","Music volume",0,100,1],["nature_volume","Nature volume",0,100,1],["sensitivity","Mouse sensitivity",0.3,2.0,.1],["fov","Field of view",55,90,1]]:
  var key=entry[0]
  g.add_note(entry[1])
  var slider=HSlider.new()
  slider.min_value=entry[2]; slider.max_value=entry[3]; slider.step=entry[4]
  slider.value=g.settings[key]
  slider.custom_minimum_size=Vector2(240,24)
  slider.value_changed.connect(func(value): g.settings[key]=value; g.apply_settings())
  slider.drag_ended.connect(func(_changed): g.save_game())
  g.list_box.add_child(slider)
 g.list_box.add_child(g.button("Replay the welcome walk",func(): welcome(g)))
 g.list_box.add_child(g.button("Save garden",func(): g.save_game(); g.toast("Your garden is saved.")))
 g.list_box.add_child(g.button("Start a new garden…",func(): confirm_restart(g)))
 g.detail_label.text="Settings are saved with your garden.\nReduced motion skips the time-lapse and menu fades."

static func journey(g) -> void:
 g.add_note("YOUR GARDEN’S NEXT CHAPTERS",15)
 for entry in [[3,"Better hand tools"],[7,"Willow water + bed care systems"],[18,"Fern hollow + master tools"],[36,"Sunrise terrace"]]:
  g.add_note(("✓ " if g.day>=entry[0] else "Day %d · " % entry[0])+entry[1])
 g.add_note("After day 36, another bed opens every 12 days, with no final bed. A new seed every third day. Deliver 3, 8 and 15 requests for three extra seed discoveries each.")

static func confirm_restart(g) -> void:
 if is_instance_valid(g.welcome): return
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.welcome_backdrop=ColorRect.new()
 g.welcome_backdrop.color=Color(.07,.12,.09,.65)
 g.welcome_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 g.welcome_backdrop.z_index=29
 g.ui.add_child(g.welcome_backdrop)
 g.welcome=g.panel_at(Vector2(415,275),Vector2(610,320))
 g.welcome.z_index=30
 var col=VBoxContainer.new()
 col.add_theme_constant_override("separation",18)
 g.welcome.add_child(col)
 col.add_child(g.label("A fresh beginning?",30))
 var note=g.label("Return to day one with the starter garden. Plants, petals, unlocks and settings will reset. Your current garden will be backed up before starting again.",18)
 note.custom_minimum_size.x=560
 note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 col.add_child(note)
 col.add_child(g.button("Keep this garden",func(): g.welcome.queue_free(); g.welcome=null; g.welcome_backdrop.queue_free(); g.welcome_backdrop=null))
 col.add_child(g.button("Back up & start again",g.restart_garden))
