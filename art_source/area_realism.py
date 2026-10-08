"""Garden masonry, jointed flags and less repetitive landscape construction.

Installed last so all ten packed source libraries reproduce the visual pass.
The existing terrain lattice, fixture IDs and collection pockets stay intact.
"""
import math
import random
import bpy
import numpy as np


def install(b):
    previous_materials = b.materials

    def mapped(name, filename, repeat=1.15):
        material = b.hq.material(name, (1, 1, 1), None, rough=.91)
        material['garden_surface'] = 'brick' if 'brick' in name else 'stone'
        material['metres_per_repeat'] = repeat
        nodes = material.node_tree.nodes
        links = material.node_tree.links
        bs = nodes.get('Principled BSDF')
        source = b.ROOT / 'art_source/areas/textures' / filename
        im = bpy.data.images.load(str(source), check_existing=True)
        im.pack()
        tex = nodes.new('ShaderNodeTexImage'); tex.image = im
        links.new(tex.outputs['Color'], bs.inputs['Base Color'])
        # Derive periodic microrelief; keep the ImageGen pigment unchanged.
        small = im.copy(); small.scale(512, 512)
        field = np.array(small.pixels[:]).reshape((512, 512, 4))[:, :, :3].mean(2)
        dx = (np.roll(field, -1, 1) - np.roll(field, 1, 1)) * 1.6
        dy = (np.roll(field, -1, 0) - np.roll(field, 1, 0)) * 1.6
        normal = np.stack((-dx, -dy, np.ones_like(field)), 2)
        normal /= np.linalg.norm(normal, axis=2)[:, :, None]
        rgba = np.ones((512, 512, 4)); rgba[:, :, :3] = normal * .5 + .5
        image = bpy.data.images.new(name + ' relief', width=512, height=512, alpha=True)
        image.colorspace_settings.name = 'Non-Color'
        image.pixels.foreach_set(rgba.astype(np.float32).ravel())
        image.filepath_raw = str(source.with_name(source.stem + '-normal.png'))
        image.file_format = 'PNG'; image.save(); image.pack()
        bpy.data.images.remove(small)
        nt = nodes.new('ShaderNodeTexImage'); nt.image = image
        nm = nodes.new('ShaderNodeNormalMap')
        links.new(nt.outputs['Color'], nm.inputs['Color'])
        links.new(nm.outputs['Normal'], bs.inputs['Normal'])
        return material

    def materials():
        previous_materials()
        if b.MATS.get('realism'): return b.MATS
        stone = mapped('Area weathered limestone', 'split-sandstone.png')
        b.MATS['stone'] = stone
        b.MATS['cream'] = stone
        b.MATS['flagstone'] = stone.copy(); b.MATS['flagstone'].name = 'Area cut garden flagstone'
        b.MATS['mossrock'] = stone.copy(); b.MATS['mossrock'].name = 'Area bank mossrock'
        b.MATS['brick'] = mapped('Area reclaimed wall brick', 'garden-wall-brick.png', 1.10)
        b.MATS['joint'] = b.hq.material('Area compacted joint sand', (.24, .215, .17), None, rough=.98)
        b.MATS['joint']['garden_surface'] = 'stone'
        # Pale pergola timber is paint, not the same stone as the pool coping.
        b.MATS['paint'] = b.hq.material('Area weathered painted oak', (.40, .43, .34), 'wood', rough=.9, size=512)
        b.MATS['paint']['garden_surface'] = 'timber'
        b.MATS['realism'] = True
        return b.MATS

    b.materials = materials
    previous_flush=b.Geometry.flush
    def flush(self):
        before=set(bpy.context.scene.objects)
        previous_flush(self)
        for node in set(bpy.context.scene.objects)-before:
            if node.type=='MESH':node['authored_surface_uv']=True
    b.Geometry.flush=flush
    old_ell = b.Geometry.ell

    def ell(self, parent, mat, p, size, seed=0, sectors=16, rings=8, rough=0):
        if not parent.name.startswith('Boulder'):
            return old_ell(self, parent, mat, p, size, seed, sectors, rings, rough)
        # Broad, bedded stones: imperfect shoulders and flattened fractured
        # tops replace identical smooth eggs while staying inside reservations.
        vs=[];fs=[];sectors=20;rings=10
        turn=seed*2.399
        for k in range(rings+1):
            t=math.pi*k/rings
            radius=math.sin(t)**.95
            for j in range(sectors):
                a=j*math.tau/sectors
                r=radius*(.94+.09*math.sin(a*3+seed)+.055*math.sin(a*7+t*3))
                # Rotate within an ellipse, not the whole footprint.
                x=math.cos(a+turn)*r*size[0]*.5;z=math.sin(a+turn)*r*size[2]*.5
                y=math.cos(t)*size[1]*.43+math.sin(t)*size[1]*.09*math.sin(a*3+seed)
                vs.append((p[0]+x,p[1]+y,p[2]+z))
        for k in range(rings):
            for j in range(sectors):
                a=k*sectors+j;c=k*sectors+(j+1)%sectors
                fs.append((a,c,c+sectors,a+sectors))
        self.poly(parent,mat,vs,fs)

    b.Geometry.ell = ell
    previous_reed=b.BUILDERS[0]
    def reed(G,root,index):
        previous_reed(G,root,index)
        support=b.pivot('Boardwalk bearers',root,collision=True,flat=True)
        for z in [4.54,5.66]:G.box(support,b.MATS['darkwood'],(0,1.29,z),(14.25,.18,.14))
        fixings=b.pivot('Boardwalk fixings',root,ground_detail=True)
        for k in range(34):
            x=-7+k*.42
            for z in [4.54,5.66]:
                for dx in [-.10,.10]:
                    G.ell(fixings,b.MATS['iron'],(x+dx,1.512,z),(.016,.005,.016),sectors=6,rings=3)
    b.BUILDERS[0]=reed

    previous_glass=b.BUILDERS[6]
    def glass(G,root,index):
        previous_glass(G,root,index)
        for key in list(G.groups):
            parent,mat=key
            if parent.name.startswith('Glasshouse frame') and mat==b.MATS['stone']:
                G.groups[(parent,b.MATS['brick'])]=G.groups.pop(key)
        frame=b.pivot('Glasshouse foundation sills',root,flat=True)
        gutters=b.pivot('Glasshouse rainwater goods',root)
        for side in [-1,1]:
            x=side*4.4
            G.box(frame,b.MATS['stone'],(x,1.92,0),(.28,.065,11.1))
            # Open U-section gutter with a wall-following downpipe.
            vs=[(x+side*(.045+.075*math.cos(j*math.pi/10)),3.60-.075*math.sin(j*math.pi/10),z) for z in [-5.53,5.53] for j in range(11)]
            G.poly(gutters,b.MATS['zinc'],vs,[(j,j+1,j+12,j+11) for j in range(10)])
            G.tube(gutters,b.MATS['zinc'],[(x+side*.12,3.56,5.14),(x+side*.18,3.35,5.14),(x+side*.18,1.42,5.14),(x+side*.30,1.28,5.14)],[.04]*4,10)
    b.BUILDERS[6]=glass

    previous_stream=b.BUILDERS[7]

    def stream(G,root,index):
        previous_stream(G,root,index)
        # Break the necklace-like regular bank stones into varied embedded
        # groups. Botanical reservations and bridge clearance still apply.
        for key in list(G.groups):
            if key[0].name.startswith('Boulder'):
                parent=key[0];del G.groups[key]
                bpy.data.objects.remove(parent,do_unlink=True)
        rng=random.Random(7401)
        for side in [-1,1]:
            z=-8.8
            while z<9:
                x=1.5*math.sin(z*.4)+side*rng.uniform(1.10,1.42)
                if abs(z-3)>.95:
                    scale=rng.uniform(.55,1.05)
                    b.rock(G,root,index,x,z,(scale,.35+scale*.22,scale*.8),int((z+12)*17),True)
                z+=rng.uniform(.70,1.28)

    b.BUILDERS[7]=stream
    previous_moon=b.BUILDERS[9]

    def moon(G,root,index):
        previous_moon(G,root,index)
        for key in list(G.groups):
            parent,mat=key
            if parent.name.startswith('Moon pergola') and mat==b.MATS['cream']:
                G.groups[(parent,b.MATS['paint'])]=G.groups.pop(key)
        # A segmented stone coping reads as masonry rather than a pipe around
        # the reflecting pool. Retain the pool's exact radius and collision.
        for key in list(G.groups):
            if key[0].name.startswith('Reflection pool rim'):del G.groups[key]
        rim=b.pivot('Reflection pool rim fitted coping',root,collision=True,flat=True)
        for j in range(52):
            a=j*math.tau/52+.003;c=(j+1)*math.tau/52-.003
            vs=[(-1+radius*math.cos(t),y,radius*math.sin(t)) for y in [1.08,1.25] for radius,t in [(2.94,a),(3.30,a),(3.30,c),(2.94,c)]]
            G.poly(rim,b.MATS['stone'],vs,[tuple(reversed(f)) for f in [(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]])

    b.BUILDERS[9]=moon
