extends SceneTree

func _initialize() -> void:
 var g=load("res://scripts/garden.gd").new()
 var failures=[]
 for horizontal in [false,true]:
  for vertical in [false,true]:
   g.settings.invert_x=horizontal
   g.settings.invert_y=vertical
   g.settings.sensitivity=1.0
   g.yaw=0.0
   g.pitch=0.0
   g.apply_mouse_look(Vector2(10,20))
   if not is_equal_approx(g.yaw,.022 if horizontal else -.022): failures.append("Horizontal inversion")
   if not is_equal_approx(g.pitch,-.044 if vertical else .044): failures.append("Vertical inversion")
 g.settings.invert_x=false
 g.settings.invert_y=false
 g.settings.sensitivity=2.0
 g.yaw=0.0
 g.pitch=0.0
 g.apply_mouse_look(Vector2(10,10000))
 if not is_equal_approx(g.yaw,-.044) or not is_equal_approx(g.pitch,1.45): failures.append("Sensitivity or pitch limit")
 # Existing saves have no invert_x; merging must preserve the default and old Y setting.
 g.settings.merge(JSON.parse_string('{"invert_y":true}'),true)
 if g.settings.invert_x or not g.settings.invert_y: failures.append("Legacy settings compatibility")
 g.settings.invert_x=true
 var restored=JSON.parse_string(JSON.stringify(g.settings))
 if not restored.invert_x or not restored.invert_y: failures.append("Inversion persistence")
 g.free()
 print("MOUSE_LOOK_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)
