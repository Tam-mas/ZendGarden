extends Node

# Pre-rendered original loops run on the audio backend, independent of frame rate.
var daylight = 1.0
var rainfall = 0.0
var music_volume = 1.0:
 set(value):
  music_volume=clampf(value,0.0,1.0)
  var music_bus=AudioServer.get_bus_index("Music")
  if music_bus>=0: AudioServer.set_bus_mute(music_bus,music_volume==0.0)
  if music_volume==0.0:
   for kind in MUSIC:
    if players.has(kind): players[kind].volume_db=-INF
var nature_volume = 1.0
var players: Dictionary = {}
var bed=0
var location_plot=-1
const MUSIC=["garden_music","water_music","woodland_music","terrace_music"]
const MUSIC_FADE_SECONDS=3.5
const AREA_HYSTERESIS=1.5

static func theme_for_plot(index: int, plot_name: String) -> int:
 if index<4: return index
 if index<14:return [1,2,3,0,3,0,2,1,3,2][index-4]
 if plot_name.begins_with("Woodland"): return 2
 if plot_name.begins_with("Orchard"): return 3
 return 0

func update_location(position: Vector3, plots: Array) -> void:
 var nearest=0
 var distance=INF
 for i in range(plots.size()):
  var candidate=position.distance_to(plots[i].center)
  if candidate<distance: nearest=i; distance=candidate
 # Keep the current theme while hovering around the midpoint between areas.
 if location_plot>=0 and location_plot<plots.size() and nearest!=location_plot:
  if position.distance_to(plots[location_plot].center)-distance<AREA_HYSTERESIS: return
 location_plot=nearest
 bed=theme_for_plot(nearest,str(plots[nearest].name))

func _ready() -> void:
 # Keep loops advancing behind a real bus mute, preserving phrase alignment.
 var music_bus=AudioServer.get_bus_index("Music")
 if music_bus<0:
  AudioServer.add_bus()
  music_bus=AudioServer.bus_count-1
  AudioServer.set_bus_name(music_bus,"Music")
 AudioServer.set_bus_mute(music_bus,music_volume==0.0)
 for kind in ["garden_music","water_music","woodland_music","terrace_music", "day", "night", "rain","waterside","woodland"]:
  var stream = load("res://assets/audio/"+kind+".wav") as AudioStreamWAV
  var voice = AudioStreamPlayer.new()
  voice.stream = stream
  if kind in MUSIC: voice.bus="Music"
  if OS.has_feature("web"):
   voice.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
  voice.volume_db = -60
  add_child(voice)
  players[kind] = voice
  voice.play()

func _process(delta: float) -> void:
 # Same tonal palette and 64-second phrases make simultaneous fades compatible.
 # Let nature lead a little more after dark and during rain.
 var music_gain=music_volume*lerpf(.65,1.0,daylight)*(1-rainfall*.15)
 var gains = {
  "garden_music": music_gain if bed==0 else 0.0,
  "water_music": music_gain if bed==1 else 0.0,
  "woodland_music": music_gain if bed==2 else 0.0,
  "terrace_music": music_gain if bed==3 else 0.0,
  "waterside": nature_volume*daylight if bed==1 else 0.0,
  "woodland": nature_volume*daylight if bed==2 else 0.0,
  "day": nature_volume*daylight*(1-rainfall*.7),
  "night": nature_volume*(1-daylight),
  "rain": nature_volume*rainfall
 }
 for kind in players:
  var voice: AudioStreamPlayer = players[kind]
  if kind in MUSIC and music_volume==0.0:
   voice.volume_db=-INF
   continue
  var fade_seconds=MUSIC_FADE_SECONDS if kind in MUSIC else 2.0
  var gain=lerpf(db_to_linear(voice.volume_db),float(gains[kind]),1-exp(-delta/fade_seconds))
  voice.volume_db=linear_to_db(maxf(.0001,gain))
