class_name GardenTerrain
extends RefCounted

# Shared with the Blender landscape generator. Existing x/z coordinates remain valid.
static func rise(x: float, z: float) -> float:
 var hill=0.8+0.55*sin(x*.15)+0.45*cos(z*.19)+0.12*sin((x+z)*.5)
 var bridge_a=smoothstep(2.4,5.5,Vector2((x-8.5)*.65,z-5.9).length())
 var bridge_b=smoothstep(2.4,5.5,Vector2(x-17,(z+8.5)*.65).length())
 return hill*bridge_a*bridge_b

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
