shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
#include "res://shaders/water_waves.gdshaderinc"
uniform vec4 deep_color : source_color;
uniform vec4 edge_color : source_color;
varying vec3 world_pos;
varying vec3 surface_normal;
float drop_foam(float z,float lip){
 // Froth forms below each drop, then breaks up through the following pool.
 return smoothstep(-.6,.3,z-lip)*(1.-smoothstep(.5,3.5,z-lip));
}
float rapid(float z){
 return max(max(drop_foam(z,-83.),drop_foam(z,-57.)),max(drop_foam(z,-28.),drop_foam(z,-4.)));
}
vec3 waves(vec2 p){
 float a=p.y*5.5-water_time*3.6+sin(p.x*2.4+p.y*.65)*1.3;
 float b=p.y*12.-water_time*7.4+p.x*4.;
 return vec3(sin(a)*.008+sin(b)*.003,cos(a)*.025*cos(p.x*2.4)+cos(b)*.021,cos(a)*.035+cos(b)*.026);
}
void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;
 surface_normal=normalize((MODEL_MATRIX*vec4(NORMAL,0.)).xyz);
 if(surface_normal.y<0.)surface_normal=-surface_normal;
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
 // Retain the actual downhill normal through cascades instead of lighting
 // every reach as a horizontal sheet. Ripples perturb that sloping surface.
 vec3 normal=normalize(surface_normal+vec3(-field.y,0.,-field.z));
 NORMAL=normalize((VIEW_MATRIX*vec4(normal,0.)).xyz);
 float fresnel=pow(1.-max(dot(NORMAL,VIEW),0.),4.);
 vec2 flow=vec2(world_pos.x*3.,UV.y*2.8-water_time*1.8);
 float flecks=foam_noise(flow)+foam_noise(flow*2.13+vec2(5.2,7.7))*.4;
 float edge_pockets=smoothstep(.50,.76,foam_noise(world_pos.xz*.7));
 float foam=(cascade*.72+bank*.10*edge_pockets)*smoothstep(.59,1.08,flecks);
 float shallows=foam_noise(world_pos.xz*.85)*bank*.14;
 vec3 water=mix(deep_color.rgb,edge_color.rgb,bank*.68+fresnel*.23+shallows);
 ALBEDO=mix(water,vec3(.78,.84,.77),foam);
 ALPHA=1.-smoothstep(.945,1.,abs(UV.x-.5)*2.);
 ROUGHNESS=mix(.27,.56,foam+bank*.13);SPECULAR=.38;
}
