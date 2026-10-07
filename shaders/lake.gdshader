shader_type spatial;
render_mode cull_disabled;
#include "res://shaders/water_waves.gdshaderinc"
uniform vec4 deep_color : source_color = vec4(0.12,0.30,0.32,1.0);
uniform vec4 edge_color : source_color = vec4(0.34,0.53,0.49,1.0);
varying vec3 world_pos;
uniform float wave_height=.14;
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 vec3 field=wind_field(world_pos.xz,wave_height)+ripple_field(world_pos.xz);
 VERTEX.y+=field.x/max(length(MODEL_MATRIX[1].xyz),.01);
 world_pos.y+=field.x;
}
void fragment(){
 vec2 p=world_pos.xz;
 float distance_to_eye=length(VERTEX);
 vec3 field=wind_field(p,wave_height)+ripple_field(p);
 // Let distant small waves soften instead of sparkling at sub-pixel sizes.
 float detail=1.-smoothstep(35.,180.,distance_to_eye);
 vec2 slopes=field.yz*mix(.45,1.,detail);
 vec3 normal=normalize(vec3(-slopes.x,1.,-slopes.y));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal,0.)).xyz);
 float fresnel=pow(1.-max(dot(NORMAL,VIEW),0.),4.);
 ALBEDO=mix(deep_color.rgb,edge_color.rgb,.15+fresnel*.55+field.x*.12);
 ALBEDO*=1.+field.x*.35;
 ROUGHNESS=mix(.24,.16,detail);METALLIC=0.;SPECULAR=.58;
}
