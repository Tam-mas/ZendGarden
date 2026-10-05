extends SceneTree

class Ledger extends RefCounted:
 var settings: Dictionary={}
 var coins=80
 var petal_remainder=0

func _initialize() -> void:
 var failures: Array=[]
 var ledger=Ledger.new()
 if GardenEconomy.mode(ledger)!="easy" or GardenEconomy.earn(ledger,24)!=24 or ledger.coins!=104:
  failures.append("Original earnings changed without choosing a difficulty")
 for mode in GardenEconomy.MODES:
  var whole=Ledger.new()
  var split=Ledger.new()
  whole.settings.petal_rate=mode
  split.settings.petal_rate=mode
  var preview=GardenEconomy.preview(whole,91)
  var actual=GardenEconomy.earn(whole,91)
  for i in range(13):GardenEconomy.earn(split,7)
  if preview!=actual or whole.coins!=split.coins or whole.petal_remainder!=split.petal_remainder:
   failures.append("Split sales or preview changed earnings for "+mode)
  if whole.coins!=80+91*int(GardenEconomy.PERCENTAGES[mode])/100:
   failures.append("Incorrect earnings percentage for "+mode)
 ledger.settings.petal_rate="hard"
 ledger.petal_remainder=0
 var before=ledger.coins
 for i in range(4):GardenEconomy.earn(ledger,1)
 if ledger.coins!=before+1 or ledger.petal_remainder!=20:
  failures.append("Small Hard rewards lost their fractional earnings")
 ledger.settings.petal_rate="easy"
 if GardenEconomy.earn(ledger,2)!=2 or ledger.petal_remainder!=20:
  failures.append("Changing rates created petals or lost earned fractions")
 ledger.settings.petal_rate="hard"
 if GardenEconomy.earn(ledger,6)!=2 or ledger.petal_remainder!=0:
  failures.append("Earned fraction was not retained across a rate change")
 if GardenEconomy.earn(ledger,0)!=0 or GardenEconomy.earn(ledger,-5)!=0:
  failures.append("Empty or negative rewards changed the balance")
 ledger.settings.petal_rate="invalid"
 GardenEconomy.restore(ledger,{})
 if ledger.settings.petal_rate!="easy" or ledger.petal_remainder!=0:
  failures.append("Legacy or invalid settings did not fall back to Easy")
 var kinds=GardenCatalogue.furnishings().map(func(item):return item.kind)
 var count=GardenCatalogue.ROWS.size()
 for mode in GardenEconomy.MODES:
  var data={"version":2,"plants":[],"settings":{"petal_rate":mode},"petal_remainder":99}
  if GardenSaveFormat.read(JSON.stringify(data).to_utf8_buffer(),count,kinds).has("error"):
   failures.append("Valid petal setting rejected during save upload")
 for data in [{"version":2,"plants":[]},{"version":1,"plants":[]}]:
  if GardenSaveFormat.read(JSON.stringify(data).to_utf8_buffer(),count,kinds).has("error"):
   failures.append("Older save rejected after adding petal settings")
 for value in [-1,100,0.5,"bad"]:
  if GardenSaveFormat.valid({"version":2,"plants":[],"petal_remainder":value},count,kinds):
   failures.append("Invalid saved petal fraction accepted")
 for value in ["invalid",50,false]:
  if GardenSaveFormat.valid({"version":2,"plants":[],"settings":{"petal_rate":value}},count,kinds):
   failures.append("Invalid saved petal rate accepted")
 print("ECONOMY_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
