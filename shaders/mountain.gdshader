shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform sampler2D strata : source_color, repeat_enable;
varying vec3 world;
varying vec3 slope_normal;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;slope_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 normal=normalize(slope_normal);
 vec3 blend=pow(abs(normal),vec3(4));blend/=max(dot(blend,vec3(1)),.001);
 vec3 grain=texture(strata,world.yz*.04).rgb*blend.x+texture(strata,world.xz*.04).rgb*blend.y+texture(strata,world.xy*.04).rgb*blend.z;
 float broad=noise(world.xz*.006)*.65+noise(world.xz*.022)*.35;
 float cliff=smoothstep(.07,.32,1.0-abs(normal.y));
 vec3 meadow=mix(vec3(.055,.105,.038),vec3(.18,.22,.09),broad);
 vec3 rock=mix(vec3(.16,.17,.145),vec3(.33,.31,.25),broad)*(.65+grain*.65);
 float strata_bands=.88+.12*sin(world.y*.16+noise(world.xz*.02)*5.0);
 vec3 base=mix(meadow,rock*strata_bands,cliff);
 // Keep lower wooded slopes green. Snow belongs only on the highest ridges.
 float snow=smoothstep(680.0,850.0,world.y+(broad-.5)*110.0)*(1.0-cliff*.85);
 ALBEDO=mix(base,vec3(.64,.68,.68),snow);
 ROUGHNESS=1.0;
}
