extends SceneTree

func _initialize() -> void:
 var failures=[]
 var report=[]
 var mix_rate=AudioServer.get_mix_rate()
 for name in ["garden_music","water_music","woodland_music","terrace_music","day","night","rain","waterside","woodland","bath_birds"]:
  var path="res://assets/audio/"+name+".wav"
  var compressed=load(path) as AudioStreamWAV
  var master=AudioStreamWAV.load_from_file(path,{"compress/mode":0,"edit/loop_mode":2,"edit/loop_end":-1})
  if not master or not compressed:
   failures.append(name+": missing source or runtime audio")
   continue
  var frames=master.data.size()/2
  var encoded_expected=name.ends_with("_music") or name=="rain"
  var expected_format=AudioStreamWAV.FORMAT_QOA if encoded_expected else AudioStreamWAV.FORMAT_16_BITS
  if compressed.format!=expected_format or compressed.loop_begin!=0 or compressed.loop_end!=frames-1 or compressed.get_length()!=master.get_length():
   failures.append(name+": compression changed phrase length or looping")
  if encoded_expected and compressed.data.size()>master.data.size()*.23:failures.append(name+": compression size regression")
  var signal_power=0.0
  var error=0.0
  var seam=0.0
  # Mix through Godot's actual codec and resampler, including across the seam.
  # This is also how its browser sample backend creates the WebAudio buffer.
  for time in [0.0,master.get_length()*.5,master.get_length()-1]:
   var original=master.instantiate_playback()
   var encoded=compressed.instantiate_playback()
   original.start(time)
   encoded.start(time)
   var reference=original.mix_audio(1.0,mix_rate*2)
   var result=encoded.mix_audio(1.0,mix_rate*2)
   if result.size()!=reference.size():failures.append(name+": missing mixed samples")
   for i in range(mini(result.size(),reference.size())):
    signal_power+=reference[i].x*reference[i].x
    error+=pow(result[i].x-reference[i].x,2)
   if time==master.get_length()-1 and result.size()>mix_rate:
    seam=absf(result[mix_rate].x-result[mix_rate-1].x)*32768
   original.stop()
   encoded.stop()
  var snr=minf(120,10*log(signal_power/maxf(error,1e-20))/log(10))
  if snr<35:failures.append(name+": audible compression error (SNR "+str(snr)+")")
  if seam>120:failures.append(name+": discontinuous compressed loop")
  report.append({"track":name,"snr_db":snappedf(snr,.1),"seam_pcm_units":snappedf(seam,.1)})
 print("AUDIO_COMPRESSION_QUALITY: ",JSON.stringify(report))
 print("AUDIO_COMPRESSION_RESULT: ",failures)
 quit(0 if failures.is_empty() else 1)
