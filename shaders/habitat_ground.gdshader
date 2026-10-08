shader_type spatial;
uniform sampler2D meadow : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D meadow_normal : hint_normal,filter_linear_mipmap,repeat_enable;
uniform sampler2D earth : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D relief : hint_normal,filter_linear_mipmap,repeat_enable;
uniform sampler2D dry_floor : source_color,filter_linear_mipmap,repeat_enable;
uniform vec4 tint : source_color = vec4(1.);
uniform float texture_scale = .72;
uniform vec2 habitat_center;
uniform int habitat_kind = 1;
uniform sampler2D margin_soil : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D margin_normal : hint_normal,filter_linear_mipmap,repeat_enable;
uniform int margin_count=0;
uniform vec4 planted_margins[16];
varying vec3 world;
void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 vec2 p=world.xz-habitat_center;
 vec3 grass=texture(meadow,world.xz*.6).rgb*vec3(.72,.86,.72);
 float luma=dot(grass,vec3(.22,.68,.10));
 grass=mix(grass,vec3(luma)*vec3(.83,.95,.72),.28)*.70;
 vec3 common_lawn=grass;
 float broad=texture(meadow,world.xz*.091+vec2(.28,.39)).g;
 grass*=mix(.93,1.06,broad);
 if(habitat_kind==2)grass=texture(dry_floor,world.xz*.9).rgb*vec3(.46,.43,.35);
 if(habitat_kind==1)grass*=vec3(.98,.95,.87);
 vec3 gravel=texture(earth,world.xz*texture_scale).rgb*tint.rgb;
 // Crushed local stone reads as a garden surface rather than a white sheet.
 if(habitat_kind==2)gravel*=vec3(.55,.51,.41);
 if(habitat_kind==9)gravel*=vec3(.55,.56,.50);
 float irregular=sin(p.x*9.+sin(p.y*4.))*sin(p.y*11.)*.035;
 float mask=0.;
 if(habitat_kind==4){
  float edge=5.7+.18*sin(p.y*1.7)+.10*sin(p.y*3.2);
  mask=smoothstep(1.42,1.58,abs(p.x)-.12*sin(p.y*.7))*
       (1.-smoothstep(edge-.10,edge+.08,abs(p.x)+irregular))*
       (1.-smoothstep(5.7,5.92,abs(p.y)-.15*sin(p.x*2.)));
 }else if(habitat_kind==0){
  float r=length((p+vec2(1.4,0.))/vec2(4.25,3.8));
  mask=1.-smoothstep(.97,1.30,r+irregular*.3);
  gravel*=vec3(.36,.43,.34);
 }else if(habitat_kind==2){
  mask=(1.-smoothstep(5.9,6.25,abs(p.x)))*(1.-smoothstep(6.8,7.2,abs(p.y)));
 }else if(habitat_kind==9){
  float r=length((p+vec2(1.,0.))/vec2(6.5,6.3));
  mask=1.-smoothstep(.94,1.03,r+irregular*.25);
 }else if(habitat_kind==1 || habitat_kind==7){
  float center=habitat_kind==1?1.0*sin(p.y*.42)+.30*sin(p.y*.83):1.5*sin(p.y*.4);
  float distance=abs(p.x-center);
  mask=1.-smoothstep(.57,.99,distance+irregular);
  gravel*=vec3(.40,.46,.37);
  grass*=habitat_kind==1?vec3(.86,.91,.81):vec3(1.);
 }
 float border=smoothstep(9.1,11.8,max(abs(p.x),abs(p.y)));
 float margin=0.;
 for(int i=0;i<margin_count;i++){
  vec4 bed=planted_margins[i];
  float radius=length((p-bed.xy)/max(bed.zw,vec2(.1)));
  float edge=radius+sin(p.x*3.2+sin(p.y*2.1))*.06+sin(p.y*5.3)*.025;
  margin=max(margin,1.-smoothstep(.58,1.08,edge));
 }
 // A broken, feathered soil edge leaves the common meadow at every seam.
 margin*=1.-smoothstep(10.7,11.8,max(abs(p.x),abs(p.y)));
 margin*=mix(.68,.88,broad);
 vec3 soil=texture(margin_soil,world.xz*.72).rgb*vec3(.78,.82,.69);
 if(habitat_kind==2 || habitat_kind==8)soil=mix(soil,gravel,.30);
 ALBEDO=mix(mix(mix(grass,gravel,mask),common_lawn,border),soil,margin);ROUGHNESS=.97;SPECULAR=.18;
 NORMAL_MAP=mix(mix(mix(texture(meadow_normal,world.xz*.6).rgb,texture(relief,world.xz*texture_scale).rgb,mask),texture(meadow_normal,world.xz*.6).rgb,border),texture(margin_normal,world.xz*.72).rgb,margin);
 NORMAL_MAP_DEPTH=.5;
}
