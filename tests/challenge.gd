extends SceneTree

class Garden extends RefCounted:
 var garden_mode="challenge"
 var challenge=GardenChallenge.initial_state()
 var catalogue=GardenCatalogue.plants()
 var planted: Array=[]
 var objects: Array=[]
 var plots=[{"condition":"sun"}]
 var day=4
 var orders: Array=[]
 var inventory: Dictionary={}
 var clean_paths: Array=[]
 var workshop_state=GardenWorkshop.initial_state()
 var coins=80
 var petal_remainder=0
 var settings={"petal_rate":"easy"}
 var fulfilled=0
 func growth_conditions(_p):return 1.0
 func toast(_text):pass
 func save_game():return true
 func refresh_ui():pass

func plant(id: int,pos=Vector3.ZERO) -> Dictionary:
 return {"id":id,"pos":pos,"plot":0,"water":4.0,"stress":0.0,"dry_days":0}

func _initialize() -> void:
 var failures=[]
 var g=Garden.new()
 var p=plant(0)
 g.planted=[p]
 GardenChallenge.sync_patches(g)
 if not is_equal_approx(GardenChallenge.loss(g,p),1):failures.append("Moderate water profile")
 var patch=g.challenge.patches[GardenChallenge.key_for(p)]
 patch.mulch_until=10
 if not is_equal_approx(GardenChallenge.loss(g,p),.5):failures.append("Mulch water retention")
 patch.mulch_until=0
 p.water=1
 if not is_equal_approx(GardenChallenge.rate(g,p),.6):failures.append("Thirst slows growth")
 p.water=0;p.dry_days=3
 if GardenChallenge.rate(g,p)!=0:failures.append("Dormant growth")
 GardenChallenge.water(g,p)
 if p.dry_days!=3:failures.append("Dormant plant recovered before morning")
 GardenChallenge.morning(g)
 if p.dry_days!=0 or GardenChallenge.rate(g,p)!=1:failures.append("Dormant plant did not recover")
 var source={"uid":"s","kind":"reserve_tank","pos":Vector3.ZERO,"work":{"water":1.0}}
 var controller={"uid":"c","kind":"soaker_controller","pos":Vector3.ZERO,"work":{"supply":"s","plot":0,"automatic":true,"priority":0}}
 g.objects=[source,controller]
 p.water=0
 for i in range(50):g.planted.append(plant(0,Vector3(.1,0,.1)))
 GardenChallenge.irrigate(g)
 if source.work.water!=0 or p.water!=4:failures.append("Patch irrigation must cost one charge regardless of density")
 source.work.water=0;p.water=0
 GardenChallenge.irrigate(g)
 if controller.work.unserved!=1 or p.water!=0:failures.append("Empty supply must report unserved patch")
 source.pos=Vector3(13,0,0)
 if not GardenChallenge.supply(g,controller).is_empty():failures.append("Distant source connected")
 source.pos=Vector3.ZERO
 controller.work.automatic=false
 source.work.water=10;p.water=0
 GardenChallenge.irrigate(g)
 if p.water!=0 or source.work.water!=10:failures.append("Off controller watered")
 g.objects=[]
 g.challenge.patches={}
 for i in range(20):
  var key=GardenChallenge.patch_key(Vector3(i*2,0,0),0)
  g.challenge.patches[key]={"plot":0,"weed":0,"weed_age":0,"mulch_until":100,"clear_until":0,"last_spawn":0}
 for day in range(4,30):g.day=day;GardenChallenge.weeds(g)
 if g.challenge.patches.values().any(func(value):return value.weed>0):failures.append("Weeds appeared through mulch")
 for value in g.challenge.patches.values():value.mulch_until=0
 for day in range(30,90):g.day=day;GardenChallenge.weeds(g)
 var count=0
 for value in g.challenge.patches.values():
  if value.weed>0:count+=1
 if count==0 or count>4:failures.append("Weed emergence or per-bed cap")
 g.day=1;g.challenge=GardenChallenge.initial_state()
 var request={"id":"0-Mixed","title":"Basket","eligible":[0,2],"count":4,"varieties":2,"reward":30,"mulch":2,"deadline":12}
 g.challenge.offers=[request];g.challenge.request=request.duplicate(true)
 g.inventory={"0":5,"2":2};g.orders=[{"plant":0,"count":2}]
 var reserved=GardenChallenge.allocation(g,request)
 if int(reserved.get("0",0))>3 or reserved.size()!=2:failures.append("Standing and seasonal reservations overlap")
 var before=g.coins
 GardenChallenge.deliver(g)
 if g.coins!=before+30 or not g.challenge.request.is_empty() or g.fulfilled!=1:failures.append("Delivery reward or completion")
 GardenChallenge.deliver(g)
 if g.coins!=before+30:failures.append("Duplicate delivery paid twice")
 var data={"version":4,"garden_mode":"challenge","plants":[],"challenge":GardenChallenge.initial_state()}
 if not GardenSaveFormat.valid(data,g.catalogue.size(),GardenCatalogue.furnishings().map(func(item):return item.kind)):failures.append("Challenge save rejected")
 data.challenge.patches={"bad":{}}
 if GardenSaveFormat.valid(data,g.catalogue.size(),[]):failures.append("Malformed patch accepted")
 data={"version":3,"plants":[],"challenge":GardenChallenge.initial_state()}
 if GardenSaveFormat.valid(data,g.catalogue.size(),[]):failures.append("Challenge data accepted as legacy Free save")
 var crowded={"version":4,"garden_mode":"challenge","plants":[],"challenge":GardenChallenge.initial_state()}
 for i in range(5):crowded.challenge.patches["0:%d:0"%i]={"plot":0,"weed":1,"weed_age":0,"mulch_until":0,"clear_until":0,"last_spawn":0}
 if GardenSaveFormat.valid(crowded,g.catalogue.size(),[]):failures.append("Imported weeds exceeded per-bed cap")
 crowded.challenge.patches={"0:0:0":{"plot":[],"weed":0,"weed_age":0,"mulch_until":0,"clear_until":0,"last_spawn":0}}
 if GardenSaveFormat.valid(crowded,g.catalogue.size(),[]):failures.append("Invalid patch plot type accepted")
 var schedule=[]
 for day in range(1,100):schedule.append(GardenChallenge.weather_for(g,day))
 for day in range(1,100):
  if schedule[day-1]!=GardenChallenge.weather_for(g,day):failures.append("Weather rerolled")
 print("CHALLENGE_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
