class_name GardenTerrain
extends RefCounted

# Sparse metre-grid offsets are persisted by the game. Bilinear interpolation
# keeps sculpting, hover rays, collision meshes and planting on one surface.
static var offsets: Dictionary={}

static func offset_at(x: float,z: float) -> float:
 if offsets.is_empty() or GardenConnectedLand.contains(Vector3(x,0,z)):return 0.0
 var ix=floori(x);var iz=floori(z)
 var tx=x-ix;var tz=z-iz
 var a=float(offsets.get("%d:%d"%[ix,iz],0.0))
 var b=float(offsets.get("%d:%d"%[ix+1,iz],0.0))
 var c=float(offsets.get("%d:%d"%[ix,iz+1],0.0))
 var d=float(offsets.get("%d:%d"%[ix+1,iz+1],0.0))
 var value=lerpf(lerpf(a,b,tx),lerpf(c,d,tx),tz)
 # Keep the outer rock foundation sealed when adjacent soil is shaped. Raw
 # saved offsets are retained; only their influence tapers at the fixed rim.
 if x>=44. and x<=93. and z>=-109. and z<=13.:
  value*=smoothstep(0.,1.25,minf(minf(x-44.,92.-x),minf(z+108.,12.-z)))
 # Saved terrain remains stored, with a graded apron into fixed bridge ends.
 if x>23. and x<25.5 and absf(z-6.)<3.5:
  value*=lerpf(1.,1.-smoothstep(23.,25.5,x),1.-smoothstep(1.4,3.5,absf(z-6.)))
 return value

# Shared with the Blender landscape generator. Existing x/z coordinates remain valid.
static func base_rise(x: float, z: float) -> float:
 var habitat=GardenAreaCatalogue.height_at(Vector3(x,0,z))
 if is_finite(habitat):return habitat
 if GardenConnectedLand.contains(Vector3(x,0,z)):
  return GardenRavine.ground(x,z)-.07
 return original_rise(x,z)

static func original_rise(x: float,z: float) -> float:
 var hill=0.8+0.55*sin(x*.15)+0.45*cos(z*.19)+0.12*sin((x+z)*.5)
 var bridge_a=smoothstep(2.4,5.5,Vector2((x-8.5)*.65,z-5.9).length())
 var bridge_b=smoothstep(2.4,5.5,Vector2(x-17,(z+8.5)*.65).length())
 return hill*bridge_a*bridge_b

static func rise(x: float,z: float) -> float:
 return base_rise(x,z)+offset_at(x,z)

static func point(pos: Vector3) -> Vector3:
 return Vector3(pos.x,.07+rise(pos.x,pos.z),pos.z)

static func ray(origin: Vector3, direction: Vector3) -> Vector3:
 # Bracket and bisect the terrain intersection, including uphill sight lines.
 var previous=origin
 for i in range(1,81):
  var p=origin+direction*float(i)*.15
  if p.y<=point(p).y:
   for j in range(12):
    var mid=(previous+p)*.5
    if mid.y>point(mid).y: previous=mid
    else: p=mid
   return point(p)
  previous=p
 return Vector3.INF
