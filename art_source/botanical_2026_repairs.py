"""Focused pumpkin attachment and giant-redwood art revisions."""
import math
from mathutils import Vector
from botanical_2026_geometry import radial, stem, bud
from plant_full_herbs import Tissue, round_leaf, palette as herb_palette
from plant_full_woody import palette as woody_palette
from fruit_tree_geometry import mark_anchor

IDS=(49,78,79)

def palette(idx):return herb_palette(idx) if idx==49 else woody_palette(idx)

def pumpkin(phase):
 g,b,bs=Tissue(),Tissue(),Tissue();s={'mature':1,'seedling':.24,'juvenile':.58}[phase]
 count={'mature':4,'seedling':1,'juvenile':2}[phase]
 for j in range(count):
  a=j*2.39996;pts=[Vector((0,0,.018)),radial(a+.12,.40*s,.027),radial(a,.95*s,.025)]
  stem(g,pts,.018*s,0,8)
  for k in range(1,5):
   t=k/5;base=pts[0].lerp(pts[-1],t);base.z=.027
   leafbase=base+radial(a+(-1 if k%2 else 1)*1.3,.14*s,.22*s)
   stem(g,[base,base.lerp(leafbase,.5),leafbase],.010*s,0,6)
   round_leaf(g,leafbase,.24*s,1 if k%2 else 2,5,True)
  if phase=='mature':
   # A stout visible peduncle joins each ground-resting fruit to its own vine.
   anchor=pts[0].lerp(pts[-1],.64);anchor.z=.027
   center=anchor+radial(a+.95,.22,.19);first=len(b.v)
   b.ellipsoid(center,(.23,.23,.19),0,16,32,ribs=.14)
   top=center+Vector((0,0,.19))
   stem(b,[anchor,anchor+radial(a+.6,.09,.20),top+Vector((0,0,.06)),top],.023,3,8)
   mark_anchor(b,first,anchor);bud(bs,anchor,.06)
 return g,b,bs

def geometry(idx):
 if idx==49:
  g,b,bs=pumpkin('mature');return [g,b,bs,pumpkin('seedling')[0],pumpkin('juvenile')[0]]
 # Retain the distinct existing redwood spray/branch design and small juveniles.
 from build_full_plant_art import normalized
 import plant_full_woody
 result,_=normalized(idx,plant_full_woody)
 xy=2.65 if idx==78 else 2.8
 z=(42.0 if idx==78 else 48.0)/max(p[2] for p in result[0].v+result[1].v)
 for geo in result[:3]:
  geo.v=[(p[0]*xy,p[1]*xy,p[2]*z) for p in geo.v]
  if hasattr(geo,'fruit_anchors'):geo.fruit_anchors={i:(p[0]*xy,p[1]*xy,p[2]*z) for i,p in geo.fruit_anchors.items()}
 return result
