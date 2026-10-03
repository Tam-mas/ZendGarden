"""Permanent scenery upgrades; retain all landscape and saved-garden coordinates."""
import math
from common_hq import *
from structures import beam,hardware

def shed():
    m=palette();r=pivot('garden_shed')
    plaster=material('HQ limewashed garden plaster',(.62,.57,.45),'stone',.88)
    roof=material('HQ warm clay shingles',(.33,.16,.079),'clay',.82)
    box('Pavilion plaster walls',(0,1.5,0),(3.2,3,3),plaster,r,.035)
    box('Inset oak door',(0,1.18,-1.516),(1.08,2.36,.055),m['darkwood'],r,.012)
    for x in [-.57,.57]:box('Door stone jamb',(x,1.13,-1.555),(.13,2.25,.13),m['stone'],r)
    for j in range(11):
        a=(j+.5)*math.pi/11
        o=box('Arched stone voussoir',(.64*math.cos(a),2.25+.66*math.sin(a),-1.555),(.16,.21,.14),m['stone'],r)
        o.rotation_euler.y=math.pi/2-a
    for x in [-1.08,1.08]:
        box('Recessed window frame',(x,1.65,-1.53),(.58,1.3,.09),m['darkwood'],r)
        box('Old window glass',(x,1.65,-1.583),(.45,1.15,.02),m['glass'],r,.002)
        box('Vertical mullion',(x,1.65,-1.602),(.032,1.16,.029),m['wood'],r,.004)
        box('Horizontal mullion',(x,1.65,-1.603),(.46,.032,.029),m['wood'],r,.004)
        box('Stone window sill',(x,.97,-1.59),(.66,.07,.22),m['stone'],r)
    for j in range(3):box('Pavilion step',(0,.08+j*.08,-1.6-(2-j)*.3),(1.55,.16,.65),m['stone'],r,.025)
    for j in range(7):box('Door plank joint',(-.45+j*.15,1.18,-1.547),(.002,2.30,.002),m['black'],r,0)
    for y in [.40,1.95]:
        box('Forged door hinge',(-.32,y,-1.556),(.26,.045,.02),m['iron'],r,.005)
        for x in [-.42,-.30,-.20]:hardware(r,(x,y,-1.57),m['iron'],r=.008)
    ell('Door handle backplate',(.31,1.05,-1.558),(.06,.13,.014),m['iron'],r,24,16)
    curve('Door pull',[(.31,1.09,-1.578),(.34,1.035,-1.594),(.31,.995,-1.579)],[.010]*3,m['iron'],r,10)
    # Four curved hipped slopes, the same roof rise/footprint as the existing shed.
    for side in range(4):
        angle=side*math.pi/2
        for k in range(8):
            t=k/8;t2=(k+1)/8
            for j in range(13):
                u=-1.9+j*3.8/13
                def point(u,t):
                    w=1.9*(1-t)+.32*t
                    return (math.cos(angle)*u*w/1.9-math.sin(angle)*w,3+t*1.9+.18*math.sin(t*math.pi),math.sin(angle)*u*w/1.9+math.cos(angle)*w)
                verts=[point(u,t),point(u+3.8/13-.012,t),point(u+3.8/13-.012,t2),point(u,t2)]
                tile=mesh('Individual hipped shingle',verts,[(0,1,2,3)],roof,r,False)
                solid=tile.modifiers.new('Shingle thickness','SOLIDIFY');solid.thickness=.025
                bpy.context.view_layer.objects.active=tile;bpy.ops.object.modifier_apply(modifier=solid.name)
    box('Roof crown cap',(0,4.905,0),(.70,.065,.70),m['darkwood'],r,.015)
    return r

def footbridge():
    m=palette();r=pivot('footbridge')
    for j in range(14):
        x=-2.1+j*.32
        box('Straight bridge deck',(x,.08,0),(.29,.15,1.8),m['wood'],r,.007)
        for z in [-.72,.72]:ell('Countersunk deck pin',(x,.156,z),(.018,.003,.018),m['iron'],r,10,6)
    for z in [-.9,.9]:
        for x in [-2.1,0,2.1]:
            box('Bridge rail post',(x,.55,z),(.1,1.0,.1),m['wood'],r,.008)
            hardware(r,(x,.88,z-.055),m['iron'],r=.012)
        box('Single bridge top rail',(0,.96,z),(4.5,.1,.1),m['wood'],r,.01)
    for z in [-.67,.67]:box('Under-deck beam',(0,.03,z),(4.48,.10,.09),m['darkwood'],r,.006)
    return r

def cottage():
    m=palette();r=pivot('lakeside_cottage')
    plaster=material('HQ limewashed garden plaster',(.62,.57,.45),'stone',.88)
    roof=material('HQ warm clay shingles',(.33,.16,.079),'clay',.82)
    box('Cottage plaster body',(0,1.5,0),(3.2,3,3.6),plaster,r,.025)
    for z in [-1.8,1.8]:mesh('Cottage gable',[(-1.6,3,z),(1.6,3,z),(0,4.5,z)],[(0,2,1) if z<0 else (0,1,2)],plaster,r,False)
    for side in [-1,1]:
        mesh('Straight cottage roof',[(0,4.50,-2.0),(side*1.9,2.95,-2.0),(side*1.9,2.95,2.0),(0,4.50,2.0)],[(0,1,2,3) if side<0 else (3,2,1,0)],roof,r,False)
        for j in range(7):
            t=(j+.5)/7
            for k in range(11):
                p=(side*1.9*t,4.50-1.55*t+.012,-1.9+k*.38)
                tile=box('Cottage roof tile',p,(.34,.025,.36),roof,r,.002);tile.rotation_euler.y=side*.684
    box('Cottage oak door',(0,1.08,-1.82),(.86,2.16,.06),m['darkwood'],r)
    for x in [-1.02,1.02]:
        box('Cottage window frame',(x,1.62,-1.826),(.55,1.03,.08),m['wood'],r)
        box('Cottage old glass',(x,1.62,-1.871),(.44,.92,.009),m['glass'],r,.002)
    return r

def upgrade_environment():
    """Append a fresh copy of the existing library, never open/replace the UI file."""
    previous=bpy.context.window.scene
    with bpy.data.libraries.load(str(ROOT/'art_source/lake_garden.blend'),link=False) as (src,dst):dst.scenes=[src.scenes[0]]
    env=dst.scenes[0];env.name='ZendGarden_HQ_environment';SCENES['ZendGarden_HQ_environment']=env
    bpy.context.window.scene=env
    # Only geometry from this freshly appended copy is changed.
    old=[o for o in env.objects if o.name.split('.')[0] in ['GardenPavilion','PavilionShingleRoof','PavilionWindows']]
    for o in old:bpy.data.objects.remove(o,do_unlink=True)
    r=shed();r.location=vec((-7.4,0,-18));r.rotation_euler.z=math.pi
    # Keep the detailed roof as eight material batches, not hundreds of draws.
    base.merge_meshes(r)
    m=palette()
    for o in list(env.objects):
        if o.type!='MESH' or o.name.split('.')[0] not in ['LimestonePathsAndWalls','DistantLakesideHamlets']:continue
        name=o.name.split('.')[0];o.name=name
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        bevel=o.modifiers.new('Subtle scenery edge wear','BEVEL');bevel.width=.012 if name=='LimestonePathsAndWalls' else .035;bevel.segments=2
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        if name=='LimestonePathsAndWalls':
            o.data.materials.clear();o.data.materials.append(m['stone'])
            for p in o.data.polygons:p.material_index=0
        else:
            o.data.materials[0]=material('HQ limewashed garden plaster',(.62,.57,.45),'stone',.88)
            o.data.materials[1]=material('HQ warm clay shingles',(.33,.16,.079),'clay',.82)
        if not o.data.uv_layers:
            bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.002);bpy.ops.object.mode_set(mode='OBJECT')
        uv_mineral(o)
    for o in list(r.children_recursive):
        if o.type=='MESH' and o.data.materials:
            if any('wood' in m.name.lower() or 'cedar' in m.name.lower() or 'oak' in m.name.lower() for m in o.data.materials):uv_grain(o)
            uv_mineral(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in env.objects:o.select_set(True)
    path=ROOT/'assets/environment/lake_garden.glb'
    # Preserve semantic terrain/chunk names and all original landscape geometry.
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,
        export_apply=True,export_animations=False,export_image_format='JPEG',export_image_quality=92)
    from glb_io import canonical_environment_names
    canonical_environment_names(path)
    save('environment')
    bpy.context.window.scene=previous
    return {'kind':'lake_garden','folder':'environment','bytes':path.stat().st_size,'source':'art_source/overhaul/environment.blend','terrain':'unchanged'}

def build(kind):
    if kind=='environment':return upgrade_environment()
    scene('scenery');replace_authored('scenery','scenery',kind)
    r={'garden_shed':shed,'footbridge':footbridge,'lakeside_cottage':cottage}[kind]()
    record=export(r,'scenery',kind)
    i=['garden_shed','footbridge','lakeside_cottage'].index(kind);r.location=vec((i*6,0,0));r.hide_set(False)
    save('scenery');return record
