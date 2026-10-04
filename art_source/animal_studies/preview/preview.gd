extends Node3D

const SPECIES=["dog","fox","echidna","rabbit","cat","wombat"]
const CLIPS={"dog":["idle","walk","sniff","look"],"fox":["idle","walk","look"],"echidna":["idle","walk","forage","look"],"rabbit":["idle","hop","forage","look"],"cat":["idle","walk","look"],"wombat":["idle","walk","forage","look","rest"]}
var kind="dog"
var models: Array[Node3D]=[]
var players: Array[AnimationPlayer]=[]
var camera: Camera3D
var labels: Array[Label3D]=[]
var title: Label
var status: Label
var motions: HBoxContainer
var yaw=-.4
var pitch=.23
var distance=1.85
var clip="idle"
var paused=false
var dragging=false
var capture_mode=false
var elapsed=0.0
var old_body: Node3D
var old_rest=Vector3.ZERO
var load_report={}

func _ready() -> void:
 capture_mode="--capture" in OS.get_cmdline_user_args()
 var environment=WorldEnvironment.new();environment.environment=Environment.new()
 environment.environment.background_mode=Environment.BG_COLOR
 environment.environment.background_color=Color("b9b6a9")
 environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color=Color("eef1f4")
 environment.environment.ambient_light_energy=.30
 environment.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 add_child(environment)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-48,-32,0)
 light.light_energy=.8;light.shadow_enabled=true;add_child(light)
 var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(60,60);floor.mesh=plane
 var mat=StandardMaterial3D.new();mat.albedo_color=Color("73766b");mat.roughness=1;floor.material_override=mat;add_child(floor)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.55
 camera.current=true;add_child(camera);update_camera();build_ui()
 for value in OS.get_cmdline_user_args():
  if value.begins_with("--animal="):kind=value.trim_prefix("--animal=")
 load_species(kind)
 if capture_mode:call_deferred("capture")

func load_species(value: String) -> void:
 if value not in SPECIES:return
 for node in models:remove_child(node);node.queue_free()
 for label in labels:remove_child(label);label.queue_free()
 models.clear();players.clear();labels.clear();old_body=null;kind=value;elapsed=0
 var old_path="../baseline/"+kind+".glb"
 var new_path="../../cat_study/export/cat_study.glb" if kind=="cat" else "../%s/export/%s.glb"%[kind,kind]
 var heights={"dog":.52,"fox":.52,"cat":.52,"rabbit":.43,"echidna":.33,"wombat":.45}
 var report=[]
 for i in range(2):
  var file=ProjectSettings.globalize_path("res://"+([old_path,new_path][i])).simplify_path()
  var doc=GLTFDocument.new();var state=GLTFState.new();state.use_named_skin_binds=true
  var error=doc.append_from_file(file,state,GLTFDocument.IMPORT_FLAG_USE_NAMED_SKIN_BINDS)
  if error!=OK:push_error("Animal load failed: %s (%s)"%[file,error]);get_tree().quit(1);return
  var asset=doc.generate_scene(state,30,false,false) as Node3D
  var model=Node3D.new();add_child(model);model.add_child(asset);models.append(model);soften_fur(model)
  var player=find_player(model);players.append(player)
  if player:
   player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
   player.play("idle",0);player.advance(0)
  var bounds=mesh_bounds(model)
  if bounds.size.y>.001:model.scale=Vector3.ONE*(heights[kind]/bounds.size.y)
  model.position=Vector3(.42 if i==0 else -.42,-bounds.position.y*model.scale.y,0)
  if i==0:old_body=model.find_child("Body*",true,false);old_rest=old_body.position if old_body else Vector3.ZERO
  var label=Label3D.new();label.text="Previous game "+kind if i==0 else "Your STL · textured and rigged"
  label.font_size=32;label.pixel_size=.0007;label.position=Vector3(model.position.x,.65,0)
  label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("33251b");label.outline_modulate=Color("eee6d8");add_child(label);labels.append(label)
  report.append({"model":"previous" if i==0 else "prototype","animations":Array(player.get_animation_list()) if player else [],"height":bounds.size.y,"textured_surfaces":count_textured(model),"renderer":RenderingServer.get_current_rendering_method()})
  if i==1:
   assert(player and player.has_animation("idle"),"Prototype animation missing")
   for required in CLIPS[kind]:assert(player.has_animation(required),"Prototype clip missing: "+required)
   assert(count_textured(model)>0,"Prototype WebP textures missing")
 load_report[kind]=report
 title.text=kind.capitalize()+" · STL modelling experiment"
 for node in motions.get_children():motions.remove_child(node);node.queue_free()
 for name in CLIPS[kind]:
  var button=Button.new();button.text=name.capitalize();motions.add_child(button);button.pressed.connect(func():play_clip(name))
 play_clip("idle")

func find_player(node: Node) -> AnimationPlayer:
 if node is AnimationPlayer:return node
 for child in node.get_children():
  var found=find_player(child)
  if found:return found
 return null

func count_textured(node: Node) -> int:
 var count=0
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var mat=node.mesh.surface_get_material(surface) as StandardMaterial3D
   if mat and mat.albedo_texture:count+=1
 for child in node.get_children():count+=count_textured(child)
 return count

func soften_fur(node: Node) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var mat=node.mesh.surface_get_material(surface) as StandardMaterial3D
   if mat and mat.resource_name.begins_with("Fur cards "):
    node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var soft=mat.duplicate() as StandardMaterial3D;soft.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
    soft.diffuse_mode=BaseMaterial3D.DIFFUSE_LAMBERT_WRAP;soft.metallic_specular=.12;soft.roughness=.94
    node.set_surface_override_material(surface,soft)
 for child in node.get_children():soften_fur(child)

func mesh_bounds(root: Node3D) -> AABB:
 var result=AABB();var first=true
 for child in root.find_children("*","MeshInstance3D",true,false):
  var mesh=child as MeshInstance3D
  var box=(root.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
  # A skinned mesh's stored AABB describes the bind pose, not the current coat.
  # Measure its posed vertices once so both animals really have equal height.
  if mesh.skin:
   var skeleton=mesh.get_node_or_null(mesh.skeleton) as Skeleton3D
   if skeleton:
    var transforms: Array[Transform3D]=[]
    for bind in range(mesh.skin.get_bind_count()):
     var bone=mesh.skin.get_bind_bone(bind)
     if bone<0:bone=skeleton.find_bone(mesh.skin.get_bind_name(bind))
     transforms.append(skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind))
    var global=root.global_transform.affine_inverse()*skeleton.global_transform
    var low=Vector3(INF,INF,INF);var high=Vector3(-INF,-INF,-INF)
    for surface in range(mesh.mesh.get_surface_count()):
     var arrays=mesh.mesh.surface_get_arrays(surface)
     var vertices=arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
     var bones=arrays[Mesh.ARRAY_BONES] as PackedInt32Array
     var weights=arrays[Mesh.ARRAY_WEIGHTS] as PackedFloat32Array
     var influences=bones.size()/vertices.size()
     for vertex in range(vertices.size()):
      var point=Vector3.ZERO
      for j in range(influences):
       var offset=vertex*influences+j
       if weights[offset]>0:point+=(transforms[bones[offset]]*vertices[vertex])*weights[offset]
      point=global*point;low=low.min(point);high=high.max(point)
    box=AABB(low,high-low)
  result=box if first else result.merge(box);first=false
 return result

func build_ui() -> void:
 var canvas=CanvasLayer.new();add_child(canvas)
 var panel=PanelContainer.new();panel.position=Vector2(22,20);canvas.add_child(panel)
 var style=StyleBoxFlat.new();style.bg_color=Color("493329");style.border_color=Color("b69565");style.set_border_width_all(2)
 style.content_margin_left=14;style.content_margin_right=14;style.content_margin_top=10;style.content_margin_bottom=10;panel.add_theme_stylebox_override("panel",style)
 var col=VBoxContainer.new();panel.add_child(col)
 title=Label.new();col.add_child(title)
 var animals=HBoxContainer.new();col.add_child(animals)
 for value in SPECIES:
  var button=Button.new();button.text=value.capitalize();animals.add_child(button);button.pressed.connect(func():load_species(value))
 motions=HBoxContainer.new();col.add_child(motions)
 var pause=Button.new();pause.text="Pause / resume";animals.add_child(pause);pause.pressed.connect(func():paused=not paused)
 status=Label.new();col.add_child(status)
 var note=Label.new();note.text="Same height and lighting. Separate prototypes for review.";col.add_child(note)

func play_clip(value: String) -> void:
 clip=value;status.text="%s · drag to orbit · wheel to zoom · Space pauses"%value.capitalize()
 for i in range(players.size()):
  var player=players[i]
  if not player:continue
  var requested=clip
  if i==0:requested={"look":"alert","forage":"graze","sniff":"graze","hop":"walk","rest":"idle"}.get(clip,clip)
  var available=""
  for name in player.get_animation_list():
   if String(name).to_lower()==requested or String(name).to_lower().ends_with("/"+requested):available=name;break
  if available.is_empty():player.stop();continue
  player.get_animation(available).loop_mode=Animation.LOOP_LINEAR;player.play(available,0.0 if capture_mode else .15);player.advance(0)

func _process(delta: float) -> void:
 if paused:return
 elapsed+=delta;update_old_motion(elapsed)
 for player in players:
  if player:player.advance(delta)

func update_old_motion(time: float) -> void:
 if models.is_empty() or players[0]:return
 var moving=clip in ["walk","hop"];var phase=time*8
 if old_body:
  old_body.position=old_rest+Vector3(0,sin(phase*2)*.012*float(moving)+sin(phase*.24)*.007,0)
  var names=["FrontL","FrontR","BackL","BackR"]
  for j in range(4):
   var leg=models[0].find_child(names[j]+"*",true,false) as Node3D
   if leg:leg.rotation.x=sin(phase+(PI if j in [1,2] else 0.0))*.48*float(moving)
 if kind=="rabbit":models[0].position.y=absf(sin(time*11))*.08 if moving else 0.0
 var head=models[0].find_child("Head*",true,false) as Node3D
 if head:head.rotation.x=sin(phase*.3)*.07;head.rotation.y=.35*sin(time*TAU/5) if clip=="look" else 0.0
 var tail=models[0].find_child("Tail*",true,false) as Node3D
 if tail:tail.rotation.y=sin(phase*.6)*.16
 for name in ["EarL","EarR"]:
  var ear=models[0].find_child(name+"*",true,false) as Node3D
  if ear:ear.rotation.z=sin(phase*.31)*.055+pow(maxf(0,sin(phase*.12)),12)*.13

func update_camera() -> void:
 var center=Vector3(0,.29,0);camera.position=center+Vector3(sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))*distance;camera.look_at(center)

func _unhandled_input(event: InputEvent) -> void:
 if capture_mode:return
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:camera.size=clampf(camera.size*(.90 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.1),.45,3)
 if event is InputEventMouseMotion and dragging:yaw-=event.relative.x*.008;pitch=clampf(pitch+event.relative.y*.005,.05,1.2);update_camera()
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_SPACE:paused=not paused
  if event.keycode==KEY_ESCAPE:get_tree().quit()

func capture() -> void:
 paused=true
 for species in ([kind] if "--single" in OS.get_cmdline_user_args() else ["fox","dog","echidna","rabbit"]):
  load_species(species)
  var folder=ProjectSettings.globalize_path("res://../%s/previews/godot"%species);DirAccess.make_dir_recursive_absolute(folder)
  for value in CLIPS[species]:
   play_clip(value)
   var count=36 if value in ["walk","hop"] else 48 if value in ["forage","sniff","look"] else 24
   for frame in range(count):
    var fraction=float(frame)/count
    update_old_motion(fraction*(1.2 if value in ["walk","hop"] else 6.0))
    for player in players:
     if player and not player.current_animation.is_empty():player.seek(player.current_animation_length*fraction,true);player.advance(0)
    for tick in range(3):await get_tree().process_frame
    RenderingServer.force_draw(false);get_viewport().get_texture().get_image().save_png(folder+"/%s_%02d.png"%[value,frame])
  print("ANIMAL_STUDIES_GODOT: rendered "+species)
 var validation_path="res://../%s/godot_validation.json"%kind if "--single" in OS.get_cmdline_user_args() else "res://../godot_validation.json"
 var file=FileAccess.open(validation_path,FileAccess.WRITE);file.store_string(JSON.stringify(load_report,"  "))
 print("ANIMAL_STUDIES_GODOT: PASS — selected prototypes, WebP surfaces and motions rendered");get_tree().quit()
