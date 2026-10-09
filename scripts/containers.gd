class_name GardenContainers
extends RefCounted

const SPECS={
 "pot":{"slots":[Vector3(0,.55,0)],"layers":1,"height":1.25},
 "raised_bed":{"slots":[Vector3(-.60,.215,-.30),Vector3(0,.215,-.30),Vector3(.60,.215,-.30),Vector3(-.60,.215,.30),Vector3(0,.215,.30),Vector3(.60,.215,.30)],"layers":1,"height":2.1},
 "wide_bowl":{"slots":[Vector3(-.24,.27,0),Vector3(.24,.27,0)],"layers":0,"height":.65},
 "large_planter":{"slots":[Vector3(0,.74,0)],"layers":2,"height":1.85},
 "herb_trough":{"slots":[Vector3(-.45,.68,0),Vector3(0,.68,0),Vector3(.45,.68,0)],"layers":1,"height":.85},
 "hanging_basket":{"slots":[Vector3(0,1.20,0)],"layers":0,"height":.45},
 "vertical_planter":{"slots":[Vector3(-.40,.50,-.18),Vector3(.40,.50,-.18),Vector3(-.40,1.05,-.18),Vector3(.40,1.05,-.18),Vector3(-.40,1.60,-.18),Vector3(.40,1.60,-.18)],"layers":0,"height":.40},
 "tiered_planter":{"slots":[Vector3(-.35,.36,-.40),Vector3(.35,.36,-.40),Vector3(-.35,.86,0),Vector3(.35,.86,0),Vector3(-.35,1.36,.40),Vector3(.35,1.36,.40)],"layers":1,"height":.65}
}

static func object(g, uid: String) -> Dictionary:
 for obj in g.objects:
  if obj.get("uid","")==uid:return obj
 return {}

static func is_contained(p: Dictionary) -> bool:
 return not str(p.get("container_uid","")).is_empty()

static func tool_covers(g, p: Dictionary, ground_covered: bool) -> bool:
 if not g.hover_container_uid.is_empty():
  return p.get("container_uid","")==g.hover_container_uid and int(p.get("container_slot",-1))==g.hover_container_slot
 return ground_covered and not is_contained(p)

static func occupant(g, obj: Dictionary, slot: int, excluding: int=-1) -> int:
 return g.plant_index.occupant(g.planted,str(obj.uid),slot,excluding)

static func spec(obj: Dictionary) -> Dictionary:
 var result: Dictionary=SPECS[obj.kind].duplicate(true)
 var data=GardenAreaFurnishings.extras(obj)
 if data.has("fixture_soil"):result.slots=[Vector3(0,float(data.fixture_soil),0)]
 if str(obj.get("area_fixture","")).begins_with("glasshouse:basket"):
  result.layers=0;result.height=.45
 return result

static func position(obj: Dictionary, slot: int) -> Vector3:
 return obj.node.to_global(spec(obj).slots[slot])

static func can_plant(g, obj: Dictionary, slot: int, id: int, excluding: int=-1, form_uid: String="") -> String:
 if obj.kind not in SPECS or slot<0 or slot>=SPECS[obj.kind].slots.size():return "Choose a planting pocket."
 if not GardenAreaCatalogue.plot_open(g,g.nearest_plot(obj.pos)):return "Choose a planter in an open garden area."
 var data=g.catalogue[id]
 var spec=spec(obj)
 var collection_slot=GardenAreaFurnishings.collection_slot(obj)
 if collection_slot>=0 and GardenAreas.state(g,6).beds.has(str(collection_slot)):return "Clear this collection pocket in Garden atlas before sowing ordinary seeds here."
 var form=GardenPlantBreeding.form(g,form_uid)
 if int(data.layer)>int(spec.layers) or float(data.height)*GardenPlantBreeding.height_factor(form)>float(spec.height):return "This plant needs a larger planter or open soil."
 if occupant(g,obj,slot,excluding)>=0:return "This pocket already has a plant."
 return ""

static func plant(g, obj: Dictionary, slot: int, id: int, form_uid: String="") -> Dictionary:
 var error=can_plant(g,obj,slot,id,-1,form_uid)
 if not error.is_empty():g.toast(error);return {}
 var p=g.add_plant(id,obj.pos,g.nearest_plot(obj.pos),0,1.0 if not form_uid.is_empty() else 0.0,NAN,-1,form_uid)
 attach(g,p,obj,slot)
 GardenEquipment.starter(g,p)
 g.planted_total+=1;GardenSeedCollection.record_planting(g,id)
 GardenPlantBreeding.record_planting(g,form_uid)
 GardenAreaProgression.refresh(g)
 return p

static func attach(g, p: Dictionary, obj: Dictionary, slot: int) -> void:
 p["container_uid"]=obj.uid;p["container_slot"]=slot
 p.pos=position(obj,slot);p.plot=g.nearest_plot(obj.pos)
 p.node.position=p.pos;p.marker.position=p.pos
 p.node.set_meta("terrain_anchor",false)
 g.plant_index.invalidate()
 if is_instance_valid(g.plant_batches):g.plant_batches.invalidate()

static func move_plant(g, index: int, obj: Dictionary, slot: int) -> String:
 var p=g.planted[index]
 if not GardenAreaProgression.allowed(g,p.pos):return "This garden has not reached its milestone yet."
 var error=can_plant(g,obj,slot,int(p.id),index,str(p.get("form_uid","")))
 if not error.is_empty():return error
 attach(g,p,obj,slot)
 return ""

static func detach(p: Dictionary) -> void:
 p.erase("container_uid");p.erase("container_slot")
 p.node.set_meta("terrain_anchor",true)

static func sync(g, obj: Dictionary={}) -> void:
 for p in g.planted:
  if not is_contained(p):continue
  if not obj.is_empty() and p.container_uid!=obj.uid:continue
  var planter=object(g,p.container_uid)
  if planter.is_empty() or planter.kind not in SPECS:continue
  attach(g,p,planter,int(p.container_slot))

static func record(p: Dictionary) -> Dictionary:
 var result={"orientation":p.node.rotation.y,"shape_seed":p.get("shape_seed",0),"prune_cuts":p.get("prune_cuts",0),"height_factor":p.height_factor,"id":p.id,"pos":[p.pos.x,p.pos.z],"plot":p.plot,"age":p.age,"water":p.water,"stress":p.stress,"pruned":p.get("pruned",0.0),"treatments":p.get("treatments",{}).duplicate(true)}
 if is_contained(p):result.merge({"container_uid":p.container_uid,"container_slot":p.container_slot})
 if p.has("watered_until"):result["watered_until"]=p.watered_until
 for field in ["area_training","area_graft","area_offset_day","form_uid","breeding_checked"]:
  if p.has(field):result[field]=p[field]
 return result

static func store(g, p: Dictionary, source: String="") -> void:
 var saved=record(p)
 saved.erase("container_uid");saved.erase("container_slot")
 saved["storage_source"]=source
 saved["storage_slot"]=int(p.get("container_slot",-1))
 g.workshop_state.nursery.append(saved)
 p.node.queue_free();p.marker.queue_free();g.planted.erase(p)
 g.plant_index.invalidate()
 if is_instance_valid(g.plant_batches):g.plant_batches.invalidate()

static func pack(g, obj: Dictionary) -> void:
 for p in g.planted.duplicate():
  if p.get("container_uid","")==obj.uid:store(g,p,obj.uid)

static func restore_record(g, saved: Dictionary) -> Dictionary:
 var p=g.add_plant(int(saved.id),Vector3(saved.pos[0],0,saved.pos[1]),int(saved.plot),float(saved.age),float(saved.get("height_factor",1)),float(saved.get("orientation",0)),int(saved.get("shape_seed",0)),str(saved.get("form_uid","")))
 for key in ["water","stress","pruned","prune_cuts","treatments","watered_until","breeding_checked","area_training","area_graft","area_offset_day"]:
  if saved.has(key):p[key]=saved[key]
 if saved.has("container_uid"):
  var obj=object(g,str(saved.container_uid))
  if not obj.is_empty() and obj.kind in SPECS and int(saved.container_slot)<SPECS[obj.kind].slots.size():attach(g,p,obj,int(saved.container_slot))
 g.refresh_plant(p,false)
 return p

static func replant(g, nursery_index: int, obj: Dictionary, slot: int) -> bool:
 if nursery_index<0 or nursery_index>=g.workshop_state.nursery.size():return false
 var saved=g.workshop_state.nursery[nursery_index]
 var error=can_plant(g,obj,slot,int(saved.id),-1,str(saved.get("form_uid","")))
 if not error.is_empty():g.toast(error);return false
 var p=restore_record(g,saved)
 attach(g,p,obj,slot)
 g.workshop_state.nursery.remove_at(nursery_index)
 return true

# Pocket spheres make elevated planting reachable independently of the ground
# ray, including the upper pockets of vertical planters.
static func ray(g, origin: Vector3, direction: Vector3, ground: Vector3) -> Dictionary:
 var best={};var closest=8.0
 for obj in g.objects:
  if obj.kind not in SPECS:continue
  var slots: Array=spec(obj).slots
  var transform: Transform3D=obj.node.global_transform
  for slot in range(slots.size()):
   var pocket=transform*slots[slot]
   var center=pocket+Vector3(0,.12,0)
   # An occupant lifts the target by at most .32 m. Reject only pockets
   # that cannot intersect the ray or reach, including that full allowance.
   if g.player.position.distance_squared_to(center)>7.32*7.32:continue
   var offset=center-origin
   var along=offset.dot(direction)
   if along<-.32 or along>closest+.32:continue
   if (origin+direction*along).distance_squared_to(center)>.55*.55:continue
   var plant_index=occupant(g,obj,slot)
   if plant_index>=0:center.y+=minf(.32,float(g.catalogue[g.planted[plant_index].id].height)*.35)
   offset=center-origin
   along=offset.dot(direction)
   if along<0 or along>closest:continue
   if (origin+direction*along).distance_to(center)>.23:continue
   if ground.is_finite() and along>origin.distance_to(ground)+.15:continue
   if g.player.position.distance_to(center)>7:continue
   closest=along;best={"object":obj,"slot":slot,"plant":plant_index,"position":pocket}
 return best
