class_name GardenUpdates
extends RefCounted

# Add one entry per meaningful player-visible change; its number is the version.
# Keep technical work in CHANGELOG.md. Never renumber previously shipped entries.
const RELEASES=[
 {"version":15,"date":"3 October 2026","title":"Your watered garden welcomes you back","note":"Gardens with freshly watered ground can open again after a refresh or a move to zend.garden, keeping your saved progress."},
 {"version":14,"date":"3 October 2026","title":"Stay a while, together","note":"Sit on a bench, rest beneath a pergola or watch the pond. Call your cat and dog over, pet them, and invite them to settle beside you. Look out for a sunny cat stretch and a curious dog sniff."},
 {"version":13,"date":"3 October 2026","title":"Grow your first bloom together","note":"A short welcome walk now teaches planting, watering, a new morning, gathering and sharing a flower in your own garden. Skip whenever you like, resume after a break, or replay it from Settings."},
 {"version":12,"date":"3 October 2026","title":"Familiar frames, more garden","note":"The warm brown menus and decorative borders are back, with a slimmer sidebar that leaves more of your garden in view. Search, filters and favourites stay close, and shortcut instructions float as plain text."},
 {"version":11,"date":"3 October 2026","title":"Pack away garden structures","note":"Aim the Remove tool at a structure to turn it warm red and see what you will pack away. Removing it returns its full petal cost, and touch controls offer Undo."},
 {"version":10,"date":"3 October 2026","title":"A clearer view of your garden","note":"Larger, clearer text and quieter menu backgrounds make gardening easier to read. Plant portraits have lighter backdrops, desktop menus fit your window, and short screens can tuck away category buttons."},
 {"version":9,"date":"3 October 2026","title":"Know what your plants need","note":"Point at a plant to see its growth, watering and growing conditions. A gentle outline shows your target, and you can switch between plants sharing a spot."},
 {"version":8,"date":"3 October 2026","title":"Find your next favourite plant","note":"Search your seeds, filter by season, light, height, colour or visiting wildlife, and keep favourites and recently planted choices close. Shop previews help you choose garden decorations."},
 {"version":7,"date":"3 October 2026","title":"Watch your garden take shape","note":"Plants now grow through seedlings, young leaves and buds before flowering or ripening. Small differences in their shape make each planting feel a little more natural."},
 {"version":6,"date":"1 October 2026","title":"A new cozy home","note":"Zend Garden is moving to zend.garden. Visiting the old address can gently carry your garden across, keeping its original copy safe."},
 {"version":5,"date":"1 October 2026","title":"A little window into the garden’s growth","note":"You can now read what’s new, close it whenever you like, and find it again in Settings."},
 {"version":4,"date":"1 October 2026","title":"A clearer greenhouse roof","note":"The roof glass now follows the frame, making a tidier shelter for your plants."},
 {"version":3,"date":"1 October 2026","title":"Quiet whenever you choose","note":"Moving Music volume all the way down now silences the music completely. Nature sounds keep their own setting."},
 {"version":2,"date":"1 October 2026","title":"More room for calm","note":"Each garden area has a gentler tune of its own, with softer nature sounds and smoother changes as you wander."},
 {"version":1,"date":"28 September 2026","title":"A growing garden","note":"More plants to discover, clearer planting previews, easier gathering, and steadier touch controls for phones and tablets."}
]
const CURRENT_VERSION=RELEASES[0].version

static func unseen(settings: Dictionary) -> Array:
 return RELEASES.filter(func(entry): return entry.version>int(settings.get("updates_seen",0)))

static func maybe_show(g) -> bool:
 if g.smoke or not g.settings.intro_seen or is_instance_valid(g.welcome) or unseen(g.settings).is_empty(): return false
 # A new visitor has no older garden to update; history remains in Settings.
 if g.loaded_data.is_empty():
  g.settings.updates_seen=CURRENT_VERSION
  g.save_game()
  return false
 show(g,true)
 return true

static func quiet_frame(color: Color, margin: int=0) -> StyleBoxFlat:
 var style=StyleBoxFlat.new()
 style.bg_color=color
 style.set_corner_radius_all(12)
 style.set_content_margin_all(margin)
 return style

static func layout(g) -> void:
 if not g.updates_open or not is_instance_valid(g.welcome): return
 var viewport=g.get_viewport().get_visible_rect().size
 var size=Vector2(minf(520,viewport.x-32),minf(500,viewport.y-32))
 g.welcome.scale=Vector2.ONE
 g.welcome.size=size
 g.welcome.position=(viewport-g.welcome.size)*.5

static func show(g, only_unseen: bool=false) -> void:
 if is_instance_valid(g.welcome): return
 g.updates_open=true
 g.updates_return_to_game=not g.side_panel.visible
 if is_instance_valid(g.touch): g.touch.reset_gestures()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.welcome_backdrop=ColorRect.new()
 g.welcome_backdrop.color=Color(.04,.08,.06,.28)
 g.welcome_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 g.welcome_backdrop.z_index=29
 g.ui.add_child(g.welcome_backdrop)
 var viewport=g.get_viewport().get_visible_rect().size
 var size=Vector2(minf(520,viewport.x-32),minf(500,viewport.y-32))
 g.welcome=g.panel_at((viewport-size)*.5,size)
 g.welcome.z_index=30
 g.welcome.add_theme_stylebox_override("panel",GardenTheme.frame("wood",Color.WHITE,20))
 var column=VBoxContainer.new()
 column.name="UpdateContent"
 column.add_theme_constant_override("separation",12)
 g.welcome.add_child(column)
 var heading=HBoxContainer.new()
 column.add_child(heading)
 var title=g.label("What’s new",25)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 heading.add_child(title)
 var close=g.button("×",func(): dismiss(g),Vector2(44,44))
 close.focus_mode=Control.FOCUS_ALL
 close.tooltip_text="Close what’s new"
 heading.add_child(close)
 column.add_child(g.label("Zend Garden · Update %d" % CURRENT_VERSION,14,GardenTheme.MUTED))
 var scroll=ScrollContainer.new()
 scroll.name="UpdateHistory"
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.custom_minimum_size.y=48
 scroll.get_v_scroll_bar().custom_minimum_size.x=6
 scroll.get_v_scroll_bar().add_theme_stylebox_override("scroll",quiet_frame(Color("2d2119")))
 for state in ["grabber","grabber_highlight","grabber_pressed"]:
  scroll.get_v_scroll_bar().add_theme_stylebox_override(state,quiet_frame(Color("a17d49")))
 column.add_child(scroll)
 var entries=VBoxContainer.new()
 entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 entries.add_theme_constant_override("separation",18)
 scroll.add_child(entries)
 for entry in unseen(g.settings) if only_unseen else RELEASES:
  var group=VBoxContainer.new()
  group.add_theme_constant_override("separation",6)
  entries.add_child(group)
  var date=g.label("Update %d · %s" % [entry.version,entry.date],12,GardenTheme.MUTED)
  date.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  group.add_child(date)
  for pair in [[entry.title,18],[entry.note,16]]:
   var text=g.label(pair[0],pair[1])
   text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   group.add_child(text)
 var done=g.button("Back to the garden" if g.updates_return_to_game else "Done",func(): dismiss(g),Vector2(0,44))
 done.name="DismissUpdates"
 done.focus_mode=Control.FOCUS_ALL
 column.add_child(done)
 layout(g)
 done.grab_focus()

static func dismiss(g) -> void:
 if not g.updates_open: return
 g.settings.updates_seen=maxi(CURRENT_VERSION,int(g.settings.get("updates_seen",0)))
 g.save_game()
 if is_instance_valid(g.welcome): g.welcome.queue_free()
 if is_instance_valid(g.welcome_backdrop): g.welcome_backdrop.queue_free()
 g.welcome=null
 g.welcome_backdrop=null
 g.updates_open=false
 if g.updates_return_to_game: g.resume_controls()
