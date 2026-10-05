"""Botanical collection organs, using the established curved-leaf/PBR workflow.
Coordinates here are Blender Z-up. The habitats convert their Y-up anchors.
Each species owns seedling, juvenile, bud and mature organs, never a flower card.
"""
import bpy, math, random
from mathutils import Vector
import botanical_geometry as bg
import botanical_detail as bd
Detailed=bd.detail_geometry(bg.Geometry)
PALETTE=[('rachis','52663d','smooth'),('leaf','365e35','leaf'),('young leaf','629746','leaf'),
 ('silver felt','a2ae95','leaf'),('white petal','eee7d8','petal'),('pink petal','cc7098','petal'),
 ('pollen','cfac4b','pollen'),('blue petal','475fbe','petal'),('purple petal','81629e','petal'),
 ('black stipe','332e26','smooth'),('fern fibre','675043','bark'),('maroon bud','713d54','petal')]
MATERIALS=[]
def materials(root):
 if MATERIALS:return MATERIALS
 maps=bd.surfaces(root)
 for name,color,kind in PALETTE:
  m=bpy.data.materials.get('Habitat botanical '+name) or bg.material('Habitat botanical '+name,color)
  bd.texture_material(m,kind,maps);MATERIALS.append(m)
 return MATERIALS

def p(x,y,z):return Vector((x,y,z))
def blade(g,a,b,w,mat=1,curl=.1,small=False):
 if small:bg.Geometry.leaf(g,a,b,w,mat,curl,segments=3)
 else:g.leaf(a,b,w,mat,curl,segments=7)
def radial(a,r,h):return p(math.cos(a)*r,math.sin(a)*r,h)
def flower(g,c,r=.1,mat=4,n=5,notch=False,vertical=False):
 c=Vector(c)
 for j in range(n):
  a=j*math.tau/n
  tip=c+(p(math.cos(a)*r,0,math.sin(a)*r) if vertical else radial(a,r,.018))
  blade(g,c,tip,r*.34,mat,.2)
  if notch:
   for s in [-1,1]:blade(g,c+(tip-c)*.6,tip+radial(a+s*.3,r*.22,.008),r*.10,mat,.08,True)
 g.ellipsoid(c+p(0,-.012 if vertical else 0,.006),(.026,.019,.018),6,4,8)
def trumpet(g,c,r,mat,n=5,orient=p(0,0,1)):
 c=Vector(c);axis=orient.normalized();side=axis.cross(p(0,1,0)).normalized();up=side.cross(axis).normalized()
 start=len(g.v);rings=8;sides=30
 for k in range(rings+1):
  t=k/rings;rr=r*(.12+.88*t**2.4)
  for j in range(sides+1):
   a=j*math.tau/sides;lobes=1+.12*math.cos(a*n)*t**7
   q=c+axis*(r*1.3*t)+rr*lobes*(math.cos(a)*side+math.sin(a)*up)
   g.v.append(tuple(q));g.uv[len(g.v)-1]=(j/sides,t)
 for k in range(rings):
  for j in range(sides):
   q=start+k*(sides+1)+j;g.face((q,q+1,q+sides+2,q+sides+1),mat)
 g.ellipsoid(c+axis*r*.45,(r*.065,r*.065,r*.12),6,4,8)

def fronds(g,tree=False,f=1):
 rng=random.Random(437);crown=1.8*f if tree else .025
 if tree:
  ps=[p(.045*math.sin(k*.7),.03*math.cos(k),k*crown/14) for k in range(15)]
  g.tube(ps,[f*(.16-.05*k/14) for k in range(15)],10,18)
  # Fibrous skirt of old petiole bases, rather than a plain cut cylinder.
  for k in range(int(70*f)):
   a=k*2.399;h=crown*(.10+.86*(k%13)/13);r=.13*f
   g.tube([radial(a,r,h),radial(a,r*1.25,h+.09*f)],[.018*f,.005*f],10,5)
 for j in range(max(3,int((9 if tree else 7)*f))):
  a=j*2.399;length=(1.6 if tree else .55)*f*rng.uniform(.82,1.16)
  pts=[radial(a,length*t,crown+length*(.52*math.sin(t*math.pi*.91)-.07*t)) for t in [k/18 for k in range(19)]]
  g.tube(pts,[max(.0008,.011*f*(1-k/20)) for k in range(19)],0,6)
  for k in range(2,18):
   t=k/18;c=pts[k];width=length*.23*math.sin(t*math.pi)**.85
   for s in [-1,1]:
    tip=c+radial(a+s*1.05,width,.025*f)
    g.tube([c,tip],[.003*f,.001*f],0,4)
    if tree:
     for q in range(1,6):
      v=q/6;b=c+(tip-c)*v;size=width*.25*math.sin(v*math.pi)**.65
      for side in [-1,1]:blade(g,b,b+radial(a+s*1.05+side*1.3,size,.008*f),size*.30,1 if j%3 else 2,.08,True)
    else:
     for q in range(3):
      b=c+(tip-c)*(q*.28+.15)
      blade(g,b,b+radial(a+s*1.0,width*.46,.045*f),width*.20,1,.14,True)
 # New coiled croziers at the crown.
 for j in range(3):
  a=j*2.4;ps=[]
  for k in range(16):
   t=k/15;angle=t*math.pi*2.1;rr=.085*f*(1-t*.68)
   ps.append(radial(a,.055*f+rr*math.cos(angle),crown+.28*f+rr*math.sin(angle)))
  g.tube([radial(a,.035*f,crown)]+ps,[.008*f]*17,2,6)

def cordate(g,base,tip,width):
 base=Vector(base);d=Vector(tip)-base;side=d.cross(p(0,0,1)).normalized();start=len(g.v)
 for k in range(9):
  t=k/8;w=width*(math.sin(math.pi*t)**.65+.36*(1-t)**12)
  for j in range(5):
   s=j/2-1;notch=abs(s)*.11*(1-t)**9
   q=base+d*(t-notch)+side*s*w+p(0,0,.024*math.sin(math.pi*t)*(1-.4*s*s))
   g.v.append(tuple(q));g.uv[len(g.v)-1]=(j/4,t)
 for k in range(8):
  for j in range(4):q=start+k*5+j;g.face((q,q+1,q+6,q+5),1)

def anatomy(key,f=1,bloom=True):
 leaf=Detailed(key,'leaf');flowers=Detailed(key,'bloom');buds=[];rng=random.Random(840+sum(map(ord,key)))
 if key in ['treefern','maidenhair']:
  if key=='treefern':fronds(leaf,True,f)
  else:
   for j in range(max(3,int(9*f))):
    a=j*2.399;end=radial(a,.48*f,.40*f);origin=p(0,0,.018)
    leaf.tube([origin,end*.45+p(0,0,.12*f),end],[.0035*f,.002*f,.0015*f],9,6)
    for k in range(2,7):
     t=k/7;c=end*t+p(0,0,.1*f*math.sin(t*math.pi))
     for s in [-1,1]:
      tip=c+radial(a+s*1.2,.13*f*(1-t*.65),.035*f)
      leaf.tube([c,tip],[.0017*f,.0007*f],9,4)
      # Broad fan-shaped pinnules on hair-fine black stalks.
      b=tip+radial(a+s*1.2,.018*f,.005*f);start=len(leaf.v);w=.065*f
      leaf.v.append(tuple(b));leaf.uv[start]=(.5,0)
      for q in range(13):
       angle=a+s*1.2+(q/12-.5)*2.2;rr=w*(1+.055*math.sin(q*3.0))
       leaf.v.append(tuple(b+radial(angle,rr,.018*f*math.sin(q*math.pi/12))));leaf.uv[start+q+1]=(q/12,1)
      for q in range(12):leaf.face((start,start+q+1,start+q+2),1)
 elif key=='birdsnest':
  for j in range(max(4,int(19*f))):
   a=j*2.399;h=f*rng.uniform(.60,.90);r=f*rng.uniform(.32,.58)
   blade(leaf,radial(a,.035*f,.035*f),radial(a,r,h),.095*f,2,.24)
  leaf.ellipsoid(p(0,0,.04*f),(.075*f,.075*f,.04*f),10,5,12)
 elif key in ['lily','hawthorn']:
  for j in range(max(2,int(6*f))):
   a=j*2.399;c=radial(a,.20*f+.10*f*(j%3),.025);r=.19*f
   if key=='hawthorn':blade(leaf,c-radial(a,r,0),c+radial(a,r,.012),r*.40,1,.01)
   else:
    start=len(leaf.v);leaf.v.append(tuple(c));leaf.uv[start]=(.5,.5)
    for q in range(33):
     angle=a+.18+q/32*(math.tau-.36);v=c+radial(angle,r,.009*math.sin(q*.7));leaf.v.append(tuple(v));leaf.uv[len(leaf.v)-1]=(.5+.5*math.cos(angle),.5+.5*math.sin(angle))
    for q in range(32):leaf.face((start,start+q+1,start+q+2),1)
  if bloom:
   if key=='lily':
    for layer in range(5):
     for j in range(12-layer):
      a=j*math.tau/(12-layer)+layer*.3;blade(flowers,p(0,0,.04+layer*.016),radial(a,(.20-layer*.025)*f,.07+layer*.032),.043*f,4,.30)
    for j in range(24):
     a=j*2.4;c=radial(a,.045*f,.16*f);flowers.tube([c,c+p(0,0,.025)],[.002,.001],6,4)
   else:
    for j in range(2):
     a=j*math.pi;c=p(0,0,.05);tip=radial(a,.19*f,.11*f)
     flowers.tube([c,tip],[.008*f,.003*f],0,6)
     for k in range(8):flower(flowers,c+(tip-c)*(k/9+.10),.034*f,4,3)
 elif key=='reed':
  for j in range(max(6,int(36*f))):
   a=j*2.399;h=rng.uniform(.55,1.15)*f;b=radial(a,.15*f*rng.random(),0);t=b+radial(a,.10*f,h)
   leaf.tube([b,b*.5+t*.5+radial(a,.035*f,0),t],[.006*f,.004*f,.001*f],1,7)
   if bloom and j%3==0:
    for q in range(3):flowers.ellipsoid(t+radial(q*2,.02*f,-.12*f),(.025*f,.017*f,.025*f),10,4,7)
 elif key=='mint':
  for j in range(max(2,int(5*f))):
   a=j*2.399;b=radial(a,.08*f,0);tip=b+radial(a,.08*f,.55*f)
   leaf.tube([b,b*.5+tip*.5,tip],[.006*f,.004*f,.002*f],0,7);buds.append(tip)
   for k in range(1,5):
    c=b+(tip-b)*k/5
    for side in [-1,1]:
     end=c+radial(a+side*math.pi/2,.13*f,.025*f)
     leaf.leaf(c,end,.040*f,1,.12,segments=7,lobed=True)
   if bloom:
    for k in range(24):
     angle=k*2.399;r=.055*f;h=(k/23-.5)*r*1.5
     c=tip+radial(angle,math.sqrt(max(0,r*r-h*h)),h)
     flower(flowers,c,.012*f,5,4)
 elif key in ['orchid','cymbidium','hoya']:
  if key=='hoya':
   ps=[p(.14*math.sin(k*.9)*f,0,k*.07*f) for k in range(14)];leaf.tube(ps,[.008*f]*14,0,8)
   for k in range(1,13):
    for s in [-1,1]:blade(leaf,ps[k],ps[k]+p(s*.18*f,.025*f,.065*f),.059*f,1,.07)
   if bloom:
    for j in range(3):
     c=p(.13*f*math.sin(j*2),-.10*f,.40*f+j*.20*f)
     for q in range(15):flower(flowers,c+radial(q*2.399,.045*f*math.sqrt(q),.03*math.cos(q)),.031*f,5,5)
  else:
   for j in range(max(3,int((7 if key=='orchid' else 18)*f))):
    a=j*2.399;blade(leaf,p(0,0,.015),radial(a,(.28 if key=='orchid' else .36)*f,(.12 if key=='orchid' else .72)*f),(.065 if key=='orchid' else .022)*f,1,.16)
   for spray in range(1 if key=='orchid' else 2):
    ps=[p((.20*t*t+spray*.08)*f,0,(.78*t-.16*t**4)*f) for t in [k/14 for k in range(15)]]
    leaf.tube(ps,[.011*f*(1-k/19) for k in range(15)],0,8)
    buds.extend(ps[k] for k in [8,10,12,14])
    if bloom:
     for q in range(5):
      c=ps[6+q*2]+p(.025*f,-.075*f,0)
      for j in range(5):
       a=j*math.tau/5+math.pi*.5;r=.11*f
       width=(.048 if j in [1,4] else .024)*f
       blade(flowers,c,c+p(math.cos(a)*r,0,math.sin(a)*r),width,4 if key=='orchid' else 6,.21)
      # Orchid lip folds forward, distinct from the broad paired petals.
      blade(flowers,c+p(0,-.018*f,0),c+p(0,-.08*f,-.055*f),.025*f,5,.13)
      flowers.ellipsoid(c+p(0,-.018*f,.008*f),(.011*f,.025*f,.011*f),6,4,8)
 elif key=='iris':
  for j in range(max(3,int(13*f))):
   blade(leaf,p((j%3-1)*.025*f,0,0),p((j-6)*.046*f,.015*math.sin(j),rng.uniform(.55,.95)*f),.022*f,1,.015)
  for j in range(2):
   c=p(j*.11*f,0,.95*f);leaf.tube([p(0,0,0),c],[.012*f,.006*f],0,8);buds.append(c)
   if bloom:
    for k in range(3):
     a=k*math.tau/3
     blade(flowers,c,c+radial(a,.15*f,-.10*f),.045*f,8,.2)
     blade(flowers,c,c+radial(a+1,.06*f,.14*f),.040*f,8,.18)
 elif key in ['edelweiss','gentian','saxifrage']:
  for cluster in range(1 if key!='saxifrage' else 5):
   c=radial(cluster*2.399,.10*f if cluster else 0,0)
   for j in range(max(5,int(16*f))):
    a=j*2.399;blade(leaf,c,c+radial(a,.15*f if key!='saxifrage' else .06*f,.04*f),.018*f,3 if key=='edelweiss' else 1,.12)
   if bloom:
    if key=='gentian':trumpet(flowers,c+p(0,0,.08*f),.095*f,7)
    elif key=='edelweiss':
     c=c+p(0,0,.21*f);leaf.tube([p(0,0,.02),c],[.006*f,.003*f],3,6)
     for j in range(9):blade(flowers,c,c+radial(j*2.399,.105*f,.015*f),.022*f,3,.12)
     for j in range(7):flowers.ellipsoid(c+radial(j*2.4,.033*f,.016*f),(.015*f,.015*f,.016*f),6,5,10)
    else:
     c=c+p(0,0,.17*f);leaf.tube([c-p(0,0,.17*f),c],[.003*f,.0015*f],0,5);flower(flowers,c,.038*f,5)
 else:
  count=max(2,int((7 if key=='nightphlox' else 4)*f));h=(.38 if key=='nightphlox' else 1.05)*f
  for j in range(count):
   a=j*2.399;b=radial(a,.10*f,0);tip=b+radial(a,.20*f,h*rng.uniform(.75,1))
   ps=[b,b*.5+tip*.5,tip];leaf.tube(ps,[.009*f,.007*f,.002*f],0,7);buds.append(tip)
   for q in range(2,7):
    c=b+(tip-b)*q/8
    for s in [-1,1]:blade(leaf,c,c+radial(a+s*1.5,(.10 if key=='nightphlox' else .17)*f,.04*f),(.018 if key=='nightphlox' else .055)*f,1,.13)
   if bloom:
    if key=='primrose':flower(flowers,tip,.10*f,6,4)
    elif key=='nightphlox':flower(flowers,tip,.046*f,4,5,True)
    else:trumpet(flowers,tip,.12*f if key=='moonflower' else .055*f,4,5,p(.3,-.75,.7))
  if key=='moonflower':
   ps=[p(.14*f*math.sin(k*.65),.14*f*math.cos(k*.65),k*.085*f) for k in range(17)];leaf.tube(ps,[.009*f]*17,0,7)
   for k in range(2,16,2):cordate(leaf,ps[k],ps[k]+radial(k*2.4,.26*f,.02*f),.105*f)
 if not bloom and key not in ['maidenhair','birdsnest','treefern','reed'] and f>.65:
  if not buds:
   buds=[p(0,0,.13*f if key in ['lily','hawthorn'] else .20*f)]
   for tip in buds:leaf.tube([p(0,0,.015),tip],[.004*f,.003*f],0,6)
  for tip in buds:flowers.ellipsoid(tip,(.016*f,.016*f,.034*f),11,5,8)
 return leaf,flowers

def build(key,root,mats,pivot):
 root['botanical_detail']=True;root['growth_stages']=True
 for stage,f,open_ in [('Mature',1,True),('Seedling',.24,False),('Juvenile',.52,False),('Buds',.80,False)]:
  parent=root if stage=='Mature' else pivot(stage,root)
  leaves=pivot('Leaves' if stage=='Mature' else stage+'Foliage',parent)
  blooms=pivot('Flowers' if stage=='Mature' else stage+'Buds',parent)
  L,F=anatomy(key,f,open_)
  for role,g,dest in [('Foliage',L,leaves),('Corollas',F,blooms)]:
   if g.f:g.object(key+' '+stage+' '+role,mats).parent=dest
