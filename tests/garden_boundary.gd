extends RefCounted

static func cast(g,a: Vector3,b: Vector3) -> Dictionary:
 var ray=PhysicsRayQueryParameters3D.create(a,b);ray.exclude=[g.player.get_rid()]
 return g.get_world_3d().direct_space_state.intersect_ray(ray)

static func check_walls(g,failures: Array) -> void:
 var samples=0
 for segment in GardenBoundary.segments(g):
  var a: Vector2=segment[0];var b: Vector2=segment[1]
  var d=(b-a).normalized();var normal=Vector3(-d.y,0,d.x)
  var steps=ceili(a.distance_to(b)/.65)
  for j in range(steps):
   var p=a.lerp(b,(j+.5)/steps)
   var center=Vector3(p.x,GardenBoundary.ground(p)+.48,p.y)
   var hit=cast(g,center+normal*.9,center-normal*.9)
   if hit.is_empty():failures.append("Gap in garden boundary at "+str(p))
   samples+=1
 print("BOUNDARY_WALL_SAMPLES: ",samples)

static func run(g,failures: Array) -> void:
 check_walls(g,failures)
 # Side-facing rays must hit outward-facing rock, even far below the grass.
 for y in [-1.,-8.,-32.,-60.]:
  for z in [-100.,-73.,-49.,-32.]:
   for side in [[12.,32.,-1.],[108.,84.,1.]]:
    var hit=cast(g,Vector3(side[0],y,z),Vector3(side[1],y,z))
    if hit.is_empty() or hit.normal.x*side[2]<=0.:failures.append("Open or reversed rock face "+str(Vector3(side[0],y,z))+": "+str(hit))
  for x in [29.,42.,60.,85.]:
   var hit=cast(g,Vector3(x,y,28.),Vector3(x,y,0.))
   if hit.is_empty() or hit.normal.z<.65:failures.append("Open southern foundation "+str(Vector2(x,y)))
 # Former blockage: full walking width has paving, not a head-high wall.
 for z in range(-27,-21):
  for x in [26.4,27.,27.6]:
   var p=Vector3(x,0,z);var hit=cast(g,p+Vector3.UP*5,p+Vector3.DOWN*5)
   if hit.is_empty() or absf(hit.position.y-GardenAreaTransitions.trail_height(p))>.015:failures.append("Old wall obstructs path "+str(p))
 # Both long edges of all landing aprons meet their deck without a lip.
 for z in GardenRavine.BRIDGES:
  for x in [26.4,27.,27.6]:
   for side in ([-1.] if z==6. else [1.] if z==-102. else [-1.,1.]):
    var p=Vector3(x,0,z+side*1.401);var hit=cast(g,p+Vector3.UP*5,p+Vector3.DOWN*5)
    if hit.is_empty() or absf(hit.position.y-GardenRavine.deck(x,z))>.02:failures.append("Unfitted bank apron "+str(p))
  for side in [-.7,0.,.7]:
   var p=Vector3(44.01,0,z+side);var hit=cast(g,p+Vector3.UP*5,p+Vector3.DOWN*5)
   if hit.is_empty() or absf(hit.position.y-GardenRavine.deck(44,z))>.02:failures.append("Unfitted east landing "+str(p))
 # Shaping adjacent earth must not detach the garden from its fixed cliff.
 GardenSculpt.restore(g,{"91:-60":1.2,"92:-60":1.2,"60:11":1.2,"24:6":.8,"25:6":.8})
 await g.get_tree().physics_frame
 for p in [Vector3(92,0,-60),Vector3(60,0,12),Vector3(25.5,0,6)]:
  if absf(GardenTerrain.offset_at(p.x,p.z))>.001:failures.append("Sculpted foundation seam "+str(p))
 if not GardenTerrain.offsets.has("91:-60") or not GardenTerrain.offsets.has("24:6"):failures.append("Edge repair discarded saved terrain")
 check_walls(g,failures)
 GardenSculpt.restore(g,{})
 await g.get_tree().physics_frame
 # Falling water stays just outside the rock face down to lake level.
 var stream=GardenRavine.stream(12.)
 for y in [-8.,-16.,-32.,-60.]:
  var top=GardenRavine.ground(stream.x,12.);var level=(top-y)/(top+66.)*66.
  var z=12.+GardenRavine.cliff_outset(stream.x,12.,level)+.065
  var hit=cast(g,Vector3(stream.x,y,z+2),Vector3(stream.x,y,z-1))
  if hit.is_empty() or hit.position.z>z:failures.append("Waterfall buried in cliff "+str(y))
 # Perimeter growth removes the old rear fence, leaving the existing route
 # open. Restore the small starting garden for the review captures afterwards.
 var old_plots=g.plots.duplicate(true);var old_unlocked=g.unlocked_plots
 g.unlocked_plots=12;GardenExpansion.prepare(g)
 for row in range(2,int(GardenAreaCatalogue.legacy_plot_count(g)/2)):GardenExpansion.build_row(g,row)
 await g.get_tree().physics_frame
 check_walls(g,failures)
 var north=-float(GardenAreaCatalogue.legacy_plot_count(g)/2-1)*17.-8.5
 for x in [0.,8.,17.,24.]:
  if cast(g,Vector3(x,-5.,north-3.),Vector3(x,-5.,north+2.)).is_empty():failures.append("Open growing-garden foundation")
 var a=GardenTerrain.point(Vector3(17,0,-24));a.y+=.48
 if not cast(g,a,a+Vector3(0,0,-3)).is_empty():failures.append("Growing rear wall blocks next garden row")
 for row in range(2,int(GardenAreaCatalogue.legacy_plot_count(g)/2)):
  var root=g.world_root.get_node_or_null("GrowingRow%d"%row)
  if root:
   g.terrain_meshes=g.terrain_meshes.filter(func(e):return is_instance_valid(e.node) and not root.is_ancestor_of(e.node))
   g.terrain_anchors=g.terrain_anchors.filter(func(e):return is_instance_valid(e.node) and not root.is_ancestor_of(e.node))
   g.world_root.remove_child(root);root.free()
 g.plots=old_plots;g.unlocked_plots=old_unlocked;GardenBoundary.build(g)
 print("BOUNDARY_RESULT: ",failures)
