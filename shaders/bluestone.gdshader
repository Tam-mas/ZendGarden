shader_type spatial;

uniform sampler2D stone : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_tint : source_color = vec4(.54,.55,.51,1.);
uniform vec4 joint_tint : source_color = vec4(.527,.501,.449,1.);
varying vec3 world;

float slab_random(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 // Same world-space coursing and stone as the ten modelled area paths.
 float row=floor(world.z/.48),course=mod(row,3.);
 float pitch=course<.5?.60:course<1.5?.90:1.20;
 float shift=course<.5?0.:course<1.5?.30:.45;
 vec2 p=vec2((world.x-shift)/pitch,world.z/.48);
 vec2 cell=floor(p),f=fract(p);
 float edge=min(min(f.x,1.-f.x)*pitch,min(f.y,1.-f.y)*.48);
 float feather=max(.001,fwidth(edge)*.65);
 float joint=1.-smoothstep(.004-feather,.004+feather,edge);
 float shade=slab_random(cell);
 vec3 pigment=texture(stone,world.xz/1.15).rgb;
 float grain=dot(pigment,vec3(.299,.587,.114));
 // Source-colour uniforms follow the same renderer conversion as the GLBs.
 vec3 basalt=pigment*stone_tint.rgb*mix(.77,1.03,shade);
 basalt*=mix(vec3(.95,.99,1.02),vec3(1.04,1.,.92),shade);
 basalt*=mix(.88,1.,smoothstep(.004,.013,edge));
 ALBEDO=mix(basalt,joint_tint.rgb,joint);
 ROUGHNESS=mix(.79+.12*grain,.97,joint);
 SPECULAR=.24;
 NORMAL_MAP=texture(relief,world.xz/1.15).rgb;
 NORMAL_MAP_DEPTH=.38*(1.-joint);
}
