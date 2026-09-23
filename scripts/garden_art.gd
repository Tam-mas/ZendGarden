class_name GardenArt
extends RefCounted

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
 var n=Node3D.new()
 box(n,Vector3(0,.62,0),Vector3(1.8,.52,.10),Color("665039"))
 for x in [-.65,.65]:
  box(n,Vector3(x,.29,0),Vector3(.065,.58,.065),Color("88704d"))
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

static func furnishing(kind: String) -> Node3D:
 if kind=="sign": return sign_board()
 var n = Node3D.new()
 var wood = Color("b19a7a")
 var dark = Color("817460")
 match kind:
  "hive":
   for x in [-.24,.24]:
    for z in [-.2,.2]: box(n,Vector3(x,.18,z),Vector3(.07,.36,.07),dark)
   for y in [.45,.73]:
    box(n,Vector3(0,y,0),Vector3(.66,.26,.54),Color("dfbb72"))
    for x in [-.34,.34]: box(n,Vector3(x,y,0),Vector3(.06,.05,.18),wood)
   box(n,Vector3(0,.90,0),Vector3(.78,.08,.66),Color("7c8e84"))
   box(n,Vector3(0,.33,-.285),Vector3(.26,.045,.025),Color("30271e"))
   box(n,Vector3(0,.30,-.36),Vector3(.50,.045,.24),wood)
  "bench":
   for x in [-0.65,0.65]:
    box(n,Vector3(x,0.3,0),Vector3(0.12,0.6,0.5),dark)
    box(n,Vector3(x,0.85,0.23),Vector3(0.1,0.9,0.1),dark)
   for j in range(3): box(n,Vector3(0,0.61,-0.22+j*0.19),Vector3(1.7,0.08,0.15),wood)
   box(n,Vector3(0,1.0,0.27),Vector3(1.7,0.34,0.08),wood)
  "arbor", "pergola":
   var depth = 2.4 if kind == "pergola" else 0.7
   for x in [-1.15,1.15]:
    for z in [-depth/2,depth/2]: box(n,Vector3(x,1.3,z),Vector3(0.13,2.6,0.13),wood)
    for j in range(5): box(n,Vector3(x,0.7+j*0.34,0),Vector3(0.06,0.05,depth),wood)
   for j in range(5): box(n,Vector3(-1.4+j*0.7,2.64,0),Vector3(0.12,0.13,depth+0.5),wood)
   for z in [-depth/2,depth/2]: box(n,Vector3(0,2.5,z),Vector3(2.9,0.18,0.12),dark)
  "greenhouse":
   for x in [-1.6,1.6]:
    for z in [-1.4,1.4]: box(n,Vector3(x,1.15,z),Vector3(0.08,2.3,0.08),wood)
    box(n,Vector3(x,1.1,0),Vector3(0.025,2.2,2.8),Color(0.72,0.9,0.84,0.23))
    var roof = box(n,Vector3(x/2,2.65,0),Vector3(1.9,0.04,2.9),Color(0.77,0.92,0.87,0.3))
    roof.rotation.z = -sign(x)*0.45
    for z in [-1.4,0.0,1.4]: branch(n,Vector3(x,2.25,z),Vector3(0,3.0,z),0.045,wood)
   box(n,Vector3(0,3,0),Vector3(0.08,0.08,2.9),wood)
   box(n,Vector3(0,1.1,1.4),Vector3(3.2,2.2,0.025),Color(0.72,0.9,0.84,0.18))
  "pond":
   cylinder(n,Vector3(0,0.025,0),1.65,0.05,Color("77aaa5"))
   for j in range(14):
    var a = j*TAU/14
    ball(n,Vector3(cos(a)*1.7,0.12,sin(a)*1.7),Vector3(0.55,0.3,0.42),Color("b0b3a0"))
   for j in range(4): cylinder(n,Vector3(cos(j*2.4),0.065,sin(j*2.4)),0.27,0.025,Color("8caf7d"))
  "lantern":
   cylinder(n,Vector3(0,0.35,0),0.18,0.7,Color("969a87"))
   box(n,Vector3(0,0.82,0),Vector3(0.42,0.4,0.42),Color("f4dba0"))
   cylinder(n,Vector3(0,1.08,0),0.38,0.18,Color("929580"),0.18)
   var light = OmniLight3D.new()
   light.position.y = 1
   light.light_color = Color("ffdc9e")
   light.light_energy = 0.8
   light.omni_range = 4
   n.add_child(light)
  "bath":
   cylinder(n,Vector3(0,0.45,0),0.16,0.9,Color("c0b9a2"))
   cylinder(n,Vector3(0,0.95,0),0.6,0.13,Color("c0b9a2"))
   cylinder(n,Vector3(0,1.02,0),0.5,0.015,Color("8ebbb9"))
  _:
   cylinder(n,Vector3(0,0.3,0),0.28,0.6,Color("c58f75"),0.42)
   cylinder(n,Vector3(0,0.61,0),0.35,0.025,Color("897362"))
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
 var n=Node3D.new()
 var dark=Color("3e3429")
 if kind=="frog":
  ball(n,Vector3.ZERO,Vector3(.17,.12,.22),Color("6f8845"))
  for side in [-1,1]:
   ball(n,Vector3(side*.065,.055,-.065),Vector3.ONE*.046,Color("a1af68"))
   ball(n,Vector3(side*.065,.065,-.084),Vector3.ONE*.019,dark)
   ball(n,Vector3(side*.095,-.025,.05),Vector3(.10,.05,.16),Color("6f8845"))
  return n
 if kind in ["songbird","native bird"]:
  var feather=Color("7d8a91") if kind=="native bird" else Color("927653")
  ball(n,Vector3.ZERO,Vector3(.12,.13,.24),feather)
  ball(n,Vector3(0,.055,-.105),Vector3.ONE*.095,feather.darkened(.1))
  branch(n,Vector3(0,.05,-.14),Vector3(0,.04,-.20),.02,Color("b39e6c"))
  for side in [-1,1]:
   var wing=Node3D.new()
   wing.name="Wing"+str(side)
   wing.set_meta("side",side)
   n.add_child(wing)
   for j in range(4):
    var feather_mesh=ball(wing,Vector3(side*(.10+j*.035),0,.01+j*.018),Vector3(.15,.018,.055),feather)
    feather_mesh.rotation.y=side*.25
   ball(n,Vector3(side*.034,.071,-.14),Vector3.ONE*.012,dark)
  ball(n,Vector3(0,0,.16),Vector3(.07,.022,.17),feather.darkened(.1))
  return n
 var bee=kind=="bee"
 var dragon=kind=="dragonfly"
 var body_color=Color("bd9a44") if bee else Color("558b85") if dragon else dark
 ball(n,Vector3.ZERO,Vector3(.025,.027,.075 if bee else .1),body_color)
 if bee:
  for j in range(3): ball(n,Vector3(0,0,-.022+j*.02),Vector3(.027,.029,.009),dark)
 for side in [-1,1]:
  var wing=Node3D.new()
  wing.name="Wing"+str(side)
  wing.set_meta("side",side)
  n.add_child(wing)
  if bee or dragon:
   for j in range(2):
    var w=ball(wing,Vector3(side*.045,.01,-.018+j*.03),Vector3(.10,.004,.023),Color(.85,.91,.91,.65))
    w.rotation.y=side*(.25 if j==0 else -.3)
  else:
   for j in range(2):
    ball(wing,Vector3(side*.048,.005,-.025+j*.049),Vector3(.082,.009,.075 if j==0 else .054),Color("cd9a67"))
    ball(wing,Vector3(side*.056,.012,-.026+j*.049),Vector3(.042,.006,.042 if j==0 else .027),Color("eed4a1"))
 if kind=="firefly":
  ball(n,Vector3(0,0,.044),Vector3.ONE*.025,Color("eadfa2"))
 return n
