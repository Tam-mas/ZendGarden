extends RefCounted

static func run(g, failures: Array) -> void:
 var sign_index=g.furniture.size()-1
 g.choose_furnishing(sign_index)
 if g.active_tab!="Sign" or not g.side_panel.visible or Input.mouse_mode!=Input.MOUSE_MODE_VISIBLE:
  failures.append("Sign editor did not open with a usable cursor")
 var field=g.list_box.get_node("SignText")
 field.text="Lavender & bees <3"
 field.text_changed.emit(field.text)
 var picker=g.list_box.get_node("SignColour")
 picker.color=Color("b4d6ff")
 picker.color_changed.emit(picker.color)
 g.finish_sign_editor()
 if g.mode!="build": failures.append("Sign editor did not start placement")
 var coins=g.coins
 g.coins=100
 var count=g.objects.size()
 g.hover_valid=true
 g.hover_plot=0
 g.hover_cell=GardenTerrain.point(Vector3(-4,0,4.8))
 g.structure_rotation=.75
 g.action_cooldown=0
 g.perform_action()
 if g.objects.size()!=count+1:
  failures.append("Custom sign could not be placed")
  return
 var obj=g.objects.back()
 if g.coins!=85 or obj.kind!="sign" or obj.text!=field.text or obj.text_color!="b4d6ff":
  failures.append("Sign purchase lost text, colour or price")
 for face_name in ["FrontText","BackText"]:
  var face=obj.node.get_node(face_name)
  var normal=face.transform.basis*Vector3.BACK
  if face.double_sided or normal.z*face.position.z<=0.05:
   failures.append("Sign face exposes reversed lettering or sits inside its board")
 g.open_sign_editor(g.objects.size()-1)
 g.sign_text="Herbs & flowers"
 g.sign_color=Color("ffe6a0")
 g.finish_sign_editor()
 if obj.text!="Herbs & flowers" or obj.node.get_node("BackText").text!=obj.text or obj.text_color!="ffe6a0":
  failures.append("Editing a placed sign did not update both faces")
 if not is_equal_approx(obj.rotation,.75): failures.append("Editing reset the sign rotation")
 # Move through the normal tool dispatcher; metadata must travel with the sign.
 g.set_mode("move")
 g.hover_cell=obj.pos
 g.action_cooldown=0
 g.perform_action()
 g.hover_cell=GardenTerrain.point(Vector3(-4.4,0,4.8))
 g.structure_rotation=1.25
 g.perform_action()
 if obj.pos.distance_to(g.hover_cell)>.01 or not is_equal_approx(obj.rotation,1.25) or obj.text!="Herbs & flowers":
  failures.append("Moving a sign lost its location, rotation or lettering")
 g.coins=coins
 g.set_mode("walk")
