"""Species-specific shrub habits, foliage and flowering positions.

Dimensions are relative to the authored mature height. Reference photographs and
botanical descriptions are recorded in flower_additions_references.md. Curves
are actual branches; no leaf clouds or opaque flower balls substitute for organs.
"""
import math, random
from mathutils import Vector
from botanical_geometry import Geometry
from flower_additions_geometry import UP, TAU

# habit, crown radius, canes, lateral levels, leaf length, half-width, leaf shape,
# leaf arrangement, leaf pigment, young pigment, bark pigment, flower layout.
PROFILES = {
198: ('upright', .46, 5, 5, .112, .32, 'toothed', 'alternate', '315e35', '72934f', '786149', 'solitary'),
199: ('dome', .66, 7, 4, .089, .29, 'oval', 'rosette', '385443', '88a85a', '7f705c', 'bouquets'),
200: ('tiered', .48, 4, 4, .092, .20, 'pointed', 'rosette', '3b6440', 'c17659', '7a6653', 'chains'),
201: ('broad', .66, 5, 5, .108, .39, 'lobed', 'opposite', '608347', '8faa61', '80715b', 'snowballs'),
202: ('tall_arch', .53, 7, 4, .094, .27, 'toothed', 'opposite', '548349', 'a0b972', '8a795e', 'short_clusters'),
203: ('arch', .76, 9, 4, .080, .24, 'toothed', 'opposite', '53804c', '88a467', '816249', 'trumpet_groups'),
204: ('low_arch', .84, 11, 3, .068, .20, 'pointed', 'opposite', '638b4e', '99ae70', '9a8768', 'racemes'),
205: ('fountain', .92, 10, 3, .049, .21, 'pointed', 'opposite', '92a75a', 'afb976', '9a7b43', 'bare_canes'),
206: ('tangled', .55, 6, 5, .061, .26, 'toothed', 'alternate', '49753e', 'a29250', '635a48', 'old_wood'),
207: ('cascade', 1.06, 13, 3, .045, .28, 'lobed', 'alternate', '597c6a', '8faf7a', '8d735a', 'corymbs'),
208: ('airy_arch', .81, 10, 4, .046, .24, 'oval', 'opposite', '526c40', 'a77b53', '965846', 'calyces'),
209: ('dense', .55, 8, 5, .049, .29, 'toothed', 'alternate', '365e3d', '79a069', '82604f', 'pink_clusters'),
210: ('cushion', .87, 9, 4, .092, .36, 'oval', 'decussate', '376966', '75a083', '7a6b54', 'spikes'),
211: ('billow', .73, 7, 5, .042, .27, 'oval', 'alternate', '355c50', '789274', '786851', 'blue_panicles'),
212: ('pendulous', .79, 8, 4, .078, .25, 'toothed', 'whorled', '58805d', '89a278', '994e5a', 'pendants'),
213: ('rounded', .67, 7, 4, .125, .23, 'ternate', 'opposite', '497844', '97b965', '7a7057', 'white_bouquets'),
214: ('spreading', .94, 8, 4, .062, .37, 'oval', 'opposite', '88907a', 'aab396', '85795f', 'bells'),
215: ('slender', .43, 6, 5, .079, .10, 'pinnate', 'opposite', '65816d', '98aa82', '887563', 'stars'),
216: ('twiggy', .44, 5, 6, .027, .16, 'needle', 'alternate', '747d62', 'a1a68a', '776557', 'twig_flowers'),
217: ('hemisphere', .80, 10, 4, .047, .14, 'lance', 'alternate', '81916c', 'a6b588', '8b7864', 'curved_tubes'),
}


def profile(idx):
    keys = ('habit','radius','canes','levels','leaf_length','leaf_width','leaf_shape',
            'arrangement','green','young','bark','flowers')
    return dict(zip(keys,PROFILES[idx]))


def point_on(path,t):
    t=max(0,min(.999999,t))*(len(path)-1);i=int(t)
    return path[i].lerp(path[i+1],t-i)


def bush_leaf(g,base,heading,length,p,material=1,tilt=.25):
    """Vary actual blades and their orientation, not just colour or leaf fans."""
    base=Vector(base);d=Vector((math.cos(heading),math.sin(heading),tilt)).normalized()
    junction=base+d*length*.12
    g.tube([base,junction],[length*.014,length*.009],0,3)
    shape=p['leaf_shape'];width=length*p['leaf_width']
    if shape=='ternate':
        for turn in [-.70,0,.70]:
            direction=Vector((math.cos(heading+turn),math.sin(heading+turn),tilt)).normalized()
            g.leaf(junction,junction+direction*length*.78,width*.74,material,.12,4)
    elif shape=='pinnate':
        tip=junction+d*length*.9
        g.tube([junction,tip],[length*.009,length*.004],0,4)
        for node in range(2):
            place=junction.lerp(tip,.28+node*.35)
            for sign in [-1,1]:
                direction=Vector((math.cos(heading+sign*1.03),math.sin(heading+sign*1.03),tilt*.5))
                g.leaf(place,place+direction*length*.34,width*.48,material,.1,3)
        g.leaf(tip-d*length*.15,tip+d*length*.17,width*.43,material,.12,3)
    else:
        # A single leaf with a serrated or lobed outline replaces the old five-blade fan.
        segments=6 if shape=='lobed' else 3 if p['leaf_length']<.08 else 4
        g.leaf(junction,junction+d*length,width,material,.16,segments,shape in ['lobed','toothed'])


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
                g.tube(shoot,[h*.0045,h*.0025,h*.00065],0,5)
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
                        g.tube(twig,[h*.0016,h*.0009,h*.0003],0,4)
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
