shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
uniform vec4 deep_color : source_color = vec4(.17,.28,.25,1.);
uniform vec4 edge_color : source_color = vec4(.38,.43,.29,1.);
uniform bool flowing = false;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 p=world_pos.xz;
 float flow=flowing?TIME*.32:TIME*.06;
 float w1=sin(p.x*3.8+p.y*1.4-flow*4.0);
 float w2=sin(p.x*7.1-p.y*2.3+flow*3.0);
 float w3=sin(p.x*1.4+p.y*.75-flow);
 float bank=flowing?smoothstep(.35,.50,abs(UV.x-.5)):0.0;
 float sediment=.5+.5*sin(p.x*11.2+sin(p.y*8.0))*sin(p.y*15.0);
 ALBEDO=mix(deep_color.rgb,edge_color.rgb,bank*.80+.09+sediment*.055);
 // Fine directional highlights, with a calmer broad swell beneath them.
 NORMAL=normalize(NORMAL+vec3(w1*.055+w2*.027,w3*.011,w2*.032));
 ALPHA=flowing?.70*(1.-smoothstep(.45,.50,abs(UV.x-.5))):.82;
 ROUGHNESS=mix(.17,.43,bank);METALLIC=.08;SPECULAR=.66;
}
