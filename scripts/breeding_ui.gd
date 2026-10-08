class_name GardenBreedingUI
extends RefCounted

const TABS=["Propagate","Breed","Nursery","My cultivars"]

static func open_library(g) -> void:
 g.breeding_library_open=true;g.breeding_tab="My cultivars"
 GardenWorkshop.open(g)

static func build(g, column: Control, obj: Dictionary) -> void:
 var bench=obj
 if bench.is_empty():
  for candidate in g.objects:
   if GardenPlantBreeding.bench_ready(g,candidate):bench=candidate;break
 var tabs=GridContainer.new();tabs.columns=2;tabs.name="BreedingTabs";column.add_child(tabs)
 for tab in TABS:
  var chosen=tab
  var button=g.button(tab,func():g.breeding_tab=chosen;g.breeding_page=0;GardenWorkshop.open(g,g.workshop_uid),Vector2(0,48))
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;GardenTheme.choose(button,g.breeding_tab==tab);tabs.add_child(button)
 GardenWorkshop.note(g,column,"Discover, preserve and grow the next generation.",14)
 if not bench.is_empty():GardenWorkshop.note(g,column,"Potting bench · %d propagation spaces"%(4 if bench.work.get("upgraded",false) else 2),13)
 elif g.breeding_tab in ["Propagate","Breed"]:GardenWorkshop.note(g,column,"Place a potting bench from the shed to begin.",15)
 match g.breeding_tab:
  "Propagate":propagate(g,column,bench)
  "Breed":breed(g,column,bench)
  "Nursery":nursery(g,column)
  _:library(g,column)

static func observed_forms(g) -> Array:
 # Preserve mature originals when the player visits the bench, so those can
 # be parents too. The snapshot survives later removal or container packing.
 var before=g.breeding_state.forms.size()
 for p in g.planted:
  if GardenPlantBreeding.supported(int(p.id)) and float(p.age)>=float(g.catalogue[p.id].days)*.78:
   GardenPlantBreeding.snapshot(g,p)
 if g.breeding_state.forms.size()!=before:g.save_game()
 var result=[]
 for f in g.breeding_state.forms.values():
  if f.observed and not f.archived:result.append(f)
 result.sort_custom(func(a,b):return GardenPlantBreeding.title(g,a).naturalnocasecmp_to(GardenPlantBreeding.title(g,b))<0)
 return result

static func picker(g, column: Control, forms: Array, name: String) -> OptionButton:
 var choice=OptionButton.new();choice.name=name;choice.fit_to_longest_item=false;choice.clip_text=true
 choice.custom_minimum_size.y=48;choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for f in forms:choice.add_item(GardenPlantBreeding.title(g,f))
 if forms.is_empty():choice.add_item("Grow a supported plant until it flowers");choice.disabled=true
 column.add_child(choice)
 return choice

static func preview(g, column: Control, f: Dictionary, flowers: bool=true) -> void:
 var view=GardenCultivarPreview.new();view.name="CultivarPreview";view.setup(g,f,flowers);column.add_child(view)
 GardenWorkshop.note(g,column,GardenPlantBreeding.title(g,f),19)
 GardenWorkshop.note(g,column,GardenPlantBreeding.traits(f,flowers),14)
 GardenWorkshop.note(g,column,"%.2f m at maturity · generation %d"%[float(g.catalogue[int(f.species)].height)*GardenPlantBreeding.height_factor(f),int(f.generation)],14)

static func selected(g, forms: Array) -> int:
 for i in range(forms.size()):
  if forms[i].uid==g.breeding_selected:return i
 return 0

static func propagate(g, column: Control, bench: Dictionary) -> void:
 GardenWorkshop.note(g,column,"PRESERVE A FORM",17)
 var forms=observed_forms(g)
 var choice=picker(g,column,forms,"PropagationSource")
 if not forms.is_empty():
  choice.select(selected(g,forms));var f=forms[choice.selected]
  choice.item_selected.connect(func(index):g.breeding_selected=forms[index].uid;GardenWorkshop.open(g,g.workshop_uid))
  preview(g,column,f)
  GardenWorkshop.note(g,column,"Preserve this flowering form with one starter-mix portion. Its parent stays intact; the new plant establishes after two mornings.",14)
  var method=str(GardenPlantBreeding.PROFILES[int(f.species)][0])
  GardenWorkshop.note(g,column,"Method: "+method+". Foliage markings are preserved here; seed crosses mix inherited flower colours and habit.",14)
  var error=GardenPlantBreeding.job_error(g,bench)
  if not error.is_empty():GardenWorkshop.note(g,column,error,14)
  GardenWorkshop.action(g,column,"Prepare "+method.to_lower(),func():GardenPlantBreeding.propagate(g,bench,f.uid),error.is_empty())
 else:GardenWorkshop.note(g,column,"Your first supported plant will reveal a variation as it grows. The first collection supports eight orchids, seven wildflowers, eight cottage flowers and five bushes.",14)
 GardenWorkshop.note(g,column,"STARTER MIX",17)
 if not bench.is_empty():
  GardenWorkshop.note(g,column,"Four spare harvest items + six petals make four portions after one morning. Current neighbour requests are kept aside.",14)
  GardenWorkshop.action(g,column,"Prepare starter mix",func():GardenEquipment.start(g,bench),GardenEquipment.jobs(g,bench.uid).size()<(2 if bench.work.get("upgraded",false) else 1))
  GardenWorkshop.action(g,column,"Bench upgraded" if bench.work.get("upgraded",false) else "Upgrade bench · 40 petals",func():GardenEquipment.upgrade(g,bench),not bench.work.get("upgraded",false))
 GardenWorkshop.supplies(g,column)
 var names=[]
 for id in GardenPlantBreeding.PROFILES:names.append(g.catalogue[int(id)].name)
 GardenWorkshop.note(g,column,"SUPPORTED COLLECTION\n"+", ".join(names),13)

static func breed(g, column: Control, bench: Dictionary) -> void:
 GardenWorkshop.note(g,column,"GROW THE NEXT GENERATION",17)
 GardenWorkshop.note(g,column,"Choose two different flowering forms of the same species. One starter-mix portion and six petals prepare four seedlings after three mornings. Plant them and compare their flowers as they grow.",14)
 var forms=observed_forms(g)
 GardenWorkshop.note(g,column,"First parent",14)
 var first=picker(g,column,forms,"BreedingParentA")
 GardenWorkshop.note(g,column,"Second parent",14)
 var second=picker(g,column,forms,"BreedingParentB")
 if forms.size()>1:second.select(1)
 var hint=g.label("",14);hint.name="BreedingOutcome";hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(hint)
 var start=GardenWorkshop.action(g,column,"Start a four-seedling tray",func():GardenPlantBreeding.breed(g,bench,forms[first.selected].uid,forms[second.selected].uid),false)
 var update=func(_index=0):
  if forms.is_empty():hint.text="Grow two specimens from the supported collection first.";start.disabled=true;return
  var a=forms[first.selected];var b=forms[second.selected]
  var error=GardenPlantBreeding.job_error(g,bench,true)
  if a.uid==b.uid:error="Choose two different parent specimens or cultivars."
  elif a.species!=b.species:error="Different species: choose another form of "+g.catalogue[int(a.species)].name+"."
  hint.text=error if not error.is_empty() else "Compatible parents. Offspring inherit flower colours, markings and height traits from both parents. Foliage sports are kept through propagation, so these seedlings begin with green leaves."
  start.disabled=not error.is_empty()
 first.item_selected.connect(update);second.item_selected.connect(update);update.call()
 if not forms.is_empty():
  var info=g.label("",14);info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(info)
  var details=func(_index=0):info.text="Parent A: "+GardenPlantBreeding.traits(forms[first.selected])+"\nParent B: "+GardenPlantBreeding.traits(forms[second.selected])
  first.item_selected.connect(details);second.item_selected.connect(details);details.call()

static func nursery(g, column: Control) -> void:
 GardenWorkshop.note(g,column,"ESTABLISHING PLANTS",17)
 for job in g.breeding_state.jobs:
  GardenWorkshop.note(g,column,"%s · %d plant%s · ready morning %d"%["Seedling tray" if job.kind=="breed" else "Propagation",job.forms.size(),"s" if job.forms.size()>1 else "",int(job.ready_day)],14)
 if g.breeding_state.jobs.is_empty():GardenWorkshop.note(g,column,"No experiments are resting. Start one in Propagate or Breed.",14)
 GardenWorkshop.note(g,column,"READY IN THE NURSERY",17)
 var entries: Array=g.breeding_state.nursery
 if entries.is_empty():GardenWorkshop.note(g,column,"Established cuttings can be named and registered. Seedlings should be planted first; choose a favourite after it flowers, then propagate it.",14)
 for i in range(entries.size()):
  var index=i;var entry=entries[i];var f=GardenPlantBreeding.form(g,entry.form_uid)
  GardenWorkshop.note(g,column,GardenPlantBreeding.title(g,f)+( " · established" if entry.kind=="propagate" else " · seedling"),16)
  if i==0:preview(g,column,f,entry.kind=="propagate")
  if entry.kind=="propagate":
   var name=LineEdit.new();name.name="CultivarName%d"%i;name.placeholder_text="Name this cultivar…";name.max_length=40;name.custom_minimum_size.y=48;column.add_child(name)
   if f.registered:name.text=f.name
   GardenWorkshop.action(g,column,"Register this cultivar",func():
    if GardenPlantBreeding.register(g,index,name.text):g.breeding_selected=f.uid;g.breeding_tab="My cultivars")
  GardenWorkshop.action(g,column,"Plant this selection",func():GardenPlantBreeding.place_nursery(g,index))
 var growing=0
 for f in g.breeding_state.forms.values():
  if not f.observed:growing+=1
 GardenWorkshop.note(g,column,"%d selections still developing their flowers. Cancelled planting keeps seedlings in Equipment & stored plants."%growing,14)

static func library(g, column: Control) -> void:
 var named=[];var discoveries=0;var generations=0
 for f in g.breeding_state.forms.values():
  if f.registered:named.append(f);generations=maxi(generations,int(f.generation))
  elif f.observed:discoveries+=1
 GardenWorkshop.note(g,column,"%d named cultivars · %d generations · %d recorded selections"%[named.size(),generations,discoveries],16)
 var search=LineEdit.new();search.name="CultivarSearch";search.placeholder_text="Search name, species or traits…";search.text=g.breeding_query;search.custom_minimum_size.y=48;column.add_child(search)
 # Submit keeps the on-screen keyboard and focus stable while typing on touch.
 search.text_submitted.connect(func(value):g.breeding_query=value;g.breeding_page=0;GardenWorkshop.open(g,g.workshop_uid))
 GardenWorkshop.action(g,column,"Search cultivars",func():g.breeding_query=search.text;g.breeding_page=0)

 var results=named.filter(func(f):return (g.breeding_show_archived or not f.archived) and (g.breeding_query.strip_edges().is_empty() or (GardenPlantBreeding.title(g,f)+" "+GardenPlantBreeding.traits(f)).to_lower().contains(g.breeding_query.to_lower())))
 results.sort_custom(func(a,b):return GardenPlantBreeding.title(g,a).naturalnocasecmp_to(GardenPlantBreeding.title(g,b))<0)
 var choice=picker(g,column,results,"CultivarPicker")
 if results.is_empty():choice.set_item_text(0,"No matching cultivars")
 if not results.is_empty():
  choice.select(selected(g,results));g.breeding_selected=results[choice.selected].uid
  choice.item_selected.connect(func(index):g.breeding_selected=results[index].uid;GardenWorkshop.open(g,g.workshop_uid))
 var f=GardenPlantBreeding.form(g,g.breeding_selected) if not results.is_empty() else {}
 if not f.is_empty() and f.registered:
  preview(g,column,f)
  GardenWorkshop.note(g,column,"Discovered on morning %d. Copies preserve these traits, with natural differences in branch arrangement."%int(f.day),14)
  if not f.parents.is_empty():
   GardenWorkshop.note(g,column,"PARENTAGE",16)
   for parent in f.parents:GardenWorkshop.note(g,column, GardenPlantBreeding.title(g,GardenPlantBreeding.form(g,parent)),14)
  GardenWorkshop.action(g,column,"Plant this cultivar",func():GardenWorkshop.close(g);GardenPlantBreeding.choose(g,f.uid))
  GardenWorkshop.action(g,column,"Remove favourite" if f.favourite else "Save favourite",func():f.favourite=not f.favourite)
  GardenWorkshop.action(g,column,"Restore to collection" if f.archived else "Archive from collection",func():f.archived=not f.archived)
  var rename=LineEdit.new();rename.name="RenameCultivar";rename.text=f.name;rename.max_length=40;rename.custom_minimum_size.y=48;column.add_child(rename)
  GardenWorkshop.action(g,column,"Rename cultivar",func():GardenPlantBreeding.rename(g,f.uid,rename.text))
 elif results.is_empty():GardenWorkshop.note(g,column,"Your named plants will appear here. Visit Propagate to preserve a flowering discovery, then register the established plant in Nursery.",14)
 var archived=CheckButton.new();archived.text="Include archived cultivars";archived.custom_minimum_size.y=48;archived.button_pressed=g.breeding_show_archived;column.add_child(archived)
 archived.toggled.connect(func(value):g.breeding_show_archived=value;g.breeding_page=0;GardenWorkshop.open(g,g.workshop_uid))
 GardenWorkshop.action(g,column,"Browse recorded discoveries",func():g.breeding_tab="Propagate")
