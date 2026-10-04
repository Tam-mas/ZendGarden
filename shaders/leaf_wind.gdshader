shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform sampler2D leaf_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaf_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaf_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool has_normal_map=false;
uniform bool has_roughness_map=false;
uniform vec4 leaf_color : source_color = vec4(1.0);
#include "res://shaders/plant_shape.gdshaderinc"
uniform bool has_color_map=true;
uniform float wind_strength=1.0;
uniform float surface_roughness=.82;
uniform float surface_backlight=.10;
uniform bool batched_plant=false;
uniform float batch_plant_height=1.0;
void vertex(){
 if(batched_plant) {
  botanical_shape_values(VERTEX,NORMAL,INSTANCE_CUSTOM,batch_plant_height);
 } else {
  botanical_shape(VERTEX,NORMAL);
 }
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float weight=clamp(VERTEX.y*.4,0.0,1.0);
 VERTEX.x+=sin(TIME*1.3+p.x*.8+p.z*.4)*.018*weight*wind_strength;
 VERTEX.z+=sin(TIME*1.7+p.z+p.x*.6)*.010*weight*wind_strength;
}
void fragment(){
 ALBEDO=(has_color_map ? texture(leaf_texture,UV).rgb : vec3(1.0))*leaf_color.rgb;
 ROUGHNESS=has_roughness_map ? texture(leaf_roughness,UV).g : surface_roughness;
 if(has_normal_map) { NORMAL_MAP=texture(leaf_normal,UV).rgb; NORMAL_MAP_DEPTH=.55; }
 BACKLIGHT=ALBEDO*surface_backlight;
 SPECULAR=.25;
}
