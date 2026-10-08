// Organ-local UVs keep markings attached to leaves and petals at every stage.
uniform int cultivar_role=0; // 0: unchanged, 1: leaf, 2: petal, 3: flower lip
uniform int cultivar_pattern=0;
uniform vec4 cultivar_primary : source_color=vec4(1.0);
uniform vec4 cultivar_secondary : source_color=vec4(1.0);
uniform float cultivar_seed=0.0;

float cultivar_mark(vec2 uv, int pattern) {
 if(pattern==1) return 1.0-smoothstep(.07,.16,min(uv.x,1.0-uv.x));
 if(pattern==2) {
  if(cultivar_role==1) {
   float marble=sin(uv.x*18.0+sin(uv.y*13.0+cultivar_seed)*2.8)+sin(uv.y*23.0+uv.x*8.0)*.55;
   return smoothstep(.25,.85,marble);
  }
  return 1.0-smoothstep(.18,.43,uv.y);
 }
 if(pattern==3) {
  if(cultivar_role==1) return smoothstep(.46,.54,uv.x+sin(uv.y*15.0)*.035);
  vec2 cells=uv*vec2(9.0,11.0);
  vec2 p=fract(cells)-.5;
  float random=fract(sin(dot(floor(cells),vec2(127.1,311.7))+cultivar_seed)*43758.5453);
  return (1.0-smoothstep(.09,.18,length(p)))*step(.38,random);
 }
 if(pattern==4) {
  if(cultivar_role==1) return smoothstep(.35,.7,sin(uv.x*38.0+sin(uv.y*5.0)*.4));
  return smoothstep(.45,.55,uv.x);
 }
 return 0.0;
}

vec3 cultivar_colour(vec3 original, vec2 uv) {
 if(cultivar_role==0) return original;
 float tissue=clamp(dot(original,vec3(.2126,.7152,.0722))*1.65,.58,1.08);
 if(cultivar_role==1) return mix(original,cultivar_secondary.rgb*tissue,cultivar_mark(uv,cultivar_pattern)*.88);
 vec3 pigment=cultivar_role==3 ? cultivar_secondary.rgb : mix(cultivar_primary.rgb,cultivar_secondary.rgb,cultivar_mark(uv,cultivar_pattern));
 return pigment*tissue;
}
