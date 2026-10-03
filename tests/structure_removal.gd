extends RefCounted

static func surface_point(node: Node) -> Dictionary:
 if node is MeshInstance3D:
  var faces=node.mesh.get_faces()
  for i in range(0,faces.size(),3):
   var a=node.global_transform*faces[i]
   var b=node.global_transform*faces[i+1]
   var c=node.global_transform*faces[i+2]
   var normal=(b-a).cross(c-a).normalized()
   var point=(a+b+c)/3
   var origin=point+normal*1.8
   # New fittings can be the first imported mesh. Aim from above the terrain,
   # so this tests structure picking rather than intentional ground occlusion.
   if normal.length_squared()>.5 and normal.y>-.1 and point.y>GardenTerrain.point(point).y+.02 and origin.y>GardenTerrain.point(origin).y+.08:return {"point":point,"normal":normal,"mesh":node,"material":node.get_active_material(0)}
 for child in node.get_children():
  var found=surface_point(child)
  if not found.is_empty():return found
 return {}

static func aim(g, obj: Dictionary) -> Dictionary:
 for frame in range(2):await g.get_tree().physics_frame
 var face=surface_point(obj.node)
 g.player.position=GardenTerrain.point(obj.pos)+Vector3(0,.1,0)
 g.camera.global_position=face.point+face.normal*1.8
 g.camera.look_at(face.point,Vector3.FORWARD if absf(face.normal.y)>.98 else Vector3.UP)
 g.hover_target=-1
 g.update_hover()
 GardenPlantInspector.update(g)
 return face

static func run(g, failures: Array) -> void:
 g.set_process(false)
 g.settings.intro_seen=true
 g.settings.request_notifications=false
 g.dismiss_request()
 if is_instance_valid(g.welcome):GardenExperience.finish(g)
 g.settings.controls="keyboard";g.touch.configure()
 g.side_panel.hide()
 g.coins=300
 var spot=GardenTerrain.point(Vector3(-8,0,3))
 for item in g.furniture:
  var count=g.objects.size()
  g.add_object(item.kind,spot,item.price,false,.72,"Rose corner",Color("b4d6ff"))
  var obj=g.objects.back()
  g.set_mode("remove")
  var face=await aim(g,obj)
  if g.aimed_object()!=count or g.highlighted_structure!=obj.node:failures.append("Structure surface not targeted: "+item.kind)
  if face.mesh.get_active_material(0)==face.material:failures.append("Structure has no removal tint: "+item.kind)
  if not g.inspector_lines.has("Returns %d petals"%item.price):failures.append("Structure refund not explained: "+item.kind)
  var original=GardenArt.furnishing(item.kind)
  g.object_root.add_child(original)
  original.transform=obj.node.transform
  if surface_point(original).material!=face.material:failures.append("Removal tint changed shared materials: "+item.kind)
  original.queue_free()
  g.hover_valid=false;GardenPlantInspector.update(g)
  if face.mesh.get_active_material(0)!=face.material or is_instance_valid(g.highlighted_structure):failures.append("Tint persists after aim leaves: "+item.kind)
  await aim(g,obj)
  g.set_mode("walk")
  if face.mesh.get_active_material(0)!=face.material:failures.append("Tint persists after tool switch: "+item.kind)
  g.set_mode("remove");await aim(g,obj)
  var ray_origin=g.camera.global_position
  var direction=(face.point-ray_origin).normalized()
  if not GardenStructureTarget.ray(g,ray_origin,direction,ray_origin+direction*.2).is_empty():failures.append("Structure selected through terrain: "+item.kind)
  g.player.position+=Vector3(30,0,0)
  g.update_hover();GardenPlantInspector.update(g)
  if g.hover_valid or is_instance_valid(g.highlighted_structure):failures.append("Distant structure still selectable: "+item.kind)
  await aim(g,obj)
  var plant=g.add_plant(0,spot,0,1)
  g.hover_target=g.planted.find(plant)
  GardenPlantInspector.update(g)
  var petals=g.coins
  g.action_cooldown=0;g.perform_action()
  if g.objects.size()!=count or g.coins!=petals+item.price or plant not in g.planted:failures.append("Structure removal/refund affected the wrong target: "+item.kind)
  if is_instance_valid(g.highlighted_structure) or g.hover_valid:failures.append("Removed structure remains actionable: "+item.kind)
  g.save_game()
  var saved=JSON.parse_string(FileAccess.get_file_as_string(g.SAVE_PATH))
  if saved.objects.size()!=count:failures.append("Removed structure remains in save: "+item.kind)
  if obj in g.objects:g.objects.erase(obj);obj.node.queue_free()
  g.planted.erase(plant);plant.node.queue_free();plant.marker.queue_free()
  await g.get_tree().process_frame
 g.settings.controls="touch";g.touch.configure();g.side_panel.hide()
 for kind in ["sign","pond"]:
  var price=15 if kind=="sign" else 75
  g.add_object(kind,spot,price,kind=="pond",.72,"Rose corner",Color("b4d6ff"))
  var count=g.objects.size()
  g.set_mode("remove");await aim(g,g.objects.back())
  g.touch._process(0)
  var petals=g.coins
  g.action_cooldown=0;g.touch.act()
  if g.objects.size()!=count-1 or g.touch.removed.is_empty() or g.touch.removed.get("plant",true):failures.append("Touch structure removal/undo target failed: "+kind)
  g.touch.undo_remove()
  var restored=g.objects.back()
  if g.objects.size()!=count or g.coins!=petals or not is_equal_approx(restored.rotation,.72) or restored.fish!=(kind=="pond"):failures.append("Touch undo lost structure state: "+kind)
  if kind=="sign" and (restored.get("text","")!="Rose corner" or restored.get("text_color","")!="b4d6ff"):failures.append("Touch undo lost custom sign text/colour")
  g.set_mode("remove");await aim(g,restored)
  g.action_cooldown=0;g.touch.act()
  await g.get_tree().process_frame
 g.settings.controls="keyboard";g.touch.configure()
 g.get_window().size=Vector2i(1280,800)
 for frame in range(3):await g.get_tree().process_frame
 g.touch.configure()
 g.add_object("bench",spot,45)
 g.set_mode("remove")
 await g.get_tree().physics_frame
 g.player.position=spot+Vector3(0,.1,3)
 g.camera.global_position=spot+Vector3(2,1.8,3.4)
 g.camera.look_at(spot+Vector3(0,.65,0))
 g.update_hover();GardenPlantInspector.update(g);g.update_hud()
 for frame in range(6):await g.get_tree().process_frame
 await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://captures/plant-improvements")
 g.get_viewport().get_texture().get_image().save_png("res://captures/plant-improvements/structure-removal.png")
 g.set_mode("walk")
