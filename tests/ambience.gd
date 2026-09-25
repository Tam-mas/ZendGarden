extends RefCounted

static func run(g, failures: Array) -> void:
 var greenhouse=GardenArt.furnishing("greenhouse")
 var posts=0
 for node in greenhouse.get_children():
  if node is MeshInstance3D and node.mesh is BoxMesh and is_equal_approx(node.mesh.size.y,2.3): posts+=1
 if posts!=6: failures.append("Greenhouse needs six full-height side supports")
 greenhouse.free()
 for item in GardenCatalogue.furnishings():
  if not ResourceLoader.exists("res://assets/shop/"+item.kind+".tscn"): failures.append("Missing inspectable shop model: "+item.kind)
 g.settings.pause_menus=false
 for i in range(4):
  g.player.position=GardenTerrain.point(g.plots[i].center)
  g.update_lighting()
  if g.ambient.bed!=i: failures.append("Bed soundscape selection incorrect")
  g.ambient._process(1)
 g.add_object("bath",Vector3(0,0,6),40)
 var bath=g.objects.back()
 var life=bath.node.get_node("BathVisitors")
 if life.birds.size()!=2: failures.append("Bird bath visitors missing")
 if GardenBathLife.bird_position(8,0).y>1.15 or GardenBathLife.bird_position(18,0).y>1.11: failures.append("Birds did not land and bathe")
 g.clock_time=.45
 g.player.position=bath.pos
 life.elapsed=18
 life._process(10)
 life.elapsed=18
 life._process(0)
 # Place the bird back in its bathing phase before measuring audio.
 life._process(1)
 var near=life.voice.volume_db
 g.player.position=Vector3(100,0,100)
 life._process(1)
 if life.voice.volume_db>=near: failures.append("Bird-bath audio did not fade with distance")
 g.clock_time=.9
 life._process(.1)
 if life.birds[0].visible or life.birds[1].visible: failures.append("Bath birds did not leave at night")
 g.save_game()
 var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
 if not saved.objects.any(func(o): return o.kind=="bath"): failures.append("Bird bath missing from save")
 # Compatibility-renderer visual review of the vista and the bathing pose.
 g.set_process(false)
 g.ui.hide()
 g.clock_time=.45
 g.update_lighting()
 g.environment.environment.fog_density=.00008
 g.camera.position=Vector3(0,4,8)
 g.camera.look_at(Vector3(-1500,220,-300))
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("/tmp/garden-mountains.png")
 life.elapsed=18
 life._process(0)
 life.set_process(false)
 g.camera.position=bath.pos+Vector3(-1.4,1.9,-2)
 g.camera.look_at(bath.pos+Vector3(0,1,0))
 await RenderingServer.frame_post_draw
 g.get_viewport().get_texture().get_image().save_png("/tmp/garden-bath.png")
 print("AMBIENCE_RESULT: ",failures)
