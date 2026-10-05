"""Replace the bench with clearly separate seat, back, arms and bolted frames."""
import bpy, math, json, hashlib
import build_distinct_areas as b

def build():
 previous=bpy.context.window.scene;selected=list(bpy.context.selected_objects);active=bpy.context.view_layer.objects.active
 scene=b.hq.scene('Area_Furnishings');b.materials();G=b.Geometry();root=b.pivot('Refined garden bench',None,flat=True)
 wood=b.MATS['wood'];iron=b.MATS['iron']
 for x in [-.71,.71]:
  for z in [-.26,.26]:G.box(root,iron,(x,.27,z),(.055,.54,.055))
  G.box(root,iron,(x,.51,0),(.06,.055,.65))
  G.tube(root,iron,[(x,.42,.23),(x,.71,.29),(x,1.10,.40)],[.032,.029,.025],8)
  G.box(root,iron,(x,.66,-.18),(.045,.25,.045))
  G.box(root,wood,(x,.80,-.02),(.095,.055,.57))
 for j in range(5):G.box(root,wood,(0,.56,-.28+j*.14),(1.84,.065,.12))
 for j in range(3):G.box(root,wood,(0,.77+j*.13,.33+j*.039),(1.84,.105,.045))
 G.tube(root,iron,[(-.71,.20,0),(.71,.20,0)],[.025,.025],8)
 for x in [-.71,.71]:
  for j in range(3):G.ell(root,b.MATS['metal'],(x,.77+j*.13,.298+j*.039),(.018,.018,.008),sectors=10,rings=4)
 G.flush();record=b.hq.export(root,'shop','bench');path=b.hq.save('Area_Furnishings')
 choices_path=b.hq.SOURCE/'model_choices.json';choices=json.loads(choices_path.read_text())
 for asset in choices['models']:
  if asset['id']=='shop/bench':asset['new_sha256']=hashlib.sha256((b.ROOT/asset['asset']).read_bytes()).hexdigest()
 choices_path.write_text(json.dumps(choices,indent=2)+'\n')
 bpy.context.window.scene=previous
 bpy.ops.object.select_all(action='DESELECT')
 for node in selected:
  if node.name in previous.objects:node.select_set(True)
 if active and active.name in previous.objects:bpy.context.view_layer.objects.active=active
 return {'asset':record,'source':path}
