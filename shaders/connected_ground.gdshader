shader_type spatial;
uniform sampler2D earth : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap, repeat_enable;
varying vec3 world;
varying float slope;
varying vec3 rock_axis;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;slope=1.-NORMAL.y;rock_axis=abs(NORMAL);}
void fragment(){
 vec2 p=world.xz;
 // Meet the meadow and habitat border at their existing world texture scales.
 vec3 close=texture(earth,p*.72).rgb;
 vec3 broad=texture(earth,mat2(vec2(.73,.68),vec2(-.68,.73))*p*.113+vec2(.37,.19)).rgb;
 float flecks=texture(earth,p*3.7).r;
 vec3 original=mix(close,broad,.32)*mix(.88,1.12,flecks);
 vec3 grass=texture(earth,p*.6).rgb*vec3(.72,.86,.72);
 float luma=dot(grass,vec3(.22,.68,.10));
 grass=mix(grass,vec3(luma)*vec3(.83,.95,.72),.28)*.70;
 float blend=smoothstep(25.5,44.,p.x);
 vec3 weights=pow(rock_axis,vec3(4.));weights/=max(.001,weights.x+weights.y+weights.z);
 vec3 mineral=texture(rock,world.yz*.65).rgb*weights.x+texture(rock,world.xz*.65).rgb*weights.y+texture(rock,world.xy*.65).rgb*weights.z;
 vec3 stone=mineral*vec3(.27,.28,.255);
 float exposure=smoothstep(.04,.35,slope);
 float damp=1.-smoothstep(-3.5,-.8,world.y);
 ALBEDO=mix(mix(original,grass,blend),stone,max(exposure,damp*.8));
 ROUGHNESS=mix(clamp(.82+flecks*.18,0.,1.),.97,blend);
 SPECULAR=mix(.5,.18,blend);
 NORMAL_MAP=mix(texture(relief,p*.72).rgb,texture(relief,p*.6).rgb,blend);
 NORMAL_MAP=mix(NORMAL_MAP,texture(rock_normal,world.xz*.59+world.y*.18).rgb,max(exposure,damp*.8));
 NORMAL_MAP_DEPTH=.7;
}
