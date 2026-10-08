extends SceneTree

class ReviewGarden:
 extends "res://scripts/garden.gd"
 var phone=false
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass
 func touch_active() -> bool:return phone

func _initialize() -> void:call_deferred("review")

func review() -> void:
 var g=ReviewGarden.new()
 root.add_child(g)
 g.make_ui()
 g.climate=GardenClimate.new()
 g.add_child(g.climate)
 g.player=CharacterBody3D.new()
 g.add_child(g.player)
 g.world_root=Node3D.new()
 g.add_child(g.world_root)
 g.plant_root=Node3D.new()
 g.add_child(g.plant_root)
 g.sun=DirectionalLight3D.new()
 g.add_child(g.sun)
 g.selected=148
 g.unlocked_plants=range(g.catalogue.size())
 g.collection_filters.group="Orchids"
 g.collection_filters.sort="Height: low to high"
 g.refresh_sidebar()
 g.side_panel.show()
 g.touch=GardenTouch.new()
 g.add_child(g.touch)
 g.touch.setup(g)
 g.touch.set_process(false)
 var directory="res://captures/flower-collection"
 DirAccess.make_dir_recursive_absolute(directory)
 for phone in [false,true]:
  g.phone=phone
  root.size=Vector2i(390,844) if phone else Vector2i(1280,900)
  root.content_scale_size=root.size
  g.refresh_sidebar()
  if phone:
   g.settings.controls="touch"
   g.touch.configure()
   g.touch._process(0)
  else:GardenInterface.layout(g,true)
  for frame in range(6):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(directory+("/phone.png" if phone else "/desktop.png"))
 g.free()
 print("FLOWER_COLLECTION_REVIEW: PASS")
 quit()
