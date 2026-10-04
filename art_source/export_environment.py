"""Strip channels ignored by the game, retaining every rendered position and normal.

The editable Blender scene keeps its UVs and relief masks. Compact only its GLB
export; copying surviving buffer views avoids re-tessellation or colour-space
round trips in the playable garden.
"""
from pathlib import Path
import json
import struct

WORLD_SHADED={'AlpineLakeValley','OuterMountainRidges','ContourLake'}

def compact_environment(path):
    path=Path(path)
    source=path.read_bytes()
    length=struct.unpack_from('<I',source,12)[0]
    doc=json.loads(source[20:20+length])
    binary=bytearray(source[28+length:])
    assert not doc.get('animations') and not doc.get('skins'), 'Landscape must be static'
    for node in doc['nodes']:
        if node.get('name') in WORLD_SHADED and 'mesh' in node:
            for primitive in doc['meshes'][node['mesh']]['primitives']:
                primitive['attributes']={name:index for name,index in primitive['attributes'].items()
                                         if name in ('POSITION','NORMAL')}
                attributes=primitive['attributes']
                position=doc['accessors'][attributes['POSITION']]
                normal=doc['accessors'][attributes['NORMAL']]
                assert position['type']==normal['type']=='VEC3'
                assert position['componentType']==normal['componentType']==5126
                def rows(accessor, width):
                    view=doc['bufferViews'][accessor['bufferView']]
                    start=view.get('byteOffset',0)+accessor.get('byteOffset',0)
                    stride=view.get('byteStride',width)
                    return [bytes(binary[start+i*stride:start+i*stride+width]) for i in range(accessor['count'])]
                unique={}; remap=[]; points=[]; normals=[]
                for point, norm in zip(rows(position,12),rows(normal,12)):
                    key=point+norm
                    if key not in unique:
                        unique[key]=len(points); points.append(point); normals.append(norm)
                    remap.append(unique[key])
                # UV/mask seams can split otherwise identical vertices. Reuse
                # only vertices whose rendered positions AND normals are exact.
                def append_accessor(template, contents, count):
                    view=len(doc['bufferViews'])
                    doc['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':len(contents)})
                    binary.extend(contents); binary.extend(b'\0'*(-len(binary)%4))
                    accessor=dict(template,bufferView=view,count=count)
                    accessor.pop('byteOffset',None)
                    doc['accessors'].append(accessor)
                    return len(doc['accessors'])-1
                attributes['POSITION']=append_accessor(position,b''.join(points),len(points))
                attributes['NORMAL']=append_accessor(normal,b''.join(normals),len(normals))
                indices=doc['accessors'][primitive['indices']]
                kind={5121:'B',5123:'H',5125:'I'}[indices['componentType']]
                width=struct.calcsize('<'+kind)
                rewritten=[remap[struct.unpack('<'+kind,value)[0]] for value in rows(indices,width)]
                template=dict(indices)
                template.pop('min',None);template.pop('max',None)
                primitive['indices']=append_accessor(template,struct.pack('<'+kind*len(rewritten),*rewritten),len(rewritten))

    accessors=sorted({index for mesh in doc['meshes'] for primitive in mesh['primitives']
                      for index in [primitive['indices'],*primitive['attributes'].values()]})
    assert not any('sparse' in doc['accessors'][index] for index in accessors)
    views=sorted({doc['accessors'][index]['bufferView'] for index in accessors}
                 | {image['bufferView'] for image in doc.get('images',[])})
    accessor_map={old:new for new,old in enumerate(accessors)}
    view_map={old:new for new,old in enumerate(views)}
    payload=bytearray()
    for index in views:
        view=doc['bufferViews'][index]
        assert view.get('buffer',0)==0
        start=view.get('byteOffset',0)
        contents=binary[start:start+view['byteLength']]
        view['byteOffset']=len(payload)
        payload.extend(contents)
        payload.extend(b'\0'*(-len(payload)%4))
    for mesh in doc['meshes']:
        for primitive in mesh['primitives']:
            primitive['indices']=accessor_map[primitive['indices']]
            primitive['attributes']={name:accessor_map[index] for name,index in primitive['attributes'].items()}
    for index in accessors:
        accessor=doc['accessors'][index]
        accessor['bufferView']=view_map[accessor['bufferView']]
    for image in doc.get('images',[]):image['bufferView']=view_map[image['bufferView']]
    doc['accessors']=[doc['accessors'][index] for index in accessors]
    doc['bufferViews']=[doc['bufferViews'][index] for index in views]
    doc['buffers']=[{'byteLength':len(payload)}]
    metadata=json.dumps(doc,separators=(',',':')).encode()
    metadata+=b' '*(-len(metadata)%4)
    output=(struct.pack('<4sII','glTF'.encode(),2,28+len(metadata)+len(payload))
            +struct.pack('<I4s',len(metadata),b'JSON')+metadata
            +struct.pack('<I4s',len(payload),b'BIN\0')+payload)
    temporary=path.with_suffix('.compact.glb')
    temporary.write_bytes(output)
    temporary.replace(path)
    print(f'Landscape channels: {len(source):,} → {len(output):,} bytes; geometry unchanged')

def export_environment(path):
    import bpy
    bpy.ops.object.select_all(action='DESELECT')
    for obj in bpy.context.scene.objects:obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
                              use_active_scene=True,export_yup=True,export_apply=True)
    compact_environment(path)

if __name__=='__main__':
    compact_environment(Path(__file__).resolve().parents[1]/'assets/environment/lake_garden.glb')
