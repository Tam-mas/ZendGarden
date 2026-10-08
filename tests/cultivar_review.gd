extends SceneTree

var g
var output=""

func _initialize() -> void:call_deferred("review")

func capture(name: String) -> void:
 for frame in range(5):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(output+"/"+name+".png")

func review() -> void:
 output=OS.get_environment("ZEND_REVIEW_OUTPUT")
 if output.is_empty():quit(1);return
 DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(1280,960);root.content_scale_size=root.size
 g=preload("res://tests/plant_breeding.gd").TestGarden.new();root.add_child(g)
 g.SAVE_PATH="user://cultivar-review.json"
 g.ui=CanvasLayer.new();g.add_child(g.ui)
 g.plant_root=Node3D.new();g.add_child(g.plant_root)
 g.object_root=Node3D.new();g.add_child(g.object_root)
 g.player=CharacterBody3D.new();g.add_child(g.player)
 g.climate=GardenClimate.new();g.add_child(g.climate)
 g.side_panel=PanelContainer.new();g.ui.add_child(g.side_panel);g.side_panel.hide()
 g.settings.reduced_motion=true;g.workshop_state.resources.starter_mix=12;g.coins=200
 var backdrop=ColorRect.new();backdrop.color=Color("293427");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);g.ui.add_child(backdrop)
 var layout=VBoxContainer.new();layout.position=Vector2(20,10);layout.size=Vector2(1240,930);g.ui.add_child(layout)
 layout.add_child(g.label("Your own cultivars · real plant models and tissue markings",26))
 var grid=GridContainer.new();grid.columns=3;grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(grid)
 var ids=[148,149,151,158,182,190,198,204,211]
 for i in range(ids.size()):
  var id=ids[i]
  var uid=GardenPlantBreeding.create(g,id,{"bloom":[1,2],"pattern":[GardenPlantBreeding.PROFILES[id][2][i%GardenPlantBreeding.PROFILES[id][2].size()],0],"habit":[i%3,1]},0 if id==158 else i%4+1,18+i)
  var f=GardenPlantBreeding.form(g,uid);f.name="Garden selection";f.registered=true
  var tile=VBoxContainer.new();tile.custom_minimum_size=Vector2(408,280);grid.add_child(tile)
  tile.add_child(g.label(g.catalogue[id].name,18))
  var view=GardenCultivarPreview.new();view.setup(g,f);view.turning=false;view.custom_minimum_size=Vector2(390,210);tile.add_child(view)
  var traits=g.label(GardenPlantBreeding.traits(f),13);traits.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;tile.add_child(traits)
 await capture("cultivar-variations")
 layout.queue_free()
 await process_frame
 var cards=GridContainer.new();cards.columns=3;cards.position=Vector2(30,30);g.ui.add_child(cards)
 for f in g.breeding_state.forms.values():
  var card=VBoxContainer.new();card.custom_minimum_size=Vector2(390,270);cards.add_child(card)
  card.add_child(g.label(g.catalogue[int(f.species)].name,18))
  var thumb=GardenCultivarThumbnail.new();thumb.setup(g,f);thumb.custom_minimum_size=Vector2(320,220);card.add_child(thumb)
 for frame in range(64):await process_frame
 if GardenCultivarThumbnail.textures.size()!=9:push_error("Cultivar thumbnails did not render or cache");quit(1);return
 await capture("cultivar-thumbnails")
 cards.queue_free()
 await process_frame
 g.add_object("potting_bench",Vector3.ZERO,75)
 var bench=g.objects.back()
 g.breeding_selected="form-1"
 for tab in ["Propagate","Breed","My cultivars"]:
  g.breeding_tab=tab;GardenWorkshop.open(g,bench.uid)
  # Show the actual rotating model and its actions in the library capture.
  if tab=="My cultivars":
   var scroll=g.welcome.find_child("WorkshopScroll",true,false)
   await process_frame
   scroll.ensure_control_visible(g.welcome.find_child("CultivarPreview",true,false))
  await capture("cultivar-bench-"+tab.to_lower().replace(" ","-"))
  GardenWorkshop.close(g)
 root.size=Vector2i(390,844);root.content_scale_size=root.size
 g.breeding_tab="Propagate";GardenWorkshop.open(g,bench.uid)
 await capture("cultivar-bench-phone")
 GardenWorkshop.close(g)
 g.free()
 for frame in range(3):await process_frame
 print("CULTIVAR_REVIEW_RESULT: PASS")
 quit(0)
