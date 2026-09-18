shader_type spatial;
uniform sampler2D earth : source_color, repeat_enable;
uniform sampler2D relief : hint_normal, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world.xz;
 vec3 close=texture(earth,p*.72).rgb;
 vec3 broad=texture(earth,mat2(vec2(.73,.68),vec2(-.68,.73))*p*.113+vec2(.37,.19)).rgb;
 float flecks=texture(earth,p*3.7).r;
 ALBEDO=mix(close,broad,.32)*mix(.88,1.12,flecks)*tint.rgb;
 ROUGHNESS=clamp(.82+flecks*.18,0.,1.);
 NORMAL_MAP=texture(relief,p*.72).rgb;
 NORMAL_MAP_DEPTH=.55;
}
