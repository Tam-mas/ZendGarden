class_name GardenAreaFurnishings
extends RefCounted

static var templates: Dictionary={}
const BENCHES=[Vector3(6,0,3),Vector3(-5,0,7),Vector3(2,0,6.5),Vector3(6,0,5),Vector3(-6,0,6),Vector3(5.5,0,-5.8),Vector3(0,0,-4.6),Vector3(-5,0,5),Vector3(-2,0,-7),Vector3(3.8,0,6)]
const FOCUS=[Vector3(-1.4,0,0),Vector3(0,0,4),Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3.ZERO,Vector3(0,0,3),Vector3(-2,0,-20),Vector3(-1,0,0)]

static func valid_id(id: String,kind: String) -> bool:
 if id=="orchard:table":return kind=="harvest_table"
 if id=="alpine:chime":return kind=="wind_chime"
 if id=="moon:pergola":return kind=="pergola"
 for j in range(3):
  if id=="moon:lamp%d"%j:return kind=="lantern"
 for j in range(2):
  if id=="kitchen:pot%d"%j:return kind=="pot"
  if id=="glasshouse:shelf%d"%j:return kind=="nursery_shelf"
  for k in range(3):
   if id=="glasshouse:basket%d%d"%[j,k]:return kind=="pot"
 for j in range(6):
  if id=="glasshouse:pot%d"%j:return kind=="pot"
 return false

static func collision(node: Node,enabled: bool) -> void:
 if node is StaticBody3D:node.collision_layer=1 if enabled else 0
 for child in node.get_children():collision(child,enabled)

static func register(node: Node,index: int) -> void:
 var extras: Dictionary=node.get_meta("extras",{})
 if extras.has("fixture_id"):
  var id=str(extras.fixture_id)
  templates[id]={"node":node,"index":index,"kind":str(extras.fixture_kind),"pos":node.global_position,"extras":extras}
  node.visible=false;node.set_meta("fixture_template",true);collision(node,false)
  return
 for child in node.get_children():register(child,index)

static func instantiate(id: String) -> Node3D:
 if not templates.has(id):return null
 var node: Node3D=templates[id].node.duplicate()
 node.visible=true;node.remove_meta("fixture_template");collision(node,true)
 return node

static func object(g,id: String) -> Dictionary:
 for obj in g.objects:
  if obj.get("area_fixture","")==id:return obj
 return {}

static func node(g,id: String) -> Node3D:
 var obj=object(g,id)
 return obj.node if not obj.is_empty() else null

static func heading(index: int) -> float:
 var direction=FOCUS[index]-BENCHES[index]
 return atan2(-direction.x,-direction.z)

static func ordinary(index: int) -> Array:
 var result=[] if index==8 else [{"id":"bench","kind":"bench","pos":BENCHES[index],"rotation":heading(index)}]
 if index==2:
  for j in range(4):result.append({"id":"pot%d"%j,"kind":"wide_bowl" if j%2==0 else "pot","pos":Vector3([-4.5,4.1,3.3,-4.4][j],0,[6,-6.8,1.5,-2.8][j]),"rotation":0.0})
 if index==5:
  for j in range(2):result.append({"id":"vertical%d"%j,"kind":"vertical_planter","pos":Vector3(-5.6 if j==0 else 5.6,0,-6.1),"rotation":PI})
  result.append({"id":"trough","kind":"herb_trough","pos":Vector3(0,0,-5.6),"rotation":0.0})
 return result

static func add_template(g,id: String) -> void:
 var spec=templates[id];var pos: Vector3=spec.pos
 var elevation=pos.y-GardenTerrain.point(pos).y
 g.add_object(spec.kind,pos,0,false,0.0,"My garden",Color("f1e5c7"),{"area_fixture":id,"elevation":elevation,"starter_orientation_version":1})
 restore_collection(g,g.objects.back())

static func remove_hillside_bench(g) -> void:
 # Retire only the untouched free alpine seat, including saves predating IDs.
 # A seat moved or rotated by the player remains their furniture.
 var original=GardenAreaCatalogue.center(8)+BENCHES[8]
 for obj in g.objects.duplicate():
  if obj.kind!="bench" or int(obj.price)!=0:continue
  if obj.get("starter_id","") not in ["","alpine:starter-bench"]:continue
  if Vector2(obj.pos.x-original.x,obj.pos.z-original.z).length()>.05:continue
  if absf(angle_difference(float(obj.rotation),heading(8)))>.01 and not is_zero_approx(float(obj.rotation)):continue
  obj.node.queue_free();g.objects.erase(obj)

static func restore(g) -> void:
 remove_hillside_bench(g)
 for index in range(10):
  var s=GardenAreas.state(g,index)
  if s.furniture_initialized:continue
  for stock in ordinary(index):
   var pos=GardenTerrain.point(GardenAreaCatalogue.center(index)+stock.pos)
   var id=GardenAreaCatalogue.entry(index).kind+":starter-"+stock.id
   var existing={}
   for obj in g.objects:
    if obj.kind==stock.kind and int(obj.price)==0 and Vector2(obj.pos.x-pos.x,obj.pos.z-pos.z).length()<.05:existing=obj;break
   if not existing.is_empty():
    existing["starter_id"]=id
    if not existing.has("starter_orientation_version"):
     if is_zero_approx(float(existing.rotation)):
      existing["orientation_repair_delta"]=float(stock.rotation)
      existing.rotation=stock.rotation;existing.node.rotation.y=stock.rotation
      for plant in g.planted:
       if plant.get("container_uid","")==existing.uid:plant.node.rotation.y+=float(stock.rotation)
      GardenContainers.sync(g,existing)
     existing["starter_orientation_version"]=1
   elif not s.initialized:
    g.add_object(stock.kind,pos,0,false,float(stock.rotation),"My garden",Color("f1e5c7"),{"starter_id":id,"starter_orientation_version":1})
  for id in templates:
   if int(templates[id].index)==index and object(g,id).is_empty():add_template(g,id)
  s.furniture_initialized=true

static func restore_missing(g,index: int) -> void:
 if not GardenAreaProgression.unlocked(g,index):return
 var count=0
 for stock in ordinary(index):
  var id=GardenAreaCatalogue.entry(index).kind+":starter-"+stock.id
  if g.objects.any(func(obj):return obj.get("starter_id","")==id):continue
  var pos=GardenTerrain.point(GardenAreaCatalogue.center(index)+stock.pos)
  if g.object_at(pos)>=0:continue
  g.add_object(stock.kind,pos,0,false,float(stock.rotation),"My garden",Color("f1e5c7"),{"starter_id":id,"starter_orientation_version":1});count+=1
 for id in templates:
  if int(templates[id].index)==index and object(g,id).is_empty():
   if g.object_at(templates[id].pos)>=0:continue
   add_template(g,id);count+=1
 g.toast("Restored %d starter objects in clear spaces."%count)

static func extras(obj: Dictionary) -> Dictionary:
 return templates.get(str(obj.get("area_fixture","")),{}).get("extras",{})

static func collection_slot(obj: Dictionary) -> int:
 return int(extras(obj).get("collection_slot",-1))

static func placement(g,kind: String,pos: Vector3,excluding: Dictionary={}) -> Vector3:
 var ground=GardenTerrain.point(pos)
 if kind not in ["pot","wide_bowl","herb_trough"]:return ground
 for shelf in g.objects:
  if shelf==excluding or shelf.kind!="nursery_shelf":continue
  var local: Vector3=shelf.node.to_local(ground)
  if absf(local.x)>.42 or absf(local.z)>4.0:continue
  return shelf.node.to_global(Vector3(local.x,.92,local.z))
 return ground

static func removal_snapshot(g,obj: Dictionary) -> Dictionary:
 var supported={}
 for pot in g.objects:
  if obj.kind=="nursery_shelf" and pot.kind in ["pot","wide_bowl","herb_trough"] and shelf_supports(obj,pot):
   supported[pot.uid]={"pos":pot.pos,"elevation":float(pot.get("elevation",0)),"rotation":float(pot.rotation)}
 return supported

static func restore_dependents(g,supported: Dictionary) -> void:
 for uid in supported:
  var pot=GardenContainers.object(g,uid);var saved=supported[uid]
  if pot.is_empty() or Vector2(pot.pos.x-saved.pos.x,pot.pos.z-saved.pos.z).length()>.05:continue
  pot.pos=saved.pos;pot.elevation=saved.elevation;pot.rotation=saved.rotation
  pot.node.position=pot.pos;pot.node.rotation.y=pot.rotation;GardenContainers.sync(g,pot)
 GardenAreas.visual_collection(g,6)

static func before_remove(g,obj: Dictionary) -> void:
 var slot=collection_slot(obj)
 if slot>=0:
  var s=GardenAreas.state(g,6);var key=str(slot)
  if s.beds.has(key):s.packed_beds[key]=s.beds[key].duplicate(true);s.beds.erase(key)
  GardenAreas.visual_collection(g,6)
 # Pots remain owned when their shelf is packed; lower them gently to the floor.
 for pot in g.objects:
  if obj.kind!="nursery_shelf" or pot.kind not in ["pot","wide_bowl","herb_trough"]:continue
  if not shelf_supports(obj,pot):continue
  pot.elevation=0.0;pot.pos=GardenTerrain.point(pot.pos);pot.node.position=pot.pos
  GardenContainers.sync(g,pot)
 GardenAreas.visual_collection(g,6)
 if obj.get("area_fixture","")=="alpine:chime":g.area_roots[8].get_node("ChimeVoice").stop()

static func shelf_supports(shelf: Dictionary,pot: Dictionary) -> bool:
 var local: Vector3=shelf.node.to_local(pot.pos)
 return absf(local.x)<.58 and absf(local.z)<4.5 and absf(local.y-.92)<.1

static func before_move(g,obj: Dictionary) -> void:
 # Carry the pots supported by a shelf with its translation and rotation.
 obj["carried_pots"]={}
 for pot in g.objects:
  if obj.kind=="nursery_shelf" and pot.kind in ["pot","wide_bowl","herb_trough"] and shelf_supports(obj,pot):
   obj.carried_pots[pot.uid]={"local":obj.node.to_local(pot.pos),"rotation":float(pot.rotation)-float(obj.rotation)}

static func after_move(g,obj: Dictionary) -> void:
 for uid in obj.get("carried_pots",{}):
  var pot=GardenContainers.object(g,uid)
  if pot.is_empty():continue
  var saved=obj.carried_pots[uid];pot.pos=obj.node.to_global(saved.local)
  pot.elevation=pot.pos.y-GardenTerrain.point(pot.pos).y;pot.node.position=pot.pos
  var previous_rotation=float(pot.rotation)
  pot.rotation=float(obj.rotation)+float(saved.rotation);pot.node.rotation.y=pot.rotation
  for plant in g.planted:
   if plant.get("container_uid","")==pot.uid:plant.node.rotation.y+=float(pot.rotation)-previous_rotation
  GardenContainers.sync(g,pot)
 obj.erase("carried_pots")
 GardenAreas.visual_collection(g,6)

static func restore_collection(g,obj: Dictionary) -> void:
 var slot=collection_slot(obj)
 if slot<0:return
 var s=GardenAreas.state(g,6);var key=str(slot)
 if s.packed_beds.has(key) and not s.beds.has(key):s.beds[key]=s.packed_beds[key];s.packed_beds.erase(key)
 GardenAreas.visual_collection(g,6)
