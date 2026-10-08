"""Full art pass for original flowers, climbers and kitchen-garden crops.

Independent seedling/juvenile architecture and attachment-local flowers/produce.
Shared primitives express organs; each profile retains its botanical habit.
No Blender scene or file side effects. See plant_full_herb_references.json.
"""
import json
import math
import random
from pathlib import Path
from mathutils import Vector
from botanical_geometry import Geometry
from botanical_forms import radial, tendril
from flower_additions_geometry import frame, petal_in_plane, rays, funnel, stamens
from plant_sample_flowers import _leaf, _stem, _path, _local_ellipsoid
from botanical_additions_forms import sweet_pea_flower, clematis_flower
from fruit_tree_geometry import mark_anchor

IDS = tuple(list(range(12))+[36,37]+list(range(46,68))+list(range(97,106)))
UP=Vector((0,0,1));TAU=math.tau
SPECS=json.loads((Path(__file__).parent/'plant_specs.json').read_text())


class Tissue(Geometry):
    def leaf(self,base,tip,width,mat=1,curl=.12,segments=5,lobed=False):
        base,tip=Vector(base),Vector(tip);d=tip-base
        if d.length<1e-7:return
        if d.length<.06:
            Geometry.leaf(self,base,tip,width,mat,curl,2,lobed);return
        # Petiole, folded midrib and a curved blade; twist varies with attachment.
        pet=base+d*.09
        if width>d.length*.1:self.tube([base,pet],[width*.035,width*.021],0,4)
        _leaf(self,[pet,pet+d*.54+UP*d.length*curl,tip],width,mat,
              segments=max(5,min(10,segments+2)),fold=.20,
              twist=.13*math.sin(base.x*21+base.y*13+base.z*9),lobed=lobed)
    def ellipsoid(self,c,scale,mat=1,rings=5,sides=8,ribs=0):
        first=len(self.v);super().ellipsoid(c,scale,mat,rings,sides,ribs)
        for j in range(rings+1):
            for k in range(sides):self.uv[first+j*sides+k]=(k/sides,j/rings)


def _bud(g,p,axis,length,width,mat=3):
    p=Vector(p);u,v,n=frame(axis);first=len(g.v)
    _local_ellipsoid(g,p+n*length*.43,(width,length*.48,width*.84),(u,n,-v),mat,3,5)
    mark_anchor(g,first,p)


def blade(g,p,d,length,width,mat=1,fold=.18,lobed=False):
    p,d=Vector(p),Vector(d).normalized()
    _leaf(g,[p,p+d*length*.48+UP*length*.17,p+d*length],width,mat,
          segments=8,fold=fold,twist=.12,lobed=lobed)


def compound(g,p,d,length,mat=1,fine=False):
    p,d=Vector(p),Vector(d).normalized();q=p+d*length
    _stem(g,[p,p+d*length*.5+UP*length*.04,q],max(.001,length*.009),segments=4,sides=4)
    side=d.cross(UP).normalized()
    if side.length<.01:side=Vector((1,0,0))
    for j in range(1,5):
        a=p.lerp(q,j/5);ll=length*(.32-.035*j)
        for sign in [-1,1]:
            end=a+side*ll*sign+d*length*.10
            if fine:
                g.tube([a,end],[.001,.0004],0,4)
                for k in range(1,5):
                    b=a.lerp(end,k/5)
                    for s in [-1,1]:g.leaf(b,b+d*ll*.34*s+side*ll*.09*sign,ll*.055,mat,.1,3)
            else:g.leaf(a,end,ll*.39,mat,.16,6,True)
    g.leaf(q-d*length*.12,q+d*length*.17,length*(.018 if fine else .085),mat,.13,6)


def fan(g,p,a,length,mat=1,lobes=7,serrate=False):
    p=Vector(p)
    for k in range(lobes):
        turn=(k-(lobes-1)/2)*(.32 if lobes>=7 else .43)
        ll=length*(.42+.58*math.cos(turn*.78))
        blade(g,p,radial(a+turn,1,.13),ll,ll*(.095 if lobes>=7 else .20),mat,lobed=serrate)


def round_leaf(g,p,r,mat=1,lobes=0,heart=False):
    p=Vector(p);rows=[];n=32
    for j in range(7):
        t=j/6;row=[]
        for k in range(n):
            a=k*TAU/n;profile=1+(.14*math.cos(lobes*a) if lobes else .025*math.sin(a*7))
            if heart:profile*=1-.42*max(0,math.cos(a))**8
            q=p+radial(a,r*t*profile,r*(.16*math.sin(math.pi*t)+.09*math.sin(a)*t-.16*t*t))
            row.append(len(g.v));g.v.append(tuple(q));g.uv[len(g.v)-1]=(.5+(q.x-p.x)/r*.45,.5+(q.y-p.y)/r*.45)
        rows.append(row)
    for left,right in zip(rows,rows[1:]):
        for k in range(n):g.face((left[k],right[k],right[(k+1)%n],left[(k+1)%n]),mat)


def cup(g,p,a,length,width,rise,mat=1,ruffle=.09):
    p=Vector(p);d=radial(a,1);s=radial(a+math.pi/2,1);start=len(g.v);rows,cols=10,7
    for j in range(rows+1):
        t=j/rows
        for k in range(cols):
            q=k/(cols-1)*2-1;w=math.sin(math.pi*t)**.48*width
            v=p+d*length*t*(1-.22*q*q*t)+s*q*w
            v+=UP*(rise*t+length*.14*math.sin(math.pi*t)+w*.28*q*q+ruffle*w*abs(q)**3*math.sin(t*22+q*7))
            g.v.append(tuple(v));g.uv[len(g.v)-1]=((q+1)/2,t)
    for j in range(rows):
        for k in range(cols-1):
            n=start+j*cols+k;g.face((n,n+cols,n+cols+1,n+1),mat)


def head(b,c,axis,r,kind):
    c=Vector(c);u,v,n=frame(axis)
    if kind in ['pea','clematis']:
        (sweet_pea_flower if kind=='pea' else clematis_flower)(b,c,r);return
    if kind=='iris':
        for j in range(3):
            a=j*TAU/3;d=u*math.cos(a)+v*math.sin(a)
            petal_in_plane(b,c,d*.42+n*.9,n-d*.4,r*.96,r*.36,0,.35,.14)
            a+=math.pi/3;d=u*math.cos(a)+v*math.sin(a)
            petal_in_plane(b,c,d-n*.40,n,r*1.1,r*.40,0,.34,.12)
            petal_in_plane(b,c+d*r*.16,d-n*.12,n,r*.5,r*.06,2,.20,.01)
        return
    if kind in ['peony','dahlia','tulip']:
        for ring in range(2 if kind=='tulip' else 5 if kind=='peony' else 7):
            count=3 if kind=='tulip' else 9+ring if kind=='dahlia' else 7+ring
            radius=r*(1-ring*(.10 if kind=='dahlia' else .12))
            for k in range(count):
                a=k*TAU/count+ring*(math.pi/3 if kind=='tulip' else 2.4);d=u*math.cos(a)+v*math.sin(a)
                petal_in_plane(b,c+n*r*ring*.03,d*(.40 if kind=='tulip' else .85)+n*(.85 if kind=='tulip' else .12+ring*.14),n-d*.5,
                               radius,radius*(.62 if kind!='dahlia' else .29),0 if ring%3 else 4,.34,.14 if kind=='peony' else .04)
        if kind=='tulip':stamens(b,c+n*r*.23,n,r,6)
        return
    count={'cosmos':8,'daisy':22,'sunflower':30,'poppy':4,'nasturtium':5,'hollyhock':5,'delphinium':5,'jasmine':5,'winter_jasmine':6,'hydrangea':4}.get(kind,5)
    rays(b,c,n,r,count,.12 if count>10 else .53 if kind in ['poppy','hollyhock'] else .33,0,
         .02,.13 if kind in ['poppy','hollyhock'] else .045,.13 if kind=='cosmos' else 0)
    if kind in ['cosmos','daisy','sunflower','poppy']:
        rr=r*(.39 if kind=='sunflower' else .22 if kind=='poppy' else .25)
        _local_ellipsoid(b,c+n*r*.025,(rr,rr,r*.095),(u,v,n),1,5,16)
        count=90 if kind=='sunflower' else 24
        for k in range(count):
            a=k*2.39996;s=math.sqrt((k+.5)/count);p=c+(u*math.cos(a)+v*math.sin(a))*rr*s+n*r*(.04+.09*math.sqrt(1-s*s))
            b.ellipsoid(p,(r*.018,r*.018,r*.028),2,3,5)
        if kind=='poppy':
            b.ellipsoid(c+n*r*.14,(r*.1,r*.1,r*.12),3,6,10)
            rays(b,c+n*r*.25,n,r*.11,8,.07,3)
    elif kind=='delphinium':
        rays(b,c+n*r*.025,n,r*.34,4,.45,1)
        b.tube([c,c-n*r*.40,c-n*r*.70+v*r*.12],[r*.12,r*.06,.0004],0,6)
    elif kind=='nasturtium':
        b.tube([c,c-n*r*.4-v*r*.4,c-n*r*.95-v*r*.7],[r*.14,r*.06,.0004],0,6)
        stamens(b,c,n,r,5)
    elif kind=='hollyhock':
        funnel(b,c+n*r*.08,n,r*.07,r*.39,2,5,.2,0)
        stamens(b,c+n*r*.25,n,r*.4,8)
    elif kind not in ['hydrangea','jasmine','winter_jasmine']:stamens(b,c,n,r,5)
    else:b.ellipsoid(c+n*r*.08,(r*.08,)*3,2,3,6)


def flower_at(b,buds,p,axis,r,kind):
    first=len(b.v);head(b,p,axis,r,kind);mark_anchor(b,first,p)
    _bud(buds,p,axis,r*.63,r*.19,3)


def stage(phase):return (1.,1.) if phase=='mature' else (.57,.28) if phase=='juvenile' else (.25,.09)


def flowers(idx,phase):
    g,b,buds=Tissue(),Tissue(),Tissue();mature=phase=='mature';s,density=stage(phase);rng=random.Random(4200+idx)
    if idx in [9,10,60,61,62]:
        for j in range(max(1,round((7 if idx>=60 else 4)*density))):
            a=j*2.4;h=(1.18+rng.random()*.2)*s
            points=[radial(a+k*.22,(.055+k*.034)*s,h*k/8) for k in range(9)]
            if idx==62:points=[radial(a+.06*math.sin(k),(.035+k*.066)*s,h*math.sin(k/8*1.85)) for k in range(9)]
            g.tube(points,[.006*s*(1-k*.08) for k in range(9)],0,6)
            for k in range(2,9):
                p=points[k];aa=a+k*1.6
                if idx==9:
                    for sign in [-1,1]:blade(g,p,radial(aa+sign*.6,1,.15),.16*s,.053*s,1+k%2)
                    tendril(g,p,aa)
                elif idx==62:
                    if k%3==0:
                        q=p+radial(aa,.025*s,.005*s);g.tube([p,q],[.0015*s,.0007*s],0,4)
                        for turn in [-.75,0,.75]:blade(g,q,radial(aa+turn,1,.15),(.065 if turn else .085)*s,.020*s,1+k%2)
                else:compound(g,p,radial(aa,1,.2),(.23 if idx>=60 else .21)*s,1+k%2)
                if mature and k%2:
                    c=p+radial(aa,.12,.04);_stem(g,[p,p.lerp(c,.5)+UP*.015,c],.0025,segments=4,sides=5)
                    if idx<60:flower_at(b,buds,c,radial(aa,1,.2),.10 if idx==9 else .17,'pea' if idx==9 else 'clematis')
                    else:
                        for q in range(5 if idx!=62 else 1):
                            f=c+radial(aa+q*2.4,.045,.02*(q%2));g.tube([c,f],[.0015,.0005],0,4)
                            flower_at(b,buds,f,radial(aa+q*.3,.5,1),.035 if idx!=62 else .042,'jasmine' if idx!=62 else 'winter_jasmine')
        return g,b,buds
    if idx==11:
        for j in range(max(1,round(6*density))):
            a=j*2.4;end=radial(a,.55*s,.022*s)
            path=[Vector((0,0,.012*s)),end*.5+radial(a+.7,.06*s,.008*s),end]
            _stem(g,path,.006*s,segments=8,sides=5)
            for k in range(1,5):
                p=_path(path,k/5);c=p+radial(a+k*.7,.055*s,(.09+.02*(k%2))*s)
                _stem(g,[p,c-UP*.05*s,c],.0025*s,segments=4,sides=4);round_leaf(g,c,.084*s,1+k%3)
                if mature and k%2:
                    f=c+radial(a+.8,.10,.036);_stem(g,[p,f-UP*.04,f],.002,segments=4,sides=4)
                    flower_at(b,buds,f,radial(a+.5,.7,.6),.064,'nasturtium')
        return g,b,buds
    if idx==1:
        for j in range(max(1,round(30*density))):
            a=j*2.4;tip=radial(a,.32*math.sqrt((j+.5)/max(1,round(30*density)))*s,(.28+rng.random()*.08)*s)
            _stem(g,[radial(a,.035*s),tip*.52+UP*.026*s,tip],.006*s,5,segments=5,sides=5)
            for k in range(7):
                p=tip*(.19+k*.105)
                for sign in [-1,1]:blade(g,p,radial(a+sign*math.pi/2,1,.24),.10*s,.009*s,4)
            if mature:
                c=tip+radial(a,.035,.32+rng.random()*.14);_stem(g,[tip,tip.lerp(c,.55),c],.0025,segments=6,sides=5)
                first=len(b.v)
                for k in range(6):
                    for q in range(4):
                        a2=q*TAU/4+k*.6;p=c+radial(a2,.012,k*.019)
                        funnel(b,p,radial(a2,.6,.2),.008,.013,0,5,.65,.04)
                mark_anchor(b,first,c);_bud(buds,c,UP,.1,.014,3)
        return g,b,buds
    if idx==5:
        for j in range(max(1,round(12*density))):
            a=j*2.4;r=.58*math.sqrt((j+.5)/max(1,round(12*density)));c=radial(a,r*s,(.66+.30*(1-r/.65))*s)
            pts=[radial(a,.045*s),c*.55+UP*.04*s,c];_stem(g,pts,.018*s,5,segments=7,sides=7)
            for k in range(2,7):
                p=_path(pts,k/8)
                for sign in [-1,1]:blade(g,p,radial(a+k*.62+sign*math.pi/2,1,.26),.25*s,.10*s,1+k%3,lobed=True)
            if mature:
                # Layered broad sterile sepals surrounding the small fertile centre.
                for k in range(31):
                    t=(k+.5)/31;aa=k*2.4;axis=radial(aa,math.sqrt(1-t*t),t)
                    f=c+axis*.195
                    flower_at(b,buds,f,axis,.047,'hydrangea')
        return g,b,buds
    heights={0:.97,2:.42,3:1.75,4:1.48,6:.65,7:.69,8:.83,36:1.10,37:.61,63:1.24,64:.66,65:1.61,66:1.60,67:1.68}
    # Basal rosettes and distichous fans stay visible beneath flower stalks.
    if idx in [2,4,7,8,36,37,64]:
        strap=idx in [8,36,64];count=max(2,round((16 if idx!=64 else 8)*density))
        for j in range(count):
            a=j*2.4;p=radial(a,.034*s);ll=(.65 if idx in [8,36] else .36 if idx in [4,64] else .19)*s
            direction=radial(a,.40 if strap else .94,.80 if strap else .16)
            blade(g,p,direction,ll,ll*(.065 if idx in [8,36] else .15 if idx==64 else .21),1+j%3,lobed=idx==7)
    count={0:7,2:10,3:3,4:3,6:6,7:7,8:5,36:5,37:9,63:4,64:5,65:4,66:5,67:4}[idx]
    for j in range(max(1,round(count*density))):
        a=j*2.4;base=radial(a,.10*s);h=heights[idx]*s*rng.uniform(.82,1.04)
        c=radial(a,.18*s,h);points=[base,base.lerp(c,.45)+radial(a+.7,.025*s),c]
        _stem(g,points,(.012 if idx in [3,63,67] else .005)*s,segments=8,sides=6)
        if idx not in [2,8,36,37,64]:
            for k in range(1,6 if mature else 4):
                p=_path(points,k/7);aa=a+k*2.4
                if idx in [0,6,63]:compound(g,p,radial(aa,1,.22),(.30 if idx in [6,63] else .27)*s,1+k%3,idx==0)
                elif idx in [65,66]:fan(g,p,aa,.25*s,1+k%3,7 if idx==66 else 5)
                elif idx==67:
                    q=p+radial(aa,.05*s,.02*s);g.tube([p,q],[.003*s,.0015*s],0,4);round_leaf(g,q,.12*s,1+k%3,7,True)
                else:blade(g,p,radial(aa,1,.2),(.30 if idx==3 else .17)*s,(.11 if idx==3 else .055)*s,1+k%3,lobed=idx==7)
        if idx==64:
            for k in range(2):blade(g,_path(points,.1+k*.17),radial(a+k*2.8,.6,.8),.43*s,.07*s,1+k)
        if not mature:continue
        if idx in [4,65,66,67]:
            levels=13 if idx==4 else 10 if idx in [65,66] else 7
            for k in range(levels):
                p=_path(points,.55+.42*k/levels)
                for q in range(1 if idx in [4,67] else 4 if idx==66 else 2):
                    aa=a+(.14*math.sin(k) if idx==4 else k*2.4+q*TAU/4);axis=radial(aa,1,-.22 if idx==4 else .13)
                    f=p+axis*(.045 if idx!=67 else .065);g.tube([p,f],[.0025,.001],0,4)
                    rr=(.062 if idx==4 else .039 if idx==66 else .055 if idx==65 else .10)*(1-k/(levels*2.6))
                    if idx==4:
                        first=len(b.v);funnel(b,f,axis,rr*.60,rr*1.25,0,5,.7,.14,.3)
                        # A pale throat with sparse dark spots, built into the lower lip.
                        mouth=f+axis*rr*1.2;u,v,n=frame(axis)
                        petal_in_plane(b,mouth,-v+n*.2,n,rr*.34,rr*.39,1,.10,.07)
                        for speck in range(5):b.ellipsoid(mouth-v*rr*(.06+speck*.045)+u*rr*math.sin(speck*2.4)*.20,(rr*.025,)*3,4,2,4)
                        mark_anchor(b,first,f);_bud(buds,f,axis,rr*.55,rr*.17,3)
                    else:flower_at(b,buds,f,axis,rr,'pea' if idx==66 else 'delphinium' if idx==65 else 'hollyhock')
        elif idx==36:
            for k in range(3):
                f=c+radial(a+k*.53,.10,k*.08);g.tube([c,f],[.005,.002],0,5)
                for q in range(3):
                    p=f+UP*q*.027;axis=radial(a,.86,.5);first=len(b.v)
                    funnel(b,p,axis,.016,.10,0,6,.18,.010,.65,.10)
                    mouth=p+axis*.10;u,v,n=frame(axis)
                    for digit in range(6):
                        aa=digit*TAU/6;petal_in_plane(b,mouth,u*math.cos(aa)+v*math.sin(aa)+n*.6,n,.023,.005,0,.1,.02)
                    mark_anchor(b,first,p);_bud(buds,p,axis,.063,.012,3)
        elif idx==37:
            first=len(b.v);b.ellipsoid(c,(.046,)*3,0,7,12)
            for k in range(65):
                z=1-2*(k+.5)/65;rr=math.sqrt(1-z*z);axis=radial(k*2.4,rr,z);p=c+axis*.046
                b.ellipsoid(p,(.004,.004,.006),2,3,5)
            mark_anchor(b,first,c);_bud(buds,c,UP,.047,.025,3)
        else:flower_at(b,buds,c,radial(a,.35 if idx!=3 else 1,.92 if idx!=3 else .45),{0:.11,2:.065,3:.26,6:.17,7:.14,8:.17,63:.22,64:.14}[idx],{0:'cosmos',2:'daisy',3:'sunflower',6:'peony',7:'poppy',8:'iris',63:'dahlia',64:'tulip'}[idx])
    return g,b,buds


def crop(idx,phase):
    g,b,buds=Tissue(),Tissue(),Tissue();s,density=stage(phase);mature=phase=='mature';rng=random.Random(4700+idx)
    def harvest(p,scale,kind='fruit',anchor=None):
        p=Vector(p);anchor=Vector(anchor) if anchor is not None else p+UP*scale[2];first=len(b.v)
        if kind=='chilli':b.tube([anchor,p,p+Vector((.02,0,-scale[2]))],[scale[0]*.65,scale[0],.0007],0,10)
        else:
            start=len(b.v);b.ellipsoid(p,scale,0,12,24,.075 if idx==49 else 0)
            if idx==50:
                # Taper achenes-bearing strawberry receptacle towards its tip.
                for n in range(start,len(b.v)):
                    v=Vector(b.v[n])-p;t=(v.z/scale[2]+1)/2;v.x*=.55+.45*t;v.y*=.55+.45*t;b.v[n]=tuple(p+v)
                for k in range(35):
                    z=-.86+1.7*(k+.5)/35;t=(z+1)/2;r=math.sqrt(1-z*z)*(.55+.45*t);q=p+radial(k*2.4,scale[0]*r,z*scale[2]);b.ellipsoid(q,(.0016,.0016,.0025),1,2,4)
            if idx==102:
                for n in range(start,len(b.v)):
                    v=Vector(b.v[n])-p;a=math.atan2(v.y,v.x);v.x*=1+.12*math.cos(4*a);v.y*=1+.12*math.cos(4*a);b.v[n]=tuple(p+v)
        top=p+UP*scale[2];_stem(b,[anchor,anchor.lerp(top,.5)+radial(idx,.008,.003),top],.004,3,segments=4,sides=5)
        if idx==55:
            for j in range(3):
                a=j*TAU/3;cup(b,p-UP*scale[2],a,scale[0]*1.05,scale[0]*.63,scale[2]*2.12,3,.03)
            for j in range(5):
                a=j*2.4;_stem(b,[top,top+radial(a,.018,.05),top+radial(a,.037,.025)],.001,1,segments=4,sides=3)
        elif idx==103:
            for j in range(3):cup(b,p-UP*scale[2]*.8,j*TAU/3,scale[0]*.83,scale[0]*.7,scale[2]*1.55,3,.035)
        else:
            for j in range(5):blade(b,top,radial(j*TAU/5,1,-.12),scale[0]*.68,scale[0]*.16,3)
        mark_anchor(b,first,anchor);_bud(buds,anchor,-UP,scale[2]*.44,scale[0]*.27,3)
    if idx in [49,56,59]:
        for j in range(max(1,round(4*density))):
            a=j*2.4;end=radial(a,.78*s,.036*s);pts=[UP*.018*s,end*.45+radial(a+.6,.08*s),end]
            _stem(g,pts,.011*s,segments=9,sides=6)
            for k in range(1,5):
                p=_path(pts,k/5);q=p+radial(a+k*.5,.04*s,.16*s);_stem(g,[p,p.lerp(q,.6),q],.006*s,segments=4,sides=5)
                round_leaf(g,q,(.21 if idx==49 else .17)*s,1+k%3,5,True)
                if mature and k%2:tendril(g,p,a+k*.6)
            if mature:
                p=_path(pts,.82)+UP*.11;harvest(p,(.19,.19,.14) if idx==49 else (.16,.19,.14) if idx==59 else (.045,.055,.16),anchor=_path(pts,.70))
        return g,b,buds
    if idx in [48,97,98,100,101,103]:
        brassica=idx in [100,101,103];count=20 if idx==48 else 14 if idx==97 else 11
        if idx==103:_stem(g,[(0,0,0),(0,0,.42*s),(0,0,.91*s)],.025*s,0,segments=9,sides=8)
        if idx in [100,101]:_stem(g,[(0,0,0),(0,0,.13*s),(0,0,.27*s)],.027*s,0,segments=5,sides=7)
        for j in range(max(3,round(count*density))):
            a=j*2.39996;t=j/max(1,round(count*density));z=(.035+t*.83 if idx==103 else .012)*s
            p=radial(a,.018*s,z);r=(.35 if brassica else .42 if idx in [97,98] else .32)*s
            if idx==103:g.tube([(0,0,z),p],[.006*s,.003*s],0,5)
            if idx==98:
                q=p+radial(a,.16*s,(.24+.08*(1-t))*s);_stem(g,[p,p.lerp(q,.55),q],.012*s,8,segments=6,sides=7)
                _leaf(g,[q,q+radial(a,.13*s,.12*s),q+radial(a,.32*s,-.055*s)],.17*s,1+j%3,segments=10,blunt=True,fold=.28,twist=.18,lobed=True)
            elif idx==97:blade(g,p,radial(a,1,.4),.65*s,.12*s,4,lobed=True)
            else:cup(g,p,a,r*(1-t*.40),r*(.42 if idx==48 else .38),(.09+.20*t)*s,1+j%3,.20 if idx==48 else .07)
        if mature:
            if idx in [100,101]:
                p=UP*.27;first=len(b.v)
                for j in range(24):
                    a=j*2.4;r=.16*math.sqrt((j+.5)/24);c=p+radial(a,r,.08*math.sqrt(max(0,1-(r/.18)**2)))
                    for k in range(7):b.ellipsoid(c+radial(k*2.4,.023,.012*(k%3)),(.027,.027,.024),0 if k%3 else 4,5,7)
                mark_anchor(b,first,p);_bud(buds,p,UP,.07,.04,3)
            elif idx==103:
                for k in range(19):
                    p=radial(k*2.4,.058,.14+k*.035);harvest(p,(.027,.027,.03),anchor=Vector((0,0,p.z)))
            elif idx==97:
                for k in range(4):
                    p=radial(k*2.4,.16,.65+.13*(k%2));_stem(g,[UP*.05,p*.6,p],.012,segments=7,sides=7);first=len(b.v)
                    for ring in range(5):
                        for j in range(9):
                            a=j*TAU/9+ring*1.2;cup(b,p+UP*(ring*.014),a,.10*(1-ring*.12),.044,.085+ring*.011,3 if ring%2 else 4,.02)
                    mark_anchor(b,first,p);_bud(buds,p,UP,.07,.022,3)
            else:
                p=UP*.07;_bud(buds,p,UP,.075,.015,3)
        return g,b,buds
    if idx in [46,50,51,58]:
        for j in range(max(2,round(10*density))):
            a=j*2.4;c=radial(a,.16*s,(.24+rng.random()*.07)*s);_stem(g,[UP*.009*s,c*.45+UP*.025*s,c],.004*s,8 if idx==58 else 0,segments=5,sides=5)
            if idx==46:compound(g,c*.35,radial(a,.6,.7),.35*s,1+j%3,True)
            elif idx==50:
                for k in [-1,0,1]:blade(g,c,radial(a+k*.85,1,.05),.13*s,.054*s,1+j%2,lobed=True)
                if mature and j%3==0:harvest(c-UP*.12,(.037,.037,.05),anchor=c)
            else:blade(g,c*.35,c,.26*s,.084*s,1+j%3,lobed=idx==51)
        if mature and idx in [51,58]:harvest((0,0,.025),(.058,.058,.042),anchor=(0,0,.067))
        if mature and idx==46:_bud(buds,(0,0,.07),UP,.06,.015,3)
        return g,b,buds
    if idx in [55,99,104]:
        count=2 if idx==55 else 9 if idx==99 else 5
        for j in range(max(1,round(count*density))):
            a=j*2.4;base=radial(a,(.14 if idx==55 else .13)*s);h=(1.9 if idx==55 else .60+rng.random()*.5 if idx==99 else .34)*s;top=base+UP*h
            _stem(g,[base,base+UP*h*.55+radial(a,.008*s),top],(.023 if idx!=99 else .012)*s,7 if idx==104 else 0,segments=8,sides=8)
            if idx==99:
                for k in range(6):blade(g,top-UP*(k*.02*s),radial(a+k*2.4,.35,.8),.044*s,.012*s,2)
                if mature and j%3==0:
                    for k in range(6):compound(g,base+UP*h*(.3+k*.10),radial(a+k*2.4,1,.6),.22*(1-k*.08),1,True)
            else:
                for k in range(9 if idx==55 else 6):
                    p=base+UP*(.22+k*.16)*s if idx==55 else top-UP*k*.025*s
                    aa=a+k*math.pi;ll=(.68 if idx==55 else .48)*s
                    _leaf(g,[p,p+radial(aa,ll*.30,ll*.48),p+radial(aa,ll*.80,-ll*.10 if idx==55 else ll*.18)],(.055 if idx==55 else .027)*s,1+k%3,segments=12,fold=.3,twist=.08)
            if mature and idx==55:
                first=len(b.v)
                for k in range(7):
                    end=top+radial(k*2.4,.13,.26);b.tube([top,end],[.004,.001],2,5)
                    for q in range(5):b.ellipsoid(top.lerp(end,.25+q*.14),(.007,.007,.013),2,3,5)
                mark_anchor(b,first,top);_bud(buds,top,UP,.12,.013,3)
                for k in range(2):harvest(base+radial(a+k*math.pi,.065,.75+k*.30),(.055,.052,.18),anchor=base+UP*(.60+k*.30))
            elif mature:_bud(buds,top,UP,.04,.009,3)
        return g,b,buds
    # Branching herbs, pods, nightshades and seven-finger hemp leaves.
    height={47:1.02,52:1.05,53:.79,54:.40,57:.68,102:.72,105:1.72}[idx]
    count=4 if idx in [52,105] else 6
    for j in range(max(1,round(count*density))):
        a=j*2.4;tip=radial(a,.27*s,height*s*rng.uniform(.83,1.04));pts=[radial(a,.025*s),tip*.5+radial(a+.5,.03*s),tip]
        _stem(g,pts,.012*s,segments=7,sides=6)
        for k in range(1,7 if mature else 4):
            p=_path(pts,k/8);aa=a+k*2.4
            if idx==47:compound(g,p,radial(aa,1,.13),.28*s,1+k%3)
            elif idx==105:fan(g,p,aa,.29*s,1+k%3,7,True)
            else:
                for sign in [-1,1] if idx in [52,54] else [1]:blade(g,p,radial(aa+sign*.65,1,.18),(.26 if idx==53 else .16)*s,(.10 if idx==53 else .054 if idx in [52,54] else .040)*s,1+k%3)
            if idx==52 and mature:tendril(g,p,aa)
            if not mature:continue
            if idx==52 and k%2:harvest(p+radial(aa,.075,-.08),(.024,.028,.105),anchor=p)
        if mature:
            if idx==105:
                for turn in [a,a+math.pi]:fan(g,_path(pts,.90),turn,.17,2,7,True)
            if idx==52:tendril(g,_path(pts,.97),a)
            anchor=_path(pts,.78)
            if idx==47:
                for k in range(3):harvest(anchor+radial(a+k*2.4,.07,-.07-k*.02),(.065,)*3,anchor=anchor)
            elif idx in [53,57,102]:harvest(anchor-UP*.10,(.065,.065,.13) if idx==53 else (.022,.022,.10) if idx==57 else (.068,.068,.085),'chilli' if idx==57 else 'fruit',anchor)
            else:_bud(buds,tip,UP,.04,.012,3)
    return g,b,buds


def build(idx,phase='mature'):
    assert idx in IDS and phase in ['mature','seedling','juvenile']
    return crop(idx,phase) if SPECS[idx][1]=='Produce' else flowers(idx,phase)


def palette(idx):
    name=SPECS[idx][0];crop_plant=SPECS[idx][1]=='Produce'
    leaf={1:'7d8b78',8:'628f78',37:'8c9c85',97:'819483',100:'668d7b',101:'7a9983',104:'688e86'}.get(idx,'547c46')
    young={48:'a4b975',8:'8eaa8e',104:'a8b99c'}.get(idx,'8caa68')
    primary={1:'8870ad',3:'e7b447',7:'da5b42',47:'c84732',49:'c7883e',50:'b83d45',51:'c15169',52:'6f9748',53:'4e3558',55:'d4b763',56:'4d783d',57:'c63928',58:'82364d',59:'c8b568',64:'41233e',98:'b24d55',100:'4a714b',101:'e4dec7',102:'c54430',103:'81a16a'}.get(idx,SPECS[idx][2])
    fol=[('stem','8eab76' if idx not in [58,98] else 'a35261','smooth',False),('leaf',leaf,'leaf',True),('young leaf',young,'leaf',True),('deep leaf','38613c','leaf',True),('silver leaf','8eaa96','leaf',True),('bark','746555','bark',False),('sheath','b8b69a','smooth',False),('cream sheath','dbdac1','smooth',False),('red petiole' if idx in [58,98] else 'accent leaf','b94d59' if idx in [58,98] else young,'smooth' if idx in [58,98] else 'leaf',idx not in [58,98])]
    bloom=[('fruit' if crop_plant else 'petals',primary,'fruit' if crop_plant else 'petal',False),('disk' if idx in [3,7] else 'cream','49372b' if idx in [3,7] else 'ede2c5','pollen' if idx in [3,7] else 'petal',False),('pollen','c9a345','pollen',False),('calyx',leaf,'leaf',False),('fruit shade' if crop_plant else 'secondary petals','557545' if crop_plant else '783f70' if idx==4 else primary,'fruit' if crop_plant else 'petal',False)]
    return {'foliage':fol,'bloom':bloom}
