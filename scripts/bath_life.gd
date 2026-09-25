class_name GardenBathLife
extends Node3D

var g
var elapsed=0.0
var birds: Array=[]
var droplets: Array=[]
var voice: AudioStreamPlayer

func setup(game) -> void:
 g=game
 name="BathVisitors"
 for i in range(2):
  var bird=GardenArt.visitor("songbird" if i==0 else "native bird")
  add_child(bird)
  for side in [-1,1]: GardenArt.branch(bird,Vector3(side*.035,-.025,0),Vector3(side*.035,-.08,-.015),.008,Color("756d50"))
  birds.append(bird)
  var drops=Node3D.new()
  add_child(drops)
  for j in range(6): GardenArt.ball(drops,Vector3.ZERO,Vector3.ONE*.018,Color("aad4d4"))
  droplets.append(drops)
 voice=AudioStreamPlayer.new()
 voice.stream=load("res://assets/audio/bath_birds.wav")
 if OS.has_feature("web"): voice.playback_type=AudioServer.PLAYBACK_TYPE_SAMPLE
 voice.volume_db=-80
 add_child(voice)
 voice.play()

static func bird_position(time: float, index: int) -> Vector3:
 var cycle=fposmod(time+index*13.0,40.0)
 var rim=Vector3(-.3 if index==0 else .3,1.13,.12 if index==0 else -.12)
 var away=rim+Vector3(-2 if index==0 else 2,2.0,2.0)
 if cycle<5: return away.lerp(rim,smoothstep(0,5,cycle))
 if cycle<12: return rim+Vector3(0,sin(cycle*5)*.007,0)
 var water=Vector3(rim.x*.4,1.08,rim.z)
 if cycle<14: return rim.lerp(water,smoothstep(12,14,cycle))+Vector3(0,sin((cycle-12)*PI/2)*.09,0)
 if cycle<25: return water+Vector3(0,sin(cycle*12)*.012,0)
 if cycle<30: return water.lerp(away,smoothstep(25,30,cycle))
 return away

func _process(delta: float) -> void:
 if not is_instance_valid(g): return
 var active=not is_instance_valid(g.welcome) and not (g.settings.pause_menus and not g.gameplay_active())
 if active: elapsed+=delta
 var daylight=g.clock_time>.2 and g.clock_time<.8
 var present=false
 for i in range(birds.size()):
  var cycle=fposmod(elapsed+i*13.0,40.0)
  var bathing=cycle>=14 and cycle<25
  birds[i].visible=daylight and cycle<30
  present=present or (birds[i].visible and cycle>=5 and cycle<25)
  birds[i].position=bird_position(elapsed,i)
  birds[i].rotation.y=-.65 if i==0 else 2.5
  birds[i].rotation.x=sin(elapsed*5)*.2 if cycle>=5 and cycle<12 else (sin(elapsed*12)*.14 if bathing else 0.0)
  for wing in birds[i].get_children():
   if str(wing.name).begins_with("Wing"):
    var flutter=.65*sin(elapsed*28) if cycle<5 or cycle>=25 or bathing else -.75
    wing.rotation.z=flutter*float(wing.get_meta("side",1))
  droplets[i].visible=daylight and bathing
  var j=0
  for drop in droplets[i].get_children():
   var phase=fposmod(elapsed*1.8+j*.17,1.0)
   var angle=j*TAU/6
   drop.position=birds[i].position+Vector3(cos(angle)*phase*.28,phase*(1-phase)*1.1-.04,sin(angle)*phase*.28)
   j+=1
 var distance=g.player.global_position.distance_to(global_position)
 var gain=pow(clampf(1-distance/12.0,0,1),2)*float(g.settings.nature_volume)/100.0
 if not active or not present: gain=0
 voice.volume_db=lerpf(voice.volume_db,linear_to_db(maxf(.0001,gain)),1-exp(-delta*3))
