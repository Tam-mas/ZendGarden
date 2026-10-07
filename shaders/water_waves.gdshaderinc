// Analytic surface waves: bounded ripples, not a volume-fluid solver.
uniform float water_time=0.;
uniform float wind_strength=1.;
uniform int ripple_count=0;
uniform vec4 ripple_events[6]; // world X/Z, birth time, strength

vec3 ripple_field(vec2 p) {
 vec3 field=vec3(0.);
 for(int j=0;j<6;j++) {
  if(j>=ripple_count)break;
  vec4 event=ripple_events[j];float age=water_time-event.z;
  if(age<0.||age>5.)continue;
  vec2 delta=p-event.xy;float distance=length(delta);
  float q=distance-age*.72;
  float envelope=exp(-q*q/ .075-age*.85)*.024*event.w;
  float h=sin(q*17.)*envelope;
  float slope=(17.*cos(q*17.)-q*26.6667*sin(q*17.))*envelope;
  field+=vec3(h,delta/max(distance,.025)*slope);
 }
 return field;
}

vec3 wind_field(vec2 p,float amplitude) {
 vec2 a=vec2(.93,.36),b=vec2(-.28,.96),c=vec2(.63,-.78);
 float u=dot(p,a)*.48-water_time*.82;
 float v=dot(p,b)*1.12-water_time*1.21;
 float w=dot(p,c)*3.4-water_time*1.68;
 float height=sin(u)+sin(v)*.38+sin(w)*.10;
 vec2 slope=a*.48*cos(u)+b*.4256*cos(v)+c*.34*cos(w);
 return vec3(height,slope)*amplitude*wind_strength;
}
