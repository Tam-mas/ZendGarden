class_name GardenTheme
extends RefCounted

const TEXT=Color("fff4dc")
const MUTED=Color("dcc8a2")
const ACCENT=Color("e7ca85")
static var button_styles: Dictionary={}

static func button_style(selected: bool=false, state: String="normal") -> StyleBoxTexture:
 var key=str(selected)+state
 if button_styles.has(key): return button_styles[key]
 var color=Color("ffdda0") if selected else Color.WHITE
 if state=="hover":color=Color("fff0c3") if selected else Color("efd49b")
 elif state=="pressed":color=Color("d4b67f")
 elif state=="disabled":color=Color("a69b86")
 elif state=="focus":color=Color("ffe5aa")
 var style=frame("button",color,8)
 button_styles[key]=style
 return style

static func choose(button: Button, selected: bool) -> void:
 for state in ["normal","hover","pressed"]:
  button.add_theme_stylebox_override(state,button_style(selected,state))

static func frame(kind: String="wood", tint: Color=Color.WHITE, margin: int=18) -> StyleBoxTexture:
 var style=StyleBoxTexture.new()
 style.texture=load("res://assets/ui/"+kind+".png")
 style.modulate_color=tint
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:
  style.set_texture_margin(side,32 if kind=="wood" else (8 if kind=="button" else 20))
  style.set_content_margin(side,margin)
 return style

static func meter(color: Color) -> StyleBoxFlat:
 var style=StyleBoxFlat.new()
 style.bg_color=color
 style.set_corner_radius_all(4)
 style.set_content_margin_all(0)
 return style

static func make() -> Theme:
 var theme=Theme.new()
 var font=SystemFont.new()
 font.font_names=PackedStringArray(["Georgia","Noto Serif","Serif"])
 theme.default_font=font
 theme.default_font_size=16
 theme.set_color("font_color","Label",TEXT)
 for state in ["normal","hover","pressed","focus","disabled"]:
  theme.set_stylebox(state,"Button",button_style(false,state))
  theme.set_color("font_"+state+"_color","Button",MUTED if state=="disabled" else TEXT)
 theme.set_color("font_color","Button",TEXT)
 theme.set_stylebox("panel","PanelContainer",frame("wood",Color.WHITE,14))
 theme.set_stylebox("panel","PopupMenu",frame("wood",Color.WHITE,14))
 theme.set_color("font_color","PopupMenu",TEXT)
 theme.set_color("font_hover_color","PopupMenu",TEXT)
 theme.set_stylebox("hover","PopupMenu",button_style(true))
 theme.set_stylebox("panel","TooltipPanel",frame("parchment"))
 theme.set_color("font_color","TooltipLabel",Color("49341e"))
 theme.set_stylebox("normal","LineEdit",frame("button",Color.WHITE,8))
 theme.set_stylebox("read_only","LineEdit",frame("button",Color("b7a78d"),8))
 theme.set_stylebox("focus","LineEdit",button_style(false,"focus"))
 theme.set_color("font_color","LineEdit",TEXT)
 theme.set_color("font_placeholder_color","LineEdit",MUTED)
 theme.set_color("caret_color","LineEdit",ACCENT)
 theme.set_color("selection_color","LineEdit",Color("8f6b3e"))
 for type in ["VScrollBar","HScrollBar"]:
  var track=StyleBoxFlat.new()
  track.bg_color=Color("2d2119")
  track.content_margin_left=5
  track.content_margin_right=5
  theme.set_stylebox("scroll",type,track)
  for state in ["grabber","grabber_highlight","grabber_pressed"]:
   var grab=StyleBoxFlat.new()
   grab.bg_color=Color("a17d49")
   grab.set_corner_radius_all(4)
   theme.set_stylebox(state,type,grab)
 return theme
