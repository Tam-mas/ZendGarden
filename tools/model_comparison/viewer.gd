extends SceneTree

const CACHE="res://captures/model_comparison/"
const CHOICES="res://art_source/overhaul/model_choices.json"
var manifest: Dictionary
var entries: Array=[]
var choices: Dictionary={}
var reviewed: Dictionary={}
var index=0
var yaw=-.65
var pitch=.28
var zoom=1.0
var extent=1.0
var dragging=false
var panels: Array=[]
var title: Label
var status: Label
var selector: OptionButton
var clips: OptionButton
var playback: CheckButton
var old_button: Button
var new_button: Button
var previous: Button
var next_button: Button
var selected_clip="Rest pose"
var smoke=false
var persistence_test=false
var errors: Array=[]
var review_finished=false

func _initialize() -> void:
 call_deferred("start")

func start() -> void:
 smoke="--smoke-test" in OS.get_cmdline_user_args()
 persistence_test="--persistence-test" in OS.get_cmdline_user_args()
 manifest=JSON.parse_string(FileAccess.get_file_as_string(CACHE+"manifest.json"))
 if manifest.is_empty():
  push_error("Run tools/model_comparison/prepare.py first.")
  quit(1)
  return
 entries=manifest.entries
 if not smoke:load_choices()
 for entry in entries:
  if choices.get(entry.id,"") not in ["new","old"]:choices[entry.id]="new"
  if entry.old.is_empty():choices[entry.id]="new"
 root.title="Zend Garden · Model comparison"
 root.size=Vector2i(1440,900)
 root.min_size=Vector2i(1000,700)
 build_ui()
 show_pair()
 if smoke:call_deferred("run_smoke")
 if persistence_test:call_deferred("run_persistence")

func load_choices() -> void:
 if FileAccess.file_exists(choices_path()):
  var saved=JSON.parse_string(FileAccess.get_file_as_string(choices_path()))
  if saved is Dictionary and saved.get("baseline","")==manifest.baseline:
   choices=saved.get("choices",{})
   reviewed=saved.get("reviewed",{})
   review_finished=saved.get("finished",false)
   index=clampi(int(saved.get("last_index",0)),0,entries.size()-1)
   var hashes={}
   for entry in saved.get("models",[]):hashes[entry.id]=entry.get("new_sha256","")
   for entry in entries:
    if hashes.get(entry.id,"")!=entry.new_sha256:
     reviewed.erase(entry.id)
     review_finished=false

func label(text: String, size: int=18) -> Label:
 var node=Label.new()
 node.text=text
 node.add_theme_font_size_override("font_size",size)
 return node

func button(text: String, callback: Callable) -> Button:
 var node=Button.new()
 node.text=text
 node.custom_minimum_size=Vector2(120,40)
 node.pressed.connect(callback)
 return node

func build_ui() -> void:
 var backdrop=ColorRect.new()
 backdrop.color=Color("30251d")
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(backdrop)
 var margin=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,18)
 margin.theme=GardenTheme.make()
 root.add_child(margin)
 var layout=VBoxContainer.new()
 layout.add_theme_constant_override("separation",12)
 margin.add_child(layout)
 var header=HBoxContainer.new()
 layout.add_child(header)
 title=label("",26)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 header.add_child(title)
 selector=OptionButton.new()
 selector.custom_minimum_size=Vector2(310,40)
 for entry in entries:selector.add_item(entry.category+" · "+entry.name)
 selector.item_selected.connect(func(value):navigate(value))
 header.add_child(selector)
 layout.add_child(label("Old: GitHub main (%s)     New: current Blender overhaul"%manifest.baseline.substr(0,7),16))
 var pair=HBoxContainer.new()
 pair.size_flags_vertical=Control.SIZE_EXPAND_FILL
 pair.add_theme_constant_override("separation",14)
 layout.add_child(pair)
 for side in range(2):
  var frame=PanelContainer.new()
  frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  pair.add_child(frame)
  var column=VBoxContainer.new()
  frame.add_child(column)
  var heading=label("OLD · GitHub main" if side==0 else "NEW · Blender overhaul",20)
  heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  column.add_child(heading)
  var container=SubViewportContainer.new()
  container.stretch=true
  container.size_flags_vertical=Control.SIZE_EXPAND_FILL
  container.custom_minimum_size=Vector2(400,360)
  container.mouse_filter=Control.MOUSE_FILTER_STOP
  container.gui_input.connect(view_input)
  column.add_child(container)
  var viewport=SubViewport.new()
  viewport.size=Vector2i(600,580)
  viewport.own_world_3d=true
  viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
  viewport.msaa_3d=Viewport.MSAA_4X
  container.add_child(viewport)
  var empty=label("New addition\nNo previous model on GitHub main",22)
  empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  empty.add_theme_color_override("font_color",Color("49392a"))
  empty.mouse_filter=Control.MOUSE_FILTER_IGNORE
  empty.visible=false
  container.add_child(empty)
  var stage=Node3D.new()
  viewport.add_child(stage)
  var world=WorldEnvironment.new()
  world.environment=Environment.new()
  world.environment.background_mode=Environment.BG_COLOR
  world.environment.background_color=Color("bdb7a8")
  world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
  world.environment.ambient_light_color=Color("f6f0e3")
  world.environment.ambient_light_energy=.55
  world.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
  stage.add_child(world)
  var light=DirectionalLight3D.new()
  light.rotation_degrees=Vector3(-45,-35,0)
  light.light_energy=1.2
  light.shadow_enabled=true
  stage.add_child(light)
  var camera=Camera3D.new()
  camera.projection=Camera3D.PROJECTION_ORTHOGONAL
  camera.current=true
  stage.add_child(camera)
  var floor=MeshInstance3D.new()
  var plane=PlaneMesh.new()
  plane.size=Vector2(1000,1000)
  floor.mesh=plane
  var material=StandardMaterial3D.new()
  material.albedo_color=Color("777060")
  material.roughness=1
  floor.material_override=material
  stage.add_child(floor)
  var note=label("",15)
  note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  column.add_child(note)
  var keep=button("Keep old" if side==0 else "Keep new",func():choose("old" if side==0 else "new"))
  column.add_child(keep)
  if side==0:old_button=keep
  else:new_button=keep
  panels.append({"stage":stage,"viewport":viewport,"camera":camera,"floor":floor,"note":note,"model":null,"player":null,"target":Vector3.ZERO,"rest":[],"empty":empty})
 var controls=HBoxContainer.new()
 layout.add_child(controls)
 controls.add_child(label("Animation:",16))
 clips=OptionButton.new()
 clips.custom_minimum_size=Vector2(180,40)
 clips.item_selected.connect(func(_value):select_clip(clips.get_item_text(clips.selected)))
 controls.add_child(clips)
 playback=CheckButton.new()
 playback.text="Play"
 playback.button_pressed=true
 controls.add_child(playback)
 controls.add_child(button("Reset view",func():yaw=-.65;pitch=.28;zoom=1.0;update_cameras()))
 var spacing=Control.new()
 spacing.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 controls.add_child(spacing)
 previous=button("← Previous",func():navigate(index-1))
 controls.add_child(previous)
 next_button=button("Next →",func():navigate(index+1))
 controls.add_child(next_button)
 controls.add_child(button("Finish review",finish_review))
 layout.add_child(label("Drag either model to rotate both · Scroll to zoom · Arrow keys: previous / next · 1: keep old · 2: keep new",15))
 status=label("",16)
 layout.add_child(status)

func load_model(path: String) -> Node3D:
 if path=="procedural:main_footbridge":return main_footbridge()
 var document=GLTFDocument.new()
 var state=GLTFState.new()
 var error=document.append_from_file(path,state)
 if error!=OK:
  errors.append("Could not load "+path)
  return null
 var model=document.generate_scene(state) as Node3D
 if model:
  GardenArt.soften_fur(model)
  # Runtime imports have fresh resource IDs. The meshes retain their overrides;
  # do not hold every visited model's textures in the game's static material cache.
  GardenArt.fur_materials.clear()
 return model

func main_footbridge() -> Node3D:
 # Exact visual construction from GitHub main ca52914, garden.gd/make_bridge.
 var model=Node3D.new()
 for j in range(14):GardenArt.box(model,Vector3(-2.1+j*.32,.08,0),Vector3(.29,.15,1.8),Color("b9a180"))
 for z in [-.9,.9]:
  for x in [-2.1,0,2.1]:GardenArt.box(model,Vector3(x,.55,z),Vector3(.1,1,.1),Color("9b876c"))
  GardenArt.box(model,Vector3(0,.96,z),Vector3(4.5,.1,.1),Color("cbb694"))
 return model

func animations(node: Node) -> AnimationPlayer:
 if node is AnimationPlayer:return node
 for child in node.get_children():
  var found=animations(child)
  if found:return found
 return null

func capture_rest(node: Node, target: Array) -> void:
 if node is Node3D:
  var item={"node":node,"transform":node.transform,"poses":[]}
  if node is Skeleton3D:
   for bone in range(node.get_bone_count()):item.poses.append(node.get_bone_pose(bone))
  target.append(item)
 for child in node.get_children():capture_rest(child,target)

func restore_rest(panel: Dictionary) -> void:
 if panel.player:panel.player.stop()
 for item in panel.rest:
  item.node.transform=item.transform
  if item.node is Skeleton3D:
   for bone in range(item.poses.size()):item.node.set_bone_pose(bone,item.poses[bone])

func bounds(node: Node3D, owner: Node3D) -> AABB:
 var result=AABB()
 var initialized=false
 for child in node.get_children():
  if child is Node3D:
   var box=bounds(child,owner)
   if box.size.length_squared()>0:
    result=result.merge(box) if initialized else box
    initialized=true
 if node is MeshInstance3D and node.mesh:
  var box=owner.global_transform.affine_inverse()*node.global_transform*node.mesh.get_aabb()
  result=result.merge(box) if initialized else box
 return result

func show_pair() -> void:
 var entry=entries[index]
 title.text="%d / %d   %s"%[index+1,entries.size(),entry.name]
 selector.select(index)
 previous.disabled=index==0
 next_button.disabled=index==entries.size()-1
 old_button.disabled=entry.old.is_empty()
 var available: Array[String]=[]
 extent=.01
 for side in range(2):
  var panel=panels[side]
  if panel.model:panel.model.free()
  panel.model=null
  panel.player=null
  panel.rest=[]
  var path=entry.old if side==0 else entry.new
  panel.empty.visible=path.is_empty()
  panel.note.text="New addition · no model on main" if path.is_empty() else "Rest pose"
  if path.is_empty():continue
  var model=load_model(path)
  if not model:
   panel.note.text="Unable to load model"
   continue
  panel.stage.add_child(model)
  panel.model=model
  capture_rest(model,panel.rest)
  panel.player=animations(model)
  if panel.player:
   panel.player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
   for clip in panel.player.get_animation_list():
    if clip!="RESET" and clip not in available:available.append(clip)
  var box=bounds(model,model)
  # Center each model independently; preserve its real scale on both sides.
  panel.target=box.get_center()
  panel.floor.position.y=box.position.y-.008
  extent=maxf(extent,maxf(box.size.x,maxf(box.size.y,box.size.z)))
 clips.clear()
 clips.add_item("Rest pose")
 available.sort()
 for clip in available:clips.add_item(clip)
 var selected=available.find(selected_clip)
 clips.select(selected+1 if selected>=0 else 0)
 select_clip(clips.get_item_text(clips.selected))
 zoom=1.0
 update_cameras()
 refresh_choice()
 save_choices()

func update_cameras() -> void:
 for panel in panels:
  var camera=panel.camera
  var target: Vector3=panel.target
  camera.size=extent*1.40*zoom
  camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))*extent*3
  camera.look_at(target)
  camera.near=maxf(.0001,extent*.001)
  camera.far=maxf(20,extent*20)

func select_clip(clip: String) -> void:
 selected_clip=clip
 for panel in panels:
  if not panel.model:continue
  var player: AnimationPlayer=panel.player
  restore_rest(panel)
  if clip=="Rest pose":
   panel.note.text=entries[index].get("old_note","Rest pose · original scale") if panel==panels[0] else "Rest pose · original scale"
  elif player and player.has_animation(clip):
   player.get_animation(clip).loop_mode=Animation.LOOP_LINEAR
   player.play(clip)
   player.advance(0)
   panel.note.text=clip.capitalize()+" · authored animation"
  else:
   if player:player.stop()
   panel.note.text="No “%s” animation on this model · showing rest pose"%clip
  panel.floor.visible=clip not in ["flight","swim"]

func _process(delta: float) -> bool:
 if playback and playback.button_pressed:
  for panel in panels:
   if panel.player and panel.player.is_playing():panel.player.advance(delta)
 return false

func choose(variant: String) -> void:
 if variant=="old" and entries[index].old.is_empty():return
 if choices[entries[index].id]!=variant:review_finished=false
 choices[entries[index].id]=variant
 reviewed[entries[index].id]=true
 refresh_choice()
 save_choices()

func refresh_choice() -> void:
 var old=choices.get(entries[index].id,"new")=="old"
 GardenTheme.choose(old_button,old)
 GardenTheme.choose(new_button,not old)
 old_button.text="✓ Keep old" if old else "Keep old"
 new_button.text="Keep new" if old else "✓ Keep new"
 var old_count=choices.values().count("old")
 status.text="Choices saved automatically · %d reviewed · %d old / %d new · Finish review when you are ready."%[reviewed.size(),old_count,entries.size()-old_count]

func navigate(value: int) -> void:
 if value<0 or value>=entries.size():return
 reviewed[entries[index].id]=true
 index=value
 show_pair()

func save_choices(finished: bool=false) -> void:
 if smoke:return
 if finished:review_finished=true
 var models=[]
 for entry in entries:
  models.append({"id":entry.id,"asset":entry.asset,"new_sha256":entry.new_sha256,"has_old":not entry.old.is_empty()})
 var data={"schema":1,"baseline":manifest.baseline,"choices":choices,"reviewed":reviewed,"last_index":index,"finished":review_finished,"models":models}
 var file=FileAccess.open(choices_path()+".tmp",FileAccess.WRITE)
 if not file:
  status.text="Could not save choices: "+error_string(FileAccess.get_open_error())
  return
 file.store_string(JSON.stringify(data," ")+"\n")
 file.close()
 var error=DirAccess.rename_absolute(choices_path()+".tmp",choices_path())
 if error!=OK:status.text="Could not save choices: "+error_string(error)

func choices_path() -> String:
 return CACHE+"test_choices.json" if persistence_test else CHOICES

func finish_review() -> void:
 reviewed[entries[index].id]=true
 save_choices(true)
 refresh_choice()
 status.text="Review saved — your selected models are ready for the final game build. You can continue revising choices here."

func view_input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   zoom=clampf(zoom*(.9 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),.25,3.0)
   update_cameras()
 if event is InputEventMouseMotion and dragging:
  yaw-=event.relative.x*.008
  pitch=clampf(pitch+event.relative.y*.008,-1.2,1.3)
  update_cameras()

func _input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:dragging=false
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_RIGHT:navigate(index+1)
  if event.keycode==KEY_LEFT:navigate(index-1)
  if event.keycode==KEY_1:choose("old")
  if event.keycode==KEY_2:choose("new")
  if event.keycode in [KEY_RIGHT,KEY_LEFT,KEY_1,KEY_2]:root.set_input_as_handled()

func run_smoke() -> void:
 playback.button_pressed=false
 var target=0
 for i in range(entries.size()):
  if not entries[i].old.is_empty():target=i;break
 navigate(target)
 if choices[entries[index].id]!="new":errors.append("New model was not the default")
 choose("old")
 navigate(target+1)
 navigate(target)
 if choices[entries[index].id]!="old":errors.append("Selection did not survive navigation")
 choose("new")
 # Load every pair and exercise each authored clip to catch runtime GLTF errors.
 for i in range(entries.size()):
  navigate(i)
  for panel in panels:
   if not panel.model and not (panel==panels[0] and entries[i].old.is_empty()):errors.append("Missing model: "+entries[i].id)
  for n in range(1,clips.item_count):
   select_clip(clips.get_item_text(n))
   for panel in panels:
    if panel.player and panel.player.is_playing():panel.player.advance(.2)
  select_clip("Rest pose")
  for panel in panels:
   for item in panel.rest:
    if not item.node.transform.is_equal_approx(item.transform):errors.append("Rest transform was not restored: "+entries[i].id)
    if item.node is Skeleton3D:
     for bone in range(item.poses.size()):
      if not item.node.get_bone_pose(bone).is_equal_approx(item.poses[bone]):errors.append("Rest bone was not restored: "+entries[i].id)
  await process_frame
  if entries[i].id in ["shop/bench","scenery/garden_shed","scenery/lakeside_cottage","wildlife/wombat"]:
   for tick in range(3):await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(CACHE+entries[i].id.replace("/","_")+".png")
 navigate(0)
 for tick in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(CACHE+"comparison.png")
 print("MODEL_COMPARISON_RESULT: ",JSON.stringify(errors))
 quit(0 if errors.is_empty() else 1)

func run_persistence() -> void:
 navigate(0)
 choose("old")
 navigate(1)
 var saved=JSON.parse_string(FileAccess.get_file_as_string(choices_path()))
 if saved.choices[entries[0].id]!="old":errors.append("Old choice was not written to disk")
 if saved.choices[entries[1].id]!="new":errors.append("Untouched model did not default to new")
 choices={}
 reviewed={}
 index=0
 load_choices()
 if choices.get(entries[0].id,"")!="old" or index!=1:errors.append("Saved review did not resume")
 finish_review()
 saved=JSON.parse_string(FileAccess.get_file_as_string(choices_path()))
 if not saved.finished:errors.append("Finished state was not written")
 DirAccess.remove_absolute(choices_path())
 print("MODEL_COMPARISON_PERSISTENCE_RESULT: ",JSON.stringify(errors))
 quit(0 if errors.is_empty() else 1)
