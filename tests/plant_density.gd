extends RefCounted

static func run(g, failures: Array) -> void:
 var old_planted=g.planted
 var old_open=g.unlocked_plots
 var old_layer=g.selected_layer
 var old_expansions=g.expansions.duplicate(true)
 var old_pose=[g.player.position,g.yaw,g.pitch,g.clock_time,g.hover_cell,g.hover_plot,g.hover_valid,g.current_plot,g.action_cooldown]
 var old_ui=g.ui.visible
 var old_mode=g.mode
 var old_selected=g.selected
 var old_moved=g.moved_index
 g.planted=[]
 g.unlocked_plots=g.plots.size()
 g.expansions={}
 for plot in range(g.plots.size()):
  if g.plot_capacity(plot)!=int(g.plots[plot].cap)*4: failures.append("Area capacity not doubled again")
  g.expansions[str(plot)]=2
  if g.plot_capacity(plot)!=int(g.plots[plot].cap)*4+160: failures.append("Saved expansions not doubled")
 g.expansions={}
 for plot in range(4):
  var center: Vector3=g.plots[plot].center
  for x in [-4.6,-.3,0.0,.3,4.6]:
   var hit=center+Vector3(x,0,x)
   var tree: Vector3=g.snap_to_bed(hit,plot,3)
   var flower: Vector3=g.snap_to_bed(hit,plot,1)
   if absf(tree.x-flower.x)<.001 or absf(tree.z-flower.z)<.001: failures.append("Canopy rows not offset")
   if g.bed_at(tree)!=plot or g.bed_at(flower)!=plot: failures.append("Offset escaped bed edge")
   if absf(tree.y-GardenTerrain.point(tree).y)>.001: failures.append("Canopy floats above terrain")
 # Groundcover must be able to use all 340 points; the old 225-cell grid could not.
 var slots={}
 for x in range(-11,12):
  for z in range(-11,12):
   var pos=g.snap_to_bed(g.plots[3].center+Vector3(x*g.GRID,0,z*g.GRID),3,0)
   slots[Vector2(pos.x,pos.z)]=true
 if slots.size()<450: failures.append("Plantable cells did not at least double")
 for i in range(340):
  var pos=g.snap_to_bed(g.plots[3].center+Vector3((i%23-11)*g.GRID,0,(int(i/23)-11)*g.GRID),3,0)
  if not g.can_plant(12,pos,3).is_empty(): failures.append("Groundcover cannot fill doubled capacity"); break
  g.planted.append({"id":12,"pos":pos,"plot":3})
 if g.capacity_used(3)!=340: failures.append("Groundcover budget not fully usable")
 g.planted=[]
 # Fill the largest bed with 48 trees, twice its old capacity of 24 trees.
 var center: Vector3=g.plots[3].center
 for i in range(48):
  var pos=g.snap_to_bed(center+Vector3((-10.5+(i%8)*3)*g.GRID,0,(-10.5+int(i/8)*3)*g.GRID),3,3)
  if not g.can_plant(28,pos,3).is_empty(): failures.append("Dense canopy rejected tree "+str(i)); break
  # Placement rules only need persisted data; avoid allocating 48 full canopies here.
  g.planted.append({"id":28,"pos":pos,"plot":3})
 if g.capacity_used(3)!=336: failures.append("Double canopy capacity not usable")
 if g.can_plant(28,g.snap_to_bed(center+Vector3(0,0,4),3,3),3).is_empty(): failures.append("Canopy exceeded budget")
 g.planted=[]
 var flower_pos=g.snap_to_bed(Vector3.ZERO,0,1)
 var tree_pos=g.snap_to_bed(Vector3.ZERO,0,3)
 g.planted.append({"id":0,"pos":flower_pos,"plot":0})
 g.planted.append({"id":20,"pos":flower_pos,"plot":0})
 if not g.can_plant(28,tree_pos,0).is_empty(): failures.append("Tree blocked by underplanting")
 g.planted.append({"id":28,"pos":tree_pos,"plot":0})
 if g.can_plant(28,tree_pos,0).is_empty(): failures.append("Duplicate tree accepted")
 if not g.can_plant(28,tree_pos,0,2).is_empty(): failures.append("Moving tree blocked by its old roots")
 g.selected_layer=3
 if g.target_plant(tree_pos)!=2: failures.append("Offset tree cannot be selected")
 g.planted[2].pos=flower_pos
 if g.target_plant(flower_pos)!=2: failures.append("Legacy tree cannot be selected")
 g.selected_layer=1
 if g.target_plant(flower_pos)!=0: failures.append("Layer targeting lost underplant")
 g.mode="move"
 g.moved_index=2
 if g.placement_layer()!=3: failures.append("Tree move lost canopy offset")
 g.mode="plant"
 g.selected=28
 if g.placement_layer()!=3: failures.append("Tree preview lost canopy offset")
 var outside=g.snap_plant_position(Vector3(-5.3,0,4.0),Vector3.ZERO,3,false)
 if not is_equal_approx(absf(fmod(outside.x/g.GRID,1)),.5): failures.append("Dry ground canopy not offset")
 # Render a real mixed bed exactly at 340 points, then exercise moving its tree.
 g.planted=[]
 for i in range(120):
  var pos=g.snap_to_bed(center+Vector3((i%15-7)*g.GRID,0,(int(i/15)-4)*g.GRID),3,1)
  g.add_plant([0,1,2,7,37][i%5],pos,3,100)
 for i in range(8):
  var pos=g.snap_to_bed(center+Vector3(-2.6+(i%4)*1.6,0,-2.6+int(i/4)*4),3,3)
  if not g.can_plant(45,pos,3).is_empty(): failures.append("Mixed canopy rejected")
  g.add_plant([45,29,30,31][i%4],pos,3,100)
 for i in range(10):
  var pos=g.snap_to_bed(center+Vector3(-2.4+(i%5)*1.2,0,-.8+int(i/5)*1.6),3,2)
  if not g.can_plant(22,pos,3).is_empty(): failures.append("Mixed shrub rejected")
  g.add_plant([20,22,39,41,25][i%5],pos,3,100)
 for i in range(4): g.add_plant(12,g.snap_to_bed(center+Vector3(i*.4,0,1.6),3,0),3,100)
 if g.capacity_used(3)!=340: failures.append("Mixed bed budget incorrect")
 g.mode="move"
 g.moved_index=120
 g.hover_cell=g.snap_to_bed(center+Vector3(-3.8,0,3.8),3,3)
 g.hover_plot=3
 g.hover_valid=true
 g.action_cooldown=0
 g.perform_action()
 if g.planted[120].pos.distance_to(g.hover_cell)>.001 or g.planted[120].marker.position.distance_to(g.hover_cell)>.001: failures.append("Offset tree move action failed")
 g.mode="walk"
 g.player.position=GardenTerrain.point(center+Vector3(0,0,5.8))+Vector3(0,.1,0)
 g.yaw=0
 g.pitch=.18
 g.clock_time=.4
 g.ui.hide()
 await g.get_tree().create_timer(1.2).timeout
 g.get_viewport().get_texture().get_image().save_png("res://captures/dense-layered-garden.png")
 print("DENSE_LAYERED_RENDER: fps=",Engine.get_frames_per_second()," plants=",g.planted.size()," capacity=",g.capacity_used(3))
 for p in g.planted:
  p.node.queue_free()
  p.marker.queue_free()
 g.player.position=old_pose[0]
 g.yaw=old_pose[1]
 g.pitch=old_pose[2]
 g.clock_time=old_pose[3]
 g.hover_cell=old_pose[4]
 g.hover_plot=old_pose[5]
 g.hover_valid=old_pose[6]
 g.current_plot=old_pose[7]
 g.action_cooldown=old_pose[8]
 g.ui.visible=old_ui
 g.planted=old_planted
 g.unlocked_plots=old_open
 g.selected_layer=old_layer
 g.expansions=old_expansions
 g.mode=old_mode
 g.selected=old_selected
 g.moved_index=old_moved
