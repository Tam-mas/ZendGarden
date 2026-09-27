extends RefCounted

static func run(g, failures: Array) -> void:
 var greenhouse=GardenArt.furnishing("greenhouse")
 var triangles=[]
 collect_triangles(greenhouse,Transform3D.IDENTITY,triangles)
 for x in [-1.6,1.6]:
  for z in [-1.4,-.7,0.0,.7,1.4]:
   var supported=false
   for tri in triangles:
    var bottom=10.0
    var top=-10.0
    var in_column=true
    for point in tri:
     in_column=in_column and absf(point.x-x)<.06 and absf(point.z-z)<.06
     bottom=minf(bottom,point.y)
     top=maxf(top,point.y)
    if in_column and bottom<.15 and top>2.3:
     supported=true
     break
   if not supported: failures.append("Greenhouse missing full-height support at "+str(Vector2(x,z)))
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

# Inspect the actual imported triangles; supports are now joined Blender meshes.
static func collect_triangles(node: Node3D, parent_transform: Transform3D, target: Array) -> void:
 var transform=parent_transform*node.transform
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var arrays=node.mesh.surface_get_arrays(surface)
   var vertices=arrays[Mesh.ARRAY_VERTEX]
   var indices=arrays[Mesh.ARRAY_INDEX]
   for i in range(0,indices.size(),3):
    target.append([transform*vertices[indices[i]],transform*vertices[indices[i+1]],transform*vertices[indices[i+2]]])
 for child in node.get_children():
  if child is Node3D: collect_triangles(child,transform,target)
