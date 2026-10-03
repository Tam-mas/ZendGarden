class_name GardenClearView
extends RefCounted

# Hide whole interface layers so timed notes cannot appear over the garden.
# Keep the current tool and menu state ready for the return key.
static func enter(g) -> void:
 if g.clear_view or g.photo_mode or g.day_transition or is_instance_valid(g.welcome): return
 g.clear_view_state={"ui":g.ui.visible,"touch":g.touch.visible,"tool":g.held_tool.visible,"mouse":Input.mouse_mode}
 g.clear_view=true
 g.get_viewport().gui_release_focus()
 g.touch.reset_gestures()
 g.ui.hide()
 g.touch.hide()
 g.held_tool.hide()
 g.grid_root.hide()
 g.grid_cursor.hide()
 g.area_cursor.hide()
 if is_instance_valid(g.preview):g.preview.hide()
 g.hover_valid=false
 g.hover_target=-1
 g.hover_object=null
 if is_instance_valid(g.highlighted_plant):GardenPlantInspector.highlight(g.highlighted_plant,false)
 g.highlighted_plant=null
 GardenStructureTarget.clear(g)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if g.touch_active() else Input.MOUSE_MODE_CAPTURED

static func leave(g) -> void:
 if not g.clear_view:return
 g.clear_view=false
 g.ui.visible=g.clear_view_state.ui
 g.touch.visible=g.clear_view_state.touch
 g.held_tool.visible=g.clear_view_state.tool
 Input.mouse_mode=g.clear_view_state.mouse
 g.clear_view_state.clear()
 g.touch.reset_gestures()
 # A click used to return must finish before a held tool can repeat.
 g.clear_view_hold_guard=true
 g.update_camera(0)
 g.update_hud()

static func input(g, event: InputEvent) -> void:
 if not g.clear_view:return
 # Touch generates a mouse press before its finger event. Wait for the real
 # finger so it can be canceled through release instead of starting a gesture.
 if event is InputEventMouse and event.device==-1:
  g.get_viewport().set_input_as_handled()
  return
 var wake=(event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
 if wake:
  leave(g)
  if event is InputEventScreenTouch:g.touch.view_return_fingers[event.index]=true
  g.get_viewport().set_input_as_handled()
