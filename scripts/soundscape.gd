extends Node

# Pre-rendered original loops run on the audio backend, independent of frame rate.
var daylight = 1.0
var rainfall = 0.0
var music_volume = 1.0
var nature_volume = 1.0
var players: Dictionary = {}
var bed=0
const MUSIC=["garden_music","water_music","woodland_music","terrace_music"]

func _ready() -> void:
 for kind in ["garden_music","water_music","woodland_music","terrace_music", "day", "night", "rain","waterside","woodland"]:
  var stream = load("res://assets/audio/"+kind+".wav") as AudioStreamWAV
  var voice = AudioStreamPlayer.new()
  voice.stream = stream
  if OS.has_feature("web"):
   voice.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
  voice.volume_db = -60
  add_child(voice)
  players[kind] = voice
  voice.play()

func _process(delta: float) -> void:
 var gains = {
  "garden_music": music_volume if bed==0 else 0.0,
  "water_music": music_volume if bed==1 else 0.0,
  "woodland_music": music_volume if bed==2 else 0.0,
  "terrace_music": music_volume if bed==3 else 0.0,
  "waterside": nature_volume*daylight if bed==1 else 0.0,
  "woodland": nature_volume*daylight if bed==2 else 0.0,
  "day": nature_volume*daylight*(1-rainfall*.7),
  "night": nature_volume*(1-daylight),
  "rain": nature_volume*rainfall
 }
 for kind in players:
  var voice: AudioStreamPlayer = players[kind]
  var gain=lerpf(db_to_linear(voice.volume_db),float(gains[kind]),1-exp(-delta*.5))
  voice.volume_db=linear_to_db(maxf(.0001,gain))
