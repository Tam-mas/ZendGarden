"""Original lake-country landscape and garden masonry, built and exported in Blender."""
from pathlib import Path
exec(Path(__file__).with_name('build_botanicals.py').read_text().split('specs=json.load')[0])
import numpy as np
from mathutils import noise
random.seed(875)
# Seamless surface maps: multi-scale noise, grain and mineral mottling.
def textured(name,base,kind):
    m=material(name,base)
    N=512; yy,xx=np.mgrid[0:N,0:N]; gen=np.random.default_rng(32+len(name))
    field=np.zeros((N,N))
    fy=np.fft.fftfreq(N)[:,None]; fx=np.fft.fftfreq(N)[None,:]
    for sigma,amp in [(28,.075),(11,.055),(3,.035),(.7,.02)]:
        white=gen.normal(0,1,(N,N))
        smooth=np.fft.ifft2(np.fft.fft2(white)*np.exp(-2*pi*pi*sigma*sigma*(fx*fx+fy*fy))).real
        field+=smooth/(smooth.std()+1e-8)*amp
    if kind=='bark': field+=np.sin(xx*.15+np.sin(yy*.035)*2)*.1
    color=np.array([int(base[i:i+2],16)/255 for i in (0,2,4)])
    rgb=np.clip(color[None,None,:]*(1+field[:,:,None]),0,1)
    if kind=='stone': rgb+=(np.maximum(field,0)*.13)[:,:,None]
    pixels=np.concatenate([np.clip(rgb,0,1),np.ones((N,N,1))],axis=2).astype('float32')
    image=bpy.data.images.new(name+' surface',width=N,height=N)
    image.pixels.foreach_set(pixels.ravel()); image.filepath_raw=ROOT+'/assets/textures/'+name.replace(' ','_')+'.png'; image.file_format='PNG'; image.save()
    tex=m.node_tree.nodes.new('ShaderNodeTexImage'); tex.image=image
    bs=m.node_tree.nodes.get('Principled BSDF'); m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color'])
    # Tangent-space normal map derived from the original height grain.
    dx=np.roll(field,-1,axis=1)-np.roll(field,1,axis=1); dy=np.roll(field,-1,axis=0)-np.roll(field,1,axis=0)
    n=np.stack([-dx*2,-dy*2,np.ones_like(dx)],2); n/=np.linalg.norm(n,axis=2)[:,:,None]
    pixels=np.concatenate([n*.5+.5,np.ones((N,N,1))],2).astype('float32')
    normal=bpy.data.images.new(name+' normal',width=N,height=N); normal.colorspace_settings.name='Non-Color'; normal.pixels.foreach_set(pixels.ravel()); normal.filepath_raw=ROOT+'/assets/textures/'+name.replace(' ','_')+'_normal.png'; normal.file_format='PNG'; normal.save()
    texn=m.node_tree.nodes.new('ShaderNodeTexImage'); texn.image=normal
    norm=m.node_tree.nodes.new('ShaderNodeNormalMap'); norm.inputs['Strength'].default_value=.45
    m.node_tree.links.new(texn.outputs['Color'],norm.inputs['Color']); m.node_tree.links.new(norm.outputs['Normal'],bs.inputs['Normal'])
    return m
stone=textured('Weathered limestone','a6a28a','stone')
soil=textured('Garden loam','514532','soil')
grass=textured('Meadow earth','4c692f','soil')
wood=textured('Aged chestnut','786044','bark')
terracotta=textured('Clay roof','a3694d','stone')
rock=textured('Mountain strata','797d6e','stone')
plaster=textured('Limewashed plaster','c6bda0','stone')

# One grouped mesh per material; small displacements make stonework genuinely three dimensional.
class WorldGeometry(Geometry):
    def object(self,name,mats):
        ob=super().object(name,mats)
        uv=ob.data.uv_layers.active
        for poly in ob.data.polygons:
            for li in poly.loop_indices:
                v=ob.data.vertices[ob.data.loops[li].vertex_index].co
                if abs(poly.normal.z)>.5: uv.data[li].uv=(v.x*.5,v.y*.5)
                else: uv.data[li].uv=(v.x*.5+v.y*.5,v.z*.5)
        return ob

warp_near=True
def rise(x,z):
    def smooth(a,b,v):
        t=max(0,min(1,(v-a)/(b-a))); return t*t*(3-2*t)
    h=.8+.55*sin(x*.15)+.45*cos(z*.19)+.12*sin((x+z)*.5)
    return h*smooth(2.4,5.5,math.hypot((x-8.5)*.65,z-5.9))*smooth(2.4,5.5,math.hypot(x-17,(z+8.5)*.65))
def V(x,y,z): return (x,-z,y+(rise(x,z) if warp_near else 0))

def wbox(g,pos,size,mat=0):
    x,y,z=pos; w,h,d=size; start=len(g.v)
    for zz in [-1,1]:
        for yy in [-1,1]:
            for xx in [-1,1]: g.v.append(V(x+xx*w/2,y+yy*h/2,z+zz*d/2))
    for f in [(0,1,3,2),(4,6,7,5),(0,4,5,1),(2,3,7,6),(0,2,6,4),(1,5,7,3)]: g.face(tuple(start+i for i in reversed(f)),mat)

def stone_piece(g,pos,scale,mat=0):
    x,y,z=pos; sx,sy,sz=scale; start=len(g.v); sides=18
    wobble=random.uniform(0,2*pi)
    profiles=[(-.48,.66),(-.32,.94),(.05,1.0),(.37,.88),(.50,.60)]
    for height,radius in profiles:
        for j in range(sides):
            a=j*2*pi/sides
            r=radius*(1+.045*sin(a*3+wobble)+.025*cos(a*5+wobble))
            g.v.append(V(x+cos(a)*sx*r,y+height*sy,z+sin(a)*sz*r))
    for k in range(len(profiles)-1):
        for j in range(sides): g.face((start+(k+1)*sides+j,start+(k+1)*sides+(j+1)%sides,start+k*sides+(j+1)%sides,start+k*sides+j),mat)
    g.face(tuple(start+(len(profiles)-1)*sides+j for j in reversed(range(sides))),mat)

near=WorldGeometry()
# Terrain edge falls from the playable hilltop, rather than ending in a box.
def near_height(x,z):
    d=max(abs(x-8)-25,abs(z+8)-18,0)
    return .02 if d<=0 else .02-min(45,d*1.55)+sin(x*.09)*sin(z*.07)*min(d*.06,3)
res=200
for j in range(res+1):
    z=-140+j*190/res
    for i in range(res+1):
        x=-100+i*216/res; near.v.append(V(x,near_height(x,z),z))
for j in range(res):
    for i in range(res):
        k=j*(res+1)+i; near.face((k,k+res+1,k+res+2,k+1),0)
near.object('HilltopMeadow',[grass])

masonry=WorldGeometry(); timber=WorldGeometry(); beds=WorldGeometry()
centers=[(0,0),(17,0),(17,-17),(0,-17)]
for cx,cz in centers:
    start=len(beds.v); steps=32
    for j in range(steps+1):
        for i in range(steps+1): beds.v.append(V(cx-4.75+i*9.5/steps,.07,cz-4.75+j*9.5/steps))
    for j in range(steps):
        for i in range(steps):
            k=start+j*(steps+1)+i; beds.face((k,k+steps+1,k+steps+2,k+1),0)
    for side in [-1,1]:
        for j in range(17):
            stone_piece(masonry,(cx+side*4.84,.11,cz-4.65+j*.58),(.22,.22,.32))
            stone_piece(masonry,(cx-4.65+j*.58,.11,cz+side*4.84),(.32,.22,.22))
    # Irregular stepping-stone walk beside the bed, with joints for moss.
    for j in range(19):
        stone_piece(masonry,(cx-6+j*.65,.05,cz+6+random.uniform(-.09,.09)),(.37,.11,.52))
for j in range(26): stone_piece(masonry,(-6+random.uniform(-.06,.06),.035,7-j*.7),(.49,.09,.36))
for j in range(10): stone_piece(masonry,(4.8+j*.65,.035,-11),(.35,.09,.5))
# Low country wall frames the garden without blocking the distant lake.
for x in range(-11,30):
    for level in range(3):
        stone_piece(masonry,(x+level%2*.43,level*.24+.1,-24.5),(.54,.26,.28))
# Watercourse banks are hand-built in original mesh geometry.
for z in np.arange(-6.5,7,.52):
    for x in [6.8,10.2]: stone_piece(masonry,(x,.03,float(z)),(.28,.18,.35))
for x in np.arange(11,24,.55):
    for z in [-7.1,-9.9]: stone_piece(masonry,(float(x),.02,z),(.36,.17,.27))
beds.object('PlantableLoam',[soil]); masonry.object('LimestonePathsAndWalls',[stone])

# A compact garden pavilion: original roof slats, arched door, windows and steps.
structure=WorldGeometry(); roof=WorldGeometry(); glazing=WorldGeometry()
cx,cz=-7.4,-18
wbox(structure,(cx,1.5,cz),(3.2,3,3.0),0)
# Door and paired tall windows, dark recessed frames.
wbox(structure,(cx,1.18,cz+1.52),(1.08,2.36,.09),1)
for offset in [-1.08,1.08]:
    wbox(structure,(cx+offset,1.65,cz+1.54),(.58,1.3,.10),1)
    wbox(glazing,(cx+offset,1.65,cz+1.61),(.42,1.13,.025),0)
    wbox(structure,(cx+offset,1.65,cz+1.65),(.045,1.2,.04),2)
    wbox(structure,(cx+offset,1.65,cz+1.65),(.49,.045,.04),2)
for j in range(10):
    a=j*pi/10
    stone_piece(structure,(cx+cos(a)*.64,2.25+sin(a)*.66,cz+1.62),(.15,.21,.16),2)
for j in range(3): wbox(structure,(cx,.08+j*.08,cz+1.6+(2-j)*.3),(1.55,.16,.65),2)
# Curved hipped roof quads, many strips visibly read as shingles.
for side in range(4):
    angle=side*pi/2
    for j in range(14):
        for k in range(6):
            u=-1.9+j*3.8/14; t=k/6; t2=(k+1)/6
            def roofpoint(u,t):
                width=1.9*(1-t)+.32*t
                return V(cx+cos(angle)*u*width/1.9-sin(angle)*width,3+t*1.9+.18*sin(t*pi),cz+sin(angle)*u*width/1.9+cos(angle)*width)
            st=len(roof.v); roof.v.extend([roofpoint(u,t),roofpoint(u+.25,t),roofpoint(u+.25,t2),roofpoint(u,t2)])
            roof.face((st,st+1,st+2,st+3),j%2)
structure.object('GardenPavilion',[plaster,wood,stone]); roof.object('PavilionShingleRoof',[terracotta,wood]); glazing.object('PavilionWindows',[material('Old glass','749498',.22)])

warp_near=False

# Large-scale alpine landscape: a continuous lake valley between eroded ridges.
def smooth(a,b,v):
    t=max(0,min(1,(v-a)/(b-a))); return t*t*(3-2*t)

def height(x,z):
    width=85+max(0,-z)*.085+sin(z*.017)*12+sin(z*.041)*4
    side=max(0,abs(x+sin(z*.002)*50)-width)
    ridge=(1-math.exp(-side/100))*(140+70*sin(z*.006+.4)**2)
    broad=noise.fractal(Vector((x*.008,z*.008,3.7)),1.0,2.0,5)*28
    fine=noise.fractal(Vector((x*.032,z*.032,8.2)),1.0,2.0,3)*13
    end_range=math.exp(-((z+1320)/185)**2)*(170+noise.fractal(Vector((x*.012,z*.007,4.5)),1,2,4)*65)
    erosion=abs(noise.fractal(Vector((x*.013,z*.009,1.2)),1,2,5))*45
    # Rounded terminal headlands close both ends of the basin well inside the mesh.
    coast=40*sin(x*.027)+24*sin(x*.061+.7)
    south=smooth(35+coast,420+coast,z)*(145+broad*.6+18*sin(x*.012+z*.009))
    north=smooth(1400,1660,-z)*(160+broad*.4)
    return -42+ridge+(broad+fine+erosion)*min(1,side/40)+end_range+south+north
X_MIN=-1200; X_SPAN=2400; Z_MIN=-1750; Z_SPAN=2850
far=WorldGeometry(); resolution=320
for j in range(resolution+1):
    z=Z_MIN+j*Z_SPAN/resolution
    for i in range(resolution+1):
        x=X_MIN+i*X_SPAN/resolution; far.v.append(V(x,height(x,z),z))
for j in range(resolution):
    for i in range(resolution):
        k=j*(resolution+1)+i; far.face((k,k+resolution+1,k+resolution+2,k+1),0)
terrain=far.object('AlpineLakeValley',[rock])
for li in terrain.data.uv_layers.active.data: li.uv*=.025

# Vertex colour mixes mountain rock, forest and summit frost in the actual asset.
attr=terrain.data.color_attributes.new(name='Color',type='FLOAT_COLOR',domain='CORNER')
for poly in terrain.data.polygons:
    for li in poly.loop_indices:
        v=terrain.data.vertices[terrain.data.loops[li].vertex_index].co
        slope=1-abs(poly.normal.z)
        if v.z>140: c=(.78,.79,.75,1)
        elif slope>.25: c=(.47,.46,.37,1)
        else: c=(.27,.38,.19,1)
        attr.data[li].color=c
# glTF exports the vertex-color layer and multiplies it with the stone surface.

def surface_height(x,z):
    # Match the exported triangle surface; analytic noise between grid vertices
    # otherwise buries or floats small trees on rugged slopes.
    gx=(x-X_MIN)/(X_SPAN/resolution); gz=(z-Z_MIN)/(Z_SPAN/resolution)
    i=max(0,min(resolution-1,int(gx))); j=max(0,min(resolution-1,int(gz)))
    tx=max(0,min(1,gx-i)); tz=max(0,min(1,gz-j)); k=j*(resolution+1)+i
    h00=far.v[k][2]; h10=far.v[k+1][2]; h01=far.v[k+resolution+1][2]; h11=far.v[k+resolution+2][2]
    return h00*(1-tz)+h01*(tz-tx)+h11*tx if tz>=tx else h00*(1-tx)+h11*tz+h10*(tx-tz)

# Clip each terrain triangle against the lake level. Its boundary is the actual
# irregular contour of the terrain, never the edge of a rectangular water plane.
LAKE_LEVEL=-39.0
lake=WorldGeometry(); shoreline=[]
for j in range(resolution):
    for i in range(resolution):
        k=j*(resolution+1)+i
        for indices in [(k,k+resolution+1,k+resolution+2),(k,k+resolution+2,k+1)]:
            polygon=[Vector(far.v[n]) for n in indices]; clipped=[]; crossings=[]
            for a,b in zip(polygon,polygon[1:]+polygon[:1]):
                inside_a=a.z<LAKE_LEVEL; inside_b=b.z<LAKE_LEVEL
                if inside_a: clipped.append(a)
                if inside_a!=inside_b:
                    crossing=a.lerp(b,(LAKE_LEVEL-a.z)/(b.z-a.z))
                    clipped.append(crossing); crossings.append(crossing)
            if len(crossings)==2: shoreline.append(crossings)
            if len(clipped)>=3:
                base=len(lake.v)
                for v in clipped: lake.v.append((v.x,v.y,LAKE_LEVEL))
                lake.face(tuple(base+n for n in range(len(clipped))),0)
lake.object('ContourLake',[material('Alpine water','456e7b',.26)])

# Weathered stones along the nearer coves break up the land/water transition.
shore=WorldGeometry()
for a,b in shoreline:
    center=(a+b)*.5; x,z=center.x,-center.y
    if z>-160 and random.random()<.72:
        size=random.uniform(.4,1.25)
        stone_piece(shore,(x,surface_height(x,z)+.12,z),(size,size*.75,size*.7))
shore.object('ShorelineRocks',[stone])
# An outer ring of ridges covers the distant terrain perimeter in every direction.
skyline=WorldGeometry(); rings=4; sectors=160
for ring in range(rings):
    radius=[.94,1.3,1.75,2.35][ring]
    for j in range(sectors):
        a=j*2*pi/sectors
        x=cos(a)*1200*radius; z=-300+sin(a)*1450*radius
        if ring==0: h=height(x,z)-12
        else: h=[0,235,310,180][ring]+65*sin(a*7+.6)+40*sin(a*17)+25*sin(a*29)
        skyline.v.append(V(x,h,z))
for ring in range(rings-1):
    for j in range(sectors):
        a=ring*sectors+j; b=ring*sectors+(j+1)%sectors
        skyline.face((a,b,b+sectors,a+sectors),0)
skyline.object('OuterMountainRidges',[rock])

# Batched woodland canopy gives distant slopes vegetation at a meaningful scale.
forest_sections={}
forest_mats=[material('Forest evergreen','334d28'),material('Forest olive','536336'),material('Forest spring','657947')]
for j in range(28000):
    x=random.uniform(-670,670); z=random.uniform(-1370,60)
    if j%4:
        z=max(-1370,min(60,random.gauss(random.choice([-1220,-980,-740,-500,-260,-70]),55)))
        width=85+max(0,-z)*.085
        x=random.choice([-1,1])*(width+abs(random.gauss(48,32)))-sin(z*.002)*50
    if j%3==0:
        z=max(65,min(950,random.gauss(random.choice([110,230,390,590,800]),65)))
        x=random.gauss(random.choice([-260,-130,20,155,300]),55)
    width=85+max(0,-z)*.085
    side=abs(x+sin(z*.002)*50)-width
    h=surface_height(x,z)
    if (side<12 and z<65) or h>215 or h<LAKE_LEVEL+.6 or (abs(x)<48 and -65<z<65): continue
    key=(int(math.floor(x/120)),int(math.floor(z/120)))
    forest=forest_sections.setdefault(key,WorldGeometry())
    size=random.uniform(1.1,2.7)
    if j%5<3:
        for level in range(4):
            base=h+size*(.35+level*.55); radius=size*(1-level*.19)
            st=len(forest.v)
            for k in range(9):
                a=k*2*pi/9; rr=radius*random.uniform(.65,1.15)
                forest.v.append(V(x+cos(a)*rr,base+random.uniform(-.2,.2),z+sin(a)*rr))
            forest.v.append(V(x,base+size*1.25,z))
            for k in range(9): forest.face((st+k,st+(k+1)%9,st+9),j%3)
    else:
        for k in range(5):
            a=k*2.4; r=size*.5
            forest.ellipsoid(V(x+cos(a)*r,h+size*(1.2+random.random()*.6),z+sin(a)*r),(size*.65,size*.6,size*.75),k%3,3,6)
forest_root=bpy.data.objects.new('ForestedMountainSlopes',None)
scene.collection.objects.link(forest_root)
for key,section in forest_sections.items():
    ob=section.object('ForestChunk_%s_%s'%key,forest_mats)
    ob.parent=forest_root

# Tiny roofed lakeside settlements establish human scale below the garden.
houses=WorldGeometry()
for j in range(480):
    z=random.uniform(-1050,-300); side=random.choice([-1,1]); width=85+abs(z)*.085
    x=side*(width+random.uniform(8,95))-sin(z*.002)*50
    h=surface_height(x,z)
    if h>85: continue
    w=random.uniform(2.5,4.0); d=random.uniform(3.0,4.3); bh=random.uniform(2.8,5)
    wbox(houses,(x,h+bh*.5,z),(w,bh,d),0)
    st=len(houses.v)
    houses.v.extend([V(x-w*.6,h+bh,z-d*.6),V(x+w*.6,h+bh,z-d*.6),V(x,h+bh+1.5,z-d*.6),V(x-w*.6,h+bh,z+d*.6),V(x+w*.6,h+bh,z+d*.6),V(x,h+bh+1.5,z+d*.6)])
    for f in [(0,1,2),(3,5,4),(0,2,5,3),(2,1,4,5)]: houses.face(tuple(st+i for i in f),1)
houses.object('DistantLakesideHamlets',[plaster,terracotta])

bpy.ops.object.select_all(action='DESELECT')
for obj in scene.objects: obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=ROOT+'/assets/environment/lake_garden.glb',export_format='GLB',use_selection=True,use_active_scene=True,export_yup=True,export_apply=True)
bpy.ops.wm.save_as_mainfile(filepath=ROOT+'/art_source/lake_garden.blend')
# Export geometry-level acceptance information alongside the editable source.
import json
boundary=[]
for j in range(resolution+1):
    for i in range(resolution+1):
        if i in [0,resolution] or j in [0,resolution]: boundary.append(far.v[j*(resolution+1)+i][2])
assert min(boundary)>LAKE_LEVEL+20, 'Water reaches the terrain boundary'
json.dump({'lake_level':LAKE_LEVEL,'shore_segments':len(shoreline),'minimum_boundary_height':min(boundary),'forest_sections':len(forest_sections),'southern_forest_sections':sum(1 for key in forest_sections if key[1]>0)},open(ROOT+'/art_source/landscape_validation.json','w'),indent=2)
result={'environment':ROOT+'/assets/environment/lake_garden.glb','objects':len(scene.objects)}
