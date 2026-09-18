extends RefCounted

static func cross(g, start: Vector3, finish: Vector3, failures: Array, title: String) -> void:
 g.player.position=GardenTerrain.point(start)+Vector3(0,.08,0)
 g.player.velocity=Vector3.ZERO
 for frame in range(220):
  await g.get_tree().physics_frame
  var direction=finish-g.player.position
  direction.y=0
  if direction.length()<.2: return
  direction=direction.normalized()
  var dt=g.get_physics_process_delta_time()
  var motion=direction*3.2*dt
  if not g.accessible(g.player.position+motion): failures.append(title+" access blocked"); return
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
 var center=g.plots[10].center
 if g.bed_at(center)!=10 or not g.accessible(center): failures.append("Later garden bed inaccessible")
 var plant=g.add_plant(0,center,10)
 g.automation["10water"]=true
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if int(saved.plants.back().plot)!=10 or not saved.automation.has("10water"): failures.append("Multi-digit garden progress not saved")
 g.player.position=GardenTerrain.point(center+Vector3(0,0,6))+Vector3(0,.1,0)
 g.yaw=0
 g.pitch=.15
 g.update_camera(0)
 await g.get_tree().create_timer(.3).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/growing-gardens.png")
 g.set_process(true)
