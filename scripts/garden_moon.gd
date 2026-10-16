class_name GardenMoon
extends RefCounted

# A deliberately short garden month, measured only in saved, playable time.
# Begin near first quarter so the first evening already has a visible moon.
const CYCLE_DAYS=28.0
const START_AGE=7.0
const ANGULAR_RADIUS=.028
const PHASES=["New moon","Waxing crescent","First quarter","Waxing gibbous","Full moon","Waning gibbous","Last quarter","Waning crescent"]
const HORIZON=Vector3(.45121994,0,.89241278)
const RIGHT=Vector3(-.89241278,0,.45121994)

static func at(day: int, clock: float) -> Dictionary:
 var age=fposmod(float(posmod(day-1,28))+clock+START_AGE,CYCLE_DAYS)
 var phase=age/CYCLE_DAYS
 var elongation=phase*TAU
 var sun_angle=(clock-.25)*TAU
 var orbit_angle=sun_angle-elongation
 var direction=(HORIZON*cos(orbit_angle)+Vector3.UP*sin(orbit_angle)).normalized()
 var sunlight=(HORIZON*cos(sun_angle)+Vector3.UP*sin(sun_angle)).normalized()
 return {"age":age,"phase":phase,"name":PHASES[posmod(int(floor(phase*8.+.5)),8)],
  "illumination":(1.-cos(elongation))*.5,"direction":direction,"sun":sunlight}

static func phase_name(day: int, clock: float) -> String:
 return at(day,clock).name

static func description(day: int, clock: float) -> String:
 var state=at(day,clock)
 return "%s · %d%% lit · %s"%[state.name,roundi(state.illumination*100.),"above the horizon" if state.direction.y>0 else "below the horizon"]

static func light_strength(state: Dictionary, daylight: float) -> float:
 return pow(float(state.illumination),1.2)*smoothstep(-.02,.24,float(state.direction.y))*(1.-daylight)
