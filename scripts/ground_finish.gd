class_name GardenGroundFinish
extends RefCounted

static func material(soil: bool) -> ShaderMaterial:
 var mat=ShaderMaterial.new()
 mat.shader=load("res://shaders/ground_detail.gdshader")
 var texture_name="Garden_loam" if soil else "Meadow_earth"
 mat.set_shader_parameter("earth",load("res://assets/textures/"+texture_name+".png"))
 mat.set_shader_parameter("relief",load("res://assets/textures/"+texture_name+"_normal.png"))
 return mat

static func path(g, center: Vector3, width: float = 1.0) -> MeshInstance3D:
 var st=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(10):
  for z in range(10):
   var a=center+Vector3(-.5+x*.1,0,-.5+z*.1)*width
   for v in [a,a+Vector3(.1*width,0,0),a+Vector3(.1*width,0,.1*width),a,a+Vector3(.1*width,0,.1*width),a+Vector3(0,0,.1*width)]:
    st.set_uv(Vector2(v.x,v.z))
    st.add_vertex(GardenTerrain.point(v)+Vector3(0,.018,0))
 st.generate_normals()
 st.generate_tangents()
 var patch=MeshInstance3D.new()
 patch.name="RakedGround"
 patch.mesh=st.commit()
 patch.material_override=material(true)
 g.world_root.add_child(patch)
 # Clear procedural blades from the newly raked earth, including on save reload.
 var lawn=g.world_root.get_node_or_null("MeadowGrass")
 if lawn:
  var mm=lawn.multimesh
  for i in range(mm.instance_count):
   var t=mm.get_instance_transform(i)
   if absf(t.origin.x-center.x)<width*.5+.01 and absf(t.origin.z-center.z)<width*.5+.01:
    t.basis=Basis.IDENTITY.scaled(Vector3.ZERO)
    mm.set_instance_transform(i,t)
 return patch
