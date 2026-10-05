class_name GardenEconomy
extends RefCounted

const MODES=["easy","medium","hard"]
const LABELS=["Easy · 100%","Medium · 60%","Hard · 30%"]
const PERCENTAGES={"easy":100,"medium":60,"hard":30}

static func mode(g) -> String:
 var selected=str(g.settings.get("petal_rate","easy"))
 return selected if selected in MODES else "easy"

# Keep hundredths across awards so small earnings and split sales do not lose
# value to rounding. Refunds and existing balances never pass through this.
static func preview(g, base: int) -> int:
 return (maxi(0,base)*int(PERCENTAGES[mode(g)])+g.petal_remainder)/100

static func earn(g, base: int) -> int:
 var total=maxi(0,base)*int(PERCENTAGES[mode(g)])+g.petal_remainder
 var paid: int=total/100
 g.petal_remainder=total%100
 g.coins+=paid
 return paid

static func restore(g, data: Dictionary) -> void:
 g.settings["petal_rate"]=mode(g)
 g.petal_remainder=clampi(int(data.get("petal_remainder",0)),0,99)

static func settings_page(g) -> void:
 g.add_note("PETAL EARNINGS",15)
 var choice=OptionButton.new()
 choice.name="PetalRate"
 choice.custom_minimum_size.y=48 if g.touch_active() else 38
 choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for text in LABELS:choice.add_item(text)
 choice.select(MODES.find(mode(g)))
 choice.item_selected.connect(func(index):
  g.settings["petal_rate"]=MODES[index]
  g.save_game()
  g.refresh_ui())
 g.list_box.add_child(choice)
 g.add_note("Choose how quickly you earn petals from spare harvest, neighbour requests and raking. Easy keeps the original rate. Small amounts accumulate towards your next petal.",14)
 g.add_note("Change anytime. Shop prices, refunds and plant growth stay the same.",14)
