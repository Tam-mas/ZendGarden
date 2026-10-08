extends RefCounted

static func land(g) -> void:
 g.player.velocity.x=0;g.player.velocity.z=0
 for settling in range(40):
  await g.get_tree().physics_frame
  g.player.velocity.y=0 if g.player.is_on_floor() else g.player.velocity.y-18*g.get_physics_process_delta_time()
  g.player.move_and_slide()
  if g.player.is_on_floor():break

static func cross(g, start: Vector3, finish: Vector3, failures: Array, title: String) -> void:
 g.player.position=GardenRavine.safe_player(start)+Vector3(0,.65,0)
 g.player.velocity=Vector3.ZERO
 # Land on the actual surface, which may be a deck above planting terrain.
 await land(g)
 if not g.player.is_on_floor():
  failures.append(title+" has no floor at the start: "+str(g.player.position));return
 for frame in range(220):
  await g.get_tree().physics_frame
  var direction=finish-g.player.position
  direction.y=0
  if g.player.position.y<GardenTerrain.point(g.player.position).y-1:
   failures.append(title+" fell through the ground at "+str(g.player.position));return
  if direction.length()<.2:
   # A descending path can end briefly above its next surface; let it settle.
   await land(g)
   if not g.player.is_on_floor():failures.append(title+" finished without a floor at "+str(g.player.position))
   return
  direction=direction.normalized()
  var dt=g.get_physics_process_delta_time()
  var motion=direction*3.2*dt
  if not g.accessible(g.player.position+motion): failures.append(title+" access blocked at "+str(g.player.position)); return
  g.player.velocity.x=direction.x*3.2
  g.player.velocity.z=direction.z*3.2
  g.player.velocity.y=0 if g.player.is_on_floor() else g.player.velocity.y-18*dt
  g.walk_motion(motion)
  g.player.move_and_slide()
 for i in range(g.player.get_slide_collision_count()):
  var hit=g.player.get_slide_collision(i)
  print("WALK_HIT ",title," ",hit.get_normal()," ",hit.get_collider().get_parent().name," at ",hit.get_position())
 failures.append(title+" player could not walk across at "+str(g.player.position)+" normal "+str(g.player.get_slide_collision(0).get_normal() if g.player.get_slide_collision_count()>0 else Vector3.ZERO))

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.unlocked_plots=1
 await cross(g,Vector3(5.7,0,5.9),Vector3(11.3,0,5.9),failures,"East bridge outward")
 await cross(g,Vector3(11.3,0,5.9),Vector3(5.7,0,5.9),failures,"East bridge return")
 await cross(g,Vector3(17,0,-5.7),Vector3(17,0,-11.3),failures,"North bridge outward")
 await cross(g,Vector3(17,0,-11.3),Vector3(17,0,-5.7),failures,"North bridge return")
 # A deterministic ankle-high obstacle exercises step-up rather than mere floor snapping.
 var rock=StaticBody3D.new()
 var collision=CollisionShape3D.new()
 var shape=BoxShape3D.new()
 shape.size=Vector3(.5,.28,1.4)
 collision.shape=shape
 rock.add_child(collision)
 rock.position=GardenTerrain.point(Vector3(0,0,6))+Vector3(0,.12,0)
 g.world_root.add_child(rock)
 await cross(g,Vector3(-1.4,0,6),Vector3(1.4,0,6),failures,"Low stone")
 rock.queue_free()
 g.unlocked_plots=12
 GardenExpansion.prepare(g)
 for row in range(2,int(g.plots.size()/2)): GardenExpansion.build_row(g,row)
 if g.plots.size()<14: failures.append("Garden stopped expanding beyond original beds")
 await cross(g,Vector3(17,0,-22),Vector3(17,0,-29),failures,"New garden gateway")
 var later=20
 var center=g.plots[later].center
 if g.bed_at(center)!=later or not g.accessible(center): failures.append("Later garden bed inaccessible")
 var plant=g.add_plant(0,center,later)
 g.automation["20water"]=true
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if int(saved.plants.back().plot)!=later or not saved.automation.has("20water"): failures.append("Multi-digit garden progress not saved")
 g.player.position=GardenTerrain.point(center+Vector3(0,0,6))+Vector3(0,.1,0)
 g.yaw=0
 g.pitch=.15
 g.update_camera(0)
 await g.get_tree().create_timer(.3).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/growing-gardens.png")
 g.set_process(true)
