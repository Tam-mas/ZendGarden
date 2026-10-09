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
    links=garden_routes.ROUTES['bridge_links']
    points=list(links[0]);end=points[-1][1]
    # Continue the spine directly into the return around the north boundary.
    # Two independently capped ribbons left a square spur on this corner.
    north=links[2]
    stop=north[-1][1]
    points.extend((68.,end-j*.25) for j in range(1,math.ceil((end-stop)/.25)))
    points.append(tuple(north[-1]))
    points.extend(reversed(north[:-1]))
    def width(t):
        k=min(int(t*(len(points)-1)),len(points)-2);x,z=points[k]
        taper=paving.smooth(0,3,7.9-z)*(1-paving.smooth(101.5,103.5,-z))
        return 2.-.12*taper if x>67.9 and z<=7.9 else 2.
    ribbons=paving.ribbon(points,width)
    ribbons.extend(paving.ribbon(links[1],lambda t:2.0))
    # The west bank path connects every crossing even before later beds open.
    ribbons.extend(paving.ribbon([(27.,6.-j*.25) for j in range(433)],lambda t:1.8))
    for z in [6.,-48.,-102.]:
        ribbons.extend(paving.ribbon([(23.+j*.25,z) for j in range(19)] if z==6. else [(25.5+j*.25,z) for j in range(9)],lambda t:2.8))
        ribbons.extend(paving.ribbon([(42.+j*.25,z) for j in range(13)],lambda t:2.8))
    bounds=[(min(p[0] for p in poly),min(p[1] for p in poly),max(p[0] for p in poly),max(p[1] for p in poly)) for poly in ribbons]
    out=[]
    for row in range(-216,23):
        z0=row*.5;z1=z0+.5
        for col in range(46,139):
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
    footprints=polygons()
    for z in [6.,-48.,-102.]:
        cut=[(25.5,z-1.4),(44,z-1.4),(44,z+1.4),(25.5,z+1.4)]
        footprints=[part for poly in footprints for part in paving.difference(poly,cut)]
    data={'version':2,'polygons':footprints}
    path.write_text(json.dumps(data,separators=(',',':'))+'\n')
    print(f'TRAIL_FOOTPRINT: {len(data["polygons"])} disjoint terrain cells')

if __name__=='__main__':write()
