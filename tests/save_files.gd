extends SceneTree

class TestGarden extends Node:
 var SAVE_PATH="user://save-transfer-test.json"
 var catalogue=GardenCatalogue.plants()
 var furniture=GardenCatalogue.furnishings()
 var original: PackedByteArray
 var notices: Array=[]
 var save_ok=true
 func save_game() -> bool:
  return save_ok and GardenSaveFiles.write_atomic(SAVE_PATH,original)
 func toast(message: String) -> void:
  notices.append(message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var failures: Array=[]
 var game=TestGarden.new()
 root.add_child(game)
 var files=GardenSaveFiles.new()
 game.add_child(files)
 files.setup(game)
 var kinds=game.furniture.map(func(item):return item.kind)
 var count=game.catalogue.size()
 var original={"version":2,"day":17,"coins":231,"plants":[{"id":147,"plot":0,"pos":[1,-2],"age":3,"water":2,"stress":0}],"bed_surfaces":{"0":"sand"},"owned_surfaces":["soil","sand"],"settings":{"intro_seen":true,"updates_seen":32},"custom_extension":{"keep":"all bytes"}}
 game.original=JSON.stringify(original).to_utf8_buffer()
 if not GardenSaveFiles.write_atomic(game.SAVE_PATH,game.original):failures.append("Fixture write failed")
 for version in [1,2,3]:
  var data=original.duplicate(true)
  data.version=version
  if GardenSaveFormat.read(JSON.stringify(data).to_utf8_buffer(),count,kinds).has("error"):failures.append("Valid v%d save rejected"%version)
 var malformed=[{},[],{"version":4,"plants":[]},{"version":2,"plants":[],"settings":{"music_volume":"loud"}},{"version":2,"plants":[],"unlocked_plots":99999999},{"version":2,"plants":[],"climate":{"values":[0]}},{"version":2,"plants":[],"tutorial":{"pos":false}},{"version":2,"plants":[],"automation":{"9999water":true}},{"version":2,"plants":[],"objects":[{"kind":"missing","pos":[0,0],"price":0,"fish":false}]},{"version":2,"plants":[],"upgrades":{"can":-1}}]
 for field in ["id","plot","pos","age","water","stress"]:
  var data=original.duplicate(true)
  data.plants[0][field]="bad"
  malformed.append(data)
 var unknown=original.duplicate(true)
 unknown.plants[0].id=count
 malformed.append(unknown)
 for data in malformed:
  files.pending_bytes=JSON.stringify(data).to_utf8_buffer()
  if files.install_upload():failures.append("Invalid file installed: "+str(data))
  if FileAccess.get_file_as_bytes(game.SAVE_PATH)!=game.original:failures.append("Rejected file changed current save")
 var oversized=PackedByteArray()
 oversized.resize(GardenSaveFormat.MAX_BYTES+1)
 if not GardenSaveFormat.read(oversized,count,kinds).has("error"):failures.append("Oversized file accepted")
 if not GardenSaveFormat.read("{broken".to_utf8_buffer(),count,kinds).has("error"):failures.append("Broken JSON accepted")
 var incoming=original.duplicate(true)
 incoming.day=29
 incoming.coins=419
 files.pending_bytes=JSON.stringify(incoming," ").to_utf8_buffer()
 var exact_bytes=files.pending_bytes.duplicate()
 game.save_ok=false
 if files.install_upload() or FileAccess.get_file_as_bytes(game.SAVE_PATH)!=game.original:failures.append("Failed current save replaced garden")
 game.save_ok=true
 DirAccess.make_dir_recursive_absolute(files.backup_path()+".tmp")
 if files.install_upload() or FileAccess.get_file_as_bytes(game.SAVE_PATH)!=game.original:failures.append("Failed backup replaced garden")
 DirAccess.remove_absolute(files.backup_path()+".tmp")
 DirAccess.make_dir_recursive_absolute(game.SAVE_PATH+".tmp")
 if files.install_upload() or FileAccess.get_file_as_bytes(game.SAVE_PATH)!=game.original:failures.append("Failed active write changed save")
 DirAccess.remove_absolute(game.SAVE_PATH+".tmp")
 if not files.install_upload():failures.append("Valid file not installed")
 if FileAccess.get_file_as_bytes(game.SAVE_PATH)!=exact_bytes:failures.append("Uploaded bytes were changed")
 if FileAccess.get_file_as_bytes(files.backup_path())!=game.original:failures.append("Previous garden backup lost bytes")
 for path in [game.SAVE_PATH,files.backup_path()]:DirAccess.remove_absolute(path)
 game.queue_free()
 await process_frame
 print("SAVE_FILES_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
