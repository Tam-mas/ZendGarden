#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
uniform vec4 plant_shape = vec4(0.0);
uniform float plant_height = 1.0;
#else
instance uniform vec4 plant_shape = vec4(0.0);
instance uniform float plant_height = 1.0;
#endif
void botanical_shape(inout vec3 vertex, inout vec3 normal) {
 float t=clamp(vertex.y/max(plant_height,.1),0.0,1.0);
 float angle=plant_shape.z*t + sin(t*6.0+plant_shape.w)*plant_shape.z*.18*t;
 float c=cos(angle); float s=sin(angle);
 vertex.xz=mat2(vec2(c,s),vec2(-s,c))*vertex.xz;
 normal.xz=mat2(vec2(c,s),vec2(-s,c))*normal.xz;
 vertex.xz+=plant_shape.xy*plant_height*t*t;
 normal.y-=dot(normal.xz,plant_shape.xy*2.0*t);
 normal=normalize(normal);
}
