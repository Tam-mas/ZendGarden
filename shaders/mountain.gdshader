shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform sampler2D strata : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D rock_normal : hint_normal, repeat_enable, filter_linear_mipmap;
varying vec3 world;
varying vec3 slope_normal;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float fbm(vec2 p) {
 float value=0.0, amplitude=.55;
 for(int i=0;i<4;i++) { value+=noise(p)*amplitude; p=p*2.03+vec2(19.7,7.1); amplitude*=.48; }
 return value;
}
vec3 unpack_normal(vec3 value) {
 vec2 xy=value.xy*2.0-1.0;
 return vec3(xy,sqrt(max(.001,1.0-dot(xy,xy))));
}
void vertex() {
 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 slope_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
 vec3 normal=normalize(slope_normal);
 vec3 weights=pow(abs(normal),vec3(5.0)); weights/=max(dot(weights,vec3(1.0)),.001);
 vec3 grain=texture(strata,world.yz*.065).rgb*weights.x
           +texture(strata,world.xz*.065).rgb*weights.y
           +texture(strata,world.xy*.065).rgb*weights.z;
 float broad=fbm(world.xz*.0035);
 float patch=fbm(world.xz*.025+vec2(broad*3.0,world.y*.007));
 float elevation=world.y+(broad-.5)*100.0;
 float cliff=smoothstep(.12,.40,1.0-abs(normal.y));
 float alpine=smoothstep(330.0,540.0,elevation);
 // Grass gives way to exposed mineral soil above an uneven ecological treeline.
 vec3 meadow=mix(vec3(.045,.078,.026),vec3(.145,.178,.068),patch);
 vec3 heath=mix(vec3(.105,.124,.070),vec3(.205,.193,.132),broad);
 vec3 vegetation=mix(meadow,heath,alpine);
 float bedding=world.y*.045+world.x*.003-world.z*.002+fbm(world.xz*.008)*2.0;
 float layer=smoothstep(.25,.75,sin(bedding)*.5+.5);
 vec3 rock=mix(vec3(.145,.155,.150),vec3(.285,.265,.225),layer*.55+broad*.45);
 rock*=(.56+grain*.92)*(.76+patch*.58);
 // Fine weathering has no contour-line threshold, avoiding painted loops on cliffs.
 float weathering=fbm(vec2(world.x*.10+world.z*.07,world.y*.13));
 rock*=.83+weathering*.32;
 float scree=alpine*(1.0-cliff)*smoothstep(.42,.68,patch);
 vec3 talus=mix(vec3(.24,.235,.20),vec3(.37,.35,.29),broad)*(.80+grain*.30);
 vec3 base=mix(vegetation,rock,cliff);
 base=mix(base,talus,scree*.78);
 // Snow collects high in sheltered bowls, with exposed steep ridges left rocky.
 float snow=smoothstep(680.0,825.0,elevation+patch*60.0)*(1.0-smoothstep(.25,.58,1.0-abs(normal.y)));
 float wind_scour=smoothstep(.35,.70,noise(world.xz*.019+world.y*.001));
 snow*=.65+.35*wind_scour;
 ALBEDO=mix(base,mix(vec3(.57,.64,.68),vec3(.82,.85,.83),patch),snow);
 ROUGHNESS=mix(.97,.83,snow);
 // World-aligned normal detail remains continuous across all terrain grid seams.
 vec3 nx=unpack_normal(texture(rock_normal,world.yz*.065).rgb);
 vec3 ny=unpack_normal(texture(rock_normal,world.xz*.065).rgb);
 vec3 nz=unpack_normal(texture(rock_normal,world.xy*.065).rgb);
 vec3 detail=normalize(vec3(nx.z*sign(normal.x),nx.x,nx.y)*weights.x
                      +vec3(ny.x,ny.z*sign(normal.y),ny.y)*weights.y
                      +vec3(nz.x,nz.y,nz.z*sign(normal.z))*weights.z);
 vec3 perturbed=normalize(mix(normal,detail,(.16+cliff*.30)*(1.0-snow*.75)));
 NORMAL=normalize((VIEW_MATRIX*vec4(perturbed,0.0)).xyz);
}
