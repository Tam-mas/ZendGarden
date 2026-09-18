shader_type spatial;
render_mode cull_disabled;
uniform vec4 deep_color : source_color = vec4(0.12,0.30,0.32,1.0);
uniform vec4 edge_color : source_color = vec4(0.34,0.53,0.49,1.0);
varying vec3 world_pos;
void vertex(){ world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 vec2 p=world_pos.xz;
 float distance_to_eye=length(VERTEX);
 float small_wave=sin(p.x*2.7+p.y*.85+TIME*.9);
 float broad_wave=sin(p.x*.22+p.y*.61+TIME*.32);
 float ripple=(small_wave*.015+sin(p.x*4.1-p.y*.73+TIME)*.007)*exp(-distance_to_eye*.008);
 ALBEDO=mix(deep_color.rgb,edge_color.rgb,.25+broad_wave*.015);
 ROUGHNESS=.27;
 METALLIC=.22;
 NORMAL=normalize(NORMAL+vec3(ripple,0.0,broad_wave*.005));
}
