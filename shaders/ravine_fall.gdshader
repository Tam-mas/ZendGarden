shader_type spatial;
render_mode cull_disabled, depth_prepass_alpha;
#include "res://shaders/water_waves.gdshaderinc"
void fragment(){
 float ribbons=.5+.5*sin(UV.x*74.+sin(UV.y*.75-water_time*2.)*.7);
 float spray=smoothstep(.3,.95,.5+.5*sin(UV.y*3.-water_time*13.+UV.x*35.));
 ALBEDO=mix(vec3(.15,.29,.27),vec3(.57,.72,.67),ribbons*.55+spray*.35);
 ALPHA=(.85+.1*spray)*(1.-smoothstep(.87,1.,abs(UV.x-.5)*2.));
 ROUGHNESS=.52;SPECULAR=.25;
}
