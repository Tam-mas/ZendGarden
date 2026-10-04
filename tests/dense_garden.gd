extends SceneTree
# MultiMesh readback requires an actual renderer; run with gl_compatibility or forward_plus.

class TestGarden:
 extends "res://scripts/garden.gd"
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass
 func refresh_ui() -> void:pass
 func refresh_wildlife() -> void:pass
 func update_hud() -> void:pass
 func resume_controls() -> void:pass
 func toast(_message: String) -> void:pass
 func care_effect(_pos: Vector3,_color: Color) -> void:pass

var failures=[]

func check(condition: bool,note: String) -> void:
 if not condition:failures.append(note)

func _initialize() -> void:
 call_deferred("verify")

func verify() -> void:
 var g=TestGarden.new()
 root.add_child(g)
 g.smoke=true
 g.expansions={"0":100}
 g.side_panel=PanelContainer.new();g.add_child(g.side_panel)
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.object_root=Node3D.new();g.add_child(g.object_root)
 g.loaded_data={"plants":range(220)}
 g.plant_batches=GardenPlantBatches.new();g.add_child(g.plant_batches);g.plant_batches.setup(g)
 for i in range(220):
  var id=[18,19,14,0][i%4]
  g.add_plant(id,Vector3((i%20-10)*g.GRID,0,(int(i/20)-5)*g.GRID),0,g.catalogue[id].days,1.0,i*.1,i)
 var young=g.add_plant(0,Vector3(4,0,4),0,0,1.0,0,7183)
 check(young.marker.get_child_count()==3,"Seed marker missing")
 check(g.planted[0].marker.get_child_count()==0,"Mature save allocated unused seed-marker meshes")
 g.plant_batches.rebuild()
 var original_meshes=0
 for entries in g.plant_batches.hidden.values():original_meshes+=entries.size()
 check(g.plant_batches.get_child_count()*3<original_meshes,"Repeated plants were not grouped efficiently")
 var p: Dictionary=g.planted[0]
 var membership: Dictionary=g.plant_batches.members[p.node.get_instance_id()][0]
 var data: Color=membership.renderer.multimesh.get_instance_custom_data(membership.slot)
 var shape: Vector4=p.node.get_meta("plant_shape")
 check(absf(data.r-shape.x)<.002 and absf(data.a-shape.w)<.005,"Saved individual shape lost in batching")
 g.plant_batches.select(p.node)
 GardenPlantInspector.highlight(p.node,true)
 check(membership.node.visible,"Selected plant was not shown for its outline")
 check(is_zero_approx(membership.renderer.multimesh.get_instance_transform(membership.slot).basis.determinant()),"Selected plant rendered twice")
 # Rebuilding during selection must not copy the outline onto every specimen.
 g.plant_batches.rebuild()
 for child in g.plant_batches.get_children():
  for i in range(child.multimesh.mesh.get_surface_count()):check(child.multimesh.mesh.surface_get_material(i).next_pass==null,"Selection outline leaked to a batch")
 GardenPlantInspector.highlight(p.node,false)
 g.plant_batches.select(null)
 check(not membership.node.visible,"Deselected plant was left outside its batch")
 var stable_renderer=g.plant_batches.get_child(0)
 p.pruned=1.0;g.refresh_plant(p,false)
 check(not g.plant_batches.dirty,"A scale-only trim forced a whole-garden rebuild")
 g.plant_batches._process(0)
 check(g.plant_batches.get_child(0)==stable_renderer,"A scale-only trim replaced unrelated render groups")
 young.age=g.catalogue[0].days
 g.refresh_plant(young,false)
 g.plant_batches.rebuild()
 check(not young.marker.visible and young.node.get_node("Bloom").visible,"Growth stage or seed marker failed to update")
 check(g.collect_plant(young),"Batched plant cannot be harvested")
 g.plant_batches.rebuild()
 check(young.node.get_meta("growth_fraction")<1,"Harvest did not change the rendered growth stage")
 g.selected_layer=0
 g.mode="move";g.moved_index=0;g.hover_valid=true;g.hover_plot=0;g.hover_cell=GardenTerrain.point(Vector3(-4.4,0,4.4));g.action_cooldown=0
 g.perform_action()
 g.plant_batches.rebuild()
 check(g.target_plant(p.pos)==0 and p.marker.position.is_equal_approx(p.pos),"Moving lost plant targeting or its marker")
 var entry: Dictionary=g.plant_batches.members[p.node.get_instance_id()][0]
 var world=entry.renderer.global_transform*entry.renderer.multimesh.get_instance_transform(entry.slot)
 check(world.origin.distance_to(entry.node.global_position)<.001,"Moved plant batch remained at its old location")
 g.mode="remove";g.hover_target=0;g.hover_valid=true;g.hover_cell=p.pos;g.action_cooldown=0
 g.perform_action();g.plant_batches.rebuild()
 check(g.planted.size()==220 and not g.plant_batches.members.has(p.node.get_instance_id()),"Removed plant left a rendered copy")
 # Rotated supports and varied plant heights still grow upright to a real post.
 g.add_object("pergola",Vector3(2,0,-1.6),80,false,PI*.5)
 var climber=g.add_plant(10,Vector3(3.2,0,-1.6),0,g.catalogue[10].days,1.2,PI*.7,42)
 GardenClimbingSupport.refresh(g)
 var vine=climber.node.get_node_or_null("Vines")
 check(vine!=null and vine.top_level,"Climber uses the plant's rotated/scaled coordinates")
 if vine:check(vine.get_child_count()==3,"Climber created individual placeholder flowers or many stem draw calls")
 g.objects[0].pos=Vector3(40,0,40);g.objects[0].node.position=g.objects[0].pos
 GardenClimbingSupport.refresh(g)
 check(climber.node.get_node_or_null("Vines")==null,"Climbing growth remained on a moved-away support")
 g.sun=DirectionalLight3D.new();g.add_child(g.sun)
 g.world_root=Node3D.new();g.add_child(g.world_root)
 g.touch=GardenTouch.new();g.add_child(g.touch);g.touch.g=g;g.touch.set_process(false)
 g.settings.render_scale=100
 g.touch.apply_graphics()
 check(is_equal_approx(root.scaling_3d_scale,1.0),"Auto graphics replaced an explicit 3D resolution")
 check(g.sun.directional_shadow_max_distance==40,"Dense Auto graphics did not limit distant shadows")
 g.settings.graphics="standard";g.touch.apply_graphics();g.plant_batches.update_detail()
 check(g.sun.directional_shadow_max_distance==90 and root.msaa_3d==Viewport.MSAA_2X,"Standard graphics lost its full shadow range or antialiasing")
 for renderer in g.plant_batches.get_children():check(renderer.cast_shadow==renderer.get_meta("full_shadow") and is_equal_approx(renderer.lod_bias,1.0),"Standard graphics did not restore full plant detail")
 g.settings.graphics="mobile";g.settings.render_scale=0;g.touch.apply_graphics()
 check(not g.sun.shadow_enabled and is_equal_approx(root.scaling_3d_scale,.7),"Mobile graphics changed unexpectedly")
 g.queue_free()
 await process_frame
 print("DENSE_GARDEN_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
