shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
#include "res://shaders/water_waves.gdshaderinc"
uniform vec4 deep_color : source_color = vec4(.17,.28,.25,1.);
uniform vec4 edge_color : source_color = vec4(.38,.43,.29,1.);
uniform bool flowing = false;
uniform float flow_speed=.32;
uniform float flow_direction=-1.;
uniform float channel_width=1.;
uniform vec4 pond_shape=vec4(0.,0.,1.,1.);
varying vec3 world_pos;
varying vec2 along_axis;

vec3 current_field(vec2 p,float along,float across,vec2 axis) {
 float phase=along*8.-water_time*flow_speed*flow_direction*8.;
 float cross_phase=(across-.5)*channel_width*15.+sin(along*2.1)*.45;
 float h=sin(phase)*.006+sin(cross_phase+phase*.53)*.003;
 vec2 side=vec2(-axis.y,axis.x);
 vec2 slope=axis*(cos(phase)*.048+cos(cross_phase+phase*.53)*.01272)+side*cos(cross_phase+phase*.53)*.045;
 float bank=1.-smoothstep(.34,.5,abs(across-.5));
 return vec3(h,slope)*bank;
}
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 along_axis=normalize((MODEL_MATRIX*vec4(BINORMAL,0.)).xz);
 vec3 field=flowing?current_field(world_pos.xz,UV.y,UV.x,along_axis):wind_field(world_pos.xz,.008);
 field+=ripple_field(world_pos.xz);
 float edge=flowing?1.-smoothstep(.42,.5,abs(UV.x-.5)):1.-smoothstep(.85,1.,length((world_pos.xz-pond_shape.xy)/pond_shape.zw));
 VERTEX.y+=field.x*edge/max(length(MODEL_MATRIX[1].xyz),.01);
 world_pos.y+=field.x*edge;
}
void fragment(){
 vec2 p=world_pos.xz;
 float radius=flowing?abs(UV.x-.5)*2.:length((p-pond_shape.xy)/pond_shape.zw);
 float bank=smoothstep(.68,1.,radius);
 vec3 field=flowing?current_field(p,UV.y,UV.x,normalize(along_axis)):wind_field(p,.008);
 field+=ripple_field(p);
 vec3 normal=normalize(vec3(-field.y,1.,-field.z));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal,0.)).xyz);
 float fresnel=pow(1.-max(dot(NORMAL,VIEW),0.),4.);
 float streak=.5+.5*sin(UV.y*7.-water_time*flow_speed*flow_direction*7.+sin(UV.x*39.));
 float foam=flowing?bank*smoothstep(.83,.97,streak)*.32:smoothstep(.94,.985,radius)*(1.-smoothstep(.985,1.,radius))*.18;
 vec3 pigment=mix(deep_color.rgb,edge_color.rgb,.14+bank*.5+fresnel*.3);
 ALBEDO=mix(pigment,vec3(.69,.78,.72),foam);
 ALPHA=(flowing?.78:.87)*(1.-smoothstep(.97,1.,radius));
 ROUGHNESS=mix(.19,.38,bank);METALLIC=0.;SPECULAR=.58;
}
