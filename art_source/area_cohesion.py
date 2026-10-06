"""Shared material scale, planted ecotones and connected garden entrances.

Adds a third, reproducible construction pass without changing user scenes or
collection pocket identities. Existing detailed botanical assets supply plants.
"""
import bpy, math, random
from mathutils import Vector
import garden_routes

garden_routes.write()

PALETTES = [
    [147,146,140], [136,145,137], [142,139,144], [140,141,139],
    [140,141,136], [141,140,142], [136,145,141], [146,147,140],
    [143,142,144], [146,137,136],
]

def approach(index,t):
    return garden_routes.point(index,t)

def on_route(index,x,z,margin=.98):
    if abs(x-(12 if index%2==0 else -12))<1.02:return True
    points=garden_routes.ROUTES['approaches'][index]
    if index==0:points=points+[[a-56,b] for a,b in garden_routes.ROUTES['eastern_link']]
    for a,b in points:
        if math.hypot(x-a,z-b)<margin:return True
    return False

def family(name):
    name=name.lower()
    if 'bark' in name or 'endgrain' in name:return 'bark'
    if 'cedar' in name or 'oak' in name:return 'timber'
    if 'terracotta' in name:return 'clay'
    if 'iron' in name or 'zinc' in name or 'bronze' in name:return 'metal'
    if 'glass' in name:return 'glass'
    if 'paving' in name or 'brick' in name:return 'brick'
    if 'litter' in name:return 'leaf_litter'
    if 'loam' in name or 'soil' in name:return 'soil'
    if 'grass' in name or 'moss' in name and 'mossrock' not in name:return 'ground'
    return 'stone'

def install(b):
    previous_rock=b.rock
    def rock(G,parent,index,x,z,size,seed=0,moss=True):
        if on_route(index,x,z,.98+max(size[0],size[2])*.55):return
        return previous_rock(G,parent,index,x,z,size,seed,moss)
    b.rock=rock
    previous_materials=b.materials
    def materials():
        previous_materials()
        if b.MATS.get('cohesion'):return b.MATS
        for key,original in list(b.MATS.items()):
            if not isinstance(original,bpy.types.Material):continue
            material=original.copy();material.name=original.name+' garden standard'
            kind=family(original.name);material['garden_surface']=kind
            material['metres_per_repeat']={'timber':1.,'stone':1.15,'brick':1.35,'clay':.85}.get(kind,.8)
            bs=material.node_tree.nodes.get('Principled BSDF')
            bs.inputs['Specular IOR Level'].default_value=.26 if kind in ['timber','stone','clay','brick'] else .38
            if kind=='glass':bs.inputs['Roughness'].default_value=.16
            b.MATS[key]=material
        import botanical_detail as bd, botanical_geometry as bg
        litter=bpy.data.materials.get('Garden dry fallen leaf')
        if not litter or litter.get('garden_surface')!='leaf_litter':
            litter=bg.material('Garden dry fallen leaf','92724c')
            bd.texture_material(litter,'leaf',bd.surfaces(b.ROOT))
        litter['garden_surface']='leaf_litter';b.MATS['litter']=litter
        b.MATS['cohesion']=True
        return b.MATS
    b.materials=materials

    old_flush=b.Geometry.flush
    def flush(self):
        before=set(bpy.context.scene.objects)
        old_flush(self)
        for node in set(bpy.context.scene.objects)-before:
            if node.type!='MESH':continue
            material=node.data.materials[0];kind=material.get('garden_surface',family(material.name))
            uv=node.data.uv_layers.active
            for face in node.data.polygons:
                if kind=='bark':continue
                if kind=='leaf_litter':
                    coords=[(.5,0),(0,.3),(0,.73),(.5,1),(1,.73),(1,.3),(.5,.48)]
                    for li in face.loop_indices:uv.data[li].uv=coords[node.data.loops[li].vertex_index%7]
                    continue
                if kind=='timber':
                    ids=list(face.vertices)
                    edges=[node.data.vertices[ids[(j+1)%len(ids)]].co-node.data.vertices[ids[j]].co for j in range(len(ids))]
                    along=max(edges,key=lambda edge:edge.length).normalized()
                    across=face.normal.cross(along).normalized()
                    for li in face.loop_indices:
                        p=node.data.vertices[node.data.loops[li].vertex_index].co
                        uv.data[li].uv=(p.dot(across),p.dot(along))
                elif kind in ['stone','brick','clay']:
                    scale=material.get('metres_per_repeat',1.)
                    major=max(range(3),key=lambda k:abs(face.normal[k]));axes=[k for k in range(3) if k!=major]
                    for li in face.loop_indices:
                        p=node.data.vertices[node.data.loops[li].vertex_index].co
                        uv.data[li].uv=(p[axes[0]]/scale,p[axes[1]]/scale)
            if node.parent and node.parent.get('ground_detail'):
                node['ground_detail']=True
    b.Geometry.flush=flush

    def borders(G,root,index):
        # Preserve functional geometry, but replace evenly spaced border rows.
        rng=random.Random(8823+index);occupied=[]
        for ob in root.children_recursive:
            if ob.get('footprint'):occupied.append(tuple(ob['footprint']))
        slots=b.layout()[index]['slots']
        for ob in list(root.children_recursive):
            if ob.get('area_species') is not None and ob.type=='EMPTY':
                x,y,z=ob.location
                if on_route(index,x,-y):bpy.data.objects.remove(ob,do_unlink=True)
        detail=b.pivot('Ground details',root,ground_detail=True)
        def clear(x,z,r=.16):
            if max(abs(x),abs(z))>11.25 or on_route(index,x,z):return False
            if any(((x-a)/(rx+r))**2+((z-c)/(rz+r))**2<1 for a,c,rx,rz in occupied):return False
            if any(math.hypot(x-s['pos'][0],z-s['pos'][1])<.7 for s in slots):return False
            if index in [1,7]:
                creek=1*math.sin(z*.42)+.30*math.sin(z*.83) if index==1 else 1.5*math.sin(z*.4)
                if abs(x-creek)<(1.15 if index==1 else 1.6):return False
                if index==1 and abs(x-creek-1.55)<.8:return False
            if index==3 and abs(x-3*math.sin(z*.4))<1.2:return False
            if index==8 and abs(x-2.4*math.sin(z*.45))<1.0:return False
            if index==4 and (abs(abs(x)-8)<.25 or abs(z+8)<.25):return False
            if index==5 and (abs(abs(x)-7.4)<.45 or abs(z+6.7)<.45):return False
            return True
        for group in range(18):
            side=group%4;t=rng.uniform(-9.7,9.7);edge=rng.uniform(8.45,10.45)
            x,z=[(-edge,t),(edge,t),(t,-edge),(t,edge)][side]
            if not clear(x,z,.38):continue
            cluster=b.pivot('Ecotone cluster',root)
            for member in range(rng.randrange(3,7)):
                a=rng.random()*math.tau;r=.70*math.sqrt(rng.random())
                xx=x+math.cos(a)*r;zz=z+math.sin(a)*r
                if not clear(xx,zz):continue
                species=PALETTES[index][(group+member//3)%3]
                ob=b.pivot('BotanicalAnchor',cluster,b.at(index,xx,zz),area_species='',area_plant_id=species,terrain_anchor=True,ecotone=True)
                size=rng.uniform(.66,1.12);ob.scale=(size,size,size);ob.rotation_euler.z=rng.random()*math.tau
                if index==1 and member==0:
                    ob['area_species']='maidenhair';ob['area_plant_id']=-1;ob.scale=(.45,.45,.45)
            # Small repeated organs are geometry, never transparent scatter cards.
            for k in range(8 if index in [1,4,9] else 3):
                dx=rng.uniform(-.58,.58);dz=rng.uniform(-.58,.58)
                if not clear(x+dx,z+dz,.03):continue
                angle=rng.random()*math.tau;length=rng.uniform(.05,.11)
                y=b.height(index,x+dx,z+dz)+.041
                G.leaf(detail,b.MATS['litter'],(x+dx,y,z+dz),(x+dx+math.cos(angle)*length,y+.006,z+dz+math.sin(angle)*length),length*.30,bend=.009)
            for k in range(3 if index in [2,8] else 1):
                dx=rng.uniform(-.5,.5);dz=rng.uniform(-.5,.5)
                if not clear(x+dx,z+dz,.06):continue
                y=b.height(index,x+dx,z+dz)+.043
                G.ell(detail,b.MATS['stone'],(x+dx,y,z+dz),(.07,.035,.055),group*5+k,sectors=8,rings=4,rough=.20)
            if index in [1,4]:
                points=[b.at(index,x+dx,z+dz,-.024) for dx,dz in [(-.22,.20),(-.04,.17),(.11,.21)]]
                G.tube(detail,b.MATS['darkwood'],points,[.010,.007,.004],5)
        # A shared family of fitted entrance stones joins the central trail.
        path=b.pivot('Arrival path',root,ground=True,flat=True,arrival_path=True)
        samples=garden_routes.ROUTES['approaches'][index]
        length=sum(math.dist(a,b) for a,b in zip(samples,samples[1:]))
        segments=max(22,math.ceil(length/.58))
        grid=b.layout()[index]['heightmap']
        def paving_height(x,z):
            # Match the game's metre-grid interpolation at shared junctions,
            # rather than crossing its blue stones with an analytic surface.
            xx=max(0,min(24,x+12));zz=max(0,min(24,z+12))
            ix=min(23,int(xx));iz=min(23,int(zz));tx=xx-ix;tz=zz-iz
            a=grid[iz][ix]*(1-tx)+grid[iz][ix+1]*tx
            c=grid[iz+1][ix]*(1-tx)+grid[iz+1][ix+1]*tx
            return a*(1-tz)+c*tz
        def path_normal(t):
            d=(Vector(approach(index,min(1,t+.001)))-Vector(approach(index,max(0,t-.001)))).normalized()
            return Vector((-d.y,d.x))
        for k in range(segments):
            t0=(k+.018)/segments;t1=(k+.982)/segments
            a=Vector(approach(index,t0));c=Vector(approach(index,t1))
            first_normal=path_normal(t0);last_normal=path_normal(t1)
            for lane in range(3):
                lo=(lane/3-.5)*1.8+.012;hi=((lane+1)/3-.5)*1.8-.012
                points=[a+first_normal*lo,c+last_normal*lo,c+last_normal*hi,a+first_normal*hi]
                heights=[]
                for p,t in zip(points,[t0,t1,t1,t0]):
                    lift=.035+.020*b.smooth(0,.15,t)
                    if index==0:lift+=.185*b.smooth(.65,1,t)
                    if index==7:
                        end=approach(index,1)
                        deck=1.40+.2*(1-(end[0]/3.6)**2)
                        lift+=(deck-paving_height(*end)-.07-.055)*b.smooth(.65,1,t)
                    heights.append((p.x,paving_height(p.x,p.y)+.07+lift,p.y))
                G.poly(path,b.MATS['stone'],heights,[(0,3,2,1)])
        root['cohesion_version']=2
    b.borders=borders

    old_layout=b.layout
    def layout():
        areas=old_layout()
        for i,area in enumerate(areas):
            area['arrival']=list(approach(i,.34 if i in [5,6] else .58))
        import json
        path=b.ROOT/'assets/areas/layout.json'
        path.write_text(json.dumps({'version':1,'areas':areas,'specialties':b.SPECIALTIES},indent=2)+'\n')
        return areas
    b.layout=layout
