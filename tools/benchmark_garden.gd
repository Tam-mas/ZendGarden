extends SceneTree

# Load a disposable copy, never the player's active garden or the supplied file.
# godot --path . --rendering-method gl_compatibility --script tools/benchmark_garden.gd -- --garden-save=/absolute/save.json --report=/tmp/report.json
var garden

func _initialize() -> void:
 call_deferred("run")

func argument(name: String, fallback: String="") -> String:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with(name+"="): return arg.substr(name.length()+1)
 return fallback

func run() -> void:
 var source=argument("--garden-save")
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(source))
 if not parsed is Dictionary:
  push_error("Supply a valid --garden-save JSON file")
  quit(1)
  return
 parsed.settings.intro_seen=true
 parsed.settings.updates_seen=999999
 parsed.settings.pause_menus=false
 var disposable=OS.get_cache_dir().path_join("zend-garden-benchmark.json")
 var copy=FileAccess.open(disposable,FileAccess.WRITE)
 copy.store_string(JSON.stringify(parsed))
 copy.close()
 var started=Time.get_ticks_usec()
 garden=load("res://scripts/garden.gd").new()
 garden.SAVE_PATH=disposable
 root.add_child(garden)
 DisplayServer.window_set_size(Vector2i(1280,800))
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 var load_ms=(Time.get_ticks_usec()-started)/1000.0
 if argument("--shadows")=="off":garden.sun.shadow_enabled=false
 if argument("--msaa")=="off":root.msaa_3d=Viewport.MSAA_DISABLED
 if not argument("--lod").is_empty():root.mesh_lod_threshold=float(argument("--lod"))
 var report=await preload("res://tests/dense_garden_benchmark.gd").sample(garden,argument("--capture"))
 report["load_ms"]=load_ms
 var file=FileAccess.open(argument("--report","/tmp/zend-garden-benchmark-report.json"),FileAccess.WRITE)
 file.store_string(JSON.stringify(report," "))
 file.close()
 print("GARDEN_BENCHMARK ",JSON.stringify(report))
 garden.queue_free()
 await process_frame
 quit()
