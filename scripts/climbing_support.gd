class_name GardenClimbingSupport
extends RefCounted

const SUPPORTS=["arbor","pergola","trellis_screen","gazebo"]
static var scenes: Dictionary={}

static func refresh(g) -> void:
 g.climbing_dirty=false
 for p in g.planted:
  if not g.catalogue[p.id].climber:continue
  var old=p.node.get_node_or_null("Vines")
  if old:p.node.remove_child(old);old.queue_free()
  var fraction=clampf(p.age/float(g.catalogue[p.id].days),0,1)
  if fraction<.52:continue
  var support={}
  var distance=3.0
  for obj in g.objects:
   var gap=obj.pos.distance_to(p.pos)
   if obj.kind in SUPPORTS and gap<distance:
    support=obj;distance=gap
  if support.is_empty():continue
  grow(p,support,fraction)

static func palette(node: Node, result: Dictionary) -> void:
 if node is MeshInstance3D:
  for i in range(node.mesh.get_surface_count()):
   var original=node.mesh.surface_get_material(i)
   var material=node.get_active_material(i)
   if original and material:
    var key="leaf" if str(original.resource_name).begins_with("Leaf") else "petal" if "petal" in str(original.resource_name).to_lower() else "stamen" if "stamen" in str(original.resource_name).to_lower() else "stem"
    if not result.has(key):result[key]=material
 for child in node.get_children():palette(child,result)

static func dress(node: Node, colors: Dictionary, share_petals: bool) -> void:
 if node is MeshInstance3D:
  for i in range(node.mesh.get_surface_count()):
   var original=node.mesh.surface_get_material(i)
   var name=str(original.resource_name).to_lower()
   var key="leaf" if "foliage" in name else "stamen" if "stamen" in name else "petal"
   if colors.has(key) and (key!="petal" or share_petals):node.set_surface_override_material(i,colors[key])
 for child in node.get_children():dress(child,colors,share_petals)

static func grow(p: Dictionary, support: Dictionary, fraction: float) -> void:
 var path="res://assets/plants/climbing/climber_%02d.glb"%int(p.id)
 if not ResourceLoader.exists(path):return
 if not scenes.has(path):scenes[path]=load(path)
 var vine=Node3D.new()
 vine.name="Vines"
 p.node.add_child(vine)
 # World coordinates prevent the plant's random rotation/height from tilting
 # support stems into the air. The shoot follows the nearest actual post.
 vine.top_level=true
 vine.global_transform=Transform3D(Basis.IDENTITY,p.pos)
 var local=support.node.to_local(p.pos)
 # Match the preserved authored post positions, including the hexagonal gazebo
 # and all six trellis uprights (art_source/overhaul/structures.py).
 var posts=[]
 if support.get("area_fixture","")=="moon:pergola":
  for x in [-1.2,1.2]:
   for z in [-2.75,2.75]:posts.append(Vector3(x,0,z))
 elif support.kind=="gazebo":
  for j in range(6):posts.append(Vector3(cos(j*TAU/6)*1.65,0,sin(j*TAU/6)*1.65))
 elif support.kind=="trellis_screen":
  for x in [-1.15,-.41,-.37,.37,.41,1.15]:posts.append(Vector3(x,0,0))
 else:
  var depth=1.2 if support.kind=="pergola" else .35
  for x in [-1.15,1.15]:
   for z in [-depth,depth]:posts.append(Vector3(x,0,z))
 var post: Vector3=posts[0]
 for candidate in posts:
  if Vector2(candidate.x-local.x,candidate.z-local.z).length_squared()<Vector2(post.x-local.x,post.z-local.z).length_squared():post=candidate
 var foot=support.node.to_global(post)-p.pos
 var height=1.85 if support.kind=="trellis_screen" else 2.45 if support.kind=="gazebo" else 2.55
 if support.get("area_fixture","")=="moon:pergola":height=2.73
 height*=smoothstep(.35,.90,fraction)
 var colors={}
 palette(p.node.get_node("MatureFoliage"),colors)
 palette(p.node.get_node("Bloom"),colors)
 var points=[Vector3(0,.12,0)]
 var rng=RandomNumberGenerator.new();rng.seed=int(p.shape_seed)
 var phase=rng.randf()*TAU
 for i in range(1,23):
  var t=i/22.0
  var approach=smoothstep(0,.32,t)
  var around=Vector3(cos(t*TAU*2+phase),0,sin(t*TAU*2+phase))*(.06 if support.kind=="trellis_screen" else .11)
  points.append(foot*approach+Vector3(0,height*t,0)+around)
 stem(vine,points)
 var organs=scenes[path].instantiate()
 vine.add_child(organs)
 GardenArt.add_leaf_wind(organs)
 dress(organs,colors,p.id in [9,10])
 var leaves=organs.find_child("SupportLeaves*",true,false)
 var blossom=organs.find_child("SupportFlower*",true,false)
 var leaf_transforms=[]
 var flower_transforms=[]
 for i in range(1,points.size()):
  if i%3!=0:continue
  var transform=Transform3D(Basis(Vector3.UP,phase+i*2.39996).scaled(Vector3.ONE*rng.randf_range(.85,1.12)),points[i])
  leaf_transforms.append(transform)
  if fraction>=.78 and i>=9 and i%2==0:flower_transforms.append(transform)
 organ_batch(vine,leaves,leaf_transforms)
 organ_batch(vine,blossom,flower_transforms)
 organs.free()

static func organ_batch(vine: Node3D, source: MeshInstance3D, transforms: Array) -> void:
 if transforms.is_empty():return
 var mesh=source.mesh.duplicate()
 for i in range(mesh.get_surface_count()):mesh.surface_set_material(i,source.get_active_material(i))
 var multi=MultiMesh.new()
 multi.transform_format=MultiMesh.TRANSFORM_3D
 multi.mesh=mesh
 multi.instance_count=transforms.size()
 var renderer=MultiMeshInstance3D.new()
 renderer.multimesh=multi
 renderer.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 vine.add_child(renderer)
 var organ_transform=vine.global_transform.affine_inverse()*source.global_transform
 for i in range(transforms.size()):multi.set_instance_transform(i,transforms[i]*organ_transform)

static func stem(vine: Node3D, points: Array) -> void:
 var surface=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rings=[]
 for i in range(points.size()):
  var direction: Vector3=(points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
  var side=direction.cross(Vector3.RIGHT).normalized()
  var up=direction.cross(side).normalized()
  var ring=[]
  for j in range(6):ring.append(points[i]+(side*cos(j*TAU/6)+up*sin(j*TAU/6))*.005)
  rings.append(ring)
 for i in range(1,rings.size()):
  for j in range(6):
   var next=(j+1)%6
   for point in [rings[i-1][j],rings[i][j],rings[i][next],rings[i-1][j],rings[i][next],rings[i-1][next]]:surface.add_vertex(point)
 surface.generate_normals()
 var mesh=MeshInstance3D.new()
 mesh.mesh=surface.commit()
 mesh.material_override=GardenArt.mat(Color("678557"))
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 vine.add_child(mesh)
