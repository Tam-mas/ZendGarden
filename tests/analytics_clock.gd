extends SceneTree

class ClockGarden:
 extends "res://scripts/garden.gd"
 var recorded_minutes=0.0
 var recorded_seconds=0.0
 var mornings=0
 func _ready() -> void:pass
 func _process(_delta: float) -> void:pass
 func report_clock_time(_delta: float, advancing: float, game_minutes: float, _flush: bool=false) -> void:
  recorded_minutes+=game_minutes
  recorded_seconds+=advancing
 func advance_growth() -> void:
  day+=1;mornings+=1
 func refresh_ui() -> void:pass
 func update_hud() -> void:pass

func _initialize() -> void:call_deferred("verify")

func verify() -> void:
 var failures=[]
 var g=ClockGarden.new();root.add_child(g);g.smoke=true
 g.side_panel=PanelContainer.new();g.add_child(g.side_panel)
 g.transition_label=Label.new();g.add_child(g.transition_label)
 # Conversion of the same delta that drives ordinary clock advancement.
 g.report_clock_time(600,600,600/g.DAY_SECONDS*1440)
 if not is_equal_approx(g.recorded_minutes,1440.0):failures.append("Ten real minutes must be one full garden day")
 var before=g.recorded_minutes;var seconds=g.recorded_seconds
 g.clock_time=.75;g.next_day()
 for _frame in range(120):g.update_day_transition(.1)
 if g.day_transition:g.update_day_transition(.001)
 if not is_equal_approx(g.recorded_minutes-before,.55*1440):failures.append("Animated next morning lost clock progress across midnight")
 if g.recorded_seconds!=seconds:failures.append("A morning jump invented normal play time")
 if g.mornings!=1 or not is_equal_approx(g.clock_time,.30):failures.append("Morning changed existing day progression")
 g.settings.reduced_motion=true;g.clock_time=.90;before=g.recorded_minutes
 g.next_day()
 if not is_equal_approx(g.recorded_minutes-before,.40*1440):failures.append("Reduced-motion next morning lost clock progress")
 if g.mornings!=2:failures.append("Reduced-motion morning skipped growth")
 g.free()
 print("ANALYTICS_CLOCK_RESULT: ",JSON.stringify(failures))
 quit(0 if failures.is_empty() else 1)
