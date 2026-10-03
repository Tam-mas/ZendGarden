class_name GardenInterface
extends RefCounted

const SIDEBAR_WIDTH=300.0

# Desktop uses logical display pixels, so a small window keeps readable text.
static func layout(g, force: bool=false) -> void:
 if g.touch_active(): return
 var size=g.get_viewport().get_visible_rect().size
 var menus=Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and g.rest_kind.is_empty() and not g.photo_mode and not g.day_transition
 var sidebar=SIDEBAR_WIDTH
 var tip_width=size.x-sidebar-48 if menus else size.x-32
 g.tip_label.size=Vector2(tip_width,0)
 var tip_height=g.tip_label.get_minimum_size().y+8
 g.tip_label.position=Vector2(sidebar+32 if menus else 16,size.y-92-tip_height if menus else size.y-16-tip_height)
 var key=str(size)+str(menus)+g.active_tab
 if not force and g.ui.get_meta("desktop_layout","")==key: return
 g.ui.set_meta("desktop_layout",key)
 var margin=16.0
 g.hud_title.position=Vector2(margin,margin)
 g.hud_title.size=Vector2(sidebar,68)
 g.hud_top.position=Vector2(sidebar+margin*2,28)
 g.side_panel.position=Vector2(margin,100)
 var column=g.side_panel.get_child(0)
 column.add_theme_constant_override("separation",10)
 column.get_child(2).custom_minimum_size=Vector2(sidebar-28,80)
 g.detail_label.custom_minimum_size.x=sidebar-28
 g.detail_label.visible=g.active_tab not in ["Seeds","Shop"]
 for tab in column.get_child(0).get_children():
  tab.custom_minimum_size=Vector2(0,40)
  tab.add_theme_font_size_override("font_size",16)
 column.get_child(4).custom_minimum_size.y=40
 # Set the panel after its children's limits, including when leaving touch mode.
 g.side_panel.size=Vector2(sidebar,maxf(320,size.y-192))
 var right_width=368.0
 g.hud_capacity.position=Vector2(size.x-right_width-margin,100)
 g.hud_capacity.size=Vector2(right_width,144)
 g.inspector_panel.position=Vector2(size.x-right_width-margin,260)
 g.inspector_panel.size.x=right_width
 g.rotation_panel.position=Vector2(size.x-right_width-margin,size.y-210)
 g.rotation_panel.size=Vector2(right_width,64)
 g.hud_tools.position=Vector2(margin,size.y-84)
 g.hud_tools.size=Vector2(size.x-margin*2,68)
 g.reticle.position=size*.5-Vector2(8,18)
 g.compact_hud.position=Vector2(margin,margin)
 g.compact_hud.size=Vector2.ZERO
 g.compact_hud.autowrap_mode=TextServer.AUTOWRAP_OFF
 g.view_button.position=Vector2(size.x-174,margin)
 g.view_button.size=Vector2(158,36)
 g.toast_label.size=Vector2(minf(560,size.x-32),0)
 g.toast_label.position=Vector2((size.x-g.toast_label.size.x)*.5,96)
 g.toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 g.transition_label.size=Vector2(minf(700,size.x-32),0)
 g.transition_label.position=Vector2((size.x-g.transition_label.size.x)*.5,80)
 g.photo_panel.size=Vector2(minf(760,size.x-32),65)
 g.photo_panel.position=Vector2((size.x-g.photo_panel.size.x)*.5,size.y-84)
 if is_instance_valid(g.request_popup): fit_popup(g,g.request_popup,false)

static func fit_popup(g, popup: Control, center: bool=true) -> void:
 var size=g.get_viewport().get_visible_rect().size
 var area=size-Vector2(32,32)
 var factor=minf(1.0,minf(area.x/popup.size.x,area.y/popup.size.y))
 popup.scale=Vector2.ONE*factor
 popup.position=(size-popup.size*factor)*.5 if center else Vector2(size.x-popup.size.x*factor-16,100)
 popup.position.y=clampf(popup.position.y,16,maxf(16,size.y-popup.size.y*factor-16))
