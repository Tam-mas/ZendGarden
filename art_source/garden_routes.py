"""Shared, metre-spaced route samples for Blender paving and game clearance."""
import json, math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def cubic(points, t):
    a,b,c,d=points;u=1-t
    return tuple(u*u*u*a[k]+3*u*u*t*b[k]+3*u*t*t*c[k]+t*t*t*d[k] for k in range(2))

def resample(points, pitch=.16):
    lengths=[0.]
    for a,b in zip(points,points[1:]):lengths.append(lengths[-1]+math.dist(a,b))
    count=max(2,math.ceil(lengths[-1]/pitch));result=[];j=0
    for i in range(count+1):
        distance=lengths[-1]*i/count
        while j<len(points)-2 and lengths[j+1]<distance:j+=1
        t=(distance-lengths[j])/max(.00001,lengths[j+1]-lengths[j])
        result.append([round(points[j][k]*(1-t)+points[j+1][k]*t,5) for k in range(2)])
    return result

def curve(points):return resample([cubic(points,i/240) for i in range(241)])

def data():
    creek=lambda z:math.sin(z*.42)+.30*math.sin(z*.83)
    curves={
        0: [[11.15,7.9],[9.4,7.9],[8.4,5.1],[7.055,5.1]],
        2: [[11.15,7.9],[9.0,7.9],[6.5,7.7],[6.5,6.35]],
        3: [[-11.15,7.9],[-7.5,7.9],[-2.0,6.0],[3*math.sin(2.4),6.0]],
        4: [[11.15,8.15],[8.8,8.15],[6.0,8.2],[6.0,6.1]],
        6: [[11.15,8.25],[7.0,8.25],[0,8.25],[0,5.5]],
        7: [[-11.15,7.9],[-8.7,7.9],[-8.7,3.0],[-3.385,3.0]],
        8: [[11.15,7.9],[8.0,7.9],[4.0,6.0],[2.4*math.sin(2.7),6.0]],
        # Arrive normal to the oval gravel court, with room for a broad bend.
        9: [[-11.15,7.9],[-7.2,7.9],[-2.95,7.85],[-2.5,6.3*math.sqrt(.98**2-(1.5/6.5)**2)]],
    }
    routes=[curve(curves[i]) if i in curves else [] for i in range(10)]
    # Straight final courses square up to the destination edge, leaving room
    # for a complete threshold slab rather than a thin, diagonally cut tile.
    for i in [0,2,6,7]:
        controls=[list(p) for p in curves[i]];end=controls[-1][:]
        axis=0 if i in [0,7] else 1;direction=-1 if i==7 else 1
        controls[-1][axis]+=direction*.60
        route=[cubic(controls,j/240) for j in range(241)]
        route.extend(tuple(controls[-1][k]+(end[k]-controls[-1][k])*j/20 for k in range(2)) for j in range(1,21))
        routes[i]=resample(route)
    # Pass around the stream's head, above the end of its water mesh. The
    # narrow inner return fits the right-bank path without crossing the creek.
    fern=[]
    for controls in [
        [[-11.15,7.9],[-8.5,7.9],[-6,10.35],[-2,10.35]],
        [[-2,10.35],[0,10.35],[creek(8.3)+1.55+(.42*math.cos(8.3*.42)+.249*math.cos(8.3*.83))*1.5,9.8],[creek(8.3)+1.55,8.3]],
    ]:
        fern.extend([cubic(controls,i/120) for i in range(120)])
    fern.append(tuple([creek(8.3)+1.55,8.3]));routes[1]=resample(fern)
    # A constant-radius kitchen turn fits through the centre of the arch.
    kitchen=[(-11.15+i*9.9/100,8.65) for i in range(101)]
    kitchen.extend((-1.25+1.25*math.sin(i*math.pi/200),7.4+1.25*math.cos(i*math.pi/200)) for i in range(1,101))
    kitchen.extend((0,7.4-i*.4/10) for i in range(1,11));routes[5]=resample(kitchen)
    # Link the original eastern approach to the shared trail around Reedwater.
    entry=[]
    for controls in [
        [[44,6],[46,6],[46,10.35],[49,10.35]],
        [[49,10.35],[53,10.35],[57,10.35],[62,10.35]],
        [[62,10.35],[66,10.35],[68,10.35],[68,7.9]],
    ]:entry.extend([cubic(controls,i/120) for i in range(120)])
    entry.append((68,7.9))
    return {"version":1,"approaches":routes,"eastern_link":resample(entry)}

def point(index,t):
    points=ROUTES['approaches'][index];f=max(0,min(1,t))*(len(points)-1);i=min(len(points)-2,int(f))
    return tuple(points[i][k]*(1-(f-i))+points[i+1][k]*(f-i) for k in range(2))

ROUTES=data()

def write():
    path=ROOT/'assets/areas/routes.json'
    path.write_text(json.dumps(ROUTES,separators=(',',':'))+'\n')

if __name__=='__main__':write()
