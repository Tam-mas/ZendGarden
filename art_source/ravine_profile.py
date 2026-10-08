"""Shared metre-scale alpine ravine profile; runtime reads the sampled lattice."""
import math, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
WEST,EAST,NORTH,SOUTH=25.5,44.,-108.,12.
BRIDGES=[6.,-48.,-102.]
def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
def original(x,z):
    hill=.8+.55*math.sin(x*.15)+.45*math.cos(z*.19)+.12*math.sin((x+z)*.5)
    return hill*smooth(2.4,5.5,math.hypot((x-8.5)*.65,z-5.9))*smooth(2.4,5.5,math.hypot(x-17,(z+8.5)*.65))
def center(z):return 34.8+1.05*math.sin(z*.064)+.30*math.sin(z*.18)
def width(z):return 2.0+.24*math.sin(z*.12)+.12*math.sin(z*.31)
def water(z):
    return -1.05-(z+108)*.011-sum(.38*smooth(k-.7,k+.7,z) for k in [-83,-57,-28,-4])
def ground(x,z):
    bank=original(WEST,z)*(1-smooth(WEST,EAST,x))+1.2*smooth(WEST,EAST,x)
    shore=28.8 if x<center(z) else 41.0
    d=abs(x-center(z));w=width(z);reach=abs(shore-center(z))
    floor=water(z)-.40+.43*smooth(w*.42,w,d)
    if d>w:
        floor=water(z)+.03+(bank+.07-(.05*(1-smooth(WEST,EAST,x))+.035*smooth(WEST,EAST,x))-water(z)-.03)*smooth(w,reach,d)
        floor+=.13*math.sin(z*.57+x*1.7)*math.sin(x*3.1-z*.14)*(1-smooth(reach-.8,reach,d))*smooth(w,w+.6,d)
    return floor

def deck(x,z):
    t=(x-WEST)/(EAST-WEST)
    return (original(WEST,z)+.38)*(1-t)+1.325*t+.72*math.sin(math.pi*t)**2

def write():
    data={'version':1,'step':.25,'west':WEST,'east':EAST,'north':NORTH,'south':SOUTH,'bridges':BRIDGES,
          'ground':[[round(ground(WEST+i*.25,NORTH+j*.25),5) for i in range(75)] for j in range(481)],
          'stream':[[round(center(z),5),round(water(z),5),z,round(width(z),5)] for z in [NORTH+j*.25 for j in range(481)]]}
    (ROOT/'assets/areas/ravine.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
if __name__=='__main__':write()
