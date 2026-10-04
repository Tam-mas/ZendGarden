class_name GardenPlantIndex
extends RefCounted

const CELL_SIZE=2.5
var cells: Dictionary={}
var source: Array=[]
var count=-1

func invalidate() -> void:
 count=-1

func nearby(plants: Array, position: Vector3, radius: float) -> Array:
 if count!=plants.size() or not is_same(source,plants):
  cells.clear()
  source=plants
  for i in range(plants.size()):
   var cell=Vector2i(floori(plants[i].pos.x/CELL_SIZE),floori(plants[i].pos.z/CELL_SIZE))
   if not cells.has(cell):cells[cell]=[]
   cells[cell].append(i)
  count=plants.size()
 var result=[]
 for x in range(floori((position.x-radius)/CELL_SIZE),floori((position.x+radius)/CELL_SIZE)+1):
  for z in range(floori((position.z-radius)/CELL_SIZE),floori((position.z+radius)/CELL_SIZE)+1):
   result.append_array(cells.get(Vector2i(x,z),[]))
 result.sort() # Preserve the existing tie-breaking order for stacked plants.
 return result
