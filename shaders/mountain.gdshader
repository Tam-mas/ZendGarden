shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D strata : source_color, repeat_enable;
varying vec3 world;
varying vec3 slope_normal;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; slope_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 blend=pow(abs(slope_normal),vec3(4.0)); blend/=max(dot(blend,vec3(1)),.001);
 vec3 grain=texture(strata,world.yz*.024).rgb*blend.x+texture(strata,world.xz*.024).rgb*blend.y+texture(strata,world.xy*.024).rgb*blend.z;
 float broad=texture(strata,world.xz*.0017).r;
 float cliff=smoothstep(.025,.23,1.0-abs(slope_normal.y));
 vec3 forest=mix(vec3(.075,.13,.048),vec3(.28,.33,.17),smoothstep(.32,.52,broad));
 vec3 stone=grain*mix(.65,1.65,smoothstep(.28,.54,texture(strata,world.xz*.005+world.y*.004).r));
 vec3 base=mix(forest,stone,cliff);
 float snow=smoothstep(235.0,335.0,world.y+(broad-.5)*100.0)*(1.0-cliff*.7);
 ALBEDO=mix(base,vec3(.78,.80,.78),snow);
 ROUGHNESS=.94;
}
