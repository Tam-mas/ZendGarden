class_name GardenExperience
extends RefCounted

static func welcome(g, _page: int = 0) -> void:
 if is_instance_valid(g.welcome):g.welcome.queue_free()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.side_panel.hide()
 if not is_instance_valid(g.welcome_backdrop):
  g.welcome_backdrop=ColorRect.new()
  g.welcome_backdrop.color=Color(.07,.12,.09,.45)
  g.welcome_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  g.welcome_backdrop.z_index=29
  g.ui.add_child(g.welcome_backdrop)
  var backdrop=TextureRect.new()
  backdrop.texture=load("res://assets/ui/start-garden.webp")
  backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  backdrop.modulate=Color(.75,.75,.75,1)
  backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  g.welcome_backdrop.add_child(backdrop)
 var width=minf(400,g.get_viewport().get_visible_rect().size.x-32)
 g.welcome=g.panel_at(Vector2.ZERO,Vector2(width,0))
 g.welcome.z_index=30
 var col=VBoxContainer.new()
 col.add_theme_constant_override("separation",12)
 g.welcome.add_child(col)
 var title=g.label("A little garden, a first bloom",24)
 title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 title.custom_minimum_size.x=width-28
 col.add_child(title)
 var note=g.label("Learn by planting a flower, giving it a drink, welcoming the morning and sharing a bloom. Take your time, or skip straight into your garden.",18)
 note.custom_minimum_size.x=width-28
 note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 col.add_child(note)
 col.add_child(g.button("Start the welcome walk",func(): GardenTutorial.start(g),Vector2(0,48)))
 col.add_child(g.button("Explore on my own",func(): finish(g),Vector2(0,44)))
 if g.touch_active():g.touch.fit_popup(g.welcome)
 else:GardenInterface.fit_popup(g,g.welcome)

static func finish(g) -> void:
 if g.tutorial_state.get("active",false):GardenTutorial.finish(g,false)
 if is_instance_valid(g.welcome): g.welcome.queue_free()
 g.welcome=null
 if is_instance_valid(g.welcome_backdrop): g.welcome_backdrop.queue_free()
 g.welcome_backdrop=null
 g.settings.intro_seen=true
 g.save_game()
 if not GardenUpdates.maybe_show(g): g.resume_controls()

static func settings_page(g) -> void:
 g.side_title.text="Make yourself at home"
 g.add_note("ZEND GARDEN · UPDATE %d" % GardenUpdates.CURRENT_VERSION,13)
 g.list_box.add_child(g.button("What’s new",func(): GardenUpdates.show(g)))
 GardenEconomy.settings_page(g)
 g.add_note("GARDEN SAVE FILES",15)
 g.list_box.add_child(g.button("Download save file",func(): g.save_files.download()))
 g.list_box.add_child(g.button("Upload save file…",func(): g.save_files.upload()))
 if FileAccess.file_exists(g.save_files.backup_path()):
  g.list_box.add_child(g.button("Download previous garden",func(): g.save_files.download(true)))
 g.add_note("Keep a copy or move your garden to another device. Upload asks before replacing your garden.",14)
 if is_instance_valid(g.touch): g.touch.settings_page()
 g.add_note("LOOK CONTROLS" if g.touch_active() else "MOUSE LOOK",15)
 for entry in [["invert_x","Invert mouse left / right"],["invert_y","Invert mouse up / down"],["request_notifications","Neighbour request pop-ups"],["reduced_motion","Reduced motion"],["pause_menus","Pause time in menus"]]:
  if entry[0]=="request_notifications": g.add_note("COMFORT & QUIET",15)
  var key=entry[0]
  var toggle=CheckButton.new()
  toggle.text=entry[1].replace("mouse","look") if g.touch_active() else entry[1]
  if g.touch_active():
   toggle.custom_minimum_size.y=48
   toggle.clip_text=true
   toggle.tooltip_text=toggle.text
  toggle.button_pressed=g.settings[key]
  toggle.toggled.connect(func(value): g.settings[key]=value; g.apply_settings(); g.save_game())
  g.list_box.add_child(toggle)
 for entry in [["volume","Master volume",0,100,1],["music_volume","Music volume",0,100,1],["nature_volume","Nature volume",0,100,1],["sensitivity","Mouse sensitivity",0.3,2.0,.1],["fov","Field of view",55,90,1]]:
  var key=entry[0]
  g.add_note(entry[1].replace("Mouse sensitivity","Look sensitivity") if g.touch_active() else entry[1])
  var slider=HSlider.new()
  slider.min_value=entry[2]; slider.max_value=entry[3]; slider.step=entry[4]
  slider.value=g.settings[key]
  slider.custom_minimum_size=Vector2(240,48 if g.touch_active() else 24)
  slider.value_changed.connect(func(value): g.settings[key]=value; g.apply_settings())
  slider.drag_ended.connect(func(_changed): g.save_game())
  g.list_box.add_child(slider)
 g.list_box.add_child(g.button("Replay the welcome walk",func(): g.show_welcome()))
 g.list_box.add_child(g.button("Save garden",func(): g.toast("Your garden is saved." if g.save_game() else "Could not save your garden. Please try again.")))
 g.list_box.add_child(g.button("Start a new garden…",func(): confirm_restart(g)))
 g.detail_label.text="Settings are saved with your garden.\nReduced motion skips the time-lapse and menu fades."

static func journey(g) -> void:
 g.add_note("YOUR GARDEN’S NEXT CHAPTERS",15)
 for entry in [[3,"Better hand tools"],[7,"Willow water + bed care systems"],[18,"Fern hollow + master tools"],[36,"Sunrise terrace"]]:
  g.add_note(("Owned " if g.day>=entry[0] else "Day %d · " % entry[0])+entry[1])
 g.add_note("TEN GARDEN REWARDS",15)
 g.add_note("Visit every area from the start. Each milestone permanently opens planting, care and furniture changes, with no petal cost. Open Garden atlas to see live progress and visit a trail.")
 for index in range(10):
  g.add_note(GardenAreaCatalogue.entry(index).name+" · "+("Unlocked" if GardenAreaProgression.unlocked(g,index) else GardenAreaProgression.requirement(index)+" · "+GardenAreaProgression.progress(g,index)))
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
