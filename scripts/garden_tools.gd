class_name GardenTools
extends RefCounted

const WATER_BOOST_DAYS=1.0
const PRUNE_BASE=1.3
const PRUNE_MIN=.4
const HOE_WIDTH=3.0

static func now(g) -> float:
 return float(g.day)+g.clock_time

static func prune_max(g) -> float:
 return PRUNE_BASE*pow(1.1,int(g.upgrades.shears))

static func prune_width(g) -> float:
 return clampf(g.prune_width,PRUNE_MIN,prune_max(g))

static func in_square(a: Vector3,b: Vector3,width: float) -> bool:
 return absf(a.x-b.x)<=width*.5+.0001 and absf(a.z-b.z)<=width*.5+.0001

static func resize_pruners(g, direction: int) -> void:
 if g.mode!="prune" or g.photo_mode or g.day_transition: return
 g.prune_width=clampf(prune_width(g)+direction*PRUNE_BASE*.1,PRUNE_MIN,prune_max(g))
 g.toast("Pruning square: %.2f m · purchased limit %.2f m"%[g.prune_width,prune_max(g)])
 g.update_hud()

static func toggle_hoe(g) -> void:
 if g.mode!="hoe" or g.photo_mode or g.day_transition: return
 g.hoe_raise=not g.hoe_raise
 g.toast("Hoe: "+("raise" if g.hoe_raise else "lower")+" ground. R switches direction.")
 g.update_hud()

static func water_ground(g, center: Vector3, radius: float) -> void:
 var key="%d:%d"%[roundi(center.x/g.GRID),roundi(center.z/g.GRID)]
 g.watered_ground[key]={"x":center.x,"z":center.z,"radius":radius,"until":now(g)+WATER_BOOST_DAYS}
 water_patch(g,key)
 g.care_effect(GardenTerrain.point(center),Color("a8dce1"))

static func boost_until(g, pos: Vector3) -> float:
 var until=0.0
 for patch in g.watered_ground.values():
  if Vector2(pos.x-float(patch.x),pos.z-float(patch.z)).length()<=float(patch.radius): until=maxf(until,float(patch.until))
 return until

static func growth_multiplier(g, pos: Vector3, at_time: float) -> float:
 return 1.2 if boost_until(g,pos)>at_time else 1.0

static func expire_water(g) -> void:
 for key in g.watered_ground.keys():
  if float(g.watered_ground[key].until)<=now(g):
   g.watered_ground.erase(key)
   if g.wet_nodes.has(key):
    if is_instance_valid(g.wet_nodes[key]):g.wet_nodes[key].queue_free()
    g.wet_nodes.erase(key)

static func water_patch(g, key: String) -> void:
 if g.wet_nodes.has(key) and is_instance_valid(g.wet_nodes[key]):g.wet_nodes[key].queue_free()
 var patch: Dictionary=g.watered_ground[key]
 var center=Vector3(float(patch.x),0,float(patch.z))
 var radius=float(patch.radius)
 var surface=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 # Tessellation follows slopes and later hoe edits; no floating flat decals.
 for ring in range(4):
  for sector in range(24):
   var a=sector*TAU/24;var b=(sector+1)*TAU/24
   var points=[center+Vector3(cos(a),0,sin(a))*radius*ring/4.0,center+Vector3(cos(b),0,sin(b))*radius*ring/4.0,center+Vector3(cos(b),0,sin(b))*radius*(ring+1)/4.0,center+Vector3(cos(a),0,sin(a))*radius*(ring+1)/4.0]
   for index in [0,2,1,0,3,2]:
    var v: Vector3=points[index]
    surface.add_vertex(GardenTerrain.point(v)+Vector3(0,.032,0))
 surface.generate_normals()
 var node=MeshInstance3D.new()
 node.mesh=surface.commit()
 node.material_override=GardenArt.mat(Color(.11,.18,.10,.22),.97)
 node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 g.world_root.add_child(node)
 g.wet_nodes[key]=node

static func restore_water(g, saved: Dictionary) -> void:
 for node in g.wet_nodes.values():
  if is_instance_valid(node):node.queue_free()
 g.wet_nodes.clear()
 g.watered_ground.clear()
 for key in saved:
  var patch=saved[key]
  if not patch is Dictionary:continue
  if not patch.has_all(["x","z","radius","until"]):continue
  if not is_finite(float(patch.x)) or not is_finite(float(patch.z)):continue
  var until=minf(float(patch.until),now(g)+WATER_BOOST_DAYS)
  if until<=now(g):continue
  g.watered_ground[str(key)]={"x":float(patch.x),"z":float(patch.z),"radius":clampf(float(patch.radius),.1,4.0),"until":until}
  water_patch(g,str(key))

static func cursor(g, center: Vector3, width: float, circle: bool) -> void:
 var stamp=[center,width,circle,g.terrain_revision]
 if g.area_cursor.get_meta("stamp",[])!=stamp:
  g.area_cursor.set_meta("stamp",stamp)
  var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
  var corners=[Vector3(-1,0,-1),Vector3(1,0,-1),Vector3(1,0,1),Vector3(-1,0,1)]
  for i in range(64):
   var points=[]
   for j in [i,i+1]:
    var direction: Vector3
    if circle:direction=Vector3(cos(j*TAU/64),0,sin(j*TAU/64))
    else:direction=corners[(j/16)%4].lerp(corners[((j/16)+1)%4],float(j%16)/16)
    for inset in [0.0,.035]:points.append(GardenTerrain.point(center+direction*(width*.5-inset))+Vector3(0,.055,0))
   for k in [0,2,1,1,2,3]:st.add_vertex(points[k])
  st.generate_normals()
  g.area_cursor.mesh=st.commit()
 g.grid_cursor.hide()
 g.area_cursor.show()
