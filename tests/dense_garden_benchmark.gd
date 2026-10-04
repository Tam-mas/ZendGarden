extends RefCounted

static func sample(garden, capture: String="") -> Dictionary:
 var tree=garden.get_tree()
 garden.smoke=true
 garden.set_process(false)
 garden.side_panel.hide()
 garden.photo_mode=true
 garden.ui.hide()
 garden.visitors.set_process(false)
 AudioServer.set_bus_mute(0,true)
 Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var report={"plants":garden.planted.size(),"structures":garden.objects.size(),"renderer":RenderingServer.get_current_rendering_method(),"views":[]}
 for view in [{"name":"Beginning bed","position":Vector3(2.5,1.8,-5.5),"yaw":PI,"pitch":.12},{"name":"Sunrise terrace","position":Vector3(2.5,2.8,-22.5),"yaw":PI,"pitch":.20}]:
  garden.camera_target=view.position
  garden.yaw=view.yaw
  garden.pitch=view.pitch
  var frames=[]
  var scripts=[]
  var previous=Time.get_ticks_usec()
  for frame in range(80):
   await tree.process_frame
   var now=Time.get_ticks_usec()
   var elapsed=(now-previous)/1000.0
   previous=now
   var started=Time.get_ticks_usec()
   garden._process(1.0/60.0)
   if frame>=20:
    frames.append(elapsed)
    scripts.append((Time.get_ticks_usec()-started)/1000.0)
   garden.clock_time=.304929728383837
  frames.sort();scripts.sort()
  var result={"name":view.name,"frame_ms_median":frames[30],"frame_ms_p95":frames[57],"script_ms_median":scripts[30],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
  report.views.append(result)
  print("GARDEN_BENCHMARK_VIEW ",JSON.stringify(result))
  if not capture.is_empty():
   await tree.process_frame
   RenderingServer.force_draw(false)
   tree.root.get_texture().get_image().save_png(capture+"-"+str(report.views.size())+".png")
 return report
