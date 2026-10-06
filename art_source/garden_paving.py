"""Fitted flags for a whole path network, with one joint pattern at junctions.

Every tile is intersected with the union of the path ribbons. Convex polygon
subtraction gives disjoint pieces without depending on a Blender Boolean or an
extra Python package. Pieces inside one flag touch without an artificial seam.
"""
import math
import garden_routes

EPS = 1e-9

def area(poly):
    return sum(a[0]*b[1]-b[0]*a[1] for a,b in zip(poly,poly[1:]+poly[:1]))*.5

def clean(poly):
    out=[]
    for p in poly:
        if not out or math.dist(p,out[-1])>EPS:out.append(tuple(p))
    if len(out)>1 and math.dist(out[0],out[-1])<EPS:out.pop()
    return out if len(out)>2 and abs(area(out))>EPS else []

def halfplane(poly,a,b,inside=True):
    """Clip a polygon to the left/right side of a directed line."""
    if not poly:return []
    side=lambda p:((b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]))*(1 if inside else -1)
    out=[];previous=poly[-1];d0=side(previous)
    for p in poly:
        d1=side(p)
        if (d0>=0)!=(d1>=0):
            t=d0/(d0-d1)
            out.append(tuple(previous[k]+t*(p[k]-previous[k]) for k in range(2)))
        if d1>=0:out.append(p)
        previous=p;d0=d1
    return clean(out)

def intersection(poly,clip):
    if area(clip)<0:clip=list(reversed(clip))
    for a,b in zip(clip,clip[1:]+clip[:1]):
        poly=halfplane(poly,a,b)
        if not poly:break
    return poly

def difference(poly,clip):
    """Partition the part of a convex polygon outside another convex polygon."""
    if area(clip)<0:clip=list(reversed(clip))
    out=[]
    for a,b in zip(clip,clip[1:]+clip[:1]):
        removed=halfplane(poly,a,b,False)
        if removed:out.append(removed)
        poly=halfplane(poly,a,b)
        if not poly:break
    return out

def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)

def ribbon(points,width):
    edges=[]
    for j,p in enumerate(points):
        a=points[max(0,j-1)];b=points[min(len(points)-1,j+1)]
        dx=b[0]-a[0];dz=b[1]-a[1];length=math.hypot(dx,dz)
        w=width(j/(len(points)-1))*.5
        edges.append([(p[0]-dz/length*w,p[1]+dx/length*w),(p[0]+dz/length*w,p[1]-dx/length*w)])
    quads=[]
    for a,b in zip(edges,edges[1:]):
        quad=[a[0],a[1],b[1],b[0]]
        if area(quad)<0:quad.reverse()
        quads.append(quad)
    return quads

def native_path(index):
    if index==1:return (lambda z:math.sin(z*.42)+.30*math.sin(z*.83)+1.55),1.05
    if index==3:return (lambda z:3*math.sin(z*.4)),1.55
    if index==8:return (lambda z:2.4*math.sin(z*.45)),1.35
    return None

def end_width(index):
    return {0:1.7,1:1.05,2:1.5,3:1.55,7:1.2,8:1.35}.get(index,1.8)

def terminal(index):
    """An exact squared threshold at the court, first tread or deck edge."""
    axis,end,direction={0:(0,7.055,1),2:(1,6.35,1),5:(1,7.,1),6:(1,5.5,1),7:(0,-3.385,-1)}.get(index,(None,0,0))
    if axis is None:return None
    center=garden_routes.point(index,1)
    w=end_width(index)*.5
    if axis==0:return [(end,center[1]-w),(end+direction*.24,center[1]-w),(end+direction*.24,center[1]+w),(end,center[1]+w)]
    return [(center[0]-w,end),(center[0]+w,end),(center[0]+w,end+direction*.24),(center[0]-w,end+direction*.24)]

def footprints(index):
    pieces=[];native=native_path(index)
    if index==1:
        # One continuous ribbon has a shared cross-section through the bend.
        # Two separately capped strips left a triangular spur and a pinched
        # inner edge, even after their overlapping faces were removed.
        approach=garden_routes.ROUTES['approaches'][index]
        center,width=native;end=approach[-1][1]
        count=math.ceil((end+9)/.12)
        points=approach[:-1]+[(center(end-j*(end+9)/count),end-j*(end+9)/count) for j in range(count+1)]
        ratio=(len(points)-1)/(len(approach)-1)
        return ribbon(points,lambda t:1.8+(width-1.8)*smooth(.60,.95,min(1,t*ratio)))
    if native:
        center,width=native
        end=9.
        count=math.ceil((end+9)/.12)
        points=[(center(-9+j*(end+9)/count),-9+j*(end+9)/count) for j in range(count+1)]
        pieces.extend(ribbon(points,lambda t:width))
    width=lambda t:1.8+(end_width(index)-1.8)*smooth(.65,1,t)
    points=garden_routes.ROUTES['approaches'][index]
    if index==9:
        # Continue the ribbon slightly into the court, then cut every flag to
        # the oval boundary. A square terminal here produced an L-shaped strip.
        a,end=points[-2:];length=math.dist(a,end)
        points=points+[tuple(end[k]+(end[k]-a[k])*.65/length for k in range(2))]
    pieces.extend(ribbon(points,width))
    if index==9:
        oval=[(-1+6.5*.98*math.cos(j*math.tau/256),6.3*.98*math.sin(j*math.tau/256)) for j in range(256)]
        pieces=[part for poly in pieces for part in difference(poly,oval)]
    slab=terminal(index)
    if slab:
        # Remove the last partial flag row. One threshold, cut exactly at the
        # destination edge, replaces it; no paving projects into the court.
        axis=0 if index in [0,7] else 1
        end=slab[0][axis];direction=-1 if index==7 else 1
        limit=end+direction*.24
        clipped=[]
        for poly in pieces:
            if axis==0:a,b=((limit,1),(limit,0)) if direction==1 else ((limit,0),(limit,1))
            else:a,b=((0,limit),(1,limit)) if direction==1 else ((1,limit),(0,limit))
            poly=halfplane(poly,a,b)
            if poly:clipped.append(poly)
        pieces=clipped
    return pieces

def flags(index):
    pieces=footprints(index)
    bounds=[(min(p[0] for p in poly),min(p[1] for p in poly),max(p[0] for p in poly),max(p[1] for p in poly)) for poly in pieces]
    xmin=min(b[0] for b in bounds);zmin=min(b[1] for b in bounds);xmax=max(b[2] for b in bounds);zmax=max(b[3] for b in bounds)
    out=[];pitch_x=.60;pitch_z=.64;joint=.010
    for row in range(math.floor(zmin/pitch_z),math.ceil(zmax/pitch_z)):
        shift=(row%2)*pitch_x*.5
        z0=row*pitch_z+joint;z1=(row+1)*pitch_z-joint
        for col in range(math.floor((xmin-shift)/pitch_x),math.ceil((xmax-shift)/pitch_x)):
            x0=col*pitch_x+shift+joint;x1=(col+1)*pitch_x+shift-joint
            tile=[(x0,z0),(x1,z0),(x1,z1),(x0,z1)];covered=[]
            for poly,bb in zip(pieces,bounds):
                if bb[2]<x0 or bb[0]>x1 or bb[3]<z0 or bb[1]>z1:continue
                cut=intersection(tile,poly)
                if not cut:continue
                fragments=[cut]
                for previous in covered:
                    fragments=[part for fragment in fragments for part in difference(fragment,previous)]
                    if not fragments:break
                out.extend(fragments);covered.append(cut)
    return out

def lattice_pieces(poly):
    """Keep metre-grid control points in paving as well as in the terrain.

    Otherwise a saved edit at a tile's interior peak would be interpolated
    between vertices on its edges, raising its collider by too little.
    These cuts do not introduce new visible joints or texture boundaries.
    """
    pieces=[poly]
    for axis in [0,1]:
        for line in range(math.floor(min(p[axis] for p in poly))+1,math.ceil(max(p[axis] for p in poly))):
            a,b=((line,0),(line,1)) if axis==0 else ((0,line),(1,line))
            split=[]
            for piece in pieces:
                for inside in [True,False]:
                    cut=halfplane(piece,a,b,inside)
                    if cut:split.append(cut)
            pieces=split
    return pieces

def build(b,G,root,index):
    path=b.pivot('Arrival path fitted network',root,ground=True,flat=True,arrival_path=True,paving_network=1)
    samples=garden_routes.ROUTES['approaches'][index];grid=b.layout()[index]['heightmap']
    def lattice(x,z):
        xx=max(0,min(24,x+12));zz=max(0,min(24,z+12));ix=min(23,int(xx));iz=min(23,int(zz));tx=xx-ix;tz=zz-iz
        return (grid[iz][ix]*(1-tx)+grid[iz][ix+1]*tx)*(1-tz)+(grid[iz+1][ix]*(1-tx)+grid[iz+1][ix+1]*tx)*tz
    def level(x,z):
        nearest=min(range(len(samples)),key=lambda j:math.hypot(x-samples[j][0],z-samples[j][1]))
        t=nearest/(len(samples)-1)
        y=max(lattice(x,z),b.height(index,x,z))+.125
        y-=.020*(1-smooth(0,.15,t))
        end=garden_routes.point(index,1)
        distance=abs((x-end[0]) if index in [0,7] else (z-end[1])) if index in [0,2,4,5,6,7,9] else math.dist((x,z),end)
        if index==9:distance=max(0,(math.hypot((x+1)/6.5,z/6.3)-.98)*6.3)
        if index in [0,2,5,6,7,9]:
            # The oval court's terrain continues underneath the flags. Leave
            # 15mm of reveal there; coincident faces flicker and expose wedges.
            target=1.51 if index==0 else 1.40+.2*(1-(end[0]/3.6)**2) if index==7 else b.height(index,x,z)+(.155 if index==2 else .05 if index==9 else .035)
            y+=(target-y)*(1-smooth(.22,1.1,distance))
        elif index==4:
            # A modest level landing meets the orchard turf without a raised
            # square lip; its final flags follow the existing route footprint.
            y-=.078*(1-smooth(.10,1.0,distance))
        return y
    material=b.MATS['slate' if index==1 else 'stone']
    polygons=flags(index)
    if terminal(index):polygons.append(terminal(index))
    for poly in [piece for polygon in polygons for piece in lattice_pieces(polygon)]:
        # Small common cuts let both halves of a junction follow the same
        # height field, including restored terrain edits. Clockwise Y-up faces.
        if area(poly)<0:poly=list(reversed(poly))
        G.poly(path,material,[(x,level(x,z),z) for x,z in poly],[tuple(reversed(range(len(poly))))])
    root['paving_network_version']=1
