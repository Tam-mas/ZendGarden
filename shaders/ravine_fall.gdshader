shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
#include "res://shaders/water_waves.gdshaderinc"
float hash(float n){return fract(sin(n*127.1)*43758.5453);}
void fragment(){
 // Uneven threads collect and separate as the fall descends. A quieter lip
 // becomes aerated below, avoiding a repeated striped curtain down the cliff.
 float lane=UV.x*17.;float band=floor(lane);
 float phase=hash(band)*6.283;
 float ribbon=.5+.5*sin(lane*6.283+sin(UV.y*.41-water_time*1.5+phase)*.8);
 float spray=smoothstep(.38,.94,.5+.5*sin(UV.y*2.6-water_time*9.+phase+UV.x*8.));
 float aeration=smoothstep(.1,5.,UV.y)*(.31+ribbon*.27+spray*.21);
 ALBEDO=mix(vec3(.22,.37,.33),vec3(.68,.78,.70),aeration);
 ALPHA=(.86+.10*spray)*(1.-smoothstep(.83,1.,abs(UV.x-.5)*2.));
 ROUGHNESS=mix(.29,.55,aeration);SPECULAR=.30;
}
