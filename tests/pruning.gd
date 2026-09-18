extends RefCounted

static func run(g, failures: Array) -> void:
 var p=g.add_plant(20,GardenTerrain.point(Vector3(-3,0,-3)),0,g.catalogue[20].days)
 await g.get_tree().create_timer(1).timeout
 var before=p.node.scale
 g.mode="prune"
 g.hover_valid=true
 g.hover_cell=p.pos
 g.action_cooldown=0
 g.perform_action()
 await g.get_tree().create_timer(1).timeout
 if p.node.scale.y>=before.y*.8 or float(p.pruned)!=1: failures.append("Pruning did not visibly reshape the plant")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if float(saved.plants.back().pruned)!=1: failures.append("Pruned shape was not saved")
 g.advance_growth()
 if p.pruned>=1: failures.append("Pruned shape did not begin regrowing")
 # Cancel must leave the garden intact; backing up must preserve the complete save.
 var count=g.planted.size()
 GardenExperience.confirm_restart(g)
 g.welcome.get_child(0).get_child(2).pressed.emit()
 if g.planted.size()!=count or is_instance_valid(g.welcome): failures.append("Restart cancellation changed the garden")
 var backup=g.backup_for_restart()
 if backup.is_empty() or not FileAccess.file_exists(backup) or FileAccess.file_exists(g.SAVE_PATH): failures.append("Restart backup failed")
 else:
  var previous=JSON.parse_string(FileAccess.get_file_as_string(backup))
  if previous.plants.size()!=count: failures.append("Restart backup lost plants")
  DirAccess.rename_absolute(backup,g.SAVE_PATH)
