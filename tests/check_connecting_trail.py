"""Audit the shipped bluestone footprint for overlap, missing lanes and spurs."""
import json, math
from pathlib import Path
from check_path_paving import cross, overlap

ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'assets/areas/connecting_trail.json').read_text())
triangles=[];buckets={}
for poly in data['polygons']:
    for k in range(1,len(poly)-1):
        tri=[tuple(poly[0]),tuple(poly[k]),tuple(poly[k+1])]
        if abs(cross(*tri))<1e-8:continue
        assert cross(*tri)>0,('reversed trail cell',tri)
        cells=[(x,z) for x in range(math.floor(min(p[0] for p in tri)),math.floor(max(p[0] for p in tri))+1) for z in range(math.floor(min(p[1] for p in tri)),math.floor(max(p[1] for p in tri))+1)]
        previous=set(j for cell in cells for j in buckets.get(cell,[]))
        for j in previous:assert overlap(tri,triangles[j])<2e-6,('stacked connecting trail',j,tri)
        for cell in cells:buckets.setdefault(cell,[]).append(len(triangles))
        triangles.append(tri)

def covered(point):
    for k in buckets.get((math.floor(point[0]),math.floor(point[1])),[]):
        tri=triangles[k]
        if all(cross(a,b,point)>=-1e-6 for a,b in zip(tri,tri[1:]+tri[:1])):return True
    return False

assert max(p[1] for tri in triangles for p in tri)<11.5,'trail runs to the cliff edge'
assert not covered((68,11.5)),'unused northern path stub'
routes=json.loads((ROOT/'assets/areas/routes.json').read_text())['eastern_link']
for a,b,c in zip(routes[::3],routes[3::3],routes[6::3]):
    length=math.dist(a,c);normal=(-(c[1]-a[1])/length,(c[0]-a[0])/length)
    for side in [-.70,0,.70]:assert covered((b[0]+normal[0]*side,b[1]+normal[1]*side)),('missing bluestone bend lane',b,side)
for z in range(-105,8):
    for x in [67.3,68.,68.7]:assert covered((x,z)),('gap in shared trail',x,z)
for x in range(26,45):
    for z in [5.3,6.,6.7]:assert covered((x,z)),('gap in original connector',x,z)
print(f'CONNECTING_TRAIL_RESULT: PASS — {len(triangles)} disjoint triangles, connected lanes and no cliff spur')
