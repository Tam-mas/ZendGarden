shader_type spatial;
uniform sampler2D pigment : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D relief : hint_normal,filter_linear_mipmap,repeat_enable;
uniform sampler2D finish_map : hint_default_white,filter_linear_mipmap,repeat_enable;
uniform bool has_pigment=false;
uniform bool has_relief=false;
uniform bool has_finish=false;
uniform vec4 tint : source_color=vec4(1.);
uniform float finish_factor=1.;
uniform float roughness_min=.70;
uniform float roughness_max=.96;
uniform float metal=0.;
uniform float surface_specular=.28;
uniform float relief_depth=.45;
uniform float base_height=0.;
uniform float stain_height=.22;
uniform int family=1;
varying vec3 point;
varying vec3 world;
float random2(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float patina(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);
 return mix(mix(random2(i),random2(i+vec2(1.,0.)),f.x),mix(random2(i+vec2(0.,1.)),random2(i+vec2(1.)),f.x),f.y);
}
void vertex(){point=VERTEX;world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec3 color=(has_pigment?texture(pigment,UV).rgb:vec3(1.))*tint.rgb;
 float patch=patina(world.xz*3.1+vec2(world.y*.8));
 float foot=(1.-smoothstep(base_height+.01,base_height+stain_height,point.y))*smoothstep(.18,.80,patch);
 float grain=patina(UV*18.);
 vec3 dirt=vec3(.17,.13,.085);
 if(family==0){color=mix(color,color*.78+vec3(.04,.045,.038),patch*.10);}
 if(family==1){dirt=vec3(.16,.18,.105);}
 color=mix(color,dirt,foot*(family==2?.22:family==1?.11:.15));
 ALBEDO=color*mix(.98,1.02,grain);
 float rough=has_finish?texture(finish_map,UV).g*finish_factor:finish_factor;
 ROUGHNESS=clamp(rough+foot*.06,roughness_min,roughness_max);
 METALLIC=metal;SPECULAR=surface_specular;
 if(has_relief){NORMAL_MAP=texture(relief,UV).rgb;NORMAL_MAP_DEPTH=relief_depth;}
}
