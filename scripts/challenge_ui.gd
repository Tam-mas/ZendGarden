class_name GardenChallengeUI
extends RefCounted

static func action(g,parent: Node,text: String,callback: Callable) -> Button:
 var button=g.button(text,callback)
 button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(button)
 return button

static func page(g) -> void:
 g.side_title.text="Challenge · Care"
 g.add_note(GardenChallenge.summary(g),17)
 g.add_note(GardenChallenge.intro_text(g),15)
 if g.day>=5 and int(g.challenge.intro)>=2 and not g.challenge.starter_claimed:
  action(g,g.list_box,"Claim starter barrel & soaker funds",func():GardenChallenge.claim_starter(g))
 g.add_note("CARE TOOLS",14)
 for entry in [["water","Water"],["weed","Weed · hold and sweep"],["mulch","Mulch · one portion per patch"],["meadow","Return empty patch to meadow"]]:
  var mode=str(entry[0])
  action(g,g.list_box,entry[1],func():g.set_mode(mode))
 g.add_note("Mulch: %d portions · Trimmings: %d"%[int(g.workshop_state.resources.get("mulch",0)),int(g.challenge.trimmings)])
 action(g,g.list_box,"Buy four mulch portions · 8 petals",func():GardenChallenge.buy_mulch(g))
 g.add_note("THREE-DAY FORECAST",14)
 for offset in range(3):g.add_note("Day %d · %s"%[g.day+offset,GardenChallenge.weather_for(g,g.day+offset)])
 g.add_note("OVERLAY",14)
 var row=GridContainer.new();row.columns=2;row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;g.list_box.add_child(row)
 for option in ["care","water","weeds","irrigation"]:
  var selected=option
  var overlay=action(g,row,option.capitalize(),func():g.care_overlay=selected;GardenChallenge.rebuild(g))
  overlay.custom_minimum_size=Vector2(120,42)
  overlay.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 g.add_note("BEDS & PLANTERS",14)
 var patches=GardenChallenge.groups(g)
 for plot in range(g.plots.size()):
  var wet=0;var weeds=0;var plants=0
  for key in patches:
   if int(patches[key][0].plot)!=plot:continue
   plants+=patches[key].size()
   if patches[key].any(func(p):return p.water<2):wet+=1
  for patch in g.challenge.patches.values():
   if int(patch.plot)==plot and int(patch.weed)>0:weeds+=1
  if plants==0 and weeds==0:continue
  var chosen=plot
  g.add_note("%s · %d plants\n%d thirsty patches · %d weed patches"%[g.plots[plot].name,plants,wet,weeds])
  action(g,g.list_box,"Show this garden",func():
   g.yaw=atan2(g.player.position.x-g.plots[chosen].center.x,g.player.position.z-g.plots[chosen].center.z)
   g.pitch=.25;g.current_plot=chosen
   g.toast(g.plots[chosen].name+" is ahead. Water and weeds overlays show care patches.")
   GardenMenus.close(g))
 g.add_note("IRRIGATION",14)
 for obj in g.objects:
  if obj.kind not in GardenChallenge.SUPPLIES and obj.kind not in GardenChallenge.EQUIPMENT:continue
  var uid=str(obj.uid)
  action(g,g.list_box,GardenEquipment.name_of(g,obj.kind)+" · "+equipment_status(g,obj),func():GardenWorkshop.open(g,uid))
 action(g,g.list_box,"Shop for equipment",func():g.menu_sections.shop="Equipment";GardenMenus.visit(g,"Shop"))
 action(g,g.list_box,"Seasonal requests",func():GardenMenus.visit(g,"Orders"))
 g.add_note("Care resolves each morning. Time stops while away. Thirsty plants grow slowly; wilting plants rest until watered. No plant or cultivar is lost through neglect. Specialist atlas collections retain their local care rules.")
 action(g,g.list_box,"Your gardens",func():GardenMenus.visit(g,"Gardens"))

static func equipment_status(g,obj: Dictionary) -> String:
 if obj.kind in GardenChallenge.SUPPLIES:return "%d / %d charges"%[int(obj.work.get("water",0)),int(GardenChallenge.capacity(obj))]
 var source=GardenChallenge.supply(g,obj)
 var demand=GardenChallenge.demand(g,obj)
 var cycles=0 if source.is_empty() else floori(float(source.work.get("water",0))/maxi(1,demand))
 return ("Off" if not obj.work.get("automatic",true) else "No supply" if source.is_empty() else "About %d full cycles"%cycles)+" · %d charges/cycle"%demand

static func equipment(g,column: Node,obj: Dictionary) -> bool:
 if obj.kind not in GardenChallenge.SUPPLIES and obj.kind not in GardenChallenge.EQUIPMENT:return false
 GardenWorkshop.note(g,column,equipment_status(g,obj),17)
 if obj.kind in GardenChallenge.SUPPLIES:
  GardenWorkshop.note(g,column,"Rain adds eight charges. A charge waters one ground patch or up to three container pockets. Manual refill is always free.")
  action(g,column,"Refill storage",func():GardenChallenge.refill(g,obj);GardenWorkshop.open(g,obj.uid))
  if obj.kind=="rain_barrel" and not obj.work.get("upgraded",false):
   action(g,column,"Upgrade to 24 charges · 40 petals",func():GardenEquipment.upgrade(g,obj);GardenWorkshop.open(g,obj.uid))
  return true
 GardenWorkshop.note(g,column,"Select a barrel or tank within twelve metres. Automatic watering tops up thirsty patches before growth. Complete patches are served in priority order.")
 action(g,column,"Turn off" if obj.work.get("automatic",true) else "Turn on",func():obj.work.automatic=not obj.work.get("automatic",true);g.save_game();GardenWorkshop.open(g,obj.uid))
 var chooser=OptionButton.new();chooser.custom_minimum_size.y=44
 chooser.add_item("Choose water supply…")
 var ids=[""]
 for candidate in g.objects:
  if candidate.kind not in GardenChallenge.SUPPLIES or Vector2(candidate.pos.x-obj.pos.x,candidate.pos.z-obj.pos.z).length()>12:continue
  ids.append(candidate.uid)
  chooser.add_item(GardenEquipment.name_of(g,candidate.kind)+" · "+equipment_status(g,candidate))
 chooser.select(maxi(0,ids.find(str(obj.work.get("supply","")))))
 chooser.item_selected.connect(func(index):
  obj.work.supply=ids[index]
  if index>0 and int(g.challenge.intro)==2:g.challenge.intro=3
  g.save_game();GardenWorkshop.open(g,obj.uid);GardenChallenge.rebuild(g))
 column.add_child(chooser)
 var priority=OptionButton.new();priority.custom_minimum_size.y=44
 for text in ["Priority 1 · first","Priority 2","Priority 3 · last"]:priority.add_item(text)
 priority.select(clampi(int(obj.work.get("priority",0)),0,2))
 priority.item_selected.connect(func(index):obj.work.priority=index;g.save_game())
 column.add_child(priority)
 action(g,column,"Show coverage",func():g.care_overlay="irrigation";GardenChallenge.rebuild(g);GardenWorkshop.close(g);GardenMenus.close(g))
 if int(obj.work.get("unserved",0))>0:GardenWorkshop.note(g,column,"Last morning: %d patches missed watering. Refill or reconnect storage."%int(obj.work.unserved))
 return true

static func requests(g) -> void:
 g.add_note("SEASONAL REQUESTS",18)
 var request=g.challenge.request
 if not request.is_empty():
  var allocation=GardenChallenge.allocation(g,request)
  var total=0
  for amount in allocation.values():total+=int(amount)
  g.add_note(request.title,17)
  g.add_note("%d / %d items · %d / %d varieties\nDue at the end of day %d · %d mornings left"%[total,int(request.count),allocation.size(),int(request.varieties),int(request.deadline),int(request.deadline)-g.day])
  var names=[]
  for id in request.eligible:names.append(g.catalogue[int(id)].name)
  g.add_note("Eligible: "+", ".join(names))
  g.add_note("Reward: %d petals%s"%[GardenEconomy.preview(g,int(request.reward))," and two mulch portions" if int(request.mulch)>0 else ""])
  var deliver=action(g,g.list_box,"Deliver seasonal basket",func():GardenChallenge.deliver(g))
  deliver.disabled=total<int(request.count) or allocation.size()<int(request.varieties)
  action(g,g.list_box,"Abandon basket · keep gathered items",func():g.challenge.request={};g.save_game();g.refresh_ui())
 else:
  g.add_note("Choose one basket at a time. Missed deadlines cost no petals, and gathered items stay yours.")
  for offer in g.challenge.offers:
   if str(offer.id) in g.challenge.completed:continue
   var id=str(offer.id)
   g.add_note("%s · %d items across %d varieties\nDue day %d · %d petals"%[offer.title,int(offer.count),int(offer.varieties),int(offer.deadline),GardenEconomy.preview(g,int(offer.reward))],15)
   var names=[]
   for plant_id in offer.eligible:names.append(g.catalogue[int(plant_id)].name)
   g.add_note("Eligible: "+", ".join(names))
   action(g,g.list_box,"Accept "+str(offer.title),func():GardenChallenge.accept(g,id))
 g.add_note("UNTIMED NEIGHBOUR REQUEST",16)

static func preview_morning(g) -> void:
 g.side_title.text="Next morning"
 var at_risk={}
 for p in g.planted:
  if float(p.water)-GardenChallenge.loss(g,p)<.5 and g.growth_conditions(p)>0:at_risk[GardenChallenge.key_for(p)]=true
 g.add_note("%d patches may wilt before rain or irrigation. Check your supplies, or continue when ready."%at_risk.size(),16)
 g.add_note("Today: "+GardenChallenge.weather_for(g,g.day)+" · tomorrow: "+GardenChallenge.weather_for(g,g.day+1))
 if not g.challenge.request.is_empty():g.add_note("Seasonal basket due day %d. Deliver before advancing from its final day."%int(g.challenge.request.deadline))
 action(g,g.list_box,"Welcome the next morning",func():g.challenge_skip_confirmed=true;GardenMenus.close(g);g.next_day())
 action(g,g.list_box,"Review garden care",func():GardenMenus.visit(g,"Care"))
 action(g,g.list_box,"Return to garden",func():GardenMenus.close(g))

static func care_lines(g) -> Array:
 var obj=GardenContainers.object(g,g.hover_container_uid)
 var patch=obj.work if not obj.is_empty() else g.challenge.patches.get(GardenChallenge.patch_key(g.hover_cell,g.hover_plot),{})
 if patch.is_empty():return ["Uncultivated ground","Plant here to start a care patch"]
 var stage=int(patch.get("weed",0))
 var remaining=maxi(0,int(patch.get("mulch_until",0))-g.day)
 return ["Container care" if not obj.is_empty() else "Cultivated patch · 2 × 2 m",["No weeds","Weed seedlings · harmless","Established weeds · hold to clear","Spreading weeds · hold to clear"][stage],"Mulch: %d mornings remaining"%remaining if remaining>0 else "No mulch protection","One portion covers this area · %d available"%int(g.workshop_state.resources.get("mulch",0)) if g.mode=="mulch" else "Weeding leaves planted specimens safe"]
