class_name GardenUpdates
extends RefCounted

# Add one entry per meaningful player-visible change; its number is the version.
# Keep technical work in CHANGELOG.md. Never renumber previously shipped entries.
const RELEASES=[
 {"version":52,"date":"6 October 2026","title":"One connected garden landscape","note":"The original garden and all ten new gardens now share one continuous piece of land. Walk across the gently sloping lawn beside the bluestone path, with grass and ground colours blending between the gardens. Each garden keeps its milestone for planting and arranging."},
 {"version":51,"date":"6 October 2026","title":"Later planting rewards","note":"The new gardens now reward longer-term planting: Pollinator Meadow opens after 250 new plantings, the Kitchen Garden after 500, Orchard Clearing after 1,000 and the Old Glasshouse after 2,000. See your totals in Garden atlas and Guide. Existing saves use the higher targets while keeping their plants and arrangements."},
 {"version":50,"date":"6 October 2026","title":"Garden milestone rewards & movable displays","note":"Explore all ten gardens from the start and earn free, permanent access to planting and arranging them through game days, new plantings and neighbour requests. See each milestone and your progress in Garden atlas and Guide. Starter benches face their gardens, kitchen pocket planters face into the courtyard, and glasshouse shelves, pots and other loose displays can be moved or packed away. Existing gardens keep their planting while the new milestones apply."},
 {"version":49,"date":"6 October 2026","title":"Smoother woodland and moonlit entrances","note":"Fern Gully's slate path now sweeps smoothly around the stream into its bank path. The Moon Garden entrance follows the curved gravel courtyard, with neatly fitted stones that stay clear of the ground beneath them."},
 {"version":48,"date":"6 October 2026","title":"Neater path junctions","note":"Stone paths now meet with one tidy paving pattern at their splits. Fitted thresholds join courtyards, steps and bridges, with narrower approaches at small crossings and level finishes at garden entrances."},
 {"version":47,"date":"6 October 2026","title":"Bluestone between the gardens","note":"Follow a blue-grey stone trail between all ten gardens, with smaller paths that meet their boardwalks, steps, doorways and inner paths. A new route links the eastern approach to the shared trail. The atlas explains where you can plant, rearrange starter plants and change specialist collections."},
 {"version":46,"date":"6 October 2026","title":"A garden that belongs together","note":"Follow a connected garden trail with fitted entrances and clearer signs. Enjoy consistent weathered stone, timber and clay, mixed low planting, scattered leaves and softer ground transitions. Gentler daylight, cooler woodland shade and balanced evening colours bring all ten gardens together."},
 {"version":45,"date":"6 October 2026","title":"A more natural garden trail","note":"Explore richer ferns and collection plants, winding water with textured banks, fitted curved paths and weathered logs. Terrace pots sit clear of walls, glasshouse plants grow inside their pots beneath woven shade, and bridges have complete railings. Change the orchard and kitchen bed surfaces in the shop, and plant clear of rocks throughout your garden."},
 {"version":44,"date":"5 October 2026","title":"Firm ground on every trail","note":"Walk safely through all ten new gardens, with solid ground beneath their arrival points, paths and planting areas."},
 {"version":43,"date":"5 October 2026","title":"Gardens with their own rhythm","note":"Discover eighteen collection plants in water, fern, glasshouse, alpine and twilight gardens. Adjust water and shade, restore glasshouse bays, train and graft fruit trees, prepare harvest baskets, guide stream water and keep a pollinator journal. Each trail has its own activities and growing benefits."},
 {"version":42,"date":"5 October 2026","title":"Ten new garden trails","note":"Follow the eastern path or open Garden atlas to explore ten detailed new landscapes, from Reedwater and Fern Gully to a walled kitchen garden, Alpine Lookout and Moon Garden. Visit each freely, tend its starter planting, and find a bench to stay awhile. Your established garden keeps its plants and progress."},
 {"version":41,"date":"5 October 2026","title":"Plant beyond the garden bed","note":"Plant real flowers, herbs and little succulents in pots, raised beds, bowls, troughs, hanging baskets and vertical or tiered planters. Tend each pocket, carry the whole display with Move, and keep its plants safely in stored plants when you pack the container away."},
 {"version":40,"date":"5 October 2026","title":"A working garden shed","note":"Make compost, worm castings, mulch and starter mix from spare harvest. Collect rain for your planters, open shade cloth or a cold-frame lid, and welcome birds at a feeding table. Hives and insect hotels also give nearby plants a little help. Face equipment and press E, or open Working garden in the shop."},
 {"version":39,"date":"5 October 2026","title":"Choose your petal pace","note":"Choose Easy, Medium or Hard petal earnings in Settings. Easy keeps the familiar rate, while Medium and Hard make your next purchase take more planning. Change whenever you like; your existing petals, shop prices, refunds and plant growth stay the same."},
 {"version":38,"date":"5 October 2026","title":"Fruit that grows on its branches","note":"Young and ripening fruit now stays attached to the tree. Fruit trees have more varied fruit sizes, colours and hanging angles, with gentler spacing instead of repeated rows of identical fruit."},
 {"version":37,"date":"4 October 2026","title":"A lighter first visit","note":"The garden has a smaller first download, with shared artwork and lighter background files. Your detailed plants, animals and structures keep their familiar appearance, with the same garden sounds and saves."},
 {"version":36,"date":"4 October 2026","title":"Room for a fuller garden","note":"Fuller gardens are quicker to explore and tend, with Auto graphics keeping finer detail closest to you. Your plants keep their individual shapes, growing stages and familiar care tools. Choose Standard graphics for full plant shadows, or set your preferred 3D resolution in Settings."},
 {"version":35,"date":"4 October 2026","title":"Climbers that follow their supports","note":"Sweet peas and Clematis now climb nearby posts with leafy stems and small, naturally shaped flowers. The oversized rows of pink ovals are gone, and climbing growth follows structures when you rearrange them."},
 {"version":34,"date":"4 October 2026","title":"Detailed companions and quiet visitors","note":"Your cat and dog have richer coats, more detailed faces and gentler movement, with familiar petting, resting and stretching routines. Look for a russet fox, a spiny echidna and little rabbits whose hops carry them through the garden."},
 {"version":33,"date":"4 October 2026","title":"Take your garden with you","note":"Download a garden save from Settings to keep a copy or move it to another device. Upload a saved copy, preview its day and plant count, and choose whether to open it. Your previous garden is backed up and can be downloaded from Settings."},
 {"version":32,"date":"3 October 2026","title":"Make every bed your own","note":"Choose sand, pale Japanese gravel, bark mulch, slate, warm pebbles or dark compost in the garden shed. Buy each finish once, use it on any open bed, and switch back to garden soil freely. Your plants and shaped ground stay in place."},
 {"version":31,"date":"3 October 2026","title":"Little grasses, softer edges","note":"Twelve new low-growing plants bring creeping lawn grasses, compact fescues, dwarf mondo grass, striped sedges and golden sweet flag. Find them in Grasses, with their own young leaves and mature shapes."},
 {"version":30,"date":"3 October 2026","title":"A little space between visitors","note":"Visiting bird pairs now take separate approaches, arrive a moment apart and beat their wings at different times, with room to rest beside one another."},
 {"version":29,"date":"3 October 2026","title":"A garden view to welcome you","note":"The start and welcome screens now open onto a richly planted garden, keeping the familiar timber borders and simple controls."},
 {"version":28,"date":"3 October 2026","title":"Familiar friends, a richer garden","note":"The original cat, dog, bee, frog and rabbit return with their familiar movement. The other animals, structures and held tools keep their new shapes and finer details."},
 {"version":27,"date":"3 October 2026","title":"Softer coats and smoother movement","note":"Mammals and birds now bend smoothly through their bodies and necks, with distinct coats, finer plumage and a heavier wombat walk. Timber, stone, buildings and held tools have richer surface detail while keeping their familiar shapes."},
 {"version":26,"date":"3 October 2026","title":"Finer details up close","note":"Look closer at your cat's coat, the kookaburra's plumage and the grain of the garden bench. These first detail improvements bring softer hair, more distinct feather surfaces and naturally weathered timber."},
 {"version":25,"date":"3 October 2026","title":"Visitors with their own habits","note":"Watch for slow wombats, cautious echidnas and a rare fox beyond the garden. Four new birds arrive to perch or forage, while blue-banded bees, hoverflies, mantises, leaf insects and evening moths bring their own little routines."},
 {"version":24,"date":"3 October 2026","title":"A more lifelike garden","note":"Your companions and garden wildlife have new shapes, detailed coats, feathers, wings and eyes. Legs bend as animals step, birds fold their wings to rest, and fish sway their tails as they swim."},
 {"version":23,"date":"3 October 2026","title":"More places to make your own","note":"Discover ten new structures, from a potting bench and rain barrel to a gazebo, swing and tiered fountain. Familiar structures, the garden shed and bridges now have richer wood, stone, glass and finer details."},
 {"version":22,"date":"3 October 2026","title":"A smoother return to the garden","note":"Browser downloads now keep each update's game files together and automatically retry an incomplete piece, helping the garden open reliably after an update."},
 {"version":21,"date":"3 October 2026","title":"Enjoy an uninterrupted view","note":"Choose Enjoy the view, or press H, to tuck away the HUD, aiming guides and held tool. The garden keeps going around you. Press any key, or click or tap, to bring your usual view back."},
 {"version":20,"date":"3 October 2026","title":"Bamboo belongs with the grasses","note":"Find all six bamboo varieties alongside the ornamental grasses. Their size and place in your garden stay the same."},
 {"version":19,"date":"3 October 2026","title":"A comfortable watering-can handle","note":"The watering can has a smooth rounded rear handle with a dark grip, joined neatly to its body and easier to see while you hold it."},
 {"version":18,"date":"3 October 2026","title":"Water with a sweep","note":"Hold left click and sweep across the soil to water an area. Release to stop; the watering can keeps its usual reach and ground-growth bonus."},
 {"version":17,"date":"3 October 2026","title":"Flowers facing the garden","note":"Sweet pea flowers now have softly folded petals, and Clematis opens its pointed blooms around fine cream centres. Both climbers are clearer to enjoy up close."},
 {"version":16,"date":"3 October 2026","title":"Grasses, cacti and little rosettes","note":"Discover ten more ornamental grasses and twenty cacti and succulents in their own seed category. Look for striped blades, pink seed clouds, spiny barrels, branching pads, fleshy rosettes and tiny living stones. Search by their garden or botanical names."},
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
