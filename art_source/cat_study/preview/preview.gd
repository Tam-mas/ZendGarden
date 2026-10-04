extends Node3D

var players: Array[AnimationPlayer]=[]
var camera: Camera3D
var yaw=-.4
var pitch=.23
var distance=1.85
var clip="idle"
var dragging=false
var status: Label
var paused=false
var capture_mode=false
var old_model: Node3D
var old_body: Node3D
var old_rest=Vector3.ZERO
var elapsed=0.0

func _ready() -> void:
 capture_mode="--capture" in OS.get_cmdline_user_args()
 var environment=WorldEnvironment.new()
 environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("b9b6a9")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color("eef1f4")
 environment.environment.ambient_light_energy=.30
 environment.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 add_child(environment)
 var light=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-48,-32,0)
 light.light_energy=.8
 light.shadow_enabled=true
 add_child(light)
 var floor=MeshInstance3D.new()
 var plane=PlaneMesh.new()
 plane.size=Vector2(60,60)
 floor.mesh=plane
 var mat=StandardMaterial3D.new()
 mat.albedo_color=Color("73766b");mat.roughness=1
 floor.material_override=mat
 add_child(floor)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.5
 camera.current=true;add_child(camera);update_camera()
 var paths=["../../../assets/companions/cat.glb","../export/cat_study.glb"]
 for i in range(2):
  var document=GLTFDocument.new();var state=GLTFState.new()
  var file=ProjectSettings.globalize_path("res://"+paths[i]).simplify_path()
  var error=document.append_from_file(file,state)
  if error!=OK:
   push_error("Could not load cat: %s (%s)"%[file,error]);get_tree().quit(1);return
  var model=document.generate_scene(state) as Node3D
  add_child(model)
  soften_fur(model)
  var player=find_player(model)
  if player:
   player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
   player.stop()
   players.append(player)
  var bounds=mesh_bounds(model,model)
  if bounds.size.y>.001:model.scale=Vector3.ONE*(.52/bounds.size.y)
  model.position=Vector3(.38 if i==0 else -.38,-bounds.position.y*model.scale.y,0)
  if i==0:
   old_model=model
   old_body=old_model.find_child("Body*",true,false)
   if old_body:old_rest=old_body.position
  var label=Label3D.new()
  label.text="Current game cat" if i==0 else "Your STL · textured and rigged"
  label.font_size=36;label.pixel_size=.0007
  label.position=Vector3(model.position.x,.65,0)
  label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  label.modulate=Color("33251b");label.outline_modulate=Color("eee6d8")
  add_child(label)
 build_ui();play_clip("idle")
 if capture_mode:call_deferred("capture")

func find_player(node: Node) -> AnimationPlayer:
 if node is AnimationPlayer:return node
 for child in node.get_children():
  var found=find_player(child)
  if found:return found
 return null

func soften_fur(node: Node) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var material=node.mesh.surface_get_material(surface) as StandardMaterial3D
   if material and material.resource_name.begins_with("Fur cards "):
    node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var soft=material.duplicate() as StandardMaterial3D
    # Smooth alpha avoids a stippled coat at this prototype's viewing distance.
    soft.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
    soft.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
    soft.metallic_specular=.18;soft.roughness=.88
    node.set_surface_override_material(surface,soft)
 for child in node.get_children():soften_fur(child)

func mesh_bounds(root: Node3D,node: Node3D) -> AABB:
 var result=AABB();var first=true
 for child in node.find_children("*","MeshInstance3D",true,false):
  var mesh=child as MeshInstance3D
  var box=(root.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  result=box if first else result.merge(box);first=false
 return result

func build_ui() -> void:
 var canvas=CanvasLayer.new();add_child(canvas)
 var panel=PanelContainer.new();panel.position=Vector2(22,20);canvas.add_child(panel)
 var style=StyleBoxFlat.new();style.bg_color=Color("493329")
 style.border_color=Color("b69565");style.set_border_width_all(2)
 style.content_margin_left=14;style.content_margin_right=14
 style.content_margin_top=10;style.content_margin_bottom=10
 panel.add_theme_stylebox_override("panel",style)
 var col=VBoxContainer.new();panel.add_child(col)
 var title=Label.new();title.text="Cat modelling experiment";col.add_child(title)
 var row=HBoxContainer.new();col.add_child(row)
 for value in ["idle","walk","look"]:
  var button=Button.new();button.text=value.capitalize();row.add_child(button)
  button.pressed.connect(func():play_clip(value))
 var pause_button=Button.new();pause_button.text="Pause / resume";row.add_child(pause_button)
 pause_button.pressed.connect(func():paused=not paused)
 status=Label.new();status.text="Drag to orbit · wheel to zoom · 1/2/3 change motion · Space pauses"
 col.add_child(status)
 var note=Label.new();note.text="Same height and lighting. Prototype only; your garden cat is unchanged."
 col.add_child(note)

func play_clip(value: String) -> void:
 clip=value
 for player in players:
  var available=""
  for name in player.get_animation_list():
   if String(name).to_lower()==clip or String(name).to_lower().ends_with("/"+clip):available=name;break
  if available.is_empty():player.stop();continue
  player.get_animation(available).loop_mode=Animation.LOOP_LINEAR
  player.play(available,0.0 if capture_mode else .15);player.advance(0)

func _process(delta: float) -> void:
 if paused:return
 elapsed+=delta
 update_old_motion(elapsed)
 for player in players:player.advance(delta)

func update_old_motion(time: float) -> void:
 # Match the existing companion controller's rigid motion, including its idle
 # breathing, head movement and tail sway. No frozen-model comparison.
 if not old_body:return
 var phase=time*8.0
 var gait=1.0 if clip=="walk" else 0.0
 old_body.position=old_rest+Vector3(0,sin(phase*2)*.012*gait+sin(phase*.24)*.007,0)
 var names=["FrontL","FrontR","BackL","BackR"]
 for j in range(4):
  var leg=old_model.find_child(names[j]+"*",true,false) as Node3D
  if leg:leg.rotation.x=sin(phase+(PI if j in [1,2] else 0.0))*.48*gait
 var tail=old_model.find_child("Tail*",true,false) as Node3D
 if tail:tail.rotation.y=sin(phase*.6)*.16
 var head=old_model.find_child("Head*",true,false) as Node3D
 if head:
  head.rotation.x=sin(phase*.3)*.07
  head.rotation.y=.35*sin(time*TAU/5) if clip=="look" else 0.0
 for name in ["EarL","EarR"]:
  var ear=old_model.find_child(name+"*",true,false) as Node3D
  if ear:ear.rotation.z=sin(phase*.31)*.055+pow(maxf(0,sin(phase*.12)),12)*.13

func update_camera() -> void:
 var center=Vector3(0,.29,0)
 camera.position=center+Vector3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))*distance
 camera.look_at(center)

func _unhandled_input(event: InputEvent) -> void:
 if capture_mode:return
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   camera.size=clampf(camera.size*(.90 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),.45,3)
 if event is InputEventMouseMotion and dragging:
  yaw-=event.relative.x*.008;pitch=clampf(pitch+event.relative.y*.005,.05,1.2);update_camera()
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_1:play_clip("idle")
  if event.keycode==KEY_2:play_clip("walk")
  if event.keycode==KEY_3:play_clip("look")
  if event.keycode==KEY_SPACE:paused=not paused
  if event.keycode==KEY_ESCAPE:get_tree().quit()

func capture() -> void:
 paused=true
 # Force capture frames even when macOS occludes the review window.
 DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
 var folder=ProjectSettings.globalize_path("res://../previews/godot")
 DirAccess.make_dir_recursive_absolute(folder)
 for value in ["idle","walk","look"]:
  play_clip(value)
  var count=36 if value=="walk" else 96 if value=="idle" else 60
  for frame in range(count):
   update_old_motion((1.2 if value=="walk" else 8.0 if value=="idle" else 5.0)*float(frame)/count)
   for player in players:
    if not player.current_animation.is_empty():
     player.seek(player.current_animation_length*float(frame)/count,true)
     player.advance(0)
   for tick in range(3):await get_tree().process_frame
   RenderingServer.force_draw(false)
   get_viewport().get_texture().get_image().save_png(folder+"/%s_%02d.png"%[value,frame])
 print("CAT_STUDY_GODOT: PASS — both models and three motions rendered")
 get_tree().quit()
