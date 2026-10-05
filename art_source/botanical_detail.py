"""Curved botanical organs and deterministic PBR surfaces for the 60-species library.
Kept separate from Geometry so rebuilding plants cannot alter landscape/shop assets.
"""
import math
from pathlib import Path
import bpy
import numpy as np
from mathutils import Vector


def surfaces(root):
    folder=Path(root)/'assets/textures/botanical'; folder.mkdir(parents=True,exist_ok=True)
    n=256; v,u=np.mgrid[0:n,0:n]/(n-1); rng=np.random.default_rng(926)
    grain=rng.normal(0,.012,(n,n)); axis=np.abs(u-.5)
    mid=np.exp(-((u-.5)/.014)**2)
    veins=np.exp(-(np.sin((v-axis*.72-axis**2*.30)*math.pi*9)/.10)**2)*np.clip(1-axis*1.7,0,1)
    reticulation=np.sin(u*190+v*21)*np.sin(v*230-u*17)*.013
    leaf=.68+.17*np.sin(v*math.pi)+.13*mid+.085*veins+grain+reticulation
    petal=.72+.18*v+.024*np.cos((u-.5)*52+(1-v)*4)+grain*.3
    furrow=np.maximum(0,np.sin(u*71+np.sin(v*19)*1.9+np.sin(u*17+v*9)))**6
    bark=.78-.17*furrow+.045*np.sin(u*196+v*8)+grain*2
    lenticels=(np.cos(v*86+np.sin(u*40)*.6)>.985)*(np.cos(u*36)>.45)
    smooth=.87+.055*np.sin(u*16+v*10)-lenticels*.24+grain*.5
    fruit=.83+.065*np.sin(u*12+np.sin(v*16))+.045*np.cos(v*13)+grain*1.2
    pollen=.75+.14*np.sin(u*190)*np.sin(v*180)+grain
    maps={}
    for kind,field,rough in [('leaf',leaf,.66),('petal',petal,.60),('bark',bark,.91),('smooth',smooth,.74),('fruit',fruit,.39),('pollen',pollen,.9)]:
        images=[]
        dy,dx=np.gradient(field); strength=3.0 if kind=='leaf' else 2.1 if kind=='bark' else 1.3
        norm=np.stack((-dx*strength,-dy*strength,np.ones_like(field)),2);norm/=np.linalg.norm(norm,axis=2)[:,:,None]
        for suffix,rgb,noncolor in [('color',np.repeat(np.clip(field,0,1)[:,:,None],3,2),False),('normal',norm*.5+.5,True),('roughness',np.repeat(np.clip(rough+(field-.75)*.2,0,1)[:,:,None],3,2),True)]:
            rgba=np.concatenate([rgb,np.ones((n,n,1))],2).astype('float32')
            image=bpy.data.images.new('Botanical '+kind+' '+suffix,width=n,height=n)
            if noncolor:image.colorspace_settings.name='Non-Color'
            image.pixels.foreach_set(rgba.ravel());image.filepath_raw=str(folder/(kind+'_'+suffix+'.png'));image.file_format='PNG';image.save();image.pack();images.append(image)
        maps[kind]=images
    return maps


def texture_material(material,kind,maps):
    tree=material.node_tree; bs=tree.nodes.get('Principled BSDF')
    # Keep each species' pigment while sharing the microstructure maps.
    for link in list(tree.links):
        if link.to_node==bs:tree.links.remove(link)
    source=maps[kind][0];pixels=np.array(source.pixels[:],dtype='float32').reshape((-1,4))
    linear=np.array(material.diffuse_color[:3])
    pigment=np.where(linear>.0031308,1.055*linear**(1/2.4)-.055,12.92*linear)
    pixels[:,:3]*=pigment
    image=bpy.data.images.new(material.name+' pigment',width=source.size[0],height=source.size[1])
    image.pixels.foreach_set(pixels.ravel())
    filename=''.join(c if c.isalnum() else '_' for c in material.name)+'_color.png'
    image.filepath_raw=str(Path(source.filepath_raw).parent/filename);image.file_format='PNG';image.save();image.pack()
    color=tree.nodes.new('ShaderNodeTexImage');color.image=image
    tree.links.new(color.outputs['Color'],bs.inputs['Base Color'])
    normal=tree.nodes.new('ShaderNodeTexImage');normal.image=maps[kind][1]
    nm=tree.nodes.new('ShaderNodeNormalMap');nm.inputs['Strength'].default_value=.6
    tree.links.new(normal.outputs['Color'],nm.inputs['Color']);tree.links.new(nm.outputs['Normal'],bs.inputs['Normal'])
    rough=tree.nodes.new('ShaderNodeTexImage');rough.image=maps[kind][2];tree.links.new(rough.outputs['Color'],bs.inputs['Roughness'])
    # Bake pigment into the map because the glTF exporter omits legacy MixRGB tints.
    material.use_backface_culling=False


def detail_geometry(base):
    class BotanicalGeometry(base):
        def __init__(self,name,role):
            super().__init__();self.species=name;self.role=role
        def object(self,name,mats):
            obj=super().object(name,mats)
            from fruit_tree_geometry import add_anchor_channels
            add_anchor_channels(obj.data,self)
            return obj
        def leaf(self,base,tip,width,mat=1,curl=.12,segments=5,lobed=False):
            base=Vector(base);tip=Vector(tip);d=tip-base;length=d.length
            if length<.00001:return
            petal=self.role=='bloom'
            blade_base=base
            if not petal and length>.065 and width/length>.13:
                blade_base=base+d*.075
                super().tube([base,blade_base],[max(.0007,width*.035),max(.0004,width*.021)],0 if self.species!='Beetroot' else 8,4)
            d=tip-blade_base; side=d.cross(Vector((0,0,1))).normalized()
            if side.length<.01:side=Vector((1,0,0))
            up=side.cross(d.normalized()).normalized()
            if up.z<0:up=-up
            phase=base.x*71+base.y*39+base.z*29+len(self.v)*.018
            broad=width/length>.14
            columns=5 if broad and length>.055 else 3
            segments=max(segments,6 if broad and length>.1 else 4) if length>.04 else min(segments,3)
            # Species leaf edges: broad blades are gently toothed, grasses stay smooth.
            toothed=self.species in ['Rose','Silver birch','Cherry blossom','Apple','Hydrangea','Camellia','Sunflower','Strawberry','Tomato','Lettuce','Radish','Banksia'] and not petal
            rows=[]
            for j in range(segments+1):
                t=j/segments
                if j in [0,segments]:
                    mid=blade_base+d*t
                    rows.append([len(self.v)]);self.v.append(tuple(mid));self.uv[len(self.v)-1]=(.5,t);continue
                profile=math.sin(math.pi*t)**(.46 if self.species in ['Lettuce','Basil','Gardenia','Camellia','Magnolia'] or petal else .82)
                if petal:profile*=.75+.5*t
                if lobed:profile*=.79+.21*math.cos(t*6*math.pi)
                if toothed:profile*=1+(.09 if self.species!='Lettuce' else .18)*math.sin(t*segments*math.pi+phase)
                w=profile*width
                arch=math.sin(math.pi*t)*length*curl
                mid=blade_base+d*t+up*arch+side*(math.sin(t*math.pi)*math.sin(phase)*length*.045)
                row=[]
                for k in range(columns):
                    s=k/(columns-1)*2-1
                    fold=-(abs(s)**1.35)*w*(.18 if petal else .22)
                    ripple=abs(s)**3*math.sin(t*math.pi*5+phase)*w*(.13 if petal or self.species=='Lettuce' else .055)
                    twist=s*math.sin(t*math.pi)*w*math.sin(phase+1)*.18
                    row.append(len(self.v));self.v.append(tuple(mid+side*s*w+up*(fold+ripple+twist)));self.uv[len(self.v)-1]=(k/(columns-1),t)
                rows.append(row)
            for j in range(segments):
                a,b=rows[j],rows[j+1]
                if len(a)==1:
                    for k in range(columns-1):self.face((a[0],b[k+1],b[k]),mat)
                elif len(b)==1:
                    for k in range(columns-1):self.face((a[k],a[k+1],b[0]),mat)
                else:
                    for k in range(columns-1):self.face((a[k],a[k+1],b[k+1],b[k]),mat)
        def cupped_blade(self,base,angle,length,width,rise,mat,ruffle=.05):
            base=Vector(base);forward=Vector((math.cos(angle),math.sin(angle),0));side=Vector((-math.sin(angle),math.cos(angle),0))
            start=len(self.v);rows=9;cols=9
            for j in range(rows):
                t=j/(rows-1);envelope=math.sin(math.pi*(t*.80+.025))**.60
                for k in range(cols):
                    q=k/(cols-1)*2-1
                    radial=length*t*(1-.38*q*q*t)
                    z=rise*t+length*.10*math.sin(math.pi*t)+width*.22*q*q*math.sin(math.pi*t)
                    z+=width*ruffle*abs(q)**2*math.sin(t*16+q*5)
                    # The curved terminal edge stays broad, with rounded corners.
                    z+=width*.10*(1-q*q)*t**5
                    p=base+forward*radial+side*q*width*envelope+Vector((0,0,z))
                    self.v.append(tuple(p));self.uv[len(self.v)-1]=((q+1)*.5,t)
            for j in range(rows-1):
                for k in range(cols-1):
                    a=start+j*cols+k;self.face((a,a+cols,a+cols+1,a+1),mat)

        def tube(self,points,radii,mat=0,sides=6):
            # More radial detail only for stems/trunks that occupy visible pixels.
            maximum=max(radii)
            sides=max(sides,12 if maximum>.08 else 8 if maximum>.018 else sides)
            start=len(self.v);super().tube(points,radii,mat,sides)
            distances=[0]
            for a,b in zip(points,points[1:]):distances.append(distances[-1]+(Vector(b)-Vector(a)).length)
            for i,dist in enumerate(distances):
                for j in range(sides):self.uv[start+i*sides+j]=(j/sides,dist/max(.08,maximum*6))
        def ellipsoid(self,c,scale,mat=1,rings=5,sides=8,ribs=0):
            size=max(scale)
            if size>.03:rings=max(rings,8);sides=max(sides,12)
            if self.species=='Pumpkin' and size>.1:sides=max(sides,32)
            start=len(self.v);super().ellipsoid(c,scale,mat,rings,sides,ribs)
            if self.species=='Strawberry' and self.role=='bloom' and mat==0 and size>.025:
                for i in range(start,len(self.v)):
                    p=Vector(self.v[i])-Vector(c);factor=.78+.22*(p.z/scale[2])
                    self.v[i]=tuple(Vector(c)+Vector((p.x*factor,p.y*factor,p.z)))
            for i in range(rings+1):
                for j in range(sides):self.uv[start+i*sides+j]=(j/sides,i/rings)
    return BotanicalGeometry
