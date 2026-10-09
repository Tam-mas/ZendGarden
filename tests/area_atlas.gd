extends SceneTree

# Exercise real atlas buttons and layout without loading the full 3D garden.
class AtlasGarden extends Node:
 var welcome: Control
 var welcome_backdrop: Control
 var touch: Control
 var ui=Control.new()
 var side_panel=Control.new()
 var player=CharacterBody3D.new()
 var area_atlas_open=false
 var area_atlas_index=-1
 var area_atlas_return=false
 var area_notice=""
 var areas_state=GardenAreas.initial_state()
 var area_roots=[]
 var catalogue=GardenCatalogue.plants()
 var planted=[]
 var plant_index=GardenPlantIndex.new()
 var objects=[]
 var inventory={}
 var orders=[]
 var day=100
 var fulfilled=8
 var planted_total=2000
 var coins=100
 var clock_time=.8
 var photo_mode=false
 var rest_kind=""
 var yaw=0.0
 var pitch=0.0
 var current_plot=0
 var saves=0
 func _ready() -> void:
  add_child(ui);add_child(side_panel);add_child(player);side_panel.hide()
 func label(value: String,size: int) -> Label:
  var result=Label.new();result.text=value;result.add_theme_font_size_override("font_size",size);return result
 func button(value: String,callback: Callable,size: Vector2) -> Button:
  var result=Button.new();result.text=value;result.custom_minimum_size=size;result.pressed.connect(callback);return result
 func panel_at(pos: Vector2,size: Vector2) -> PanelContainer:
  var result=PanelContainer.new();result.position=pos;result.size=size;ui.add_child(result);return result
 func refresh_ui() -> void:pass
 func refresh_wildlife() -> void:pass
 func save_game() -> void:saves+=1
 func resume_controls() -> void:pass
 func dismiss_request() -> void:pass
 func set_mode(_mode: String,_notify: bool=false) -> void:pass
 func toggle_photo() -> void:photo_mode=not photo_mode
 func toast(value: String) -> void:area_notice=value

var failures=[]
var garden: AtlasGarden

func _initialize() -> void:call_deferred("run")

func check(value: bool,message: String) -> void:
 if not value:failures.append(message)

func labels(node: Node) -> String:
 var value=node.text+"\n" if node is Label or node is Button else ""
 for child in node.get_children():value+=labels(child)
 return value

func button(value: String) -> Button:
 for control in garden.welcome.find_children("*","Button",true,false):
  if control.text==value:return control
 return null

func settle() -> void:
 for frame in range(3):await process_frame

func run() -> void:
 garden=AtlasGarden.new();root.add_child(garden)
 root.size=Vector2i(390,844)
 for index in range(10):GardenAreas.state(garden,index).initialized=true
 for index in range(10):
  GardenAreaAtlas.open(garden,index);await settle()
  check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(garden.welcome.get_rect()),"Atlas exceeds phone viewport: %d"%index)
  check(GardenAreaCatalogue.entry(index+1 if index%2==0 else index-1).name in labels(garden.welcome),"Missing neighbouring garden: %d"%index)
 # Reading a garden from the overview must not save or rebuild its plants.
 GardenAreaAtlas.open(garden);await settle()
 var before=garden.saves
 button("Moon Garden · Unlocked").pressed.emit();await settle()
 check(garden.area_atlas_index==9 and garden.saves==before,"Read-only atlas navigation saves the garden")
 # A care action deep in a collection keeps the reader's place and its notice.
 var moon=GardenAreas.state(garden,9)
 for slot in range(6):moon.beds[str(slot)]={"species":"primrose","age":1000.0,"water":1.0,"offset_day":0}
 GardenAreaAtlas.open(garden,9);await settle()
 var scroll=garden.welcome.find_child("AtlasScroll",true,false)
 scroll.scroll_vertical=650;await settle()
 var position=scroll.scroll_vertical
 check(position>0,"Atlas test has no scrolling content")
 button("Water pocket 5").pressed.emit();await settle()
 scroll=garden.welcome.find_child("AtlasScroll",true,false)
 check(moon.beds["4"].water==4.0 and garden.saves==before+1,"Collection care did not update and save exactly once")
 check(scroll.scroll_vertical==position,"Collection care jumps back to the top of the atlas")
 check("100% grown" in labels(garden.welcome) and "1000% grown" not in labels(garden.welcome),"Mature collection growth exceeds 100%")
 check("A drink for pocket 5." in labels(garden.welcome.get_child(0)) and "A drink for pocket 5." not in labels(scroll),"Activity result is hidden inside the long scroller")
 button("All ten garden trails").pressed.emit();await settle()
 check(garden.area_notice.is_empty() and garden.saves==before+1,"Returning to all trails retains an old activity notice or saves again")
 # Recipe availability must use spare inventory, respecting neighbour orders.
 GardenAreaAtlas.open(garden,5);await settle()
 check(button("Prepare Summer salad basket").disabled,"Empty inventory offers a kitchen basket")
 garden.inventory={"48":1,"47":1,"56":1}
 garden.orders=[{"plant":48,"count":1,"pending":false}]
 GardenAreaAtlas.open(garden,5);await settle()
 check(button("Prepare Summer salad basket").disabled,"Reserved neighbour produce offers a basket")
 garden.orders=[];GardenAreaAtlas.open(garden,5);await settle()
 check(not button("Prepare Summer salad basket").disabled,"Available kitchen ingredients remain disabled")
 GardenAreaAtlas.open(garden,4);await settle()
 check(button("Prepare orchard basket").disabled,"Empty fruit inventory offers an orchard basket")
 for id in GardenPlantGrowth.FRUIT_TREES.slice(0,3):garden.inventory[str(id)]=1
 GardenAreaAtlas.open(garden,4);await settle()
 check(not button("Prepare orchard basket").disabled,"Three spare fruit varieties do not enable the orchard basket")
 # An ordinary plant in a glasshouse pot needs its regular tools, not a dead button.
 var pot=Node3D.new();garden.add_child(pot);pot.position=GardenAreaCatalogue.center(6)
 garden.objects=[{"uid":"atlas-pot","kind":"pot","area_fixture":"glasshouse:pot0","node":pot}]
 garden.planted=[{"id":0,"plot":10,"age":0.0,"container_uid":"atlas-pot","container_slot":0}]
 GardenAreas.state(garden,6).restored=[true,true,true]
 GardenAreaAtlas.open(garden,6);await settle()
 check(button("Plant pocket 1")==null and "growing an ordinary plant" in labels(garden.welcome),"Occupied glasshouse pot offers a failing collection action")
 # Repeated bay controls retain the actual focused bay for keyboard use.
 var vents=GardenAreaAtlas.matching_buttons(garden.welcome,"Open roof vent")
 vents[1].grab_focus();vents[1].pressed.emit();await settle()
 var focused=root.gui_get_focus_owner()
 check(focused==GardenAreaAtlas.matching_buttons(garden.welcome,"Open roof vent")[1] and focused.text.ends_with("Off"),"Keyboard focus leaves the selected glasshouse bay")
 # Selecting a distant photograph must arrive in the actual Moon Garden.
 garden.player.position=Vector3.ZERO;GardenAreaAtlas.open(garden,9);await settle()
 button("Compose a night photograph").pressed.emit();await settle()
 check(garden.photo_mode and GardenAreaCatalogue.index_at(garden.player.position)==9 and not garden.area_atlas_open,"Moon photograph opens outside its garden")
 garden.queue_free();await process_frame
 print("AREA_ATLAS_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
