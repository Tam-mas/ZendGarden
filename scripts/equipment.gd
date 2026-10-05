class_name GardenEquipment
extends RefCounted

const KINDS=["compost_bays","worm_farm","mulch_bin","potting_bench","rain_barrel","shade_canopy","cold_frame","bird_feeder","hive","insect_hotel"]
const RECIPES={
 "compost":{"station":"compost_bays","name":"Garden compost","input":8,"days":2,"output":4,"cost":0,"hint":"+10% growth for four mornings"},
 "castings":{"station":"worm_farm","name":"Worm castings","input":6,"days":3,"output":4,"cost":0,"hint":"Eases stress now and slows its return for four mornings"},
 "mulch":{"station":"mulch_bin","name":"Leaf mulch","input":6,"days":1,"output":4,"cost":0,"hint":"Water lasts twice as long for six mornings"},
 "starter_mix":{"station":"potting_bench","name":"Starter mix","input":4,"days":1,"output":4,"cost":6,"hint":"New plants begin with 8% growth and a full drink"}
}

static func name_of(g, kind: String) -> String:
 for item in g.furniture:
  if item.kind==kind:return item.name
 return kind.capitalize()

static func setup(g, obj: Dictionary) -> void:
 if not obj.has("uid"):
  g.workshop_state.sequence+=1
  obj["uid"]="garden-%d"%int(g.workshop_state.sequence)
  while g.objects.any(func(other):return other!=obj and other.get("uid","")==obj.uid) or g.loaded_data.get("objects",[]).any(func(other):return other.get("uid","")==obj.uid):
   g.workshop_state.sequence+=1;obj.uid="garden-%d"%int(g.workshop_state.sequence)
 if not obj.has("work"):obj["work"]={}
 if obj.kind=="rain_barrel":
  obj.work.merge({"water":0.0,"irrigating":false,"upgraded":false},false)
 if obj.kind=="shade_canopy":obj.work.merge({"shade_on":true},false)
 if obj.kind=="cold_frame":obj.work.merge({"closed":true},false)
 if obj.kind=="bird_feeder":obj.work.merge({"feed_until":0},false)
 visual(g,obj)

static func visual(g, obj: Dictionary) -> void:
 var changed=false
 if obj.kind=="cold_frame":
  var lid=obj.node.find_child("ColdFrameLid*",true,false)
  if lid:
   var angle=0.0 if obj.work.get("closed",true) else -1.05
   changed=not is_equal_approx(lid.rotation.x,angle);lid.rotation.x=angle
 elif obj.kind=="shade_canopy":
  var cloth=obj.node.find_child("ShadeFabric*",true,false)
  if cloth:
   changed=cloth.visible!=obj.work.get("shade_on",true);cloth.visible=obj.work.get("shade_on",true)
 elif obj.kind=="bird_feeder":
  var food=obj.node.find_child("BirdFood*",true,false)
  if food:food.visible=int(obj.work.get("feed_until",0))>g.day
 if changed:GardenStructureTarget.refresh(obj.node)

static func recipe_for(kind: String) -> String:
 for key in RECIPES:
  if RECIPES[key].station==kind:return key
 return ""

static func spare(g, produce_only: bool=false) -> Dictionary:
 var result={}
 for key in g.inventory:
  var id=int(key)
  if produce_only and g.catalogue[id].category!="Produce":continue
  var reserved=0
  for order in g.orders:
   if not order.get("pending",false) and int(order.plant)==id:reserved+=int(order.count)
  var amount=maxi(0,int(g.inventory[key])-reserved)
  if amount>0:result[str(id)]=amount
 return result

static func spare_count_for(g,id: int) -> int:
 return int(spare(g).get(str(id),0))

static func spare_count(g, produce_only: bool=false) -> int:
 var total=0
 for count in spare(g,produce_only).values():total+=int(count)
 return total

static func consume(g, amount: int, produce_only: bool=false) -> bool:
 if spare_count(g,produce_only)<amount:return false
 var available=spare(g,produce_only)
 for id in range(g.catalogue.size()):
  var key=str(id)
  var taken=mini(amount,int(available.get(key,0)))
  if taken>0:g.inventory[key]=int(g.inventory[key])-taken;amount-=taken
  if amount==0:break
 return true

static func jobs(g, uid: String) -> Array:
 return g.workshop_state.jobs.filter(func(job):return job.station==uid)

static func start(g, obj: Dictionary) -> bool:
 var key=recipe_for(obj.kind)
 if key.is_empty():return false
 var recipe=RECIPES[key]
 var slots=2 if obj.work.get("upgraded",false) else 1
 if jobs(g,obj.uid).size()>=slots:g.toast("This station is already preparing its next batch.");return false
 if g.coins<int(recipe.cost):g.toast("Preparing starter mix costs %d petals."%int(recipe.cost));return false
 if not consume(g,int(recipe.input),key=="castings"):
  g.toast("Gather %d spare %s first. Current neighbour requests are kept aside."%[int(recipe.input),"produce items" if key=="castings" else "harvest items"]);return false
 g.coins-=int(recipe.cost)
 g.workshop_state.jobs.append({"recipe":key,"station":obj.uid,"ready_day":g.day+int(recipe.days),"amount":int(recipe.output)})
 g.toast(recipe.name+" is resting until morning %d."%(g.day+int(recipe.days)))
 return true

static func upgrade(g, obj: Dictionary) -> bool:
 if obj.work.get("upgraded",false):return false
 if obj.kind!="rain_barrel" and recipe_for(obj.kind).is_empty():return false
 if g.coins<40:g.toast("This equipment upgrade costs 40 petals.");return false
 g.coins-=40;obj.price+=40;obj.work["upgraded"]=true
 g.toast("The barrel now stores 24 drinks." if obj.kind=="rain_barrel" else "A second batch can now rest at this station.")
 return true

static func feed(g, obj: Dictionary) -> bool:
 if obj.kind!="bird_feeder":return false
 if int(obj.work.get("feed_until",0))>g.day:g.toast("There is still food on the bird table.");return false
 if not consume(g,3):g.toast("Set aside three spare harvest items for the birds.");return false
 obj.work.feed_until=g.day+3
 visual(g,obj)
 g.refresh_wildlife();g.toast("A little food welcomes songbirds for three garden days.")
 return true

static func weather(g, rainfall: float, delta: float) -> void:
 if rainfall<=0:return
 for obj in g.objects:
  if obj.kind=="rain_barrel":obj.work.water=minf(24.0 if obj.work.get("upgraded",false) else 12.0,float(obj.work.get("water",0))+rainfall*delta/30.0)

static func morning(g) -> void:
 for job in g.workshop_state.jobs.duplicate():
  if int(job.ready_day)>g.day+1:continue
  var key=str(job.recipe)
  g.workshop_state.resources[key]=int(g.workshop_state.resources.get(key,0))+int(job.amount)
  g.workshop_state.jobs.erase(job)
 for obj in g.objects:
  if obj.kind!="rain_barrel" or not obj.work.get("irrigating",false):continue
  for p in g.planted:
   if str(p.get("container_uid","")).is_empty() or p.pos.distance_to(obj.pos)>4 or p.water>=3:continue
   if float(obj.work.water)<1:break
   obj.work.water-=1.0;p.water=4.0

static func near(g, p: Dictionary, kind: String, radius: float, active_key: String="") -> Dictionary:
 for obj in g.objects:
  if not active_key.is_empty() and not obj.work.get(active_key,true):continue
  if obj.kind==kind and Vector2(p.pos.x-obj.pos.x,p.pos.z-obj.pos.z).length()<=radius:return obj
 return {}

static func active(p: Dictionary, treatment: String, day: int) -> bool:
 return int(p.get("treatments",{}).get(treatment,0))>day

static func treat(g, p: Dictionary, key: String) -> bool:
 if key not in ["compost","castings","mulch"] or active(p,key,g.day):return false
 if int(g.workshop_state.resources.get(key,0))<=0:return false
 if not p.has("treatments"):p["treatments"]={}
 g.workshop_state.resources[key]-=1
 p.treatments[key]=g.day+(6 if key=="mulch" else 4)
 if key=="castings":p.stress=maxf(0,float(p.stress)-.35)
 return true

static func growth_multiplier(g, p: Dictionary, manual: float) -> float:
 if GardenContainers.is_contained(p):manual=1.2 if float(p.get("watered_until",0))>float(g.day+1)-.000001 else 1.0
 var bonus=.10 if active(p,"compost",g.day) else 0.0
 if g.catalogue[p.id].category=="Produce" and not near(g,p,"hive",4).is_empty():bonus+=.05
 return minf(1.30,manual+bonus)

static func water_pocket(g, p: Dictionary, amount: float=4.0) -> void:
 p.water=amount
 p["watered_until"]=GardenTools.now(g)+GardenTools.WATER_BOOST_DAYS
 g.care_effect(p.pos,Color("a8dce1"))

static func water_loss(g, p: Dictionary) -> float:
 return .5 if active(p,"mulch",g.day) else 1.0

static func stress_gain(g, p: Dictionary) -> float:
 var amount=.13-(.08 if active(p,"castings",g.day) else 0.0)
 if g.catalogue[p.id].category in ["Flowers","Produce"] and not near(g,p,"insect_hotel",3).is_empty():amount-=.04
 return maxf(0,amount)

static func starter(g, p: Dictionary) -> void:
 if not g.workshop_state.use_starter or int(g.workshop_state.resources.get("starter_mix",0))<1:return
 g.workshop_state.resources.starter_mix-=1
 p.age=float(g.catalogue[p.id].days)*.08;p.water=4.0
 g.refresh_plant(p,false)

static func status(g, obj: Dictionary) -> String:
 var queue=jobs(g,obj.uid)
 if not queue.is_empty():return "Batch ready morning %d"%int(queue[0].ready_day)
 if obj.kind=="rain_barrel":return "%.1f / %d drinks · %s"%[float(obj.work.water),24 if obj.work.get("upgraded",false) else 12,"watering planters" if obj.work.irrigating else "stored"]
 if obj.kind=="bird_feeder":return "Food until morning %d"%int(obj.work.feed_until) if int(obj.work.feed_until)>g.day else "Ready for a little food"
 if obj.kind=="shade_canopy":return "Shade open" if obj.work.shade_on else "Shade folded away"
 if obj.kind=="cold_frame":return "Lid closed · small plants grow out of season" if obj.work.closed else "Lid open"
 if obj.kind=="hive":return "Bees visit · nearby produce gets +5% growth"
 if obj.kind=="insect_hotel":return "Small visitors · nearby flowers and produce build stress more slowly"
 return "Ready to prepare a batch"
