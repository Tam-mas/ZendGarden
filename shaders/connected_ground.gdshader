shader_type spatial;
uniform sampler2D earth : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap, repeat_enable;
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
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
 ALBEDO=mix(original,grass,blend);
 ROUGHNESS=mix(clamp(.82+flecks*.18,0.,1.),.97,blend);
 SPECULAR=mix(.5,.18,blend);
 NORMAL_MAP=mix(texture(relief,p*.72).rgb,texture(relief,p*.6).rgb,blend);
 NORMAL_MAP_DEPTH=mix(.55,.5,blend);
}
