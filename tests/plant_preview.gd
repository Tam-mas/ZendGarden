extends SceneTree

class PreviewGarden:
 extends "res://scripts/garden.gd"
 func _ready() -> void: pass
 func _process(_delta: float) -> void: pass

var failures: Array=[]
var surfaces=0
var foliage=0

func _initialize() -> void:
 call_deferred("verify")

func inspect(before: Node, after: Node) -> void:
 if before is MeshInstance3D:
  if before.mesh!=after.mesh or not before.transform.is_equal_approx(after.transform): failures.append("Preview geometry differs from plant")
  if after.material_override!=null: failures.append("Flat material override hides plant detail")
  for surface in range(before.mesh.get_surface_count()):
   surfaces+=1
   var original=before.get_active_material(surface)
   var ghost=after.get_active_material(surface)
   if original==ghost: failures.append("Ghost changed a shared plant material")
   if original is StandardMaterial3D:
    if ghost.albedo_texture!=original.albedo_texture or ghost.normal_texture!=original.normal_texture or ghost.cull_mode!=original.cull_mode: failures.append("Preview lost texture or sidedness")
   elif original is ShaderMaterial:
    foliage+=1
    if not ghost.shader.resource_path.ends_with("leaf_preview.gdshader"): failures.append("Preview lost wind shader")
    for parameter in ["leaf_texture","leaf_color","leaf_normal","leaf_roughness","has_normal_map","has_roughness_map"]:
     if ghost.get_shader_parameter(parameter)!=original.get_shader_parameter(parameter): failures.append("Preview lost foliage parameter: "+parameter)
 if before.get_child_count()!=after.get_child_count(): failures.append("Preview hierarchy differs"); return
 for i in range(before.get_child_count()): inspect(before.get_child(i),after.get_child(i))

func check_tint(node: Node, tint: Color) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var material=node.get_active_material(surface)
   if material is ShaderMaterial and material.get_shader_parameter("preview_tint")!=tint: failures.append("Preview validity tint is stale")
 for child in node.get_children(): check_tint(child,tint)

func verify() -> void:
 var g=PreviewGarden.new()
 root.add_child(g)
 g.plant_root=Node3D.new()
 g.add_child(g.plant_root)
 # Keep this isolated from the game scene, player saves and world generation.
 for data in g.catalogue:
  var plant=GardenArt.plant(data)
  var ghost=GardenArt.plant(data)
  g.ghost_material(ghost)
  inspect(plant,ghost)
  g.ghost_material(ghost,Color(.94,.53,.40,.45))
  g.ghost_material(ghost)
  inspect(plant,ghost)
  plant.free()
  ghost.free()
 g.mode="walk"
 g.update_placement_preview("p60")
 var rotation=g.preview.rotation.y
 var first=g.preview
 g.hover_cell=Vector3(1,0,2)
 g.update_placement_preview("p60")
 if g.preview!=first or not is_equal_approx(g.preview.rotation.y,rotation): failures.append("Plant preview rotation changes with cursor")
 if not g.preview.position.is_equal_approx(g.hover_cell): failures.append("Preview did not follow cursor")
 g.mode="plant"
 g.selected=61
 g.unlocked_plots=0
 g.update_placement_preview("p61")
 if g.preview_error.is_empty(): failures.append("Blocked placement lacks error")
 check_tint(g.preview,Color(.94,.53,.40,.45))
 g.mode="walk"
 g.update_placement_preview("p61")
 check_tint(g.preview,Color(.82,.95,.66,.4))
 g.moved_index=-1
 for i in range(2):
  var source=GardenArt.plant(g.catalogue[60])
  source.scale=Vector3.ONE*(.12 if i==0 else .7)
  source.rotation.y=1.2+i
  source.get_node("Bloom").visible=i==1
  g.planted.append({"id":60,"node":source})
  g.moved_index=i
  g.update_placement_preview("m"+str(i))
  if not g.preview.scale.is_equal_approx(source.scale) or not g.preview.rotation.is_equal_approx(source.rotation): failures.append("Move preview differs from current plant shape")
  if g.preview.get_node("Bloom").visible!=source.get_node("Bloom").visible: failures.append("Move preview has wrong bloom state")
 var seed=g.add_plant(60,Vector3.ZERO,0,0,1,rotation)
 if not is_equal_approx(seed.node.rotation.y,rotation): failures.append("Planting lost preview rotation")
 for p in g.planted: p.node.free()
 g.free()
 await process_frame
 if "--review" in OS.get_cmdline_user_args(): await render_review()
 print("PLANT_PREVIEW_RESULT: ",JSON.stringify(failures)," (",surfaces," surfaces, ",foliage," foliage surfaces)")
 quit(0 if failures.is_empty() else 1)

func render_review() -> void:
 var stage=Node3D.new()
 root.add_child(stage)
 var world=WorldEnvironment.new()
 var environment=Environment.new()
 environment.background_mode=Environment.BG_COLOR
 environment.background_color=Color("39483d")
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color=Color.WHITE
 environment.ambient_light_energy=.65
 world.environment=environment
 stage.add_child(world)
 var sun=DirectionalLight3D.new()
 sun.rotation_degrees=Vector3(-55,-25,0)
 stage.add_child(sun)
 var g=PreviewGarden.new()
 stage.add_child(g)
 var ids=[60,65,76,105]
 for i in range(ids.size()):
  for ghost in [false,true]:
   var model=GardenArt.plant(g.catalogue[ids[i]])
   model.position=Vector3(i*3.6-5.4,0,2.5 if ghost else -1.5)
   model.rotation.y=.6
   if ghost: g.ghost_material(model)
   stage.add_child(model)
 var camera=Camera3D.new()
 stage.add_child(camera)
 camera.position=Vector3(0,9,15)
 camera.look_at(Vector3(0,1,0))
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=17
 camera.current=true
 for i in range(6): await process_frame
 await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("res://captures/plant-preview-review.png")
 stage.free()
