class_name GardenCultivarThumbnail
extends TextureRect

static var textures: Dictionary={}
static var renderer: Node
var garden
var selection: Dictionary
var cache_key=""

func setup(g, f: Dictionary) -> void:
 garden=g;selection=f
 cache_key=str(f.species)+":"+JSON.stringify(f.genes)+":"+str(f.foliage)+":"+str(int(f.seed)%16)
 texture=textures.get(cache_key,load(GardenArt.card_path("res://assets/ui/plants/%02d"%int(f.species))))
 expand_mode=TextureRect.EXPAND_IGNORE_SIZE;stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 custom_minimum_size=Vector2(96,106);mouse_filter=Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
 if textures.has(cache_key) or DisplayServer.get_name()=="headless":return
 if not is_instance_valid(renderer):
  renderer=preload("res://scripts/cultivar_portrait_renderer.gd").new()
  get_tree().root.add_child(renderer)
 renderer.enqueue(self,garden,selection,cache_key)
