extends SceneTree

class PreviewGame extends Node:
 var ui: Control
 var side_panel: PanelContainer
 var welcome: PanelContainer
 var welcome_backdrop: ColorRect
 var touch=null
 var updates_open=false
 var updates_return_to_game=false
 var settings={"intro_seen":true,"updates_seen":0}
 var loaded_data={"day":12}
 var smoke=false
 var saves=0
 var resumed=0
 var saved_settings={}

 func _ready() -> void:
  ui=Control.new()
  ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  ui.theme=GardenTheme.make()
  add_child(ui)
  side_panel=PanelContainer.new()
  ui.add_child(side_panel)
  side_panel.hide()

 func _process(_delta: float) -> void:
  if updates_open: GardenUpdates.layout(self)

 func panel_at(pos: Vector2, dimensions: Vector2) -> PanelContainer:
  var panel=PanelContainer.new()
  panel.position=pos
  panel.size=dimensions
  ui.add_child(panel)
  return panel

 func label(text: String, font_size: int=16, color: Color=Color("efdfbc")) -> Label:
  var result=Label.new()
  result.text=text
  result.add_theme_font_size_override("font_size",font_size)
  result.add_theme_color_override("font_color",color)
  return result

 func button(text: String, action: Callable, minimum: Vector2=Vector2(0,38)) -> Button:
  var result=Button.new()
  result.text=text
  result.custom_minimum_size=minimum
  result.pressed.connect(action)
  return result

 func save_game() -> void:
  saves+=1
  saved_settings=settings.duplicate(true)

 func resume_controls() -> void:
  resumed+=1

func _initialize() -> void:
 create_timer(20).timeout.connect(func(): push_error("Update test timed out"); quit(1))
 call_deferred("run")

func run() -> void:
 var failures=[]
 var game=PreviewGame.new()
 root.add_child(game)
 var previous=GardenUpdates.CURRENT_VERSION+1
 for entry in GardenUpdates.RELEASES:
  if entry.version!=previous-1: failures.append("Update counter is not sequential")
  previous=entry.version
 if GardenUpdates.unseen({}).size()!=GardenUpdates.RELEASES.size(): failures.append("Old save did not receive updates")
 game.smoke=true
 if GardenUpdates.maybe_show(game): failures.append("Smoke test interrupted by updates")
 game.smoke=false
 game.loaded_data={}
 if GardenUpdates.maybe_show(game) or game.settings.updates_seen!=GardenUpdates.CURRENT_VERSION: failures.append("New visitor interrupted with old history")
 game.loaded_data={"day":12}
 game.settings.updates_seen=GardenUpdates.CURRENT_VERSION-1
 if not GardenUpdates.maybe_show(game): failures.append("Returning player did not receive new update")
 var entries=game.welcome.get_node("UpdateContent/UpdateHistory").get_child(0)
 if entries.get_child_count()!=1: failures.append("Already seen updates repeated automatically")
 if not game.updates_open: failures.append("Updates dialog not marked open")
 GardenUpdates.dismiss(game)
 if game.saved_settings.get("updates_seen",0)!=GardenUpdates.CURRENT_VERSION: failures.append("Dismissal was not saved")
 if is_instance_valid(game.welcome_backdrop) or game.updates_open or game.resumed!=1: failures.append("Dismissal did not restore garden controls")
 if GardenUpdates.maybe_show(game): failures.append("Dismissed update appeared again")
 game.settings=game.saved_settings.duplicate(true)
 if GardenUpdates.maybe_show(game): failures.append("Dismissal was lost after reloading saved settings")
 game.side_panel.show()
 GardenUpdates.show(game)
 if not game.updates_open: failures.append("Cannot reopen update history")
 if game.welcome.get_node("UpdateContent/UpdateHistory").get_child(0).get_child_count()!=GardenUpdates.RELEASES.size(): failures.append("Reopened history is incomplete")
 for dimensions in [Vector2i(1280,800),Vector2i(390,844),Vector2i(667,375),Vector2i(320,568)]:
  root.size=dimensions
  root.content_scale_size=Vector2i.ZERO
  await process_frame
  await process_frame
  await process_frame
  GardenUpdates.layout(game)
  var bounds=game.welcome.get_global_rect()
  var viewport=game.get_viewport().get_visible_rect()
  if not viewport.encloses(bounds): failures.append("Update card outside viewport at "+str(dimensions))
  var done=game.welcome.get_node("UpdateContent/DismissUpdates")
  if not bounds.encloses(done.get_global_rect()): failures.append("Dismiss button outside card at "+str(dimensions))
  if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
   await RenderingServer.frame_post_draw
   var output="res://captures/updates-%dx%d.png"%[dimensions.x,dimensions.y]
   root.get_texture().get_image().save_png(output)
 GardenUpdates.dismiss(game)
 if game.resumed!=1: failures.append("History dismissal closed the settings menu")
 game.queue_free()
 await process_frame
 print("PLAYER_UPDATES_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)
