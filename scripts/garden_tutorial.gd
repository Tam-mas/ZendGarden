class_name GardenTutorial
extends RefCounted

const STEPS=[
 ["Plant a little beginning", "Choose a flower, aim at open soil, and plant it. Discovered seeds are endless.", "Choose a flower"],
 ["Give it a drink", "Aim at your new flower and water it. This welcome flower will bloom after its first watered morning.", "Use the watering can"],
 ["Welcome the next morning", "Take a breath and watch the light change. Your flower is ready for its first morning.", "Next morning"],
 ["Gather a little joy", "Aim at your welcome flower and gather its bloom into your basket. The plant stays in your garden.", "Use Gather"],
 ["Share with a neighbour", "Open Orders and deliver your welcome flower. Requests have no deadline.", "Open Orders"]
]

static func start(g) -> void:
 if is_instance_valid(g.welcome): g.welcome.queue_free()
 if is_instance_valid(g.welcome_backdrop): g.welcome_backdrop.queue_free()
 g.welcome=null; g.welcome_backdrop=null
 g.dismiss_request()
 GardenLeisure.leave(g)
 g.settings.intro_seen=true
 if g.loaded_data.is_empty():g.settings.updates_seen=GardenUpdates.CURRENT_VERSION
 g.tutorial_state={"step":0,"active":true}
 g.orders=g.orders.filter(func(o):return not o.get("welcome",false))
 g.side_panel.hide()
 g.set_mode("walk")
 build(g)
 g.save_game()

static func build(g) -> void:
 if is_instance_valid(g.tutorial_panel): g.tutorial_panel.queue_free()
 g.tutorial_panel=g.panel_at(Vector2(16,96),Vector2(300,0))
 g.tutorial_panel.z_index=12
 var col=VBoxContainer.new()
 col.add_theme_constant_override("separation",8)
 g.tutorial_panel.add_child(col)
 var step=clampi(int(g.tutorial_state.get("step",0)),0,4)
 col.add_child(g.label("WELCOME WALK · %d / 5"%(step+1),13))
 col.add_child(g.label(STEPS[step][0],19))
 var note=g.label(STEPS[step][1],16)
 note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 col.add_child(note)
 var row=HBoxContainer.new()
 col.add_child(row)
 var next=g.button("Continue",func(): action(g),Vector2(0,44))
 next.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(next)
 row.add_child(g.button("Skip",func(): finish(g,false),Vector2(70,44)))
 row.get_child(1).tooltip_text="Skip the welcome walk · Escape"
 layout(g)

static func layout(g) -> void:
 if not is_instance_valid(g.tutorial_panel): return
 var size=g.get_viewport().get_visible_rect().size
 g.tutorial_panel.visible=bool(g.tutorial_state.get("active",false)) and not g.side_panel.visible and not g.photo_mode and not g.day_transition and not is_instance_valid(g.welcome) and not (is_instance_valid(g.touch) and is_instance_valid(g.touch.drawer))
 var width=minf(300,size.x-32)
 var col=g.tutorial_panel.get_child(0)
 var step=clampi(int(g.tutorial_state.get("step",0)),0,4)
 col.get_child(0).visible=not g.touch_active()
 col.get_child(1).autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 col.get_child(1).custom_minimum_size.x=width-28
 col.get_child(2).custom_minimum_size.x=width-28
 col.get_child(2).visible=not (g.touch_active() and size.y<500)
 col.get_child(2).text=["Plant one flower on open soil.","Water your new flower.","Your watered flower blooms next morning.","Gather your welcome flower’s bloom.","Deliver one bloom in Orders."][step] if g.touch_active() else STEPS[step][1]
 col.get_child(3).get_child(0).text=["Seeds","Water","Morning","Gather","Orders"][step]+(" · Enter" if not g.touch_active() else "")
 g.tutorial_panel.position=Vector2(16,(64 if size.y<500 else 82) if g.touch_active() else 96)
 g.tutorial_panel.size=Vector2(width,0)
 if g.touch_active():g.toast_label.position.y=size.y*.5+32

static func action(g) -> void:
 match int(g.tutorial_state.get("step",0)):
  0: g.open_sidebar("Seeds")
  1: g.set_mode("water")
  2: g.next_day()
  3: g.set_mode("harvest")
  4: g.open_sidebar("Orders")

static func flower(g) -> Dictionary:
 var pos=g.tutorial_state.get("pos",[])
 if pos.size()!=2:return {}
 for p in g.planted:
  if int(p.id)==int(g.tutorial_state.get("plant",-1)):
   if g.tutorial_state.has("seed") and int(p.shape_seed)==int(g.tutorial_state.seed):return p
   if not g.tutorial_state.has("seed") and Vector2(p.pos.x-pos[0],p.pos.z-pos[1]).length()<.05:return p
 return {}

static func event(g, kind: String, plant: Dictionary={}) -> void:
 if not g.tutorial_state.get("active",false): return
 var step=int(g.tutorial_state.get("step",0))
 if step==0 and kind=="plant" and g.catalogue[plant.id].category=="Flowers":
  g.tutorial_state.plant=int(plant.id)
  g.tutorial_state.seed=int(plant.shape_seed)
  g.tutorial_state.pos=[plant.pos.x,plant.pos.z]
  advance(g)
 elif step==1 and kind=="water":
  var p=flower(g)
  if not p.is_empty() and p.water>0 and Vector2(p.pos.x-g.hover_cell.x,p.pos.z-g.hover_cell.z).length()<=.65+int(g.upgrades.can)*1.25:
   g.tutorial_state.morning=g.day
   advance(g)
 elif step==2 and kind=="morning" and g.day>int(g.tutorial_state.get("morning",g.day)):
  var p=flower(g)
  if p.is_empty():return
  # Only the planted welcome flower gets this one-time bloom; normal seasons stay intact.
  p.age=float(g.catalogue[p.id].days)
  g.refresh_plant(p)
  advance(g)
 elif step==3 and kind=="gather" and not plant.is_empty() and int(plant.id)==int(g.tutorial_state.get("plant",-1)):
  var p=flower(g)
  if p.is_empty() or p!=plant:return
  if not g.orders.any(func(o): return o.get("welcome",false) and not o.get("pending",false)):
   g.orders.append({"person":"Jun · a welcome for you","plant":int(plant.id),"count":1,"reward":12,"welcome":true})
  advance(g)
 elif step==4 and kind=="deliver": finish(g,true)

static func advance(g) -> void:
 g.tutorial_state.step=int(g.tutorial_state.step)+1
 build(g)
 g.save_game()

static func finish(g, completed: bool) -> void:
 g.tutorial_state.active=false
 g.tutorial_state.completed=completed
 if is_instance_valid(g.tutorial_panel):g.tutorial_panel.queue_free()
 g.tutorial_panel=null
 if is_instance_valid(g.touch):g.touch.last_size=Vector2.ZERO
 g.side_panel.hide()
 g.set_mode("walk")
 g.toast("Your first bloom has made someone’s day. The garden is yours to explore." if completed else "The garden is yours. Replay the welcome walk in Settings whenever you like.")
 g.save_game()

static func update(g) -> void:
 if not g.tutorial_state.get("active",false):return
 if int(g.tutorial_state.get("step",0)) in [1,2,3] and flower(g).is_empty():
  g.tutorial_state={"step":0,"active":true}
  build(g)
  g.toast("Choose another flower to continue your welcome walk.")
 if not is_instance_valid(g.tutorial_panel):build(g)
 layout(g)

static func hint(g, key: String, message: String) -> void:
 var seen: Array=g.settings.get("learned_hints",[])
 if key in seen:return
 seen.append(key)
 g.settings.learned_hints=seen
 g.toast(message)
