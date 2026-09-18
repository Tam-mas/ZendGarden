extends RefCounted

static func run(g, failures: Array) -> void:
 g.settings.reduced_motion=true
 var petals=g.coins
 var day=g.day
 g.next_day()
 if g.coins!=petals or g.day!=day+1 or g.day_transition: failures.append("Quiet day skip or no-passive-income rule failed")
 g.orders[0]["pending"]=true
 g.orders[0]["ready_day"]=g.day+2
 g.replenish_orders()
 if not g.orders[0].pending: failures.append("Request arrived before its due day")
 g.settings.request_notifications=false
 g.day+=2
 g.replenish_orders()
 if g.orders[0].get("pending",false) or not g.request_unread: failures.append("Scheduled request did not arrive")
 if is_instance_valid(g.request_popup) and g.request_popup.visible: failures.append("Disabled notification still visible")
 g.settings.request_notifications=true
 g.notify_requests()
 if not is_instance_valid(g.request_popup): failures.append("Request notification missing")
 g.open_sidebar("Settings")
 await g.get_tree().create_timer(.4).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/comfort-settings.png")
 var later=g.request_popup.get_child(0).get_child(3)
 later.pressed.emit()
 await g.get_tree().process_frame
 if g.request_popup.visible: failures.append("Dismissed request popup returned")
 g.show_welcome()
 var clock=g.clock_time
 var position=g.player.position
 await g.get_tree().create_timer(.5).timeout
 if g.clock_time!=clock or g.player.position!=position: failures.append("Welcome did not pause the game")
 g.get_viewport().get_texture().get_image().save_png("res://captures/welcome-garden.png")
 GardenExperience.welcome(g,3)
 await g.get_tree().create_timer(.3).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/welcome-neighbours.png")
 GardenExperience.welcome(g,4)
 await g.get_tree().create_timer(.3).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/welcome-future.png")
 GardenExperience.finish(g)
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if not saved.settings.intro_seen or not saved.settings.reduced_motion: failures.append("Experience preferences not saved")
 g.pets[0].routine_time=45
 g.pets[1].routine_time=45
 for i in range(2):
  g.pets[i].animate(g,.01,i)
  if g.pets[i].visiting: failures.append("Companion did not wander independently")
 g.pets[0].routine_time=135
 g.pets[1].routine_time=135
 for i in range(2):
  g.pets[i].animate(g,.01,i)
  if not g.pets[i].visiting: failures.append("Companions cannot return together")
