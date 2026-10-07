shader_type spatial;

uniform sampler2D stone : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap, repeat_enable;
varying vec3 world;

float slab_random(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 // Metre-scaled running-bond bluestone: solid slabs, rather than slate chips.
 vec2 p=world.xz/vec2(.62,.93);
 float row=floor(p.y);p.x+=mod(row,2.)*.5;
 vec2 cell=floor(p),f=fract(p);
 float edge=min(min(f.x,1.-f.x)*.62,min(f.y,1.-f.y)*.93);
 float feather=max(.006,fwidth(edge)*.75);
 float joint=1.-smoothstep(.012-feather,.012+feather,edge);
 float shade=slab_random(cell);
 vec3 pigment=texture(stone,world.xz*1.2+vec2(shade*.7)).rgb;
 float grain=dot(pigment,vec3(.299,.587,.114));
 vec3 basalt=mix(vec3(.115,.155,.19),vec3(.265,.305,.33),shade);
 basalt*=mix(.76,1.20,grain);
 basalt+=vec3(.025,.023,.018)*smoothstep(.73,.93,grain);
 ALBEDO=mix(basalt,vec3(.115,.12,.118),joint*.80);
 ROUGHNESS=mix(.79+.12*grain,.97,joint);
 SPECULAR=.24;
 NORMAL_MAP=texture(relief,world.xz*1.2).rgb;
 NORMAL_MAP_DEPTH=.38*(1.-joint);
}
