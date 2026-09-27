shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
uniform sampler2D leaf_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaf_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D leaf_roughness : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool has_normal_map=false;
uniform bool has_roughness_map=false;
uniform vec4 leaf_color : source_color = vec4(1.0);
uniform vec4 preview_tint : source_color = vec4(.82,.95,.66,.4);
void vertex(){
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 float weight=clamp(VERTEX.y*.4,0.0,1.0);
 VERTEX.x+=sin(TIME*1.3+p.x*.8+p.z*.4)*.018*weight;
 VERTEX.z+=sin(TIME*1.7+p.z+p.x*.6)*.010*weight;
}
void fragment(){
 vec4 leaf=texture(leaf_texture,UV)*leaf_color;
 ALBEDO=mix(leaf.rgb,preview_tint.rgb,.45);
 ALPHA=leaf.a*preview_tint.a;
 ROUGHNESS=has_roughness_map ? texture(leaf_roughness,UV).g : .82;
 if(has_normal_map) { NORMAL_MAP=texture(leaf_normal,UV).rgb; NORMAL_MAP_DEPTH=.55; }
 BACKLIGHT=ALBEDO*.10;
 SPECULAR=.25;
}
