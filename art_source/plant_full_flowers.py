"""Full flower art pass: 64 botanical assets, excluding six approved studies.

Pure deterministic meshes, Z-up metres. Branch architecture and inflorescence
counts retain the existing shrub identities; new blades, corollas and juvenile
plants are authored here. No scene, export, shader or runtime setting is touched.
"""
import math
import random
from functools import partial
from mathutils import Vector
from botanical_geometry import Geometry
from fruit_tree_geometry import mark_anchor
from flower_additions_data import FLOWER_ADDITIONS
from flower_bush_geometry import PROFILES, profile, point_on
from plant_sample_flowers import _path, _stem, _leaf, _local_ellipsoid

TAU=math.tau
UP=Vector((0,0,1))
IDS=[i for i in range(148,218) if i not in (148,149,158,174,198,212)]
ROWS={row['id']:row for row in FLOWER_ADDITIONS}


def frame(axis):
    n=Vector(axis).normalized()
    u=UP.cross(n).normalized() if abs(n.z)<.95 else Vector((1,0,0))
    return u,n.cross(u).normalized(),n


def petal_in_plane(g,c,d,n,length,width,mat=0,cup=.12,ruffle=.04,notch=0,tiny=False):
    """Spoon-shaped lamina with a raised midrib, rolled edge and lobed tip."""
    c=Vector(c);d=Vector(d).normalized();n=Vector(n).normalized()
    side=n.cross(d).normalized();n=d.cross(side).normalized()
    rows=6 if length>.022 and not tiny else 3
    cols=5 if length>.022 and not tiny else 3
    first=len(g.v)
    for j in range(rows+1):
        t=j/rows;w=width*max(0,math.sin(math.pi*t))**.56
        for k in range(cols):
            q=k/(cols-1)*2-1
            reach=length*(t-notch*(1-abs(q))**3*t**10)
            bow=length*cup*(math.sin(math.pi*t)*.75+t*t*.30)
            edge=-w*.22*q*q+ruffle*w*abs(q)**3*math.sin(t*22+q*9)
            p=c+d*reach+side*w*q+n*(bow+edge)
            g.v.append(tuple(p));g.uv[len(g.v)-1]=((q+1)/2,t)
    for j in range(rows):
        for k in range(cols-1):
            a=first+j*cols+k;g.face((a,a+cols,a+cols+1,a+1),mat)


def petal(g,c,direction,length,width,mat=0,cup=.12,ruffle=.04,notch=0,low_detail=False,tiny=False):
    d=Vector(direction).normalized();side=d.cross(UP).normalized()
    if side.length<.01:side=Vector((1,0,0))
    n=side.cross(d).normalized()
    if n.z<0:n=-n
    petal_in_plane(g,c,d,n,length,width,mat,cup,ruffle,notch,tiny or low_detail)


def rays(g,c,axis,r,count,width=.32,mat=0,droop=0,ruffle=.04,notch=0,start=0,tiny=False):
    u,v,n=frame(axis)
    for k in range(count):
        a=start+k*TAU/count
        d=u*math.cos(a)+v*math.sin(a)-n*droop
        petal_in_plane(g,c,d,n,r,r*width,mat,.20,ruffle,notch,tiny)


def funnel(g,c,axis,r,length,mat=0,lobes=5,flare=.65,ruffle=.04,base_radius=.14,curve=0):
    """A fused corolla whose final ring forms distinct flared/recurved lobes."""
    c=Vector(c);u,v,n=frame(axis);first=len(g.v)
    rows=7 if r>.018 else 4;sides=lobes*4
    for j in range(rows+1):
        t=j/rows
        for k in range(sides):
            a=k*TAU/sides;lobe=(1+math.cos(a*lobes))*.5
            radius=r*(base_radius+(1-base_radius)*((1-flare)*t+flare*t**3))
            radius*=1+.14*lobe*t**6
            z=length*t+ruffle*r*math.cos(a*lobes)*t**7
            p=c+n*z+u*(curve*r*math.sin(math.pi*t))
            p+=(u*math.cos(a)+v*math.sin(a))*radius
            g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
    for j in range(rows):
        for k in range(sides):
            a=first+j*sides+k;b=first+j*sides+(k+1)%sides
            g.face((a,b,b+sides,a+sides),mat)


def stamens(g,c,axis,r,count=7,mat=2,low_detail=False):
    c=Vector(c);u,v,n=frame(axis)
    for k in range(count):
        a=k*2.39996;out=u*math.cos(a)+v*math.sin(a)
        end=c+out*r*.19+n*r*(.36+.10*(k%3)/2)
        g.tube([c,end],[max(.00012,r*.013),max(.00009,r*.007)],mat,3 if low_detail else 4)
        g.ellipsoid(end,(r*.039,r*.027,r*.051),mat,2,4 if low_detail else 5)


def blade(g,base,heading,length,width,mat=1,shape='lance',tilt=.25,small=False):
    """Blade silhouettes distinguish entire, serrate, three-lobed and strap leaves."""
    base=Vector(base);d=Vector((math.cos(heading),math.sin(heading),tilt)).normalized()
    side=d.cross(UP).normalized();normal=side.cross(d).normalized()
    if normal.z<0:normal=-normal
    rows=2 if small==2 else 4 if small else 7;first=len(g.v)
    for j in range(rows+1):
        t=j/rows
        power=.45 if shape in ('oval','strap','round') else .76
        w=width*max(0,math.sin(math.pi*t))**power
        if shape=='lobed':w*=.60+.40*math.cos(t*6*math.pi)
        elif shape=='toothed':w*=1+(.09 if j%2 else -.05)
        mid=base+d*(length*t)+normal*length*(.15*math.sin(math.pi*t)-.09*t*t)
        for k in range(3):
            q=k-1;p=mid+side*(w*q)+normal*w*(.16-.24*abs(q))
            g.v.append(tuple(p));g.uv[len(g.v)-1]=(k*.5,t)
    for j in range(rows):
        a=first+j*3;g.face((a,a+3,a+4,a+1),mat);g.face((a+1,a+4,a+5,a+2),mat)


def fan_leaf(g,base,heading,length,mat=1,lobes=7,deep=False):
    """A continuous palmate blade with radiating folds and a basal sinus."""
    base=Vector(base);d=Vector((math.cos(heading),math.sin(heading),.25)).normalized()
    side=d.cross(UP).normalized();normal=side.cross(d).normalized()
    if normal.z<0:normal=-normal
    hub=base+d*length*.18;g.tube([base,hub],[length*.012,length*.006],0,4)
    first=len(g.v);g.v.append(tuple(hub));g.uv[first]=(.5,.15)
    outline=[]
    count=lobes*4+1
    trilobes=[(-2.15,.18),(-1.64,.42),(-1.36,.72),(-1.12,.94),(-.83,.64),(-.60,.44),(-.27,.77),(0,1),(.27,.77),(.60,.44),(.83,.64),(1.12,.94),(1.36,.72),(1.64,.42),(2.15,.18)]
    for k in range(len(trilobes) if lobes==3 and deep else count):
        if lobes==3 and deep:a,r=trilobes[k];r*=length
        else:
            a=-2.28+k/(lobes*4)*4.56
            r=length*(.64+.36*math.cos(a*.64))
            r*=1-(.48 if deep else .14)*(1-math.cos(k*math.pi/2))*.5
        p=hub+d*math.cos(a)*r+side*math.sin(a)*r*.73
        p+=normal*length*(.06+.055*math.cos(k*math.pi/2))
        outline.append(len(g.v));g.v.append(tuple(p))
        g.uv[len(g.v)-1]=(.5+math.sin(a)*r/(length*2),.15+math.cos(a)*r/(length*1.3))
    for a,b in zip(outline,outline[1:]):g.face((first,a,b),mat)


def herb_leaf(g,idx,base,heading,length,mat=1,small=False):
    base=Vector(base);d=Vector((math.cos(heading),math.sin(heading),.25)).normalized()
    if idx in (162,197):
        fan_leaf(g,base,heading,length,mat,7 if idx==197 else 5,idx==162);return
    if idx in (164,185):
        tip=base+d*length;g.tube([base,tip],[length*.012,length*.003],0,4)
        for j in range(5 if idx==164 else 4):
            p=base.lerp(tip,.12+j*.17)
            for sign in (-1,1):
                a=heading+sign*.90;ll=length*(.30-j*.027)
                blade(g,p,a,ll,ll*(.045 if idx==185 else .08),mat,'needle',.08,True)
                if idx==164:
                    for tooth in range(2):
                        q=p+Vector((math.cos(a),math.sin(a),.08))*ll*(.40+tooth*.26)
                        blade(g,q,a+sign*.7,ll*.25,ll*.025,mat,'needle',.08,True)
        return
    if idx in (168,180,181,188,189,190,191):
        tip=base+d*length*.28;g.tube([base,tip],[length*.014,length*.006],0,4)
        lobes=7 if idx==190 else 3
        for k in range(lobes):
            a=heading+(k-(lobes-1)/2)*(.33 if idx==190 else .7)
            ll=length*(.72-abs(k-(lobes-1)/2)*.06)
            if idx in (188,189):
                blade(g,tip,a,ll,ll*.27,mat,'lobed',.23,small)
            elif idx==191:
                end=tip+Vector((math.cos(a),math.sin(a),.23))*ll
                g.tube([tip,end],[length*.008,length*.003],0,3)
                for node in range(3):
                    for sign in (-1,1):blade(g,tip.lerp(end,.25+node*.27),a+sign*.85,ll*.35,ll*.11,mat,'toothed',.2,True)
            else:blade(g,tip,a,ll,ll*(.10 if idx==190 else .21),mat,'toothed' if idx==190 else 'lobed',.2,small)
        return
    if idx==196:
        fan_leaf(g,base,heading,length,mat,5,False);return
    shape='oval' if idx in (165,166,179,187) else 'strap' if idx in (171,172,173,175,176,177,178) else 'lance'
    ratio={159:.055,160:.23,161:.085,165:.22,166:.21,167:.17,169:.15,170:.14,171:.028,172:.020,173:.045,175:.016,176:.074,177:.045,178:.075,179:.27,182:.08,183:.09,184:.13,186:.22,187:.28,192:.11,193:.13,194:.16,195:.105}.get(idx,.16)
    blade(g,base,heading,length,length*ratio,mat,shape,1.65 if shape=='strap' else .30,small)


def bush_leaf(g,base,heading,length,p,material=1,tilt=.25):
    """Retain shrub-specific phyllotaxy; replace flat blades with folded organs."""
    base=Vector(base);d=Vector((math.cos(heading),math.sin(heading),tilt)).normalized()
    join=base+d*length*.10;g.tube([base,join],[length*.012,length*.006],0,3)
    shape=p['leaf_shape'];width=length*p['leaf_width']
    if shape=='ternate':
        for turn in (-.72,0,.72):blade(g,join,heading+turn,length*.82,width*.82,material,'oval',tilt,True)
    elif shape=='pinnate':
        tip=join+d*length*.9;g.tube([join,tip],[length*.008,length*.003],0,3)
        for node in range(3):
            for sign in (-1,1):blade(g,join.lerp(tip,.20+node*.27),heading+sign*.96,length*.28,width*.42,material,'lance',tilt*.5,2)
        blade(g,tip-d*length*.1,heading,length*.24,width*.45,material,'lance',tilt,2)
    elif shape=='lobed' and p['leaf_length']>.08:
        fan_leaf(g,join,heading,length*.85,material,3,True)
    else:blade(g,join,heading,length,width*1.08,material,shape,tilt,True)


def orchid_foliage(row,phase):
    idx=row['id'];g=Geometry();centres=[];h=row['height']
    age={'seedling':.20,'juvenile':.52,'mature':1}[phase];h*=age
    mature=phase=='mature';rng=random.Random(idx*617)
    monopodial=idx==152;terrestrial=idx in (156,157)
    clumps=1 if not mature or monopodial or terrestrial else 3
    tops=[]
    for k in range(clumps):
        a=.4+k*2.39996;out=Vector((math.cos(a),math.sin(a),0));base=out*h*.08
        if monopodial:
            top=base+UP*h*.67;_stem(g,[base,base+UP*h*.32,top],h*.020,segments=6)
            for j in range(10 if mature else 4):
                p=base+UP*h*(.08+j*.053);side=(-1 if j%2 else 1)
                _leaf(g,[p,p+out*h*.18*side+UP*h*.10,p+out*h*.31*side-UP*h*.025],h*.025,2 if j>7 else 1,segments=7,blunt=True)
        elif terrestrial:
            top=base
            for j in range(7 if mature else 3):herb_leaf(g,169,base,j*2.39996,h*(.29+j%2*.04),1,not mature)
        else:
            cane=idx==155;top=base+UP*h*(.37 if cane else .18)
            g.tube([base,base+UP*h*.08,top],[h*.035,h*(.05 if cane else .065),h*.023],1,8)
            for j in range(3 if cane else 2):
                sign=-1 if j%2 else 1;ll=h*(.35 if cane else .55)
                _leaf(g,[top,top+out*ll*.22*sign+UP*ll*.73,top+out*ll*.73*sign+UP*ll*.30],ll*(.11 if idx==153 else .08),2 if k==2 else 1,segments=8,blunt=idx in (151,155))
        if not terrestrial:
            for j in range(4 if mature else 2):
                angle=a+j*2.4;outroot=Vector((math.cos(angle),math.sin(angle),0))
                start=base+UP*h*(.31 if monopodial else .05)
                end=base+outroot*h*.18+UP*.003
                _stem(g,[start,start+outroot*h*.11,end],h*.009,3,5,5)
        tops.append(top)
    if not mature:return g,centres
    count=row['flower_count'];r=row['bloom_radius']
    stems=1 if idx in (156,157,152) else 3 if idx in (150,155) else 2
    for k in range(stems):
        a=.5+k*2.39996;out=Vector((math.cos(a),math.sin(a),0));base=tops[k%len(tops)]
        if idx in (150,151,153,154):base=Vector((base.x,base.y,h*.12))
        tip=out*h*(.26 if idx in (150,154,155) else .13)+UP*h*.87
        curve=[base,base+UP*h*.45,tip+UP*h*.07,tip]
        _stem(g,curve,h*.008,segments=9,sides=6)
        for j in range(math.ceil(count/stems)):
            t=.40+.53*(j+.4)/math.ceil(count/stems);attach=_path(curve,t)
            turn=a+j*(1.1 if idx==157 else 2.2)
            face=Vector((math.cos(turn),math.sin(turn),.10))
            reach=r*(1.2 if idx==150 else .8)
            c=attach+face*reach
            _stem(g,[attach,attach+face*reach*.45+UP*r*.14,c],h*.002,segments=3,sides=4)
            centres.append((c,face,r))
        if terrestrial:
            for j in range(3):herb_leaf(g,169,_path(curve,.13+j*.16),a+j*2.4,h*(.18-j*.035),1)
    return g,centres[:count]


def herb_foliage(row,phase):
    idx=row['id'];g=Geometry();centres=[];mature=phase=='mature'
    h=row['height']*{'seedling':.18,'juvenile':.48,'mature':1}[phase]
    rng=random.Random(731*idx);count=row['flower_count'];r=row['bloom_radius']
    bulbs=idx in (171,172,173,175,176,177,178,179)
    basal=bulbs or idx in (163,170,180,181,188,189,190,191,194,196,197)
    basal_count=3 if phase=='seedling' else 6 if phase=='juvenile' else (6 if idx==179 else 10)
    for j in range(basal_count if basal else 4):
        a=j*2.39996;out=Vector((math.cos(a),math.sin(a),0))
        ll=h*(.52 if bulbs else .54 if idx in (180,181) else .30 if basal else .17)*rng.uniform(.83,1.12)
        base=out*h*.025+UP*.003
        herb_leaf(g,idx,base,a,ll,2 if j==basal_count-1 else 1,not mature)
    if phase=='seedling':return g,centres
    spikes=idx in (176,177,179,182,184,192,194)
    stems=(3 if bulbs or spikes else 4) if mature else 2
    if idx in (173,175,178):stems=count if mature else 2
    if idx==195:stems=1
    if idx==189:stems=3 if mature else 2
    if idx==196:stems=count if mature else 2
    for k in range(stems):
        a=.22+k*2.39996;out=Vector((math.cos(a),math.sin(a),0));side=Vector((-out.y,out.x,0))
        base=out*h*.045
        height=h*(.90-.052*(k%3))
        reach=h*(.26 if idx in (177,179,189) else .14 if not bulbs else .10)
        if idx==189:
            curve=[base,base+UP*h*.82,base+out*h*.34+UP*h*.94,base+out*h*.41+UP*h*.61]
        elif idx in (177,179):
            curve=[base,base-out*h*.04+UP*h*.76,base+out*reach+UP*height,base+out*reach*1.20+UP*height*.83]
        else:curve=[base,base-out*h*.025+UP*height*.34,base+out*reach*.65+UP*height*.80,base+out*reach+UP*height]
        _stem(g,curve,max(.00055,h*(.010 if idx in (176,195) else .0045)),segments=8,sides=6)
        if not bulbs and idx not in (170,180,181,190,191,196,197):
            for j in range(7 if idx==195 else 5):
                p=_path(curve,.16+j*(.095 if idx==195 else .12))
                pairs=2 if row['foliage']=='opposite' else 1
                for pair in range(pairs):
                    herb_leaf(g,idx,p,a+j*2.39996+pair*math.pi,h*(.19-j*.019),2 if j==4 else 1,not mature)
        if idx in (188,189,191):
            for j in range(3):herb_leaf(g,idx,_path(curve,.16+j*.14),a+j*2.4,h*(.24-j*.03),1,not mature)
        if not mature:continue
        per=len(range(k,count,stems))
        for j in range(per):
            if spikes:
                t=.43+.52*(j+.4)/per;attach=_path(curve,t)
                angle=a+(0 if idx in (177,179) else j*2.39996)
                axis=Vector((math.cos(angle),math.sin(angle),-.35 if idx in (177,179,194) else .08))
                c=attach+Vector((math.cos(angle),math.sin(angle),0))*r*1.15
                if idx in (177,179):c-=UP*r*.28;axis=Vector((axis.x*.16,axis.y*.16,-1))
            elif idx==189:
                t=.36+.60*(j+.4)/per;attach=_path(curve,t);c=attach-UP*r*1.5;axis=Vector((0,0,-1))
            elif j==0:
                attach=_path(curve,1);c=attach;axis=(out*.22+UP).normalized()
                if idx in (173,188,190):axis=(out+UP*(.05 if idx==173 else -.40)).normalized()
            else:
                attach=_path(curve,.42+.12*(j%3))
                c=_path(curve,1)+side*((-1 if j%2 else 1)*h*(.055+j*.014))-UP*h*(.055+j*.040)
                axis=(out*.20+UP).normalized()
            if idx==193:
                angle=j*2.39996;c=_path(curve,1)+Vector((math.cos(angle),math.sin(angle),0))*r*(.9+math.sqrt(j)*.60)-UP*r*(j%3)*.35
                attach=_path(curve,.83);axis=UP
            if idx==195:axis=(out+side*((j-2)*.4)+UP*.4).normalized()
            if (c-attach).length>.00001:
                _stem(g,[attach,attach.lerp(c,.58)+UP*r*.22,c],max(.00035,h*.0018),segments=4,sides=4)
            if idx==181:
                for whorl in range(3):herb_leaf(g,idx,c-UP*h*.09,a+whorl*TAU/3,h*.10,1,True)
            centres.append((c,axis,r))
    return g,centres


def palette(idx):
    row=ROWS[idx];p=profile(idx) if idx>=198 else {}
    leaf={150:'628654',151:'779761',152:'3f7150',153:'416c40',154:'669155',155:'496842',156:'5d8550',157:'718856',159:'81976b',160:'65864e',161:'648c61',163:'6f9273',164:'718c75',168:'92a59b',173:'819d87',175:'477444',176:'56824f',177:'618755',178:'689675',179:'4b7945',184:'8c9b89',189:'628a78',190:'426d48',191:'426f44',195:'3e7140',197:'88a47a'}.get(idx,'698b56')
    leaf=p.get('green',leaf);young=p.get('young','9cab73');bark=p.get('bark','778952')
    primary=row['color'];lip={150:'bd9735',151:'b0609d',152:'4c629a',153:'694ba0',154:'836447',155:'9b7099',156:'5b3a26',157:'813d87',165:'af6734',166:'392c25',167:'9c4539',169:'bc7c25',181:'332537',185:'447473',186:'985e26',188:'ece2cf',190:'dacfa3',193:'893e87',195:'ae4263',199:'d994ac',202:'d7b753',205:'d29922',206:'b47629',208:'a96565',209:'973b6d',210:'e2c8d9',214:'a6b55b',216:'705541',217:'eee1bd'}.get(idx,primary)
    cream='f2ecdd';sepal={153:'a6a66c',154:'bec489',208:'9b6264',214:'9ca357'}.get(idx,leaf)
    pollen='392b32' if idx==181 else 'ac763a' if idx==195 else 'd6af4c'
    foliage=[('stem',bark,'bark' if idx>=198 else 'smooth',False),('leaf',leaf,'leaf',True),('young leaf',young,'leaf',True),('roots','d1ccb4','smooth',False)]
    bloom=[('petals',primary,'petal',False),('cream petals',cream,'petal',False),('pollen',pollen,'pollen',False),('calyx',leaf,'leaf',False),('sepals',sepal,'leaf',False),('flower lip',lip,'petal',False),('secondary petals',primary,'petal',False)]
    return {'foliage':foliage,'bloom':bloom}

def bush_foliage(row,phase='mature'):
    idx=row['id'];p=profile(idx);g=Geometry();g.attachment_paths=[]
    g.bush_shoots=[];g.bush_canes=[]
    rng=random.Random(idx*7919+181+{'mature':0,'seedling':13,'juvenile':29}[phase])
    early=phase!='mature';h=row['height']*({'seedling':.17,'juvenile':.48}.get(phase,1))
    radius=p['radius']*h*(.72 if early else 1)
    canes=1 if phase=='seedling' else 3 if early else p['canes']
    levels=1 if phase=='seedling' else 2 if early else p['levels']
    anchors=[]
    arch=p['habit'] in ['tall_arch','arch','low_arch','fountain','cascade','airy_arch','pendulous']
    sparse=idx in [205,206] and not early

    def register(path,heading,terminal=True):
        path=[Vector(v) for v in path];axis=Vector((math.cos(heading),math.sin(heading),.28)).normalized()
        g.bush_shoots.append((path,heading,terminal))
        anchors.append((path[-1],axis));g.attachment_paths.append(path)

    def leafy(path,heading,count,terminal=False):
        path=[Vector(v) for v in path]
        if sparse:count=1 if idx==205 else 2
        for node in range(count):
            t=.10+.88*(node+.8)/count
            location=point_on(path,t)
            turn=heading+node*2.39996
            length=h*p['leaf_length']*rng.uniform(.80,1.12)
            if sparse:length*=.62
            if p['arrangement']=='rosette':
                # Crowded terminal foliage, with coppery Pieris tips above green leaves.
                location=point_on(path,.62+.35*(node+.3)/count)
                sides=2
            elif p['arrangement']=='whorled':sides=3
            elif p['arrangement'] in ['opposite','decussate']:sides=2
            else:sides=1
            for side in range(sides):
                angle=turn+side*TAU/sides
                if p['arrangement']=='decussate':angle=heading+node*math.pi/2+side*math.pi
                mat=2 if node>=count-1 and (idx==200 or rng.random()<.35) else 1
                tilt=rng.uniform(.16,.68) if idx in [199,200,209,210,213] else rng.uniform(-.12,.45)
                bush_leaf(g,location,angle,length,p,mat,tilt)

    for cane in range(canes):
        angle=cane*2.39996+rng.uniform(-.16,.16)
        direction=Vector((math.cos(angle),math.sin(angle),0))
        base=direction*h*rng.uniform(.012,.050)
        amplitude=rng.uniform(.78,1.0)
        if arch:
            reach=radius*amplitude
            end_height={'tall_arch':.63,'arch':.42,'low_arch':.32,'fountain':.47,'cascade':.25,'airy_arch':.37,'pendulous':.29}[p['habit']]
            peak=.74 if idx not in [202,205] else .86
            path=[base+direction*reach*(t/10)**1.32+UP*h*amplitude*(peak*math.sin(math.pi*t/10)+end_height*t/10) for t in range(11)]
        else:
            # Variable-height basal leaders feed a rounded crown rather than a repeated vase.
            z=h*(.94 if cane==0 else .48+.43*((cane*.61803398875)%1))*amplitude
            if p['habit'] in ['slender','twiggy','upright']:z=h*(.76+.20*(cane%3)/2)*amplitude
            lean=radius*(.18 if idx==216 else .24 if idx in [198,215] else .40)
            path=[base,base+direction*lean*.25+UP*z*.25,base+direction*lean*.66+UP*z*.65,base+direction*lean+UP*z]
        g.tube(path,[h*.012*(1-.90*t/(len(path)-1)) for t in range(len(path))],0,7)
        g.bush_canes.append(path)
        leafy(path,angle,3 if early else 10 if arch else 5)
        if arch:register(path,angle,False)
        for level in range(levels):
            t=.22+.65*(level+.5)/levels
            start=point_on(path,t)
            for side in range(1 if early else 2):
                heading=angle+(-1 if side else 1)*rng.uniform(.45,1.25)
                outward=Vector((math.cos(heading),math.sin(heading),0))
                if arch:
                    reach=radius*(.13 if idx==205 else .23)*rng.uniform(.7,1.15)
                    lift=h*(.13 if idx==202 else .07)
                    tip=start+outward*reach+UP*(lift-h*(.08 if idx in [207,212] else .035))
                    shoot=[start,start+outward*reach*.45+UP*lift,tip]
                else:
                    height=start.z/h
                    envelope=math.sqrt(max(.06,1-((height-.49)/.57)**2))
                    reach=radius*envelope*rng.uniform(.62,1.0)
                    tip=outward*reach+UP*(start.z+h*rng.uniform(.05,.13))
                    if p['habit']=='tiered':tip.z=start.z+h*.075
                    if p['habit']=='tangled':tip+=Vector((rng.uniform(-.12,.12)*h,rng.uniform(-.12,.12)*h,0))
                    shoot=[start,start.lerp(tip,.5)+UP*h*.025,tip]
                _stem(g,shoot,h*.0045,segments=5,sides=5)
                leafy(shoot,heading,3 if early else 5)
                register(shoot,heading)
                if idx==206 and not early:
                    spine=point_on(shoot,.43)
                    g.tube([spine,spine+outward*h*.04+UP*h*.02],[h*.003,0.0001],0,4)
                if not early:
                    # Fan actual leafy shoots into the crown, retaining gaps and tapered twigs.
                    forks=1 if idx==205 else 2 if idx in [207,213,215,216] else 3
                    for fork in range(forks):
                        location=point_on(shoot,.43+fork*.17)
                        turn=heading+(-.80 if fork%2 else .80)+rng.uniform(-.20,.20)
                        d=Vector((math.cos(turn),math.sin(turn),0))
                        length=h*(.105 if idx in [198,200,201,202] else .075 if idx==216 else .135)*rng.uniform(.8,1.2)
                        tip=location+d*length+UP*h*(.025 if arch else .060)
                        twig=[location,location.lerp(tip,.5)+UP*h*.014,tip]
                        _stem(g,twig,h*.0016,segments=4,sides=3)
                        leafy(twig,turn,4 if idx not in [199,200,209,210,213] else 4 if idx==213 else 6)
                        register(twig,turn)
    return g,anchors

def bush_blooms(row,g,anchors):
    """Branch-bound inflorescences with their real habit and attachment positions."""
    idx=row['id'];h=row['height'];r=row['bloom_radius'];centres=[]
    shoots=g.bush_shoots
    # Select around the whole crown; avoid the old modular stride hitting only a few shoots.
    terminal=[s for s in shoots if s[2]] or shoots
    def choose(k,total):return terminal[min(len(terminal)-1,int((k+.5)*len(terminal)/total))]
    def add(attachment,centre,axis,radius=r):
        attachment=Vector(attachment);centre=Vector(centre);axis=Vector(axis).normalized()
        g.tube([attachment,(attachment+centre)*.5,centre],[max(.00035,h*.0010),max(.00025,h*.0006),.0002],0,4)
        centres.append((centre,axis,radius))
    def exposed(path,heading,offset=.035):
        axis=Vector((math.cos(heading),math.sin(heading),.45)).normalized()
        return path[-1]+axis*h*offset,axis

    if idx in [205,206,207,216]:
        # Older wood / cane flowers form ribbons, not a few dots atop a green tree.
        paths=g.bush_canes if idx in [205,207] else [s[0] for s in shoots]
        total={205:240,206:100,207:85,216:160}[idx]
        for k in range(total):
            path=paths[k%len(paths)];layer=k//len(paths);layers=math.ceil(total/len(paths))
            t=.29+.65*(layer+.35)/layers
            a=k*2.39996;axis=Vector((math.cos(a),math.sin(a),.35)).normalized()
            attach=point_on(path,t)
            c=attach+axis*(r*(1.3 if idx==207 else .30))
            add(attach,c,axis,r*(1.55 if idx==207 else 1.30 if idx==205 else 1.10 if idx==206 else 1.0))
        return centres
    if idx==200:
        # Three-dimensional drooping chains, with tiny narrow urns attached along rachises.
        chains=20
        for k in range(chains):
            path,angle,_=choose(k,chains);start=path[-1]
            out=Vector((math.cos(angle),math.sin(angle),0))
            chain=[start,start+out*h*.055-UP*h*.025,start+out*h*.090-UP*h*.14]
            g.tube(chain,[h*.0014,h*.0008,h*.00035],0,5)
            for j in range(9):
                attach=point_on(chain,.12+.85*(j+.5)/9)
                turn=angle+(j%2-.5)*2
                c=attach+Vector((math.cos(turn)*.009,math.sin(turn)*.009,-.003))
                add(attach,c,-UP,r*1.45)
        return centres
    if idx in [199,202,203,204,208,209,213,215]:
        clusters={199:16,202:24,203:32,204:28,208:32,209:30,213:25,215:35}[idx]
        per={199:10,202:4,203:4,204:5,208:3,209:5,213:5,215:4}[idx]
        for k in range(clusters):
            path,heading,_=choose(k,clusters)
            hub,axis=exposed(path,heading,.05 if idx==215 else profile(idx)['leaf_length']*.95)
            hub+=UP*h*(.035 if idx not in [203,208] else .018)
            g.tube([path[-1],hub],[h*.0015,.00035],0,4)
            u=Vector((-math.sin(heading),math.cos(heading),0))
            for j in range(per):
                a=j*2.39996;spread=r*(1.15 if idx in [199,209] else 1.6)
                c=hub+u*math.cos(a)*spread+UP*math.sin(a)*spread
                if idx==204:c+=UP*(j-2)*r*.90
                add(hub,c,axis,r*(1.15 if idx in [202,203,213] else 1.0))
        return centres
    count={198:24,201:21,210:30,211:48,212:95,214:65,217:85}[idx]
    for k in range(count):
        path,angle,_=choose(k,count)
        attach=point_on(path,.62+(k%3)*.16) if idx in [212,214,217] else path[-1]
        axis=Vector((math.cos(angle),math.sin(angle),.50)).normalized()
        if idx in [212,214]:
            c=attach+axis*h*.028-UP*h*.025
            add(attach,c,-UP,r*1.15)
        else:
            offset=.13 if idx==210 else .11 if idx==201 else .075 if idx==211 else .040
            c=attach+axis*h*offset
            if idx in [201,210,211]:c+=UP*h*.040
            add(attach,c,UP if idx==210 else axis,r*(1.45 if idx==211 else 1.25 if idx==201 else 1.20 if idx==198 else 1.0))
    return centres

def orchid(g,c,axis,r,kind):
    c=Vector(c);u,v,n=frame(axis)
    narrow=kind=='spider'
    # Three sepals and two lateral petals, plus a separately shaped labellum.
    for a in [math.pi/2,7*math.pi/6,11*math.pi/6]:
        d=u*math.cos(a)+v*math.sin(a)
        petal_in_plane(g,c,d,n,r*(1.45 if narrow else .60 if kind=='oncidium' else 1),r*(.065 if narrow else .52 if kind=='slipper' and a==math.pi/2 else .25),4 if kind in ['zygo','slipper','spider'] else 0,.16,.08)
    for a in [.15,math.pi-.15]:
        d=u*math.cos(a)+v*math.sin(a)
        petal_in_plane(g,c,d,n,r*(1.4 if narrow or kind=='slipper' else .30 if kind=='bee' else .55 if kind=='oncidium' else .95),r*(.045 if narrow else .07 if kind=='bee' else .40 if kind in ['cattleya','pansy','vanda'] else .20),0,.18,.18 if kind=='cattleya' else .04)
    lip=c-v*r*.13+n*r*.08
    if kind=='slipper':
        # Hollow pouch with an open rim and hanging rounded lower bag.
        offset=len(g.v);rings=9;sides=24
        for j in range(rings+1):
            t=j/rings;rad=math.sin((t*.83+.13)*math.pi)*r*.43
            for k in range(sides):
                a=k*TAU/sides;p=lip-v*r*(.05+t*.8)+u*math.cos(a)*rad+n*(r*.23+math.sin(a)*rad*.65)
                g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
        for j in range(rings):
            for k in range(sides):
                a=offset+j*sides+k;b=offset+j*sides+(k+1)%sides;g.face((a,b,b+sides,a+sides),5)
    elif kind=='cattleya':funnel(g,lip,n-v*.35,r*.62,r*.53,5,6,.8,.22)
    elif kind=='bee':
        g.ellipsoid(lip-v*r*.35,(r*.25,r*.15,r*.32),5,8,12)
        for sign in [-1,1]:petal_in_plane(g,lip-v*r*.20,u*sign-v*.25,n,r*.35,r*.13,2,.12)
    elif kind in ['oncidium','spike']:
        for a,length in [(4.0,.7),(5.4,.7),(4.7,.9)]:
            petal_in_plane(g,lip,u*math.cos(a)+v*math.sin(a),n,r*length,r*.23,5,.1,.07)
    else:petal_in_plane(g,lip,-v+n*.15,n,r*(.85 if kind=='zygo' else .7),r*(.50 if kind in ['pansy','zygo'] else .33),5,.20,.12)
    g.ellipsoid(c+n*r*.15,(r*.08,r*.08,r*.16),1,5,8)

def heart(g,c,r):
    c=Vector(c);offset=len(g.v);rings=16;sides=24
    for j in range(rings+1):
        t=j/rings;theta=math.pi*t
        for k in range(sides):
            a=k*TAU/sides
            outline_x=math.sin(a)**3
            outline_z=(13*math.cos(a)-5*math.cos(2*a)-2*math.cos(3*a)-math.cos(4*a))/17
            x=outline_x*math.sin(theta)*r*.80
            y=math.cos(theta)*r*.35
            z=outline_z*math.sin(theta)*r
            g.v.append(tuple(c+Vector((x,y,z))));g.uv[len(g.v)-1]=(k/sides,t)
    for j in range(rings):
        for k in range(sides):
            a=offset+j*sides+k;b=offset+j*sides+(k+1)%sides;g.face((a,b,b+sides,a+sides),0)
    petal(g,c-Vector((0,0,r*.7)),(0,0,-1),r*.55,r*.13,1,.2)

def original_flower(row,g,c,axis=(0,0,1),radius=None):
    idx=row['id'];r=radius or row['bloom_radius'];c=Vector(c);u,v,n=frame(axis)
    flower_stamens=partial(stamens,low_detail=idx>=198)
    flower_rays=partial(rays,tiny=idx>=198)
    if idx<158:
        kind=['cattleya','slipper','oncidium','pansy','vanda','zygo','spider','rock','bee','spike'][idx-148]
        orchid(g,c,axis,r,kind);return
    if idx==158:
        for ring in range(2):
            flower_rays(g,c+n*r*ring*.08,axis,r*(1-ring*.20),10,.10,0,-.05,.08,.20,start=ring*.28)
        flower_stamens(g,c,n,r,14);return
    if idx==172:
        flower_rays(g,c,axis,r*.90,3,.08,0,0,.01,start=math.pi/3)
        flower_rays(g,c,axis,r,3,.30,0,0,.10)
        for k in range(3):
            a=k*TAU/3;d=u*math.cos(a)+v*math.sin(a);side=n.cross(d)
            for step in range(9):
                t=.25+step*.065
                for sign in [-1,1]:
                    start=c+d*r*t+side*sign*r*.25*math.sin(math.pi*t)
                    end=start+side*sign*r*.15+d*r*.045
                    g.tube([start,end],[r*.010,r*.003],0,4)
        flower_stamens(g,c,n,r,6);return
    if idx==196:
        for a in [.5,2.64,3.45,5.97,4.71]:
            petal_in_plane(g,c,u*math.cos(a)+v*math.sin(a),n,r,r*.30,1 if a==4.71 else 0,.08,.03)
        flower_stamens(g,c,n,r,3);return
    if idx==191:
        # The astilbe head is an airy branching plume, not a compact pom-pom.
        for branch in range(12):
            t=branch/12;a=branch*2.39996
            start=c+n*(t-.3)*r*1.9
            tip=start+(u*math.cos(a)+v*math.sin(a))*r*(1-t)*.65+n*r*.20
            g.tube([start,tip],[r*.012,r*.004],3,5)
            for k in range(5):
                p=start.lerp(tip,(k+.4)/5)
                flower_rays(g,p,axis,r*.07,5,.32,0,.02)
        return
    if idx==189:heart(g,c,r);return
    if idx==182: # Snapdragon: a compressed tube and distinct upper/lower lips.
        funnel(g,c,axis,r*.50,r*.70,0,5,.45,.03)
        mouth=c+n*r*.70
        for a in [.85,2.29]:
            petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a)+n*.30,n,r*.70,r*.32,0,.25,.02)
        for a in [3.70,4.71,5.72]:
            petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a)+n*.15,n,r*.62,r*.31,0,.36,.02)
        g.ellipsoid(mouth-v*r*.20+n*r*.05,(r*.30,r*.20,r*.16),1,5,8)
        return
    if idx==214: # Correa: long pendent four-lobed tube, green-yellow mouth.
        funnel(g,c,axis,r*.72,r*2.7,0,4,.90,.04,.70)
        flower_rays(g,c+n*r*2.7,axis,r*.72,4,.20,4,-.05,.02)
        flower_stamens(g,c+n*r*2.55,n,r,4);return
    if idx==217: # Eremophila: curved tube and asymmetric two/three-lobed mouth.
        funnel(g,c,axis,r*.64,r*2.3,0,5,.80,.03,.55,.35)
        mouth=c+n*r*2.3
        for a in [.9,2.24,3.65,4.71,5.78]:
            petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a),n,r*.65,r*.18,0,.12,.02)
        flower_stamens(g,c+n*r*2.3,n,r,4);return
    if idx==200:
        offset=len(g.v);sides=10
        for j in range(7):
            t=j/6;radius=r*(.25+.70*math.sin(math.pi*t)**.7)
            for k in range(sides):
                a=k*TAU/sides;p=c+n*r*t*1.45+(u*math.cos(a)+v*math.sin(a))*radius
                g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
        for j in range(6):
            for k in range(sides):
                a=offset+j*sides+k;b=offset+j*sides+(k+1)%sides
                g.face((a,b,b+sides,a+sides),1)
        flower_rays(g,c+n*r*1.45,axis,r*.3,5,.23,1);return
    if idx==210:
        # A complete short raceme: many tiny four-lobed corollas around an upright axis.
        base=c-n*r*1.7;tip=c+n*r*1.7
        g.tube([base,tip],[r*.08,r*.025],3,5)
        for k in range(22):
            t=(k+.5)/22;a=k*2.39996
            out=u*math.cos(a)+v*math.sin(a)
            pos=base.lerp(tip,t)+out*r*.37
            flower_rays(g,pos,out,r*.20,4,.28,0)
            flower_stamens(g,pos,out,r*.25,2,1)
        return
    if idx==205:
        funnel(g,c-n*r*.1,axis,r*.24,r*.32,0,4,.3)
        flower_rays(g,c,axis,r,4,.17,0,-.22,.02);return
    if idx==208:
        flower_rays(g,c,axis,r*.75,5,.22,5,.08,.01)
        funnel(g,c,axis,r,r*1.6,1,5,.8,.02);return
    if idx==216:
        flower_rays(g,c,axis,r,5,.34,0,.03,.02)
        g.ellipsoid(c+n*r*.10,(r*.25,r*.25,r*.12),5,3,8)
        flower_stamens(g,c,n,r,8);return
    if idx in [176,177,192,199,203,209]:
        lobes=6 if idx in [176,177] else 4 if idx in [199,210] else 5
        funnel(g,c,axis,r,r*(1.75 if idx==192 else 1.05),0,lobes,.6,.04)
        flower_stamens(g,c+n*r*.7,n,r,lobes);return
    if idx==174: # Snowdrop: three long outer petals and three green-tipped inner ones.
        flower_rays(g,c,axis,r,3,.22,1,-.65,.02)
        flower_rays(g,c,axis,r*.55,3,.28,4,-.3,.02,start=math.pi/3);return
    if idx==173:
        flower_rays(g,c,axis,r,6,.38,0,.08);funnel(g,c,axis,r*.48,r*.65,2,6,.3,.14);return
    if idx==175:flower_rays(g,c,axis,r,6,.40,0,-.5,.03);flower_stamens(g,c,n,r,3);return
    if idx==179: # Lily of the valley bells have rolled, distinctly lobed mouths.
        funnel(g,c,axis,r,r*1.2,1,6,.20,.07);return
    if idx==188: # Columbine: outer sepals and five spurred petals.
        flower_rays(g,c,axis,r,5,.24,0,.08)
        flower_rays(g,c+n*r*.15,axis,r*.65,5,.26,1,-.30,start=math.pi/5)
        for k in range(5):
            a=k*TAU/5;start=c+(u*math.cos(a)+v*math.sin(a))*r*.45
            end=start-n*r*.8;g.tube([start,start-n*r*.6,end+u*r*.1],[r*.055,r*.035,r*.004],0,6)
        flower_stamens(g,c,n,r,8);return
    if idx==161: # Ragged robin: five deeply cut petals, each with four narrow fingers.
        for k in range(5):
            a=k*TAU/5
            for cut in range(4):
                turn=a+(cut-1.5)*.105
                petal_in_plane(g,c,u*math.cos(turn)+v*math.sin(turn),n,r,r*.065,0,.08,.02)
        flower_stamens(g,c,n,r,5);return
    if idx==193: # Tall garden phlox: five rounded lobes on a narrow throat.
        funnel(g,c-n*r*.2,n,r*.15,r*.3,0,5,.25)
        flower_rays(g,c,axis,r,5,.36,0,0,.04);return
    if idx==194:funnel(g,c,axis,r,r*1.3,0,5,.55,.06);return
    if idx==195:
        for k in range(6):
            a=k*TAU/6
            petal_in_plane(g,c,u*math.cos(a)+v*math.sin(a)+n*.18,n,r,r*.27,0,.35,.08)
        flower_stamens(g,c,n,r,6);return
    if idx==169: # Strawflower: overlapping, pointed papery bracts.
        for ring in range(4):flower_rays(g,c+n*r*ring*.07,axis,r*(1-ring*.16),16+ring*2,.12,0,-ring*.08,.02,start=ring*.2)
        g.ellipsoid(c+n*r*.2,(r*.20,r*.20,r*.13),2,6,12);return
    if idx==180: # Ranunculus: many concentric cupped petals rather than a daisy.
        for ring in range(6):flower_rays(g,c+n*r*ring*.08,axis,r*(1-ring*.12),9+ring,.32,0,-ring*.11,.08,start=ring*.4)
        return
    if idx in [165,166,167,186,187]:
        count={165:15,166:13,167:12,186:14,187:16}[idx]
        flower_rays(g,c,axis,r,count,.15,0,.32 if idx==165 else .05,.04)
        if idx==187:
            for ring in range(2):flower_rays(g,c+n*r*(.08+ring*.08),axis,r*(.8-ring*.2),count,.18,0,-.13,.06,start=.15+ring*.2)
        if idx==167:
            for k in range(count):
                a=k*TAU/count;d=u*math.cos(a)+v*math.sin(a)
                petal_in_plane(g,c+d*r*.56,d,n,r*.42,r*.105,2,.06,.03)
        g.ellipsoid(c+n*r*.10,(r*.32,r*.32,r*(.44 if idx==165 else .15)),5 if idx==166 else 2,8,14)
        for k in range(25):
            a=k*2.39996;distance=r*.27*math.sqrt((k+.5)/25)
            g.ellipsoid(c+n*r*.22+u*math.cos(a)*distance+v*math.sin(a)*distance,(r*.026,)*3,2,3,5)
        return
    if idx in [163,164,170,178,183,197,201,207,211]:
        # Individual florets, not an opaque ball substituting for a flower head.
        count=18 if idx not in [178,201] else 48 if idx==201 else 30
        for k in range(count):
            a=k*2.39996;distance=r*.80*math.sqrt((k+.3)/count)
            if idx in [178,201]:
                z=1-2*(k+.5)/count;s=math.sqrt(1-z*z)
                outward=(u*math.cos(a)*s+v*math.sin(a)*s+n*z).normalized()
                p=c+outward*r*.76
                flower_rays(g,p,outward,r*.23,6 if idx==178 else 5,.38 if idx==201 else .26,0,.03)
                if idx!=201:flower_stamens(g,p,outward,r*.23,3)
                continue
            lift=0 if idx==164 else math.sqrt(max(0,r*r-distance*distance))*.55
            p=c+u*math.cos(a)*distance+v*math.sin(a)*distance+n*lift
            flower_rays(g,p,axis,r*.18,4 if idx in [163,197] else 5,.27,0,.02)
            g.ellipsoid(p+n*r*.025,(r*.03,)*3,2,3,5)
        return
    if idx==212: # Fuchsia has reflexed sepals, a separate corolla and long stamens.
        funnel(g,c,axis,r*.24,r*.95,0,4,.85,.03,.85)
        tier=c+n*r*.95
        flower_rays(g,tier,axis,r,4,.17,0,.5,.04)
        funnel(g,tier,n,r*.5,r*.7,5,4,.50,.04)
        for k in range(8):
            a=k*TAU/8;end=c+n*r*2.10+(u*math.cos(a)+v*math.sin(a))*r*.13
            g.tube([c,end],[r*.012,r*.008],1,5);g.ellipsoid(end,(r*.025,)*3,2,3,5)
        return
    if idx==198: # Hibiscus staminal column projects conspicuously beyond five petals.
        flower_rays(g,c,axis,r,5,.44,0,-.1,.12)
        g.tube([c,c+n*r*1.05],[r*.05,r*.028],2,8)
        flower_stamens(g,c+n*r*.70,n,r,12);return
    count=max(3,min(12,int(row['petals'])))
    flower_rays(g,c,axis,r,count,.25 if idx in [171,172] else .34,0,.03,.05,.10 if idx in [158,159,160] else 0)
    flower_stamens(g,c,n,r,8 if idx in [168,213,216] else 6)


def urn(g,c,axis,r,length,mat=1,lobes=5):
    """Inflated bell with a constricted, toothed opening and hollow interior."""
    c=Vector(c);u,v,n=frame(axis);start=len(g.v);rings=6;sides=lobes*3
    for j in range(rings+1):
        t=j/rings;profile=.25+.69*math.sin(math.pi*t)**.70
        if j==rings:profile=.31
        for k in range(sides):
            a=k*TAU/sides;tooth=(.5+.5*math.cos(a*lobes))*.05*r*t**8
            p=c+n*(length*t+tooth)+(u*math.cos(a)+v*math.sin(a))*r*profile
            g.v.append(tuple(p));g.uv[len(g.v)-1]=(k/sides,t)
    for j in range(rings):
        for k in range(sides):
            a=start+j*sides+k;b=start+j*sides+(k+1)%sides;g.face((a,b,b+sides,a+sides),mat)


def sepals(g,c,axis,r,count=5,long=False):
    rays(g,Vector(c)-Vector(axis).normalized()*r*.10,axis,r*(1.06 if long else .35),count,.075,4,.20,.01,tiny=True)


def tubular_flower(g,c,axis,r,idx):
    c=Vector(c);u,v,n=frame(axis)
    if idx in (176,177):
        length=r*(1.58 if idx==177 else .94)
        funnel(g,c,n,r*.52,length,0,6,.22,.04,.55)
        rays(g,c+n*length,n,r*.48,6,.23,0,.58,.04,tiny=True)
        stamens(g,c+n*length*.75,n,r*.65,3,1,True)
    elif idx in (179,200):
        urn(g,c,n,r*(.86 if idx==179 else .66),r*1.20,1,6 if idx==179 else 5)
    elif idx in (182,192):
        funnel(g,c,n,r*.53,r*1.28,0,5,.48,.025,.28)
        mouth=c+n*r*1.24
        for sign in (-1,1):petal_in_plane(g,mouth,u*sign*.5+v*.66+n*.20,n,r*.51,r*.25,0,.20,.025,tiny=True)
        for a in (3.6,4.71,5.82):petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a)+n*.30,n,r*.58,r*.26,0,.30,.04,tiny=True)
        _local_ellipsoid(g,mouth-v*r*.18+n*r*.10,(r*.29,r*.15,r*.11),(u,v,n),1,4,8)
        if idx==192:stamens(g,mouth-n*r*.12,n,r*.40,1,2,True)
    elif idx==194:
        funnel(g,c,n,r*.96,r*1.38,0,5,.30,.14,.24)
        rays(g,c+n*r*1.34,n,r*.30,5,.30,0,.22,.02,tiny=True)
        stamens(g,c+n*r*.98,n,r*.55,3,1,True)
    elif idx in (199,203,208,209):
        length=r*(1.20 if idx==203 else 1.45 if idx==208 else .95)
        lobes=4 if idx==199 else 5
        funnel(g,c,n,r*(.45 if idx!=203 else .68),length,0,lobes,.68,.04,.28)
        rays(g,c+n*length,n,r*.57,lobes,.32,1 if idx in (199,208) else 0,.05,.03,tiny=True)
        if idx==208:rays(g,c-n*r*.05,n,r*.80,5,.15,5,.13,.02,tiny=True)
        else:stamens(g,c+n*length*.90,n,r*.35,2,2,True)
    elif idx==214:
        funnel(g,c,n,r*.57,r*2.35,0,4,.15,.02,.83)
        funnel(g,c+n*r*2.05,n,r*.61,r*.36,5,4,.20,.05,.87)
        rays(g,c+n*r*2.35,n,r*.34,4,.20,5,.25,.01,tiny=True)
        stamens(g,c+n*r*2.25,n,r*.60,4,1,True)
    elif idx==217:
        funnel(g,c,n,r*.58,r*1.98,0,5,.55,.02,.30,.37)
        mouth=c+n*r*1.96
        for a in (.80,2.34,3.65,4.71,5.78):
            petal_in_plane(g,mouth,u*math.cos(a)+v*math.sin(a)+n*.12,n,r*.52,r*.19,1,.15,.02,tiny=True)
        stamens(g,mouth,n,r*.65,4,2,True)


def complete_flower(row,g,c,axis,r):
    idx=row['id'];c=Vector(c);u,v,n=frame(axis)
    if idx in (176,177,179,182,192,194,199,200,203,208,209,214,217):
        sepals(g,c,n,r,6 if idx in (176,177) else 5)
        tubular_flower(g,c,n,r,idx);return
    if idx in (150,151,152,153,154,155):
        orchid(g,c,n,r,{150:'oncidium',151:'pansy',152:'vanda',153:'zygo',154:'spider',155:'rock'}[idx])
        # Paired callus ridges distinguish the labellum from ordinary ray petals.
        for sign in (-1,1):
            origin=c+u*sign*r*.055-v*r*.12+n*r*.11
            _stem(g,[origin,origin-v*r*.16+n*r*.045,origin-v*r*.29],r*.028,2,3,4)
        if idx==150:
            petal_in_plane(g,c-v*r*.12,-v,n,r*.80,r*.43,0,.18,.11,.12)
        elif idx==151:
            petal_in_plane(g,c-v*r*.10+n*r*.04,-v,n,r*.72,r*.40,1,.19,.05,.10)
        return
    if idx==156:
        rays(g,c,n,r,3,.24,0,.03,.03,start=math.pi/2)
        lip=c-v*r*.37+n*r*.15
        _local_ellipsoid(g,lip,(r*.36,r*.46,r*.20),(u,v,n),5,7,10)
        for sign in (-1,1):
            petal_in_plane(g,lip+u*sign*r*.22+n*r*.17,-v+u*sign*.3,n,r*.33,r*.06,2,.04,.01,tiny=True)
            petal_in_plane(g,c,u*sign+v*.08,n,r*.28,r*.08,4,.15,.01,tiny=True)
        return
    if idx==157:
        for a in (.55,1.57,2.59):petal_in_plane(g,c,u*math.cos(a)+v*math.sin(a)+n*.35,n,r*.65,r*.22,0,.45,.03,tiny=True)
        for a in (3.8,4.71,5.62):petal_in_plane(g,c,u*math.cos(a)+v*math.sin(a),n,r*(.88 if a==4.71 else .64),r*.24,0,.12,.03,.16,tiny=True)
        _stem(g,[c,c-n*r*.7,c-n*r*1.05+v*r*.15],r*.07,0,5,5);return
    if idx==173:
        rays(g,c,n,r,6,.34,0,.04,.03)
        funnel(g,c+n*r*.08,n,r*.45,r*.91,2,6,.44,.14,.61)
        stamens(g,c+n*r*.61,n,r*.36,3,2,True);return
    if idx==175:
        for ring in range(2):
            for k in range(3):
                a=(k+ring*.5)*TAU/3;out=u*math.cos(a)+v*math.sin(a)
                petal_in_plane(g,c,out*.65+n*.88,n,r*1.32,r*.35,0,.25,.03)
        stamens(g,c+n*r*.53,n,r*.65,3,2);return
    if idx==178:
        for k in range(42):
            z=1-2*(k+.5)/42;a=k*2.39996;s=math.sqrt(1-z*z)
            out=(u*math.cos(a)*s+v*math.sin(a)*s+n*z).normalized();p=c+out*r*.75
            g.tube([c,p],[r*.008,r*.003],3,3)
            rays(g,p,out,r*.22,6,.21,0,.05,.01,tiny=True)
            stamens(g,p,out,r*.16,3,2,True)
        return
    if idx==188:
        rays(g,c,n,r,5,.27,0,.12,.03)
        rays(g,c+n*r*.10,n,r*.58,5,.32,1,-.15,.02,start=math.pi/5)
        for k in range(5):
            a=(k+.5)*TAU/5;out=u*math.cos(a)+v*math.sin(a);base=c+out*r*.32
            _stem(g,[base,base-n*r*.65+out*r*.20,base-n*r*.90-out*r*.13,base-n*r*.72-out*r*.20],r*.065,0,7,5)
        stamens(g,c,n,r*.9,8,2,True);return
    if idx==190:
        rays(g,c,n,r,5,.49,0,-.18,.02)
        for k in range(8):
            a=k*TAU/8;p=c+(u*math.cos(a)+v*math.sin(a))*r*.21
            funnel(g,p,n,r*.043,r*.15,3,5,.20,.01,.65)
        stamens(g,c,n,r*.83,13,1,True);return
    if idx==195:
        for k in range(6):
            a=k*TAU/6;out=u*math.cos(a)+v*math.sin(a)
            petal_in_plane(g,c,out+n*.14,n,r,r*(.25 if k%2 else .20),0,.33,.07)
        for k in range(6):
            a=k*TAU/6;out=u*math.cos(a)+v*math.sin(a);end=c+n*r*.62+out*r*.26
            _stem(g,[c,c+n*r*.32,end],r*.011,1,4,4)
            _local_ellipsoid(g,end,(r*.035,r*.095,r*.027),(u,v,n),2,4,6)
        _stem(g,[c,c+n*r*.48,c+n*r*.83],r*.014,3,5,5);return
    if idx==196:
        for a in (.78,2.36,3.37,6.05,4.71):
            petal_in_plane(g,c,u*math.cos(a)+v*math.sin(a),n,r*(1.08 if a==4.71 else .84),r*.32,0,.13,.03)
        petal_in_plane(g,c+n*r*.04,-v,n,r*.32,r*.13,1,.08,.01,tiny=True)
        _stem(g,[c,c-n*r*.36,c-n*r*.60+v*r*.15],r*.07,0,4,5);return
    if idx==202:
        sepals(g,c,n,r,4)
        rays(g,c,n,r,4,.48,1,-.08,.04)
        stamens(g,c,n,r*.82,12,2,True);return
    if idx==205:
        funnel(g,c,n,r*.23,r*.31,0,4,.28,.03,.42)
        rays(g,c+n*r*.26,n,r*.88,4,.19,0,-.16,.035,tiny=True)
        stamens(g,c+n*r*.20,n,r*.60,2,2,True);return
    if idx==206:
        sepals(g,c,n,r)
        rays(g,c,n,r,5,.44,0,-.22,.03)
        stamens(g,c,n,r*.84,12,2,True);return
    if idx==210:
        base=c-n*r*1.6;tip=c+n*r*1.65
        g.tube([base,tip],[r*.08,r*.025],3,5)
        for k in range(30):
            t=(k+.3)/30;a=k*2.39996;out=u*math.cos(a)+v*math.sin(a)
            p=base.lerp(tip,t)+out*r*(.28-.10*t)
            rays(g,p,out,r*(.21-.07*t),4,.31,0,.05,.01,tiny=True)
            stamens(g,p,out,r*.28,2,1,True)
        return
    if idx==215:
        sepals(g,c,n,r,4)
        rays(g,c,n,r,4,.40,0,-.13,.01,tiny=True)
        stamens(g,c,n,r*.73,8,2,True);return
    # Remaining flowers retain their characteristic organ arrangement while
    # the local loft primitives give them curved petals, folds and finer mouths.
    if idx not in (163,164,170,178,183,189,191,197,201,207,211):
        sepals(g,c,n,r,5,long=idx==159)
    original_flower(row,g,c,n,r)
    if idx in (165,166,167,169,186,187):
        for ring in range(2):rays(g,c-n*r*(.08+ring*.06),n,r*(.39+ring*.06),10,.13,4,.40,.01,start=ring*.3,tiny=True)
    elif idx==185:
        for k in range(7):
            a=k*TAU/7;out=u*math.cos(a)+v*math.sin(a)
            p=c+out*r*.35
            _stem(g,[p,p+out*r*.6,p+out*r*1.05+n*r*.23],r*.009,3,3,3)
    elif idx==193:
        # The slender tube is visible between a leafy panicle and each flat face.
        g.tube([c-n*r*.62,c],[r*.045,r*.07],0,5)


def closed_buds(row,g,c,axis,r):
    c=Vector(c);u,v,n=frame(axis);idx=row['id']
    if idx in (178,201):
        for k in range(12):
            z=1-2*(k+.5)/12;a=k*2.39996;s=math.sqrt(1-z*z)
            p=c+(u*math.cos(a)*s+v*math.sin(a)*s+n*z)*r*.60
            g.ellipsoid(p,(r*.16,)*3,3,2,5)
    elif idx in (191,210):
        g.tube([c-n*r*1.35,c+n*r*1.55],[r*.045,r*.012],3,4)
        for k in range(12):
            t=(k+.5)/12;a=k*2.39996
            p=c+n*r*(-1.2+t*2.55)+(u*math.cos(a)+v*math.sin(a))*r*.23*(1-t*.6)
            g.ellipsoid(p,(r*.11,)*3,0,2,5)
    elif idx in (163,164,170,183,197,207,211):
        for k in range(7):
            a=k*2.39996;p=c+(u*math.cos(a)+v*math.sin(a))*r*.54*math.sqrt((k+.3)/7)
            g.ellipsoid(p,(r*.14,r*.14,r*.20),3,2,5)
    else:
        length=r*(1.55 if idx in (177,179,192,194,203,214,217) else .77 if idx<158 else .60)
        width=r*(.28 if idx in (175,180,181) else .17)
        # Low-poly closed buds keep dense blossom shrubs under the growth budget.
        _local_ellipsoid(g,c+n*length*.43,(width,length*.48,width*.84),(u,n,-v),0 if idx in (175,180,181,189) else 3,3,6)


def build(idx,phase='mature'):
    if idx not in IDS:raise ValueError('Not a full-pass flower: '+str(idx))
    if phase not in ('seedling','juvenile','mature'):raise ValueError(phase)
    row=ROWS[idx]
    if idx>=198:
        g,attachments=bush_foliage(row,phase)
        centres=bush_blooms(row,g,attachments) if phase=='mature' else []
    elif idx<158:g,centres=orchid_foliage(row,phase)
    else:g,centres=herb_foliage(row,phase)
    b=Geometry();buds=Geometry();b.fruit_anchors={};buds.fruit_anchors={}
    for c,axis,r in centres:
        first=len(b.v);first_bud=len(buds.v)
        complete_flower(row,b,c,axis,r)
        closed_buds(row,buds,c,axis,r)
        mark_anchor(b,first,c);mark_anchor(buds,first_bud,c)
    for mesh in (g,b,buds):
        assert all(math.isfinite(v) for point in mesh.v for v in point),(idx,phase,'non-finite mesh')
        assert all(0<=v<len(mesh.v) for face in mesh.f for v in face),(idx,phase,'invalid face')
    if phase=='mature':
        assert g.v and b.v and buds.v,(idx,'missing organs')
        assert len(b.fruit_anchors)==len(b.v) and len(buds.fruit_anchors)==len(buds.v)
    return g,b,buds
