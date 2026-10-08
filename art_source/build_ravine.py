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
    for j in range(74):
        x0=25.5+j*.25;x1=x0+.25
        lows=[]
        for xx in [x0,x1]:
            low=r.deck(xx,z)-.20
            if xx<28.2 or xx>41.8:low=min(low,min(r.ground(xx,z+dz) for dz in [-1.82,0,1.82])-.12)
            lows.append(low)
        wedge(G,parent,b.MATS['mossrock'],x0,x1,*lows,r.deck(x0,z)-.025,r.deck(x1,z)-.025,z-1.82,z+1.82)

def build():
    old=bpy.context.window.scene;b.materials();b.MATS['granite']=b.MATS['stone'].copy();b.MATS['granite'].name='Ravine alpine granite';scene=b.hq.scene('AlpineRavine')
    root=b.pivot('AlpineRavine',None);G=b.Geometry();rng=random.Random(41892)
    for i,z in enumerate(r.BRIDGES):bridge(G,root,z,i)
    occupied=[]
    for cell in range(10):
        chunk=b.pivot('RavineReach%d'%cell,root)
        rocks=b.pivot('Boulder granite reach%d'%cell,chunk)
        for side in [-1,1]:
            for j in range(16):
                z=-107+cell*12+rng.uniform(0,11.4);x=r.center(z)+side*rng.uniform(r.width(z)*.82,5.0)
                if x<29.3 or x>40.6:continue
                size=(rng.uniform(.48,1.65),rng.uniform(.4,1.1),rng.uniform(.6,1.85))
                if j%6==0:size=(size[0]*1.45,size[1]*1.6,size[2]*1.4)
                p=(x,r.ground(x,z)-size[1]*.12,z)
                occupied.append((x,z,size[0]*.52,size[2]*.52))
                G.ell(rocks,b.MATS['granite'],p,size,seed=cell*100+side*20+j,rough=.24)
        # Wet cobbles, placed in clusters instead of a regular stone necklace.
        for j in range(38):
            z=-108+cell*12+rng.uniform(.1,11.9);x=r.center(z)+rng.uniform(-r.width(z),r.width(z))
            if abs(x-r.center(z))<r.width(z)*.70:continue
            size=rng.uniform(.12,.38)
            G.ell(chunk,b.MATS['granite'],(x,r.ground(x,z)+size*.2,z),(size,size*.55,size*1.3),seed=j,sectors=9,rings=5,rough=.28)
        for group in range(22):
            z=-107.5+cell*12+rng.uniform(0,11);side=-1 if group%2 else 1
            x=r.center(z)+side*rng.uniform(r.width(z)+.35,5.3)
            if x<29.3 or x>40.7:continue
            if any(abs(z-k)<2.2 for k in r.BRIDGES):continue
            for j in range(rng.randint(2,4)):
                xx=x+rng.uniform(-.3,.3);zz=z+rng.uniform(-.5,.5)
                if any(((xx-a)/w)**2+((zz-c)/d)**2<1.15 for a,c,w,d in occupied):continue
                species='maidenhair' if group%4==0 else ''
                plant_id=-1 if species else [140,145,136,143][group%4]
                plant=b.pivot('RavineBotanical',chunk,(xx,r.ground(xx,zz),zz),area_species=species,area_plant_id=plant_id)
                size=rng.uniform(.65,1.1);plant.scale=(size,size,size);plant.rotation_euler.z=rng.random()*math.tau
        # Small mountain shrubs on shelves above the water, kept below sightlines.
        for j in range(3):
            z=-105+cell*12+j*3.1;side=-1 if j%2 else 1;x=29.8 if side<0 else 40.1
            if any(abs(z-k)<3 for k in r.BRIDGES):continue
            if any(((x-a)/w)**2+((z-c)/d)**2<1.3 for a,c,w,d in occupied):continue
            plant=b.pivot('RavineShrub',chunk,(x,r.ground(x,z),z),area_species='hawthorn',area_plant_id=-1)
            plant.scale=(.5,.5,.5);plant.rotation_euler.z=j*2.3
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
        G.ell(head,b.MATS['granite'],(x,r.ground(x,11.6),11.6),(1.5,2.1,2.),seed=j+260,rough=.3)
    G.flush()
    record=b.hq.export(root,'environment','alpine_ravine')
    bpy.data.libraries.write(str(b.hq.SOURCE/'AlpineRavine.blend'),{scene},fake_user=True,compress=True)
    bpy.context.window.scene=old;r.write()
    (ROOT/'art_source/areas/ravine_manifest.json').write_text(json.dumps(record,indent=2)+'\n')
    print('RAVINE_ASSET: '+json.dumps(record))
if __name__=='__main__':build()
