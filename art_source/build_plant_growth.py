"""Supplementary botanical stages; never modifies the mature source libraries.
Run in a separate, approved background Blender process. Metres, Z-up.
"""
import bpy, sys, json, math, random
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from botanical_geometry import Geometry, material
from botanical_detail import detail_geometry
from botanical_forms import compound, palmate, round_leaf
Detailed=detail_geometry(Geometry)
scene=bpy.data.scenes.new('ZendGarden_PlantGrowth')
bpy.context.window.scene=scene
# Read existing authored organs and pigments without opening or saving their files.
sources={}
for filename in ['botanical_library.blend','botanical_expansion.blend']:
    with bpy.data.libraries.load(str(ROOT/'art_source'/filename),link=False) as (src,dst):
        dst.objects=[n for n in src.objects if n.startswith('Plant_') or n.startswith('Foliage') or n.startswith('Bloom')]
    for obj in dst.objects:
        if obj and obj.name.startswith('Plant_'):
            sources[int(obj.name.split('_')[1])]=obj
folder=ROOT/'assets/plants/growth';folder.mkdir(parents=True,exist_ok=True)
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
report=[]

def family(name,category,layer):
    if 'bamboo' in name.lower(): return 'bamboo'
    if 'redwood' in name.lower(): return 'conifer'
    if name in ['Blue fescue','Feather grass','Sedge','Fountain grass','Lomandra','Iris','Leek','Corn','Gymea lily','Kangaroo paw']:return 'strap'
    if name in ['Moss carpet','Creeping thyme','Dichondra']:return 'mat'
    if name in ['Ginkgo','Japanese maple','Fig','Rhubarb','Pumpkin','Melon','Nasturtium']:return 'broad'
    if name in ['Tomato','Rose','Pea','Carrot','Hemp'] or name.startswith('Rose '):return 'compound'
    if name in ['Lettuce','Broccoli','Cauliflower','Globe artichoke','Radish','Beetroot']:return 'rosette'
    if layer==3:return 'sapling'
    return 'herb'

def leaf(g,p,a,length,kind,young=False):
    p=Vector(p);tip=p+Vector((math.cos(a)*length,math.sin(a)*length,length*.17))
    if kind=='compound': compound(g,p,tip,2 if young else 1)
    elif kind=='broad':
        if g.species in ['Ginkgo','Japanese maple','Fig']:palmate(g,p,length,a,2 if young else 1,5 if g.species!='Ginkgo' else 3)
        else:round_leaf(g,p+Vector((math.cos(a),math.sin(a),.2))*length*.6,length*.45,2 if young else 1)
    elif kind=='conifer':
        for j in range(7):
            q=p.lerp(tip,j/7)
            for s in [-1,1]: g.leaf(q,q+Vector((math.cos(a+s),math.sin(a+s),.1))*length*.25,.008,2 if young else 1,.1,3)
    else:g.leaf(p,tip,length*(.08 if kind in ['bamboo','strap'] else .26),2 if young else 1,.18,6)

def immature(name,kind,height,juvenile):
    g=Detailed(name,'foliage')
    h=min(1.5,max(.18,height*.48)) if juvenile else min(.28,max(.13,height*.13))
    if kind in ['strap','mat','rosette']:
        count=9 if juvenile else 3
        for j in range(count):
            a=j*2.39996;length=h*random.uniform(.65,1.05)
            base=Vector((math.cos(a)*.025,math.sin(a)*.025,.005))
            if kind=='strap':g.leaf(base,base+Vector((math.cos(a)*h*.3,math.sin(a)*h*.3,length)),h*.055,1,.35,8)
            elif kind=='mat':leaf(g,base,a,h*.8,'herb',j%2==0)
            else:g.leaf(base,base+Vector((math.cos(a)*length*.8,math.sin(a)*length*.8,length*.5)),length*.32,1,.3,8,True)
    else:
        woody=kind in ['sapling','conifer','bamboo']
        count=3 if juvenile and woody and kind!='conifer' else 1
        for k in range(count):
            a=k*2.39996;offset=Vector((math.cos(a)*h*.12,math.sin(a)*h*.12,0)) if count>1 else Vector()
            end=offset+Vector((h*.04*math.sin(a+1),h*.025*math.cos(a),h))
            g.tube([offset,offset.lerp(end,.45),end],[h*(.023 if woody else .018),h*.012,h*.004],0,8)
            levels=5 if juvenile else 2
            for j in range(levels):
                p=offset.lerp(end,.28+j*(.60/max(1,levels-1)));turn=j*2.39996+k
                ll=h*(.40 if juvenile else .38)*(1-j*.075)
                if juvenile and woody and kind!='bamboo':
                    branch=p+Vector((math.cos(turn)*ll*.7,math.sin(turn)*ll*.7,h*.09))
                    g.tube([p,branch],[h*.009,h*.003],0,6)
                    for n in range(3):leaf(g,p.lerp(branch,.45+n*.25),turn+n*.8,ll*.65,kind,n==2)
                else:
                    for side in [0,math.pi]:leaf(g,p,turn+side,ll,kind,j==levels-1)
    return g

def centers(mesh,height):
    # Connected organs are combined spatially into compact unopened flower/fruit clusters.
    parent=list(range(len(mesh.vertices)))
    def find(i):
        while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
        return i
    for edge in mesh.edges:
        a,b=map(find,edge.vertices)
        if a!=b:parent[b]=a
    groups={}
    for v in mesh.vertices:groups.setdefault(find(v.index),[]).append(v.co)
    cells={};spacing=max(.055,min(.23,height*.07))
    for points in groups.values():
        if len(points)<3:continue
        c=sum(points,Vector())/len(points)
        key=tuple(round(x/spacing) for x in c)
        cells.setdefault(key,[]).append(c)
    values=[sum(v,Vector())/len(v) for v in cells.values()]
    values.sort(key=lambda v:(v.z,v.x,v.y))
    if len(values)>40:values=[values[int(i*len(values)/40)] for i in range(40)]
    return values

for idx,row in enumerate(specs):
    name,category,color,layer,*_=row;random.seed(idx*7919+181)
    src=sources[idx]
    foliage=next(o for o in src.children if o.name.startswith('Foliage'))
    flowers=next(o for o in src.children if o.name.startswith('Bloom'))
    height=max(v.co.z for v in foliage.data.vertices)
    kind=family(name,category,layer)
    # Reuse packed source PBR maps, retaining species' foliage identity.
    leafm=next(m for m in foliage.data.materials if m and m.name.startswith('Leaf'))
    young=next((m for m in foliage.data.materials if m and ('young' in m.name.lower() or 'new leaves' in m.name.lower())),leafm)
    palette=[foliage.data.materials[0],leafm,young]
    root=bpy.data.objects.new(f'Growth_{idx:02d}_{name}',None);scene.collection.objects.link(root)
    root['catalogue_id']=idx;root['family']=kind
    organs=[]
    for label,juvenile in [('Seedling',False),('Juvenile',True)]:
        geometry=immature(name,kind,height,juvenile)
        obj=geometry.object(label,palette);obj.parent=root;organs.append(obj)
    buds=Geometry()
    points=centers(flowers.data,height)
    if not points:
        # Non-flowering carpets and leafy crops develop new growing tips instead.
        tips=sorted((v.co.copy() for v in foliage.data.vertices),key=lambda v:v.z,reverse=True)
        points=[tips[int(i*min(len(tips)-1,80)/4)] for i in range(4)]
    for c in points:
        r=max(.016,min(.065,height*.023))
        # Closed sepals surround the coloured tip; fruit starts small and green.
        buds.ellipsoid(c,(r*.68,r*.68,r),0,5,8)
        for j in range(4):
            a=j*math.pi/2
            base=c+Vector((0,0,-r*.8))
            buds.leaf(base,c+Vector((math.cos(a)*r*.65,math.sin(a)*r*.65,r*.45)),r*.22,1,.1,4)
    obj=buds.object('Buds',[leafm if category=='Produce' or layer==3 else flowers.data.materials[0],leafm,young]);obj.parent=root;organs.append(obj)
    bpy.ops.object.select_all(action='DESELECT')
    for o in [root,*organs]:o.select_set(True)
    bpy.context.view_layer.objects.active=organs[0]
    bpy.ops.export_scene.gltf(filepath=str(folder/f'growth_{idx:02d}.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
    tris=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in organs)
    assert 0<tris<18000,(name,tris)
    report.append({'id':idx,'name':name,'family':kind,'height':round(height,4),'triangles':tris})
    root.location=(idx%10*3,idx//10*5,0)
    print('GROWTH_PLANT',idx,name,tris,flush=True)
# Remove unlinked source objects only in this isolated process, keep the packed pigments.
for o in list(bpy.data.objects):
    if not o.users_collection:bpy.data.objects.remove(o)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art_source/plant_growth.blend'))
(ROOT/'art_source/plant_growth_manifest.json').write_text(json.dumps(report,indent=2)+'\n')
(ROOT/'scripts/plant_profiles.gd').write_text('class_name GardenPlantProfiles\nextends RefCounted\n\n# Generated from the authored mature foliage, in garden metres.\nconst HEIGHTS='+json.dumps([r['height'] for r in report])+'\n')
print('PLANT_GROWTH_EXPORT: PASS',len(report),sum(r['triangles'] for r in report),flush=True)
