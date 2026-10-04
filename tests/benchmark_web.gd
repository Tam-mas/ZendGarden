extends "res://scripts/garden.gd"

# Only used as the main scene of a disposable local test export.
func browser_save_check() -> bool:
 # The loader fingerprints the active garden; this harness uses its own file.
 return FileAccess.file_exists(SAVE_PATH)

func _ready() -> void:
 SAVE_PATH="user://dense-garden-benchmark.json"
 var fixture=JavaScriptBridge.eval("window.gardenBenchmarkSave",true)
 var copy=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
 copy.store_string(fixture)
 copy.close()
 super._ready()
 call_deferred("benchmark")

func benchmark() -> void:
 var report=await preload("res://tests/dense_garden_benchmark.gd").sample(self)
 var output=JSON.stringify(report)
 print("GARDEN_BROWSER_BENCHMARK ",output)
 JavaScriptBridge.eval("document.getElementById('benchmark-report').textContent="+JSON.stringify(output))
 set_process(false)
