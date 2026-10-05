class_name GardenAreaCatalogue
extends RefCounted

const FIRST=4
const COUNT=10
const LEGACY_FIRST=14
static var cached: Dictionary={}

static func data() -> Dictionary:
 if cached.is_empty():
  var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://assets/areas/layout.json"))
  if parsed is Dictionary:cached=parsed
 return cached

static func entries() -> Array:
 return data().get("areas",[])

static func entry(index: int) -> Dictionary:
 return entries()[index] if index>=0 and index<COUNT else {}

static func center(index: int) -> Vector3:
 var c=entry(index).center
 return Vector3(float(c[0]),0,float(c[1]))

static func index_at(pos: Vector3) -> int:
 if pos.x<44 or pos.x>92 or pos.z>12 or pos.z< -108:return -1
 var column=clampi(floori((pos.x-44)/24),0,1)
 var row=clampi(floori((12-pos.z)/24),0,4)
 return row*2+column

static func height_at(pos: Vector3) -> float:
 var index=index_at(pos)
 if index<0:return NAN
 var local=pos-center(index)
 var x=clampf(local.x+12,0,24);var z=clampf(local.z+12,0,24)
 var ix=mini(23,floori(x));var iz=mini(23,floori(z))
 var grid: Array=entry(index).heightmap
 return lerpf(lerpf(float(grid[iz][ix]),float(grid[iz][ix+1]),x-ix),lerpf(float(grid[iz+1][ix]),float(grid[iz+1][ix+1]),x-ix),z-iz)

static func plot_open(g, index: int) -> bool:
 if index>=FIRST and index<LEGACY_FIRST:return true
 return index>=0 and (index if index<FIRST else index-COUNT)<g.unlocked_plots

static func next_plot(g) -> int:
 return g.unlocked_plots if g.unlocked_plots<FIRST else g.unlocked_plots+COUNT

static func legacy_plot_count(g) -> int:
 return g.plots.size()-COUNT

static func migrate(saved: Dictionary) -> Dictionary:
 if saved.has("areas"):return saved
 # Old expansion indices are shifted, but their world coordinates and content
 # are preserved. The ten habitats occupy a separate extension to the east.
 var result=saved.duplicate(true)
 for p in result.get("plants",[]):
  if int(p.plot)>=FIRST:p.plot=int(p.plot)+COUNT
 for p in result.get("workshop",{}).get("nursery",[]):
  if int(p.get("plot",0))>=FIRST:p.plot=int(p.plot)+COUNT
 for field in ["wild_collection","wild_pruning"]:
  var shifted_wild={}
  for old in result.get(field,{}):
   var parts=str(old).split(":")
   var key=str(old)
   if parts.size()==3 and parts[0]=="edge" and int(parts[1])>=FIRST:key="edge:%d:%s"%[int(parts[1])+COUNT,parts[2]]
   shifted_wild[key]=result[field][old]
  if result.has(field):result[field]=shifted_wild
 for key in ["expansions","bed_surfaces"]:
  var shifted={}
  for old in result.get(key,{}):
   var index=int(old);shifted[str(index+COUNT if index>=FIRST else index)]=result[key][old]
  if result.has(key):result[key]=shifted
 var automation={}
 for old in result.get("automation",{}):
  var suffix="water" if str(old).ends_with("water") else "prune"
  var index=int(str(old).trim_suffix(suffix))
  automation[str(index+COUNT if index>=FIRST else index)+suffix]=result.automation[old]
 if result.has("automation"):result.automation=automation
 return result

static func valid_save(saved: Dictionary) -> bool:
 if not saved.has("areas"):return true
 var state=saved.areas
 if not state is Dictionary or not GardenSaveFormat.integer(state.get("version"),1,1) or not state.get("gardens") is Dictionary:return false
 if state.gardens.size()>COUNT:return false
 var kinds=entries().map(func(item):return item.kind)
 for kind in state.gardens:
  var garden=state.gardens[kind]
  if kind not in kinds or not garden is Dictionary:return false
  if not GardenSaveFormat.fields(garden,["sluice","lanterns","basket_day","melt","rotation_day"],["visited","initialized","photo"]):return false
  if garden.has("sluice") and not GardenSaveFormat.integer(garden.sluice,0,2):return false
  if garden.has("lanterns") and not GardenSaveFormat.integer(garden.lanterns,0,2):return false
  for key in ["basket_day","rotation_day"]:
   if garden.has(key) and not GardenSaveFormat.integer(garden[key]):return false
  if garden.has("melt") and not GardenSaveFormat.integer(garden.melt,0,3):return false
  for key in ["clearings","shelters","restored","vents","shade","mist","gates","windbreaks"]:
   if garden.has(key):
    if not garden[key] is Array or garden[key].size()!=(2 if key=="gates" else 3) or not garden[key].all(func(v):return v is bool):return false
  for key in ["discoveries","journal"]:
   if garden.has(key) and (not garden[key] is Array or garden[key].size()>24 or not garden[key].all(func(v):return v is String)):return false
  if garden.has("rotation"):
   if not garden.rotation is Dictionary or garden.rotation.size()>4:return false
   for value in garden.rotation.values():
    if not value is String:return false
  if not garden.get("beds",{}) is Dictionary or garden.get("beds",{}).size()>8:return false
  var area=entries().filter(func(item):return item.kind==kind)[0]
  for slot_key in garden.get("beds",{}):
   if not str(slot_key).is_valid_int() or int(slot_key)<0 or int(slot_key)>=area.slots.size():return false
   var plant=garden.beds[slot_key]
   if not plant is Dictionary or plant.get("species") not in data().specialties:return false
   if not GardenSaveFormat.fields(plant,["age","water","offset_day"]):return false
   if not GardenSaveFormat.number(plant.get("age")) or float(plant.age)<0 or float(plant.age)>1000000000:return false
   if not GardenSaveFormat.number(plant.get("water")) or float(plant.water)<0 or float(plant.water)>4:return false
   if plant.has("offset_day") and not GardenSaveFormat.integer(plant.offset_day):return false
   var allowed={"reedwater":["lily","hawthorn","iris","reed","mint"],"fern_gully":["maidenhair","birdsnest","treefern"],"glasshouse":["orchid","cymbidium","hoya"],"alpine":["edelweiss","gentian","saxifrage"],"moon":["primrose","nicotiana","moonflower","nightphlox"]}
   if plant.species not in allowed.get(kind,[]):return false
 return true
