// Fruit attachment X/Y is UV2; Z uses two colour bytes to retain precision.
// All stalk/body vertices grow about the same branch attachment, before shape.
uniform bool fruit_anchors=false;
uniform float fruit_growth=1.0;
void attached_fruit_growth(inout vec3 vertex, vec2 anchor_xy, vec4 depth) {
 if(fruit_anchors) {
  float z=dot(depth.rg,vec2(256.0,1.0))*255.0/65535.0*16.0-8.0;
  // glTF exports Blender's V coordinate as 1-V, including the data UV layer.
  vec3 anchor=vec3(anchor_xy.x,1.0-anchor_xy.y,z);
  vertex=anchor+(vertex-anchor)*fruit_growth;
 }
}
