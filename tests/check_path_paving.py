"""Audit exported path triangles for stacking and courtyard/deck overshoot.

Checks the final GLBs, independently of the authoring mesh grouping. A spatial
bucket keeps the triangle intersection audit local, including differently named
entrance/inner meshes in older exports. --baseline reads the last Git LFS assets.
"""
import json, math, struct, subprocess, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
KINDS=['reedwater','fern_gully','limestone','pollinator','orchard','kitchen','glasshouse','stream','alpine','moon']
TRAIL_BUCKETS={}
for poly in json.loads((ROOT/'assets/areas/connecting_trail.json').read_text())['polygons']:
    for j in range(1,len(poly)-1):
        tri=[poly[0],poly[j],poly[j+1]]
        for x in range(math.floor(min(p[0] for p in tri)),math.floor(max(p[0] for p in tri))+1):
            for z in range(math.floor(min(p[1] for p in tri)),math.floor(max(p[1] for p in tri))+1):
                TRAIL_BUCKETS.setdefault((x,z),[]).append(tri)

def cross(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])

def overlap(a,b):
    poly=list(a)
    if cross(*b)<0:b=list(reversed(b))
    for p,q in zip(b,b[1:]+b[:1]):
        if not poly:return 0
        out=[];prev=poly[-1];d0=cross(p,q,prev)
        for current in poly:
            d1=cross(p,q,current)
            if (d0>=0)!=(d1>=0):
                t=d0/(d0-d1);out.append(tuple(prev[k]+t*(current[k]-prev[k]) for k in range(2)))
            if d1>=0:out.append(current)
            prev=current;d0=d1
        poly=out
    return abs(sum(p[0]*q[1]-q[0]*p[1] for p,q in zip(poly,poly[1:]+poly[:1]))*.5)

def read(path,baseline,prefixes=('Arrival path','Fitted garden path')):
    raw=path.read_bytes()
    if baseline:
        pointer=subprocess.check_output(['git','show','HEAD:'+str(path.relative_to(ROOT))],cwd=ROOT,text=True)
        oid=next(line.split(':')[1] for line in pointer.splitlines() if line.startswith('oid sha256:'))
        raw=(ROOT/'.git/lfs/objects'/oid[:2]/oid[2:4]/oid).read_bytes()
    n=struct.unpack_from('<I',raw,12)[0];doc=json.loads(raw[20:20+n]);binary=raw[28+n:]
    def values(index):
        a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']]
        code={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']]
        width={'VEC3':3,'SCALAR':1}[a['type']];fmt='<'+code*width
        start=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',struct.calcsize(fmt))
        return [struct.unpack_from(fmt,binary,start+j*stride) for j in range(a['count'])]
    triangles=[];points=[]
    for node in doc['nodes']:
        if 'mesh' not in node or not node['name'].startswith(prefixes):continue
        assert not any(k in node for k in ['matrix','translation','rotation','scale']),('path coordinates unexpectedly transformed',path)
        for primitive in doc['meshes'][node['mesh']]['primitives']:
            vertices=values(primitive['attributes']['POSITION']);ids=values(primitive['indices']);points.extend(vertices)
            for j in range(0,len(ids),3):
                tri=[(vertices[ids[j+k][0]][0],vertices[ids[j+k][0]][2]) for k in range(3)]
                if abs(cross(*tri))>1e-8:triangles.append(tri)
    return triangles,points

def audit(index,baseline):
    path=ROOT/'assets/areas'/f'{KINDS[index]}.glb';triangles,points=read(path,baseline)
    assert triangles,(path,'missing paving')
    buckets={};overlaps=[]
    for j,tri in enumerate(triangles):
        xmin=min(p[0] for p in tri);xmax=max(p[0] for p in tri);zmin=min(p[1] for p in tri);zmax=max(p[1] for p in tri)
        cells=[(x,z) for x in range(math.floor(xmin),math.floor(xmax)+1) for z in range(math.floor(zmin),math.floor(zmax)+1)]
        previous=set(k for cell in cells for k in buckets.get(cell,[]))
        for k in previous:
            size=overlap(tri,triangles[k])
            if size>2e-6:overlaps.append((k,j,size))
        for cell in cells:buckets.setdefault(cell,[]).append(j)
    assert not overlaps,(KINDS[index],'stacked path flags',len(overlaps),overlaps[:3])
    if not baseline:
        center=(56+(index%2)*24,-(index//2)*24)
        for tri in triangles:
            world=[(p[0]+center[0],p[1]+center[1]) for p in tri]
            for x in range(math.floor(min(p[0] for p in world)),math.floor(max(p[0] for p in world))+1):
                for z in range(math.floor(min(p[1] for p in world)),math.floor(max(p[1] for p in world))+1):
                    for main in TRAIL_BUCKETS.get((x,z),[]):
                        assert overlap(world,main)<2e-6,(KINDS[index],'entrance overlaps shared trail',world)
        if index in [2,5,6]:
            edge={2:6.35,5:7.,6:5.5}[index]
            assert min(p[2] for p in points)>=edge-1e-5,(KINDS[index],'paving projects into destination')
        if index==0:assert min(p[0] for p in points)>=7.055-1e-5,('paving projects into boardwalk',points)
        if index==7:assert max(p[0] for p in points)<=-3.385+1e-5,('paving projects into bridge',points)
        if index==8:
            assert min(p[2] for p in points)>5.,'alpine paving still climbs the steep hillside'
            _,railing=read(path,False,('Lookout railing',))
            assert railing and min(p[1] for p in railing)>5.3,'lookout fence is below the hilltop'
        if index in [5,6]:
            edge={5:7.,6:5.5}[index]
            ends=[p for p in points if abs(p[2]-edge)<1e-5]
            assert len(ends)>=2 and all(abs(p[1]-1.235)<1e-5 for p in ends),(KINDS[index],'raised courtyard threshold',ends)
        if index==2:
            # Compare the finished entry with the actual exported stair, rather
            # than assuming that the soil query equals the tread's height.
            _,treads=read(path,False,('Terrace steps',))
            edge=[p for p in treads if abs(p[2]-6.35)<1e-5]
            assert edge,('missing first terrace tread',path)
            top=max(p[1] for p in edge)
            ends=[p for p in points if abs(p[2]-6.35)<1e-5]
            assert len(ends)>=2 and all(abs(p[1]-top)<1e-5 for p in ends),('terrace threshold differs from first tread',top,ends)
            assert abs(min(p[0] for p in ends)-min(p[0] for p in edge))<1e-5 and abs(max(p[0] for p in ends)-max(p[0] for p in edge))<1e-5,('terrace landing misses a corner',ends)
        if index==9:
            # The Moon court is oval, so a constant-Z bound cannot detect
            # the long sideways strip or fit both sides of its entrance.
            radius=lambda p:math.hypot((p[0]+1)/6.5,p[2]/6.3)
            assert min(radius(p) for p in points)>.9798,('paving projects into oval court',min(radius(p) for p in points))
            ends=[p for p in points if abs(radius(p)-.98)<.0002]
            assert len(ends)>8 and all(min(abs(p[1]-1.250),abs(p[1]-1.248))<1e-5 for p in ends),('incorrect oval threshold reveal',ends)
            assert any(abs(p[1]-1.250)<1e-5 for p in ends),('missing flush stone edge',path)
        if index in [1,3,8,9]:
            route=json.loads((ROOT/'assets/areas/routes.json').read_text())['approaches'][index]
            radii=[math.dist(a,b)*math.dist(b,c)*math.dist(c,a)/(2*abs(cross(a,b,c))) for a,b,c in zip(route,route[1:],route[2:]) if abs(cross(a,b,c))>1e-8]
            assert min(radii)>1.1,(KINDS[index],'turn too tight for the paving width',min(radii))
            # A bend must retain its walkable width in the final export.
            # Allow only the 2cm mortar joints, not missing wedges or a spur.
            for j in range(int(len(route)*.70),len(route)-1):
                a,b,c=route[j-1:j+2];length=math.dist(a,c)
                normal=(-(c[1]-a[1])/length,(c[0]-a[0])/length)
                for side in [-.38,0,.38]:
                    point=(b[0]+normal[0]*side,b[1]+normal[1]*side)
                    if index==9 and math.hypot((point[0]+1)/6.5,point[1]/6.3)<.981:continue
                    candidates=buckets.get((math.floor(point[0]),math.floor(point[1])),[])
                    covered=False
                    for dx,dz in [(0,0),(.025,0),(-.025,0),(0,.025),(0,-.025)]:
                        q=(point[0]+dx,point[1]+dz)
                        for k in candidates:
                            signs=[cross(p,r,q) for p,r in zip(triangles[k],triangles[k][1:]+triangles[k][:1])]
                            if min(signs)>=-1e-7 or max(signs)<=1e-7:covered=True;break
                        if covered:break
                    assert covered,(KINDS[index],'missing paving across bend',point)
    print(f'PATH_PAVING: {KINDS[index]} — {len(triangles)} disjoint triangles, fitted destination edge')

if __name__=='__main__':
    baseline='--baseline' in sys.argv
    indices=[int(a) for a in sys.argv[1:] if a.isdigit()] or range(10)
    for index in indices:audit(index,baseline)
    print('PATH_PAVING_RESULT: PASS')
