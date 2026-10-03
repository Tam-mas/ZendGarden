"""Small sequential MCP batches; restore the user's scene and selection."""
import bpy,importlib
import common_hq

def run(category,kinds):
    module=importlib.import_module(category)
    previous=bpy.context.window.scene
    selected=list(bpy.context.selected_objects)
    active=bpy.context.view_layer.objects.active
    records=[]
    try:
        for kind in kinds:records.append(module.build(kind))
    finally:
        bpy.context.window.scene=previous
        for ob in bpy.context.selected_objects:ob.select_set(False)
        for ob in selected:
            if ob.name in previous.objects:ob.select_set(True)
        bpy.context.view_layer.objects.active=active
    return {'category':category,'assets':records,'restored_scene':previous.name}
