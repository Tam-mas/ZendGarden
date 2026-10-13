"""Species-aware Blender mesh construction; no scene changes on import.

Each model is built at seedling, sapling and mature complexity independently.
Flowers, fruit and unfurling tips carry local attachment coordinates. Foliage is
shaped geometry (folds, petioles, compound pinnae, fleshy blades), not billboards.
"""
import math
import random
from mathutils import Vector
from botanical_geometry import Geometry
from botanical_2026_data import BY_ID, IDS
from plant_full_herbs import Tissue, round_leaf
from plant_full_low import ellipse
from fruit_tree_geometry import mark_anchor
from flower_additions_geometry import frame, petal_in_plane

Z=Vector((0,0,1))
TAU=math.tau

def radial(a,r,z=0):return Vector((math.cos(a)*r,math.sin(a)*r,z))
def path(points,t):
 t=max(0,min(.999999,t))*(len(points)-1);k=int(t)
 return Vector(points[k]).lerp(Vector(points[k+1]),t-k)
def stem(g,pts,r,mat=0,sides=7):
 g.tube(pts,[r*(1-i/max(1,len(pts)-1)*.8) for i in range(len(pts))],mat,sides)

def leaf(g,p,a,length,width,mat=1,lift=.18,shape='oval',steps=6):
 """Folded blade with an attached petiole and species-specific margins."""
 p=Vector(p);d=radial(a,1);side=radial(a+math.pi/2,1)
 start=p+d*length*.12+Z*length*.05
 stem(g,[p,start],max(.001,length*.012),0,4)
 base=len(g.v)
 for i in range(steps+1):
  t=i/steps;profile=max(.005,math.sin(math.pi*t))**(.5 if shape in ['round','heart'] else .85)
  if shape=='lance':profile*=1-.3*t
  if shape=='lobed':profile*=.52+.48*math.cos(t*TAU*3)
  if shape=='serrate':profile*=1+(.10 if i%2 else -.03)
  if shape=='heart':profile*=1.2-.65*t
  center=start+d*length*.88*t+Z*length*(lift*t+.16*math.sin(math.pi*t))
  for k in [-1,0,1]:
   g.v.append(tuple(center+side*width*profile*k+Z*length*(-.05*abs(k)*profile)))
   g.uv[len(g.v)-1]=((k+1)/2,t)
 for i in range(steps):
  for k in range(2):
   n=base+i*3+k;g.face((n,n+3,n+4,n+1),mat)
 # Fine raised midrib makes the close-up silhouette read without painted veins.
 if length>.18:stem(g,[start,start+d*length*.44+Z*length*(lift*.5+.16),start+d*length*.88+Z*length*lift],length*.004,2,3)

def compound(g,p,a,length,mat=1,pairs=5,fern=False):
 p=Vector(p);d=radial(a,1);pts=[p,p+d*length*.5+Z*length*.13,p+d*length+Z*length*.03]
 stem(g,pts,length*.009,0,4)
 for j in range(pairs):
  t=(j+.6)/(pairs+1);q=path(pts,t);ll=length*(.42 if fern and pairs==3 else .23 if fern else .29)*(1-t*.55)
  for sign in [-1,1]:leaf(g,q,a+sign*1.04,ll,ll*(.27 if fern else .31),mat,lift=.05,steps=3 if fern else 5)
 leaf(g,pts[-1],a,length*.23,length*.06,mat,steps=4)

def palm_leaf(g,p,a,length,mat=1,fan=False,fishtail=False,early=False):
 p=Vector(p);d=radial(a,1);pts=[p,p+d*length*.34+Z*length*.34,p+d*length*.73+Z*length*.24,p+d*length-Z*length*.15]
 if fan:
  hub=path(pts,.45);radius=length*.58
  stem(g,[p,path(pts,.25),hub],length*.014,0,5)
  upright=radial(a,.43,.90).normalized();across=radial(a+math.pi/2,1)
  # Connected pleated fan, with short split tips rather than disconnected fingers.
  for j in range(32):
   a0=-1.42+j*2.84/32;a1=-1.42+(j+1)*2.84/32
   n=len(g.v);v0=hub+(upright*math.cos(a0)+across*math.sin(a0))*radius+radial(a,radius*(.03 if j%2 else .09));v1=hub+(upright*math.cos(a1)+across*math.sin(a1))*radius+radial(a,radius*(.09 if j%2 else .03))
   g.v.extend([tuple(hub),tuple(v0),tuple(v1)]);g.uv.update({n:(.5,0),n+1:(j/32,1),n+2:((j+1)/32,1)})
   g.face((n,n+1,n+2),mat)
  return
 stem(g,pts,length*.014,0,5)
 for j in range(6 if early else 22):
  t=.18+j*(.72/(6 if early else 22));q=path(pts,t);ll=length*.32*math.sin(math.pi*t)**.65
  for sign in [-1,1]:
   aa=a+sign*(1.05 if not fishtail else .86)
   if fishtail:
    end=q+radial(aa,ll)+Z*ll*.05
    stem(g,[q,end],ll*.011,0,4)
    for k in range(3):
     base=q.lerp(end,.4+k*.25);u=radial(aa+sign*.5,1);v=radial(aa+sign*1.8,1);n=len(g.v)
     g.v.extend([tuple(base),tuple(base+u*ll*.48),tuple(base+u*ll*.45+v*ll*.3),tuple(base+v*ll*.28)])
     g.uv.update({n:(.5,0),n+1:(0,1),n+2:(.5,.83),n+3:(1,1)});g.face((n,n+1,n+2,n+3),mat)
   else:leaf(g,q,aa,ll,ll*.065,mat,lift=-.24,steps=4)

def bud(buds,anchor,size=.055):
 anchor=Vector(anchor);first=len(buds.v)
 ellipse(buds,anchor+Z*size*.4,(size*.35,size*.35,size*.7),3,5,7);mark_anchor(buds,first,anchor)

def flower(b,buds,p,r=.09,color=0,count=9):
 p=Vector(p);first=len(b.v)
 for ring in range(2):
  for j in range(count):
   a=j*TAU/count+ring*.4;petal_in_plane(b,p,radial(a,1),Z,r*(1-ring*.23),r*.22,color,.16,.02)
 ellipse(b,p+Z*r*.1,(r*.20,r*.20,r*.10),2,4,8)
 mark_anchor(b,first,p);bud(buds,p,r*.55)

def fruit(b,buds,anchor,form,r,rng):
 """Fruit attached to an exact woody/cactus node; pedicel grows with the fruit."""
 anchor=Vector(anchor);first=len(b.v);rr=r*rng.uniform(.88,1.10)
 stretch={'mango':1.30,'papaya':1.65,'jackfruit':1.6,'loquat':1.2,'tamarillo':1.5,'kumquat':1.45,'mulberry':1.8,'breadfruit':1.1}.get(form,1)
 c=anchor-Z*rr*(stretch+(.15 if form=='jackfruit' else .5))
 stem(b,[anchor,c+Z*rr*stretch],max(.003,rr*.05),3,5)
 start=len(b.v);ellipse(b,c,(rr,rr,rr*stretch),0,10,20)
 for i in range(start,len(b.v)):
  v=Vector(b.v[i])-c;a=math.atan2(v.y,v.x)
  if form=='mango':v.x+=rr*.20*(1-v.z/(rr*stretch));v.y*=.76
  if form=='starfruit':
   fac=.62+.38*math.cos(5*a);v.x*=fac;v.y*=fac;v.z*=1.35
  if form in ['lychee','jackfruit','custard','breadfruit','yuzu']:
   fac=1+.035*math.cos(19*a)*math.sin(v.z/rr*24);v*=fac
  b.v[i]=tuple(c+v)
 if form in ['lychee','jackfruit','custard','breadfruit','mulberry']:
  # Scales / drupelets are real relief, not oversized spikes.
  count=90 if form=='jackfruit' else 36 if form=='lychee' else 60
  for k in range(count):
   z=1-2*(k+.5)/count;axis=radial(k*2.39996,math.sqrt(1-z*z),z)
   q=c+Vector((axis.x*rr,axis.y*rr,axis.z*rr*stretch))
   size=rr*(.15 if form=='mulberry' else .11 if form=='custard' else .055)
   ellipse(b,q,(size,size,size*.75),0 if k%4 else 1,3,5)
 if form in ['persimmon','pomegranate','guava','loquat','dragonfruit']:
  top=c+(Z*rr*stretch if form=='persimmon' else -Z*rr*stretch)
  for j in range(4 if form=='persimmon' else 5):leaf(b,top,j*TAU/5,rr*.65,rr*.23,3,lift=.2,steps=3)
 if form=='dragonfruit':
  for k in range(15):
   a=k*2.39996;z=-.7+1.4*k/15;q=c+radial(a,rr*math.sqrt(1-z*z),z*rr)
   leaf(b,q,a,rr*.8,rr*.18,3,lift=.8,steps=4)
 mark_anchor(b,first,anchor);bud(buds,anchor,rr*.45)

def woody(p,phase):
 g,b,bs=Tissue(),Tissue(),Tissue();form=p['form'];rng=random.Random(p['id']*919)
 early=phase!='mature';s={'mature':1,'seedling':.055,'juvenile':.23}[phase];h=p['height']*s
 forest=p['group']=='Rainforest & tree ferns';wide=form in ['banyan','kapok','candlenut','mulberry'];spread=.45 if wide else .39 if form=='mango' else .32 if not forest else .29
 trunk=[Vector((math.sin(k*1.3+p['id'])*h*.008,math.cos(k*.8)*h*.008,h*k/8*.84)) for k in range(9)]
 radius=h*(.035 if form in ['banyan','kapok','lauan'] else .023)
 stem(g,trunk,radius,5,12)
 if not early and forest:
  for j in range(6):
   a=j*TAU/6;tip=radial(a,radius*4)
   # Buttress fins share the trunk and meet ground level.
   n=len(g.v);g.v.extend([tuple(tip),tuple(radial(a+.11,radius)),tuple(radial(a,radius*.8)+Z*h*.19),tuple(radial(a-.11,radius))]);g.face((n,n+1,n+2),5);g.face((n,n+2,n+3),5)
 count=2 if phase=='seedling' else 4 if early else 11
 compound_forms=['lychee','longan','starfruit','qmaple','blackbean']
 for j in range(count):
  t=(.46 if forest else .34)+j/count*.43;angle=j*2.39996+p['id']*.37;origin=path(trunk,t)
  length=h*spread*(.79+.21*math.sin(j*1.73+.5))
  # Branches rise into an irregular domed canopy instead of repeated conical tiers.
  end=origin+radial(angle,length,0);end.z=h*(.70+.16*math.sin(j*1.39+.2))
  branch=[origin,origin.lerp(end,.48)-Z*h*.035,end]
  stem(g,branch,radius*.40*(1-t),5,7)
  if not early and form=='banyan' and j%2==0:
   q=path(branch,.65)
   stem(g,[q,q-Z*h*.20,Vector((q.x,q.y,.01))],h*.007,5,7)
  for k in range(1 if early else 4):
   q=path(branch,.48+k*.16);aa=angle+(-1 if k%2 else 1)*.75
   tip=q+radial(aa,length*.48,h*.045);stem(g,[q,q.lerp(tip,.6),tip],radius*.10,5,5)
   for tw in range(1 if early else 3):
    start=q.lerp(tip,.45+tw*.25);a=aa+(-1 if tw%2 else 1)*.8;terminal=start+radial(a,length*.25,h*.025)
    stem(g,[start,terminal],radius*.03,0,4)
    for m in range(3 if early else 2 if form in compound_forms else 4 if form=='kapok' else 7):
     base=start.lerp(terminal,(m+.6)/8);turn=a+m*2.4
     ll=(.47 if not forest else .79)*(.5 if phase=='seedling' else .8 if early else 1)*rng.uniform(.78,1.12)
     ll*=1.4 if form in ['loquat','breadfruit','tamarillo','banyan'] else .70 if form in ['kumquat','pomegranate'] else 1
     mat=2 if m==6 or j==count-1 else 1 if (m+k)%3 else 3
     if form in compound_forms:compound(g,base,turn,ll*1.7,mat,3 if form!='blackbean' else 4)
     elif form=='kapok':
      for finger in range(5):leaf(g,base,turn+(finger-2)*.50,ll,ll*.17,mat)
     else:
      shape='lance' if form in ['mango','pomegranate','lauan'] else 'serrate' if form in ['loquat','quandong'] else 'lobed' if form in ['breadfruit','candlenut'] else 'heart' if form in ['tamarillo','mulberry'] else 'oval'
      leaf(g,base,turn,ll,ll*(.14 if shape=='lance' else .35 if shape in ['heart','lobed'] else .24),mat,lift=-.20 if form in ['mango','loquat'] else .14,shape=shape)
    if not early and tw==1 and k%2==0:
     if p['group']=='Fruit trees' and form!='jackfruit':
      size={'mango':.14,'pomelo':.18,'grapefruit':.14,'kumquat':.048,'longan':.034,'lychee':.045,'loquat':.055,'mulberry':.035,'breadfruit':.17,'starfruit':.10}.get(form,.10)
      for f in range(4 if form in ['lychee','longan','loquat'] else 1):
       anchor=terminal+radial(f*2.4,.06,-f*.06);stem(g,[terminal,anchor],.003,0,4);fruit(b,bs,anchor,form,size,rng)
     elif forest and j%3==0:fruit(b,bs,terminal,form,.10 if form in ['blackbean','kauri'] else .06,rng)
 if not early and form=='jackfruit':
  for j in range(5):
   anchor=path(trunk,.30+j*.08)+radial(j*2.4,radius*.75);fruit(b,bs,anchor,form,.24,rng)
 return g,b,bs

def crown(p,phase):
 g,b,bs=Tissue(),Tissue(),Tissue();form=p['form'];early=phase!='mature';rng=random.Random(p['id'])
 s={'mature':1,'seedling':.08,'juvenile':.28}[phase];h=p['height']*s
 fern='fern' in form;banana=form=='banana';papaya=form=='papaya'
 fern_trunk={'softfern':.54,'lacyfern':.66,'roughfern':.60,'silverfern':.62,'blackfern':.75,'goldenfern':.20}
 tr=h*(fern_trunk[form] if fern else .63 if banana else .79)
 if early:
  tr=h*(.07 if fern else .26 if banana or papaya else .12) if phase=='seedling' else h*(.20 if fern else .43)
 r=h*({'softfern':.054,'lacyfern':.030,'roughfern':.050,'silverfern':.036,'blackfern':.036,'goldenfern':.073}.get(form,.035))
 trunk=[(0,0,0),(.035*h,0,tr*.45),(.02*h,.01*h,tr)]
 stem(g,trunk,r,5 if fern else 0,14)
 top=Vector(trunk[-1]);count=4 if phase=='seedling' else 6 if early else {'softfern':12,'lacyfern':11,'roughfern':10,'silverfern':12,'blackfern':9,'goldenfern':9}.get(form,10)
 if not early:
  for j in range(18 if fern else 11):
   z=tr*j/(18 if fern else 11);a=j*2.4
   if fern:
    for side in range(5):
     q=radial(a+side*TAU/5,r*.81,z);stem(g,[q,q+radial(a+side*TAU/5,r*.25,r*.35)],r*.22,5,4)
   else:
    ring=[radial(k*TAU/12,r*(1-j/24),z) for k in range(13)];g.tube(ring,[r*.035]*13,6,4)
 if form=='walkingpalm' and not early:
  for j in range(8):stem(g,[radial(j*TAU/8,h*.12),radial(j*TAU/8,h*.035,h*.17),Z*h*.31],h*.013,5,6)
 for j in range(count):
  a=j*2.39996;length=h*({'softfern':.60,'lacyfern':.48,'roughfern':.55,'silverfern':.52,'blackfern':.45,'goldenfern':.72}.get(form,.50 if banana else .36))
  origin=top-Z*h*(.035*(j%3));mat=2 if j==count-1 else 1 if j%3 else 3
  if fern:
   d=radial(a,1);pts=[origin,origin+d*length*.3+Z*length*.33,origin+d*length*.72+Z*length*.19,origin+d*length-Z*length*.16]
   stem(g,pts,length*.011,0,5)
   pairs=4 if early else 19 if form=='lacyfern' else 14 if form=='goldenfern' else 16
   for k in range(pairs):
    t=.16+k*.77/pairs;ll=length*.28*math.sin(math.pi*t)**.72;q=path(pts,t)
    for sign in [-1,1]:compound(g,q,a+sign*1.06,ll,4 if form=='silverfern' and sign<0 else mat,3 if early else 7,True)
  elif banana:
   start=origin+radial(a,length*.13,length*.16);stem(g,[origin,start],length*.025,0,6)
   # Broad leaves split at the edge, with a continuous central rib.
   d=radial(a,1);side=radial(a+math.pi/2,1);pts=[start,start+d*length*.5+Z*length*.22,start+d*length-Z*length*.12];stem(g,pts,length*.014,0,5)
   for k in range(14):
    t=k/14;q=path(pts,t);end=path(pts,(k+1)/14);width=length*.17*math.sin(math.pi*(t+.04))**.65
    for sign in [-1,1]:
     edge=q+side*sign*width-Z*width*.3;edge2=end+side*sign*width-Z*width*(.36 if k%3 else .5);n=len(g.v)
     g.v.extend(map(tuple,[q,end,edge2,edge]));g.uv.update({n:(.5,t),n+1:(.5,(k+1)/14),n+2:((sign+1)/2,(k+.97)/14),n+3:((sign+1)/2,t)})
     g.face((n,n+1,n+2,n+3),mat)
  elif papaya:
   end=origin+radial(a,length*.72,length*.05);stem(g,[origin,end],length*.020,0,6)
   # Deep palmately cut lobes with a continuous web near the petiole.
   n=len(g.v);g.v.append(tuple(end));g.uv[n]=(.5,.5);ring=[]
   for k in range(56):
    turn=k*TAU/56;profile=.30+.70*max(0,math.sin(k%8/8*math.pi))**1.6
    q=end+radial(turn,length*.44*profile,length*.024*math.sin(turn*7))
    ring.append(len(g.v));g.v.append(tuple(q));g.uv[len(g.v)-1]=(.5+.5*profile*math.cos(turn),.5+.5*profile*math.sin(turn))
   for k in range(56):g.face((n,ring[k],ring[(k+1)%56]),mat)
  else:palm_leaf(g,origin,a,length,mat,fan=form=='fanpalm',fishtail=form=='fishtail',early=early)
 if not early:
  if papaya:
   for j in range(12):
    anchor=top-Z*h*(.06+j*.019)+radial(j*2.4,r*.55);fruit(b,bs,anchor,'papaya',.14,rng)
  elif banana:
   anchor=top;first=len(b.v);start=top+Vector((h*.12,0,-h*.05));bottom=start-Z*h*.32
   stem(b,[top,top+Vector((h*.09,0,h*.02)),start,bottom],.035,3,7)
   for tier in range(6):
    for j in range(8):
     a=j*TAU/8;q=start-Z*(tier*.14)
     pts=[q+radial(a,.04),q+radial(a,.18,-.03),q+radial(a,.24,.10),q+radial(a,.23,.21)]
     b.tube(pts,[.033,.044,.035,.009],0,7)
   ellipse(b,bottom-Z*.13,(.10,.10,.20),1,8,12);mark_anchor(b,first,anchor);bud(bs,anchor,.18)
  elif fern:
   for j in range(3):
    anchor=top+radial(j*2.4,r*.6);first=len(bs.v);pts=[]
    for k in range(17):
     t=k/16;angle=TAU*t*1.2;rr=.13*(1-t)+.015;pts.append(anchor+Vector((rr*math.sin(angle),0,h*.05+rr*math.cos(angle))))
    stem(bs,[anchor,*pts],.018,3,5);mark_anchor(bs,first,anchor)
  else:
   for j in range(4):
    anchor=top-Z*h*.035+radial(j*2.4,r*.8);fruit(b,bs,anchor,'palm',.06,rng)
 return g,b,bs

def cactus_stem(g,pts,radii,ribs,spines=True,mat=1,spine_mat=6):
 pts=list(map(Vector,pts));sides=ribs*3;base=len(g.v)
 for i,p in enumerate(pts):
  tangent=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized();u,v,n=frame(tangent)
  for j in range(sides):
   a=j*TAU/sides;rr=radii[i]*((.67+.33*math.cos(a*ribs)) if ribs==5 else (.84+.16*math.cos(a*ribs)));q=p+(u*math.cos(a)+v*math.sin(a))*rr
   g.v.append(tuple(q));g.uv[len(g.v)-1]=(j/sides,i/(len(pts)-1))
 for i in range(len(pts)-1):
  for j in range(sides):
   a=base+i*sides+j;c=base+i*sides+(j+1)%sides;g.face((a,c,c+sides,a+sides),mat)
 g.face(tuple(base+j for j in reversed(range(sides))),mat)
 g.face(tuple(base+(len(pts)-1)*sides+j for j in range(sides)),mat)
 if spines:
  for i in range(1,len(pts)-1):
   for j in range(0,sides,3):
    q=Vector(g.v[base+i*sides+j]);d=(q-pts[i]).normalized();length=min(.045,radii[i]*.24)
    for sign in [-1,0,1]:stem(g,[q,q+d*length+Z*length*.40*sign],max(.0008,length*.034),spine_mat,3)

def fleshy(g,p,a,length,width,mat=1,lift=.4,teeth=False):
 p=Vector(p);d=radial(a,1);u=radial(a+math.pi/2,1);rows=[]
 for j in range(9):
  t=j/8;profile=max(.015,math.sin(math.pi*t))**.55;c=p+d*length*t+Z*length*(lift*t+.12*math.sin(math.pi*t));row=[]
  for k in range(8):
   angle=k*TAU/8;q=c+u*width*profile*math.cos(angle)+Z*width*.30*profile*math.sin(angle)
   row.append(len(g.v));g.v.append(tuple(q));g.uv[len(g.v)-1]=(k/8,t)
  rows.append(row)
 for arow,brow in zip(rows,rows[1:]):
  for k in range(8):g.face((arow[k],brow[k],brow[(k+1)%8],arow[(k+1)%8]),mat)
 if teeth:
  for j in range(1,8):
   t=j/8;c=p+d*length*t+Z*length*(lift*t+.12*math.sin(math.pi*t));w=width*math.sin(math.pi*t)**.55
   for sign in [-1,1]:stem(g,[c+u*sign*w,c+u*sign*(w+length*.035)+d*length*.025],length*.006,6,3)

def dry(p,phase):
 g,b,bs=Tissue(),Tissue(),Tissue();form=p['form'];rng=random.Random(p['id']);early=phase!='mature'
 s={'mature':1,'seedling':.16,'juvenile':.48}[phase];h=p['height']*s;sites=[]
 columns=['saguaro','organpipe','bluetorch','totem','bishop','barrel','pincushion','rainbow']
 if form in columns:
  barrel=form in ['bishop','barrel','pincushion','rainbow'];r=h*(.50 if form in ['bishop','barrel'] else .31 if barrel else .075)
  count=1 if early or form in ['saguaro','bishop','barrel','rainbow'] else 5 if form=='organpipe' else 3
  for j in range(count):
   origin=radial(j*2.4,r*1.8 if j else 0);height=h*(1 if j==0 else rng.uniform(.56,.84));pts=[];rads=[]
   for k in range(17):
    t=k/16;pts.append(origin+Z*height*t);profile=math.sin(math.pi*t)**.45 if barrel else min(1,(1-t)*7)**.50
    rr=r*max(.025,profile)*(1+.15*math.sin(t*TAU*3+j) if form=='totem' else 1);rads.append(rr)
   cactus_stem(g,pts,rads,5 if form=='bishop' else 8 if form=='totem' else 12,form not in ['bishop','totem'],1,7 if form=='rainbow' else 6);sites.append(origin+Z*height)
  if form=='saguaro' and not early:
   for j in range(3):
    a=j*2.4;origin=Z*h*(.34+j*.09);tip=origin+radial(a,h*.19,h*(.26-j*.025))
    pts=[origin+radial(a,h*.19*math.sin(k/8*math.pi/2),h*.10*(1-math.cos(k/8*math.pi/2))) for k in range(9)]
    pts.extend(pts[-1].lerp(tip,k/6) for k in range(1,7))
    cactus_stem(g,pts,[r*.72*(1-i/(len(pts)-1)*.18) if i<len(pts)-1 else r*.035 for i in range(len(pts))],10,True);sites.append(tip)
 elif form in ['fishbone','rattail','epiphyllum','dragonfruit']:
  count=3 if early else 9;trunk=h*.50
  if form=='dragonfruit':
   stem(g,[(0,0,0),(0,0,h*.75)],h*.043,5,10)
   cactus_stem(g,[(.05*s,0,0),(.05*s,0,h*.4),(.05*s,0,h*.8)],[.07*s,.07*s,.055*s],3,False)
  for j in range(count):
   a=j*2.4;length=h*(.55 if form=='dragonfruit' else 1.15);origin=Z*(trunk if form=='dragonfruit' else .02)
   pts=[origin,origin+radial(a,length*.16,length*.8),origin+radial(a,length*.63,length*.65),origin+radial(a,length,length*.15)]
   if form in ['rattail','dragonfruit']:
    rings=9 if early else 16
    dense=[path(pts,k/(rings-1)) for k in range(rings)];cactus_stem(g,dense,[max(.003,length*(.045 if form=='dragonfruit' else .024)*(1-k/(rings+2))) for k in range(rings)],3 if form=='dragonfruit' else 8,form=='rattail')
   else:
    stem(g,pts,length*.012,0,4)
    for k in range(15):
     q=path(pts,k/15);end=path(pts,(k+1)/15);u=radial(a+math.pi/2,1);w=length*(.12 if form=='fishbone' else .15)*math.sin(math.pi*(k+.5)/15)**.6
     for sign in [-1,1]:
      n=len(g.v)
      if form=='epiphyllum':
       outer=q+u*sign*w;outer2=end+u*sign*w*.98;g.v.extend(map(tuple,[q,end,outer2,outer]));g.uv.update({n:(.5,k/15),n+1:(.5,(k+1)/15),n+2:((sign+1)/2,(k+1)/15),n+3:((sign+1)/2,k/15)});g.face((n,n+1,n+2,n+3),1)
      else:
       outer=(q+end)/2+u*sign*w;g.v.extend(map(tuple,[q,end,outer]));g.uv.update({n:(.5,k/15),n+1:(.5,(k+1)/15),n+2:((sign+1)/2,(k+.5)/15)});g.face((n,n+1,n+2),1)
   sites.append(Vector(pts[-1]))
 elif form in ['spiral','foxtail','paddle','tiger']:
  count=8 if early else 65 if form=='spiral' else 24 if form=='foxtail' else 10 if form=='paddle' else 12
  for j in range(count):
   t=j/count;a=j*2.39996;length=h*(1.0 if form=='paddle' else 1.6 if form=='foxtail' else 1.1 if form=='tiger' else 1.45)*(1-t*.6)
   fleshy(g,Z*h*t*.45,a,length,length*(.37 if form=='paddle' else .30 if form=='tiger' else .20),7 if form=='paddle' and j%3==0 else 1,lift=.45+t*.7,teeth=form in ['spiral','tiger'])
  sites=[Z*h*.67]
 elif form in ['panda','bearpaw']:
  for j in range(2 if early else 5):
   a=j*2.4;tip=radial(a,h*.35,h*(.60+j*.06));stem(g,[(0,0,0),tip],h*.025,0,6)
   for k in range(2 if early else 4):
    q=tip*(.32+k*.16)
    for sign in [-1,1]:
     aa=a+sign*1.15;ll=h*.34;fleshy(g,q,aa,ll,ll*(.31 if form=='bearpaw' else .21),1,lift=.45)
     for claw in range(5 if form=='bearpaw' else 7):
      t=.84 if form=='bearpaw' else .18+claw*.1;c=q+radial(aa,ll*t,ll*(.45*t+.12*math.sin(math.pi*t)))+radial(aa+math.pi/2,ll*.20*((claw-2)/3 if form=='bearpaw' else (-1 if claw%2 else 1)))
      ellipse(g,c,(ll*.035,ll*.035,ll*.025),7,3,5)
   sites.append(tip)
 elif form in ['pearls','burro']:
  for j in range(3 if early else 9):
   a=j*2.4;length=h*2.6;pts=[Z*h*.45,Z*h+radial(a,length*.3),radial(a,length,.018)]
   stem(g,pts,h*.017,0,4)
   for k in range(8 if early else 24):
    q=path(pts,(k+.2)/(8 if early else 24))
    if form=='pearls':ellipse(g,q,(h*.095,)*3,1,5,8)
    else:
     for sign in [-1,1]:fleshy(g,q,a+sign*1.2,h*.28,h*.065,1,lift=.45,teeth=False)
   sites.append(Vector(pts[-1]))
 elif form=='splitrock':
  for j in range(1 if early else 3):
   center=radial(j*2.4,h*1.0 if j else 0,h*.44)
   for sign in [-1,1]:ellipse(g,center+Vector((sign*h*.29,0,0)),(h*.28,h*.51,h*.47),1,10,16)
   sites.append(center+Z*h*.47)
 if not early:
  for j,site in enumerate(sites):
   if form=='dragonfruit':fruit(b,bs,site,form,.13,rng)
   elif form in ['totem','foxtail']:bud(bs,site,h*.055)
   else:
    stalk=form in ['spiral','paddle','panda','bearpaw'];base=site;site=site+Z*(h*.22 if stalk else 0)
    if stalk:stem(g,[base,site],.006,0,5)
    if form in ['panda','bearpaw']:
     from flower_additions_geometry import funnel
     first=len(b.v)
     for k in range(3):
      q=site+radial(k*2.4,.022,-.02);stem(b,[site,q],.002,3,4)
      funnel(b,q,-Z,.01,.035,0,5,.07,.015,.4,.08)
     mark_anchor(b,first,site);bud(bs,site,.020)
    else:flower(b,bs,site,max(.027,min(.17,h*.16)),count=13 if form in ['epiphyllum','splitrock','tiger'] else 9)
 return g,b,bs

def palette(idx):
 p=BY_ID[idx];dryplant=p['group']=='Cacti & succulents' or p['form']=='dragonfruit'
 tissue='succulent' if dryplant else 'parallel' if p['form'] in ['banana','kingpalm','bangalow','fanpalm','walkingpalm','fishtail'] else 'tropical'
 bark='574334' if 'fern' in p['form'] else '938472' if p['form'] in ['guava','banyan'] else '7e6a53'
 fol=[('petiole','809267','smooth',False),('leaf',p['leaf'],tissue,not dryplant),('new tissue' if dryplant else 'young leaf','9da76a',tissue,not dryplant),('deep leaf','3d6540',tissue,not dryplant),('silver underside','b5c3a4',tissue,not dryplant),('bark',bark,'bark',False),('spine','d2c3a1','smooth',False),('leaf edge','9c665a' if dryplant else '9fa779',tissue,False)]
 blo=[('fruit' if p['group']=='Fruit trees' else 'petals',p['color'],'fruit' if p['group']=='Fruit trees' else 'petal',False),('secondary tissue','765253' if p['form']=='banana' else 'b9a16a','fruit',False),('pollen','d3b35c','pollen',False),('calyx',p['leaf'],tissue,False)]
 return {'foliage':fol,'bloom':blo}

def build(idx,phase='mature'):
 p=BY_ID[idx];form=p['form']
 if p['group']=='Cacti & succulents' or form=='dragonfruit':return dry(p,phase)
 if 'fern' in form or form in ['banana','papaya','kingpalm','bangalow','fanpalm','fishtail','walkingpalm']:return crown(p,phase)
 if form=='hooppine':
  # Whorled evergreen architecture from the existing conifer library.
  from plant_full_woody import conifer
  return conifer(79,phase)
 return woody(p,phase)
