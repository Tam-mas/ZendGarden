class_name GardenChallengeArt
extends RefCounted

# Code-authored models: small, editable, shared meshes with no Blender runtime.
static var scenes: Dictionary={}

static func model(kind: String) -> Node3D:
 if scenes.has(kind):return scenes[kind].instantiate()
 var root=Node3D.new()
 root.name=kind.to_pascal_case()
 var wood=Color("aa8054")
 var metal=Color("52766b")
 if kind=="weed_tool":
  GardenArt.cylinder(root,Vector3(0,.13,0),.034,.3,wood)
  GardenArt.box(root,Vector3(0,-.04,0),Vector3(.14,.045,.04),metal)
  for x in [-.055,0,.055]:GardenArt.box(root,Vector3(x,-.12,-.015),Vector3(.018,.16,.035),metal)
 elif kind=="mulch_tool":
  GardenArt.cylinder(root,Vector3(0,.15,0),.03,.27,wood)
  GardenArt.box(root,Vector3(0,-.04,-.04),Vector3(.20,.055,.24),metal)
  for x in [-.10,.10]:GardenArt.box(root,Vector3(x,.005,-.04),Vector3(.018,.1,.24),metal)
  GardenArt.ball(root,Vector3(0,0,-.05),Vector3(.15,.06,.18),Color("785338"))
 elif kind=="reserve_tank":
  GardenArt.cylinder(root,Vector3(0,.84,0),.58,1.6,metal)
  for y in [.20,.57,.94,1.31]:GardenArt.cylinder(root,Vector3(0,y,0),.60,.035,Color("39584f"))
  GardenArt.cylinder(root,Vector3(0,1.68,0),.25,.08,Color("39584f"))
  GardenArt.branch(root,Vector3(.25,.18,-.53),Vector3(.25,.18,-.78),.035,Color("ba9864"))
  GardenArt.box(root,Vector3(-.20,.82,-.58),Vector3(.07,1.0,.025),Color("d7ceb2"))
 elif kind=="soaker_controller":
  GardenArt.box(root,Vector3(0,.18,0),Vector3(.34,.32,.25),metal)
  GardenArt.cylinder(root,Vector3(0,.4,0),.13,.025,Color("ba9864"))
  for x in [-.11,0,.11]:GardenArt.branch(root,Vector3(x,.14,0),Vector3(x,.05,.55),.025,metal)
 elif kind=="planter_drip":
  GardenArt.cylinder(root,Vector3(0,.35,0),.035,.7,wood)
  GardenArt.box(root,Vector3(0,.7,0),Vector3(.24,.17,.12),metal)
  for x in [-.3,.3]:
   GardenArt.branch(root,Vector3(0,.66,0),Vector3(x,.6,0),.015,metal)
   GardenArt.branch(root,Vector3(x,.6,0),Vector3(x,.26,0),.012,metal)
   GardenArt.ball(root,Vector3(x,.24,0),Vector3(.05,.06,.05),Color("ba9864"))
 elif kind.begins_with("weed_"):
  var stage=int(kind.get_slice("_",1))
  var grassy=kind.ends_with("grass")
  for i in range(8 if grassy else 6):
   var angle=i*TAU/(8 if grassy else 6)
   var length=.18+stage*.09
   var leaf=GardenArt.ball(root,Vector3(cos(angle)*length*.5,.04+stage*.025,sin(angle)*length*.5),Vector3(.035 if grassy else .11,.025,length),Color("65833c") if i%2 else Color("83934a"))
   leaf.rotation=Vector3(.35,angle,.12)
  if stage>=2:
   for i in range(2):
    var pos=Vector3(i*.1-.05,.16*stage,.02)
    GardenArt.branch(root,Vector3.ZERO,pos,.012,Color("65833c"))
    GardenArt.ball(root,pos,Vector3(.075,.045,.075),Color("b5a069") if stage==3 else Color("83934a"))
 for child in root.find_children("*","",true,false):
  child.owner=root
  if kind.begins_with("weed_") and child is MeshInstance3D:child.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var packed=PackedScene.new()
 packed.pack(root)
 scenes[kind]=packed
 root.free()
 return packed.instantiate()

static func surface(g,st: SurfaceTool,pos: Vector3,color: Color) -> void:
 for dx in range(2):
  for dz in range(2):
   var a=pos+Vector3(dx-1,0,dz-1)
   var points=[a,a+Vector3.RIGHT,a+Vector3(1,0,1),a+Vector3.BACK]
   for index in [0,2,1,0,3,2]:
    st.set_color(color)
    st.add_vertex(GardenTerrain.point(points[index])+Vector3(0,.04,0))

static func rebuild(g) -> void:
 if is_instance_valid(g.challenge_visual):
  g.challenge_visual.get_parent().remove_child(g.challenge_visual)
  g.challenge_visual.queue_free()
 for obj in g.objects:equipment_visual(g,obj)
 var root=Node3D.new();root.name="ChallengeCare"
 g.world_root.add_child(root);g.challenge_visual=root
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var cells=0
 var patches=GardenChallenge.groups(g)
 for key in g.challenge.patches:
  var patch=g.challenge.patches[key]
  var pos=GardenChallenge.center(key)
  if not GardenAreaProgression.allowed(g,pos):continue
  var stage=int(patch.weed)
  if stage>0:
   var weeds=model("weed_%d_%s"%[stage,"grass" if posmod(key.hash(),2)==0 else "broad"])
   root.add_child(weeds)
   weeds.position=GardenTerrain.point(pos)
  var tint=Color.TRANSPARENT
  if int(patch.mulch_until)>g.day:
   tint=Color(.30,.19,.10,.45 if int(patch.mulch_until)-g.day>2 else .23)
  if g.care_overlay=="water" and patches.has(key):
   var thirsty=patches[key].any(func(p):return p.water<2)
   tint=Color(.65,.36,.10,.40) if thirsty else Color(.10,.42,.55,.35)
  elif g.care_overlay=="weeds":tint=Color(.7,.4,.1,.35) if stage>0 else Color.TRANSPARENT
  elif g.care_overlay=="irrigation" and patches.has(key):
   for controller in GardenChallenge.controllers(g):
    if GardenChallenge.covered(g,controller,key,patches[key]):
     tint=Color(.12,.5,.45,.35) if not GardenChallenge.supply(g,controller).is_empty() else Color(.7,.4,.1,.35)
     break
  if tint.a>0:surface(g,st,pos,tint);cells+=1
 if cells>0:
  st.generate_normals()
  var mesh=MeshInstance3D.new();mesh.mesh=st.commit()
  var material=StandardMaterial3D.new()
  material.vertex_color_use_as_albedo=true
  material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  material.cull_mode=BaseMaterial3D.CULL_DISABLED
  mesh.material_override=material
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  root.add_child(mesh)

static func equipment_visual(g,obj: Dictionary) -> void:
 if obj.kind in GardenChallenge.SUPPLIES:
  var gauge=obj.node.get_node_or_null("ChallengeWaterGauge")
  if not gauge:
   gauge=Node3D.new();gauge.name="ChallengeWaterGauge";obj.node.add_child(gauge)
   gauge.position=Vector3(-.18,.7,-.59 if obj.kind=="reserve_tank" else -.43)
   GardenArt.box(gauge,Vector3.ZERO,Vector3(.085,.56,.035),Color("d7ceb2"))
   var fill=GardenArt.box(gauge,Vector3(0,0,-.025),Vector3(.05,.5,.02),Color("559fa5"))
   fill.name="Fill"
  var level=clampf(float(obj.work.get("water",0))/GardenChallenge.capacity(obj),0,1)
  gauge.get_node("Fill").scale.y=maxf(.01,level)
  gauge.get_node("Fill").position.y=-(1-level)*.25
 elif obj.kind=="soaker_controller":
  var stamp=[obj.pos,obj.node.rotation.y,g.terrain_revision,int(obj.work.get("plot",-1))]
  if obj.node.get_meta("hose_stamp",[])==stamp:return
  obj.node.set_meta("hose_stamp",stamp)
  var previous=obj.node.get_node_or_null("BedHoses")
  if previous:obj.node.remove_child(previous);previous.queue_free()
  var plot=int(obj.work.get("plot",-1))
  if plot<0 or plot>=g.plots.size():return
  var hoses=Node3D.new();hoses.name="BedHoses";obj.node.add_child(hoses)
  var center=g.plots[plot].center
  for x in [-3.5,0,3.5]:
   for j in range(16):
    var a=GardenTerrain.point(center+Vector3(x,0,-3.8+j*.48))+Vector3(0,.05,0)
    var b=GardenTerrain.point(center+Vector3(x,0,-3.32+j*.48))+Vector3(0,.05,0)
    GardenArt.branch(hoses,obj.node.to_local(a),obj.node.to_local(b),.016,Color("546f5c"))
    hoses.get_child(hoses.get_child_count()-1).cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
