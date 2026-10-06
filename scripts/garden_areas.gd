class_name GardenAreas
extends RefCounted

const FRUIT_FAMILIES=[[35,83],[84,85,86,87],[34,88,89,90]]
const KITCHEN_RECIPES={
 "salad":{"name":"Summer salad basket","items":[48,47,56],"reward":24,"supply":"starter_mix"},
 "soup":{"name":"Soup garden basket","items":[46,104,54],"reward":28,"supply":"mulch"},
 "herbs":{"name":"Kitchen herb basket","items":[54,22,12],"reward":22,"supply":"compost"}
}
const JOURNAL={
 "bee":{"name":"Honey bee","flowers":3,"types":1,"gift":1},
 "butterfly":{"name":"Meadow butterfly","flowers":4,"types":3,"gift":65},
 "hoverfly":{"name":"Hoverfly","flowers":5,"types":4,"gift":19},
 "blue banded bee":{"name":"Blue-banded bee","flowers":4,"types":3,"native":true,"gift":36},
 "lady beetle":{"name":"Lady beetle","flowers":6,"types":4,"gift":7},
 "emperor gum moth":{"name":"Emperor gum moth","flowers":5,"types":4,"night":true,"gift":119}
}
const SOLID_PIVOTS=["Boardwalk","Sluice wheel","Fallen log","Stepping stones","Terrace masonry","Meadow fence","Orchard fence","Espalier wires","Harvest table","Kitchen walls","Entry arch","Kitchen bed edging","Kitchen espalier","Glasshouse frame","Stream bridge railing","Stream stepping stones","StreamGate","Lookout railing","Reflection pool rim","Moon pergola","MoonLantern"]
static var scenes: Dictionary={}

static func initial_state() -> Dictionary:
 return {"version":1,"gardens":{}}

static func state(g,index: int) -> Dictionary:
 var kind: String=GardenAreaCatalogue.entry(index).kind
 if not g.areas_state.gardens.has(kind):
  g.areas_state.gardens[kind]={"visited":false,"initialized":false,"beds":{},"sluice":1,"clearings":[false,false,false],"discoveries":[],"shelters":[false,false,false],"journal":[],"basket_day":0,"rotation":{},"rotation_day":0,"restored":[false,false,false],"vents":[true,true,true],"shade":[false,false,false],"mist":[false,false,false],"gates":[true,false],"windbreaks":[true,true,true],"melt":0,"lanterns":1,"photo":false}
 return g.areas_state.gardens[kind]

static func restore(g,saved: Dictionary) -> void:
 g.areas_state=initial_state()
 if saved.get("areas") is Dictionary and GardenAreaCatalogue.valid_save(saved):g.areas_state=saved.areas.duplicate(true)
 # Fill missing defaults when opening a save made before another control was added.
 for index in range(10):
  var kind: String=GardenAreaCatalogue.entry(index).kind
  var old: Dictionary=g.areas_state.gardens.get(kind,{}).duplicate(true)
  g.areas_state.gardens.erase(kind)
  state(g,index).merge(old,true)

static func instantiate(path: String) -> Node3D:
 if not ResourceLoader.exists(path):return null
 if not scenes.has(path):scenes[path]=load(path)
 return scenes[path].instantiate()

static func build(g) -> void:
 for index in range(10):
  var info=GardenAreaCatalogue.entry(index)
  var root=Node3D.new();root.name="Habitat_"+info.kind
  g.world_root.add_child(root);root.position=GardenAreaCatalogue.center(index)
  var model=instantiate("res://assets/areas/"+info.kind+".glb")
  if model:root.add_child(model);prepare_meshes(model,false,false,index+4)
  if model:GardenAreaMaterials.prepare(model)
  GardenAreaFlora.build(g,root)
  var collection=Node3D.new();collection.name="LivingCollection";root.add_child(collection)
  g.area_roots.append(root)
  water_features(g,root,index)
  landmark_trees(g,root,index)
  walk_surfaces(root,index)
  if index==6:
   for bay in range(3):
    var mist=CPUParticles3D.new();mist.name="BayMist%d"%bay;root.add_child(mist)
    mist.position=Vector3(0,4.45,-3.6+bay*3.6);mist.amount=80;mist.lifetime=3
    mist.emission_shape=CPUParticles3D.EMISSION_SHAPE_BOX;mist.emission_box_extents=Vector3(3.3,.01,1.3)
    mist.direction=Vector3.DOWN;mist.gravity=Vector3(0,-.05,0);mist.initial_velocity_min=.07;mist.initial_velocity_max=.15
    var droplet=SphereMesh.new();droplet.radius=.013;droplet.height=.026;droplet.radial_segments=4;droplet.rings=2
    mist.mesh=droplet;mist.emitting=false;mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    var damp=g.Art.mat(Color(.67,.82,.77,.16)).duplicate();damp.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
    mist.material_override=damp
  if index==8:
   var chime=AudioStreamPlayer3D.new();chime.name="ChimeVoice";root.add_child(chime)
   chime.position=local_point(index,Vector3(-6,0,-5))+Vector3(0,2,0)
   chime.stream=load("res://assets/audio/alpine_chime.wav");chime.max_distance=22;chime.unit_size=3
   root.set_meta("chime_timer",12.0)
  var sign=g.Art.furnishing("sign")
  root.add_child(sign);sign.position=local_point(index,Vector3(8.0 if index%2==0 else -8.0,0,8.7))
  sign.rotation.y=-PI/4 if index%2==0 else PI/4
  sign.set_meta("terrain_anchor",true);GardenAreaMaterials.prepare(sign)
  g.Art.set_sign_text(sign,info.name.to_upper()+"\nE · GARDEN ACTIVITY")
  if index==9:
   for j in range(3):
    var node=find(root,"MoonLantern%d"%j)
    if node:
     var light=OmniLight3D.new();light.name="MoonLight";node.add_child(light)
     light.position=Vector3(0,1.35,0);light.light_color=Color("ffdca0")
     light.omni_range=7;light.light_energy=.9;light.shadow_enabled=false
     var bulb=g.Art.ball(node,Vector3(0,1.35,0),Vector3(.11,.17,.11),Color("ffdf99"))
     bulb.name="LampWick"
     var glow=StandardMaterial3D.new();glow.albedo_color=Color("ffe6b4");glow.emission_enabled=true
     glow.emission=Color("ffb650");glow.emission_energy_multiplier=2;bulb.material_override=glow
  root.visible=true
 build_trail(g)
 GardenAreaTransitions.build(g)

static func prepare_meshes(node: Node, ground: bool=false, solid: bool=false,bed_plot: int=-1) -> void:
 var name=String(node.name)
 # Godot keeps glTF custom properties in extras. Blender also numbers repeated
 # pivot names across the library, so the first area's "Ground" is not enough.
 var extras: Dictionary=node.get_meta("extras",{})
 if extras.get("terrain_anchor",false):node.set_meta("terrain_anchor",true)
 if extras.get("ground_detail",false):node.set_meta("ground_detail",true)
 ground=ground or name=="Ground" or node.get_meta("area_ground",false) or extras.get("ground",false) or extras.get("area_ground",false)
 solid=solid or node.get_meta("area_collision",false) or extras.get("collision",false) or extras.get("area_collision",false) or SOLID_PIVOTS.any(func(part):return name.begins_with(part))
 if node is MeshInstance3D:
  if not ground and String(node.name).contains("mossrock"):solid=true
  if not ground and str(node.name).contains("weathered bark"):
   for surface in range(node.mesh.get_surface_count()):
    var original=node.mesh.surface_get_material(surface)
    if original is StandardMaterial3D:
     var bark=original.duplicate();bark.albedo_color=Color(.82,.78,.72);node.set_surface_override_material(surface,bark)
  node.visibility_range_end=0 if ground else 80
  if ground:
   node.set_meta("editable_ground",true)
   if bed_plot in [8,9] and (str(node.name).contains("potting loam") or bed_plot==8 and str(node.name).contains("Area grass")):
    node.set_meta("area_bed_plot",bed_plot);node.material_override=GardenBedSurfaces.area_material(bed_plot,"soil")
   if (bed_plot in [4,5,6,7,11,12,13] and not str(node.name).contains("limestone")) or bed_plot in [9,10] and str(node.name).contains("Area grass"):
    var mat=ShaderMaterial.new();mat.shader=load("res://shaders/habitat_ground.gdshader")
    mat.set_shader_parameter("habitat_kind",bed_plot-4)
    var c=GardenAreaCatalogue.center(bed_plot-4);mat.set_shader_parameter("habitat_center",Vector2(c.x,c.z))
    mat.set_shader_parameter("meadow",load("res://assets/textures/Meadow_earth.webp"))
    mat.set_shader_parameter("meadow_normal",load("res://assets/textures/Meadow_earth_normal.webp"))
    if bed_plot==6:mat.set_shader_parameter("dry_floor",load("res://assets/textures/beds/sand.webp"))
    mat.set_shader_parameter("earth",load("res://assets/textures/beds/gravel.webp"))
    mat.set_shader_parameter("relief",load("res://assets/textures/beds/gravel_normal.webp"))
    node.material_override=mat
  elif solid:
   node.create_trimesh_collision()
   for body in node.get_children():
    if body is StaticBody3D:body.set_meta("area_obstacle",true)
 for child in node.get_children():
  if child is Node3D and not child is StaticBody3D:prepare_meshes(child,ground,solid,bed_plot)

static func find(root: Node, prefix: String) -> Node3D:
 if String(root.name).begins_with(prefix) and root is Node3D and not root is MeshInstance3D:return root
 for child in root.get_children():
  var matched=find(child,prefix)
  if matched:return matched
 return null

static func local_point(index: int, local: Vector3) -> Vector3:
 return GardenTerrain.point(GardenAreaCatalogue.center(index)+local)-GardenAreaCatalogue.center(index)

static func build_trail(g) -> void:
 var root=Node3D.new();root.name="HabitatTrail";g.world_root.add_child(root)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for j in range(38):
  var x=25+j*.5
  for points in [[Vector3(x,0,4.5),Vector3(x,0,7.5),Vector3(x+.5,0,7.5)],[Vector3(x,0,4.5),Vector3(x+.5,0,7.5),Vector3(x+.5,0,4.5)]]:
   for p in [points[0],points[2],points[1]]:st.set_uv(Vector2(p.x,p.z)*.4);st.add_vertex(GardenTerrain.point(p)+Vector3(0,.12,0))
 st.generate_normals();st.generate_tangents()
 var mesh=MeshInstance3D.new();mesh.name="Eastern trail";mesh.mesh=st.commit()
 mesh.material_override=GardenAreaTransitions.bluestone();root.add_child(mesh);mesh.create_trimesh_collision()
 var sign=g.Art.furnishing("sign");root.add_child(sign)
 sign.position=GardenTerrain.point(Vector3(27,0,7.6))
 g.Art.set_sign_text(sign,"TEN GARDEN TRAILS\nFollow the eastern path")

static func walk_surfaces(root: Node3D,index: int) -> void:
 if index not in [2,7]:return
 # Continuous collision under narrow stair treads and separate bridge planks.
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var points=[]
 for k in range(28):
  if index==2:
   var z=6.4-k*.475
   points=[Vector3(5.73,GardenAreaCatalogue.height_at(root.position+Vector3(5.73,0,z))+.18,z),Vector3(7.3,GardenAreaCatalogue.height_at(root.position+Vector3(7.3,0,z))+.18,z),Vector3(7.3,GardenAreaCatalogue.height_at(root.position+Vector3(7.3,0,z-.475))+.18,z-.475),Vector3(5.73,GardenAreaCatalogue.height_at(root.position+Vector3(5.73,0,z-.475))+.18,z-.475)]
  else:
   var x=-3.4+k*(6.8/28.0);var next=x+6.8/28.0
   var y=1.40+.2*(1-pow(x/3.6,2));var ny=1.40+.2*(1-pow(next/3.6,2))
   points=[Vector3(x,y,2.4),Vector3(x,y,3.6),Vector3(next,ny,3.6),Vector3(next,ny,2.4)]
  for j in [0,2,1,0,3,2]:st.add_vertex(points[j])
 st.generate_normals()
 var floor=MeshInstance3D.new();floor.name="ContinuousWalkSurface";floor.mesh=st.commit();root.add_child(floor)
 floor.create_trimesh_collision();floor.hide()

static func water_surface(g,root: Node3D,name: String,points: Array,height: float) -> MeshInstance3D:
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for k in range(1,points.size()-1):
  for p in [points[0],points[k],points[k+1]]:
   st.set_uv(Vector2(p.x,p.z)*.2);st.add_vertex(Vector3(p.x,height,p.z))
 st.generate_normals()
 var n=MeshInstance3D.new();n.name=name;n.mesh=st.commit()
 var material=ShaderMaterial.new();material.shader=load("res://shaders/habitat_water.gdshader")
 material.set_shader_parameter("deep_color",Color("29454b"));material.set_shader_parameter("edge_color",Color("63847b"))
 n.material_override=material;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 root.add_child(n);return n

static func circle_points(x: float,z: float,rx: float,rz: float) -> Array:
 var result=[]
 for k in range(64):result.append(Vector3(x+cos(k*TAU/64)*rx,0,z+sin(k*TAU/64)*rz))
 return result

static func ribbon(g,root: Node3D,name: String,points: Array,width: float,raised: float=0) -> Node3D:
 var node=Node3D.new();node.name=name;root.add_child(node)
 var index=GardenAreaCatalogue.index_at(root.position)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rows=[];var distance=0.0
 for k in range(points.size()):
  var point: Vector3=points[k]
  var tangent: Vector3=points[mini(k+1,points.size()-1)]-points[maxi(0,k-1)]
  var side=tangent.cross(Vector3.UP).normalized()*width*.5
  var level=.88+.008*point.z if index==1 and name=="MainStream" else .78 if name=="MainStream" else local_point(index,point).y+raised
  if k>0:distance+=point.distance_to(points[k-1])
  rows.append([Vector3(point.x-side.x,level,point.z-side.z),Vector3(point.x+side.x,level,point.z+side.z),distance])
 for k in range(rows.size()-1):
  var a=rows[k];var b=rows[k+1]
  for v in [[a[0],Vector2(0,a[2])],[b[0],Vector2(0,b[2])],[a[1],Vector2(1,a[2])],[a[1],Vector2(1,a[2])],[b[0],Vector2(0,b[2])],[b[1],Vector2(1,b[2])]]:
   st.set_uv(v[1]);st.add_vertex(v[0])
 st.generate_normals();st.generate_tangents()
 var mesh=MeshInstance3D.new();mesh.name="ContinuousWater";mesh.mesh=st.commit()
 var material=ShaderMaterial.new();material.shader=load("res://shaders/habitat_water.gdshader")
 material.set_shader_parameter("flowing",true);mesh.material_override=material
 mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.add_child(mesh)
 return node

static func water_features(g,root: Node3D,index: int) -> void:
 if index==0:water_surface(g,root,"InletWater",circle_points(-1.4,0,4.25,3.8),.72)
 elif index==1 or index==7:
  var points=[]
  for k in range(121):
   var z=-9+k*.15
   points.append(Vector3(1.0*sin(z*.42)+.30*sin(z*.83) if index==1 else 1.5*sin(z*.4),0,z))
  ribbon(g,root,"MainStream",points,1.10 if index==1 else 1.2,.12)
  if index==7:
   for side in range(2):
    var x=-3.0 if side==0 else 3.0
    ribbon(g,root,"Flow%d"%side,[Vector3(0,0,0),Vector3(x,0,-.5),Vector3(x,0,-4),Vector3(x,0,-7)],.42,.10)
   var audio=AudioStreamPlayer3D.new();audio.name="StreamVoice";root.add_child(audio)
   audio.stream=load("res://assets/audio/waterside.wav")
   audio.unit_size=4;audio.max_distance=18;audio.volume_db=-14;audio.play()
 elif index==9:water_surface(g,root,"MoonPool",circle_points(-1,0,2.9,2.9),.95)

static func landmark_trees(g,root: Node3D,index: int) -> void:
 var layout={0:[[32,-8,-6],[32,8,-7]],1:[[29,-8,-7],[30,8,7]],2:[[93,-8,-8],[31,8,-8]],3:[[38,-8,7],[45,8,-8]],4:[[28,-8,8],[29,8,8]],5:[[34,-8,-8],[31,8,-8]],6:[[23,-7,-7],[29,8,7]],7:[[30,-7,-6],[30,7,6],[32,7,-7]],8:[[93,-8,6],[92,8,-6]],9:[[29,-8,-7],[33,8,-8]]}
 for item in layout[index]:
  var tree=g.Art.plant(g.catalogue[int(item[0])],true)
  var location=Vector3(item[1],0,item[2])
  if GardenAreaTransitions.on_path(index,root.position+location):location.z+=1.6 if index==4 else -1.6
  root.add_child(tree);tree.position=local_point(index,location)
  tree.set_meta("terrain_anchor",true)
  GardenLandscape.trunk_collision(tree,.16,2.0)

static func visit(g,index: int) -> void:
 if index<0 or index>=10:return
 if g.photo_mode:g.toggle_photo()
 if not g.rest_kind.is_empty():GardenLeisure.leave(g)
 GardenAreaAtlas.close(g)
 initialize(g,index)
 var s=state(g,index);s.visited=true
 var arrival=GardenAreaCatalogue.entry(index).get("arrival",[7.5,7.5])
 g.player.position=GardenTerrain.point(GardenAreaCatalogue.center(index)+Vector3(arrival[0],0,arrival[1]))+Vector3(0,.15,0)
 g.player.velocity=Vector3.ZERO;g.yaw=PI/4 if index%2==0 else -PI/4;g.pitch=.08
 g.current_plot=index+4;g.set_mode("walk",false);g.side_panel.hide()
 g.dismiss_request();g.resume_controls();visual(g,index);g.refresh_wildlife();g.refresh_ui();g.save_game()
 g.toast(GardenAreaCatalogue.entry(index).name+" · E opens this garden’s activities. The atlas is in Guide.")

static func initialize(g,index: int) -> void:
 var s=state(g,index)
 if s.initialized:return
 s.initialized=true
 var bench_spots=[Vector3(6,0,3),Vector3(-5,0,7),Vector3(2,0,6.5),Vector3(6,0,5),Vector3(-6,0,6),Vector3(5.5,0,-5.8),Vector3(0,0,-4.6),Vector3(-5,0,5),Vector3(-2,0,-7),Vector3(3.8,0,6)]
 g.add_object("bench",GardenAreaCatalogue.center(index)+bench_spots[index],0,false)
 var seeds: Array=GardenAreaCatalogue.entry(index).seeds
 for id in seeds:
  if int(id) not in g.unlocked_plants:g.unlocked_plants.append(int(id))
 var c=GardenAreaCatalogue.center(index)
 if index==0:
  for slot in [0,3,6]:plant_collection(g,index,slot,default_species(index,slot),false)
 elif index==1:plant_collection(g,index,0,"maidenhair",false)
 elif index==2:
  for j in range(4):g.add_object("wide_bowl" if j%2==0 else "pot",c+Vector3([-4.5,4.1,3.3,-4.4][j],0,[6,-6.8,1.5,-2.8][j]),0,false)
 elif index==4:
  for j in range(4):
   var id=[35,83,84,82][j]
   if id not in g.unlocked_plants:g.unlocked_plants.append(id)
   g.add_plant(id,c+Vector3(-4 if j%2==0 else 4,0,4 if j<2 else -1),index+4,float(g.catalogue[id].days)*.55)
 elif index==5:
  for j in range(2):g.add_object("vertical_planter",c+Vector3(-5.6 if j==0 else 5.6,0,-6.1),0,false)
  g.add_object("herb_trough",c+Vector3(0,0,-5.6),0,false)
 elif index==8:plant_collection(g,index,0,"edelweiss",false)
 elif index==9:
  plant_collection(g,index,0,"moonflower",false);plant_collection(g,index,1,"nicotiana",false)
 visual(g,index)

static func default_species(index: int,slot: int) -> String:
 return str(GardenAreaCatalogue.entry(index).slots[slot].default)

static func choices(g,index: int,slot: int) -> Array:
 var spec=GardenAreaCatalogue.entry(index).slots[slot]
 match index:
  0:return {"deep":["lily","hawthorn"],"margin":["iris","reed"],"bank":["mint"]}[str(spec.depth)]
  1:
   var result=["maidenhair"]
   if "Mossy hollow" in state(g,index).discoveries:result.append("birdsnest")
   if "Old fern grove" in state(g,index).discoveries:result.append("treefern")
   return result
  6:return ["orchid","cymbidium","hoya","maidenhair"] if state(g,index).restored[int(spec.bay)] else []
  8:return ["edelweiss","gentian","saxifrage"]
  9:return ["primrose","nicotiana","moonflower","nightphlox"]
 return []

static func plant_collection(g,index: int,slot: int,species: String,notify: bool=true) -> bool:
 var slots: Array=GardenAreaCatalogue.entry(index).slots
 if slot<0 or slot>=slots.size() or species not in choices(g,index,slot):return false
 var s=state(g,index)
 if s.beds.has(str(slot)):return false
 s.beds[str(slot)]={"species":species,"age":0.0,"water":4.0,"offset_day":0}
 if notify:g.toast(GardenAreaCatalogue.data().specialties[species].name+" planted in pocket %d."%(slot+1))
 visual_collection(g,index);return true

static func slot_position(g,index: int,slot: int,plant: Dictionary={}) -> Vector3:
 var spec=GardenAreaCatalogue.entry(index).slots[slot]
 var local=Vector3(float(spec.pos[0]),0,float(spec.pos[1]))
 var p=local_point(index,local)
 p.y+=float(spec.get("elevation",0))
 if index==0 and not plant.is_empty() and plant.species in ["lily","hawthorn"]:p.y=water_level(g)+.018
 return p

static func water_level(g) -> float:
 return [.52,.72,.92][int(state(g,0).sluice)]

static func pocket_rate(g,index: int,slot: int,plant: Dictionary) -> float:
 var s=state(g,index)
 var season=GardenClimate.season(g.day)
 match index:
  0:
   var depth=water_level(g)-slot_position(g,index,slot).y
   var band=str(GardenAreaCatalogue.entry(index).slots[slot].depth)
   return 1.2 if (band=="deep" and depth>.25) or (band=="margin" and depth>0 and depth<.38) or (band=="bank" and depth<.10) else .55
  1:
   var local=GardenAreaCatalogue.entry(index).slots[slot].pos
   var clearing=clampi(roundi((float(local[0])+3.8)/3.8),0,2)
   return .65 if s.clearings[clearing] else 1.15
  6:
   var bay=int(GardenAreaCatalogue.entry(index).slots[slot].bay)
   if not s.restored[bay]:return 0.0
   var humid=bool(s.mist[bay]) and bool(s.shade[bay])
   if plant.species=="cymbidium":return 1.2 if s.vents[bay] and not s.shade[bay] else .7
   return 1.2 if humid else .75
  8:return 1.2 if s.windbreaks[slot%3] and season!="Winter" else (.4 if season=="Winter" else .7)
  9:return 1.15
 return 1.0

static func visual_collection(g,index: int) -> void:
 if index>=g.area_roots.size():return
 var root: Node3D=g.area_roots[index]
 var collection=root.get_node("LivingCollection")
 for child in collection.get_children():collection.remove_child(child);child.free()
 var s=state(g,index)
 for key in s.beds:
  var slot=int(key);var p: Dictionary=s.beds[key]
  var model=instantiate("res://assets/areas/plants/"+p.species+".glb")
  if not model:continue
  var age=clampf(float(p.age)/float(GardenAreaCatalogue.data().specialties[p.species].days),0,1)
  model.name="Pocket%d"%slot;collection.add_child(model)
  model.position=slot_position(g,index,slot,p)
  model.rotation.y=slot*2.399
  GardenAreaFlora.growth(model,age,index!=9 or dusk(g))
  g.Art.add_leaf_wind(model)
  model.set_meta("species",p.species)
  var flowers=find(model,"Flowers")
  if flowers and age>=.78:flowers.visible=index!=9 or dusk(g)
  var marker=Node3D.new();marker.name="Label";model.add_child(marker)
  g.Art.seed_marker(marker,Color("e2d9a2"));marker.visible=age<.30
 for slot in range(GardenAreaCatalogue.entry(index).slots.size()):
  if s.beds.has(str(slot)):continue
  var marker=Node3D.new();marker.name="EmptyPocket%d"%slot;collection.add_child(marker)
  marker.position=slot_position(g,index,slot);g.Art.seed_marker(marker,Color("9ea888"))

static func visible_node(root: Node,prefix: String,shown: bool) -> void:
 var node=find(root,prefix)
 if node:
  node.visible=shown
  collision_enabled(node,shown)

static func collision_enabled(node: Node,enabled: bool) -> void:
 if node is CollisionShape3D:node.set_deferred("disabled",not enabled)
 for child in node.get_children():collision_enabled(child,enabled)

static func prop_blocks(g,pos: Vector3) -> bool:
 var origin=GardenTerrain.point(pos)
 var space=g.get_world_3d().direct_space_state
 # Include tool-target surfaces of user furniture, even inside ordinary beds.
 # A few centimetres of root clearance prevents stems entering rock edges.
 for offset in [Vector3.ZERO,Vector3(.14,0,0),Vector3(-.14,0,0),Vector3(0,0,.14),Vector3(0,0,-.14)]:
  var query=PhysicsRayQueryParameters3D.create(origin+offset+Vector3(0,2.4,0),origin+offset-Vector3(0,.06,0),3)
  if is_instance_valid(g.player):query.exclude=[g.player.get_rid()]
  query.hit_back_faces=true
  var hit=space.intersect_ray(query)
  if not hit.is_empty() and is_instance_valid(hit.collider) and (hit.collider.get_meta("area_obstacle",false) or hit.collider.get_meta("planting_obstacle",false) or hit.collider.has_meta("structure")):return true
 return false

static func repair_starter_container(kind: String,pos: Vector3,price: int) -> Vector3:
 if price!=0 or kind not in ["pot","wide_bowl"]:return pos
 var center=GardenAreaCatalogue.center(2)
 var previous=[Vector3(-5,0,5),Vector3(4,0,-5),Vector3(3,0,0),Vector3(-5,0,-6)]
 var corrected=[Vector3(-4.5,0,6),Vector3(4.1,0,-6.8),Vector3(3.3,0,1.5),Vector3(-4.4,0,-2.8)]
 for j in range(4):
  if Vector2(pos.x-center.x-previous[j].x,pos.z-center.z-previous[j].z).length()<.01:return center+corrected[j]
 return pos

static func visual(g,index: int) -> void:
 if index<0 or index>=g.area_roots.size():return
 var root: Node3D=g.area_roots[index];var s=state(g,index)
 root.visible=true
 match index:
  0:
   var water=root.get_node_or_null("InletWater")
   if water:water.position.y=water_level(g)-.72
  1:
   for j in range(3):visible_node(root,"Canopy%d"%j,not s.clearings[j])
  2:
   for j in range(3):visible_node(root,"RainShelter%d"%j,s.shelters[j])
  6:
   for j in range(3):
    visible_node(root,"RestoredBay%d"%j,s.restored[j]);visible_node(root,"OldBay%d"%j,not s.restored[j])
    visible_node(root,"GlassShade%d"%j,s.shade[j])
    var vent=find(root,"GlassVent%d"%j)
    if vent:vent.rotation.x=-.48 if s.vents[j] else 0
    root.get_node("BayMist%d"%j).emitting=s.restored[j] and s.mist[j] and not g.settings.reduced_motion
  7:
   for j in range(2):
    visible_node(root,"Flow%d"%j,s.gates[j])
    var gate=find(root,"StreamGate%d"%j)
    if gate:gate.position.y=local_point(index,Vector3(-3 if j==0 else 3,0,-.5)).y+(.34 if s.gates[j] else 0)
   var voice=root.get_node_or_null("StreamVoice")
   if voice:voice.volume_db=-14+3*s.gates.count(true)
  8:
   for j in range(3):visible_node(root,"Windbreak%d"%j,s.windbreaks[j])
  9:
   visible_node(root,"DuskFlowers",dusk(g))
   for j in range(3):
    var lantern=find(root,"MoonLantern%d"%j)
    if lantern and lantern.has_node("MoonLight"):
     lantern.get_node("MoonLight").light_energy=[0.0,.9,1.6][int(s.lanterns)] if dusk(g) else 0
     lantern.get_node("LampWick").visible=dusk(g) and int(s.lanterns)>0
 visual_collection(g,index)

static func dusk(g) -> bool:
 return g.clock_time>=.76 or g.clock_time<=.23

static func animate(g,delta: float,time: float) -> void:
 if g.area_roots.size()<9:return
 var root: Node3D=g.area_roots[8]
 var swing=find(root,"ChimeSwing")
 if swing:swing.rotation.z=0 if g.settings.reduced_motion else sin(time*.9)*(.045+g.climate.current.x*.05)
 var voice=root.get_node("ChimeVoice")
 var volume=float(g.ambient.nature_volume) if is_instance_valid(g.ambient) else 1.0
 voice.volume_db=-17+linear_to_db(maxf(.0001,volume))
 var timer=float(root.get_meta("chime_timer",12.0))-delta
 if timer<=0:
  if volume>0 and g.player.position.distance_to(root.position)<22:voice.play()
  timer=18+fposmod(time,11.0)
 root.set_meta("chime_timer",timer)
 var stream=g.area_roots[7].get_node_or_null("StreamVoice")
 if stream:stream.volume_db=-14+3*state(g,7).gates.count(true)+linear_to_db(maxf(.0001,volume))

static func local(g,p: Dictionary) -> Vector3:
 return p.pos-GardenAreaCatalogue.center(int(p.plot)-4)

static func context(g,p: Dictionary,actual: String) -> Dictionary:
 var index=int(p.plot)-4
 if index<0 or index>=10:return {"actual":actual,"bonus":1.0,"protected":false,"reason":""}
 var s=state(g,index);var point=local(g,p);var data=g.catalogue[int(p.id)]
 var result={"actual":actual,"bonus":1.0,"protected":false,"reason":""}
 match index:
  1:
   var clearing=clampi(roundi((point.x+3.8)/3.8),0,2)
   result.actual="sun" if s.clearings[clearing] else "shade"
   if data.condition==result.actual:result.bonus=1.10;result.reason="Comfortable in the fern clearing"
  2:
   if data.category=="Cacti & succulents":result.bonus=1.15;result.reason="Free-draining limestone pocket · +15% growth"
  5:
   var companion=false
   for other in g.planted:
    if int(other.plot)!=int(p.plot) or other==p or other.pos.distance_to(p.pos)>1.8:continue
    if data.category=="Produce" and (int(other.id) in [12,19,22,54] or g.catalogue[int(other.id)].category=="Flowers"):companion=true;break
   if companion:result.bonus=1.15;result.reason="Companion planting · +15% growth"
   var previous=str(s.rotation.get(str(kitchen_bed(point)),""))
   if data.category=="Produce" and not previous.is_empty() and previous!=crop_family(int(p.id)):
    result.bonus+=.10;result.reason="Rotated crop family · +10% growth"+("; companions +15%" if companion else "")
  6:
   var bay=clampi(floori((point.z+5.4)/3.6),0,2)
   result.protected=bool(s.restored[bay]);result.actual="shade" if s.shade[bay] else "sun"
   result.reason="Restored glasshouse bay · grows year-round" if result.protected else "Unrestored bay follows the seasons"
  7:
   var branch=0 if point.x<0 else 1
   if s.gates[branch] and absf(absf(point.x)-3)<1.5 and point.z<0:result.bonus=1.1;result.reason="Open stream gate · watered each morning"
  8:
   var pocket=alpine_pocket(point)
   if int(data.layer)<2 and s.windbreaks[pocket]:result.bonus=1.15;result.reason="Sheltered alpine pocket · +15% growth"
 return result

static func rain_reaches(g,p: Dictionary) -> bool:
 var index=int(p.plot)-4
 if index==2:
  var band=clampi(roundi((3.1-local(g,p).z)/4.4),0,2)
  if state(g,index).shelters[band] and absf(local(g,p).x+3)<1.3 and absf(local(g,p).z-(3.1-band*4.4))<.9:return false
 if index==6:return not state(g,index).restored[clampi(floori((local(g,p).z+5.4)/3.6),0,2)]
 return true

static func water_loss(g,p: Dictionary,loss: float) -> float:
 var index=int(p.plot)-4
 if index==2 and g.catalogue[int(p.id)].category=="Cacti & succulents":return loss*.7
 if index==6:
  var bay=clampi(floori((local(g,p).z+5.4)/3.6),0,2)
  if state(g,index).restored[bay] and state(g,index).mist[bay]:return loss*.35
 return loss

static func stress_gain(g,p: Dictionary,gain: float) -> float:
 if int(p.plot)==12 and int(g.catalogue[int(p.id)].layer)<2 and state(g,8).windbreaks[alpine_pocket(local(g,p))]:return maxf(0,gain-.06)
 if str(p.get("area_training",""))=="open":return maxf(0,gain-.03)
 return gain

static func alpine_pocket(point: Vector3) -> int:
 var spots=[Vector3(-4,0,-2),Vector3(2,0,-5),Vector3(4,0,1)]
 var nearest=0;var best=INF
 for j in range(3):
  var distance=Vector2(point.x-spots[j].x,point.z-spots[j].z).length_squared()
  if distance<best:best=distance;nearest=j
 return nearest

static func morning(g) -> void:
 # Called before normal growth: flowing strips and glasshouse mist provide
 # ordinary water; manual watering remains a separate +20% bonus.
 var alpine_state=state(g,8)
 if GardenClimate.season(g.day)=="Winter" and GardenClimate.season(g.day+1)=="Spring":alpine_state.melt=3
 elif int(alpine_state.melt)>0:alpine_state.melt=int(alpine_state.melt)-1
 for p in g.planted:
  var index=int(p.plot)-4
  if index==7:
   var point=local(g,p);var branch=0 if point.x<0 else 1
   if state(g,index).gates[branch] and absf(absf(point.x)-3)<1.5 and point.z<0:p.water=4.0
  elif index==6:
   var s=state(g,index);var bay=clampi(floori((local(g,p).z+5.4)/3.6),0,2)
   if s.restored[bay] and s.mist[bay]:p.water=4.0
  elif index==8 and int(state(g,index).melt)>0:p.water=4.0
 for index in range(10):
  var s=state(g,index)
  for key in s.beds:
   var slot=int(key);var plant: Dictionary=s.beds[key]
   var spec=GardenAreaCatalogue.data().specialties[plant.species]
   if index==0:plant.water=4.0
   if index==6:
    var bay=int(GardenAreaCatalogue.entry(index).slots[slot].bay)
    if s.mist[bay] and s.restored[bay]:plant.water=4.0
   if index==8 and int(s.melt)>0:plant.water=4.0
   plant.age=minf(float(spec.days),float(plant.age)+pocket_rate(g,index,slot,plant)*(1.0 if float(plant.water)>0 else .45))
   plant.water=maxf(0,float(plant.water)-(0 if index==0 else .5 if index==6 else 1))

static func after_morning(g) -> void:
 for index in range(10):
  if g.area_roots.size()>index and g.area_roots[index].visible:visual(g,index)
 observe_meadow(g,false)

static func kitchen_bed(point: Vector3) -> int:
 return (0 if point.x<0 else 1)+(0 if point.z<0 else 2)

static func crop_family(id: int) -> String:
 if id in [46,51,58]:return "Roots"
 if id in [48,97,99,100,101,103,104]:return "Leaves"
 if id==52:return "Legumes"
 if id in [12,19,22,54]:return "Herbs"
 return "Fruiting crops"

static func harvested(g,p: Dictionary) -> void:
 if int(p.plot)==9 and g.catalogue[int(p.id)].category=="Produce":
  state(g,5).rotation[str(kitchen_bed(local(g,p)))]=crop_family(int(p.id))
 if p.has("area_graft"):
  var id=int(p.area_graft)
  g.inventory[str(id)]=int(g.inventory.get(str(id),0))+1

static func train(g,p: Dictionary,style: String) -> bool:
 if int(p.plot)!=8 or int(p.id) not in GardenPlantGrowth.FRUIT_TREES or style not in ["open","fan","espalier"]:return false
 p["area_training"]=style;p.stress=maxf(0,float(p.stress)-.15);g.refresh_plant(p,false)
 g.toast(g.catalogue[int(p.id)].name+" trained as "+style+".");return true

static func compatible_grafts(id: int) -> Array:
 for family in FRUIT_FAMILIES:
  if id in family:return family.filter(func(other):return other!=id)
 return []

static func graft(g,p: Dictionary,donor: int) -> bool:
 if int(p.plot)!=8 or donor not in compatible_grafts(int(p.id)) or p.has("area_graft") or float(p.age)<float(g.catalogue[int(p.id)].days)*.78:return false
 if GardenEquipment.spare_count_for(g,donor)<2:g.toast("Keep two spare donor fruit items for a graft. Neighbour requests are kept aside.");return false
 g.inventory[str(donor)]=int(g.inventory[str(donor)])-2
 p["area_graft"]=donor;g.refresh_plant(p,false)
 g.toast("A "+g.catalogue[donor].name+" branch is grafted onto this tree. Gathering it will also bring one donor fruit.");return true

static func apply_tree(g,p: Dictionary) -> void:
 var style=str(p.get("area_training",""))
 if not style.is_empty():
  p.node.scale=g.plant_scale(p)
 var branch=p.node.get_node_or_null("GraftedBranch")
 if p.has("area_graft") and not branch:
  branch=g.Art.plant(g.catalogue[int(p.area_graft)],true);branch.name="GraftedBranch"
  p.node.add_child(branch);branch.position=Vector3(.60,1.7,0);branch.scale=Vector3.ONE*.24
  branch.set_meta("terrain_anchor",false)
 if branch:branch.visible=float(p.age)>=float(g.catalogue[int(p.id)].days)*.78

static func offsets(g,p: Dictionary) -> bool:
 if int(p.plot)!=6 or g.catalogue[int(p.id)].category!="Cacti & succulents" or float(p.age)<float(g.catalogue[int(p.id)].days):return false
 if int(p.get("area_offset_day",0))>g.day:g.toast("This plant is resting after its last offsets.");return false
 var saved=GardenContainers.record(p);saved.erase("container_uid");saved.erase("container_slot")
 saved.erase("area_offset_day");saved.age=float(g.catalogue[int(p.id)].days)*.12;saved.water=4;saved.stress=0;saved.pruned=0;saved.prune_cuts=0
 saved["storage_source"]="Limestone offsets";g.workshop_state.nursery.append(saved)
 p["area_offset_day"]=g.day+4;p.age=maxf(0,p.age-.4);g.refresh_plant(p,false)
 g.toast("A young "+g.catalogue[int(p.id)].name+" offset is ready in Stored plants.");return true

static func kitchen_basket(g,key: String) -> bool:
 if not KITCHEN_RECIPES.has(key):return false
 var s=state(g,5)
 if int(s.basket_day)==g.day:g.toast("The kitchen table will be ready for another basket tomorrow.");return false
 var recipe=KITCHEN_RECIPES[key]
 for id in recipe.items:
  if GardenEquipment.spare_count_for(g,id)<1:g.toast("Gather each listed ingredient first. Neighbour request items are kept aside.");return false
 for id in recipe.items:g.inventory[str(id)]=int(g.inventory[str(id)])-1
 g.workshop_state.resources[recipe.supply]=int(g.workshop_state.resources.get(recipe.supply,0))+2
 GardenEconomy.earn(g,int(recipe.reward));s.basket_day=g.day
 g.toast(recipe.name+" prepared · petals and two portions of "+GardenEquipment.RECIPES[recipe.supply].name+".");return true

static func orchard_basket(g) -> bool:
 var s=state(g,4)
 if int(s.basket_day)==g.day:g.toast("The orchard table will be ready again tomorrow.");return false
 var ids=[]
 for id in GardenPlantGrowth.FRUIT_TREES:
  if GardenEquipment.spare_count_for(g,id)>0:ids.append(id)
 if ids.size()<3:g.toast("Gather three different spare fruit varieties for this seasonal basket.");return false
 for id in ids.slice(0,3):g.inventory[str(id)]=int(g.inventory[str(id)])-1
 s.basket_day=g.day;GardenEconomy.earn(g,30)
 g.workshop_state.resources.compost=int(g.workshop_state.resources.get("compost",0))+2
 g.toast("Seasonal orchard basket ready · petals and two compost portions.");return true

static func restore_bay(g,bay: int) -> bool:
 var s=state(g,6)
 if bay<0 or bay>2 or s.restored[bay]:return false
 if g.coins<30:g.toast("Restoring a glasshouse bay takes 30 petals.");return false
 g.coins-=30;s.restored[bay]=true;s.mist[bay]=true;s.shade[bay]=bay!=1
 for slot in range(GardenAreaCatalogue.entry(6).slots.size()):
  if int(GardenAreaCatalogue.entry(6).slots[slot].bay)==bay:
   plant_collection(g,6,slot,default_species(6,slot),false);break
 visual(g,6);g.toast("Bay %d restored. Its collection pocket and growing controls are ready."%(bay+1));return true

static func observe_meadow(g,notify: bool=true) -> Array:
 var flowers=0;var ids=[];var native=false
 for p in g.planted:
  if int(p.plot)!=7 or float(p.age)<float(g.catalogue[int(p.id)].days)*.78:continue
  var data=g.catalogue[int(p.id)]
  if data.category=="Flowers" or data.category=="Natives":
   flowers+=1
   if int(p.id) not in ids:ids.append(int(p.id))
   if data.category=="Natives":native=true
 var found=[];var s=state(g,3)
 for kind in JOURNAL:
  var rule=JOURNAL[kind]
  if flowers<int(rule.flowers) or ids.size()<int(rule.types):continue
  if rule.get("native",false) and not native:continue
  if rule.get("night",false)!=dusk(g):continue
  if kind not in s.journal:
   s.journal.append(kind);found.append(rule.name)
   if int(rule.gift) not in g.unlocked_plants:g.unlocked_plants.append(int(rule.gift))
 if notify and not found.is_empty():g.toast("Habitat journal: "+", ".join(found)+". A seed gift is in your collection.")
 return found

static func season_coverage(g) -> Array:
 var coverage=[]
 for p in g.planted:
  if int(p.plot)!=7:continue
  var data=g.catalogue[int(p.id)]
  if data.category!="Flowers" and data.category!="Natives":continue
  for season in (GardenClimate.SEASONS if data.seasons.is_empty() else data.seasons):
   if season not in coverage:coverage.append(season)
 return coverage

static func photograph(g) -> void:
 if GardenAreaCatalogue.index_at(g.camera.position)!=9 or not dusk(g):return
 var s=state(g,9);var blooms=0
 for p in s.beds.values():
  if float(p.age)>=float(GardenAreaCatalogue.data().specialties[p.species].days)*.72:blooms+=1
 if s.photo or blooms<3 or int(s.lanterns)>1:return
 s.photo=true
 if 74 not in g.unlocked_plants:g.unlocked_plants.append(74)
 g.toast("Moon Garden memory collected · three dusk flowers in soft light. Iceberg rose seeds are yours.")
 g.save_game()

static func update(g,delta: float) -> void:
 g.area_update_time+=delta
 if g.area_update_time<.5:return
 var elapsed=g.area_update_time
 g.area_update_time=0
 for j in range(10):
  for pocket in state(g,j).beds.values():
   var wet=g.climate.current.y>0 and j!=6
   if wet:pocket.water=minf(4,float(pocket.water)+g.climate.current.y*elapsed/24.0)
 var index=GardenAreaCatalogue.index_at(g.player.position)
 for j in range(g.area_roots.size()):
  var root: Node3D=g.area_roots[j]
  # The connected land stays visible. Individual ornaments cull by distance.
  root.visible=true
  if not root.get_meta("activity_visual_ready",false):
   visual(g,j);root.set_meta("activity_visual_ready",true)
 if index>=0:
  initialize(g,index);state(g,index).visited=true
  if index==1:
   var points=[Vector3(-3,0,3),Vector3(3,0,-4),Vector3(-3,0,-6)]
   var names=["Mossy hollow","Old fern grove","Spring clearing"]
   for j in range(3):
    if names[j] not in state(g,1).discoveries and Vector2(g.player.position.x-GardenAreaCatalogue.center(1).x-points[j].x,g.player.position.z-GardenAreaCatalogue.center(1).z-points[j].z).length()<1.8:
     state(g,1).discoveries.append(names[j]);g.toast("Discovered "+names[j]+" · another fern collection is ready in Activities.")
  elif index==3:
   var found=observe_meadow(g)
   if not found.is_empty():g.refresh_wildlife()
 if g.area_roots.size()>9 and g.area_roots[9].visible:
  var root=g.area_roots[9];visible_node(root,"DuskFlowers",dusk(g))
  for plant in root.get_node("LivingCollection").get_children():
   var flowers=find(plant,"Flowers")
   if flowers:
    var slot=int(String(plant.name).trim_prefix("Pocket"))
    var p=state(g,9).beds.get(str(slot),{})
    flowers.visible=not p.is_empty() and float(p.age)>=float(GardenAreaCatalogue.data().specialties[p.species].days)*.72 and dusk(g)
  for j in range(3):
   var lantern=find(root,"MoonLantern%d"%j)
   if lantern and lantern.has_node("MoonLight"):
    lantern.get_node("MoonLight").light_energy=[0.0,.9,1.6][int(state(g,9).lanterns)] if dusk(g) else 0
    lantern.get_node("LampWick").visible=dusk(g) and int(state(g,9).lanterns)>0

static func plantable(pos: Vector3) -> bool:
 var index=GardenAreaCatalogue.index_at(pos)
 if index<0:return true
 var p=pos-GardenAreaCatalogue.center(index)
 if GardenAreaTransitions.on_path(index,pos):return false
 if absf(p.x)>8.1 or absf(p.z)>8.1:return false
 match index:
  0:return Vector2(p.x+1.4,p.z*1.1).length()>5.1 and absf(p.z-5.1)>1.0
  1:return absf(p.x-(1.0*sin(p.z*.42)+.30*sin(p.z*.83)))>.90 and absf(p.x-(1.0*sin(p.z*.42)+.30*sin(p.z*.83))-1.55)>.65
  2:return absf(p.x)<5.7 and absf(p.z+5)>.5 and absf(p.z+.5)>.5 and absf(p.z-4)>.5
  3:return absf(p.x-3*sin(p.z*.4))>1.0
  4:return absf(p.z+6)>.5
  5:return absf(p.x)>1.4 and absf(p.x)<4.8 and absf(p.z)>1.4 and absf(p.z)<4.8
  6:return absf(p.x)<2.6 and absf(p.z)<4.1
  7:return absf(p.x-1.5*sin(p.z*.4))>1.4 and absf(p.z-3)>1.0
  8:return absf(p.x)<6 and absf(p.z)<6
  9:return Vector2(p.x+1,p.z).length()>3.4 and p.x> -3.1
 return true

static func can_sculpt(pos: Vector3) -> bool:
 var index=GardenAreaCatalogue.index_at(pos)
 if index<0:return true
 return index in [1,3,4,8] and plantable(pos) and absf((pos-GardenAreaCatalogue.center(index)).x)<5.0

static func walkable(pos: Vector3) -> bool:
 var index=GardenAreaCatalogue.index_at(pos)
 if index<0:return false
 var p=pos-GardenAreaCatalogue.center(index)
 if index==0 and Vector2(p.x+1.4,p.z*1.1).length()<4.1 and absf(p.z-5.1)>.9:return false
 if index==9 and Vector2(p.x+1,p.z).length()<2.9:return false
 if index==7 and absf(p.x-1.5*sin(p.z*.4))<.65 and absf(p.z-3)>.8 and absf(p.z+3.3)>.8:return false
 return true

static func interact(g) -> bool:
 if g.mode!="walk" or g.photo_mode or g.day_transition:return false
 var index=GardenAreaCatalogue.index_at(g.player.position)
 if index<0:return false
 GardenAreaAtlas.open(g,index);return true

static func wildlife_entries(g) -> Array:
 var result=[]
 for index in [0,1,3,7,9]:
  if not state(g,index).visited:continue
  var center=GardenTerrain.point(GardenAreaCatalogue.center(index))
  var species=[]
  if index in [0,7]:species=["frog","dragonfly"]
  elif index==1:species=["firefly"] if not state(g,index).discoveries.is_empty() else []
  elif index==3:species=state(g,index).journal.duplicate()
  elif index==9:
   if state(g,index).beds.size()>=3:
    species=["emperor gum moth"] if int(state(g,index).lanterns)==2 else ["firefly","emperor gum moth"]
  for kind in species:result.append({"kind":kind,"target":center+Vector3(-3 if index==9 else 2,0,2),"height":1.1 if kind!="frog" else 0,"area":index})
 return result
