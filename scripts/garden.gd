extends Node3D

const Art = preload("res://scripts/garden_art.gd")
const Catalogue = preload("res://scripts/catalogue.gd")
const Soundscape = preload("res://scripts/soundscape.gd")
var SAVE_PATH = "user://garden_v1.json"
const GRID = 0.4
const CAPACITY_MULTIPLIER = 4
const TREE_SPACING = 1.15
const DAY_SECONDS = 600.0
const STARTERS = [0,1,2,12,14,20,28,36,37,44,46,48,50]
var catalogue = Catalogue.plants()
var furniture = Catalogue.furnishings()
var plots: Array = [
 {"name":"The beginning", "subtitle":"A sunlit patch to call your own", "center":Vector3(0,0,0), "condition":"sun", "cap":55, "cost":0},
 {"name":"Willow water", "subtitle":"Across the bridge, beside still water", "center":Vector3(17,0,0), "condition":"water", "cap":65, "cost":160},
 {"name":"Fern hollow", "subtitle":"A sheltered bend beneath the trees", "center":Vector3(17,0,-17), "condition":"shade", "cap":70, "cost":260},
 {"name":"Sunrise terrace", "subtitle":"The hillside opens to the morning", "center":Vector3(0,0,-17), "condition":"sun", "cap":85, "cost":380}
]
var planted: Array = []
var objects: Array = []
var unlocked_plants: Array = STARTERS.duplicate()
var unlocked_plots = 1
var coins = 80
var day = 1
var clock_time = 0.39
var inventory: Dictionary = {}
var upgrades = {"can":0,"shears":0,"trowel":0,"rake":0}
var automation: Dictionary = {}
var expansions: Dictionary = {}
var orders: Array = []
var fulfilled = 0
var planted_total = 0
var clean_paths: Array = []
var path_widths: Dictionary = {}
var companion_names = ["Miso", "Clover"]
var selected = 0
var selected_furniture = 0
var category = "Flowers"
var active_tab = "Seeds"
var mode = "walk"
var selected_layer = 1
var moved_index = -1
var moved_object = -1
var current_plot = 0
var hover_cell = Vector3.ZERO
var hover_plot = -1
var hover_valid = false
var action_cooldown = 0.0
var save_timer = 0.0
var preview: Node3D
var preview_id = ""
var player: CharacterBody3D
var camera: Camera3D
var camera_target = Vector3.ZERO
var yaw = 0.0
var pitch = 0.12
var distance = 7.5
var sun: DirectionalLight3D
var environment: WorldEnvironment
var world_root: Node3D
var plant_root: Node3D
var object_root: Node3D
var wildlife: Array = []
var pets: Array = []
var water_motes: Array = []
var plot_signs: Array = []
var grid_root: Node3D
var grid_cursor: Node3D
var ambient: Node
var ui: CanvasLayer
var top_label: Label
var capacity_label: Label
var capacity_bar: ProgressBar
var status_label: Label
var toast_label: Label
var tip_label: Label
var list_box: VBoxContainer
var side_panel: PanelContainer
var side_title: Label
var detail_label: Label
var mode_buttons: Dictionary = {}
var toast_time = 0.0
var photo_mode = false
var photo_panel: PanelContainer
var welcome_backdrop: ColorRect
var welcome: PanelContainer
var ui_refresh = 0.0
var rng = RandomNumberGenerator.new()
var smoke = false
var reticle: Label
var view_fov = 74.0
var hud_top: PanelContainer
var hud_tools: PanelContainer
var hud_foot: PanelContainer
var hud_capacity: PanelContainer
var compact_hud: Label
var preview_error = ""
var held_tool: Node3D
var tool_models: Dictionary = {}
var menu_theme: Theme
var hud_title: PanelContainer
var rotation_panel: PanelContainer
var structure_rotation=0.0
var day_transition=false
var transition_elapsed=0.0
var transition_start=0.0
var transition_crossed_midnight=false
var transition_label: Label
const TRANSITION_SECONDS=6.0
var tool_tween: Tween
var sign_text="My garden"
var sign_color=Color("f1e5c7")
var editing_sign=-1

var settings={"intro_seen":false,"request_notifications":true,"reduced_motion":false,"invert_x":false,"invert_y":false,"pause_menus":true,"volume":75.0,"music_volume":70.0,"nature_volume":100.0,"sensitivity":1.0,"fov":74.0}
var request_popup: PanelContainer
var request_unread=false
var orders_button: Button
var request_popup_time=0.0
var request_return_to_game=false
var rake_petals=0
var climate: GardenClimate

func _ready() -> void:
 rng.seed = 7183
 smoke = "--smoke-test" in OS.get_cmdline_user_args() or "--walk-test" in OS.get_cmdline_user_args() or "--experience-test" in OS.get_cmdline_user_args() or "--ground-test" in OS.get_cmdline_user_args()
 if smoke: SAVE_PATH="user://smoke-test-save.json"
 load_game()
 GardenExpansion.prepare(self)
 make_world()
 make_player()
 make_camera()
 climate=GardenClimate.new()
 add_child(climate)
 climate.restore(loaded_data.get("climate",{}))
 make_ui()
 restore_garden()
 ambient = Soundscape.new()
 add_child(ambient)
 make_orders()
 apply_settings()
 refresh_ui()
 if planted.is_empty() and loaded_data.is_empty(): starter_garden()
 if not settings.intro_seen and not smoke: show_welcome()
 if "--ground-test" in OS.get_cmdline_user_args(): call_deferred("run_ground_test")
 elif "--experience-test" in OS.get_cmdline_user_args(): call_deferred("run_experience_test")
 elif "--walk-test" in OS.get_cmdline_user_args(): call_deferred("run_walk_test")
 elif smoke: call_deferred("run_smoke_test")
 elif not is_instance_valid(welcome): Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func make_world() -> void:
 world_root = Node3D.new()
 add_child(world_root)
 plant_root = Node3D.new()
 add_child(plant_root)
 object_root = Node3D.new()
 add_child(object_root)
 environment = WorldEnvironment.new()
 var env = Environment.new()
 env.background_mode = Environment.BG_SKY
 var sky = Sky.new()
 var sky_material = ShaderMaterial.new()
 sky_material.shader=load("res://shaders/country_sky.gdshader")
 sky.sky_material=sky_material
 env.sky=sky
 env.background_color = Color("b8d1ce")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("e4e7cc")
 env.ambient_light_energy = 0.4
 env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
 env.fog_enabled = true
 env.fog_light_color = Color("c4d7d2")
 env.fog_density = 0.00012
 env.fog_sky_affect = 0.08
 env.ssao_enabled = true
 env.ssao_radius = 1.0
 env.ssao_intensity = 1.1
 environment.environment = env
 add_child(environment)
 sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-48,-28,0)
 sun.light_color = Color("ffe5bd")
 sun.light_energy = 1.15
 sun.shadow_enabled = true
 sun.light_angular_distance = 0.7
 sun.directional_shadow_max_distance = 90
 add_child(sun)
 GardenLandscape.build(self)
 for row in range(2,int(plots.size()/2)): GardenExpansion.build_row(self,row)
 for j in range(35):
  var mote = Art.ball(world_root,Vector3(rng.randf_range(-8,25),rng.randf_range(0.5,4),rng.randf_range(-23,8)),Vector3.ONE*0.045,Color("f9e6ac"))
  water_motes.append(mote)
 for j in range(2):
  var pet = Art.companion(j==0)
  pet.position = GardenTerrain.point(Vector3(-5+j*2,0,6))
  add_child(pet)
  pets.append(pet)
 grid_root = Node3D.new()
 add_child(grid_root)
 # Small individual cell edges follow the slopes instead of long floating grid bars.
 for x in range(-12,12):
  for z in range(-12,12):
   var tile=Node3D.new()
   tile.position=Vector3(x*GRID,0,z*GRID)
   grid_root.add_child(tile)
   Art.box(tile,Vector3(0,.07,0),Vector3(.04,.02,.04),Color("efdb9c"))
 grid_root.visible = false
 grid_cursor = Node3D.new()
 add_child(grid_cursor)
 for v in [-1,1]:
  Art.box(grid_cursor,Vector3(v*GRID/2,0.13,0),Vector3(0.045,0.025,GRID),Color("efdb9c"))
  Art.box(grid_cursor,Vector3(0,0.13,v*GRID/2),Vector3(GRID,0.025,0.045),Color("efdb9c"))
 grid_cursor.visible = false

func make_bridge(pos: Vector3, turn: bool) -> void:
 var n = Node3D.new()
 n.position = pos
 var body=StaticBody3D.new()
 var collision=CollisionShape3D.new()
 var deck=BoxShape3D.new()
 deck.size=Vector3(4.5,.15,1.8)
 collision.shape=deck
 collision.position.y=.08
 body.add_child(collision)
 n.add_child(body)
 if turn: n.rotation.y = PI/2
 world_root.add_child(n)
 for j in range(14): Art.box(n,Vector3(-2.1+j*0.32,0.08,0),Vector3(0.29,0.15,1.8),Color("b9a180"))
 for z in [-0.9,0.9]:
  for x in [-2.1,0,2.1]: Art.box(n,Vector3(x,0.55,z),Vector3(0.1,1.0,0.1),Color("9b876c"))
  Art.box(n,Vector3(0,0.96,z),Vector3(4.5,0.1,0.1),Color("cbb694"))

func make_player() -> void:
 player = CharacterBody3D.new()
 var body_shape = CollisionShape3D.new()
 var capsule = CapsuleShape3D.new()
 capsule.radius = 0.24
 capsule.height = 1.65
 body_shape.shape = capsule
 body_shape.position.y = 0.84
 player.add_child(body_shape)
 player.position = GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.1,0)
 player.floor_snap_length=.35
 add_child(player)
 Art.cylinder(player,Vector3(0,0.8,0),0.25,0.64,Color("809b9b"),0.20)
 Art.ball(player,Vector3(0,1.37,0),Vector3(0.39,0.43,0.39),Color("e4b993"))
 Art.cylinder(player,Vector3(0,1.58,0),0.43,0.045,Color("dfc58b"))
 Art.cylinder(player,Vector3(0,1.68,0),0.25,0.2,Color("e8cf97"),0.2)
 for x in [-0.13,0.13]:
  var leg=Node3D.new()
  leg.name="LegLeft" if x<0 else "LegRight"
  leg.position=Vector3(x,0.54,0)
  player.add_child(leg)
  Art.cylinder(leg,Vector3(0,-0.27,0),0.09,0.53,Color("617f79"))
  Art.ball(leg,Vector3(0,-0.47,-0.07),Vector3(0.20,0.14,0.32),Color("786f5e"))
 for x in [-0.3,0.3]: Art.branch(player,Vector3(x,1.03,0),Vector3(x,0.59,-0.05),0.065,Color("e4b993"))

func make_camera() -> void:
 camera = Camera3D.new()
 camera.projection = Camera3D.PROJECTION_PERSPECTIVE
 camera.fov = view_fov
 camera.near = 0.1
 camera.far = 10000
 add_child(camera)
 camera_target = player.position + Vector3(0,1.62,0)
 player.hide()
 held_tool=Node3D.new()
 held_tool.position=Vector3(.35,-.36,-.63)
 camera.add_child(held_tool)
 for kind in ["can","shears","trowel","rake"]:
  var path="res://assets/tools/"+kind+".glb"
  if ResourceLoader.exists(path):
   var model=load(path).instantiate()
   held_tool.add_child(model)
   tool_models[kind]=model
   model.hide()
 update_camera(1.0)

func panel_style(color: Color, _radius: int = 18) -> StyleBoxTexture:
 var light=color.r>.8 and color.g>.8
 return GardenTheme.frame("parchment" if light else "wood")

func label(text: String, size: int = 16, color: Color = Color("efdfbc")) -> Label:
 var l = Label.new()
 l.theme=menu_theme
 l.text = text
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color("cbb98e") if color in [Color("75816b"),Color("7b886f"),Color("82917c")] else color)
 return l

func button(text: String, action: Callable, min_size: Vector2 = Vector2(0,38)) -> Button:
 var b = Button.new()
 b.text = text
 b.focus_mode = Control.FOCUS_NONE
 b.custom_minimum_size = min_size
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 b.theme=menu_theme
 b.add_theme_font_size_override("font_size",14)
 b.pressed.connect(action)
 return b

func panel_at(pos: Vector2, size: Vector2) -> PanelContainer:
 var p = PanelContainer.new()
 p.position = pos
 p.size = size
 p.theme=menu_theme
 p.add_theme_stylebox_override("panel",GardenTheme.frame())
 ui.add_child(p)
 return p

func make_ui() -> void:
 ui = CanvasLayer.new()
 add_child(ui)
 menu_theme=GardenTheme.make()
 hud_title=panel_at(Vector2(24,20),Vector2(300,76))
 hud_title.add_theme_stylebox_override("panel",GardenTheme.frame("parchment"))
 var title_col=VBoxContainer.new()
 title_col.add_theme_constant_override("separation",0)
 hud_title.add_child(title_col)
 title_col.add_child(label("ZEND GARDEN",26,Color("49341e")))
 title_col.add_child(label("A LITTLE GROWTH, EVERY DAY",10,Color("60482c")))
 hud_top=panel_at(Vector2(346,32),Vector2.ZERO)
 var status_frame=GardenTheme.frame("parchment",Color.WHITE,8)
 status_frame.content_margin_left=12
 status_frame.content_margin_right=12
 hud_top.add_theme_stylebox_override("panel",status_frame)
 top_label=label("",16,Color("49341e"))
 hud_top.add_child(top_label)
 side_panel = panel_at(Vector2(24,112),Vector2(300,664))
 var col = VBoxContainer.new()
 col.add_theme_constant_override("separation",12)
 side_panel.add_child(col)
 var tabs = HBoxContainer.new()
 tabs.add_theme_constant_override("separation",4)
 col.add_child(tabs)
 for tab in ["Seeds","Shop","Orders","Guide"]:
  var tab_button=button(tab,func(): active_tab=tab; refresh_sidebar(),Vector2(0,32))
  tabs.add_child(tab_button)
  if tab=="Orders": orders_button=tab_button
 side_title = label("The seed collection",22)
 col.add_child(side_title)
 var scroll = ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(264,448)
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 col.add_child(scroll)
 list_box = VBoxContainer.new()
 list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 list_box.add_theme_constant_override("separation",7)
 scroll.add_child(list_box)
 detail_label = label("",13,Color("75816b"))
 detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 detail_label.custom_minimum_size.x = 256
 col.add_child(detail_label)
 col.add_child(button("Settings",func(): open_sidebar("Settings"),Vector2(0,30)))
 var capacity = panel_at(Vector2(1054,112),Vector2(362,144))
 hud_capacity=capacity
 var cap_col = VBoxContainer.new()
 cap_col.add_theme_constant_override("separation",8)
 capacity.add_child(cap_col)
 capacity_label = label("",17)
 capacity_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 capacity_label.custom_minimum_size.x=320
 cap_col.add_child(capacity_label)
 capacity_bar = ProgressBar.new()
 capacity_bar.custom_minimum_size.y = 8
 capacity_bar.show_percentage = false
 capacity_bar.add_theme_stylebox_override("background",GardenTheme.meter(Color("392b20")))
 capacity_bar.add_theme_stylebox_override("fill",GardenTheme.meter(Color("a8bd79")))
 cap_col.add_child(capacity_bar)
 status_label = label("",13,Color("7b886f"))
 status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status_label.custom_minimum_size.x=320
 cap_col.add_child(status_label)
 var toolbar = panel_at(Vector2(346,797),Vector2(1070,78))
 hud_tools=toolbar
 var tools_row = HBoxContainer.new()
 tools_row.add_theme_constant_override("separation",7)
 toolbar.add_child(tools_row)
 var tools_data = [["walk","1  Wander"],["plant","2  Plant"],["water","3  Water"],["prune","4  Prune"],["harvest","5  Gather"],["move","6  Move"],["remove","7  Lift"],["rake","8  Rake"]]
 for entry in tools_data:
  var key: String = entry[0]
  var b = button(entry[1],func(): set_mode(key),Vector2(0,42))
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tools_row.add_child(b)
  mode_buttons[key] = b
 var foot = panel_at(Vector2(24,797),Vector2(300,78))
 hud_foot=foot
 var fc = VBoxContainer.new()
 foot.add_child(fc)
 foot.add_theme_stylebox_override("panel",GardenTheme.frame("parchment"))
 fc.add_child(label("Take your time…",19,Color("49341e")))
 fc.add_child(label("Nothing here is ever too late.",12,Color("60482c")))
 tip_label = label("",15,Color("fff6dc"))
 tip_label.position = Vector2(356,753)
 tip_label.add_theme_color_override("font_shadow_color",Color("465947"))
 tip_label.add_theme_constant_override("shadow_offset_x",1)
 tip_label.add_theme_constant_override("shadow_offset_y",2)
 ui.add_child(tip_label)
 toast_label = label("",16,Color("49341e"))
 toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 toast_label.position = Vector2(430,125)
 toast_label.size.x = 560
 toast_label.add_theme_stylebox_override("normal",panel_style(Color(0.98,0.96,0.86,0.95),12))
 toast_label.visible = false
 ui.add_child(toast_label)
 photo_panel = panel_at(Vector2(390,810),Vector2(660,65))
 var pr = HBoxContainer.new()
 photo_panel.add_child(pr)
 pr.add_child(label("PHOTO  •  WASD fly · Q/E height · right-drag look",14))
 pr.add_child(button("Capture",capture_photo))
 pr.add_child(button("Done",toggle_photo))
 photo_panel.hide()
 rotation_panel=panel_at(Vector2(1070,276),Vector2(346,64))
 var rotate_row=HBoxContainer.new()
 rotation_panel.add_child(rotate_row)
 for direction in [-1,1]:
  var turn=direction
  var control=button("↶  Q" if turn<0 else "E  ↷",func(): rotate_structure(turn),Vector2(145,34))
  control.tooltip_text="Rotate anticlockwise" if turn<0 else "Rotate clockwise"
  rotate_row.add_child(control)
 rotation_panel.hide()
 transition_label=label("",30,Color("ffe8b3"))
 transition_label.position=Vector2(430,92)
 transition_label.size=Vector2(580,60)
 transition_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 transition_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 transition_label.add_theme_color_override("font_shadow_color",Color("211c2e"))
 transition_label.add_theme_constant_override("shadow_offset_y",2)
 ui.add_child(transition_label)
 transition_label.hide()
 side_panel.hide()
 reticle=label("·",28,Color("fff7d9"))
 reticle.position=Vector2(712,432)
 reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE
 reticle.add_theme_color_override("font_shadow_color",Color("203222"))
 reticle.add_theme_constant_override("shadow_offset_x",1)
 reticle.add_theme_constant_override("shadow_offset_y",1)
 ui.add_child(reticle)
 compact_hud=label("",15,Color("fff4d6"))
 compact_hud.position=Vector2(28,24)
 compact_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
 compact_hud.add_theme_color_override("font_shadow_color",Color("27372b"))
 compact_hud.add_theme_constant_override("shadow_offset_y",2)
 ui.add_child(compact_hud)

func open_sidebar(page: String) -> void:
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var was_open = side_panel.visible and active_tab==page
 active_tab=page
 side_panel.visible=not was_open
 refresh_sidebar()

func choose_furnishing(index: int) -> void:
 selected_furniture=index
 if furniture[index].kind=="sign":
  open_sign_editor()
 else:
  set_mode("build")
  toast(furniture[index].hint)

func open_sign_editor(index: int = -1) -> void:
 editing_sign=index
 if index>=0:
  sign_text=objects[index].get("text","My garden")
  sign_color=Color.from_string(objects[index].get("text_color","f1e5c7"),Color("f1e5c7"))
 active_tab="Sign"
 side_panel.show()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 refresh_sidebar()

func sign_editor_page() -> void:
 side_title.text="Your garden sign"
 add_note("SIGN TEXT · up to 64 characters",14)
 var field=LineEdit.new()
 field.name="SignText"
 field.max_length=64
 field.text=sign_text
 field.placeholder_text="A name, a welcome, a little reminder…"
 list_box.add_child(field)
 add_note("TEXT COLOUR",14)
 var picker=ColorPickerButton.new()
 picker.name="SignColour"
 picker.color=sign_color
 picker.edit_alpha=false
 picker.custom_minimum_size=Vector2(254,40)
 list_box.add_child(picker)
 var sample=label(sign_text,20,sign_color)
 sample.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 sample.custom_minimum_size=Vector2(254,80)
 list_box.add_child(sample)
 var apply=button("Save changes" if editing_sign>=0 else "Place sign · ◇ 15",finish_sign_editor)
 apply.disabled=Art.clean_sign_text(sign_text).is_empty()
 list_box.add_child(apply)
 field.text_changed.connect(func(value):
  sign_text=Art.clean_sign_text(value)
  sample.text=sign_text
  apply.disabled=sign_text.is_empty())
 picker.color_changed.connect(func(value):
  sign_color=value
  sample.add_theme_color_override("font_color",value))
 list_box.add_child(button("Back to the shed",func(): open_sidebar("Shop")))
 detail_label.text="Lettering appears on both sides.\nQ/E rotates a sign while placing or moving it.\nEdit placed signs from the Shop at any time."

func finish_sign_editor() -> void:
 sign_text=Art.clean_sign_text(sign_text)
 if sign_text.is_empty(): return
 if editing_sign>=0:
  if editing_sign>=objects.size() or objects[editing_sign].kind!="sign": return
  var obj=objects[editing_sign]
  obj.text=sign_text
  obj.text_color=sign_color.to_html(false)
  Art.set_sign_text(obj.node,sign_text,sign_color)
  save_game()
  open_sidebar("Shop")
  toast("Your sign has been updated.")
 else:
  for i in range(furniture.size()):
   if furniture[i].kind=="sign": selected_furniture=i
  set_mode("build")
  toast("Choose a spot for your sign. Q/E to rotate.")

func clear_list() -> void:
 for c in list_box.get_children():
  list_box.remove_child(c)
  c.queue_free()

func add_note(text: String, size: int = 13) -> void:
 var l = label(text,size,Color("7b886f"))
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.custom_minimum_size.x = 254
 list_box.add_child(l)

func refresh_sidebar() -> void:
 clear_list()
 match active_tab:
  "Seeds":
   side_title.text = "The seed collection"
   var cats = GridContainer.new()
   cats.columns = 3
   list_box.add_child(cats)
   for cat in Catalogue.CATEGORIES:
    var chosen: String = cat
    var cb = button(cat,func(): category=chosen; refresh_sidebar(),Vector2(81,30))
    cb.add_theme_font_size_override("font_size",12)
    if cat==category: cb.add_theme_stylebox_override("normal",GardenTheme.frame("button",Color("efd49b"),8))
    cats.add_child(cb)
   add_note("Seeds are endless once discovered. Plant in beds or on dry ground nearby; both share the area’s capacity.")
   var cards=GridContainer.new()
   cards.name="PlantCards"
   cards.columns=2
   cards.add_theme_constant_override("h_separation",8)
   cards.add_theme_constant_override("v_separation",8)
   list_box.add_child(cards)
   for p in catalogue:
    if p.category != category: continue
    var id: int = p.id
    var unlocked = id in unlocked_plants
    var b=button("",func(): choose_plant(id),Vector2(120,150))
    b.name="PlantCard%02d" % id
    b.tooltip_text="%s · %s layer · %d growing days\n%s · %s" % [p.name,["Ground","Flower","Shrub","Canopy"][p.layer],p.days,Catalogue.growing_seasons(id),"Discovered" if unlocked else "Unlock for %d petals" % p.price]
    b.add_theme_stylebox_override("normal",GardenTheme.frame("button",Color("efcd8c") if id==selected else Color.WHITE,4))
    var content=VBoxContainer.new()
    content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    content.offset_left=6
    content.offset_right=-6
    content.offset_top=6
    content.offset_bottom=-6
    content.add_theme_constant_override("separation",1)
    content.mouse_filter=Control.MOUSE_FILTER_IGNORE
    b.add_child(content)
    var portrait=TextureRect.new()
    portrait.texture=load("res://assets/ui/plants/%02d.png" % id)
    portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.custom_minimum_size=Vector2(108,96)
    portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
    portrait.modulate=Color.WHITE if unlocked else Color(.65,.61,.52)
    content.add_child(portrait)
    var name_label=label(p.name,14)
    name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    content.add_child(name_label)
    var cost=label("Capacity %d" % p.capacity if unlocked else "◇ %d to discover" % p.price,11,Color("cbb98e"))
    cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
    cost.mouse_filter=Control.MOUSE_FILTER_IGNORE
    content.add_child(cost)
    cards.add_child(b)
   var plant = catalogue[selected]
   detail_label.text = "%s\n%s layer · %d capacity · %d growing days\nLikes %s · welcomes %s%s" % [plant.name,["Ground","Flower","Shrub","Canopy"][plant.layer],plant.capacity,plant.days,plant.condition,plant.animal,"\nClimbs nearby arbors & pergolas." if plant.climber else ""]
   detail_label.text+="\nGrows: "+Catalogue.growing_seasons(plant.id)
  "Shop":
   side_title.text = "The garden shed"
   add_note("BED CARE  ·  available day 7",14)
   for kind in ["water","prune"]:
    var k: String = kind
    var owned = automation.has(str(current_plot)+k)
    list_box.add_child(button(("✓ " if owned else "◇ 45  ")+ ("Soaker system" if k=="water" else "Gentle auto-pruner"),func(): buy_automation(k)))
   list_box.add_child(button("◇ 65  Expand bed capacity +80",expand_bed))
   add_note("TOOLS  ·  first upgrades day 3, master day 18",14)
   for kind in ["can","shears","trowel","rake"]:
    var k: String = kind
    var level: int = int(upgrades[k])
    var names = {"can":"Watering can", "shears":"Pruning shears", "trowel":"Planting trowel", "rake":"Garden rake"}
    list_box.add_child(button(names[k]+(" · complete" if level>=2 else " +"+str(level+1)+"   ◇ "+str(45+level*45)),func(): buy_tool(k)))
   add_note("ORNAMENTS & STRUCTURES",14)
   for i in range(furniture.size()):
    var idx = i
    var b = button(furniture[i].name+"   ◇ "+str(furniture[i].price),func(): choose_furnishing(idx))
    b.tooltip_text = furniture[i].hint
    list_box.add_child(b)
   for i in range(objects.size()):
    if objects[i].kind=="sign":
     var sign_index=i
     list_box.add_child(button("Edit sign: "+str(objects[i].get("text","My garden")).left(22),func(): open_sign_editor(sign_index)))
   list_box.add_child(button("◇ 20  Stock nearest pond with fish",stock_fish))
   add_note("A LITTLE MORE ROOM",14)
   if unlocked_plots<plots.size(): list_box.add_child(button("Open "+plots[unlocked_plots].name+"   ◇ "+str(plots[unlocked_plots].cost),buy_plot))
   else: add_note("Every path is open. Keep making it yours.")
   detail_label.text = "Aim at a nearby patch of ground.\nNew beds open over time; after day 36, another opens every 12 days."
  "Orders":
   request_unread=false
   request_popup_time=0
   side_title.text = "Notes from neighbours"
   add_note("No deadlines. A thank-you, whenever you're ready.")
   for i in range(orders.size()):
    var idx = i
    var order = orders[i]
    if order.get("pending",false):
     add_note(order.person+" sends thanks. Next note on day %d." % order.ready_day)
     continue
    add_note(order.person+" would love",16)
    add_note("%d × %s  ·  in basket: %d" % [order.count,catalogue[order.plant].name,int(inventory.get(str(order.plant),0))])
    list_box.add_child(button("Deliver   +"+str(order.reward)+" petals",func(): fulfill_order(idx)))
   add_note("YOUR BASKET",14)
   var total = 0
   for key in inventory:
    if int(inventory[key])>0:
     add_note(catalogue[int(key)].name+" × "+str(inventory[key]))
     total += int(inventory[key])
   if total==0: add_note("Gather mature flowers and produce to fill your basket.")
   list_box.add_child(button("Sell spare harvest",sell_harvest))
   detail_label.text = "Gathering keeps the plant and starts its next bloom. Trees and shrubs offer cuttings."
  "Sign":
   sign_editor_page()
  "Settings":
   GardenExperience.settings_page(self)
  "Guide":
   GardenExperience.journey(self)
   side_title.text = "A field companion"
   add_note("GROWING IN LAYERS",15)
   add_note("Groundcover, flowers and shrubs share planting rows. Trees sit between the rows, above the underplanting. Each uses 1, 2, 4 or 7 capacity. Press L to target a layer. Trees shade nearby plants; leave sunny flowers at the edges.")
   add_note("A GENTLE RHYTHM",15)
   add_note("A day lasts 10 minutes; G plays a six-second sunset, starry night and sunrise into the next morning. Each season lasts 12 days. Plants take 2–28 ideal growing days. Seasonal plants rest outside their growing season, keeping all progress. Greenhouses let them grow year-round. Rain gently waters plants. Plants never die.")
   add_note("WELCOMING WILDLIFE",15)
   add_note("Native plants → native birds\nThree flowering plants → bees & butterflies\nTrees or bird baths → songbirds\nPonds → frogs & dragonflies\nMoss and dusk → fireflies\nFish → stock a placed pond in the shop")
   add_note("STRUCTURES & PHOTOS",15)
   add_note("Q rotates a structure anticlockwise; E rotates clockwise in 15° steps. Use these while placing or moving an ornament. Tab releases the pointer for the rotation buttons.\nP enters photo mode: WASD fly, Q/E move down/up, right-drag looks around, and F12 captures a photo. Press P again to return.")
   add_note("COMPANIONS",15)
   for i in range(2):
    var idx = i
    var input = LineEdit.new()
    input.text = companion_names[i]
    input.placeholder_text = "Name your "+("cat" if i==0 else "dog")
    input.max_length = 24
    input.text_changed.connect(func(value): companion_names[idx]=value)
    list_box.add_child(input)
   add_note("Walk near a companion and press E for a little affection. No feeding, chores or worries.")
   list_box.add_child(button("Save garden",func(): save_game(); toast("Your garden is saved.")))
   list_box.add_child(button("Comfort & sound settings",func(): open_sidebar("Settings")))
   detail_label.text = "WASD move · Shift stroll faster\nMouse look · Tab menus · Wheel field of view\nL switches target layer · Esc settings"

func refresh_ui() -> void:
 refresh_sidebar()
 update_hud()

func update_hud() -> void:
 if is_instance_valid(orders_button): orders_button.text="Orders •" if request_unread else "Orders"
 var menus=Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and not photo_mode and not day_transition
 hud_top.visible=menus
 hud_title.visible=menus
 rotation_panel.visible=not photo_mode and not day_transition and (mode=="build" or (mode=="move" and moved_object>=0))
 hud_tools.visible=menus
 hud_foot.visible=menus
 compact_hud.visible=not menus and not photo_mode and not day_transition
 hud_capacity.visible=not photo_mode and not day_transition and ((hover_valid and mode!="walk") or (menus and active_tab=="Shop"))
 tip_label.visible=not photo_mode and not day_transition
 tip_label.position=Vector2(356,753) if menus else Vector2(28,850)
 compact_hud.text="ZEND GARDEN   /   "+plots[current_plot].name+"\nDay %02d   ·   %02d:%02d   ·   %d petals   ·   %s" % [day,int(clock_time*24),int(fmod(clock_time*1440,60)),coins,mode.capitalize()]
 compact_hud.text+="\n"+GardenClimate.season(day)+" · "+climate.description()
 var hour = int(clock_time*24)
 top_label.text = "DAY %02d · %02d:%02d  |  ◇ %d petals" % [day,hour,int(fmod(clock_time*1440,60)),coins]
 hud_top.reset_size()
 var used = capacity_used(current_plot)
 var cap = plot_capacity(current_plot)
 var pending = int(catalogue[selected].capacity) if mode=="plant" and hover_valid else 0
 capacity_label.text = plots[current_plot].name+"   "+str(used)+(" +"+str(pending) if pending else "")+" / "+str(cap)
 capacity_bar.max_value = cap
 capacity_bar.value = used+pending
 capacity_bar.modulate=Color("d68d78") if used+pending>cap else Color.WHITE
 status_label.text = "%s · %s%s" % [plots[current_plot].condition.capitalize(),["ground","flowers","shrubs","canopy"][selected_layer]," · auto-care" if automation.has(str(current_plot)+"water") else ""]
 if hover_valid:
  var target = plant_at(hover_cell,selected_layer)
  if target>=0:
   var p = planted[target]
   status_label.text += "\n"+catalogue[p.id].name+" · "+("ready" if p.age>=catalogue[p.id].days else str(int(100*p.age/catalogue[p.id].days))+"% grown")+" · "+("thirsty" if p.water<=0 else "watered")
 if hover_valid:
  var index=plant_at(hover_cell,selected_layer)
  if index>=0 and growth_conditions(planted[index])==0: status_label.text+="\nResting until "+Catalogue.growing_seasons(planted[index].id)
 for key in mode_buttons:
  mode_buttons[key].add_theme_stylebox_override("normal",GardenTheme.frame("button",Color("efcd8c") if key==mode else Color.WHITE,8))
 var tips = {"walk":"WASD walk  ·  Mouse look  ·  Tab garden menus  ·  E greet companion  ·  G next morning", "plant":"Aim at soil & click to plant  ·  Tab seeds  ·  L layer  ·  G next morning", "water":"Click plants to water  ·  Upgrade your can for a wider, longer pour", "prune":"Click to ease stress and encourage new growth", "harvest":"Click a mature plant to gather  ·  It will bloom again", "move":"Click a plant or ornament, then click its new home  ·  L target layer", "remove":"Click to lift a plant or ornament  ·  L target layer  ·  Seeds stay yours", "rake":"Click a path or lawn to tidy it and reveal a little reward", "build":"Click to place "+furniture[selected_furniture].name+"  ·  Esc cancel"}
 tip_label.text = tips.get(mode,"")
 if mode=="build" or (mode=="move" and moved_object>=0): tip_label.text+="  ·  Q/E rotate 15°"
 if hover_valid and not preview_error.is_empty() and mode=="plant": status_label.text=preview_error

func show_welcome() -> void:
 GardenExperience.welcome(self)

func apply_settings() -> void:
 if is_instance_valid(ambient):
  ambient.music_volume=float(settings.music_volume)/100
  ambient.nature_volume=float(settings.nature_volume)/100
 view_fov=float(settings.fov)
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(.0001,float(settings.volume)/100)))
 if not settings.request_notifications and is_instance_valid(request_popup): request_popup.hide()

func dismiss_request() -> void:
 request_popup_time=0
 if is_instance_valid(request_popup): request_popup.hide()
 if request_return_to_game and not side_panel.visible:
  Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 request_return_to_game=false

func notify_requests() -> void:
 request_unread=true
 if not settings.request_notifications:
  dismiss_request()
  return
 if is_instance_valid(request_popup): request_popup.queue_free()
 request_popup=panel_at(Vector2(1030,295),Vector2(380,190))
 request_popup.z_index=15
 request_return_to_game=Input.mouse_mode==Input.MOUSE_MODE_CAPTURED
 if not photo_mode and not day_transition: Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var col=VBoxContainer.new()
 request_popup.add_child(col)
 col.add_child(label("A note at the garden gate",20))
 col.add_child(label("A neighbour has a new request.
A little kindness, whenever you’re ready.",15))
 col.add_child(button("Read neighbour requests",func(): request_return_to_game=false; dismiss_request(); open_sidebar("Orders")))
 col.add_child(button("Later",dismiss_request,Vector2(0,28)))
 request_popup_time=1.0 # Remain available until the player responds.

func replenish_orders() -> void:
 var arrived=false
 for i in range(orders.size()):
  if int(orders[i].get("ready_day",0))>day or not orders[i].get("pending",false): continue
  var pool=[]
  for id in unlocked_plants:
   if catalogue[id].category in ["Flowers","Produce"]: pool.append(id)
  var id=pool[(day+i+fulfilled)%pool.size()]
  orders[i]={"person":["Hazel at the bakery","Jun, your neighbour","Mae at the cottage"][i],"plant":id,"count":2,"reward":18+int(catalogue[id].value)*2}
  arrived=true
 if arrived: notify_requests()

func _process(delta: float) -> void:
 if not is_instance_valid(camera): return
 if is_instance_valid(welcome):
  return
 if is_instance_valid(request_popup):
  var show_note=request_popup_time>0 and settings.request_notifications and not photo_mode and not day_transition
  if show_note and not request_popup.visible: Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
  request_popup.visible=show_note
 var input_focus = get_viewport().gui_get_focus_owner() is LineEdit
 var move = Vector3.ZERO
 if not day_transition and not input_focus and not is_instance_valid(welcome) and (Input.mouse_mode==Input.MOUSE_MODE_CAPTURED or photo_mode):
  move.x = float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A))
  move.z = float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))
  move = move.rotated(Vector3.UP,yaw).normalized()
 if photo_mode:
  camera_target += move*delta*8
  camera_target.y += (float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)))*delta*4
 else:
  var speed = 5.5 if Input.is_physical_key_pressed(KEY_SHIFT) else 3.2
  var next = player.position+move*delta*speed
  player.velocity.x = move.x*speed if accessible(next) else 0.0
  player.velocity.z = move.z*speed if accessible(next) else 0.0
  if not player.is_on_floor(): player.velocity.y -= 18.0*delta
  else: player.velocity.y = 0
  walk_motion(Vector3(player.velocity.x,0,player.velocity.z)*delta)
  player.move_and_slide()
  var stride=sin(Time.get_ticks_msec()*0.012)*0.45*minf(1,move.length())
  player.get_node("LegLeft").rotation.x=stride
  player.get_node("LegRight").rotation.x=-stride
  if move.length()>0.1:
   player.rotation.y = lerp_angle(player.rotation.y,atan2(-move.x,-move.z),delta*10)
  camera_target = camera_target.lerp(player.position+Vector3(0,1.15,0),minf(1,delta*8))
  if mode=="walk": current_plot=nearest_plot(player.position)
  if day_transition: update_day_transition(delta)
  elif not (settings.pause_menus and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and not smoke):
   clock_time += delta/DAY_SECONDS
   if clock_time>=1:
    clock_time-=1
    advance_growth()
 update_camera(delta)
 climate.update(self,delta)
 update_lighting()
 climate.apply(self)
 action_cooldown = maxf(0,action_cooldown-delta)
 update_hover()
 animate_garden(delta)
 toast_time -= delta
 toast_label.visible = toast_time>0 and not photo_mode and not day_transition
 save_timer += delta
 if save_timer>20 and not smoke:
  save_timer=0
  save_game()
 ui_refresh += delta
 if ui_refresh>0.3:
  ui_refresh=0
  update_hud()

func update_camera(_delta: float) -> void:
 camera.fov=view_fov
 if photo_mode:
  camera.position=camera_target
 else:
  camera.position=player.position+Vector3(0,1.62,0)
 camera.rotation=Vector3(-pitch,yaw,0)
 if day_transition and not settings.reduced_motion:
  camera.rotation.x=lerpf(-pitch,.40,sin(transition_elapsed/TRANSITION_SECONDS*PI)*.85)
 if is_instance_valid(reticle): reticle.visible=not photo_mode and not day_transition and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED
 if is_instance_valid(held_tool):
  var tools_by_mode={"water":"can","prune":"shears","harvest":"shears","plant":"trowel","remove":"trowel","rake":"rake"}
  var active=tools_by_mode.get(mode,"")
  for key in tool_models: tool_models[key].visible=key==active and not photo_mode and not day_transition and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED


func walk_motion(motion: Vector3) -> void:
 if motion.length()<.0001 or player.velocity.y>0: return
 var contact=KinematicCollision3D.new()
 if not player.test_move(player.global_transform,motion,contact): return
 # Clear headroom, move over a low obstacle, then land on a walkable top.
 var raised=player.global_transform
 if player.test_move(raised,Vector3.UP*.48): return
 raised.origin.y+=.48
 var probe=motion.normalized()*maxf(motion.length(),.36)
 if player.test_move(raised,probe): return
 raised.origin+=probe
 var landing=KinematicCollision3D.new()
 if not player.test_move(raised,Vector3.DOWN*.55,landing): return
 if landing.get_normal().y<cos(player.floor_max_angle): return
 var top=raised.origin+landing.get_travel()
 if top.y-player.position.y>.49 or top.y-player.position.y<.015: return
 player.position.y=top.y+.005
 player.velocity.y=0

func accessible(pos: Vector3) -> bool:
 var north=minf(-26,-(int(plots.size()/2)-1)*17-8)
 if pos.x < -8.5 or pos.x > 25.5 or pos.z > 9 or pos.z < north: return false
 if pos.x>6.6 and pos.x<10.4 and pos.z>-7 and pos.z<7:
  return abs(pos.z-5.9)<0.92
 if pos.z>-10 and pos.z<-7 and pos.x>10 and pos.x<24:
  return abs(pos.x-17)<0.92
 return true

func nearest_plot(pos: Vector3) -> int:
 var idx = 0
 var best = INF
 for i in range(plots.size()):
  var d = pos.distance_squared_to(plots[i].center)
  if d<best: best=d; idx=i
 return idx

func bed_at(pos: Vector3) -> int:
 for i in range(plots.size()):
  var c: Vector3 = plots[i].center
  if abs(pos.x-c.x)<4.7 and abs(pos.z-c.z)<4.7: return i
 return -1

func snap_to_bed(pos: Vector3, plot: int, layer: int = -1) -> Vector3:
 return snap_plant_position(pos, plots[plot].center, layer, true)

func snap_plant_position(pos: Vector3, center: Vector3, layer: int, in_bed: bool) -> Vector3:
 var offset = 0.5 if layer==3 else 0.0
 var x = round((pos.x-center.x)/GRID-offset)+offset
 var z = round((pos.z-center.z)/GRID-offset)+offset
 if in_bed:
  var edge = 11.5 if layer==3 else 11.0
  x=clampf(x,-edge,edge)
  z=clampf(z,-edge,edge)
 return GardenTerrain.point(Vector3(x*GRID+center.x,0,z*GRID+center.z))

func placement_layer() -> int:
 if mode=="plant": return int(catalogue[selected].layer)
 if mode=="move" and moved_index>=0: return int(catalogue[int(planted[moved_index].id)].layer)
 return -1

func target_plant(pos: Vector3) -> int:
 # Pick from the actual ground aim, so old and offset positions both remain reachable.
 var chosen = -1
 var nearest = GRID*.75
 for i in range(planted.size()):
  if int(catalogue[int(planted[i].id)].layer)!=selected_layer: continue
  var distance = Vector2(planted[i].pos.x-pos.x,planted[i].pos.z-pos.z).length()
  if distance<nearest: chosen=i; nearest=distance
 if chosen>=0: return chosen
 for i in range(planted.size()):
  var distance = Vector2(planted[i].pos.x-pos.x,planted[i].pos.z-pos.z).length()
  if distance<nearest: chosen=i; nearest=distance
 return chosen

func apply_mouse_look(movement: Vector2) -> void:
 var sensitivity=0.0022*float(settings.sensitivity)
 yaw -= movement.x*sensitivity*(-1 if settings.invert_x else 1)
 pitch = clampf(pitch+movement.y*sensitivity*(-1 if settings.invert_y else 1),-1.45,1.45)

func _unhandled_input(event: InputEvent) -> void:
 if is_instance_valid(welcome): return
 if day_transition: return
 if event is InputEventMouseMotion and (Input.mouse_mode==Input.MOUSE_MODE_CAPTURED or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
  apply_mouse_look(event.relative)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP: view_fov=clampf(view_fov-2,45,90)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN: view_fov=clampf(view_fov+2,45,90)
  elif event.button_index==MOUSE_BUTTON_LEFT and not photo_mode and not is_instance_valid(welcome):
   if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:
    side_panel.hide()
    Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
   else: perform_action()
 if event is InputEventKey and event.pressed and not event.echo:
  if get_viewport().gui_get_focus_owner() is LineEdit: return
  match event.physical_keycode:
   KEY_1: set_mode("walk")
   KEY_2: set_mode("plant")
   KEY_3: set_mode("water")
   KEY_4: set_mode("prune")
   KEY_5: set_mode("harvest")
   KEY_6: set_mode("move")
   KEY_7: set_mode("remove")
   KEY_8: set_mode("rake")
   KEY_G: if not photo_mode: next_day()
   KEY_P: toggle_photo()
   KEY_TAB:
    if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
     Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
     side_panel.show()
    else:
     side_panel.hide()
     Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
   KEY_L:
    selected_layer=(selected_layer+1)%4
    toast("Target layer: "+["groundcover","flowers","shrubs","canopy"][selected_layer])
   KEY_Q: if not photo_mode: rotate_structure(-1)
   KEY_E:
    if not photo_mode:
     if mode=="build" or (mode=="move" and moved_object>=0): rotate_structure(1)
     else: greet_pet()
   KEY_F12: capture_photo()
   KEY_ESCAPE:
    if photo_mode: toggle_photo()
    elif is_instance_valid(welcome): welcome.queue_free(); welcome=null
    else:
     set_mode("walk")
     open_sidebar("Settings")

func set_mode(value: String) -> void:
 mode=value
 if value=="build": structure_rotation=0.0
 side_panel.visible=value=="plant"
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if value=="plant" else Input.MOUSE_MODE_CAPTURED
 if value=="plant": active_tab="Seeds"; refresh_sidebar()
 moved_index=-1
 moved_object=-1
 if is_instance_valid(preview): preview.queue_free(); preview=null
 preview_id=""
 preview_error=""
 update_hud()

func rotate_structure(direction: int) -> void:
 if day_transition or photo_mode: return
 if mode!="build" and not (mode=="move" and moved_object>=0): return
 structure_rotation=wrapf(structure_rotation-direction*PI/12.0,-PI,PI)
 if is_instance_valid(preview): preview.rotation.y=structure_rotation

func choose_plant(id: int) -> void:
 if id not in unlocked_plants:
  if coins<catalogue[id].price:
   toast("This variety opens through new plots too. Keep exploring.")
   return
  coins-=catalogue[id].price
  unlocked_plants.append(id)
  toast(catalogue[id].name+" added to your seed collection, forever.")
 selected=id
 selected_layer=catalogue[id].layer
 set_mode("plant")
 side_panel.hide()
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 refresh_ui()

func update_hover() -> void:
 grid_cursor.hide()
 grid_root.hide()
 if is_instance_valid(preview): preview.hide()
 hover_valid=false
 if day_transition or photo_mode or mode=="walk": return
 if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and get_viewport().gui_get_hovered_control()!=null: return
 var mouse = get_viewport().get_visible_rect().size*0.5 if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else get_viewport().get_mouse_position()
 var origin = camera.project_ray_origin(mouse)
 var dir = camera.project_ray_normal(mouse)
 var hit = GardenTerrain.ray(origin,dir)
 if not hit.is_finite(): return
 hover_plot=bed_at(hit)
 hover_plot=nearest_plot(hit) if hover_plot<0 else hover_plot
 var layer=placement_layer()
 hover_cell=snap_to_bed(hit,hover_plot,layer) if bed_at(hit)>=0 else snap_plant_position(hit,Vector3.ZERO,layer,false)
 if mode in ["water","prune","harvest","remove"] or (mode=="move" and moved_index<0 and moved_object<0):
  var target=target_plant(hit)
  if target>=0: hover_cell=planted[target].pos
 if hover_plot>=unlocked_plots: return
 if player.position.distance_to(hover_cell)>7: return
 if not accessible(hover_cell) and bed_at(hover_cell)<0: return
 hover_valid=true
 current_plot=hover_plot
 grid_cursor.position=hover_cell
 grid_cursor.show()
 if bed_at(hover_cell)>=0 and mode in ["plant","move","build"]:
  grid_root.position=plots[hover_plot].center+Vector3(GRID*.5,0,GRID*.5) if layer==3 else plots[hover_plot].center
  for tile in grid_root.get_children():
   var p=grid_root.position+tile.position
   tile.position.y=GardenTerrain.point(p).y
   tile.visible=bed_at(p)==hover_plot
  grid_root.show()
 var pid = ""
 if mode=="plant": pid="p"+str(selected)
 if mode=="build": pid="f"+str(selected_furniture)
 if mode=="move" and moved_index>=0: pid="p"+str(planted[moved_index].id)
 if mode=="move" and moved_object>=0: pid="o"+str(moved_object)
 if not pid.is_empty():
  if preview_id!=pid:
   if is_instance_valid(preview): preview.queue_free()
   if pid.begins_with("p"): preview=Art.plant(catalogue[int(pid.substr(1))])
   elif pid.begins_with("f"): preview=Art.furnishing(furniture[selected_furniture].kind)
   else: preview=Art.furnishing(objects[moved_object].kind)
   if pid.begins_with("f") and furniture[selected_furniture].kind=="sign": Art.set_sign_text(preview,sign_text,sign_color)
   if pid.begins_with("o") and objects[moved_object].kind=="sign": Art.set_sign_text(preview,objects[moved_object].text,Color.from_string(objects[moved_object].text_color,Color("f1e5c7")))
   add_child(preview)
   preview_id=pid
   ghost_material(preview)
  preview.position=hover_cell
  if pid.begins_with("f") or pid.begins_with("o"): preview.rotation.y=structure_rotation
  preview.show()
  var error=can_plant(selected,hover_cell,hover_plot) if mode=="plant" else ""
  if mode=="move" and moved_index>=0: error=can_plant(int(planted[moved_index].id),hover_cell,hover_plot,moved_index)
  if error!=preview_error or preview_id!=pid:
   ghost_material(preview,Color(0.94,0.53,0.40,0.45) if not error.is_empty() else Color(0.82,0.95,0.66,0.4))
  preview_error=error

func ghost_material(node: Node, tint: Color = Color(0.82,0.95,0.66,0.4)) -> void:
 if node is MeshInstance3D: node.material_override=Art.mat(tint)
 for child in node.get_children(): ghost_material(child,tint)

func capacity_used(plot: int, excluding: int = -1) -> int:
 var amount = 0
 for i in range(planted.size()):
  if i!=excluding and int(planted[i].plot)==plot: amount+=int(catalogue[int(planted[i].id)].capacity)
 return amount

func plot_capacity(plot: int) -> int:
 return (int(plots[plot].cap)+int(expansions.get(str(plot),0))*20)*CAPACITY_MULTIPLIER

func plant_at(pos: Vector3, layer: int, excluding: int = -1) -> int:
 for i in range(planted.size()):
  if i!=excluding and Vector2(planted[i].pos.x-pos.x,planted[i].pos.z-pos.z).length()<GRID*.35 and int(catalogue[int(planted[i].id)].layer)==layer: return i
 return -1

func object_at(pos: Vector3) -> int:
 for i in range(objects.size()):
  if objects[i].pos.distance_to(pos)<0.8: return i
 return -1

func plantable_ground(pos: Vector3) -> bool:
 if not accessible(pos): return false
 if pos.x>6.3 and pos.x<10.7 and pos.z>-7.3 and pos.z<7.3: return false
 if pos.z>-10.3 and pos.z<-6.7 and pos.x>10 and pos.x<24: return false
 if absf(pos.x+7.4)<2 and absf(pos.z+18)<2: return false
 if object_at(pos)>=0: return false
 return true

func can_plant(id: int, pos: Vector3, plot: int, excluding: int = -1) -> String:
 if plot<0 or plot>=unlocked_plots: return "Choose an unlocked garden area."
 var bed=bed_at(pos)
 if bed>=0 and bed!=plot: return "Choose an open garden bed."
 if bed<0 and not plantable_ground(pos): return "Choose dry ground away from bridges, water and structures."
 if capacity_used(plot,excluding)+int(catalogue[id].capacity)>plot_capacity(plot): return "This bed is full. Lift a plant, move one, or expand its capacity."
 if plant_at(pos,catalogue[id].layer,excluding)>=0: return "This layer is occupied. Another layer can share this square."
 # Root systems require room at canopy level, but allow genuine underplanting.
 if int(catalogue[id].layer)==3:
  for i in range(planted.size()):
   if i!=excluding and int(catalogue[int(planted[i].id)].layer)==3 and Vector2(planted[i].pos.x-pos.x,planted[i].pos.z-pos.z).length()<TREE_SPACING-0.001: return "Give this tree’s roots a little more room (1.15 m between trees)."
 return ""

func perform_action() -> void:
 if day_transition: return
 if mode=="walk": return
 if not hover_valid:
  toast("Walk a little closer to an open garden area.")
  return
 if action_cooldown>0: return
 animate_tool_action()
 var idx = plant_at(hover_cell,selected_layer)
 if idx<0:
  for layer in range(4):
   idx=plant_at(hover_cell,layer)
   if idx>=0: break
 match mode:
  "plant":
   var error = can_plant(selected,hover_cell,hover_plot)
   if not error.is_empty(): toast(error); return
   add_plant(selected,hover_cell,hover_plot)
   planted_total+=1
   action_cooldown=0.55/(1.0+int(upgrades.trowel))
   toast(catalogue[selected].name+" planted. A little beginning.")
  "water", "prune":
   var radius = 0.65+int(upgrades.can if mode=="water" else upgrades.shears)*1.25
   var count = 0
   for p in planted:
    if p.pos.distance_to(hover_cell)<=radius:
     if mode=="water": p.water=2.0+int(upgrades.can)*1.5
     else:
      p.stress=maxf(0,p.stress-(0.55+int(upgrades.shears)*0.25))
      p.pruned=1.0
      refresh_plant(p)
     count+=1
     care_effect(p.pos,Color("a8dce1") if mode=="water" else Color("efdda7"))
   toast(("Watered " if mode=="water" else "Tended ")+str(count)+" plants.")
   action_cooldown=0.3
  "harvest":
   if idx<0: toast("Choose a plant to gather from."); return
   var p = planted[idx]
   if p.age<float(catalogue[p.id].days): toast("Still growing. Every morning brings a little more."); return
   inventory[str(p.id)]=int(inventory.get(str(p.id),0))+1
   p.age=maxf(0.5,p.age-1.5)
   refresh_plant(p)
   toast("Gathered "+catalogue[p.id].name+". It will bloom again.")
  "remove":
   if idx>=0:
    planted[idx].marker.queue_free()
    planted[idx].node.queue_free()
    planted.remove_at(idx)
    toast("Lifted gently. There are always more seeds.")
   else:
    var obj = object_at(hover_cell)
    if obj>=0:
     coins+=int(objects[obj].price)
     objects[obj].node.queue_free()
     objects.remove_at(obj)
     toast("Packed away. Full ornament cost returned.")
  "move":
   if moved_index<0 and moved_object<0:
    if idx>=0: moved_index=idx; toast("Now choose a new square for "+catalogue[planted[idx].id].name+".")
    else:
     moved_object=object_at(hover_cell)
     if moved_object>=0:
      structure_rotation=float(objects[moved_object].get("rotation",0.0))
      toast("Choose a new home. Q/E rotates the ornament.")
   elif moved_index>=0:
    var p = planted[moved_index]
    var error = can_plant(p.id,hover_cell,hover_plot,moved_index)
    if not error.is_empty(): toast(error); return
    p.pos=hover_cell
    p.plot=hover_plot
    p.node.position=hover_cell
    p.marker.position=hover_cell
    var vines=p.node.get_node_or_null("Vines")
    if vines: p.node.remove_child(vines); vines.queue_free()
    set_mode("move")
    toast("A fresh arrangement. Growth stays with your plant.")
   else:
    var occupied=object_at(hover_cell)
    if occupied>=0 and occupied!=moved_object: toast("Another ornament is here."); return
    objects[moved_object].pos=hover_cell
    objects[moved_object].node.position=hover_cell
    objects[moved_object].rotation=structure_rotation
    objects[moved_object].node.rotation.y=structure_rotation
    set_mode("move")
  "build":
   var f = furniture[selected_furniture]
   if coins<f.price: toast("Gather or fill a neighbour’s order for more petals."); return
   if object_at(hover_cell)>=0: toast("There is already an ornament here."); return
   coins-=f.price
   add_object(f.kind,hover_cell,f.price,false,structure_rotation,sign_text,sign_color)
   toast(f.name+" placed. "+f.hint)
  "rake":
   if bed_at(hover_cell)>=0 or not plantable_ground(hover_cell): toast("Rake dry paths and lawn away from bridges and structures."); return
   var key = str(round(hover_cell.x))+":"+str(round(hover_cell.z))
   if key not in clean_paths:
    clean_paths.append(key)
    var found=mini(1+int(upgrades.rake),maxi(0,4-rake_petals))
    coins+=found
    rake_petals+=found
    path_widths[key]=.95+int(upgrades.rake)*.3
    var xy=key.split(":")
    GardenGroundFinish.path(self,Vector3(float(xy[0]),0,float(xy[1])),path_widths[key])
    toast("A tidy little corner."+(" Found %d petals." % found if found>0 else ""))
   else: toast("Already looking lovely here.")
 refresh_ui()
 refresh_wildlife()

func add_plant(id: int, pos: Vector3, plot: int, age: float = 0.0, height_factor: float = 0.0) -> Dictionary:
 pos=GardenTerrain.point(pos)
 var n = Art.plant(catalogue[id])
 plant_root.add_child(n)
 n.position=pos
 n.rotation.y=rng.randf()*TAU
 var marker=Node3D.new()
 marker.name="PlantedSeedMarker"
 marker.position=pos
 plant_root.add_child(marker)
 Art.ball(marker,Vector3(0,.025,0),Vector3(.30,.06,.30),Color("483726"))
 Art.box(marker,Vector3(.13,.15,.09),Vector3(.028,.30,.025),Color("b69869"))
 Art.box(marker,Vector3(.13,.29,.09),Vector3(.13,.10,.022),catalogue[id].color)
 var mature_height=clampf(height_factor,0.8,1.2) if height_factor>0.0 else rng.randf_range(0.8,1.2)
 var p = {"height_factor":mature_height,"marker":marker,"id":id,"pos":pos,"plot":plot,"age":age,"water":2.0,"stress":0.0,"pruned":0.0,"node":n}
 n.scale=plant_scale(p)
 planted.append(p)
 refresh_plant(p)
 return p

func add_object(kind: String, pos: Vector3, price: int, fish: bool = false, orientation: float = 0.0, text: String = "My garden", color: Color = Color("f1e5c7")) -> void:
 pos=GardenTerrain.point(pos)
 var n = Art.furnishing(kind)
 object_root.add_child(n)
 n.position=pos
 n.rotation.y=orientation
 objects.append({"rotation":orientation,"kind":kind,"pos":pos,"price":price,"fish":fish,"node":n})
 if kind=="sign":
  objects[-1]["text"]=Art.clean_sign_text(text)
  objects[-1]["text_color"]=color.to_html(false)
  Art.set_sign_text(n,objects[-1].text,color)
 if fish: make_fish(n)

func plant_scale(p: Dictionary) -> Vector3:
 var fraction=clampf(float(p.age)/float(catalogue[int(p.id)].days),0,1)
 var amount=0.12+fraction*0.88
 var trim=float(p.get("pruned",0.0))
 var width=1.0-trim*(.20 if catalogue[int(p.id)].layer>=2 else .07)
 # Seedlings start alike; each plant gradually reaches its own mature height.
 var height=lerpf(1.0,float(p.get("height_factor",1.0)),fraction)*(1.0-trim*.30)
 return Vector3(width,height,width)*amount

func legacy_height_factor(p: Dictionary) -> float:
 # Old saves acquire a repeatable value, even before their first new save.
 var key="%d:%.6f:%.6f" % [int(p.id),float(p.pos[0]),float(p.pos[1])]
 return 0.8+float(key.hash()%1000001)/1000000.0*0.4

func refresh_plant(p: Dictionary) -> void:
 var fraction = clampf(p.age/float(catalogue[p.id].days),0,1)
 p.marker.visible=fraction<.52
 if p.has("shape_tween") and is_instance_valid(p.shape_tween): p.shape_tween.kill()
 var tween = create_tween()
 p.shape_tween=tween
 tween.tween_property(p.node,"scale",plant_scale(p),0.9).set_trans(Tween.TRANS_SINE)
 p.node.get_node("Bloom").visible=fraction>=0.52

func starter_garden() -> void:
 for entry in [[28,-2,-2,5],[0,-2,0,2],[0,-1,0,1.5],[2,0,0,2],[1,1,-1,3],[12,-2,-2,2],[14,0,1,2],[37,2,0,2],[48,1,2,0.7],[50,2,2,1.3],[3,2,-2,3],[20,-2,1,4],[1,-1,1,3],[0,0,-2,2],[12,-1,0,2]]:
  add_plant(entry[0],Vector3(entry[1]*1.15,0,entry[2]*1.15),0,entry[3]/float(Catalogue.ROWS[entry[0]][4])*catalogue[entry[0]].days)
 add_object("bench",Vector3(-4,0,5.7),45)
 add_object("lantern",Vector3(4.8,0,5.6),55)
 refresh_wildlife()

func growth_conditions(p: Dictionary) -> float:
 for obj in objects:
  if obj.kind=="greenhouse" and obj.pos.distance_to(p.pos)<=4: return 1.0
 if not catalogue[p.id].seasons.is_empty() and GardenClimate.season(day) not in catalogue[p.id].seasons: return 0.0
 var wanted: String = catalogue[p.id].condition
 var actual: String = plots[p.plot].condition
 for other in planted:
  if int(catalogue[other.id].layer)==3 and other.pos.distance_to(p.pos)<2.3 and other.age/float(catalogue[other.id].days)>=.52 and int(catalogue[p.id].layer)<3: actual="shade"
 return 1.0 if wanted=="any" or wanted==actual else 0.6

func next_day() -> void:
 if day_transition or photo_mode: return
 if settings.reduced_motion:
  advance_growth()
  clock_time=.30
  return
 day_transition=true
 transition_elapsed=0.0
 transition_start=clock_time
 transition_crossed_midnight=false
 side_panel.hide()
 transition_label.show()
 update_hud()

func update_day_transition(delta: float) -> void:
 transition_elapsed=minf(TRANSITION_SECONDS,transition_elapsed+delta)
 var progress=transition_elapsed/TRANSITION_SECONDS
 var elapsed_clock=lerpf(transition_start,1.30,smoothstep(0,1,progress))
 clock_time=fposmod(elapsed_clock,1.0)
 if elapsed_clock>=1.0 and not transition_crossed_midnight:
  transition_crossed_midnight=true
  advance_growth()
 transition_label.text="A new morning" if elapsed_clock>=1.22 else ("Under the stars" if clock_time>.78 or clock_time<.22 else ("The sun slips away" if clock_time>.65 else "The garden takes a breath"))
 transition_label.modulate.a=sin(progress*PI)
 if progress>=1:
  day_transition=false
  transition_label.hide()
  if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED: side_panel.show()
  refresh_ui()
  if not smoke: save_game()


func advance_growth() -> void:
 rake_petals=0
 for p in planted:
  var plot = str(p.plot)
  if automation.has(plot+"water"): p.water=4.0
  if automation.has(plot+"prune"): p.stress=0.0
  p.pruned=maxf(0,float(p.get("pruned",0.0))-.25*growth_conditions(p))
  var health = (1.0 if p.water>0 else 0.4)*(1.0-p.stress*0.35)
  p.age=minf(float(catalogue[p.id].days),p.age+health*growth_conditions(p))
  p.water=maxf(0,p.water-1.0)
  p.stress=minf(1,p.stress+0.13)
  refresh_plant(p)
 day+=1
 if day>=GardenExpansion.opening_day(unlocked_plots): unlock_plot()
 # Seed gifts unfold across seasons; mornings no longer mint currency.
 if day%3==0:
  discover_seeds(1)
 replenish_orders()
 if day in [3,7,18,36]: toast("A new chapter on day %d. See Guide for your garden’s journey." % day)
 refresh_wildlife()
 refresh_ui()
 if not smoke: save_game()

func make_irrigation(center: Vector3) -> void:
 for x in [-3.5,0,3.5]:
  for j in range(20):
   var a=GardenTerrain.point(center+Vector3(x,0,-4+j*.4))+Vector3(0,.025,0)
   var b=GardenTerrain.point(center+Vector3(x,0,-3.6+j*.4))+Vector3(0,.025,0)
   Art.branch(world_root,a,b,.018,Color("546f5c"))

func buy_automation(kind: String) -> void:
 if day<7: toast("Bed care systems arrive on day 7."); return
 var key = str(current_plot)+kind
 if automation.has(key): toast("Already caring for this bed."); return
 if coins<45: toast("This bed system costs 45 petals."); return
 coins-=45
 automation[key]=true
 var c: Vector3 = plots[current_plot].center
 if kind=="water":
  make_irrigation(c)
 else:
  var system = Art.furnishing("pot")
  system.position=GardenTerrain.point(c+Vector3(4.6,0,-4.6))
  world_root.add_child(system)
 toast("Automatic "+kind+" care will tend this bed every morning.")
 refresh_ui()

func buy_tool(kind: String) -> void:
 var level = int(upgrades[kind])
 if day<(3 if level==0 else 18): toast("This tool upgrade arrives on day %d." % (3 if level==0 else 18)); return
 if level>=2: toast("Your tool is fully upgraded."); return
 var cost=45+level*45
 if coins<cost: toast("This upgrade costs "+str(cost)+" petals."); return
 coins-=cost
 upgrades[kind]=level+1
 var notes = {"can":"Wider coverage and water lasts longer.","shears":"Wider reach and more stress relief.","trowel":"Quicker planting between clicks.","rake":"Wider tidy patches and more found petals."}
 toast(notes[kind])
 refresh_ui()

func expand_bed() -> void:
 if coins<65: toast("An expansion costs 65 petals."); return
 coins-=65
 expansions[str(current_plot)]=int(expansions.get(str(current_plot),0))+1
 toast("Room for 80 more capacity. Keep layering.")
 refresh_ui()

func buy_plot() -> void:
 GardenExpansion.prepare(self)
 if coins<int(plots[unlocked_plots].cost): toast("This plot also opens freely as the days pass."); return
 coins-=int(plots[unlocked_plots].cost)
 unlock_plot()
 refresh_ui()

func unlock_plot() -> void:
 GardenExpansion.prepare(self)
 unlocked_plots+=1
 GardenExpansion.prepare(self)
 for row in range(2,int(plots.size()/2)): GardenExpansion.build_row(self,row)
 discover_seeds(3)
 toast(plots[unlocked_plots-1].name+" is open. Follow the path. Three new seed varieties await.")
 for i in range(plot_signs.size()): Art.set_sign_text(plot_signs[i],plots[i].name.to_upper()+("\nOpens day "+str(GardenExpansion.opening_day(i)) if i>=unlocked_plots else ""))

func discover_seeds(count: int) -> void:
 for id in range(catalogue.size()):
  if id not in unlocked_plants:
   unlocked_plants.append(id)
   count-=1
   toast("A gift of "+catalogue[id].name+" seeds. Find them in Seeds.")
   if count<=0: break

func make_orders() -> void:
 if not orders.is_empty(): return
 orders=[{"person":"Hazel at the bakery","plant":0,"count":2,"reward":24},{"person":"Jun, your neighbour","plant":48,"count":2,"reward":22,"pending":true,"ready_day":3},{"person":"Mae at the cottage","plant":50,"count":2,"reward":26,"pending":true,"ready_day":5}]

func fulfill_order(idx: int) -> void:
 var order=orders[idx]
 if order.get("pending",false): return
 var key=str(order.plant)
 if int(inventory.get(key,0))<int(order.count): toast("No rush. Gather a little more "+catalogue[order.plant].name+" first."); return
 inventory[key]=int(inventory[key])-int(order.count)
 coins+=int(order.reward)
 fulfilled+=1
 orders[idx]["pending"]=true
 orders[idx]["ready_day"]=day+2
 if fulfilled in [3,8,15]: discover_seeds(3)
 toast("A grateful note, and petals for your next idea.")
 refresh_ui()

func sell_harvest() -> void:
 var value=0
 for key in inventory:
  value+=int(inventory[key])*maxi(1,int(catalogue[int(key)].value)/2)
  inventory[key]=0
 coins+=value
 toast("Your basket brought "+str(value)+" petals.")
 refresh_ui()

func stock_fish() -> void:
 for obj in objects:
  if obj.kind=="pond" and not obj.fish and nearest_plot(obj.pos)==current_plot:
   if coins<20: toast("Fish cost 20 petals."); return
   coins-=20
   obj.fish=true
   make_fish(obj.node)
   toast("A few little fish settle into the pond.")
   refresh_ui()
   return
 toast("Place an unstocked pond in this garden first.")

func make_fish(parent: Node3D) -> void:
 for j in range(4):
  var fish=Art.ball(parent,Vector3(cos(j*1.7),0.09,sin(j*1.7)),Vector3(0.21,0.06,0.09),Color("efd3a0") if j%2 else Color("d99270"))
  fish.name="Fish"+str(j)

func care_effect(pos: Vector3, color: Color) -> void:
 for j in range(5):
  var mote=Art.ball(self,pos+Vector3(rng.randf_range(-0.4,0.4),1.3+j*0.07,rng.randf_range(-0.4,0.4)),Vector3.ONE*0.065,color)
  var t=create_tween()
  t.tween_property(mote,"position:y",pos.y+0.1,0.55)
  t.tween_callback(mote.queue_free)

func refresh_wildlife() -> void:
 for entry in wildlife: entry.node.queue_free()
 wildlife.clear()
 var native_count=0
 var flowers=0
 var trees=0
 var pond_count=0
 var moss=0
 for p in planted:
  if catalogue[p.id].category=="Natives": native_count+=1
  if catalogue[p.id].category=="Flowers": flowers+=1
  if catalogue[p.id].layer==3: trees+=1
  if p.id==13: moss+=1
 for obj in objects:
  if obj.kind=="pond": pond_count+=1
  if obj.kind=="bath": trees+=1
 var species: Array = []
 if flowers>=3: species.append_array(["butterfly","butterfly","bee","bee"])
 if native_count>=2: species.append_array(["native bird","native bird"])
 if trees>0: species.append("songbird")
 if pond_count>0: species.append_array(["dragonfly","frog"])
 if moss>0: species.append("firefly")
 for i in range(species.size()):
  var kind: String=species[i]
  var n=Art.visitor(kind)
  add_child(n)
  var target=Vector3.ZERO
  if not planted.is_empty(): target=planted[i%planted.size()].pos
  if kind in ["frog","dragonfly"]:
   for obj in objects:
    if obj.kind=="pond": target=obj.pos
  wildlife.append({"node":n,"kind":kind,"target":target,"phase":float(i)*1.73})

func animate_garden(delta: float, sample_time: float = -1.0) -> void:
 var t=Time.get_ticks_msec()*0.001 if sample_time<0 else sample_time
 for p in planted:
  p.node.rotation.z=sin(t*1.25+p.pos.x)*0.018
  # Vines extend visibly up nearby support frames as they mature.
  if catalogue[p.id].climber and p.age>=2 and not p.node.has_node("Vines"):
   for obj in objects:
    if obj.kind in ["arbor","pergola"] and obj.pos.distance_to(p.pos)<3:
     var vine=Node3D.new()
     vine.name="Vines"
     p.node.add_child(vine)
     var end: Vector3=(obj.pos-p.pos)+Vector3(0,2.6,0)
     Art.branch(vine,Vector3(0,0.2,0),end,0.03,Color("7b9662"))
     for j in range(8): Art.ball(vine,end+Vector3(-1+j*0.27,0,0),Vector3(0.32,0.15,0.27),catalogue[p.id].color)
     break
 for entry in wildlife:
  var phase=t*0.7+entry.phase
  var flight_height=0.8+sin(phase*1.3)*.25
  if entry.kind in ["songbird","native bird"]: flight_height=2.8+sin(phase)*.5
  if entry.kind=="frog": flight_height=.10
  entry.node.position=entry.target+Vector3(cos(phase)*1.4,flight_height,sin(phase)*1.4)
  # All visitor models face local -Z; face the tangent, not away from it.
  var travel=Vector3(-sin(phase),0,cos(phase))
  entry.node.rotation.y=atan2(-travel.x,-travel.z)
  entry.node.visible=clock_time>0.7 or clock_time<0.2 if entry.kind=="firefly" else true
  for wing in entry.node.get_children():
   if str(wing.name).begins_with("Wing"): wing.rotation.z=sin(t*(35 if entry.kind=="bee" else 13)+entry.phase)*.8*float(wing.get_meta("side",1))
 for j in range(pets.size()): pets[j].animate(self,delta,j)
 for j in range(water_motes.size()):
  var mote=water_motes[j]
  mote.position.y+=sin(t+j)*delta*0.035
  mote.position.x+=cos(t*0.3+j)*delta*0.035
 for obj in objects:
  if obj.fish:
   for j in range(4):
    var fish=obj.node.get_node_or_null("Fish"+str(j))
    if fish:
     fish.position=Vector3(cos(t*0.4+j*1.7),0.09,sin(t*0.4+j*1.7))*Vector3(1,1,0.8)
     # Fish bodies run along local +X and swim an ellipse, not a circle.
     var angle=t*.4+j*1.7
     var travel=Vector3(-sin(angle),0,.8*cos(angle))
     fish.rotation.y=atan2(-travel.z,travel.x)

func update_lighting() -> void:
 var angle=(clock_time-.25)*TAU
 var sun_direction=Vector3(cos(angle)*.45,sin(angle),cos(angle)*.89).normalized()
 var daylight=clampf(smoothstep(-.12,.30,sun_direction.y),.025,1)
 var twilight=exp(-pow(sun_direction.y/.19,2))
 sun.light_energy=.025+daylight*.95
 sun.light_color=Color("ffae69").lerp(Color("ffedcd"),daylight)
 sun.quaternion=Quaternion(Vector3.FORWARD,-sun_direction)
 var horizon=Color("18213a").lerp(Color("bfd6cd"),daylight).lerp(Color("dd9467"),twilight*.45)
 environment.environment.background_color=horizon
 environment.environment.fog_light_color=horizon
 var sky_material=environment.environment.sky.sky_material
 sky_material.set_shader_parameter("daylight",daylight)
 sky_material.set_shader_parameter("sun_direction",sun_direction)
 sky_material.set_shader_parameter("day_phase",clock_time)
 sky_material.set_shader_parameter("sky_motion",float(day)+clock_time)
 sky_material.set_shader_parameter("twilight",twilight)
 environment.environment.ambient_light_color=Color("8196c5").lerp(Color("e4e7cc"),daylight)
 environment.environment.ambient_light_energy=.16+daylight*.38
 if is_instance_valid(ambient): ambient.daylight=daylight

func greet_pet() -> void:
 var nearest=0
 if player.position.distance_to(pets[1].position)<player.position.distance_to(pets[0].position): nearest=1
 if player.position.distance_to(pets[nearest].position)<4:
  toast(companion_names[nearest]+(" leans in with a happy purr." if nearest==0 else " wags a very enthusiastic hello."))
  care_effect(pets[nearest].position,Color("e9b6b6"))
 else: toast("Your companions will wander over in their own time.")

func toast(message: String) -> void:
 toast_label.text=message
 toast_time=4.5

func toggle_photo() -> void:
 photo_mode=not photo_mode
 if photo_mode: camera_target=camera.position
 for child in ui.get_children(): child.visible=not photo_mode
 photo_panel.visible=photo_mode
 toast_label.hide()
 grid_root.hide()
 grid_cursor.hide()
 if is_instance_valid(preview): preview.hide()
 player.hide()
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if photo_mode else Input.MOUSE_MODE_CAPTURED
 if not photo_mode:
  camera_target=player.position+Vector3(0,1.15,0)
  side_panel.hide()
 update_hud()

func capture_photo() -> void:
 var was_visible=ui.visible
 ui.hide()
 await RenderingServer.frame_post_draw
 var img=get_viewport().get_texture().get_image()
 var path="user://photos"
 DirAccess.make_dir_recursive_absolute(path)
 var file=path+"/zend-garden-"+Time.get_datetime_string_from_system().replace(":","-")+".png"
 img.save_png(file)
 ui.visible=was_visible
 toast("Photo saved in "+ProjectSettings.globalize_path(path))
 if photo_mode:
  photo_panel.get_child(0).get_child(0).text="Saved to user data / photos"

func save_game() -> void:
 var ps: Array=[]
 for p in planted: ps.append({"height_factor":p.height_factor,"id":p.id,"pos":[p.pos.x,p.pos.z],"plot":p.plot,"age":p.age,"water":p.water,"stress":p.stress,"pruned":p.get("pruned",0.0)})
 var os: Array=[]
 for obj in objects: os.append({"kind":obj.kind,"pos":[obj.pos.x,obj.pos.z],"price":obj.price,"fish":obj.fish,"rotation":obj.get("rotation",0.0),"text":obj.get("text","My garden"),"text_color":obj.get("text_color","f1e5c7")})
 var data={"settings":settings,"request_unread":request_unread,"rake_petals":rake_petals,"version":2,"climate":climate.save_state(),"plants":ps,"objects":os,"coins":coins,"day":day,"clock":clock_time,"unlocked_plants":unlocked_plants,"unlocked_plots":unlocked_plots,"inventory":inventory,"upgrades":upgrades,"automation":automation,"expansions":expansions,"orders":orders,"fulfilled":fulfilled,"planted_total":planted_total,"clean_paths":clean_paths,"path_widths":path_widths,"names":companion_names,"player":[player.position.x,player.position.z]}
 var file=FileAccess.open(SAVE_PATH+".tmp",FileAccess.WRITE)
 if file:
  file.store_string(JSON.stringify(data))
  file.close()
  DirAccess.rename_absolute(SAVE_PATH+".tmp",SAVE_PATH)

var loaded_data: Dictionary={}
func load_game() -> void:
 if smoke or not FileAccess.file_exists(SAVE_PATH): return
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
 if not parsed is Dictionary or int(parsed.get("version",0)) not in [1,2]: return
 if int(parsed.get("version",0))==1 and not FileAccess.file_exists(SAVE_PATH+".v1-backup"):
  var backup=FileAccess.open(SAVE_PATH+".v1-backup",FileAccess.WRITE)
  if backup:
   backup.store_string(JSON.stringify(parsed))
   backup.close()
 loaded_data=parsed
 settings.merge(parsed.get("settings",{}),true)
 request_unread=parsed.get("request_unread",false)
 rake_petals=int(parsed.get("rake_petals",0))
 coins=int(parsed.get("coins",80))
 day=int(parsed.get("day",1))
 clock_time=float(parsed.get("clock",0.26))
 unlocked_plants=parsed.get("unlocked_plants",STARTERS.duplicate())
 unlocked_plots=int(parsed.get("unlocked_plots",1))
 inventory=parsed.get("inventory",{})
 upgrades=parsed.get("upgrades",upgrades)
 automation=parsed.get("automation",{})
 expansions=parsed.get("expansions",{})
 orders=parsed.get("orders",[])
 fulfilled=int(parsed.get("fulfilled",0))
 planted_total=int(parsed.get("planted_total",0))
 clean_paths=parsed.get("clean_paths",[])
 path_widths=parsed.get("path_widths",{})
 companion_names=parsed.get("names",companion_names)

func restore_garden() -> void:
 for p in loaded_data.get("plants",[]):
  var age=Catalogue.saved_age(int(p.id),float(p.age),int(loaded_data.get("version",1)))
  var plant=add_plant(int(p.id),Vector3(p.pos[0],0,p.pos[1]),int(p.plot),age,float(p.get("height_factor",legacy_height_factor(p))))
  plant.water=float(p.water)
  plant.stress=float(p.stress)
  plant.pruned=float(p.get("pruned",0.0))
  refresh_plant(plant)
 for obj in loaded_data.get("objects",[]): add_object(obj.kind,Vector3(obj.pos[0],0,obj.pos[1]),int(obj.price),bool(obj.fish),float(obj.get("rotation",0.0)),str(obj.get("text","My garden")),Color.from_string(str(obj.get("text_color","f1e5c7")),Color("f1e5c7")))
 if loaded_data.has("player"): player.position=GardenTerrain.point(Vector3(loaded_data.player[0],0,loaded_data.player[1]))+Vector3(0,.1,0)
 for i in range(plot_signs.size()): Art.set_sign_text(plot_signs[i],plots[i].name.to_upper()+("\nOpens day "+str(GardenExpansion.opening_day(i)) if i>=unlocked_plots else ""))
 for key in automation:
  var index=int(key.trim_suffix("water").trim_suffix("prune"))
  var center: Vector3=plots[index].center
  if key.ends_with("water"):
   make_irrigation(center)
 for key in clean_paths:
  var xy=key.split(":")
  GardenGroundFinish.path(self,Vector3(float(xy[0]),0,float(xy[1])),float(path_widths.get(key,.95)))
 refresh_wildlife()

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST and not smoke: save_game()

func run_smoke_test() -> void:
 await get_tree().create_timer(2.0).timeout
 var failures: Array=[]
 if catalogue.size()<50: failures.append("Plant catalogue below 50")
 var pos=GardenTerrain.point(Vector3(3*1.15,0,3*1.15))
 var initial=planted.size()
 for id in [12,0,20,29]:
  var error=can_plant(id,pos,0)
  if not error.is_empty(): failures.append("Layer placement: "+error)
  else: add_plant(id,pos,0)
 if planted.size()!=initial+4: failures.append("Four layers did not coexist")
 if can_plant(12,pos,0).is_empty(): failures.append("Duplicate layer accepted")
 expansions["0"]=-3
 if can_plant(0,Vector3(-3*GRID,0,3*GRID),0).is_empty(): failures.append("Capacity not enforced")
 expansions.erase("0")
 var p=planted.back()
 p.water=0.0
 automation["0water"]=true
 automation["0prune"]=true
 var before=p.age
 next_day()
 while day_transition: await get_tree().process_frame
 if p.age<=before: failures.append("Automated growth failed")
 day=6
 next_day()
 while day_transition: await get_tree().process_frame
 if unlocked_plots<2: failures.append("Free plot progression failed")
 inventory["0"]=2
 var old_coins=coins
 fulfill_order(0)
 if coins<=old_coins: failures.append("Order reward failed")
 add_object("greenhouse",pos,120)
 if growth_conditions(p)!=1.0: failures.append("Greenhouse protection failed")
 add_object("pond",Vector3(4.8,0,3),75,true)
 if not objects.back().node.has_node("Fish0"): failures.append("Fish failed")
 # Exercise tools through the same action dispatcher used by mouse clicks.
 hover_valid=true
 hover_plot=0
 hover_cell=GardenTerrain.point(Vector3(-3*1.15,0,3*1.15))
 selected=0
 set_mode("plant")
 action_cooldown=0
 var n_before=planted.size()
 perform_action()
 if planted.size()!=n_before+1: failures.append("Plant action failed")
 selected_layer=1
 set_mode("water")
 action_cooldown=0
 perform_action()
 var fresh=planted.back()
 if fresh.water<=0: failures.append("Water action failed")
 fresh.stress=0.8
 set_mode("prune")
 action_cooldown=0
 perform_action()
 if fresh.stress>=0.8: failures.append("Prune action failed")
 set_mode("move")
 action_cooldown=0
 perform_action()
 hover_cell=GardenTerrain.point(Vector3(-3*1.15,0,2*1.15))
 perform_action()
 if fresh.marker.position.distance_to(hover_cell)>.01: failures.append("Seed marker did not move with plant")
 if fresh.pos.distance_to(hover_cell)>0.01: failures.append("Move action failed")
 set_mode("remove")
 perform_action()
 if planted.size()!=n_before: failures.append("Lift action failed")
 if not fresh.marker.is_queued_for_deletion(): failures.append("Lift left a seed marker behind")
 if accessible(Vector3(8.5,0,0)): failures.append("Water crossing allowed outside bridge")
 if not accessible(Vector3(8.5,0,5.9)): failures.append("Bridge blocked")
 if snap_to_bed(Vector3(0.15,0,0.15),0)!=GardenTerrain.point(Vector3.ZERO): failures.append("Grid snapping failed")
 await preload("res://tests/signs.gd").run(self,failures)
 # Persist and reconstruct live models, with a separate smoke-test save.
 save_game()
 var saved_heights=planted.map(func(p): return p.height_factor)
 var saved_count=planted.size()
 var saved_coins=coins
 for item in planted: item.node.queue_free(); item.marker.queue_free()
 for item in objects: item.node.queue_free()
 planted.clear()
 objects.clear()
 coins=0
 smoke=false
 load_game()
 smoke=true
 restore_garden()
 var restored_sign=objects.filter(func(obj): return obj.kind=="sign")
 if restored_sign.is_empty():
  failures.append("Sign missing after reload")
 else:
  var sign_obj=restored_sign[0]
  if sign_obj.text!="Herbs & flowers" or sign_obj.text_color!="ffe6a0" or not is_equal_approx(sign_obj.rotation,1.25): failures.append("Saved sign lost its lettering, colour or rotation")
  if sign_obj.node.get_node("FrontText").text!=sign_obj.text: failures.append("Restored sign model has incorrect lettering")
 if planted.size()!=saved_count or coins!=saved_coins: failures.append("Save/reload round trip failed")
 for i in range(mini(saved_heights.size(),planted.size())):
  if not is_equal_approx(float(saved_heights[i]),float(planted[i].height_factor)): failures.append("Plant height changed after save/reload")
 dismiss_request() # Walking HUD check starts after acknowledging any simulated deliveries.
 set_mode("walk")
 player.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.1,0)
 yaw=0
 pitch=0.04
 clock_time=0.40
 distance=7.5
 camera_target=player.position+Vector3(0,1.15,0)
 toast_time=0
 refresh_ui()
 await get_tree().create_timer(1.5).timeout
 print("RENDER_METRICS: fps=",Engine.get_frames_per_second()," primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
 get_viewport().get_texture().get_image().save_png("res://captures/smoke-test.png")
 if tool_models.size()!=4: failures.append("Missing held tool models")
 update_hud()
 if hud_top.visible or hud_tools.visible or hud_capacity.visible: failures.append("Walking HUD should be unobtrusive")
 set_mode("water")
 pitch=.28
 update_camera(0)
 update_hover()
 update_hud()
 if not tool_models.has("can") or not tool_models["can"].visible: failures.append("Watering can is not visible")
 await get_tree().create_timer(.4).timeout
 get_viewport().get_texture().get_image().save_png("res://captures/first-person-watering.png")
 set_mode("walk")
 # Exercise first-person aiming and cursor switching using the player input path.
 set_mode("plant")
 side_panel.hide()
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 yaw=0
 pitch=atan2(player.position.y+1.62-GardenTerrain.point(Vector3.ZERO).y,player.position.z)
 update_camera(0)
 update_hover()
 if not hover_valid or hover_cell.distance_to(GardenTerrain.point(Vector3.ZERO))>.1: failures.append("Crosshair planting ray failed")
 pitch=-.4
 update_camera(0)
 update_hover()
 if hover_valid: failures.append("Upward aim incorrectly targets the ground")
 var tab_event=InputEventKey.new()
 tab_event.pressed=true
 tab_event.physical_keycode=KEY_TAB
 _unhandled_input(tab_event)
 if Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE or not side_panel.visible: failures.append("Tab did not release menus")
 _unhandled_input(tab_event)
 if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED or side_panel.visible: failures.append("Tab did not resume mouse look")
 set_mode("walk")
 pitch=.04
 update_camera(0)
 # Camera validation: exact eye position, full vertical look and saved gardening compatibility.
 if camera.position.distance_to(player.position+Vector3(0,1.62,0))>.02: failures.append("Camera is not first person")
 if player.visible: failures.append("First-person body obstructs the camera")
 for id in range(60):
  if not ResourceLoader.exists("res://assets/plants/plant_%02d.glb" % id): failures.append("Missing Blender plant "+str(id))
 player.position=GardenTerrain.point(Vector3(0,0,-23))+Vector3(0,.1,0)
 pitch=.28
 yaw=0
 clock_time=.42
 ui.hide()
 await get_tree().create_timer(.6).timeout
 get_viewport().get_texture().get_image().save_png("res://captures/lake-lookout.png")
 ui.show()
 player.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.1,0)
 pitch=.04
 clock_time=0.84
 toggle_photo()
 await get_tree().create_timer(0.5).timeout
 get_viewport().get_texture().get_image().save_png("res://captures/night-garden.png")
 toggle_photo()
 await preload("res://tests/plant_height.gd").run(self,failures)
 await preload("res://tests/plant_density.gd").run(self,failures)
 await preload("res://tests/ecology.gd").run(self,failures)
 await preload("res://tests/ui_update.gd").run(self,failures)
 await preload("res://tests/shoreline.gd").run(self,failures)
 await preload("res://tests/experience.gd").run(self,failures)
 await preload("res://tests/walking.gd").run(self,failures)
 await preload("res://tests/ground_finish.gd").run(self,failures)
 await preload("res://tests/pruning.gd").run(self,failures)
 print("ZEND_GARDEN_TEST_RESULT: ","PASS" if failures.is_empty() else failures)
 get_tree().quit(0 if failures.is_empty() else 1)


func animate_tool_action() -> void:
 if not is_instance_valid(held_tool): return
 if tool_tween and tool_tween.is_running(): tool_tween.kill()
 held_tool.rotation=Vector3.ZERO
 tool_tween=create_tween()
 var tilt=Vector3(0,0,-.40) if mode=="water" else Vector3(-.32,.10,-.12)
 tool_tween.tween_property(held_tool,"rotation",tilt,.14).set_trans(Tween.TRANS_SINE)
 tool_tween.tween_property(held_tool,"rotation",Vector3.ZERO,.30).set_trans(Tween.TRANS_SINE)

func run_walk_test() -> void:
 await get_tree().create_timer(2).timeout
 var failures=[]
 await preload("res://tests/walking.gd").run(self,failures)
 print("WALK_RESULT: ",failures)
 get_tree().quit(0 if failures.is_empty() else 1)

func run_experience_test() -> void:
 await get_tree().create_timer(2).timeout
 var failures=[]
 await preload("res://tests/experience.gd").run(self,failures)
 print("EXPERIENCE_RESULT: ",failures)
 get_tree().quit(0 if failures.is_empty() else 1)

func run_ground_test() -> void:
 await get_tree().create_timer(2).timeout
 var failures=[]
 await preload("res://tests/ground_finish.gd").run(self,failures)
 print("GROUND_RESULT: ",failures)
 get_tree().quit(0 if failures.is_empty() else 1)

func backup_for_restart() -> String:
 save_game()
 var backup=SAVE_PATH+".before-restart-"+str(Time.get_unix_time_from_system())+".json"
 if DirAccess.rename_absolute(SAVE_PATH,backup)!=OK: return ""
 return backup

func restart_garden() -> void:
 if backup_for_restart().is_empty():
  toast("Could not back up the garden. Restart cancelled.")
  return
 set_process(false)
 get_tree().reload_current_scene()
