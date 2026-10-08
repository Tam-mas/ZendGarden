shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
#include "res://shaders/water_waves.gdshaderinc"
uniform vec4 deep_color : source_color;
uniform vec4 edge_color : source_color;
varying vec3 world_pos;
float rapid(float z){
 return max(max(1.-smoothstep(.2,1.6,abs(z+83.)),1.-smoothstep(.2,1.6,abs(z+57.))),max(1.-smoothstep(.2,1.6,abs(z+28.)),1.-smoothstep(.2,1.6,abs(z+4.))));
}
vec3 waves(vec2 p){
 float a=p.y*9.-water_time*7.+sin(p.x*4.2+p.y*1.3)*2.3;
 float b=p.y*17.-water_time*12.+p.x*6.;
 return vec3(sin(a)*.012+sin(b)*.005,cos(a)*.04*cos(p.x*4.2)+cos(b)*.042,cos(a)*.06+cos(b)*.04);
}
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 vec3 field=waves(world_pos.xz)+ripple_field(world_pos.xz);
 float bank=1.-smoothstep(.34,.5,abs(UV.x-.5));
 VERTEX.y+=field.x*bank;
}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float foam_noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+vec2(1.,1.)),f.x),f.y);
}
void fragment(){
 float bank=smoothstep(.28,.50,abs(UV.x-.5));
 float cascade=rapid(world_pos.z);
 vec3 field=waves(world_pos.xz)+ripple_field(world_pos.xz);
 vec3 normal=normalize(vec3(-field.y,1.,-field.z));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal,0.)).xyz);
 float fresnel=pow(1.-max(dot(NORMAL,VIEW),0.),4.);
 vec2 flow=vec2(world_pos.x*4.,UV.y*3.5-water_time*2.8);
 float flecks=foam_noise(flow)+foam_noise(flow*2.13+vec2(5.2,7.7))*.4;
 float foam=(cascade*.72+bank*.12)*smoothstep(.57,1.1,flecks);
 ALBEDO=mix(mix(deep_color.rgb,edge_color.rgb,bank*.5+fresnel*.35),vec3(.76,.83,.77),foam);
 ALPHA=1.*(1.-smoothstep(.965,1.,abs(UV.x-.5)*2.));
 ROUGHNESS=mix(.32,.55,foam);SPECULAR=.32;
}
