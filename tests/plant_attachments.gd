extends SceneTree
# Run with a real renderer, not --headless (which uses the dummy renderer):
# godot --path . --rendering-method gl_compatibility --resolution 480x400 --script tests/plant_attachments.gd
# Linux CI uses xvfb + Mesa. Compare silhouettes, not renderer-specific lighting.

class TestGarden extends "res://scripts/garden.gd":
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass
 func refresh_ui() -> void:pass
 func refresh_wildlife() -> void:pass
 func update_hud() -> void:pass
 func resume_controls() -> void:pass
 func toast(_message: String) -> void:pass
 func care_effect(_pos: Vector3,_color: Color) -> void:pass

var failures=[]
var comparisons=0

func check(ok: bool,note: String) -> void:
 if not ok:failures.append(note)

func _initialize() -> void:call_deferred("verify")

func freeze_wind(node: Node) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var material=node.get_active_material(surface)
   if material is ShaderMaterial:material.set_shader_parameter("wind_strength",0.)
 for child in node.get_children():freeze_wind(child)

func capture() -> Image:
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()

func foreground(pixel: Color,background: Color) -> bool:
 return absf(pixel.r-background.r)+absf(pixel.g-background.g)+absf(pixel.b-background.b)>.1

func foreground_near(image: Image,x: int,y: int,background: Color) -> bool:
 for dy in range(maxi(0,y-1),mini(image.get_height(),y+2)):
  for dx in range(maxi(0,x-1),mini(image.get_width(),x+2)):
   if foreground(image.get_pixel(dx,dy),background):return true
 return false

func compare(a: Image,b: Image,label: String,expect_match: bool=true) -> void:
 var background=a.get_pixel(0,0)
 var mismatched=0
 var occupied=0
 for y in range(a.get_height()):
  for x in range(a.get_width()):
   var first=foreground(a.get_pixel(x,y),background)
   var second=foreground(b.get_pixel(x,y),background)
   if first or second:occupied+=1
   if first and not second and not foreground_near(b,x,y,background):mismatched+=1
   elif second and not first and not foreground_near(a,x,y,background):mismatched+=1
 check(occupied>8,label+": fixture is not visible")
 # Ignore one-pixel rasterisation/half-float edges, never a displaced organ.
 var limit=maxi(8,ceili(occupied*.015))
 var matched=mismatched<=limit
 check(matched==expect_match,"%s: %d silhouette pixels moved (limit %d, expect match %s)"%[label,mismatched,limit,expect_match])
 if matched!=expect_match:
  DirAccess.make_dir_recursive_absolute("res://build/attachment-review")
  a.save_png("res://build/attachment-review/"+label+"-batch.png")
  b.save_png("res://build/attachment-review/"+label+"-individual.png")
 comparisons+=1

func attachment_view(g,p: Dictionary,individual: bool) -> void:
 # Isolate organs using encoded attachment coordinates. Whole-tree silhouettes
 # also differ with automatic leaf LOD and aren't an attachment-position oracle.
 for entry in g.plant_batches.members.get(p.node.get_instance_id(),[]):
  var material=entry.node.get_active_material(0)
  var anchored=material is ShaderMaterial and bool(material.get_shader_parameter("fruit_anchors"))
  entry.renderer.visible=anchored
  entry.node.visible=individual and anchored

func check_members(g,p: Dictionary,label: String) -> void:
 var entries: Array=g.plant_batches.members.get(p.node.get_instance_id(),[])
 check(not entries.is_empty(),label+": plant was not batched")
 for entry in entries:
  var multi: MultiMesh=entry.renderer.multimesh
  check(multi.use_colors,label+": missing neutral instance colour")
  check(multi.get_instance_color(entry.slot).is_equal_approx(Color.WHITE),label+": attachment bytes are being multiplied by a tint")
  var actual=entry.renderer.global_transform*multi.get_instance_transform(entry.slot)
  check(actual.is_equal_approx(entry.node.global_transform),label+": stale transform after growth/pruning")

func verify() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Attachment regression needs a real renderer; use xvfb on CI, not --headless")
  quit(1);return
 var g=TestGarden.new();root.add_child(g)
 g.smoke=true;g.SAVE_PATH="user://attachment-regression-unused.json"
 # Auto deliberately lowers batched leaf LOD; use equal detail for comparisons.
 g.settings.graphics="standard"
 g.expansions={"0":100}
 g.side_panel=PanelContainer.new();g.add_child(g.side_panel)
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.object_root=Node3D.new();g.add_child(g.object_root)
 g.camera=Camera3D.new();g.add_child(g.camera);g.camera.current=true
 var light=DirectionalLight3D.new();g.add_child(light)
 light.rotation_degrees=Vector3(-50,-25,0)
 # Use the normal activation threshold with real off-camera planted specimens.
 for i in range(GardenPlantBatches.MIN_PLANTS):
  g.add_plant(0,Vector3(100+i,0,100),0,g.catalogue[0].days,1.,0.,i)
 g.loaded_data={"plants":range(g.planted.size())}
 g.plant_batches=GardenPlantBatches.new();g.add_child(g.plant_batches)
 g.plant_batches.setup(g);g.plant_batches.set_process(false)
 check(g.plant_batches.active,"Dense garden did not activate batching")
 for id in range(278,298)+GardenPlantGrowth.FRUIT_TREES:
  for scenario in ["forming","ripening","pruned"]:
   var fraction=.65 if scenario=="forming" else .88 if scenario=="ripening" else 1.
   var p=g.add_plant(id,Vector3(-3,0,-3),0,float(g.catalogue[id].days)*fraction,1.,.5,100)
   # Freeze before a mesh/material enters the batch cache; this is a geometry test.
   freeze_wind(p.node)
   if scenario=="pruned":
    g.plant_batches.rebuild()
    g.mode="prune";g.hover_valid=true;g.hover_cell=p.pos;g.action_cooldown=0
    g.perform_action()
    check(is_equal_approx(p.pruned,1.),"Prune action was not exercised")
    check(p.age<float(g.catalogue[id].days),"Prune did not gather mature produce")
    # Finish the scale animation deterministically, as the normal refresh does.
    g.refresh_plant(p,false)
   freeze_wind(p.node)
   var height=float(g.catalogue[id].height)
   g.camera.position=p.node.position+Vector3(1,1,2)*maxf(.22,height*.60)
   g.camera.look_at(p.node.position+Vector3(0,height*.45,0))
   g.plant_batches.rebuild()
   var label="%d-%s"%[id,scenario]
   check_members(g,p,label)
   attachment_view(g,p,false)
   var batched=await capture()
   if id==278 and scenario=="ripening":
    # Negative control: reproduce corrupted depth bytes. The rendered oracle
    # must reject this, not just pass because its tolerance hides the bug.
    for entry in g.plant_batches.members[p.node.get_instance_id()]:
     entry.renderer.multimesh.set_instance_color(entry.slot,Color.BLACK)
    var corrupted=await capture()
    compare(corrupted,batched,label+"-corrupted-depth",false)
    for entry in g.plant_batches.members[p.node.get_instance_id()]:
     entry.renderer.multimesh.set_instance_color(entry.slot,Color.WHITE)
   # This is the same individual-rendering switch performed when pointing.
   g.plant_batches.select(p.node)
   attachment_view(g,p,true)
   var individual=await capture()
   compare(batched,individual,label)
   g.plant_batches.select(null)
   var deselected=await capture()
   compare(deselected,individual,label+"-deselected")
   check_members(g,p,label+"-deselected")
   p.node.free();p.marker.free();g.planted.erase(p);g.plant_index.invalidate()
 g.free();await process_frame
 print("PLANT_ATTACHMENTS_RESULT: ",JSON.stringify({"comparisons":comparisons,"failures":failures}))
 quit(0 if failures.is_empty() else 1)
