class_name GardenAreaProgression
extends RefCounted

# Index order follows the atlas, not an enforced unlock order.
const PLANTING_REVISION=1
const RULES=[
 {"metric":"day","target":14}, {"metric":"day","target":7},
 {"metric":"fulfilled","target":5}, {"metric":"planted_total","target":250},
 {"metric":"planted_total","target":1000}, {"metric":"planted_total","target":500},
 {"metric":"planted_total","target":2000}, {"metric":"fulfilled","target":8},
 {"metric":"day","target":60}, {"metric":"day","target":100}
]

static func restore(g) -> void:
 # Apply the higher planting targets to saves from the initial balance too.
 # Once earned under this revision, access remains a permanent reward.
 if int(g.areas_state.get("planting_milestones_revision",0))<PLANTING_REVISION:
  for index in range(10):
   if RULES[index].metric=="planted_total":
    var s=GardenAreas.state(g,index)
    s.unlocked=bool(s.unlocked) and int(g.planted_total)>=int(RULES[index].target)
 g.areas_state["planting_milestones_revision"]=PLANTING_REVISION

static func unlocked(g,index: int) -> bool:
 return index>=0 and index<10 and (bool(GardenAreas.state(g,index).unlocked) or int(g.get(RULES[index].metric))>=int(RULES[index].target))

static func requirement(index: int) -> String:
 var rule=RULES[index]
 match rule.metric:
  "day":return "Reach game day %d"%int(rule.target)
  "fulfilled":return "Complete %d neighbour requests"%int(rule.target)
 return "Plant %d new plants"%int(rule.target)

static func progress(g,index: int) -> String:
 var rule=RULES[index];var value=mini(int(g.get(rule.metric)),int(rule.target))
 if GardenAreas.state(g,index).unlocked:value=int(rule.target)
 var unit="game days" if rule.metric=="day" else "requests" if rule.metric=="fulfilled" else "plants"
 return "%d / %d %s"%[value,int(rule.target),unit]

static func message(g,index: int) -> String:
 return GardenAreaCatalogue.entry(index).name+" · "+requirement(index)+" to garden here ("+progress(g,index)+"). Visit and explore any time."

static func allowed(g,pos: Vector3,notify: bool=false) -> bool:
 var index=GardenAreaCatalogue.index_at(pos)
 if index<0 or unlocked(g,index):return true
 if notify:g.toast(message(g,index))
 return false

static func refresh(g,notify: bool=true) -> void:
 var earned=[]
 for index in range(10):
  var s=GardenAreas.state(g,index)
  if not s.unlocked and unlocked(g,index):
   s.unlocked=true;earned.append(GardenAreaCatalogue.entry(index).name)
   GardenAreas.initialize(g,index)
 if not earned.is_empty():
  if notify:g.toast("A garden reward: "+", ".join(earned)+". Plant and arrange here now. See Garden atlas in Guide.")
  if is_instance_valid(g.ui):g.refresh_ui()
  if not g.smoke:g.save_game()

# Explicit fixture setup for isolated review/test gardens only.
static func unlock_review(g) -> void:
 for index in range(10):GardenAreas.state(g,index).unlocked=true
