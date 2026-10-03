extends RefCounted

static func run(g, failures: Array) -> void:
 g.open_sidebar("Settings")
 for text in ["Download save file","Upload save file…"]:
  if not g.list_box.get_children().any(func(control):return control is Button and control.text==text):failures.append("Save Settings button missing: "+text)
 var was_processing=g.is_processing()
 var original_dimensions=g.get_viewport().size
 var controls=g.settings.controls
 var path=g.SAVE_PATH
 g.SAVE_PATH="user://save-file-ui-test.json"
 g.save_game()
 var bytes=FileAccess.get_file_as_bytes(g.SAVE_PATH)
 if GardenSaveFormat.read(bytes,g.catalogue.size(),g.furniture.map(func(item):return item.kind)).has("error"):failures.append("Actual garden snapshot rejected")
 for size in [Vector2i(1280,800),Vector2i(390,844),Vector2i(667,375),Vector2i(320,568)]:
  g.get_viewport().size=size
  g.settings.controls="touch" if size.x<700 else "keyboard"
  g.touch.configure()
  if not g.save_files.begin() or not g.save_files.preview(bytes,"my-garden-copy.json"):failures.append("Upload preview failed")
  await g.get_tree().process_frame
  await g.get_tree().process_frame
  g.save_files.fit_confirmation()
  var rect=g.welcome.get_global_rect()
  var viewport=g.get_viewport().get_visible_rect()
  if rect.position.x<0 or rect.position.y<0 or rect.end.x>viewport.end.x+1 or rect.end.y>viewport.end.y+1:failures.append("Save confirmation clipped at "+str(size))
  if g.is_processing():failures.append("Garden kept progressing during upload confirmation")
  if size==Vector2i(390,844):g.get_viewport().get_texture().get_image().save_png("res://captures/save-upload-confirmation.png")
  g.save_files.finish()
  await g.get_tree().process_frame
  if is_instance_valid(g.welcome) or g.is_processing()!=was_processing:failures.append("Cancel did not restore garden")
  if FileAccess.get_file_as_bytes(g.SAVE_PATH)!=bytes:failures.append("Cancel changed save bytes")
 g.settings.controls=controls
 g.touch.configure()
 g.get_viewport().size=original_dimensions
 DirAccess.remove_absolute(g.SAVE_PATH)
 g.SAVE_PATH=path
