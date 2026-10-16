shader_type sky;
uniform float overcast = 0.0;
uniform float cloud_opacity = 1.0;
uniform float daylight = 1.0;
uniform float day_phase = .4;
uniform float sky_motion = 1.4;
uniform float twilight = 0.0;
uniform vec3 sun_direction = vec3(-0.4,0.6,-0.3);
uniform vec3 moon_direction = vec3(0.4,0.6,0.3);
uniform vec3 moon_right = vec3(-0.89,0.0,0.45);
uniform float moon_radius = .028;
uniform float moon_illumination = .5;
uniform float moonlight = 0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){float v=0.0,a=.5;for(int i=0;i<5;i++){v+=noise(p)*a;p=p*2.04+vec2(17.3,9.1);a*=.5;}return v;}
float crater(vec2 p,vec2 center,float radius){
 float r=length(p-center)/radius;
 return -.16*(1.-smoothstep(.55,.82,r))+.10*exp(-pow((r-.91)*13.,2.));
}
void sky(){
 vec3 d=normalize(EYEDIR);
 float h=max(d.y,0.0);
 vec3 horizon=mix(vec3(.025,.037,.08),vec3(.70,.78,.83),daylight);
 horizon=mix(horizon,vec3(.88,.34,.13),twilight*.67);
 vec3 zenith=mix(vec3(.003,.006,.025),vec3(.19,.40,.57),daylight);
 vec3 col=mix(horizon,zenith,pow(h,.42));
 vec3 clear_sky=col;
 // A rotating celestial sphere, tied to game time so stars sweep through a skipped night.
 float a=day_phase*6.2831853;
 vec3 stellar=d;
 stellar.xy=mat2(vec2(cos(a),-sin(a)),vec2(sin(a),cos(a)))*stellar.xy;
 vec2 star_uv=vec2(atan(stellar.x,stellar.z)/6.2831853+.5,asin(clamp(stellar.y,-1.,1.))/3.14159265+.5)*vec2(900.,450.);
 vec2 cell=floor(star_uv);
 float seed=hash(cell);
 float star=(1.-smoothstep(.045,.22,length(fract(star_uv)-vec2(.5))))*step(.991,seed);
 col+=mix(vec3(.55,.70,1.),vec3(1.,.84,.57),hash(cell+31.))*star*2.6*pow(1.-daylight,2.)*smoothstep(0.,.13,d.y)*(1.-moonlight*.40);
 // A spherical disc: the projected sun lights its actual curved surface.
 // Keeping a fixed orbital tangent avoids a texture flip at the zenith.
 vec3 md=normalize(moon_direction);
 vec3 mr=normalize(moon_right);
 vec3 mu=normalize(cross(mr,md));
 float facing=dot(d,md);
 vec2 moon_uv=vec2(dot(d,mr),dot(d,mu))/sin(moon_radius);
 float r2=dot(moon_uv,moon_uv);
 float horizon_fade=smoothstep(-.015,.025,d.y);
 col+=vec3(.035,.045,.065)*exp(-max(0.,1.-facing)*480.)*moonlight*horizon_fade;
 if(facing>0.0 && r2<1.02){
  float edge=(1.-smoothstep(.975,1.0,r2))*horizon_fade;
  vec3 normal=vec3(moon_uv,sqrt(max(0.,1.-r2)));
  vec3 light=vec3(dot(sun_direction,mr),dot(sun_direction,mu),-dot(sun_direction,md));
  float incidence=dot(normal,normalize(light));
  float lit=smoothstep(-.015,.035,incidence);
  // Stable mottled maria, pale highlands and several visible crater rims.
  float maria=smoothstep(.38,.65,fbm(moon_uv*2.5+vec2(3.7,11.2)));
  float surface=.88-maria*.27+(noise(moon_uv*42.)-.5)*.06;
  surface+=crater(moon_uv,vec2(-.37,.23),.17);
  surface+=crater(moon_uv,vec2(.32,-.46),.15);
  surface+=crater(moon_uv,vec2(.51,.22),.10);
  surface+=crater(moon_uv,vec2(-.17,-.62),.09);
  vec3 rock=vec3(.91,.93,.96)*surface;
  vec3 earthshine=clear_sky*.22+rock*.018*sqrt(moon_illumination);
  vec3 dark=mix(earthshine,col,daylight);
  vec3 bright=mix(rock*1.18*(.35+.65*pow(max(incidence,0.),.28)),mix(col,rock,.68),daylight);
  col=mix(col,mix(dark,bright,lit),edge);
 }
 vec2 uv=d.xz/max(d.y+.18,.12)*.7+vec2(sky_motion*.8,sky_motion*.13);
 // Three drifting cloud decks: rounded low clouds, broken middle banks and high wisps.
 // Density sampled toward the sun supplies self-shadowing and illuminated rims.
 for(int layer=2;layer>=0;layer--){
  float level=float(layer);
  vec2 q=uv*(2.4+level*1.7)+vec2(sky_motion*level*.17,level*19.7);
  float billow=fbm(q+vec2(fbm(q*.45),fbm(q*.45+13.))*1.3);
  float detail=fbm(q*3.2+7.);
  float density=mix(billow,detail,.17);
  float threshold=.49-overcast*.22+level*.025;
  float shape=smoothstep(threshold,threshold+.16,density)*smoothstep(.01,.18,d.y);
  if(layer==2){shape*=smoothstep(.38,.68,fbm(q*vec2(.25,2.5)))*.42;}
  vec2 light_offset=normalize(sun_direction.xz+vec2(.001))*.22;
  float sunward=fbm(q+light_offset);
  float lighting=clamp(.55+(billow-sunward)*3.8+sun_direction.y*.18,0.,1.);
  vec3 shade=mix(vec3(.012,.018,.04),vec3(.36,.43,.49),daylight);
  vec3 bright=mix(vec3(.055,.073,.12),vec3(.93,.95,.96),daylight);
  bright=mix(bright,vec3(.98,.49,.25),twilight*.65);
  vec3 cloud_color=mix(shade,bright,lighting);
  float rim=pow(max(dot(d,sun_direction),0.),12.)*(1.-shape)*.5;
  cloud_color+=bright*rim;
  float moon_scatter=pow(max(dot(d,md),0.),400.)*moonlight;
  cloud_color+=vec3(.025,.034,.05)*moon_scatter;
  // Thin clear-weather cloud lets a little moonlight through; overcast stays dense.
  float transmission=1.-moon_scatter*.45*(1.-overcast);
  col=mix(col,cloud_color,shape*(.9-level*.12)*cloud_opacity*transmission);
 }
 float sun=max(dot(d,normalize(sun_direction)),0.0);
 col+=vec3(1.,.65,.29)*pow(sun,6500.)*1.4*smoothstep(0.,.08,daylight);
 col+=vec3(.9,.36,.12)*pow(sun,35.)*twilight*.45;
 COLOR=mix(col,col*vec3(.64,.70,.77),overcast*.6);
}
