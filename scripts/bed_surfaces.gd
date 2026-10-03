class_name GardenBedSurfaces
extends RefCounted

const FINISHES=[
 {"id":"soil","name":"Garden soil","price":0,"texture":"Garden_loam","scale":.72,"hint":"The familiar rich earth.","tint":Color.WHITE},
 {"id":"sand","name":"Desert sand","price":30,"texture":"beds/sand","scale":1.0,"hint":"Fine, warm sand for a desert planting.","tint":Color.WHITE},
 {"id":"gravel","name":"Japanese gravel","price":40,"texture":"beds/gravel","scale":1.0,"hint":"Pale, small stones for a quiet garden.","tint":Color.WHITE},
 {"id":"bark","name":"Pine bark mulch","price":25,"texture":"beds/bark","scale":1.0,"hint":"Warm woody chips around flowers and shrubs.","tint":Color.WHITE},
 {"id":"slate","name":"Blue slate chips","price":40,"texture":"beds/slate","scale":1.0,"hint":"Angular blue-grey stone for striking contrasts.","tint":Color.WHITE},
 {"id":"pebbles","name":"Warm pebble gravel","price":35,"texture":"beds/gravel","scale":.65,"hint":"Larger, softly coloured gravel for sunny beds.","tint":Color("d6bd97")},
 {"id":"compost","name":"Dark compost","price":20,"texture":"Garden_loam","scale":.9,"hint":"A deep, dark earth finish for lush planting.","tint":Color("827264")}
]

static func finish(id: String) -> Dictionary:
 for item in FINISHES:
  if item.id==id:return item
 return FINISHES[0]

static func restore(g,data: Dictionary) -> void:
 g.owned_surfaces=["soil"]
 var owned=data.get("owned_surfaces",[])
 if owned is Array:
  for value in owned:
   var id=str(value)
   if finish(id).id==id and id not in g.owned_surfaces:g.owned_surfaces.append(id)
 g.bed_surfaces.clear()
 var saved=data.get("bed_surfaces",{})
 if saved is Dictionary:
  for key in saved:
   if not str(key).is_valid_int():continue
   var index=int(key)
   var id=str(saved[key])
   if index>=0 and index<g.unlocked_plots and id in g.owned_surfaces:g.bed_surfaces[str(index)]=id

static func material(id: String) -> ShaderMaterial:
 var item=finish(id)
 var mat=GardenGroundFinish.material(true)
 mat.set_shader_parameter("earth",load("res://assets/textures/"+item.texture+".webp"))
 mat.set_shader_parameter("relief",load("res://assets/textures/"+item.texture+"_normal.webp"))
 mat.set_shader_parameter("tint",item.tint)
 mat.set_shader_parameter("texture_scale",item.scale)
 mat.set_shader_parameter("broad_mix",.08 if id in ["gravel","pebbles","slate","bark"] else .32)
 return mat

static func rebuild(g,center: Vector3=Vector3.INF) -> void:
 for key in g.bed_surfaces:
  var index=int(key)
  if index<0 or index>=g.unlocked_plots or index>=g.plots.size():continue
  var c: Vector3=g.plots[index].center
  if center.is_finite() and (absf(center.x-c.x)>8 or absf(center.z-c.z)>8):continue
  if g.bed_surface_nodes.has(key):
   var old=g.bed_surface_nodes[key]
   if is_instance_valid(old):old.free()
   g.bed_surface_nodes.erase(key)
  if g.bed_surfaces[key]=="soil":continue
  var st=SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  # Copy the actual sculpted soil triangles, including its full border. Using
  # the same triangles avoids clipping across a freshly raised or lowered bed.
  var count=0
  for entry in g.terrain_meshes:
   var source: MeshInstance3D=entry.node
   var mat=source.material_override as ShaderMaterial
   if not mat:continue
   var earth=mat.get_shader_parameter("earth") as Texture2D
   if not earth or not earth.resource_path.ends_with("Garden_loam.webp"):continue
   for surface in range(source.mesh.get_surface_count()):
    var arrays=source.mesh.surface_get_arrays(surface)
    var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
    if indices.is_empty():
     for vertex in range(vertices.size()):indices.append(vertex)
    for triangle in range(0,indices.size(),3):
     var points: Array[Vector3]=[]
     for k in range(3):points.append(source.global_transform*vertices[indices[triangle+k]])
     var midpoint=(points[0]+points[1]+points[2])/3
     if absf(midpoint.x-c.x)>4.76 or absf(midpoint.z-c.z)>4.76:continue
     for v in points:
      st.set_uv(Vector2(v.x,v.z))
      st.add_vertex(v+Vector3(0,.004,0))
      count+=1
  if count==0:continue
  st.generate_normals()
  st.generate_tangents()
  st.index()
  var mesh=MeshInstance3D.new()
  mesh.name="BedSurface"+key
  mesh.mesh=st.commit()
  mesh.material_override=material(g.bed_surfaces[key])
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  g.world_root.add_child(mesh)
  g.bed_surface_nodes[key]=mesh

static func apply(g,index: int,id: String) -> bool:
 if index<0 or index>=g.unlocked_plots or index>=g.plots.size():
  g.toast("Choose an open bed first.");return false
 var item=finish(id)
 if item.id!=id:return false
 if id not in g.owned_surfaces:
  if g.coins<item.price:g.toast("This surface costs %d petals."%item.price);return false
  g.coins-=int(item.price)
  g.owned_surfaces.append(id)
 g.bed_surfaces[str(index)]=id
 rebuild(g,g.plots[index].center)
 g.save_game()
 g.refresh_ui()
 g.toast(item.name+" covers "+g.plots[index].name+". Switch finishes freely once owned.")
 return true

static func shop(g) -> void:
 g.add_note("BED SURFACES",14)
 g.add_note("Buy a finish once, then use it on any open bed. Changes cover the whole bed and leave your plants in place.")
 var chooser=OptionButton.new()
 chooser.name="SurfaceBedChoice"
 chooser.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 chooser.custom_minimum_size.y=40
 for i in range(g.unlocked_plots):chooser.add_item(g.plots[i].name,i)
 g.surface_shop_plot=clampi(g.surface_shop_plot,0,g.unlocked_plots-1)
 chooser.select(g.surface_shop_plot)
 chooser.item_selected.connect(func(index):g.surface_shop_plot=index;g.refresh_sidebar())
 g.list_box.add_child(chooser)
 var chosen=g.surface_shop_plot
 var selected=str(g.bed_surfaces.get(str(chosen),"soil"))
 for item in FINISHES:
  var id: String=item.id
  var owned=id in g.owned_surfaces
  var action="Selected" if selected==id else "Apply" if owned else "%d petals · Buy & apply"%item.price
  var row=g.button("",func():apply(g,chosen,id),Vector2(0,76))
  row.name="Surface_"+id
  row.disabled=selected==id or not owned and g.coins<int(item.price)
  row.tooltip_text=item.hint
  var content=HBoxContainer.new()
  content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  content.offset_left=10;content.offset_right=-10;content.offset_top=8;content.offset_bottom=-8
  content.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var swatch=TextureRect.new()
  swatch.texture=load("res://assets/textures/"+item.texture+".webp")
  swatch.modulate=item.tint
  swatch.custom_minimum_size=Vector2(40,40)
  swatch.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  swatch.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  swatch.mouse_filter=Control.MOUSE_FILTER_IGNORE
  content.add_child(swatch)
  var words=VBoxContainer.new()
  words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  words.mouse_filter=Control.MOUSE_FILTER_IGNORE
  for text in [item.name,action]:
   var caption=g.label(text,14)
   caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
   words.add_child(caption)
  content.add_child(words)
  row.add_child(content)
  g.list_box.add_child(row)
