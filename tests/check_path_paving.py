"""Audit exported path triangles for stacking and courtyard/deck overshoot.

Checks the final GLBs, independently of the authoring mesh grouping. A spatial
bucket keeps the triangle intersection audit local, including differently named
entrance/inner meshes in older exports. --baseline reads the last Git LFS assets.
"""
import json, math, struct, subprocess, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
KINDS=['reedwater','fern_gully','limestone','pollinator','orchard','kitchen','glasshouse','stream','alpine','moon']

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

def read(path,baseline):
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
        if 'mesh' not in node or not node['name'].startswith(('Arrival path','Fitted garden path')):continue
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
        if index in [2,5,6,9]:
            edge={2:6.35,5:7.,6:5.5,9:6.}[index]
            assert min(p[2] for p in points)>=edge-1e-5,(KINDS[index],'paving projects into destination')
        if index==0:assert min(p[0] for p in points)>=7.055-1e-5,('paving projects into boardwalk',points)
        if index==7:assert max(p[0] for p in points)<=-3.385+1e-5,('paving projects into bridge',points)
        if index in [5,6,9]:
            edge={5:7.,6:5.5,9:6.}[index]
            ends=[p for p in points if abs(p[2]-edge)<1e-5]
            assert len(ends)>=2 and all(abs(p[1]-1.235)<1e-5 for p in ends),(KINDS[index],'raised courtyard threshold',ends)
    print(f'PATH_PAVING: {KINDS[index]} — {len(triangles)} disjoint triangles, fitted destination edge')

if __name__=='__main__':
    baseline='--baseline' in sys.argv
    indices=[int(a) for a in sys.argv[1:] if a.isdigit()] or range(10)
    for index in indices:audit(index,baseline)
    print('PATH_PAVING_RESULT: PASS')
