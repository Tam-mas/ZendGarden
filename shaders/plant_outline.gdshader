shader_type spatial;
render_mode cull_front, unshaded, shadows_disabled;
#include "res://shaders/plant_shape.gdshaderinc"
#include "res://shaders/fruit_growth.gdshaderinc"
uniform float wind_strength=1.0;
void vertex() {
 attached_fruit_growth(VERTEX,UV2,COLOR);
 botanical_shape(VERTEX,NORMAL);
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float weight=clamp(VERTEX.y*.4,0.0,1.0);
 VERTEX.x+=sin(TIME*1.3+p.x*.8+p.z*.4)*.018*weight*wind_strength;
 VERTEX.z+=sin(TIME*1.7+p.z+p.x*.6)*.010*weight*wind_strength;
 VERTEX+=NORMAL*.008;
}
void fragment() { ALBEDO=vec3(1.0,.83,.42); }
