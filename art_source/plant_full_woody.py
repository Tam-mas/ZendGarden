"""Botanical art upgrade for 49 woody species, with deterministic organ meshes.

This module owns only geometry and material descriptions. It leaves runtime
quality, lighting, animation and batching unchanged. All reproductive organs
carry exact growth anchors; seedlings and juveniles have their own architecture.
"""
import json
import math
import random
from pathlib import Path
from mathutils import Vector
from botanical_geometry import Geometry
from fruit_tree_geometry import hanging_fruit, mark_anchor
from plant_sample_woody import petal, frame, direction, point, rose_leaf

IDS = tuple(list(range(21, 30)) + list(range(31, 36)) + list(range(38, 44)) + [45] + list(range(68, 96)))
FRUIT_IDS = (31, 34, 35, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91)
TREE_IDS = (28, 29, 31, 32, 33, 34, 35, 45, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94)
BAMBOO_IDS = (68, 69, 70, 71, 72, 80)
UP = Vector((0, 0, 1))
TAU = math.tau
SPECS = json.loads((Path(__file__).resolve().parent / 'plant_specs.json').read_text())


class WoodyGeometry(Geometry):
    """Stable UVs on wood and round organs, without altering shared primitives."""
    def tube(self, points, radii, mat=0, sides=6):
        start = len(self.v)
        super().tube(points, radii, mat, sides)
        travelled = 0
        for j, p in enumerate(points):
            if j:
                travelled += (Vector(p) - Vector(points[j - 1])).length
            for k in range(sides):
                self.uv[start + j * sides + k] = (k / sides, travelled / max(.025, max(radii) * 8))

    def ellipsoid(self, c, scale, mat=1, rings=5, sides=8, ribs=0):
        start = len(self.v)
        super().ellipsoid(c, scale, mat, rings, sides, ribs)
        for j in range(rings + 1):
            for k in range(sides):
                self.uv[start + j * sides + k] = (k / sides, j / rings)


def groups():
    return WoodyGeometry(), WoodyGeometry(), WoodyGeometry()


def leaf(g, base, heading, length, width, mat=1, tilt=.10, shape='oval', rows=7, stalk=True):
    """Petiolate folded blades: correct upward normals, tissue-aligned UVs."""
    base = Vector(base)
    d = direction(heading, tilt)
    side = UP.cross(d).normalized()
    normal = d.cross(side).normalized()
    petiole = length * (.13 if width / length > .12 else .07) if stalk else 0
    c = base + d * petiole
    if stalk:g.tube([base, c], [length * .012, length * .005], 0, 3)
    start = len(g.v)
    for j in range(rows + 1):
        t = j / rows
        profile = max(0, math.sin(math.pi * t)) ** (.48 if shape in ('round', 'heart') else .78)
        if shape == 'heart':
            profile = max(0, math.sin(math.pi * (.12+.88*t))) ** .48 * (1.25-.45*t)
        elif shape == 'birch':
            profile *= 1.45-.85*t
        if shape in ('toothed', 'banksia', 'birch'):
            profile *= 1.0 if j % 2 else (.70 if shape == 'banksia' else .88)
        w = width * profile
        mid = c + d * (length * t) + normal * length * (.10 * math.sin(math.pi * t) - .08 * t ** 3)
        for k in range(3):
            q = k - 1
            p = mid + side * (q * w) - normal * w * .19 * abs(q)
            if shape=='heart':p -= d * length * .11 * abs(q)**2 * (1-t)**4
            g.v.append(tuple(p)); g.uv[len(g.v) - 1] = (k / 2, t)
    for j in range(rows):
        a = start + j * 3
        g.face((a, a + 3, a + 4, a + 1), mat)
        g.face((a + 1, a + 4, a + 5, a + 2), mat)


def palmate(g, base, a, length, mat=1, lobes=5):
    """Connected fig blade, with broad rounded lobes and deep sinuses."""
    base = Vector(base); f = direction(a, -.04); s = UP.cross(f).normalized()
    hub = base + f * length * .17
    g.tube([base, hub], [length * .020, length * .010], 0, 4)
    start = len(g.v); g.v.append(tuple(hub + UP * length * .07)); g.uv[start] = (.5, .2)
    rim = []
    for k in range(lobes):
        turn = (k / (lobes - 1) - .5) * 4.8
        extent = 1 - .30 * abs(turn) / 2.4
        for off, r in ((-.38, .28), (-.24, .73), (-.10, .97), (.10, .97), (.24, .73), (.38, .28)):
            angle = turn + off; x = math.cos(angle) * length * extent * r; y = math.sin(angle) * length * extent * r
            rim.append(len(g.v)); g.v.append(tuple(hub + f * x + s * y + UP * length * (.06 * r - .10 * r * r)))
            g.uv[len(g.v)-1] = (.5 + y / length / 2, .3 + x / length / 1.6)
    for j in range(len(rim)):
        g.face((start, rim[j], rim[(j+1) % len(rim)]), mat)


def ginkgo_fan(g, base, angle, length, mat=1):
    base = Vector(base); d = direction(angle, -.10); side = UP.cross(d).normalized()
    c = base + d * length * .26
    g.tube([base, c], [length*.013, length*.005], 0, 3)
    start = len(g.v); columns = 13; rows = 4
    for j in range(rows+1):
        t = j/rows
        for k in range(columns):
            u = k/(columns-1); a = (u-.5)*2.0
            notch = 1-.24*math.exp(-((u-.5)/.075)**2)
            r = length*t*notch
            p = c+d*(math.cos(a)*r)+side*(math.sin(a)*r)+UP*length*(.13*math.sin(math.pi*t)+.02*math.cos(k*math.pi)*t)
            g.v.append(tuple(p)); g.uv[len(g.v)-1]=(u,t)
    for j in range(rows):
        for k in range(columns-1):
            i = start+j*columns+k; g.face((i,i+columns,i+columns+1,i+1),mat)


def compound(g, base, angle, length, mat=1, fine=False):
    base = Vector(base); end = base+direction(angle,.15)*length
    g.tube([base,end],[length*.013,length*.004],0,3)
    for j in range(3 if fine else 4):
        loc = base.lerp(end,.18+j*(.26 if fine else .21))
        for sign in (-1,1):
            a=angle+sign*1.14; ll=length*(.34 if fine else .40)*(1-j*.09)
            if fine:
                tip=loc+direction(a,.08)*ll;g.tube([loc,tip],[length*.005,length*.002],0,3)
                for n in range(3):
                    for side in (-1,1):
                        q=loc.lerp(tip,.23+n*.30)
                        leaf(g,q,a+side*1.0,ll*.27,ll*.027,mat,.05,'oval',2,False)
            else:leaf(g,loc,a,ll,ll*.105,mat,.08,'oval',4)
    if not fine:leaf(g,end,angle,length*.21,length*.025,mat,.10,'oval',4)


def closed_bud(buds, anchor, radius=.013, axis=UP, mat=3):
    """One small independently anchored bud per mature inflorescence site."""
    anchor=Vector(anchor);axis=Vector(axis).normalized();start=len(buds.v)
    c=anchor+axis*radius*.65
    buds.tube([anchor,c],[radius*.20,radius*.12],3,4)
    # Bud bodies are compact; no extruded spikes are substituted for leaves.
    buds.ellipsoid(c+axis*radius*.65,(radius*.63,radius*.63,radius),mat,4,7)
    mark_anchor(buds,start,anchor)


def petalled(b, anchor, axis, radius, petals=5, whorls=1, seed=0, style='open'):
    u,v,n=frame(axis);anchor=Vector(anchor);c=anchor+n*radius*.20;start=len(b.v)
    b.tube([anchor,c],[radius*.055,radius*.025],3,4)
    for ring in range(whorls):
        count=petals-ring//2 if whorls>1 else petals
        r=radius*(1-ring*.17)
        for j in range(count):
            a=j*TAU/count+ring*.78+seed*.21;d=u*math.cos(a)+v*math.sin(a)
            mat=0
            if style=='striped' and (j+ring)%3==0:mat=6
            face_start=len(b.f)
            petal(b,c+n*radius*ring*.09,d,n,r,r*(.54 if whorls>1 else .52),mat,
                  .26+ring*(.24 if style=='high' else .13),.23 if style=='ruffled' else .06,6,5)
            if style=='striped':
                # Cream runs lengthwise in irregular petal sectors, not whole white petals.
                for f in range(face_start,len(b.f)):
                    row=(f-face_start)//4;col=(f-face_start)%4
                    b.mi[f]=6 if col==(seed+j+ring+row//3)%4 and row>=1 else 0
    if whorls<3:
        for k in range(9):
            a=k*2.4;tip=c+n*radius*.25+(u*math.cos(a)+v*math.sin(a))*radius*.16
            b.tube([c,tip],[radius*.012,radius*.007],2,3)
            b.ellipsoid(tip,(radius*.031,)*3,2,2,4)
    for k in range(5):
        a=k*TAU/5;d=u*math.cos(a)+v*math.sin(a)
        petal(b,c-n*radius*.06,d-n*.1,n,radius*.39,radius*.063,4,.05,0,3,3)
    mark_anchor(b,start,anchor)


# Habit, radius, blade length/half-width, blade type, main branches, twig nodes.
TREE = {
28:('spreading',.37,.047,.015,'toothed',16,5),29:('light',.27,.036,.013,'birch',18,7),
31:('spreading',.34,.055,.010,'oval',16,8),32:('weeping',.35,.072,.0065,'oval',16,11),
33:('spreading',.35,.072,.026,'oval',14,6),34:('rounded',.34,.057,.019,'oval',16,7),
35:('open',.36,.056,.020,'toothed',16,7),45:('airy',.29,.075,.010,'oval',16,7),
81:('tiered',.34,.060,.030,'fan',14,5),82:('open',.38,.075,.040,'fig',14,5),
83:('upright',.29,.054,.019,'toothed',16,7),84:('open',.37,.075,.010,'toothed',16,8),
85:('rounded',.34,.050,.018,'toothed',16,8),86:('rounded',.36,.054,.026,'round',16,7),
87:('open',.36,.077,.010,'toothed',16,8),88:('rounded',.33,.059,.019,'oval',17,8),
89:('rounded',.35,.052,.016,'oval',16,8),90:('rounded',.34,.050,.017,'oval',17,8),
91:('spreading',.37,.081,.021,'oval',15,7),92:('snow',.38,.071,.012,'oval',13,7),
93:('alpine',.43,.069,.013,'oval',12,7),94:('rounded',.37,.066,.025,'oval',15,7),
}


def tree_leaf(idx,g,base,heading,length,width,shape,mat=1,young=False):
    if shape=='fan':ginkgo_fan(g,base,heading,length,mat)
    elif shape=='fig':palmate(g,base,heading,length,mat)
    else:
        # Juvenile eucalyptus leaves precede pendulous mature lance blades.
        if young and idx in (45,92,93):shape='round';width=length*.36
        leaf(g,base,heading,length,width,mat,-.65 if idx in (32,45,92,93) and not young else -.06,
             shape,10 if shape in ('toothed','round','birch') else 6)


def tree(idx, phase):
    g,b,buds=groups();rng=random.Random(idx*13007+{'mature':0,'seedling':41,'juvenile':89}[phase])
    habit,radius,ll,width,shape,branches,nodes=TREE[idx];early=phase!='mature'
    scale={'mature':1.,'seedling':.080,'juvenile':.31}[phase]
    if idx==45 and early:scale*=.72
    trunks=3 if idx in (92,93) and not early else 1
    bark=6 if idx in (29,45,92,93) else 5
    tips=[]
    if phase=='seedling':
        path=[Vector((0,0,0)),Vector((.006,0,scale*.45)),Vector((0,.004,scale))]
        g.tube(path,[.004,.0025,.0008],bark,6)
        for k in range(5):
            tree_leaf(idx,g,point(path,.20+k*.18),k*2.4,ll*.40,width*.40,shape,2 if k>2 else 1,True)
        return g,b,buds
    for trunk in range(trunks):
        a=trunk*2.4
        lean=.23 if idx==93 else .15 if idx==92 else .045
        path=[direction(a)*.022*scale,direction(a+.3)*lean*.22*scale+UP*.25*scale,
              direction(a)*lean*.65*scale+UP*.52*scale,direction(a+.4)*lean*scale+UP*.89*scale]
        g.tube(path,[scale*(.030 if trunks==1 else .021),scale*.021,scale*.012,scale*.003],bark,10)
        if not early:
            for k in range(5):
                ang=k*TAU/5;root=direction(ang)*scale*.047
                g.tube([root,path[0]+UP*.035,path[0]+UP*.14],[scale*.009,scale*.012,scale*.017],bark,6)
            if idx in (29,45,92,93):
                for k in range(15):
                    t=.10+k*.045;loc=point(path,t);ang=k*2.4
                    rr=.026*(1-t*.70)
                    if idx==29:
                        g.tube([loc+direction(ang-.45)*rr,loc+direction(ang)*rr+UP*.002,loc+direction(ang+.45)*rr], [.0018]*3,5,3)
                    else:
                        leaf(g,loc+direction(ang)*rr,ang,.075,.011,7,.7,'oval',4)
        count=5 if early else max(7,branches//trunks)
        for j in range(count):
            t=.35+j/(max(1,count-1))*.48
            angle=j*2.39996+trunk*1.73+rng.uniform(-.20,.20)
            base=point(path,t)
            crown=math.sqrt(max(.08,1-((t-.52)/.57)**2))
            reach=radius*scale*crown*rng.uniform(.80,1.08)
            if habit=='upright':reach*=.87
            lift=.14 if habit=='upright' else .085 if habit in ('rounded','open') else .045
            end=base+direction(angle)*reach+UP*scale*lift
            branch=[base,base.lerp(end,.42)+UP*scale*.035,base.lerp(end,.80)-UP*scale*.013,end]
            g.tube(branch,[scale*.010*(1-.45*t),scale*.006,scale*.003,scale*.0008],bark,6)
            forks=2 if early else 4
            for k in range(forks):
                start=point(branch,.35+k*(.48 if early else .19))
                turn=angle+(-1 if k%2 else 1)*rng.uniform(.58,1.08)
                span=scale*rng.uniform(.092,.18)
                tip=start+direction(turn)*span+UP*scale*rng.uniform(.01,.055)
                if habit=='weeping':
                    tip=start+direction(turn)*span*.75-UP*scale*rng.uniform(.15,.35)
                twig=[start,start.lerp(tip,.36)+UP*scale*.028,tip]
                g.tube(twig,[scale*.0026,scale*.0013,scale*.00025],0,4)
                n=3 if early else nodes
                if idx==28 and not early:n=3
                for m in range(n):
                    loc=point(twig,.15+m*.82/max(1,n-1));turnleaf=turn+(-1 if m%2 else 1)*rng.uniform(.65,1.40)
                    leaves=2 if idx in (31,81) else 1
                    for side in range(leaves):
                        length=ll*(.63 if early else 1)*rng.uniform(.79,1.16)
                        mat=4 if idx in (31,45,92,93) and m%3==0 else 2 if m==n-1 else 1
                        tree_leaf(idx,g,loc,turnleaf+side*math.pi,length,width*length/ll,shape,mat,early)
                tips.append((tip,direction(turn,.44),twig))
                # Additional leafy tiplets create depth without leaf balls.
                if not early and idx not in (28,32):
                    forkbase=point(twig,.58);fa=turn-.9;fe=forkbase+direction(fa)*ll*1.25+UP*.022
                    g.tube([forkbase,fe],[.0011,.0002],0,3)
                    for m in range(3):
                        tree_leaf(idx,g,forkbase.lerp(fe,.25+m*.35),fa+(-1 if m%2 else 1),ll*.83,width*.83,shape,1)
    if early:return g,b,buds
    if idx in FRUIT_IDS:
        # 24 or more sites around the whole canopy; fruit is clear of leaf tips.
        fruit_name=SPECS[idx][0];fruit_rng=random.Random(6619+idx)
        for j,(tip,axis,twig) in enumerate(tips):
            if j%2:continue
            anchor=point(twig,.84)
            radius=.0095 if idx==31 else .032 if idx==91 else .022 if idx in (82,85,86,90) else .027
            stalk_start=len(b.v)
            hanging_fruit(b,anchor,fruit_name,radius,fruit_rng,fruit_rng.choice((0,0,4,5)))
            # Tree coordinates are normalized to metres during export. Keep the
            # fixed-radius helper's three stalk rings slim after that scaling;
            # their centres, fruit bodies and attachment data remain unchanged.
            for ring in range(3):
                first=stalk_start+ring*5
                center=sum((Vector(b.v[v]) for v in range(first,first+5)),Vector((0,0,0)))/5
                for v in range(first,first+5):b.v[v]=tuple(center+(Vector(b.v[v])-center)*.25)
            closed_bud(buds,anchor,.0055,-UP,3)
    else:
        for j,(tip,axis,twig) in enumerate(tips):
            if idx==28:
                if j%2:continue
                for k in range(4):
                    anchor=tip+direction(k*2.4)*.018+UP*.005*k
                    g.tube([tip,anchor],[.0011,.0004],0,3)
                    petalled(b,anchor,direction(j*2.4+k,.45),.025,5,1,j)
                    closed_bud(buds,anchor,.007)
            elif idx==33 and j%2==0:
                petalled(b,tip,axis,.063,9,1,j,'cup');closed_bud(buds,tip,.015)
            elif idx==94 and j%3==0:
                brush_head(b,tip,axis,.065,'gum',j);closed_bud(buds,tip,.012)
            elif idx==94 and j%13==2:
                start=len(b.v)
                for capsule in range(3):
                    c=Vector(tip)+direction(capsule*2.4)*.012
                    b.tube([tip,c],[.0015,.0010],3,4)
                    base=len(b.v)
                    for z,r in ((0,.004),(.011,.008),(.019,.0065),(.019,.0045),(.012,.003)):
                        for k in range(10):
                            a=k*TAU/10;b.v.append(tuple(c+direction(a)*r+UP*z));b.uv[len(b.v)-1]=(k/10,z/.02)
                    for ring in range(4):
                        for k in range(10):
                            a=base+ring*10+k;other=base+ring*10+(k+1)%10
                            b.face((a,other,other+10,a+10),6)
                mark_anchor(b,start,tip);closed_bud(buds,tip,.009)
            elif idx in (92,93) and j%9==0:
                start=len(b.v)
                for k in range(3):
                    q=tip+direction(k*2.4)*.008
                    b.ellipsoid(q,(.004,.004,.007),1,4,7)
                mark_anchor(b,start,tip);closed_bud(buds,tip,.006)
            elif j%7==0:
                start=len(b.v)
                if idx==81:ginkgo_fan(b,tip,j*2.4,.022,3)
                else:leaf(b,tip,j*2.4,.022,.004 if idx in (32,45) else .007,3,.35,'oval',4)
                mark_anchor(b,start,tip);closed_bud(buds,tip,.006)
    return g,b,buds


# Stem habit, crown radius, leaf size, shape, arrangement, mature canes.
SHRUB = {
21:('rounded',.53,.090,.025,'oval','alternate',7),22:('upright',.40,.065,.006,'needle','opposite',9),
23:('rounded',.48,.14,.050,'toothed','alternate',7),24:('upright',.44,.14,.068,'heart','opposite',7),
25:('cushion',.61,.065,.028,'round','opposite',9),26:('rounded',.54,.14,.050,'oval','whorled',7),
27:('upright',.46,.10,.030,'oval','alternate',7),38:('airy',.49,.16,.018,'bipinnate','alternate',6),
39:('arching',.51,.13,.015,'oval','alternate',7),40:('spreading',.66,.16,.022,'divided','alternate',7),
41:('upright',.47,.17,.036,'banksia','whorled',6),42:('rounded',.46,.13,.036,'oval','opposite',7),
43:('airy',.53,.070,.004,'needle','opposite',8),95:('upright',.37,.18,.040,'banksia','alternate',6),
}


def shrub_leaf(idx,g,loc,a,ll,width,shape,mat,early=False):
    if shape in ('divided','bipinnate'):compound(g,loc,a,ll,mat,shape=='bipinnate')
    else:leaf(g,loc,a,ll,width,mat,.16 if idx in (23,26,41,95) else -.04,
              'oval' if shape=='needle' else shape,4 if shape=='needle' else 12 if shape=='banksia' else 8)


def full_shrub_framework(idx,g,phase,rng):
    """Low forks and overlapping leafy shoots retain seven distinct shrub habits."""
    habit,radius,ll,width,shape,arrangement,_=SHRUB[idx]
    early=phase!='mature';scale=.42 if early else 1.
    # Cane count, branches/cane, leafy nodes, secondary shoots, nodes/shoot.
    profiles={21:(11,5,7,3,4),22:(13,5,11,3,5),23:(9,5,7,3,5),
              24:(9,5,6,2,4),25:(13,6,8,3,5),26:(9,5,6,2,4),27:(10,5,7,3,4)}
    canes,branches,nodes,forks,forknodes=profiles[idx]
    if early:canes,branches,nodes,forks,forknodes=3,2,3,0,0
    sites=[]
    def foliage(loc,a,length,halfwidth,young=False):
        # Changing blade pitch gives depth, rather than stacked horizontal fans.
        tilt=(.32 if idx==22 else .19)+.34*math.sin(loc.x*23+loc.y*19+loc.z*27+a)
        leaf(g,loc,a,length,halfwidth,2 if young else 1,tilt,shape if shape!='needle' else 'oval',
             4 if shape=='needle' else 6 if idx in (21,25,27) else 8)
    for i in range(canes):
        a=i*2.39996+rng.uniform(-.16,.16);d=direction(a)
        outside=math.sqrt((i+.6)/canes)
        low=idx in (21,25,26)
        h=scale*((.75-.27*outside if low else .95-.20*outside)*rng.uniform(.91,1.08))
        if idx==25:h*=.83
        spread=radius*scale*(.31+.47*outside if low else .18+.40*outside)
        base=d*scale*(.018+.050*outside)
        tip=d*spread+UP*h
        path=[base,base+d*spread*.18+UP*h*.24,d*spread*.67+UP*h*.70,tip]
        if idx==27:path[2].z+=scale*.065;path[-1].z-=scale*.045
        g.tube(path,[scale*.013,scale*.009,scale*.0045,scale*.0010],5,7)
        for n in range(3 if early else 7):
            p=point(path,.12+n*(.31 if early else .135))
            for side in range(2 if arrangement in ('opposite','whorled') else 1):
                foliage(p,a+n*2.4+side*math.pi,ll*(.60 if early else .90),width*(.60 if early else .90))
        for j in range(branches):
            t=.18+j*(.59 if early else .73/max(1,branches-1))
            origin=point(path,t)
            turn=a+(-1 if j%2 else 1)*rng.uniform(.65,1.25)
            # The lower branches form a leafy skirt; upper tips close the dome.
            span=radius*scale*(.43 if low else .42)*(1-.27*t)*rng.uniform(.91,1.13)
            rise=scale*(.020 if low else .11 if idx in (22,24) else .060)
            end=origin+direction(turn)*span+UP*rise
            branch=[origin,origin.lerp(end,.53)+UP*scale*.040,end]
            g.tube(branch,[scale*.0045,scale*.0023,scale*.00055],0,5)
            for n in range(nodes):
                p=point(branch,.12+n*.86/max(1,nodes-1))
                for side in range(3 if arrangement=='whorled' else 2 if arrangement=='opposite' else 1):
                    a_leaf=turn+n*2.4+side*TAU/(3 if arrangement=='whorled' else 2)
                    factor=(.61 if early else .90)*rng.uniform(.87,1.12)
                    foliage(p,a_leaf,ll*factor,width*factor,n==nodes-1)
            if early:continue
            # Flowers face outward above their supporting shoot's last leaves.
            if idx!=21 or (i+j)%4!=0:sites.append((end,direction(turn,.65 if idx in (21,23,26) else .48)))
            for k in range(forks):
                p=point(branch,.22+k*.31);aa=turn+(-.92 if k%2 else .92)
                length=ll*(1.50 if idx in (22,25) else 1.16)
                q=p+direction(aa)*length+UP*scale*(.045+.025*(k%2))
                g.tube([p,p.lerp(q,.55)+UP*.022,q],[.0019,.0010,.00025],0,4)
                for n in range(forknodes):
                    loc=p.lerp(q,.15+n*.83/max(1,forknodes-1))
                    for side in range(2 if arrangement in ('opposite','whorled') else 1):
                        factor=.83*rng.uniform(.90,1.11)
                        foliage(loc,aa+n*2.4+side*math.pi,ll*factor,width*factor,n==forknodes-1 and k==2)
    return sites


def shrub(idx,phase):
    g,b,buds=groups();rng=random.Random(idx*5113+{'mature':0,'seedling':7,'juvenile':31}[phase])
    habit,radius,ll,width,shape,arrangement,canes=SHRUB[idx];early=phase!='mature'
    scale={'mature':1.,'seedling':.15,'juvenile':.42}[phase]
    sites=[]
    if phase=='seedling':
        path=[Vector((0,0,0)),Vector((.006,0,.07)),Vector((0,.008,.15))]
        g.tube(path,[.006,.004,.001],0,5)
        for k in range(4):
            sides=2 if arrangement in ('opposite','whorled') else 1
            for side in range(sides):shrub_leaf(idx,g,point(path,.2+k*.25),k*2.4+side*math.pi,ll*.45,width*.45,shape,2 if k==3 else 1,True)
        return g,b,buds
    if 21<=idx<=27:
        sites=full_shrub_framework(idx,g,phase,rng)
    else:
        for i in range(3 if early else canes):
            a=i*2.39996+rng.uniform(-.18,.18);d=direction(a)
            h=scale*rng.uniform(.66,.88);reach=radius*scale*(.46 if habit in ('arching','spreading') else .24)
            path=[d*scale*.028,d*reach*.20+UP*h*.29,d*reach*.63+UP*h*.76,d*reach+UP*h]
            if habit in ('arching','spreading'):path[2].z+=scale*.08;path[-1].z-=scale*.10
            g.tube(path,[scale*.012,scale*.008,scale*.0038,scale*.0009],5,7)
            for node in range(3 if early else 5):
                loc=point(path,.25+node*(.28 if early else .17));angle=a+node*2.4
                for side in range(2 if arrangement=='opposite' else 1):
                    shrub_leaf(idx,g,loc,angle+side*math.pi,ll*(.60 if early else 1),width*(.60 if early else 1),shape,1,early)
            for j in range(2 if early else 4):
                base=point(path,.35+j*(.42 if early else .17));angle=a+(-1 if j%2 else 1)*rng.uniform(.60,1.20)
                length=radius*scale*(.75 if habit=='cushion' else .65)*rng.uniform(.74,1.15)
                tip=base+direction(angle)*length+UP*scale*(.09 if habit=='upright' else -.035 if habit=='arching' else .035)
                branch=[base,base.lerp(tip,.55)+UP*scale*.035,tip]
                g.tube(branch,[scale*.0045,scale*.0023,scale*.0006],0,5)
                count=3 if early else 7 if idx in (22,25,43) else 5
                for n in range(count):
                    t=.14+n*.80/max(1,count-1);loc=point(branch,t)
                    for side in range(3 if arrangement=='whorled' else 2 if arrangement=='opposite' else 1):
                        la=angle+n*2.4+side*TAU/(3 if arrangement=='whorled' else 2)
                        fac=(.60 if early else 1)*rng.uniform(.83,1.10)
                        shrub_leaf(idx,g,loc,la,ll*fac,width*fac,shape,2 if n==count-1 else 1,early)
                if not early:
                    sites.append((tip,direction(angle,.45)))
                    for fork in range(1 if idx in (38,40,95) else 2):
                        origin=point(branch,.45+fork*.33);turn=angle+(-.95 if fork else .87)
                        end=origin+direction(turn)*ll*1.1+UP*.025
                        g.tube([origin,end],[.0015,.0003],0,4)
                        for n in range(3):
                            loc=origin.lerp(end,.22+n*.33)
                            for side in range(2 if arrangement in ('opposite','whorled') else 1):
                                shrub_leaf(idx,g,loc,turn+n*2.4+side*math.pi,ll*.79,width*.79,shape,1)
    if early:return g,b,buds
    for j,(anchor,axis) in enumerate(sites):
        if idx==21:
            for k in range(3):
                q=anchor+direction(k*2.4)*.040+UP*.010*k
                g.tube([anchor,q],[.0011,.0004],0,3)
                petalled(b,q,direction(j*2.4+k,.65),.056,5,1,j);closed_bud(buds,q,.011)
        elif idx in (23,26):
            if j%2:continue
            petalled(b,anchor,axis,.081 if idx==23 else .085,8 if idx==23 else 7,4 if idx==23 else 3,j)
            closed_bud(buds,anchor,.018)
        elif idx==24:
            if j%2:continue
            start=len(b.v)
            for k in range(32):
                t=(k+.3)/32;aa=k*2.4;rr=.073*(1-t)**.6
                q=Vector(anchor)+direction(aa)*rr+UP*(.18*t)
                b.tube([anchor,q],[.0012,.00035],3,3)
                u,v,n=frame(direction(aa,.70))
                for lobe in range(4):
                    d=u*math.cos(lobe*TAU/4)+v*math.sin(lobe*TAU/4)
                    petal(b,q,d,n,.015,.0065,0,.23,.01,3,3)
                b.ellipsoid(q+n*.002,(.0025,.0025,.002),2,2,5)
            # Panicle opens around one supporting branch attachment.
            mark_anchor(b,start,anchor);closed_bud(buds,anchor,.030)
        elif idx in (27,42):
            start=len(b.v)
            for k in range(6):
                q=Vector(anchor)+direction(k*2.4)*.027-UP*(.025+k*.006)
                b.tube([anchor,q],[.0011,.0004],3,3)
                b.ellipsoid(q,(.015,.015,.014),0 if k%3 else 6,5,8)
                # Blueberry's indented five-point crown remains readable nearby.
                if idx==27:
                    for n in range(5):
                        leaf(b,q+UP*.013,n*TAU/5,.005,.0018,5,0,'oval',2)
            mark_anchor(b,start,anchor);closed_bud(buds,anchor,.012)
        elif idx==22:
            start=len(b.v)
            for k in range(5):
                q=Vector(anchor)-UP*k*.021+direction(k*2.4)*.010
                u,v,n=frame(direction(j*2.4,.2))
                petal(b,q,u+n*.2,n,.020,.012,0,.28,.02,4,3)
                petal(b,q,-u+n*.3,n,.012,.006,6,.28,.02,4,3)
            mark_anchor(b,start,anchor);closed_bud(buds,anchor,.006)
        elif idx==25:
            if j%3:continue
            start=len(b.v);leaf(b,anchor,j*2.4,.028,.012,3,.35,'round',4)
            mark_anchor(b,start,anchor);closed_bud(buds,anchor,.007)
        elif idx==43:
            for k in range(3):
                q=Vector(anchor)+direction(k*2.4)*.026
                g.tube([anchor,q],[.0008,.0003],0,3)
                petalled(b,q,direction(j*2.4+k,.75),.025,5,1,k);closed_bud(buds,q,.006)
        elif idx==38:
            start=len(b.v)
            for k in range(7):
                q=Vector(anchor)+direction(k*2.4)*(.03+.015*(k%2))+UP*.026*(k%3)
                b.tube([anchor,q],[.0011,.0004],3,3)
                b.ellipsoid(q,(.018,)*3,0,5,9)
                for n in range(6):
                    e=q+direction(n*2.4,.4)*.020
                    b.tube([q,e],[.00065,.0003],0,3)
            mark_anchor(b,start,anchor);closed_bud(buds,anchor,.013)
        elif idx in (39,40,41,95):
            if idx in (41,95) and j%2:continue
            brush_head(b,anchor,axis,.092 if idx==95 else .087 if idx==41 else .080,
                       {39:'bottlebrush',40:'grevillea',41:'banksia',95:'waratah'}[idx],j)
            closed_bud(buds,anchor,.024 if idx in (41,95) else .016)
    return g,b,buds


def brush_head(b,anchor,axis,radius,kind,seed):
    """Distinct native inflorescences, rather than recoloured generic brushes."""
    anchor=Vector(anchor);u,v,n=frame(axis);start=len(b.v)
    if kind=='waratah':
        for ring in range(2):
            for k in range(12):
                a=k*TAU/12+ring*.26;d=u*math.cos(a)+v*math.sin(a)
                petal(b,anchor-n*radius*.22,d+n*.72,n,radius*(1-ring*.13),radius*.26,6,.35,.03,5,3)
        for k in range(65):
            t=(k+.5)/65;a=k*2.4;rr=radius*.80*math.sqrt(t)
            q=anchor+(u*math.cos(a)+v*math.sin(a))*rr+n*radius*.94*math.sqrt(1-t)
            end=q+(u*math.cos(a)+v*math.sin(a))*radius*.17+n*radius*.12
            b.tube([q,q+n*radius*.25,end],[radius*.032,radius*.030,radius*.011],0,4)
            b.ellipsoid(end,(radius*.029,radius*.029,radius*.045),0,3,5)
    elif kind=='gum':
        for flower in range(5):
            c=anchor+(u*math.cos(flower*2.4)+v*math.sin(flower*2.4))*radius*.45+n*radius*(.12+.15*(flower%2))
            b.tube([anchor,c],[radius*.038,radius*.020],3,4)
            b.ellipsoid(c,(radius*.16,radius*.16,radius*.20),3,4,7)
            for k in range(21):
                a=k*2.4;end=c+(u*math.cos(a)+v*math.sin(a))*radius*.40+n*radius*(.40+.15*(k%3)/2)
                b.tube([c,c.lerp(end,.55)+n*radius*.10,end],[radius*.020,radius*.013,radius*.008],0,3)
                b.ellipsoid(end,(radius*.026,)*3,2,2,4)
    else:
        length=radius*(2.3 if kind in ('banksia','bottlebrush') else 1.7)
        b.tube([anchor,anchor+n*length],[radius*.075,radius*.04],3,6)
        if kind=='banksia':b.ellipsoid(anchor+n*length*.52,(radius*.48,radius*.48,length*.57),6,7,12)
        count=110 if kind in ('banksia','bottlebrush') else 42
        for k in range(count):
            t=(k+.5)/count;a=k*2.39996
            if kind=='grevillea':a=math.pi*.5+math.sin(k*1.3)*.68
            d=u*math.cos(a)+v*math.sin(a);base=anchor+n*length*t
            r=radius*(.85 if kind=='bottlebrush' else .73 if kind=='banksia' else 1.0)
            end=base+d*r+n*radius*.12
            points=[base,base+d*r*.55+n*radius*.36,end] if kind in ('grevillea','banksia') else [base,end]
            b.tube(points,[radius*.025]*(len(points)-1)+[radius*.012],0,3)
            b.ellipsoid(end,(radius*.034,)*3,2 if kind!='banksia' else 0,2,4)
    mark_anchor(b,start,anchor)


def roses(idx,phase):
    g,b,buds=groups();rng=random.Random(idx*7949+{'mature':0,'seedling':7,'juvenile':23}[phase])
    early=phase!='mature';scale={'mature':1.,'seedling':.15,'juvenile':.42}[phase]
    if phase=='seedling':
        path=[Vector((0,0,0)),Vector((.006,0,.07)),Vector((0,.007,.15))]
        g.tube(path,[.005,.003,.001],0,5)
        for k in range(3):rose_leaf(g,point(path,.28+k*.30),k*2.4,.095,k==2,True)
        return g,b,buds
    count=3 if early else 9 if idx==74 else 7
    sites=[]
    for j in range(count):
        a=j*2.39996;h=scale*rng.uniform(.68,.96);reach=scale*(.15 if idx==73 else .31 if idx in (75,76) else .23)
        path=[direction(a)*scale*.024,direction(a)*reach*.35+UP*h*.43,direction(a)*reach+UP*h]
        if idx in (75,76):path[-1].z-=scale*.08
        g.tube(path,[scale*.012,scale*.007,scale*.0014],0,7)
        for k in range(3 if early else 6):
            loc=point(path,.20+k*(.32 if early else .145))
            rose_leaf(g,loc,a+k*2.4,scale*rng.uniform(.16,.22),k==5,early)
            if not early and k%2==0:g.tube([loc,loc+direction(a+k)*.018-UP*.006],[.003,.0001],0,4)
        sites.append((path[-1],direction(a,.90)))
        for fork in range(1 if early else 2):
            start=point(path,.48+fork*.24);turn=a+(-.9 if fork else .9)
            end=start+direction(turn)*scale*.20+UP*scale*(.18 if idx==73 else .10)
            shoot=[start,start.lerp(end,.56)+UP*scale*.03,end]
            g.tube(shoot,[scale*.0032,scale*.0015,scale*.0005],0,5)
            for k in range(2 if early else 3):rose_leaf(g,point(shoot,.18+k*.33),turn+(-1 if k%2 else 1),scale*.16,k==2,early)
            if not early:sites.append((end,direction(turn,.65)))
    if early:return g,b,buds
    for j,(anchor,axis) in enumerate(sites):
        if idx==73 and j%2:continue
        flower_count=2 if idx==74 else 1
        for k in range(flower_count):
            q=Vector(anchor)+direction(j*2.4+k*math.pi)*(.025 if flower_count>1 else 0)+UP*.012*k
            if flower_count>1:g.tube([anchor,q],[.0015,.0005],0,3)
            radius={73:.085,74:.051,75:.084,76:.098,77:.078}[idx]*rng.uniform(.89,1.10)
            petalled(b,q,axis,radius,8 if idx==75 else 7,2 if idx==74 else 4,j,
                     {73:'high',74:'open',75:'cup',76:'ruffled',77:'striped'}[idx])
            closed_bud(buds,q,radius*.23,axis,3)
    return g,b,buds


def bamboo(idx,phase):
    g,b,buds=groups();rng=random.Random(idx*1223+{'mature':0,'seedling':8,'juvenile':29}[phase])
    early=phase!='mature';giant=idx==80;red=idx==72;slender=idx==68
    scale={'mature':1.,'seedling':.055 if giant else .10,'juvenile':.24 if giant else .36}[phase]
    count=1 if phase=='seedling' else 3 if early else 7 if giant else 13 if red else 9
    nodes=4 if phase=='seedling' else 7 if early else 13
    for j in range(count):
        a=j*2.39996;base=direction(a)*math.sqrt((j+.3)/count)*scale*(.075 if giant else .105)
        height=scale*rng.uniform(.76,1);lean=scale*(.065 if slender else .19 if red else .14)
        radius=scale*(.013 if giant else .0045 if red else .0075)
        pts=[]
        for k in range(nodes+1):
            t=k/nodes;z=height*(t**1.22 if idx==69 else t)
            pts.append(base+direction(a)*lean*t*t+UP*z)
        g.tube(pts,[radius*(1-.67*k/nodes) for k in range(nodes+1)],8 if j%4 else 0,10 if giant else 8)
        for k in range(1,nodes):
            p=pts[k];rr=radius*(1-.67*k/nodes)
            g.tube([p-UP*scale*.002,p,p+UP*scale*.002],[rr*1.04,rr*1.22,rr*1.04],6,8)
            if k<3 and j%2==0:leaf(g,p-UP*scale*.012,a,scale*.07,rr*.8,7,.70,'oval',4)
            if k<(2 if early else 5):continue
            for side in range(1 if early or red else 2):
                angle=a+k*1.32+side*2.0;length=scale*(.16 if giant else .23)*(1-k/(nodes*1.6))
                end=p+direction(angle)*length+UP*scale*.020
                twig=[p,p.lerp(end,.60)+UP*scale*.025,end]
                g.tube(twig,[rr*.25,rr*.11,rr*.035],0,4)
                for m in range(3 if early else 6):
                    q=point(twig,.23+m*(.32 if early else .15))
                    for sign in (-1,1):
                        ll=scale*(.042 if giant else .071)*rng.uniform(.85,1.19)
                        leaf(g,q,angle+sign*.77,ll,ll*.075,2 if m==5 else 1,-.27,'oval',4)
    if early:return g,b,buds
    # Unopened sheathed shoots keep bamboo's distinct growth group near its base.
    for k in range(3):
        anchor=direction(k*2.4+.7)*(.06+.025*k);start=len(b.v)
        b.tube([anchor,anchor+UP*.030,anchor+UP*.086],[.017,.011,.0006],3,8)
        for j in range(5):leaf(b,anchor+UP*j*.014,j*2.4,.041,.010,4,.85,'oval',4)
        mark_anchor(b,start,anchor);closed_bud(buds,anchor,.014,UP,3)
    return g,b,buds


def conifer(idx,phase):
    g,b,buds=groups();rng=random.Random(idx*9001+{'mature':0,'seedling':5,'juvenile':43}[phase])
    giant=idx==78;early=phase!='mature';scale={'mature':1.,'seedling':.033,'juvenile':.18}[phase]
    trunk=[Vector((math.sin(k*.67)*.006*scale,math.cos(k*.71)*.005*scale,scale*k/10)) for k in range(11)]
    r=scale*(.053 if giant else .029)
    g.tube(trunk,[r*(1-k/11)**1.18+.0006*scale for k in range(11)],5,14)
    if not early:
        for j in range(7):
            a=j*TAU/7;g.tube([direction(a)*r*1.6,direction(a)*r*.8+UP*.055,UP*.15],[r*.22,r*.28,r*.16],5,6)
    sites=[];tiers=3 if phase=='seedling' else 5 if early else 14
    for tier in range(tiers):
        t=.20+(tier+.2)/tiers*.73;span=scale*(.23 if giant else .19)*(1-t)**.70
        for j in range(3 if early else 5):
            a=j*TAU/(3 if early else 5)+tier*2.4;base=point(trunk,t)
            end=base+direction(a)*span+UP*scale*(.018 if giant else -.01)
            path=[base,base.lerp(end,.67)-UP*scale*.012,end+UP*scale*.017]
            g.tube(path,[scale*.005*(1-t),scale*.002,scale*.0004],5,5)
            for k in range(2 if early else 5):
                origin=point(path,.25+k*(.55 if early else .17))
                for sign in (-1,1):
                    turn=a+sign*.90;length=span*(.36 if giant else .41)
                    tip=origin+direction(turn)*length+UP*scale*.008
                    g.tube([origin,tip],[scale*.00065,scale*.00012],0,3)
                    for node in range(3 if early else 7):
                        q=origin.lerp(tip,(node+.2)/(3 if early else 7))
                        for side in range(3 if giant else 2):
                            ang=turn+(side-1)*1.6 if giant else turn+(-1 if side else 1)*1.05
                            ll=scale*((.010 if giant else .019) if early else (.014 if giant else .023))*(1-node*.035)
                            leaf(g,q,ang,ll,ll*(.30 if giant else .19),1 if tier%3 else 3,.70 if giant and side==1 else .10,'oval',2,False)
            if not early:
                # Foliage extends down the main spray, hiding bare branch centres.
                for node in range(7):
                    q=point(path,.18+node*.115)
                    for side in range(3 if giant else 2):
                        ang=a+(side-1)*1.52 if giant else a+(-1 if side else 1)*1.12
                        ll=(.014 if giant else .024)*(1-node*.025)
                        leaf(g,q,ang,ll,ll*(.30 if giant else .19),1,.52 if giant and side==1 else .13,'oval',2,False)
            if tier%3==1:sites.append(end)
    if not early:
        # The upper leader carries living foliage as well as the branch tiers.
        for node in range(19):
            p=point(trunk,.78+node*.0114)
            for side in range(5):
                aa=side*TAU/5+node*1.1;ll=(.016 if giant else .022)*(1-node*.026)
                leaf(g,p,aa,ll,ll*(.28 if giant else .18),2 if node>14 else 1,.62,'oval',2,False)
        for j,anchor in enumerate(sites[::2]):
            start=len(b.v);r=.0048 if giant else .0037;c=Vector(anchor)-UP*r*1.7
            b.tube([anchor,c+UP*r],[r*.15,r*.08],3,3);b.ellipsoid(c,(r,r,r*1.5),6,5,8,ribs=.05)
            for k in range(8):leaf(b,c+direction(k*2.4)*r*.8-UP*r*.4,k*2.4,r*.72,r*.33,6,.6,'oval',2)
            mark_anchor(b,start,anchor);closed_bud(buds,anchor,r*.6,-UP,3)
    return g,b,buds


def palette(idx):
    if idx not in IDS:raise ValueError(idx)
    name=SPECS[idx][0];bloom=SPECS[idx][2]
    leafcolor={21:'526f40',22:'789381',23:'365f3b',24:'66894d',25:'527644',26:'386844',27:'698857',
      28:'688549',29:'72975b',31:'79896a',32:'8a9e59',33:'436f46',34:'4f7e45',35:'5e8149',38:'729780',
      39:'718752',40:'577b60',41:'6c8151',42:'397250',43:'678665',45:'89a69a',
      68:'528047',69:'578642',70:'4d7848',71:'587f62',72:'5c8658',78:'548467',79:'41765d',80:'5b824b',
      81:'8cad56',82:'5d824a',83:'547b43',84:'6a8d51',85:'54784b',86:'658347',87:'719257',88:'3f7346',
      89:'467c48',90:'4e7b47',91:'467147',92:'94aa99',93:'8fa69a',94:'637f5b',95:'557245'}.get(idx,'4e7543')
    stem={29:'87776a',45:'b9b3a1',68:'64844c',69:'c4ae5b',70:'343831',71:'719b9e',72:'ad5344',80:'799856',
          78:'926249',79:'805745',92:'bfb8a5',93:'c1bcae'}.get(idx,'806b50')
    young={42:'b17b65',70:'72915b',73:'a36e62',77:'a76c62'}.get(idx,'94a36c')
    fol=[('stem',stem,'smooth',False),('leaf',leafcolor,'leaf',True),('young leaf',young,'leaf',True),
         ('dark leaf','3f6645','leaf',True),('silver leaf','95a68e','leaf',True),
         ('bark',stem,'bark',False),('smooth bark','ddd4bc' if idx==29 else stem,'smooth',False),
         ('sheath','b4a086','smooth',False),('culm',stem,'smooth',False)]
    if idx in BAMBOO_IDS:
        fol[0]=('living bamboo shoot','64864f','smooth',False)
        fol[6]=('node collar','b0b996','smooth',False)
    primary={22:'8b94c1',27:'63779e',28:'edc5d0',31:'6e7951',34:'d8be45',35:'bd5c48',38:'e4c449',
             39:'c84447',40:'df795d',41:'d4ad64',42:'c77f9c',43:'e8bfd1',73:'a62940',74:'f4f0df',75:'e7b452',
             76:'e3a27d',77:'ad3550',82:'705276',83:'adac62',84:'df9964',85:'654e7e',86:'dfa15b',87:'ce7047',
             88:'d99444',89:'e1a04a',90:'719b49',91:'415d3c',94:'d54746',95:'bd3c50'}.get(idx,bloom)
    secondary='ede6d5' if idx==77 else 'd9b783' if idx==41 else '967557' if idx in (78,79,94) else primary
    if idx in FRUIT_IDS:
        shades={31:('414b3d','929768'),34:('ead26a','b7a54b'),35:('cf8348','ab4947'),82:('8e6a8f','5d4a67'),
                83:('c1b873','8e974e'),84:('eeb978','c98661'),85:('837095','574363'),86:('edb775','cd8249'),
                87:('e29d54','bb583f'),88:('e8b266','c78339'),89:('efb762','d58b38'),90:('a2b36c','62823f'),91:('5b7247','364c31')}[idx]
        blo=[('ripe fruit',primary,'fruit',False),('cream','eee2c7','petal',False),('pollen','d9bb64','pollen',False),
             ('leaf',leafcolor,'leaf',False),('varied fruit',shades[0],'fruit',False),('shaded fruit',shades[1],'fruit',False),('secondary fruit',primary,'fruit',False)]
    else:
        blo=[('petals',primary,'petal',False),('cream','efe8cc','petal',False),('pollen','d7b85a','pollen',False),
             ('bud green',leafcolor,'leaf',False),('sepal',leafcolor,'leaf',False),('flower lip','76644c' if idx==27 else primary,'petal',False),
             ('cone scales' if idx in (78,79,94) else 'secondary petals',secondary,'bark' if idx in (78,79,94) else 'petal',False)]
    return {'foliage':fol,'bloom':blo}


def build(idx,phase='mature'):
    if idx not in IDS or phase not in ('mature','seedling','juvenile'):raise ValueError((idx,phase))
    if idx in TREE_IDS:return tree(idx,phase)
    if idx in BAMBOO_IDS:return bamboo(idx,phase)
    if idx in (78,79):return conifer(idx,phase)
    if 73<=idx<=77:return roses(idx,phase)
    return shrub(idx,phase)
