#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
uniform vec4 plant_shape = vec4(0.0);
uniform float plant_height = 1.0;
#else
instance uniform vec4 plant_shape = vec4(0.0);
instance uniform float plant_height = 1.0;
#endif
void botanical_shape_values(inout vec3 vertex, inout vec3 normal, vec4 shape, float height) {
 float t=clamp(vertex.y/max(height,.1),0.0,1.0);
 float angle=shape.z*t + sin(t*6.0+shape.w)*shape.z*.18*t;
 float c=cos(angle); float s=sin(angle);
 vertex.xz=mat2(vec2(c,s),vec2(-s,c))*vertex.xz;
 normal.xz=mat2(vec2(c,s),vec2(-s,c))*normal.xz;
 vertex.xz+=shape.xy*height*t*t;
 normal.y-=dot(normal.xz,shape.xy*2.0*t);
 normal=normalize(normal);
}
void botanical_shape(inout vec3 vertex, inout vec3 normal) {
 botanical_shape_values(vertex,normal,plant_shape,plant_height);
}
