class_name GardenSaveFormat
extends RefCounted

const MAX_BYTES=4*1024*1024

static func number(value) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and absf(float(value))<=1.0e12

static func integer(value, minimum: int=0, maximum: int=1000000000) -> bool:
 return number(value) and float(value)==floor(float(value)) and value>=minimum and value<=maximum

static func vector(value, length: int=2) -> bool:
 return value is Array and value.size()==length and value.all(number)

static func fields(data: Dictionary, numeric: Array=[], booleans: Array=[], strings: Array=[]) -> bool:
 for key in numeric:
  if data.has(key) and not number(data[key]):return false
 for key in booleans:
  if data.has(key) and not data[key] is bool:return false
 for key in strings:
  if data.has(key) and not data[key] is String:return false
 return true

# Validate every shape read by restoration before allowing an external file to
# replace a garden. Keep v1/v2/v3 bytes intact, including unknown extension fields.
static func read(bytes: PackedByteArray, plant_count: int, kinds: Array) -> Dictionary:
 if bytes.is_empty() or bytes.size()>MAX_BYTES:
  return {"error":"Choose a complete garden JSON file smaller than 4 MB."}
 var text=bytes.get_string_from_utf8()
 if text.to_utf8_buffer()!=bytes:
  return {"error":"This file is not readable UTF-8 text. Choose a garden JSON save."}
 var parser=JSON.new()
 if parser.parse(text)!=OK or not parser.data is Dictionary:
  return {"error":"This file is not a garden JSON save. Your current garden is unchanged."}
 var data: Dictionary=parser.data
 if not valid(data,plant_count,kinds):
  return {"error":"This save is damaged or uses garden content this version cannot open. Your current garden is unchanged."}
 return {"data":data}

static func valid(data: Dictionary, plant_count: int, kinds: Array) -> bool:
 if not integer(data.get("version"),1,3) or not data.get("plants") is Array:return false
 for key in ["objects","orders","clean_paths","unlocked_plants","names","favourite_plants","recent_plants","owned_surfaces"]:
  if data.has(key) and not data[key] is Array:return false
 for key in ["settings","terrain","watered_ground","wild_collection","wild_pruning","inventory","upgrades","automation","expansions","path_widths","climate","tutorial","bed_surfaces"]:
  if data.has(key) and not data[key] is Dictionary:return false
 if not fields(data,["coins","clock","fulfilled","planted_total","rake_petals","prune_width"],["hoe_raise","request_unread"]):return false
 for counter in ["fulfilled","planted_total"]:
  if data.has(counter) and not integer(data[counter]):return false
 if data.has("petal_remainder") and not integer(data.petal_remainder,0,99):return false
 if not integer(data.get("day",1),1) or not integer(data.get("unlocked_plots",1),1,1024):return false
 var plot_count=maxi(4,int(data.get("unlocked_plots",1))+2)
 if plot_count%2:plot_count+=1
 if data.has("areas"):plot_count+=10
 for plant in data.plants:
  if not plant is Dictionary or not integer(plant.get("id"),0,plant_count-1) or not integer(plant.get("plot"),0,plot_count-1) or not vector(plant.get("pos")):return false
  for key in ["age","water","stress"]:
   if not number(plant.get(key)):return false
  if not fields(plant,["orientation","shape_seed","prune_cuts","height_factor","pruned"]):return false
 for item in data.get("objects",[]):
  if not item is Dictionary or item.get("kind") not in kinds or not vector(item.get("pos")) or not number(item.get("price")) or not item.get("fish") is bool:return false
  if not fields(item,["rotation","elevation","starter_orientation_version"],[],["text","text_color","area_fixture","starter_id"]):return false
  if item.has("elevation") and absf(float(item.elevation))>10:return false
  if item.has("area_fixture") and not GardenAreaFurnishings.valid_id(str(item.area_fixture),str(item.kind)):return false
 for key in ["unlocked_plants","favourite_plants","recent_plants"]:
  for id in data.get(key,[]):
   if not integer(id,0,plant_count-1):return false
 for order in data.get("orders",[]):
  if not order is Dictionary or not order.get("person") is String or not integer(order.get("plant"),0,plant_count-1):return false
  for key in ["count","reward"]:
   if not number(order.get(key)):return false
  if not fields(order,["ready_day"],["pending","welcome"]):return false
 for key in ["terrain","inventory","upgrades","expansions","path_widths","wild_collection","wild_pruning"]:
  for value in data.get(key,{}).values():
   if not number(value):return false
 for key in data.get("inventory",{}):
  if not str(key).is_valid_float() or not integer(float(key),0,plant_count-1):return false
 for key in data.get("upgrades",{}):
  if key not in ["can","shears","trowel","rake","gather"] or not integer(data.upgrades[key],0,2):return false
 for key in data.get("automation",{}):
  var index=str(key).trim_suffix("water").trim_suffix("prune")
  if not (str(key).ends_with("water") or str(key).ends_with("prune")) or not index.is_valid_int() or not integer(int(index),0,plot_count-1) or not data.automation[key] is bool:return false
 for key in data.get("clean_paths",[]):
  if not key is String:return false
  var parts=key.split(":")
  if parts.size()!=2 or not parts[0].is_valid_float() or not parts[1].is_valid_float():return false
 for patch in data.get("watered_ground",{}).values():
  if not patch is Dictionary:return false
  for key in ["x","z","radius","until"]:
   if not number(patch.get(key)):return false
 if data.has("player") and not vector(data.player):return false
 if data.has("names") and (data.names.size()!=2 or not data.names.all(func(value):return value is String)):return false
 var climate: Dictionary=data.get("climate",{})
 if climate.has("values") and not vector(climate.values,3):return false
 if not fields(climate,["snow","slot"],[],["target"]):return false
 var tutorial: Dictionary=data.get("tutorial",{})
 if not fields(tutorial,["step","plant","seed","morning"],["active"]):return false
 if tutorial.has("pos") and not vector(tutorial.pos):return false
 var settings: Dictionary=data.get("settings",{})
 if not fields(settings,["control_size","render_scale","updates_seen","volume","music_volume","nature_volume","sensitivity","fov"],["left_handed","intro_seen","request_notifications","reduced_motion","invert_x","invert_y","pause_menus"],["controls","graphics","petal_rate"]):return false
 if settings.has("petal_rate") and settings.petal_rate not in GardenEconomy.MODES:return false
 if settings.has("learned_hints") and (not settings.learned_hints is Array or not settings.learned_hints.all(func(value):return value is String)):return false
 for value in data.get("owned_surfaces",[]):
  if not value is String:return false
 for value in data.get("bed_surfaces",{}).values():
  if not value is String:return false
 return GardenAreaCatalogue.valid_save(data) and GardenWorkshop.valid_save(data,plant_count) and GardenPlantBreeding.valid_save(data)
