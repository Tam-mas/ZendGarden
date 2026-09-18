extends Node

# Pre-rendered original loops run on the audio backend, independent of frame rate.
var daylight = 1.0
var rainfall = 0.0
var music_volume = 1.0
var nature_volume = 1.0
var players: Dictionary = {}

func _ready() -> void:
 for kind in ["garden_music", "day", "night", "rain"]:
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
  "garden_music": music_volume,
  "day": nature_volume*daylight*(1-rainfall*.7),
  "night": nature_volume*(1-daylight),
  "rain": nature_volume*rainfall
 }
 for kind in players:
  var voice: AudioStreamPlayer = players[kind]
  var target = linear_to_db(maxf(.0001,float(gains[kind])))
  voice.volume_db = lerpf(voice.volume_db,target,1-exp(-delta*4))
