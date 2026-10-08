class_name GardenCultivarPreview
extends SubViewportContainer

var model: Node3D
var turning=true
var dragging=false

func setup(g, f: Dictionary, flowering: bool=true) -> void:
 custom_minimum_size=Vector2(220,190)
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 stretch=true
 mouse_filter=Control.MOUSE_FILTER_STOP
 tooltip_text="Drag to turn this plant"
 turning=not g.settings.get("reduced_motion",false)
 var viewport=SubViewport.new()
 viewport.size=Vector2i(400,250);viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 var world=WorldEnvironment.new();var environment=Environment.new()
 environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("344637")
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color.WHITE;environment.ambient_light_energy=.7
 world.environment=environment;viewport.add_child(world)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-35,0);light.light_energy=1.1;viewport.add_child(light)
 var data=g.catalogue[int(f.species)]
 model=GardenArt.plant(data);viewport.add_child(model)
 var fraction=1.0 if flowering else .35
 model.scale=Vector3(1,GardenPlantBreeding.height_factor(f),1)
 GardenPlantGrowth.apply(model,data,fraction,int(f.seed),model.scale)
 GardenCultivarAppearance.apply(g,model,f)
 var height=maxf(.2,float(data.height)*GardenPlantBreeding.height_factor(f))
 var camera=Camera3D.new();viewport.add_child(camera)
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=maxf(.5,height*1.55)
 camera.position=Vector3(height*.45,height*.9,height*2.8+.5)
 camera.basis=Basis.looking_at(Vector3(0,height*.48,0)-camera.position);camera.current=true

func _process(delta: float) -> void:
 if is_instance_valid(model) and turning and not dragging:model.rotation.y+=delta*.18

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:dragging=event.pressed;accept_event()
 if event is InputEventMouseMotion and dragging and is_instance_valid(model):model.rotation.y+=event.relative.x*.012;accept_event()
 if event is InputEventScreenDrag and is_instance_valid(model):model.rotation.y+=event.relative.x*.012;accept_event()
