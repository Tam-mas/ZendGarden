"""Shared mesh primitives; no scene or file side effects on import."""
import bpy, math
from math import sin, cos, pi
from mathutils import Vector

def material(name,hexcolor,roughness=.8):
    m=bpy.data.materials.new(name); m.use_nodes=True
    col=tuple(int(hexcolor[i:i+2],16)/255 for i in (0,2,4))
    # glTF values are linear, unlike the supplied art-direction swatches.
    col=tuple(((c+.055)/1.055)**2.4 if c>.04045 else c/12.92 for c in col)
    bs=m.node_tree.nodes.get('Principled BSDF'); bs.inputs['Base Color'].default_value=(*col,1)
    bs.inputs['Roughness'].default_value=roughness
    bs.inputs['Specular IOR Level'].default_value=.25
    m.diffuse_color=(*col,1); m.use_backface_culling=False
    return m

class Geometry:
    def __init__(self): self.v=[]; self.f=[]; self.mi=[]; self.uv={}
    def face(self,indices,mat): self.f.append(indices); self.mi.append(mat)
    def tube(self,points,radii,mat=0,sides=6):
        points=[Vector(p) for p in points]; start=len(self.v)
        for i,p in enumerate(points):
            d=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized()
            up=Vector((0,0,1)) if abs(d.z)<.9 else Vector((1,0,0))
            a=d.cross(up).normalized(); b=d.cross(a).normalized()
            for j in range(sides): self.v.append(tuple(p+(a*cos(j*2*pi/sides)+b*sin(j*2*pi/sides))*radii[i]))
        for i in range(len(points)-1):
            for j in range(sides): self.face((start+i*sides+j,start+i*sides+(j+1)%sides,start+(i+1)*sides+(j+1)%sides,start+(i+1)*sides+j),mat)
        self.face(tuple(start+j for j in reversed(range(sides))),mat)
        self.face(tuple(start+(len(points)-1)*sides+j for j in range(sides)),mat)
    def leaf(self,base,tip,width,mat=1,curl=.12,segments=5,lobed=False):
        base=Vector(base); tip=Vector(tip); d=tip-base
        side=d.cross(Vector((0,0,1))).normalized()
        if side.length<.01: side=Vector((1,0,0))
        start=len(self.v)
        for j in range(segments+1):
            t=j/segments; w=sin(pi*t)**.85*width
            if lobed: w*=.7+.3*cos(t*6*pi)
            mid=base+d*t+Vector((0,0,sin(pi*t)*d.length*curl))
            self.v.extend([tuple(mid-side*w-Vector((0,0,w*.18))),tuple(mid+Vector((0,0,w*.1))),tuple(mid+side*w-Vector((0,0,w*.18)))])
        for j in range(segments+1):
            for side in range(3): self.uv[start+j*3+side]=(side*.5,j/segments)
        for j in range(segments):
            k=start+j*3
            self.face((k+1,k+4,k+3,k),mat); self.face((k+2,k+5,k+4,k+1),mat)
    def ellipsoid(self,c,scale,mat=1,rings=5,sides=8,ribs=0):
        start=len(self.v); c=Vector(c)
        for i in range(rings+1):
            theta=pi*i/rings
            for j in range(sides):
                a=2*pi*j/sides; r=1+ribs*cos(a*10)
                self.v.append(tuple(c+Vector((sin(theta)*cos(a)*scale[0]*r,sin(theta)*sin(a)*scale[1]*r,cos(theta)*scale[2]))))
        for i in range(rings):
            for j in range(sides): self.face((start+(i+1)*sides+j,start+(i+1)*sides+(j+1)%sides,start+i*sides+(j+1)%sides,start+i*sides+j),mat)
    def object(self,name,mats):
        mesh=bpy.data.meshes.new(name); mesh.from_pydata(self.v,[],self.f); mesh.update()
        uv=mesh.uv_layers.new(name='Botanical UV')
        for poly in mesh.polygons:
            for li in poly.loop_indices:
                vi=mesh.loops[li].vertex_index; point=mesh.vertices[vi].co
                uv.data[li].uv=self.uv.get(vi,(point.x*.7+point.y*.7,point.z*.7))
        for m in mats: mesh.materials.append(m)
        obj=bpy.data.objects.new(name,mesh); bpy.context.scene.collection.objects.link(obj)
        for p,mi in zip(mesh.polygons,self.mi): p.material_index=mi; p.use_smooth=True
        return obj
