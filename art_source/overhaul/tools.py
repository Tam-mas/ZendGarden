"""Preserve the existing tool grips while adding grain, metal and enamel detail."""
import bpy
from common_hq import *

KINDS=['can','shears','trowel','rake','hoe']

def build(kind):
    target=scene('tools');replace_authored('tools','tools',kind)
    with bpy.data.libraries.load(str(ROOT/'art_source/hand_tools.blend'),link=False) as (src,dst):
        dst.objects=list(src.objects)
    source=next(o for o in dst.objects if o and o.name.split('.')[0]=='Held_'+kind)
    source.location=(0,0,0)
    pieces=[source]+list(source.children_recursive)
    for o in pieces:target.collection.objects.link(o)
    replacements={
        'Honey ash handles':material('HQ ash handle wood',(.31,.19,.075),'wood',.78),
        'Brushed steel':material('HQ brushed tool steel',(.34,.39,.39),'metal',.31,.8,size=512),
        'Enamel sage':material('HQ sage enamel',(.13,.26,.20),'metal',.34,.3,size=512),
        'Handle grips':material('HQ rubber handle grips',(.04,.06,.045),'fabric',.9,size=512),
    }
    for o in pieces:
        if o.type!='MESH':continue
        for i,m in enumerate(o.data.materials):
            if m:
                replacement=replacements.get(m.name.split('.')[0])
                if replacement:o.data.materials[i]=replacement
        bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
        for modifier in list(o.modifiers):bpy.ops.object.modifier_apply(modifier=modifier.name)
        if not o.data.uv_layers:
            bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
            bpy.ops.uv.smart_project(island_margin=.01);bpy.ops.object.mode_set(mode='OBJECT')
    record=export(source,'tools',kind)
    source.location.x=KINDS.index(kind)*.7;source.hide_set(False)
    save('tools')
    return record
