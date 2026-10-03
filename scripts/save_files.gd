class_name GardenSaveFiles
extends Node

# Scene reloads keep the verified browser mount. Only the initial mount should
# be compared with the loader's fingerprint, before any legitimate game writes.
static var browser_mount_verified=false
static var arrival_notice=""
var g
var busy=false
var was_processing=false
var picker: FileDialog
var callback: JavaScriptObject
var pending_bytes=PackedByteArray()
var confirmation: PanelContainer

func setup(game) -> void:
 g=game

func backup_path() -> String:
 return g.SAVE_PATH+".before-upload.json"

func filename() -> String:
 return "zend-garden-day-%d-%s.json" % [g.day,Time.get_datetime_string_from_system().replace(":","-")]

static func write_atomic(path: String, bytes: PackedByteArray) -> bool:
 var temporary=path+".tmp"
 var file=FileAccess.open(temporary,FileAccess.WRITE)
 if not file:return false
 file.store_buffer(bytes)
 file.flush()
 var success=file.get_error()==OK
 file.close()
 if success:success=FileAccess.get_file_as_bytes(temporary)==bytes
 if success:success=DirAccess.rename_absolute(temporary,path)==OK
 if not success:DirAccess.remove_absolute(temporary)
 return success

func begin() -> bool:
 if busy or is_instance_valid(g.welcome):return false
 busy=true
 was_processing=g.is_processing()
 g.set_process(false)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 return true

func finish() -> void:
 pending_bytes=PackedByteArray()
 if is_instance_valid(picker):picker.queue_free()
 picker=null
 if is_instance_valid(confirmation):
  confirmation.queue_free()
  g.welcome=null
  if is_instance_valid(g.welcome_backdrop):g.welcome_backdrop.queue_free()
  g.welcome_backdrop=null
 confirmation=null
 if busy:g.set_process(was_processing)
 busy=false

func download(previous: bool=false) -> void:
 if busy:return
 if not previous and not g.save_game():
  g.toast("Could not save your garden. Please try again before downloading.")
  return
 var path=backup_path() if previous else g.SAVE_PATH
 var bytes=FileAccess.get_file_as_bytes(path)
 if bytes.is_empty():
  g.toast("There is no readable garden copy to download.")
  return
 var name="zend-garden-before-upload.json" if previous else filename()
 if OS.has_feature("web"):
  JavaScriptBridge.download_buffer(bytes,name,"application/json")
  g.toast("Garden copy ready to download.")
 elif begin():
  pending_bytes=bytes
  show_picker(FileDialog.FILE_MODE_SAVE_FILE,name)
  picker.file_selected.connect(save_download)

func show_picker(mode: FileDialog.FileMode, name: String="") -> void:
 picker=FileDialog.new()
 picker.title="Save a garden copy" if mode==FileDialog.FILE_MODE_SAVE_FILE else "Choose a garden save"
 picker.access=FileDialog.ACCESS_FILESYSTEM
 picker.file_mode=mode
 picker.use_native_dialog=true
 picker.filters=PackedStringArray(["*.json ; Garden save files"])
 picker.current_file=name
 picker.canceled.connect(finish)
 add_child(picker)
 picker.popup_centered(Vector2i(700,500))

func save_download(path: String) -> void:
 var protected_paths=[ProjectSettings.globalize_path(g.SAVE_PATH),ProjectSettings.globalize_path(backup_path())]
 var success=path not in protected_paths and write_atomic(path,pending_bytes)
 finish()
 g.toast("Garden copy saved." if success else "Could not save the copy there. Choose another file location.")

func upload() -> void:
 if not begin():return
 if OS.has_feature("web"):
  var bridge=JavaScriptBridge.get_interface("window").ZendSaveFiles
  if bridge==null:
   finish()
   g.toast("The file picker could not open. Reload the page and try again.")
   return
  callback=JavaScriptBridge.create_callback(browser_selected)
  bridge.choose(callback)
 else:
  show_picker(FileDialog.FILE_MODE_OPEN_FILE)
  picker.file_selected.connect(read_upload)

func browser_selected(arguments: Array) -> void:
 # Leave the JavaScript callback before potentially replacing the scene.
 call_deferred("receive_upload",str(arguments[0]),str(arguments[1]),str(arguments[2]))

func receive_upload(text: String, name: String, error: String) -> void:
 if not busy:return
 if not error.is_empty():
  finish()
  if error!="cancelled":g.toast(error)
  return
 preview(text.to_utf8_buffer(),name)

func read_upload(path: String) -> void:
 var file=FileAccess.open(path,FileAccess.READ)
 if not file or file.get_length()>GardenSaveFormat.MAX_BYTES:
  finish()
  g.toast("Choose a readable garden JSON file smaller than 4 MB.")
  return
 var bytes=file.get_buffer(file.get_length())
 file.close()
 preview(bytes,path.get_file())

func preview(bytes: PackedByteArray, name: String) -> bool:
 var result=GardenSaveFormat.read(bytes,g.catalogue.size(),g.furniture.map(func(item):return item.kind))
 if result.has("error"):
  finish()
  g.toast(result.error)
  return false
 pending_bytes=bytes
 if is_instance_valid(picker):picker.queue_free()
 picker=null
 g.welcome_backdrop=ColorRect.new()
 g.welcome_backdrop.color=Color(.07,.12,.09,.65)
 g.welcome_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 g.welcome_backdrop.z_index=29
 g.ui.add_child(g.welcome_backdrop)
 var width=minf(420,g.get_viewport().get_visible_rect().size.x-32)
 confirmation=g.panel_at(Vector2.ZERO,Vector2(width,0))
 confirmation.custom_minimum_size.x=width
 confirmation.z_index=30
 g.welcome=confirmation
 var col=VBoxContainer.new()
 col.add_theme_constant_override("separation",14)
 confirmation.add_child(col)
 var title=g.label("Open this garden copy?",22)
 title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 title.custom_minimum_size.x=width-28
 col.add_child(title)
 var note=g.label("%s\nDay %d · %d plants\n\nThis replaces the garden on this device. A copy of your current garden will be kept; download it from Settings if you want to return to it." % [name.left(100),int(result.data.get("day",1)),result.data.plants.size()],17)
 note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 note.custom_minimum_size.x=width-28
 col.add_child(note)
 col.add_child(g.button("Keep my current garden",finish))
 col.add_child(g.button("Back up & open this save",apply_upload))
 fit_confirmation()
 return true

func fit_confirmation() -> void:
 if not is_instance_valid(confirmation):return
 # Wrapped labels can briefly grow before their first container layout, most
 # noticeably in the browser. Shrink back to the content before fitting.
 confirmation.size=confirmation.get_combined_minimum_size()
 if g.touch_active():g.touch.fit_popup(confirmation)
 else:GardenInterface.fit_popup(g,confirmation)

func _process(_delta: float) -> void:
 fit_confirmation()

func _unhandled_input(event: InputEvent) -> void:
 if is_instance_valid(confirmation) and event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE:
  finish()
  get_viewport().set_input_as_handled()

# Install without touching live state until both the old copy and new file are
# safely written. Keeping this separate also lets tests verify failure recovery.
func install_upload() -> bool:
 if pending_bytes.is_empty():return false
 if GardenSaveFormat.read(pending_bytes,g.catalogue.size(),g.furniture.map(func(item):return item.kind)).has("error"):return false
 if not g.save_game():
  g.toast("Could not save your current garden. Upload cancelled.")
  return false
 var original=FileAccess.get_file_as_bytes(g.SAVE_PATH)
 if original.is_empty() or not write_atomic(backup_path(),original):
  g.toast("Could not back up your current garden. Upload cancelled.")
  return false
 if not write_atomic(g.SAVE_PATH,pending_bytes):
  g.toast("Could not open that copy. Your current garden is unchanged.")
  return false
 return true

func apply_upload() -> void:
 if not install_upload():
  finish()
  return
 arrival_notice="Garden copy opened. Your previous garden is available in Settings."
 var tree=g.get_tree()
 var error=tree.reload_current_scene()
 if error!=OK:
  write_atomic(g.SAVE_PATH,FileAccess.get_file_as_bytes(backup_path()))
  arrival_notice=""
  finish()
  g.toast("Could not reopen the garden. Your previous save has been restored.")

func _exit_tree() -> void:
 if OS.has_feature("web") and callback!=null:
  var bridge=JavaScriptBridge.get_interface("window").ZendSaveFiles
  if bridge!=null:bridge.cancel()
