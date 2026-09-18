class_name GardenTheme
extends RefCounted

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
 theme.default_font_size=15
 theme.set_color("font_color","Label",Color("efdfbc"))
 for state in ["normal","hover","pressed","focus","disabled"]:
  var tint=Color("efd49b") if state=="hover" else (Color("c7ad7e") if state=="pressed" else Color.WHITE)
  theme.set_stylebox(state,"Button",frame("button",tint,8))
  theme.set_color("font_"+state+"_color","Button",Color("f5e5c0"))
 theme.set_color("font_color","Button",Color("f5e5c0"))
 theme.set_stylebox("panel","PanelContainer",frame())
 theme.set_stylebox("panel","TooltipPanel",frame("parchment"))
 theme.set_color("font_color","TooltipLabel",Color("49341e"))
 for state in ["normal","focus","read_only"]: theme.set_stylebox(state,"LineEdit",frame("button",Color.WHITE,8))
 theme.set_color("font_color","LineEdit",Color("f5e5c0"))
 theme.set_color("caret_color","LineEdit",Color("ead29a"))
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
