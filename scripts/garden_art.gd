class_name GardenArt
extends RefCounted

static var detail_scenes: Dictionary = {}
static var materials: Dictionary = {}
static var botanical_scenes: Dictionary = {}
static var leaf_materials: Dictionary = {}

static func mat(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
 var key = color.to_html() + str(roughness)
 if materials.has(key): return materials[key]
 var m = StandardMaterial3D.new()
 m.albedo_color = color
 m.roughness = roughness
 if color.a < 1.0:
  m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  m.cull_mode = BaseMaterial3D.CULL_DISABLED
 materials[key] = m
 return m

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
 var n = MeshInstance3D.new()
 n.mesh = shape
 n.material_override = mat(color)
 n.position = pos
 parent.add_child(n)
 return n

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var s = BoxMesh.new()
 s.size = size
 return mesh(parent, s, pos, color)

static func ball(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var s = SphereMesh.new()
 s.radial_segments = 10
 s.rings = 5
 s.radius = 0.5
 s.height = 1.0
 var n = mesh(parent, s, pos, color)
 n.scale = size
 return n

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
 var s = CylinderMesh.new()
 s.top_radius = radius if top < 0 else top
 s.bottom_radius = radius
 s.height = height
 s.radial_segments = 10
 return mesh(parent, s, pos, color)

static func branch(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> void:
 var n = cylinder(parent, (a+b)*0.5, width, a.distance_to(b), color, width*0.7)
 n.quaternion = Quaternion(Vector3.UP, (b-a).normalized())

static func plant(data: Dictionary, decorative: bool = false) -> Node3D:
 var path="res://assets/plants/plant_%02d.glb" % int(data.id)
 if ResourceLoader.exists(path):
  if not botanical_scenes.has(path): botanical_scenes[path]=load(path)
  var root=Node3D.new()
  var imported=botanical_scenes[path].instantiate()
  root.add_child(imported)
  add_leaf_wind(imported)
  var bloom=Node3D.new()
  bloom.name="Bloom"
  root.add_child(bloom)
  collect_blooms(imported,bloom)
  if decorative: root.rotation.y=float(data.id)*2.39996
  return root
 return fallback_plant(data,decorative)

static func add_leaf_wind(node: Node) -> void:
 if node is MeshInstance3D:
  for surface in range(node.mesh.get_surface_count()):
   var original=node.mesh.surface_get_material(surface)
   if original is StandardMaterial3D and str(original.resource_name).begins_with("Leaf"):
    var key=original.resource_name
    if not leaf_materials.has(key):
     var material=ShaderMaterial.new()
     material.shader=load("res://shaders/leaf_wind.gdshader")
     material.set_shader_parameter("leaf_texture",original.albedo_texture)
     material.set_shader_parameter("leaf_color",original.albedo_color)
     material.set_shader_parameter("leaf_normal",original.normal_texture)
     material.set_shader_parameter("leaf_roughness",original.roughness_texture)
     material.set_shader_parameter("has_normal_map",original.normal_enabled and original.normal_texture!=null)
     material.set_shader_parameter("has_roughness_map",original.roughness_texture!=null)
     leaf_materials[key]=material
    node.set_surface_override_material(surface,leaf_materials[key])
 for child in node.get_children(): add_leaf_wind(child)

static func collect_blooms(node: Node, target: Node3D) -> void:
 for child in node.get_children():
  if str(child.name).begins_with("Bloom"):
   child.owner=null
   node.remove_child(child)
   target.add_child(child)
  else: collect_blooms(child,target)

static func fallback_plant(data: Dictionary, decorative: bool = false) -> Node3D:
 var n = Node3D.new()
 var tint: Color = data.color
 var layer: int = data.layer
 var stem = Color("628557")
 var leaf = Color("7d9b64")
 var bloom = Node3D.new()
 bloom.name = "Bloom"
 n.add_child(bloom)
 var rng = RandomNumberGenerator.new()
 rng.seed = data.id * 91 + 34
 if layer == 3:
  cylinder(n, Vector3(0,1.35,0),0.14,2.7,Color("8e7863"),0.09)
  for j in range(5):
   var angle = j * TAU / 5
   var p = Vector3(cos(angle)*0.72, 2.35 + rng.randf()*0.55, sin(angle)*0.72)
   branch(n, Vector3(0,1.5,0), p,0.06,Color("8e7863"))
   ball(bloom,p,Vector3(1.6,1.35,1.6),tint.lerp(leaf,0.30 if j%2 else 0.0))
  ball(bloom,Vector3(0,3.15,0),Vector3(1.8,1.55,1.8),tint)
 elif layer == 2:
  for j in range(7):
   var p = Vector3(rng.randf_range(-0.45,0.45),rng.randf_range(0.5,1.0),rng.randf_range(-0.45,0.45))
   branch(n,Vector3.ZERO,p,0.025,stem)
   ball(n,p,Vector3(0.7,0.7,0.7),leaf)
   ball(bloom,p+Vector3(0,0.29,0.1),Vector3(0.23,0.19,0.23),tint)
 elif data.category == "Grasses" or (data.category == "Natives" and layer == 0):
  for j in range(9):
   var a = j * 2.4
   var end = Vector3(cos(a)*0.3, rng.randf_range(0.25,0.65),sin(a)*0.3)
   branch(n,Vector3.ZERO,end,0.025,leaf.lerp(tint,0.5))
   ball(bloom,end,Vector3(0.06,0.22,0.06),tint)
 else:
  var count = 5 if layer == 0 else 4
  for j in range(count):
   var a = j * 2.4
   var h = rng.randf_range(0.45,0.95) if layer == 1 else rng.randf_range(0.14,0.3)
   var p = Vector3(cos(a)*0.23,h,sin(a)*0.23)
   branch(n,Vector3(p.x,0,p.z),p,0.018,stem)
   var l = ball(n,p*Vector3(1,0.5,1)+Vector3(0.09,0,0),Vector3(0.3,0.075,0.12),leaf)
   l.rotation.z = 0.4
   if data.category == "Produce":
    ball(bloom,p,Vector3(0.22,0.26,0.22),tint)
   else:
    for k in range(5):
     var b = k*TAU/5
     ball(bloom,p+Vector3(cos(b)*0.11,0,sin(b)*0.11),Vector3(0.19,0.065,0.19),tint)
    ball(bloom,p+Vector3(0,0.035,0),Vector3(0.11,0.08,0.11),Color("efd18a"))
 if decorative: n.rotation.y = rng.randf()*TAU
 return n

# Each face is one-sided: the board never exposes mirrored lettering.
static func sign_board() -> Node3D:
 var n=detailed_model("shop", "sign")
 for back in [false,true]:
  var face=Label3D.new()
  face.name="BackText" if back else "FrontText"
  face.position=Vector3(0,.62,-.056 if back else .056)
  face.rotation.y=PI if back else 0.0
  face.double_sided=false
  face.font_size=40
  face.pixel_size=.002
  face.width=810
  face.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  face.outline_size=3
  face.outline_modulate=Color("30291f")
  n.add_child(face)
 set_sign_text(n,"My garden",Color("f1e5c7"))
 return n

static func clean_sign_text(value: String) -> String:
 return value.replace("\n"," ").replace("\r"," ").replace("\t"," ").strip_edges().left(64)

static func set_sign_text(node: Node3D, value: String, color: Color = Color("f1e5c7")) -> void:
 for face_name in ["FrontText","BackText"]:
  var face=node.get_node_or_null(face_name) as Label3D
  if face:
   face.text=value
   face.modulate=Color(color.r,color.g,color.b,1.0)

# Cache PackedScenes so repeated furnishings and wildlife share mesh/texture resources.
static func detailed_model(folder: String, kind: String) -> Node3D:
 var path="res://assets/%s/%s.glb" % [folder,kind]
 if not detail_scenes.has(path): detail_scenes[path]=load(path)
 var scene=detail_scenes[path].instantiate()
 # Blender exports an identity scene wrapper around the asset root.
 if scene.get_child_count()==1 and scene.get_child(0) is Node3D:
  var asset=scene.get_child(0)
  asset.owner=null
  scene.remove_child(asset)
  scene.free()
  return asset
 return scene

static func furnishing(kind: String) -> Node3D:
 if kind=="sign": return sign_board()
 var n=detailed_model("shop",kind)
 if kind=="lantern":
  var light=OmniLight3D.new()
  light.position.y=1
  light.light_color=Color("ffdc9e")
  light.light_energy=.8
  light.omni_range=4
  n.add_child(light)
 return n

static func companion(cat: bool) -> Node3D:
 var n=GardenCompanion.new()
 n.is_cat=cat
 return n

static func mountain(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, seed_value: int) -> void:
 var random = RandomNumberGenerator.new()
 random.seed = seed_value
 var st = SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var ring: Array = []
 for j in range(12):
  var a=j*TAU/12
  ring.append(Vector3(cos(a)*radius*random.randf_range(0.8,1.2),0,sin(a)*radius*random.randf_range(0.8,1.2)))
 var peak=Vector3(radius*0.15,height,-radius*0.12)
 for j in range(12):
  var a: Vector3=ring[j]
  var b: Vector3=ring[(j+1)%12]
  var ridge=(a+b)*0.32+Vector3(random.randf_range(-2,2),height*random.randf_range(0.28,0.58),random.randf_range(-2,2))
  for tri in [[a,b,ridge],[a,ridge,peak],[ridge,b,peak]]:
   for v in tri: st.add_vertex(v)
 st.generate_normals()
 var n=mesh(parent,st.commit(),pos,color)
 n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func visitor(kind: String) -> Node3D:
 var n=detailed_model("wildlife",kind.replace(" ","_"))
 # Keep the existing animation dispatchers' direct-child joint contract.
 for side in [-1,1]:
  var wing=n.find_child("WingL*" if side<0 else "WingR*",true,false) as Node3D
  if wing:
   if wing.get_parent()!=n:
    wing.owner=null
    wing.reparent(n,false)
   wing.set_meta("side",side)
 return n
