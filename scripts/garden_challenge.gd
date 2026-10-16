class_name GardenChallenge
extends RefCounted

# All Challenge-only simulation lives here. Free Garden never enters these rules.
const PATCH_SIZE=2.0
const RULES_VERSION=1
const EQUIPMENT=["reserve_tank","planter_drip","soaker_controller"]
const SUPPLIES=["rain_barrel","reserve_tank"]
const WATER_OVERRIDES={1:0,5:2,12:0,13:2,16:2,20:1,22:0,25:0,26:2,31:0,32:2,44:0,47:2,48:2,49:2,50:2,54:2,56:2,59:2}

static func active(g) -> bool:
 return g.get("garden_mode")=="challenge"

static func initial_state() -> Dictionary:
 return {"rules":RULES_VERSION,"seed":829731,"patches":{},"trimmings":0,"season":-1,"offers":[],"request":{},"completed":[],"intro":0,"starter_claimed":false,"report":"Welcome to Challenge Garden. Start with a small planting and four portions of mulch."}

static func setup(g) -> void:
 if not active(g):return
 if g.loaded_data.is_empty():
  g.workshop_state.resources.mulch=4
  g.settings.intro_seen=true
  g.settings.updates_seen=GardenUpdates.CURRENT_VERSION
  g.settings.pause_menus=true
  g.orders=[]
  g.make_orders()
 sync_patches(g)
 offers(g)
 g.challenge.report=summary(g)
 rebuild(g)

static func patch_key(pos: Vector3, plot: int) -> String:
 return "%d:%d:%d"%[plot,floori(pos.x/PATCH_SIZE),floori(pos.z/PATCH_SIZE)]

static func center(key: String) -> Vector3:
 var parts=key.split(":")
 return Vector3((int(parts[1])+.5)*PATCH_SIZE,0,(int(parts[2])+.5)*PATCH_SIZE)

static func key_for(p: Dictionary) -> String:
 return "pot:"+str(p.container_uid) if GardenContainers.is_contained(p) else patch_key(p.pos,int(p.plot))

static func sync_patches(g) -> void:
 for p in g.planted:
  if GardenContainers.is_contained(p):continue
  var key=key_for(p)
  if not g.challenge.patches.has(key):
   g.challenge.patches[key]={"plot":int(p.plot),"weed":0,"weed_age":0,"mulch_until":0,"clear_until":0,"last_spawn":0}

static func water_class(data: Dictionary) -> int:
 var id=int(data.id)
 if WATER_OVERRIDES.has(id):return int(WATER_OVERRIDES[id])
 if data.category=="Cacti & succulents":return 0
 if data.category=="Produce" or data.condition=="water" or "fern" in str(data.name).to_lower():return 2
 return 1

static func water_label(data: Dictionary) -> String:
 return ["Low","Moderate","High"][water_class(data)]+" water needs"

static func mulched(g,p: Dictionary) -> bool:
 if GardenContainers.is_contained(p):
  var obj=GardenContainers.object(g,p.container_uid)
  return not obj.is_empty() and int(obj.work.get("mulch_until",0))>g.day
 return int(g.challenge.patches.get(key_for(p),{}).get("mulch_until",0))>g.day

static func loss(g,p: Dictionary) -> float:
 if g.growth_conditions(p)<=0:return 0.0
 var amount=[.5,1.0,1.5][water_class(g.catalogue[p.id])]
 amount*=1.25 if GardenClimate.season(g.day)=="Summer" else .75 if GardenClimate.season(g.day)=="Winter" else 1.0
 if GardenContainers.is_contained(p):amount*=1.25
 if mulched(g,p):amount*=.5
 var weather=weather_for(g,g.day)
 if weather in ["Cloudy","Mist"]:amount*=.85
 return GardenAreas.water_loss(g,p,amount)

static func condition(p: Dictionary) -> String:
 if int(p.get("dry_days",0))>=3:return "Resting from dryness"
 return "Wilting" if p.water<.5 else "Thirsty" if p.water<2 else "Comfortable"

static func rate(g,p: Dictionary) -> float:
 if int(p.get("dry_days",0))>=3 or p.water<.5:return 0.0
 var value=.6 if p.water<2 else 1.0
 var patch=g.challenge.patches.get(key_for(p),{})
 return value*(.75 if int(patch.get("weed",0))==3 else .85 if int(patch.get("weed",0))==2 else 1.0)

static func water(g,p: Dictionary) -> void:
 p.water=4.0
 if int(p.get("dry_days",0))<3:p["dry_days"]=0
 if int(g.challenge.intro)==0:g.challenge.intro=1

static func weather_for(g,day: int) -> String:
 if day<=3:return ["Clear","Cloudy","Rain"][day-1]
 # Authored opening; stateless schedule is invariant under reload and time skip.
 if day<=7:return ["Clear","Clear","Cloudy","Rain"][day-4]
 var value=posmod(int(g.challenge.seed)+day*1103515245+int(day/4)*12345,100)
 return "Snow" if value<22 and GardenClimate.season(day)=="Winter" else "Rain" if value<22 else "Cloudy" if value<42 else "Mist" if value<50 else "Clear"

static func rain_reaches(g,p: Dictionary) -> bool:
 if not GardenAreas.rain_reaches(g,p):return false
 return GardenEquipment.near(g,p,"greenhouse",4).is_empty()

static func morning(g) -> void:
 sync_patches(g)
 var rain=weather_for(g,g.day)=="Rain"
 for p in g.planted:
  if not GardenAreaProgression.allowed(g,p.pos):continue
  if g.growth_conditions(p)<=0:continue
  p.water=maxf(0,float(p.water)-loss(g,p))
  if rain and rain_reaches(g,p):p.water=minf(4,p.water+2)
  if g.catalogue[p.id].condition=="water" and g.plots[p.plot].condition=="water":p.water=4.0
 for obj in g.objects:
  if obj.kind in SUPPLIES:
   if rain:obj.work.water=minf(capacity(obj),float(obj.work.get("water",0))+8)
 irrigate(g)
 for p in g.planted:
  if g.growth_conditions(p)<=0:continue
  if p.water<.5:p["dry_days"]=mini(3,int(p.get("dry_days",0))+1)
  elif p.water>=2:p["dry_days"]=0

static func after_morning(g) -> void:
 var expired=not g.challenge.request.is_empty() and g.day>int(g.challenge.request.deadline)
 weeds(g)
 offers(g)
 g.challenge.report=("Seasonal basket expired; gathered items kept. " if expired else "")+summary(g)
 rebuild(g)

static func groups(g) -> Dictionary:
 var result={}
 for p in g.planted:
  if not GardenAreaProgression.allowed(g,p.pos):continue
  var key=key_for(p)
  if not result.has(key):result[key]=[]
  result[key].append(p)
 return result

static func capacity(obj: Dictionary) -> float:
 return 48.0 if obj.kind=="reserve_tank" else 24.0 if obj.work.get("upgraded",false) else 12.0

static func controllers(g) -> Array:
 var result=[]
 for obj in g.objects:
  if obj.kind in ["soaker_controller","planter_drip"]:result.append(obj)
 result.sort_custom(func(a,b):return int(a.work.get("priority",0))<int(b.work.get("priority",0)) if int(a.work.get("priority",0))!=int(b.work.get("priority",0)) else str(a.uid)<str(b.uid))
 return result

static func covered(g,obj: Dictionary,key: String,plants: Array) -> bool:
 if not GardenAreaProgression.allowed(g,obj.pos) or plants.is_empty():return false
 if obj.kind=="soaker_controller":return not key.begins_with("pot:") and int(plants[0].plot)==int(obj.work.get("plot",-1))
 if not key.begins_with("pot:"):return false
 var planter=GardenContainers.object(g,str(plants[0].container_uid))
 return not planter.is_empty() and Vector2(planter.pos.x-obj.pos.x,planter.pos.z-obj.pos.z).length()<=4.0

static func supply(g,controller: Dictionary) -> Dictionary:
 var obj=GardenContainers.object(g,str(controller.work.get("supply","")))
 if obj.is_empty() or obj.kind not in SUPPLIES or not GardenAreaProgression.allowed(g,obj.pos):return {}
 if Vector2(obj.pos.x-controller.pos.x,obj.pos.z-controller.pos.z).length()>12:return {}
 return obj

static func charge_cost(key: String,plants: Array) -> int:
 return maxi(1,ceili(plants.size()/3.0)) if key.begins_with("pot:") else 1

static func irrigate(g) -> void:
 var patches=groups(g)
 var served={}
 for obj in controllers(g):
  obj.work["unserved"]=0
  if not obj.work.get("automatic",true):continue
  var source=supply(g,obj)
  for key in patches:
   var plants=patches[key]
   if served.has(key) or not covered(g,obj,key,plants):continue
   if not plants.any(func(p):return p.water<2 and g.growth_conditions(p)>0):continue
   var cost=charge_cost(key,plants)
   if source.is_empty() or float(source.work.get("water",0))<cost:
    obj.work.unserved+=1
    continue
   source.work.water-=cost
   for p in plants:p.water=4.0
   served[key]=true

static func demand(g,obj: Dictionary) -> int:
 var total=0
 var patches=groups(g)
 for key in patches:
  if covered(g,obj,key,patches[key]):total+=charge_cost(key,patches[key])
 return total

static func refill(g,obj: Dictionary) -> void:
 obj.work.water=capacity(obj)
 g.toast("Water storage filled. Manual water is always available.")
 GardenChallengeArt.equipment_visual(g,obj)
 g.save_game()

static func weeds(g) -> void:
 if g.day<=3:return
 var count=0
 var beds={}
 var last_by_bed={}
 var spreading=[]
 for key in g.challenge.patches:
  var patch=g.challenge.patches[key]
  var bed=str(patch.plot)
  last_by_bed[bed]=maxi(int(last_by_bed.get(bed,0)),int(patch.last_spawn))
  if int(patch.weed)>0:
   patch.weed_age+=1
   patch.weed=3 if patch.weed_age>=6 else 2 if patch.weed_age>=3 else 1
   if int(patch.weed)==3:spreading.append(key)
   count+=1
   beds[str(patch.plot)]=int(beds.get(str(patch.plot),0))+1
 var keys=g.challenge.patches.keys()
 keys.sort()
 if keys.is_empty():return
 var made=0
 var start=posmod(g.day*17+int(g.challenge.seed),keys.size())
 for n in range(keys.size()):
  if made>=2 or count>=24:break
  var key=keys[(start+n)%keys.size()]
  var patch=g.challenge.patches[key]
  var pos=center(key)
  # Specialist atlas pockets keep their own local care rules.
  if int(patch.plot) in range(4,14) or not GardenAreaProgression.allowed(g,pos):continue
  if int(patch.weed)>0 or int(patch.mulch_until)>g.day or int(patch.clear_until)>g.day:continue
  if int(beds.get(str(patch.plot),0))>=4:continue
  if g.day-int(last_by_bed.get(str(patch.plot),0))<2:continue
  var spread=false
  for other_key in spreading:
   if int(g.challenge.patches[other_key].plot)==int(patch.plot) and center(other_key).distance_to(pos)<=PATCH_SIZE+.01:spread=true;break
  if not spread and posmod(g.day+key.hash(),3)!=0:continue
  if g.clean_paths.any(func(path):var xy=path.split(":");return Vector2(float(xy[0])-pos.x,float(xy[1])-pos.z).length()<1):continue
  patch.weed=1;patch.weed_age=0;patch.last_spawn=g.day
  last_by_bed[str(patch.plot)]=g.day
  beds[str(patch.plot)]=int(beds.get(str(patch.plot),0))+1
  made+=1;count+=1

static func care_action(g,repeating: bool) -> void:
 sync_patches(g)
 var key=patch_key(g.hover_cell,g.hover_plot)
 var obj=GardenContainers.object(g,g.hover_container_uid)
 if g.mode=="mulch":
  var target=obj.work if not obj.is_empty() else g.challenge.patches.get(key,{})
  if target.is_empty():
   if not repeating:g.toast("Plant this patch first, or aim at a planted container.")
   return
  if int(target.get("mulch_until",0))>=g.day+6:return
  if int(g.workshop_state.resources.get("mulch",0))<=0:
   if not repeating:g.toast("Buy a mulch bag or prepare a batch in a leaf mulch bin.")
   return
  target.mulch_until=g.day+6
  g.workshop_state.resources.mulch-=1
  if int(g.challenge.intro)==1:g.challenge.intro=2
  g.toast("Mulched for six mornings · half moisture loss and weed prevention.")
 elif g.mode=="weed":
  var patch=g.challenge.patches.get(key,{})
  if patch.is_empty() or int(patch.weed)==0:return
  if int(patch.weed)>1:
   var progress=float(g.weed_progress.get(key,0))+.3
   g.weed_progress[key]=progress
   if progress<2:
    g.toast("Clearing established weeds… hold and keep aiming here.")
    g.action_cooldown=.3
    return
  g.weed_progress.erase(key)
  g.challenge.trimmings+=1
  patch.weed=0;patch.weed_age=0;patch.clear_until=g.day+2
  g.toast("Weeds cleared · one garden trimming for mulch.")
 elif g.mode=="meadow":
  if g.planted.any(func(p):return not GardenContainers.is_contained(p) and key_for(p)==key):
   g.toast("Move the planted specimens first, then return this patch to meadow.");return
  g.challenge.patches.erase(key)
  g.toast("Patch returned to meadow. It no longer needs weed care.")
 g.action_cooldown=.3
 g.animate_tool_action()
 g.challenge.report=summary(g)
 rebuild(g)
 g.update_hud()

static func buy_mulch(g) -> void:
 if g.coins<8:g.toast("A four-portion mulch bag costs eight petals.");return
 g.coins-=8
 g.workshop_state.resources.mulch=int(g.workshop_state.resources.get("mulch",0))+4
 g.save_game();g.refresh_ui()

static func trimming_batch(g,obj: Dictionary) -> void:
 if int(g.challenge.trimmings)<6:g.toast("Collect six garden trimmings first.");return
 if GardenEquipment.jobs(g,obj.uid).size()>=(2 if obj.work.get("upgraded",false) else 1):g.toast("This bin is already preparing mulch.");return
 g.challenge.trimmings-=6
 g.workshop_state.jobs.append({"recipe":"mulch","station":obj.uid,"ready_day":g.day+1,"amount":4})
 g.save_game()

static func intro_text(g) -> String:
 if int(g.challenge.intro)==2 and g.challenge.starter_claimed:return "Place a bed soaker from Shop → Bed care, then connect it to your starter barrel in the equipment panel."
 return ["Water your starter patch. Water is always free.","Apply one mulch portion using the Care tools.","From day 5, claim a starter barrel here. Buy a soaker and connect it.","Your garden is ready. Choose a seasonal request and expand when you like."][clampi(int(g.challenge.intro),0,3)]

static func claim_starter(g) -> void:
 if g.day<5 or int(g.challenge.intro)<2 or g.challenge.starter_claimed:return
 g.challenge.starter_claimed=true
 g.add_object("rain_barrel",g.plots[0].center+Vector3(-4.6,0,4.6),0)
 g.objects.back().work.water=12.0
 # The infrastructure lesson cannot be blocked by spending petals on decor.
 g.coins+=45
 g.toast("Starter barrel and 45 petals for your first soaker received.")
 g.save_game();g.refresh_ui()

static func offers(g) -> void:
 var season_index=int((g.day-1)/GardenClimate.SEASON_DAYS)
 if int(g.challenge.season)==season_index:return
 var previous=g.challenge.request
 if not previous.is_empty():g.toast("The season has ended. Your gathered items stay in the basket.")
 g.challenge.season=season_index
 g.challenge.request={}
 g.challenge.offers=[]
 g.challenge.completed=[]
 var types=["Flowers","Produce","Mixed"]
 for type in types:
  var eligible=[]
  for id in g.unlocked_plants:
   var data=g.catalogue[int(id)]
   if type=="Flowers" and int(data.layer)!=1:continue
   if type=="Produce" and data.category!="Produce":continue
   if not data.seasons.is_empty() and GardenClimate.season(g.day) not in data.seasons:continue
   if int(data.days)>6:continue
   eligible.append(int(id))
  if eligible.is_empty():continue
  g.challenge.offers.append({"id":"%d-%s"%[season_index,type],"title":type+" seasonal basket","eligible":eligible,"count":4 if type=="Produce" else 6 if type=="Flowers" else 8,"varieties":mini(2 if type!="Mixed" else 3,eligible.size()),"reward":35 if type=="Produce" else 30 if type=="Flowers" else 45,"mulch":2 if type=="Mixed" else 0,"deadline":(season_index+1)*12})

static func accept(g,id: String) -> void:
 if not g.challenge.request.is_empty():return
 for offer in g.challenge.offers:
  if str(offer.id)!=id or id in g.challenge.completed:continue
  var longest=0
  for plant_id in offer.eligible:longest=maxi(longest,int(g.catalogue[plant_id].days))
  if int(offer.deadline)-g.day+1<longest+1:g.toast("Too late to start this basket safely. A new selection arrives next season.");return
  g.challenge.request=offer.duplicate(true)
  g.save_game();g.refresh_ui();return

static func allocation(g,request: Dictionary) -> Dictionary:
 var result={}
 if request.is_empty():return result
 var remaining=int(request.count)
 # Reserve diversity first, then fill from eligible harvest. Exclude standing orders.
 for id in request.eligible:
  var available=int(g.inventory.get(str(id),0))-standing_reserved(g,int(id))
  if available>0 and remaining>0:result[str(id)]=1;remaining-=1
 for id in request.eligible:
  if remaining<=0:break
  var key=str(id)
  var available=maxi(0,int(g.inventory.get(key,0))-standing_reserved(g,int(id))-int(result.get(key,0)))
  var take=mini(remaining,available)
  if take>0:result[key]=int(result.get(key,0))+take;remaining-=take
 return result

static func standing_reserved(g,id: int) -> int:
 var total=0
 for order in g.orders:
  if not order.get("pending",false) and int(order.plant)==id:total+=int(order.count)
 return total

static func reserved(g,id: int) -> int:
 return int(allocation(g,g.challenge.request).get(str(id),0)) if active(g) else 0

static func deliver(g) -> void:
 var request=g.challenge.request
 var items=allocation(g,request)
 var total=0
 for amount in items.values():total+=int(amount)
 if request.is_empty() or g.day>int(request.deadline) or total<int(request.count) or items.size()<int(request.varieties):return
 for key in items:g.inventory[key]-=int(items[key])
 var earned=GardenEconomy.earn(g,int(request.reward))
 g.workshop_state.resources.mulch=int(g.workshop_state.resources.get("mulch",0))+int(request.mulch)
 g.challenge.completed.append(str(request.id))
 g.challenge.request={}
 g.fulfilled+=1
 g.toast("Seasonal basket delivered · %d petals."%earned)
 g.save_game();g.refresh_ui()

static func summary(g) -> String:
 var thirsty={}
 var weed_count=0
 for p in g.planted:
  if p.water<2 and g.growth_conditions(p)>0:thirsty[key_for(p)]=true
 for patch in g.challenge.patches.values():
  if int(patch.weed)>0:weed_count+=1
 var missing=0
 for obj in controllers(g):missing+=int(obj.work.get("unserved",0))
 return "%d thirsty patches · %d weed patches%s"%[thirsty.size(),weed_count," · %d patches missed irrigation"%missing if missing>0 else ""]

static func rebuild(g) -> void:
 if not active(g) or not is_instance_valid(g.world_root):return
 GardenChallengeArt.rebuild(g)

static func valid_save(data: Dictionary,plant_count: int) -> bool:
 if int(data.get("version",0))!=4:return not data.has("challenge") and data.get("garden_mode","free")=="free"
 if data.get("garden_mode")!="challenge" or not data.get("challenge") is Dictionary:return false
 var state=data.challenge
 if not state.has_all(["rules","seed","patches","trimmings","season","offers","request","completed","intro","starter_claimed","report"]):return false
 if not GardenSaveFormat.integer(state.rules,1,1) or not GardenSaveFormat.integer(state.seed,0,2147483647):return false
 for key in ["trimmings","intro"]:
  if not GardenSaveFormat.integer(state[key],0,3 if key=="intro" else 1000000):return false
 if not GardenSaveFormat.integer(state.season,-1) or not state.starter_claimed is bool or not state.report is String:return false
 if not state.patches is Dictionary or state.patches.size()>32768:return false
 if state.report.length()>1024:return false
 var weed_count=0
 var weeds_by_bed={}
 var plot_count=maxi(4,int(data.get("unlocked_plots",1))+2)
 if plot_count%2:plot_count+=1
 if data.has("areas"):plot_count+=10
 for key in state.patches:
  if not key is String:return false
  var parts=key.split(":")
  if parts.size()!=3 or not Array(parts).all(func(value):return str(value).is_valid_int()):return false
  if absi(int(parts[1]))>10000 or absi(int(parts[2]))>10000:return false
  var patch=state.patches[key]
  if not patch is Dictionary or not patch.has_all(["plot","weed","weed_age","mulch_until","clear_until","last_spawn"]):return false
  if not GardenSaveFormat.integer(patch.plot,0,plot_count-1) or int(parts[0])!=int(patch.plot):return false
  for field in ["plot","weed","weed_age","mulch_until","clear_until","last_spawn"]:
   if not GardenSaveFormat.integer(patch[field],0,3 if field=="weed" else 1000000000):return false
  if int(patch.weed)>0:
   weed_count+=1
   weeds_by_bed[str(patch.plot)]=int(weeds_by_bed.get(str(patch.plot),0))+1
   if weed_count>24 or int(weeds_by_bed[str(patch.plot)])>4:return false
 if not state.offers is Array or state.offers.size()>3 or not state.request is Dictionary:return false
 if not state.completed is Array or state.completed.size()>3 or not state.completed.all(func(value):return value is String):return false
 var ids=[]
 for request in state.offers:
  if not valid_request(request,plant_count):return false
  if request.id in ids:return false
  ids.append(request.id)
 if not state.request.is_empty():
  if not valid_request(state.request,plant_count) or state.request.id not in ids or state.request.id in state.completed:return false
 for id in state.completed:
  if id not in ids:return false
 for obj in data.get("objects",[]):
  var work=obj.get("work",{})
  if not work is Dictionary:return false
  for key in ["automatic"]:
   if work.has(key) and not work[key] is bool:return false
  if work.has("supply") and not work.supply is String:return false
  for key in ["priority","plot","unserved","mulch_until"]:
   if work.has(key) and not GardenSaveFormat.integer(work[key],0,2 if key=="priority" else 1000000000):return false
 return true

static func valid_request(request,plant_count: int) -> bool:
 if not request is Dictionary or not request.has_all(["id","title","eligible","count","varieties","reward","mulch","deadline"]):return false
 if not request.id is String or not request.title is String:return false
 if not request.eligible is Array or request.eligible.is_empty() or request.eligible.size()>plant_count:return false
 var seen=[]
 for id in request.eligible:
  if not GardenSaveFormat.integer(id,0,plant_count-1) or id in seen:return false
  seen.append(id)
 for key in ["count","varieties","reward","mulch","deadline"]:
  if not GardenSaveFormat.integer(request[key],1 if key in ["count","varieties","deadline"] else 0,1000000):return false
 return int(request.varieties)<=request.eligible.size() and int(request.varieties)<=int(request.count)
