extends Node

# One temporary model at a time, only for visible cards. Opening a large saved
# collection must not create hundreds of simultaneous 3D viewports.
var pending=[]
var busy=false

func enqueue(widget: TextureRect, garden: Node, selection: Dictionary, key: String) -> void:
 pending.append({"widget":weakref(widget),"garden":weakref(garden),"selection":selection.duplicate(true),"key":key})

func _process(_delta: float) -> void:
 if busy:return
 for request in pending.duplicate():
  var widget=request.widget.get_ref()
  var garden=request.garden.get_ref()
  if not is_instance_valid(widget) or not is_instance_valid(garden):pending.erase(request);continue
  if GardenCultivarThumbnail.textures.has(request.key):widget.texture=GardenCultivarThumbnail.textures[request.key];pending.erase(request);continue
  if not widget.is_visible_in_tree() or not widget.get_viewport().get_visible_rect().intersects(widget.get_global_rect()):continue
  pending.erase(request);busy=true;render(request);return

func render(request: Dictionary) -> void:
 var garden=request.garden.get_ref()
 var view=GardenCultivarPreview.new();view.setup(garden,request.selection);view.turning=false
 var viewport=view.get_child(0) as SubViewport
 view.remove_child(viewport);view.free()
 viewport.size=Vector2i(192,192)
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 for i in range(3):await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var image=viewport.get_texture().get_image()
 if not image.is_empty():
  var texture=ImageTexture.create_from_image(image)
  GardenCultivarThumbnail.textures[request.key]=texture
  if GardenCultivarThumbnail.textures.size()>128:GardenCultivarThumbnail.textures.erase(GardenCultivarThumbnail.textures.keys()[0])
  var widget=request.widget.get_ref()
  if is_instance_valid(widget):widget.texture=texture
 viewport.queue_free();busy=false
