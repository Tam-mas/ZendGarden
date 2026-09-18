shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform sampler2D leaf_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 leaf_color : source_color = vec4(1.0);
void vertex(){
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float weight=clamp(VERTEX.y*.4,0.0,1.0);
 VERTEX.x+=sin(TIME*1.3+p.x*.8+p.z*.4)*.018*weight;
 VERTEX.z+=sin(TIME*1.7+p.z+p.x*.6)*.010*weight;
}
void fragment(){
 ALBEDO=texture(leaf_texture,UV).rgb*leaf_color.rgb;
 ROUGHNESS=.82;
 SPECULAR=.25;
}
