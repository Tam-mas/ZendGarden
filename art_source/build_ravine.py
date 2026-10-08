"""Author three stone arch bridges and a planted alpine stream in a separate scene.

The packed library retains the arches, individually coursed masonry, granite
outcrops and botanical anchors. Shared profile data supplies matching game ground.
"""
import bpy, sys, math, random, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
import build_distinct_areas as b
import ravine_profile as r

CASCADE_Z=(-83.,-57.,-28.,-4.)

def ledge(G,parent,p,size,seed,mat=None,angle=.18):
    """Weathered, bedded stone: a broad shoulder with a broken, bevelled rim.

    The river uses the same granite as the garden walls, but horizontal fracture
    planes distinguish it from the rounded garden boulders. Low-poly stones are
    batched per reach rather than becoming hundreds of individual draw calls.
    """
    rng=random.Random(seed);vs=[];n=9
    radius=[rng.uniform(.88,1.08) for _ in range(n)]
    for ring,(scale,y) in enumerate([(.83,-.48),(1.,-.12),(.91,.25),(.62,.43)]):
        for j in range(n):
            a=math.tau*j/n;xx=math.cos(a)*size[0]*.5*radius[j]*scale;zz=math.sin(a)*size[2]*.5*radius[j]*scale
            x=p[0]+xx*math.cos(angle)-zz*math.sin(angle);z=p[2]+xx*math.sin(angle)+zz*math.cos(angle)
            bottom=p[1]+size[1]*(y+rng.uniform(-.045,.045))
            # Keep the weathered shoulder horizontal, but extend its buried
            # footing into the sampled slope at every lower-ring vertex.
            # Burying only the centre leaves the downhill edge hovering.
            if ring==0:bottom=min(bottom,r.ground(x,z)-.14)
            vs.append((x,bottom,z))
    faces=[tuple(range(n)),tuple(range(4*n-1,3*n-1,-1))]
    for ring in range(3):
        for j in range(n):faces.append((ring*n+j,(ring+1)*n+j,(ring+1)*n+(j+1)%n,ring*n+(j+1)%n))
    G.poly(parent,mat or b.MATS['granite'],vs,faces)

def botanical(parent,x,z,species='',plant_id=-1,scale=1.,angle=0.):
    plant=b.pivot('RavineBotanical',parent,(x,r.ground(x,z)-.025,z),area_species=species,area_plant_id=plant_id)
    plant.scale=(scale,scale,scale);plant.rotation_euler.z=angle
    return plant

def outlet_boulder(G,parent,p,size,seed):
    """Retain rounded outlet shoulders while seating their underside in rock."""
    stone=b.Geometry()
    stone.ell(parent,b.MATS['granite'],p,size,seed=seed,rough=.3)
    for (owner,material),(vertices,faces) in stone.groups.items():
        grounded=[(x,min(y,r.ground(x,z)-.14) if y<=p[1]+.00001 else y,z) for x,y,z in vertices]
        G.poly(owner,material,grounded,faces)

def wedge(G,parent,mat,x0,x1,low0,low1,high0,high1,z0,z1):
    v=[(x0,low0,z0),(x1,low1,z0),(x1,low1,z1),(x0,low0,z1),(x0,high0,z0),(x1,high1,z0),(x1,high1,z1),(x0,high0,z1)]
    G.poly(parent,mat,v,[(0,1,2,3),(7,6,5,4),(4,5,1,0),(5,6,2,1),(6,7,3,2),(7,4,0,3)])

def bridge(G,root,z,index):
    parent=b.pivot('StoneBridge%d'%index,root,collision=True,flat=True)
    def lower(x):
        t=max(0,min(1,(x-27.5)/14.5))
        return r.deck(x,z)-.63-3.25*(1-math.sin(math.pi*t))
    # Continuous structural arch barrel; split wedge blocks reveal real joints.
    n=38
    for j in range(n):
        x0=27.5+14.5*j/n+.007;x1=27.5+14.5*(j+1)/n-.007
        for side in [-1,1]:
            z0=z+side*1.42-.24;z1=z+side*1.42+.24
            wedge(G,parent,b.MATS['stone'],x0,x1,lower(x0),lower(x1),lower(x0)+.40,lower(x1)+.40,z0,z1)
        wedge(G,parent,b.MATS['mossrock'],x0,x1,lower(x0)+.05,lower(x1)+.05,lower(x0)+.39,lower(x1)+.39,z-1.18,z+1.18)
    # Recessed mortar core closes the clipped edges of each arch course.
    for j in range(58):
        x0=27.5+j*.25;x1=x0+.25
        for side in [-1,1]:
            wedge(G,parent,b.MATS['joint'],x0,x1,lower(x0)+.36,lower(x1)+.36,r.deck(x0,z)-.1,r.deck(x1,z)-.1,z+side*1.42-.145,z+side*1.42+.145)
    # Staggered spandrel courses infill the masonry above the arch extrados.
    for side in [-1,1]:
        for course in range(16):
            y=-2.8+course*.30
            for col in range(24):
                x0=27.5+col*.65-(.325 if course%2 else 0);x1=min(42.,x0+.635);x0=max(27.5,x0)
                if x1<=x0:continue
                lo0=max(y,lower(x0)+.4);lo1=max(y,lower(x1)+.4)
                hi0=min(y+.285,r.deck(x0,z)-.13);hi1=min(y+.285,r.deck(x1,z)-.13)
                # Clip each course against the arch; retain triangular corner
                # stones rather than leaving entire half-blocks as bare mortar.
                import garden_paving
                profile=garden_paving.intersection([(x0,y),(x1,y),(x1,y+.285),(x0,y+.285)],[(x0,lower(x0)+.4),(x1,lower(x1)+.4),(x1,r.deck(x1,z)-.13),(x0,r.deck(x0,z)-.13)])
                if not profile:continue
                n=len(profile);zs=[z+side*1.42-.18,z+side*1.42+.18]
                vs=[(x,h,zz) for zz in zs for x,h in profile]
                faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]
                faces.extend((j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n))
                G.poly(parent,b.MATS['stone'],vs,faces)
    # Foundations, open landings, segmented low parapets and wide coping stones.
    for x in [27.65,41.85]:
        y=r.ground(x,z)
        G.box(parent,b.MATS['mossrock'],(x,(y-1+r.deck(x,z)-.18)*.5,z),(1.35,r.deck(x,z)-.18-y+1,3.5))
    for side in [-1,1]:
        for course in range(3):
            for j in range(21):
                x0=28.2+j*.66-(.33 if course%2 else 0);x1=min(41.8,x0+.647);x0=max(28.2,x0)
                if x1<=x0:continue
                wedge(G,parent,b.MATS['stone'],x0,x1,r.deck(x0,z)+course*.27,r.deck(x1,z)+course*.27,r.deck(x0,z)+course*.27+.255,r.deck(x1,z)+course*.27+.255,z+side*1.61-.19,z+side*1.61+.19)
        for j in range(22):
            x0=28.15+j*13.7/22;x1=x0+13.7/22-.009
            wedge(G,parent,b.MATS['stone'],x0,x1,r.deck(x0,z)+.81,r.deck(x1,z)+.81,r.deck(x0,z)+.95,r.deck(x1,z)+.95,z+side*1.61-.25,z+side*1.61+.25)
        # Capped end piers finish each rail without closing the clear landing.
        # Their inner edge remains outside the 2.44 m protected walking lane.
        for x in [28.42,41.58]:
            for course in range(4):
                y=r.deck(x,z)+course*.245
                G.box(parent,b.MATS['stone'],(x,y+.117,z+side*1.64),(.49,.234,.49))
            G.box(parent,b.MATS['stone'],(x,r.deck(x,z)+1.035,z+side*1.64),(.60,.13,.60))
    for j in range(74):
        x0=25.5+j*.25;x1=x0+.25
        lows=[]
        for xx in [x0,x1]:
            low=r.deck(xx,z)-.20
            if xx<28.2 or xx>41.8:low=min(low,min(r.ground(xx,z+dz) for dz in [-1.82,0,1.82])-.12)
            lows.append(low)
        wedge(G,parent,b.MATS['mossrock'],x0,x1,*lows,r.deck(x0,z)-.025,r.deck(x1,z)-.025,z-1.82,z+1.82)

def _build():
    old=bpy.context.window.scene;b.materials();b.MATS['granite']=b.MATS['stone'].copy();b.MATS['granite'].name='Ravine alpine granite';scene=b.hq.scene('AlpineRavine')
    for generated in [o for o in scene.objects if o.parent is None and o.name.split('.')[0]=='AlpineRavine']:
        for child in list(generated.children_recursive)+[generated]:bpy.data.objects.remove(child,do_unlink=True)
    root=b.pivot('AlpineRavine',None);G=b.Geometry();rng=random.Random(41892)
    for i,z in enumerate(r.BRIDGES):bridge(G,root,z,i)
    occupied=[]
    for cell in range(10):
        chunk=b.pivot('RavineReach%d'%cell,root)
        rocks=b.pivot('Boulder granite reach%d'%cell,chunk,flat=True)
        for side in [-1,1]:
            # Two related outcrops per bank leave restful open water between.
            # Satellite stones follow the current and share the host's bedding.
            for group in range(2):
                z=-106.6+cell*12+group*5.9+rng.uniform(-.65,.65)
                x=r.center(z)+side*rng.uniform(r.width(z)+.1,4.35)
                for j in range(3):
                    xx=x+side*j*.35;zz=z+j*.72+rng.uniform(-.22,.22)
                    size=(rng.uniform(1.45,2.1)*(1-j*.20),rng.uniform(.65,1.25)*(1-j*.17),rng.uniform(1.9,2.9)*(1-j*.21))
                    if xx-size[0]*.6<28.95 or xx+size[0]*.6>40.95:continue
                    if any(abs(zz-k)<2.4 for k in r.BRIDGES):continue
                    p=(xx,r.ground(xx,zz)-size[1]*.10,zz)
                    occupied.append((xx,zz,size[0]*.6,size[2]*.6))
                    ledge(G,rocks,p,size,cell*200+side*40+group*10+j,angle=.18+side*.14)
        # Shingle fans collect on alternating inside bends; no pebble necklace.
        side=-1 if cell%2 else 1;fan_z=-103.+cell*12.
        for j in range(32):
            z=fan_z+rng.uniform(-2.,2.5);x=r.center(z)+side*rng.uniform(r.width(z)*.82,r.width(z)+.55)
            size=rng.uniform(.12,.34)
            G.ell(chunk,b.MATS['granite'],(x,r.ground(x,z)+size*.10,z),(size,size*.45,size*1.4),seed=cell*50+j,sectors=9,rings=4,rough=.25)
        # Repeated grass/sedge drifts tie the stream to the garden, with ferns
        # tucked into the shaded toes and fewer, lower plants near the source.
        for group in range(16):
            z=-107.3+cell*12+rng.uniform(0,10.5);side=-1 if group%2 else 1
            x=r.center(z)+side*rng.uniform(r.width(z)+.5,5.0)
            if x<29.25 or x>40.65 or any(abs(z-k)<2.5 for k in r.BRIDGES):continue
            species='maidenhair' if group%4==0 and cell>2 else ''
            plant_id=-1 if species else ([143,144,136,143][group%4] if cell<3 else [136,145,146,140][group%4])
            for j in range(4):
                xx=x+rng.uniform(-.28,.28);zz=z+(j-1.5)*.43+rng.uniform(-.12,.12)
                if not 29.05<xx<40.8 or any(abs(zz-k)<2.3 for k in r.BRIDGES):continue
                if any(((xx-a)/w)**2+((zz-c)/d)**2<1.1 for a,c,w,d in occupied):continue
                botanical(chunk,xx,zz,species,plant_id,rng.uniform(.63,.98),rng.random()*math.tau)
        # Occasional hawthorn gives a soft middle layer; open bridge viewpoints
        # frame the water and still let the original garden remain in view.
        if cell%2:
            z=-102.5+cell*12;x=30.0 if cell%4==1 else 40.0
            if not any(abs(z-k)<4. for k in r.BRIDGES) and not any(((x-a)/w)**2+((z-c)/d)**2<1.3 for a,c,w,d in occupied):
                botanical(chunk,x,z,'hawthorn',scale=.58,angle=cell*2.3)
    # Four rock-framed drops explain the moving whitewater. Asymmetric ledges
    # narrow the flow visually while retaining a continuous central channel.
    for index,z in enumerate(CASCADE_Z):
        shelves=b.pivot('Cascade granite shelves%d'%index,root,flat=True)
        for side in [-1,1]:
            for j in range(3):
                zz=z-.45+j*.57;x=r.center(zz)+side*(r.width(zz)-.13+j*.16)
                p=(x,r.ground(x,zz)+.1,zz)
                ledge(G,shelves,p,(1.25-j*.16,.54-j*.06,1.5),840+index*10+j+side*3,angle=side*.22)
    # The stream emerges from a shaded cleft at the head of the ravine.
    head=b.pivot('Boulder spring cleft',root)
    for j in range(16):
        x=26.+j*1.12;z=-109.4-rng.uniform(0,2.4)
        if abs(x-r.center(-108))<1.8:continue
        G.ell(head,b.MATS['granite'],(x,1.0+rng.uniform(-.2,.6),z),(2.7,rng.uniform(3.,5.),3.8),seed=201+j,rough=.3)
    for j in range(74):
        x=25.5+j*.25
        G.poly(head,b.MATS['granite'],[(x,r.ground(x,-108),-108),(x+.25,r.ground(x+.25,-108),-108),(x+.25,2.6,-112),(x,2.6,-112)],[(0,1,2,3)])
    # One outward-facing escarpment surrounds the entire new land mass. Its
    # top meets the terrain exactly; irregular lower shelves reach below the
    # lake. No internal face remains at the habitat/ravine seam (x=44).
    rim=[]
    corners=[(25.5,12.),(92.,12.),(92.,-108.),(44.,-108.),(44.,-112.),(25.5,-112.)]
    for a,c in zip(corners,corners[1:]+corners[:1]):
        length=math.dist(a,c);n=math.ceil(length/.5)
        rim.extend((a[0]+(c[0]-a[0])*j/n,a[1]+(c[1]-a[1])*j/n) for j in range(n))
    def shelf(x,z,level):
        y=r.ground(x,z) if x<=44 else 1.235
        if z< -108:y=r.ground(x,-108)+(2.6-r.ground(x,-108))*(-108-z)/4.
        outward=level*.18+(1.4+1.2*math.sin(z*.31+x*.23)+.7*math.sin(z*.79+x*.48))*min(1,level/7.)
        if x==25.5:xx=x-outward*(1-r.smooth(-31.,-25.5,z))
        elif x==92 or x==44 and z< -108:xx=x+outward
        else:xx=x
        if z==12:zz=z+outward
        elif z==-112 or z==-108 and x>=44:zz=z-outward
        else:zz=z
        return (xx,y+(-66.-y)*level/66.,zz)
    levels=[0,2.5,7.,14.,25.,41.,66.]
    for chunk in range(math.ceil(len(rim)/24)):
        cliff=b.pivot('Ravine escarpment %03d'%chunk,root)
        for j in range(chunk*24,min(len(rim),(chunk+1)*24)):
            a=rim[j];c=rim[(j+1)%len(rim)]
            for lo,hi in zip(levels,levels[1:]):
                G.poly(cliff,b.MATS['granite'],[shelf(*a,lo),shelf(*a,hi),shelf(*c,hi),shelf(*c,lo)],[(0,1,2,3)])
    # Partly embedded outcrops break up the exposed upper cliff into natural
    # shelves. Their highest points stay below the protected walking surface.
    for side in [-1,1]:
        for j in range(24):
            z=-105+j*4.8+rng.uniform(-.8,.8);x=25.5 if side<0 else 92.
            if side<0 and z> -27:continue
            parent=b.pivot('Ravine escarpment outcrop %d %d'%(side,j),root)
            y=(r.ground(x,z) if side<0 else 1.235)-2.6-rng.random()*1.2
            G.ell(parent,b.MATS['granite'],(x+side*.4,y,z),(rng.uniform(2.4,4.6),rng.uniform(2.5,4.0),rng.uniform(3.,6.5)),seed=500+j+side*31,rough=.32)
    # Seal the underside well below the lake, including both end corners.
    cliff=b.pivot('Ravine escarpment base',root)
    for j in range(len(rim)):
        G.poly(cliff,b.MATS['granite'],[(58.75,-66.,-48.),shelf(*rim[(j+1)%len(rim)],66.),shelf(*rim[j],66.)],[(0,1,2)])
    for j in range(10):
        side=-1 if j%2 else 1;x=r.center(12)+side*rng.uniform(2.2,4.4)
        outlet_boulder(G,head,(x,r.ground(x,11.6),11.6),(1.5,2.1,2.),j+260)
    G.flush()
    record=b.hq.export(root,'environment','alpine_ravine')
    bpy.data.libraries.write(str(b.hq.SOURCE/'AlpineRavine.blend'),{scene},fake_user=True,compress=True)
    bpy.context.window.scene=old;r.write()
    (ROOT/'art_source/areas/ravine_manifest.json').write_text(json.dumps(record,indent=2)+'\n')
    print('RAVINE_ASSET: '+json.dumps(record))
    return record

def build():
    # MCP rebuilds touch only this generated scene. Return the artist to their
    # prior scene and selection even when a texture or export operation fails.
    if bpy.context.mode!='OBJECT':raise RuntimeError('Switch to Object mode before authoring the ravine')
    previous=bpy.context.window.scene;selected=list(bpy.context.selected_objects);active=bpy.context.view_layer.objects.active
    try:return _build()
    finally:
        bpy.context.window.scene=previous
        bpy.ops.object.select_all(action='DESELECT')
        for obj in selected:
            if obj.name in previous.objects:obj.select_set(True)
        if active and active.name in previous.objects:bpy.context.view_layer.objects.active=active

if __name__=='__main__':build()
