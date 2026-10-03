class_name GardenLeisure
extends RefCounted

const VERBS={"bench":"Sit on bench","pergola":"Rest under pergola","pond":"Watch the pond","gazebo":"Rest in gazebo","garden_swing":"Sit on swing"}

static func target(g) -> Dictionary:
 if g.mode!="walk" or g.photo_mode or g.day_transition:return {}
 var best={}
 var nearest=3.2
 var forward=Vector3(-sin(g.yaw),0,-cos(g.yaw))
 for obj in g.objects:
  if obj.kind not in VERBS or not is_instance_valid(obj.node):continue
  var direction=obj.pos-g.player.position
  direction.y=0
  if direction.length()>nearest:continue
  if direction.length()>.8 and direction.normalized().dot(forward)<.25:continue
  nearest=direction.length();best=obj
 return best

static func interact(g) -> void:
 if g.photo_mode or g.day_transition or g.mode!="walk":return
 if is_instance_valid(g.rest_object):leave(g);return
 var obj=target(g)
 if not obj.is_empty():rest(g,obj)
 else:g.greet_pet()

static func rest(g, obj: Dictionary) -> void:
 if not is_instance_valid(obj.get("node")) or obj.kind not in VERBS:return
 if g.player.position.distance_to(obj.pos)>3.5:return
 g.rest_return=g.player.position
 g.rest_object=obj.node
 g.rest_kind=obj.kind
  # The bench back is local +Z; sit facing its open, local -Z side.
 var offset=Vector3(0,.65,-.08) if obj.kind in ["bench","garden_swing"] else (Vector3(0,0,1.65) if obj.kind=="pond" else Vector3.ZERO)
 g.player.position=obj.node.to_global(offset)
 if obj.kind not in ["bench","garden_swing"]:g.player.position=GardenTerrain.point(g.player.position)+Vector3(0,.1,0)
 g.player.velocity=Vector3.ZERO
 g.yaw=obj.node.rotation.y
 g.pitch=.38 if obj.kind=="pond" else (.2 if obj.kind in ["bench","garden_swing"] else .08)
 g.side_panel.hide();g.resume_controls()
 if not g.touch_active():Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 g.toast({"bench":"Take a seat. Invite a companion to share the view.","pergola":"A little shade and a quiet moment.","gazebo":"A sheltered seat and a quiet view.","garden_swing":"A gentle sway in the garden.","pond":"Watch the ripples"+(" and your fish." if obj.fish else ". Stock fish in Shop for little visitors.")}[obj.kind])
 g.update_camera(0)

static func leave(g) -> void:
 if g.rest_kind.is_empty():return
 g.player.position=GardenTerrain.point(g.rest_return)+Vector3(0,.1,0)
 g.player.velocity=Vector3.ZERO
 g.rest_object=null;g.rest_kind=""
 for pet in g.pets:
  if pet.command_kind=="settle":pet.command_time=minf(pet.command_time,5.0)
 if not g.side_panel.visible:g.resume_controls()
 g.toast("Back to wandering.")

static func call_pet(g, index: int, settle: bool=false) -> void:
 if index<0 or index>=g.pets.size():return
 var point=g.player.position
 if settle and is_instance_valid(g.rest_object):
  point=g.rest_object.to_global(Vector3(-1.65 if index==0 else 1.65,0,-.8))
 if not g.accessible(point):point=g.rest_return if not g.rest_kind.is_empty() else g.player.position
 g.pets[index].invite(GardenTerrain.point(point),settle)
 g.toast(g.companion_names[index]+(" is coming to settle nearby." if settle else " is coming over. Walk nearby to pet them."))

static func build(g) -> void:
 g.leisure_panel=g.panel_at(Vector2(16,96),Vector2(300,0))
 g.leisure_panel.z_index=11
 var col=VBoxContainer.new()
 col.add_theme_constant_override("separation",6)
 g.leisure_panel.add_child(col)
 col.add_child(g.label("A MOMENT IN YOUR GARDEN",13))
 col.add_child(g.button("Sit on bench · E",func():interact(g),Vector2(0,44)))
 for i in range(2):
  var index=i
  col.add_child(g.button("Invite companion",func():call_pet(g,index,true),Vector2(0,40)))
 col.add_child(g.button("Pet companion",func():g.greet_pet(),Vector2(0,40)))

static func update(g) -> void:
 if not g.rest_kind.is_empty() and (not is_instance_valid(g.rest_object) or g.rest_object.is_queued_for_deletion()):leave(g)
 if not is_instance_valid(g.leisure_panel):build(g)
 var obj=target(g)
 var resting=not g.rest_kind.is_empty()
 var nearby=g.pets.any(func(p):return p.position.distance_to(g.player.position)<4)
 var visible=g.mode=="walk" and (resting or not obj.is_empty() or nearby) and not g.photo_mode and not g.day_transition and not g.side_panel.visible and not is_instance_valid(g.welcome) and not g.tutorial_state.get("active",false)
 # Touch has the same actions in its large Interact button and Garden drawer.
 g.leisure_panel.visible=visible and not g.touch_active() and (resting or g.gameplay_active())
 var col=g.leisure_panel.get_child(0)
 col.get_child(1).visible=resting or not obj.is_empty()
 col.get_child(1).text=("Stand up" if resting else VERBS.get(obj.get("kind",""),"Rest"))+" · E"
 for i in range(2):
  col.get_child(i+2).visible=resting
  col.get_child(i+2).text="Invite "+g.companion_names[i]+" to settle"
 col.get_child(4).visible=nearby
 var index=0 if g.pets[0].position.distance_to(g.player.position)<g.pets[1].position.distance_to(g.player.position) else 1
 col.get_child(4).text="Pet "+g.companion_names[index]+" · F"
 g.leisure_panel.size=Vector2(300,0)
