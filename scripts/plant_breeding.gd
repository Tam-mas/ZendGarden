class_name GardenPlantBreeding
extends RefCounted

# A curated first collection. Crosses stay within a species; foliage sports are
# preserved vegetatively and never silently treated as seed-inherited genes.
const PROFILES={
 148:["Division",["c477ca","f3e5db","d85690"],[1,2,3,4]],
 149:["Division",["c5a452","e9dfb9","9baf75"],[1,3]],
 150:["Division",["edc632","efdca3","bc8441"],[2,3]],
 151:["Division",["dd90b8","f5eadf","bc5e8e"],[1,2,4]],
 152:["Offset",["839acf","e8e5f1","9d70bc"],[1,3,4]],
 153:["Division",["a99b53","c7c78a","8d7056"],[3,4]],
 154:["Division",["bec37e","e6dfa1","cad9a9"],[2,3]],
 155:["Division",["f3e5b0","f5eee2","e6c45e"],[2,3]],
 158:["Seed-grown selection",["416cbd","ede4e4","9963b1"],[1,2]],
 159:["Cutting",["c65ba4","f1e4e9","923f87"],[1,4]],
 160:["Division",["d34b85","f0e4e4","e990b2"],[1,2]],
 161:["Division",["d981ac","f0e6e5","bd578b"],[1,4]],
 162:["Division",["7d81ca","ebe6ea","bc86c2"],[1,2]],
 165:["Division",["c87aaa","ece2cc","d99369"],[1,2,4]],
 166:["Division",["ebba32","e2d49a","c88842"],[1,2]],
 176:["Bulb offset",["ae82c4","eadde8","d886a7"],[1,4]],
 177:["Bulb offset",["697fc3","ede8e0","b58abf"],[1]],
 178:["Bulb offset",["996fc1","e8e3d9","b991cc"],[1]],
 182:["Cutting",["d47a99","eadbbe","db9d63"],[1,2,4]],
 185:["Seed-grown selection",["85a9ce","e9e8dc","c19cbd"],[1,2]],
 188:["Division",["967ac1","e5dbce","c07599"],[1,2,4]],
 190:["Division",["ba7893","e3d8b4","775668"],[1,3]],
 192:["Cutting",["e9dfe1","be7798","ac83bf"],[1,2]],
 198:["Cutting",["dc6d83","e9c88f","f0decf"],[1,2,4]],
 199:["Cutting",["e8b7c8","f0e2db","c380a9"],[1]],
 204:["Cutting",["e8e3db","dfa9be","e9c7d1"],[1,2]],
 209:["Cutting",["d4809c","e7d8d9","be608c"],[1]],
 211:["Cutting",["7c93c7","ece3e0","aa8bc6"],[1,2]]
}
const LEAVES=["Green foliage","Cream leaf margins","Marbled leaves","Split-tone leaves","Striped leaves"]
const PATTERNS=["Plain flowers","Contrasting petal edges","Contrasting flower centres","Spotted flowers","Two-tone flowers"]
const MAX_FORMS=2048
const MAX_NURSERY=128

static func initial_state() -> Dictionary:
 return {"sequence":0,"forms":{},"jobs":[],"nursery":[],"misses":0,"discoveries":0,"recent":[]}

static func restore(g, data: Dictionary) -> void:
 g.breeding_state=initial_state()
 g.breeding_state.merge(data.get("breeding",{}).duplicate(true),true)
 for f in g.breeding_state.forms.values():
  for key in ["species","foliage","seed","generation","day"]:f[key]=int(f[key])
  for key in ["bloom","pattern","habit"]:f.genes[key]=f.genes[key].map(func(value):return int(value))
 g.selected_cultivar=""

static func supported(id: int) -> bool:return PROFILES.has(id)

static func blank_genes() -> Dictionary:
 return {"bloom":[0,0],"pattern":[0,0],"habit":[1,1]}

static func form(g, uid: String) -> Dictionary:
 return g.breeding_state.forms.get(uid,{})

static func of_plant(g, p: Dictionary) -> Dictionary:
 if not p.has("form_uid"):return {}
 return form(g,str(p.get("form_uid","")))

static func height_factor(f: Dictionary) -> float:
 if f.is_empty():return 1.0
 return .85+.075*(int(f.genes.habit[0])+int(f.genes.habit[1]))

static func palette(f: Dictionary) -> Array:
 return PROFILES[int(f.species)][1] if not f.is_empty() else []

static func title(g, f: Dictionary) -> String:
 if f.is_empty():return "Original plant"
 return g.catalogue[int(f.species)].name+" ‘"+str(f.name)+"’" if bool(f.registered) else g.catalogue[int(f.species)].name+" · selection "+str(f.uid).trim_prefix("form-")

static func traits(f: Dictionary, flowers: bool=true) -> String:
 if f.is_empty():return "Original form"
 var result=[LEAVES[int(f.foliage)]]
 var height=height_factor(f)
 if height<.98:result.append("Compact habit")
 elif height>1.02:result.append("Taller habit")
 if flowers:
  var pattern=maxi(int(f.genes.pattern[0]),int(f.genes.pattern[1]))
  result.append(PATTERNS[pattern])
  if int(f.genes.bloom[0])!=0 or int(f.genes.bloom[1])!=0:result.append("Selected flower colour")
 else:result.append("Flower colours reveal at flowering")
 return " · ".join(result)

static func create(g, id: int, genes: Dictionary, foliage: int, seed_value: int, parents: Array=[], generation: int=0, observed: bool=true) -> String:
 if g.breeding_state.forms.size()>=MAX_FORMS:return ""
 g.breeding_state.sequence+=1
 var uid="form-%d"%int(g.breeding_state.sequence)
 g.breeding_state.forms[uid]={"uid":uid,"species":id,"genes":genes.duplicate(true),"foliage":foliage,"seed":seed_value,"parents":parents.duplicate(),"generation":generation,"day":g.day,"observed":observed,"registered":false,"name":"","favourite":false,"archived":false}
 return uid

static func snapshot(g, p: Dictionary) -> String:
 if not supported(int(p.id)) or p not in g.planted:return ""
 var existing=of_plant(g,p)
 if not existing.is_empty():return existing.uid
 var uid=create(g,int(p.id),blank_genes(),0,int(p.shape_seed),[],0,float(p.age)>=float(g.catalogue[p.id].days)*.78)
 if not uid.is_empty():p["form_uid"]=uid;p["breeding_checked"]=true
 return uid

# Only growth into a new stage admits a specimen once. Empty mornings cannot
# reroll it. The first discovery and a six-specimen drought are protected.
static func observe(g, p: Dictionary) -> void:
 if not supported(int(p.id)) or float(p.age)<float(g.catalogue[p.id].days)*.35:return
 var f=of_plant(g,p)
 if not f.is_empty():
  if not f.observed and float(p.age)>=float(g.catalogue[p.id].days)*.78:
   f.observed=true
   g.toast("A new selection is flowering: "+title(g,f)+". Preserve it at the potting bench.")
  return
 if p.get("breeding_checked",false):return
 p["breeding_checked"]=true
 var rng=RandomNumberGenerator.new();rng.seed=int(p.shape_seed)+int(p.id)*104729
 var found=int(g.breeding_state.discoveries)==0 or int(g.breeding_state.misses)>=5 or rng.randf()<.18
 if not found:g.breeding_state.misses+=1;return
 var genes=blank_genes()
 var colours: Array=PROFILES[int(p.id)][1]
 genes.bloom=[rng.randi_range(1,colours.size()-1),rng.randi_range(0,colours.size()-1)]
 var patterns: Array=PROFILES[int(p.id)][2]
 genes.pattern=[patterns[rng.randi_range(0,patterns.size()-1)],0]
 genes.habit=[rng.randi_range(0,2),1]
 # Seed-only annuals receive inherited flower discoveries, not a fictitious
 # cutting-preserved foliage sport.
 var foliage=0 if PROFILES[int(p.id)][0]=="Seed-grown selection" else rng.randi_range(1,4)
 var uid=create(g,int(p.id),genes,foliage,int(p.shape_seed),[],0,float(p.age)>=float(g.catalogue[p.id].days)*.78)
 if uid.is_empty():return
 p["form_uid"]=uid
 g.breeding_state.discoveries+=1;g.breeding_state.misses=0
 g.refresh_plant(p,false)
 g.toast("Unusual growth on your "+g.catalogue[p.id].name+"! Inspect it, then visit the potting bench when it flowers.")

static func bench_ready(g, obj: Dictionary) -> bool:
 return not obj.is_empty() and obj in g.objects and obj.kind=="potting_bench" and GardenAreaProgression.allowed(g,obj.pos)

static func job_error(g, obj: Dictionary, breeding: bool=false) -> String:
 if not bench_ready(g,obj):return "Place a potting bench in an open garden to start an experiment."
 var count=0
 for job in g.breeding_state.jobs:
  if job.station==obj.uid:count+=1
 if count>=(4 if obj.work.get("upgraded",false) else 2):return "The propagation spaces are full. Wait for a morning or upgrade this bench."
 if g.breeding_state.nursery.size()+g.breeding_state.jobs.size()*4+4>MAX_NURSERY:return "Plant or register some nursery selections first."
 if int(g.workshop_state.resources.get("starter_mix",0))<1:return "Prepare starter mix first; each experiment uses one portion."
 if breeding and g.coins<6:return "A seedling tray costs six petals."
 return ""

static func propagate(g, obj: Dictionary, uid: String) -> bool:
 var f=form(g,uid)
 var error=job_error(g,obj)
 if f.is_empty() or not f.observed:error="Grow this selection until it flowers before preserving it."
 if not error.is_empty():g.toast(error);return false
 g.workshop_state.resources.starter_mix-=1
 g.breeding_state.jobs.append({"kind":"propagate","station":obj.uid,"ready_day":g.day+2,"forms":[uid]})
 g.toast(str(PROFILES[int(f.species)][0])+" is establishing. Ready on morning %d."%(g.day+2))
 return true

static func breed(g, obj: Dictionary, a_uid: String, b_uid: String) -> bool:
 var a=form(g,a_uid);var b=form(g,b_uid)
 var error=job_error(g,obj,true)
 if a.is_empty() or b.is_empty() or not a.observed or not b.observed:error="Choose two flowering parent selections."
 elif a_uid==b_uid:error="Choose two different parent specimens or cultivars."
 elif a.species!=b.species:error="These parents are different species. Choose two forms of the same plant."
 if g.breeding_state.forms.size()+4>MAX_FORMS:error="The journal is full; keep your current selections safely."
 if not error.is_empty():g.toast(error);return false
 var rng=RandomNumberGenerator.new();rng.seed=int(g.breeding_state.sequence)*7919+int(a.seed)+int(b.seed)
 var children=[]
 for i in range(4):
  var genes=blank_genes()
  for key in genes:
   genes[key]=[a.genes[key][rng.randi_range(0,1)],b.genes[key][rng.randi_range(0,1)]]
  # A small new inherited colour allele can appear in a seedling generation.
  if rng.randf()<.12:genes.bloom[rng.randi_range(0,1)]=rng.randi_range(0,2)
  children.append(create(g,int(a.species),genes,0,rng.randi_range(0,2147483646),[a_uid,b_uid],maxi(int(a.generation),int(b.generation))+1,false))
 g.workshop_state.resources.starter_mix-=1;g.coins-=6
 g.breeding_state.jobs.append({"kind":"breed","station":obj.uid,"ready_day":g.day+3,"forms":children})
 g.toast("Four seedlings are starting. Ready to plant on morning %d; their flowers will reveal as they grow."%(g.day+3))
 return true

static func morning(g) -> void:
 for job in g.breeding_state.jobs.duplicate():
  if int(job.ready_day)>g.day:continue
  for uid in job.forms:g.breeding_state.nursery.append({"form_uid":uid,"kind":job.kind})
  g.breeding_state.jobs.erase(job)
  g.toast("Your potting-bench nursery has new plants ready.")
 for p in g.planted:observe(g,p)

static func register(g, index: int, name: String) -> bool:
 if index<0 or index>=g.breeding_state.nursery.size():return false
 var entry=g.breeding_state.nursery[index];var f=form(g,entry.form_uid)
 var clean=name.strip_edges().replace("\n"," ").replace("\r"," ").replace("‘","").replace("’","")
 if entry.kind!="propagate" or f.is_empty() or not f.observed:g.toast("Grow a seedling and propagate your chosen form first.");return false
 if clean.is_empty() or clean.length()>40:g.toast("Give your cultivar a name between one and forty characters.");return false
 for other in g.breeding_state.forms.values():
  if other.uid!=f.uid and other.registered and other.species==f.species and str(other.name).to_lower()==clean.to_lower():g.toast("That cultivar name is already used for this species.");return false
 f.name=clean;f.registered=true;f.archived=false
 g.breeding_state.nursery.remove_at(index)
 g.toast(title(g,f)+" is yours forever. Find it in My cultivars in the seed collection.")
 return true

static func choose(g, uid: String) -> void:
 var f=form(g,uid)
 if f.is_empty() or not f.registered:return
 g.selected_cultivar=uid;g.selected=int(f.species);g.selected_layer=g.catalogue[g.selected].layer;g.nursery_placing=-1
 g.set_mode("plant");g.side_panel.hide();g.resume_controls();g.refresh_ui()

static func rename(g, uid: String, name: String) -> bool:
 var f=form(g,uid);var clean=name.strip_edges().replace("\n"," ").replace("\r"," ").replace("‘","").replace("’","")
 if f.is_empty() or not f.registered:return false
 if clean.is_empty() or clean.length()>40:g.toast("Use a name between one and forty characters.");return false
 for other in g.breeding_state.forms.values():
  if other.uid!=uid and other.registered and other.species==f.species and str(other.name).to_lower()==clean.to_lower():g.toast("That name is already used for this species.");return false
 f.name=clean;g.toast("Cultivar renamed.");return true

static func place_nursery(g, index: int) -> void:
 if index<0 or index>=g.breeding_state.nursery.size():return
 var entry=g.breeding_state.nursery[index];var f=form(g,entry.form_uid)
 var id=int(f.species)
 var saved={"id":id,"pos":[0,0],"plot":0,"age":float(g.catalogue[id].days)*.20,"water":4.0,"stress":0.0,"pruned":0.0,"height_factor":1.0,"shape_seed":f.seed,"orientation":0.0,"form_uid":f.uid,"breeding_checked":true}
 g.workshop_state.nursery.append(saved);g.breeding_state.nursery.remove_at(index)
 GardenWorkshop.close(g);g.selected_cultivar="";g.selected=id;g.selected_layer=g.catalogue[id].layer
 g.set_mode("plant");g.nursery_placing=g.workshop_state.nursery.size()-1;g.side_panel.hide();g.resume_controls()
 g.toast("Choose soil or a suitable planter. Cancelling keeps this selection in Stored plants.")

static func selected_form(g) -> Dictionary:
 if g.nursery_placing>=0 and g.nursery_placing<g.workshop_state.nursery.size():return form(g,str(g.workshop_state.nursery[g.nursery_placing].get("form_uid","")))
 return form(g,g.selected_cultivar)

static func apply_selection(g, p: Dictionary) -> void:
 var f=form(g,g.selected_cultivar)
 if not f.is_empty() and f.registered and int(f.species)==int(p.id):
  p["form_uid"]=f.uid;p["breeding_checked"]=true;p.height_factor=1.0
  record_planting(g,f.uid)
  g.refresh_plant(p,false)

static func record_planting(g, uid: String) -> void:
 if uid.is_empty():return
 g.breeding_state.recent.erase(uid);g.breeding_state.recent.push_front(uid)
 if g.breeding_state.recent.size()>20:g.breeding_state.recent.resize(20)

static func compatible(a: Dictionary, b: Dictionary) -> bool:
 return not a.is_empty() and not b.is_empty() and a.uid!=b.uid and a.species==b.species and a.observed and b.observed

static func valid_save(data: Dictionary) -> bool:
 var state=data.get("breeding",{})
 if not state is Dictionary:return false
 if not state.get("forms",{}) is Dictionary or not state.get("jobs",[]) is Array or not state.get("nursery",[]) is Array or not state.get("recent",[]) is Array:return false
 for key in ["sequence","misses","discoveries"]:
  if not GardenSaveFormat.integer(state.get(key,0)):return false
 var forms: Dictionary=state.get("forms",{})
 if forms.size()>MAX_FORMS or state.get("jobs",[]).size()>128 or state.get("nursery",[]).size()>MAX_NURSERY or state.get("recent",[]).size()>20:return false
 for uid in forms:
  var f=forms[uid]
  if not uid is String or not uid.begins_with("form-") or not uid.trim_prefix("form-").is_valid_int():return false
  if not f is Dictionary or f.get("uid")!=uid or not GardenSaveFormat.integer(f.get("species")) or not supported(int(f.species)):return false
  if not GardenSaveFormat.integer(int(uid.trim_prefix("form-")),1,int(state.get("sequence",0))):return false
  if not f.get("genes") is Dictionary:return false
  if f.genes.size()!=3:return false
  for key in ["bloom","pattern","habit"]:
   var values=f.genes.get(key)
   if not values is Array or values.size()!=2:return false
   for value in values:
    if not GardenSaveFormat.integer(value,0,4 if key=="pattern" else 2):return false
    if key=="pattern" and value!=0 and int(value) not in PROFILES[int(f.species)][2]:return false
  if not GardenSaveFormat.integer(f.get("foliage"),0,4) or not GardenSaveFormat.integer(f.get("seed"),0,2147483646) or not GardenSaveFormat.integer(f.get("generation"),0,MAX_FORMS) or not GardenSaveFormat.integer(f.get("day"),1):return false
  if PROFILES[int(f.species)][0]=="Seed-grown selection" and int(f.foliage)!=0:return false
  if not f.get("name") is String or f.name.length()>40:return false
  for key in ["registered","observed","favourite","archived"]:
   if not f.get(key) is bool:return false
  if f.registered and (f.name.strip_edges().is_empty() or not f.observed):return false
  if not f.get("parents") is Array or f.parents.size() not in [0,2]:return false
  for parent in f.parents:
   if not parent is String or not forms.has(parent) or parent==uid:return false
   var older=forms[parent]
   if not older is Dictionary or older.get("species")!=f.species or not GardenSaveFormat.integer(older.get("generation")) or int(older.generation)>=int(f.generation):return false
 for job in state.get("jobs",[]):
  if not job is Dictionary or job.get("kind") not in ["propagate","breed"] or not job.get("station") is String or not GardenSaveFormat.integer(job.get("ready_day"),1) or not job.get("forms") is Array:return false
  if job.forms.size()!=(4 if job.kind=="breed" else 1):return false
  for uid in job.forms:
   if not uid is String or not forms.has(uid):return false
 for entry in state.get("nursery",[]):
  if not entry is Dictionary or entry.get("kind") not in ["propagate","breed"] or not entry.get("form_uid") is String or not forms.has(entry.form_uid):return false
 for uid in state.get("recent",[]):
  if not uid is String or not forms.has(uid):return false
 for p in data.get("plants",[])+data.get("workshop",{}).get("nursery",[]):
  if p.has("breeding_checked") and not p.breeding_checked is bool:return false
  if p.has("form_uid"):
   if not p.form_uid is String or not forms.has(p.form_uid) or int(forms[p.form_uid].species)!=int(p.id):return false
 return true
