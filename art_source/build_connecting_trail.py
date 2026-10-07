"""One disjoint, terrain-editable footprint for the full bluestone trail.

Keep these cuts on the half-metre lattice used by the walking terrain. The
runtime supplies heights, so existing saves and sculpting keep their shape.
"""
import json, math
from pathlib import Path
import garden_paving as paving
import garden_routes

ROOT=Path(__file__).resolve().parents[1]

def hull(points):
    # Rounding collinear clip points can create microscopic reversed slivers.
    # Restore the convex fragment before serialising its triangle fan.
    points=sorted(set(points))
    def side(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    chains=[]
    for sequence in [points,list(reversed(points))]:
        chain=[]
        for p in sequence:
            while len(chain)>1 and side(chain[-2],chain[-1],p)<=1e-10:chain.pop()
            chain.append(p)
        chains.append(chain[:-1])
    return chains[0]+chains[1]

def polygons():
    link=garden_routes.ROUTES['eastern_link']
    points=[(25+j*.25,6.) for j in range(76)]+link
    # The curved link turns into the main trail. There is no north-facing stub
    # beyond that bend, and neither strip has a cap stacked over the other.
    end=points[-1][1]
    points.extend((68.,end-j*.25) for j in range(1,math.ceil((end+106)/.25)+1))
    points[-1]=(68.,-106.)
    def width(t):
        d=t*(len(points)-1);k=min(int(d),len(points)-2)
        x,z=points[k]
        if x<44:return 3.-paving.smooth(39,44,x)
        return 2.-.12*paving.smooth(0,3,7.9-z) if x>67.9 and z<=7.9 else 2.
    ribbons=paving.ribbon(points,width)
    bounds=[(min(p[0] for p in poly),min(p[1] for p in poly),max(p[0] for p in poly),max(p[1] for p in poly)) for poly in ribbons]
    out=[]
    for row in range(-212,23):
        z0=row*.5;z1=z0+.5
        for col in range(50,139):
            x0=col*.5;x1=x0+.5
            tile=[(x0,z0),(x1,z0),(x1,z1),(x0,z1)];covered=[]
            for poly,bb in zip(ribbons,bounds):
                if bb[2]<x0 or bb[0]>x1 or bb[3]<z0 or bb[1]>z1:continue
                cut=paving.intersection(tile,poly)
                if not cut:continue
                fragments=[cut]
                for previous in covered:
                    fragments=[part for fragment in fragments for part in paving.difference(fragment,previous)]
                    if not fragments:break
                for fragment in fragments:
                    if abs(paving.area(fragment))>1e-7:
                        rounded=hull([(round(x,6),round(z,6)) for x,z in fragment])
                        if len(rounded)>2 and paving.area(rounded)>1e-7:out.append(rounded)
                covered.append(cut)
    return out

def write():
    garden_routes.write()
    path=ROOT/'assets/areas/connecting_trail.json'
    data={'version':1,'polygons':polygons()}
    path.write_text(json.dumps(data,separators=(',',':'))+'\n')
    print(f'TRAIL_FOOTPRINT: {len(data["polygons"])} disjoint terrain cells')

if __name__=='__main__':write()
