extends SceneTree

func _initialize() -> void:
 var failures=[]
 var names=[]
 for eighth in range(8):
  var age=float(eighth)*3.5
  var elapsed=fposmod(age-GardenMoon.START_AGE,28.)
  var state=GardenMoon.at(1+int(elapsed),fmod(elapsed,1.))
  names.append(state.name)
  if absf(state.illumination-(1.-cos(float(eighth)*TAU/8.))*.5)>.00001:failures.append("Incorrect phase illumination: "+state.name)
 if names!=GardenMoon.PHASES:failures.append("Eight named phases are not in order")
 var quarter=GardenMoon.at(1,.70)
 var full=GardenMoon.at(8,.85)
 if quarter.direction.y<=0 or full.direction.y<=0:failures.append("Evening quarter/full moon is below the horizon")
 if GardenMoon.at(8,.5).direction.y>=0:failures.append("Full moon visible at noon")
 if GardenMoon.at(1,.65).direction.y<=0:failures.append("No daytime waxing moon")
 if GardenMoon.at(15,.25).direction.y<=0:failures.append("No morning waning moon")
 for day in [1,7,14,21,28,29,498,10000000]:
  for clock in [.0,.25,.5,.75,.999999]:
   var a=GardenMoon.at(day,clock)
   var b=GardenMoon.at(day+28,clock)
   if a.direction.distance_to(b.direction)>.00001 or absf(a.illumination-b.illumination)>.00001:failures.append("Cycle does not repeat")
   if absf(a.direction.length()-1.)>.00001:failures.append("Non-unit moon direction")
   if absf((1.-a.sun.dot(a.direction))*.5-a.illumination)>.00001:failures.append("Bright limb disagrees with the sun")
  var before=GardenMoon.at(day,.999999)
  var after=GardenMoon.at(day+1,0.)
  if before.direction.distance_to(after.direction)>.00002 or absf(before.illumination-after.illumination)>.00001:failures.append("Moon jumps at midnight")
 if GardenMoon.light_strength(GardenMoon.at(22,0.),0.)>.0001:failures.append("New moon casts light")
 if GardenMoon.light_strength(full,0.)<.5:failures.append("Full moon casts no night light")
 if GardenMoon.light_strength(full,1.)>.0001:failures.append("Moon light persists in daylight")
 print("MOON_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
