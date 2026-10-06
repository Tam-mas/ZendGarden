class_name GardenAreaTransitions
extends RefCounted

static func approach(index: int,t: float) -> Vector2:
 if index==0:return Vector2(12-4*t,7.9-2.8*smoothstep(0.,1.,t))
 if index==5:
  var straight=10.85;var arc=PI*1.15/2;var distance=t*(straight+arc+.5)
  if distance<straight:return Vector2(-12+distance,8.25)
  if distance<straight+arc:
   var angle=(distance-straight)/1.15
   return Vector2(-1.15+1.15*sin(angle),7.1+1.15*cos(angle))
  return Vector2(0,7.1-(distance-straight-arc))
 if index==6:return Vector2(12*(1-t),8.25-2.10*smoothstep(0.,1.,t))
 if index==4:return Vector2(12-6*t,8.15-.5*smoothstep(0.,1.,t))
 return Vector2((1 if index%2==0 else -1)*(12-6*t),7.9-1.9*smoothstep(0.,1.,t))

static func on_path(index: int,pos: Vector3) -> bool:
 var p=pos-GardenAreaCatalogue.center(index)
 if absf(p.x-(12 if index%2==0 else -12))<1.03:return true
 for j in range(31):
  if Vector2(p.x,p.z).distance_to(approach(index,j/30.))<1.03:return true
 return false

static func build(g) -> void:
 var root=Node3D.new();root.name="GardenConnectingTrail";g.world_root.add_child(root)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 # The shared boundary is flat in the original height field. Retain that field
 # for saves, planting rays and sculpting, and grade each surface to it.
 for k in range(236):
  var z=-106+k*.5
  var width=.94+.035*sin(z*.38);var next_width=.94+.035*sin((z+.5)*.38)
  # A centre vertex and half-metre cross sections follow both banks and carry
  # sparse metre-grid terrain edits through the middle of the walking surface.
  for lane in range(4):
   var a=lane/2.-1.;var b=(lane+1)/2.-1.
   var quad=[Vector3(68+width*a,0,z),Vector3(68+next_width*a,0,z+.5),Vector3(68+next_width*b,0,z+.5),Vector3(68+width*b,0,z)]
   for points in [[quad[0],quad[2],quad[1]],[quad[0],quad[3],quad[2]]]:
    for p in points:st.set_uv(Vector2(p.x,p.z));st.add_vertex(GardenTerrain.point(p)+Vector3(0,.055,0))
 st.generate_normals();st.generate_tangents()
 var mesh=MeshInstance3D.new();mesh.name="Shared garden trail";mesh.mesh=st.commit()
 mesh.set_meta("editable_ground",true)
 var mat=GardenBedSurfaces.material("gravel");mat.set_shader_parameter("tint",Color("b6aea0"))
 mesh.material_override=mat;root.add_child(mesh)
 for j in range(5):
  var sign=g.Art.furnishing("sign");root.add_child(sign)
  sign.position=GardenTerrain.point(Vector3(69.7,0,6-j*24))+Vector3(0,.02,0)
  sign.rotation.y=-PI/2;sign.set_meta("terrain_anchor",true)
  g.Art.set_sign_text(sign,GardenAreaCatalogue.entry(j*2).name+"\n"+GardenAreaCatalogue.entry(j*2+1).name)
  GardenAreaMaterials.prepare(sign)
