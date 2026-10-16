class_name GardenModes
extends RefCounted

const REGISTRY="user://garden-slots.json"
const PATHS={"free":"user://garden_v1.json","challenge":"user://challenge-garden.json"}
static var requested=""

static func select_start(g) -> void:
 if g.smoke:return
 var selection=requested
 if selection.is_empty() and FileAccess.file_exists(REGISTRY):
  var registry=JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
  if registry is Dictionary:selection=str(registry.get("last","free"))
 if selection not in PATHS:selection="free"
 g.garden_mode=selection
 g.SAVE_PATH=PATHS[selection]

static func switch_to(g,selection: String) -> void:
 if selection not in PATHS or selection==g.garden_mode:return
 if not g.save_game():g.toast("Could not save this garden. Please try again before switching.");return
 var previous=g.garden_mode
 if not GardenSaveFiles.write_atomic(REGISTRY,JSON.stringify({"last":selection}).to_utf8_buffer()):
  g.toast("Could not remember the garden selection.");return
 requested=selection
 var error=g.get_tree().reload_current_scene()
 if error!=OK:
  requested=previous
  GardenSaveFiles.write_atomic(REGISTRY,JSON.stringify({"last":previous}).to_utf8_buffer())
  g.toast("Could not switch gardens. Your saved gardens are safe.")

static func slot_description(selection: String) -> String:
 var path=PATHS[selection]
 if not FileAccess.file_exists(path):return "Start a new garden"
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary:return "Saved garden needs recovery — download a backup first"
 return "Continue · day %d · %s"%[int(data.get("day",1)),GardenClimate.season(int(data.get("day",1)))]

static func page(g) -> void:
 g.side_title.text="Your gardens"
 g.add_note("Keep a peaceful Free Garden alongside a separate Challenge Garden. Each has its own plants, supplies and save file.",15)
 for selection in ["free","challenge"]:
  var chosen=selection
  var title="Free Garden" if selection=="free" else "Challenge Garden"
  g.add_note(title,19)
  g.add_note("The familiar relaxed garden, with no deadlines." if selection=="free" else "Water, weed and mulch your planting. Build irrigation and deliver seasonal baskets. Neglected plants recover, and time stops while away.")
  var action=g.button("You are here" if g.garden_mode==selection else slot_description(selection),func():switch_to(g,chosen))
  action.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  action.name="GardenSlot_"+selection
  action.disabled=g.garden_mode==selection
  g.list_box.add_child(action)
 g.list_box.add_child(g.button("Back to guide",func():GardenMenus.visit(g,"Guide")))

static func recovery(g) -> void:
 g.ui=CanvasLayer.new();g.add_child(g.ui)
 g.menu_theme=GardenTheme.make()
 var panel=g.panel_at(Vector2(24,24),Vector2(340,0))
 var column=VBoxContainer.new();panel.add_child(column)
 var note=g.label("This saved garden needs recovery. Its file has been preserved. You can keep a copy and return to Free Garden.",18)
 note.custom_minimum_size.x=300;note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(note)
 column.add_child(g.button("Keep a copy of the preserved save",func():
  if OS.has_feature("web"):JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(g.SAVE_PATH),"preserved-challenge-garden.json","application/json")
  else:OS.shell_show_in_file_manager(ProjectSettings.globalize_path(g.SAVE_PATH))))
 column.add_child(g.button("Open Free Garden",func():
  if not GardenSaveFiles.write_atomic(REGISTRY,JSON.stringify({"last":"free"}).to_utf8_buffer()):return
  requested="free"
  g.get_tree().reload_current_scene()))
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
