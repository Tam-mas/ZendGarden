"""Original deterministic alpine relief. Blender noise, metres before game scale."""
import math
from mathutils import Vector, noise

def smooth(a,b,value):
    t=max(0,min(1,(value-a)/(b-a)));return t*t*(3-2*t)

def fbm(x,z,scale=1,seed=3.7,octaves=4):
    return noise.fractal(Vector((x*scale,z*scale,seed)),1.0,2.0,octaves)

# Asymmetric massifs around the entire basin; shoulders overlap into long watersheds.
MASSIFS=[(-470,-1400,260,280,235),(-610,-1010,335,280,295),(-420,-570,255,235,250),(-535,-140,330,280,260),(-455,380,290,275,245),(-250,820,295,300,240),
         (410,-1500,325,260,280),(625,-1130,290,310,260),(450,-720,345,280,275),(510,-260,270,240,245),(565,250,355,300,250),(325,740,285,300,250),
         (10,-1525,250,270,200),(45,850,240,285,220)]

def height(x,z):
    width=85+max(0,-z)*.085+math.sin(z*.017)*12+math.sin(z*.041)*4
    side=max(0,abs(x+math.sin(z*.002)*50)-width)
    ridge=(1-math.exp(-side/100))*(140+70*math.sin(z*.006+.4)**2)
    broad=fbm(x,z,.008,3.7,5)*28
    fine=fbm(x,z,.032,8.2,3)*13
    end_range=math.exp(-((z+1320)/185)**2)*(170+noise.fractal(Vector((x*.012,z*.007,4.5)),1,2,4)*65)
    erosion=abs(noise.fractal(Vector((x*.013,z*.009,1.2)),1,2,5))*45
    coast=40*math.sin(x*.027)+24*math.sin(x*.061+.7)
    south=smooth(35+coast,420+coast,z)*(145+broad*.6+18*math.sin(x*.012+z*.009))
    north=smooth(1400,1660,-z)*(160+broad*.4)
    base=-42+ridge+(broad+fine+erosion)*min(1,side/40)+end_range+south+north
    # Leave the lake contour and lower shoreline exactly on the original basin.
    land=smooth(55,140,base)*max(smooth(35,140,side),smooth(180,450,z),smooth(1200,1510,-z))
    peaks=[]
    warp=fbm(x,z,.003,7.1,3)*30
    for px,pz,alt,rx,rz in MASSIFS:
        dx=(x-px+warp)/rx;dz=(z-pz+warp*.45)/rz
        radius=math.sqrt(dx*dx+dz*dz)
        peaks.append(alt*math.exp(-radius**1.18*2.1))
    massif=max(peaks)+sum(peaks)*.12
    # Domain-warped long drainage grooves cut the shoulders between rock spurs.
    drainage=abs(noise.fractal(Vector((x*.016+warp*.02,z*.008,12.6)),1,2,4))
    spur=(1-abs(noise.fractal(Vector((x*.012,z*.019,5.3)),1,2,4)))**3
    ledges=fbm(x,z,.053,2.8,3)*5
    relief=massif+spur*37-drainage*55+ledges
    return base+land*max(-12,relief)

def outer_height(x,z,radius,angle):
    """Three irregular ridge chains, with valleys between them and a buried skirt."""
    crest1=math.exp(-((radius-1.23)/.17)**2)
    crest2=math.exp(-((radius-1.69)/.20)**2)
    crest3=math.exp(-((radius-2.12)/.22)**2)
    along=fbm(x,z,.0035,17.4,5)
    crags=(1-abs(fbm(x,z,.011,8.9,4)))**3
    peak=225+125*along+crags*85
    elevated=145+crest1*peak+crest2*(peak*1.2+45)+crest3*(peak*.78+75)
    elevated+=fbm(x,z,.035,4.1,3)*12
    tie=smooth(.94,1.12,radius)
    return (height(x,z)-18)*(1-tie)+elevated*tie
