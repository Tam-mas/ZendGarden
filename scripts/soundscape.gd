extends Node

# Original generative pentatonic score, wind, water and birds; no audio assets.
var daylight = 1.0
var rainfall = 0.0
var player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var sample_index = 0
var rng = RandomNumberGenerator.new()
var smooth_noise = 0.0
var music_rng=RandomNumberGenerator.new()
var last_beat=-1
var melody_index=3
var melody_frequency=261.63
var note_rest=false
var voice=0
var music_volume=1.0
var nature_volume=1.0
const RATE = 22050.0
const NOTES = [130.81,164.81,196.0,261.63,293.66,329.63,392.0,523.25]

func _ready() -> void:
 rng.seed=159
 music_rng.randomize()
 player=AudioStreamPlayer.new()
 var stream=AudioStreamGenerator.new()
 stream.mix_rate=RATE
 stream.buffer_length=0.25
 player.stream=stream
 add_child(player)
 player.play()
 playback=player.get_stream_playback()

func _process(_delta: float) -> void:
 if not playback: return
 var count=playback.get_frames_available()
 var buffer=PackedVector2Array()
 buffer.resize(count)
 for i in range(count):
  var t=sample_index/RATE
  var beat=int(t/3.1)
  var elapsed=fmod(t,3.1)
  var section=int(beat/16)
  if beat!=last_beat:
   last_beat=beat
   melody_index=clampi(melody_index+music_rng.randi_range(-2,2),0,7)
   melody_frequency=NOTES[melody_index]*[1.0,.75,.9,1.125][section%4]
   note_rest=music_rng.randf()<.27 or beat%16==15
   voice=section%3
  var freq=melody_frequency
  var envelope=(1.0-exp(-elapsed*5.0))*exp(-elapsed*(1.5 if voice==0 else .8))
  var fundamental=sin(TAU*freq*t)
  var overtone=sin(TAU*freq*(2.0 if voice!=2 else 3.0)*t)
  var note=(fundamental*.03+overtone*(.008 if voice==0 else .003))*envelope
  if voice==1: note*=.8+.2*sin(TAU*4.5*elapsed)
  if note_rest: note=0.0
  var chord_fade=smoothstep(0,12,fmod(t,49.6))
  var roots=[130.81,98.0,117.43,147.17]
  var root_now=float(roots[section%4])
  var root_before=float(roots[(section+3)%4])
  var pad_now=sin(TAU*root_now*t)*.007+sin(TAU*root_now*1.5*t)*.005
  var pad_before=sin(TAU*root_before*t)*.007+sin(TAU*root_before*1.5*t)*.005
  var pad=lerpf(pad_before,pad_now,chord_fade)
  # A sparse high bell, with a slow attack to keep the ambience gentle.
  var bell_time=fmod(t,37.3)
  var bell=sin(TAU*784*t)*.006*(1-exp(-bell_time*6))*exp(-bell_time*1.4)
  smooth_noise=lerpf(smooth_noise,rng.randf_range(-1,1),0.018)
  var wind=smooth_noise*(0.034+sin(t*0.2)*0.008)
  var bird_phase=fmod(t+sin(t*.031)*2.3,11.7)
  var bird=0.0
  if bird_phase<0.28:
   bird=sin(TAU*(1800*t+60*sin(t*35)))*sin(bird_phase/0.28*PI)*0.012*daylight
  var night=sin(TAU*2700*t)*pow(maxf(0,sin(t*12)),12)*0.003*(1-daylight)
  var water=sin(TAU*(430*t+sin(t*8)*1.8))*0.002
  var rain=(rng.randf_range(-1,1)*.018+smooth_noise*.12)*rainfall
  var value=(note+pad+bell)*music_volume+(wind+bird*(1-rainfall*.8)+night+water+rain)*nature_volume
  buffer[i]=Vector2(value,value*0.96)
  sample_index+=1
 playback.push_buffer(buffer)
