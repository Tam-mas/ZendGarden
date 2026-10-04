extends SceneTree

const Soundscape=preload("res://scripts/soundscape.gd")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var failures=[]
 var sound=Soundscape.new()
 root.add_child(sound)
 sound.set_process(false)
 var plots=[
  {"name":"The beginning","center":Vector3.ZERO},
  {"name":"Willow water","center":Vector3(17,0,0)},
  {"name":"Fern hollow","center":Vector3(17,0,-17)},
  {"name":"Sunrise terrace","center":Vector3(0,0,-17)},
  {"name":"Meadow garden 5","center":Vector3(0,0,-34)},
  {"name":"Orchard garden 6","center":Vector3(17,0,-34)},
  {"name":"Wildflower garden 7","center":Vector3(0,0,-51)},
  {"name":"Woodland garden 8","center":Vector3(17,0,-51)}
 ]
 for i in range(plots.size()):
  sound.update_location(plots[i].center,plots)
  if sound.bed!=[0,1,2,3,0,3,0,2][i]: failures.append("Theme does not match area "+str(i))
 sound.update_location(Vector3.ZERO,plots)
 for x in [8.4,8.6,8.4,8.7]:
  sound.update_location(Vector3(x,0,0),plots)
  if sound.bed!=0: failures.append("Theme flickers at boundary")
 sound.update_location(Vector3(10,0,0),plots)
 if sound.bed!=1: failures.append("Theme failed to change after crossing boundary")
 for kind in sound.players:
  var voice=sound.players[kind]
  if voice.stream.loop_mode!=AudioStreamWAV.LOOP_FORWARD: failures.append("Imported track does not loop forward")
  var expected=AudioStreamWAV.FORMAT_QOA if kind in sound.MUSIC or kind=="rain" else AudioStreamWAV.FORMAT_16_BITS
  if voice.stream.format!=expected: failures.append("Audio compression policy changed")
  if voice.pitch_scale!=1.0: failures.append("Runtime altered concert pitch")
 sound.daylight=1.0
 sound.rainfall=0.0
 sound.music_volume=.7
 sound.nature_volume=.8
 sound.bed=0
 sound._process(60)
 sound.bed=1
 var outgoing=sound.players.garden_music
 var incoming=sound.players.water_music
 sound._process(1)
 if db_to_linear(outgoing.volume_db)<.3 or db_to_linear(incoming.volume_db)<.1: failures.append("Crossfade cuts off a theme")
 var total=0.0
 for kind in sound.MUSIC: total+=db_to_linear(sound.players[kind].volume_db)
 if total>.701: failures.append("Crossfade raises the total music gain")
 sound._process(60)
 var daytime=db_to_linear(incoming.volume_db)
 sound.daylight=0.0
 sound.rainfall=1.0
 sound._process(60)
 if db_to_linear(incoming.volume_db)>=daytime*.7: failures.append("Music did not soften at night in rain")
 if db_to_linear(sound.players.rain.volume_db)<.79: failures.append("Rain did not follow nature volume")
 sound.music_volume=0.0
 var music_bus=AudioServer.get_bus_index("Music")
 if not AudioServer.is_bus_mute(music_bus): failures.append("Zero music volume did not immediately mute its bus")
 for kind in sound.MUSIC:
  if sound.players[kind].bus!=&"Music" or not sound.players[kind].playing: failures.append("Music mute lost bus routing or phrase alignment")
  if sound.players[kind].volume_linear!=0.0: failures.append("Zero slider left residual music output")
 for kind in ["day","night","rain","waterside","woodland"]:
  if sound.players[kind].bus==&"Music": failures.append("Nature routed through music mute")
 sound._process(60)
 for kind in sound.MUSIC:
  if sound.players[kind].volume_db>-79: failures.append("Music volume zero is still audible")
 if db_to_linear(sound.players.rain.volume_db)<.79: failures.append("Music mute also muted nature")
 sound.music_volume=.7
 if AudioServer.is_bus_mute(music_bus): failures.append("Raising music slider did not unmute music")
 sound.nature_volume=0.0
 sound._process(60)
 for kind in ["day","night","rain","waterside","woodland"]:
  if sound.players[kind].volume_db>-79: failures.append("Nature volume zero is still audible")
 for voice in sound.players.values():
  voice.stop()
  voice.stream=null
 sound.players.clear()
 sound.queue_free()
 await process_frame
 # Playback resources are released on the audio thread, after its next mix.
 await create_timer(.5).timeout
 print("SOUNDSCAPE_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)
