class_name GardenMenuScroll
extends ScrollContainer

# Observe the gesture before a card/button consumes it. Taps still use Godot's
# normal controls; crossing the dead zone cancels the press before moving rows.
const DRAG_DISTANCE=10.0
const FRICTION=2400.0
var g
var finger=-1
var mouse_down=false
var suppress_emulated=false
var extra_fingers: Dictionary={}
var anchor=Vector2.ZERO
var previous=Vector2.ZERO
var position_y=0.0
var speed=0.0
var last_motion=0
var scrolling=false

func _ready() -> void:
 visibility_changed.connect(cancel_gesture)
 resized.connect(cancel_gesture)
 get_viewport().size_changed.connect(cancel_gesture)

func available() -> bool:
 if not is_instance_valid(g) or not g.touch_active() or not is_visible_in_tree():return false
 if is_instance_valid(g.welcome) and not g.welcome.is_ancestor_of(self):return false
 if is_instance_valid(g.request_popup) and g.request_popup.visible:return false
 return true

func local_point(point: Vector2) -> Vector2:
 return get_global_transform_with_canvas().affine_inverse()*point

# Sliders, text selection, dropdowns and scrollbars keep their own gestures.
func owns_gesture(node: Node, point: Vector2) -> bool:
 for child in node.get_children():
  if child is Control and child.is_visible_in_tree():
   var inside=Rect2(Vector2.ZERO,child.size).has_point(child.get_global_transform_with_canvas().affine_inverse()*point)
   if inside and (child is Range or child is LineEdit or child is TextEdit or child is OptionButton):return true
   if (inside or not child.clip_contents) and owns_gesture(child,point):return true
 return false

func begin(point: Vector2) -> bool:
 if not Rect2(Vector2.ZERO,size).has_point(local_point(point)) or owns_gesture(self,point):return false
 var was_coasting=scrolling
 cancel_gesture()
 anchor=local_point(point)
 previous=anchor
 position_y=get_v_scroll_bar().value
 last_motion=Time.get_ticks_msec()
 # A tap during momentum stops the list, without activating the moving card.
 if was_coasting:start_scroll()
 return true

func start_scroll() -> void:
 if scrolling:return
 scrolling=true
 propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
 scroll_started.emit()

func move(point: Vector2) -> void:
 var local=local_point(point)
 var now=Time.get_ticks_msec()
 if not scrolling and local.distance_to(anchor)>DRAG_DISTANCE:start_scroll()
 if scrolling:
  var delta=previous.y-local.y
  position_y=clampf(position_y+delta,0,maxf(0,get_v_scroll_bar().max_value-get_v_scroll_bar().page))
  get_v_scroll_bar().value=position_y
  var elapsed=maxf(.008,(now-last_motion)/1000.0)
  speed=lerpf(speed,clampf(delta/elapsed,-1800,1800),.55)
  get_viewport().set_input_as_handled()
 previous=local
 last_motion=now

func release(canceled: bool=false) -> void:
 finger=-1
 mouse_down=false
 if canceled:
  propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
  cancel_gesture()
 elif not scrolling or absf(speed)<20 or Time.get_ticks_msec()-last_motion>120 or g.settings.reduced_motion:
  cancel_gesture()
 # Let the release reach the original control so Godot clears GUI ownership.
 # Its press was already canceled by SCROLL_BEGIN, so it cannot activate.

func cancel_gesture() -> void:
 if finger>=0 or mouse_down:propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
 finger=-1
 mouse_down=false
 extra_fingers.clear()
 speed=0
 if scrolling:
  scrolling=false
  propagate_notification(Control.NOTIFICATION_SCROLL_END)
  scroll_ended.emit()

func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch and event.pressed:suppress_emulated=false
 if not available():
  cancel_gesture()
  return
 # Godot may send the emulated mouse press BEFORE the matching touch. Decide
 # from this new position, not the preceding gesture (which may be another page).
 if event is InputEventMouseButton and event.device==-1 and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  suppress_emulated=Rect2(Vector2.ZERO,size).has_point(local_point(event.position)) and not owns_gesture(self,event.position)
 if event is InputEventMouse and event.device==-1 and suppress_emulated:
  get_viewport().set_input_as_handled()
  return
 if event is InputEventScreenTouch:
  if extra_fingers.has(event.index):
   if not event.pressed:extra_fingers.erase(event.index)
   get_viewport().set_input_as_handled()
  elif event.pressed:
   if finger>=0:
    extra_fingers[event.index]=true
    suppress_emulated=true
    get_viewport().set_input_as_handled()
   elif begin(event.position):
    finger=event.index
    suppress_emulated=true
    if scrolling:get_viewport().set_input_as_handled()
  elif event.index==finger:release(event.canceled)
 elif event is InputEventScreenDrag:
  if event.index==finger:move(event.position)
  elif extra_fingers.has(event.index):get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.device!=-1:
  if event.pressed:
   mouse_down=begin(event.position)
   if mouse_down and scrolling:get_viewport().set_input_as_handled()
  elif mouse_down:release()
 elif event is InputEventMouseMotion and mouse_down:move(event.position)

func _process(delta: float) -> void:
 if not available():
  cancel_gesture()
  return
 if not scrolling or finger>=0 or mouse_down:return
 if absf(speed)<20 or g.settings.reduced_motion:
  cancel_gesture()
  return
 var maximum=maxf(0,get_v_scroll_bar().max_value-get_v_scroll_bar().page)
 position_y=clampf(position_y+speed*delta,0,maximum)
 get_v_scroll_bar().value=position_y
 speed=move_toward(speed,0,FRICTION*delta)
 if position_y<=0 or position_y>=maximum:cancel_gesture()

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:cancel_gesture()
