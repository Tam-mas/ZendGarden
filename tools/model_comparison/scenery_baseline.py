"""Extract the original scenery samples without changing their geometry."""
import copy
import json
import struct


def extract(data, names, cottage=False):
    size = struct.unpack_from('<I', data, 12)[0]
    source = json.loads(data[20:20 + size])
    bin_start = 20 + size + 8
    source_bin = data[bin_start:]
    output = {'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': []}],
              'nodes': [], 'meshes': [], 'materials': copy.deepcopy(source.get('materials', [])),
              'accessors': [], 'bufferViews': [], 'buffers': []}
    for key in ['extensionsUsed', 'textures', 'samplers']:
        if key in source:
            output[key] = copy.deepcopy(source[key])
    payload = bytearray()
    selected = [n for n in source['nodes'] if n.get('name') in names]
    if len(selected) != len(names):
        raise ValueError(f'Scenery nodes not found: {names}')

    def read(index):
        accessor = source['accessors'][index]
        view = source['bufferViews'][accessor['bufferView']]
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[accessor['type']]
        fmt = {5126: 'f', 5123: 'H', 5125: 'I', 5121: 'B'}[accessor['componentType']]
        row_size = struct.calcsize('<' + fmt * width)
        start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        stride = view.get('byteStride', row_size)
        rows = [struct.unpack_from('<' + fmt * width, source_bin, start + i * stride)
                for i in range(accessor['count'])]
        return accessor, rows, fmt

    center = (-7.4, 0, -18)
    if cottage:
        primitive = source['meshes'][selected[0]['mesh']]['primitives'][0]
        _, points, _ = read(primitive['attributes']['POSITION'])
        # Main's WorldGeometry emits 16 vertices per plaster box and 12 per roof.
        # Keep the first complete cottage from the exported hamlet batch.
        first = points[:16]
        center = ((min(p[0] for p in first) + max(p[0] for p in first)) / 2,
                  min(p[1] for p in first),
                  (min(p[2] for p in first) + max(p[2] for p in first)) / 2)

    def write_accessor(index, semantic, limit=None):
        accessor, rows, fmt = read(index)
        if limit is not None:
            rows = rows[:limit]
        if semantic == 'POSITION':
            # Face the same direction as the new sample, retaining metre scale.
            rows = [(-(p[0]-center[0]), p[1]-center[1], -(p[2]-center[2])) for p in rows]
        elif semantic == 'NORMAL':
            rows = [(-p[0], p[1], -p[2]) for p in rows]
        while len(payload) % 4:
            payload.append(0)
        offset = len(payload)
        for row in rows:
            payload.extend(struct.pack('<' + fmt * len(row), *row))
        view_index = len(output['bufferViews'])
        output['bufferViews'].append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(payload)-offset})
        new = {k: accessor[k] for k in ['componentType', 'type']}
        new.update({'bufferView': view_index, 'count': len(rows)})
        if semantic == 'POSITION':
            new['min'] = [min(row[i] for row in rows) for i in range(3)]
            new['max'] = [max(row[i] for row in rows) for i in range(3)]
        output['accessors'].append(new)
        return len(output['accessors'])-1

    for node in selected:
        mesh = {'name': node['name'], 'primitives': []}
        for number, primitive in enumerate(source['meshes'][node['mesh']]['primitives']):
            new = {k: primitive[k] for k in ['material', 'mode'] if k in primitive}
            limit = (16 if number == 0 else 12) if cottage else None
            new['attributes'] = {semantic: write_accessor(index, semantic, limit)
                                 for semantic, index in primitive['attributes'].items()}
            new['indices'] = write_accessor(primitive['indices'], 'INDEX',
                                            (36 if number == 0 else 18) if cottage else None)
            mesh['primitives'].append(new)
        output['scenes'][0]['nodes'].append(len(output['nodes']))
        output['nodes'].append({'name': node['name'], 'mesh': len(output['meshes'])})
        output['meshes'].append(mesh)
    # Retain original embedded texture bytes and material bindings. Environment
    # materials include other scenery too; every retained index must stay valid.
    output['images'] = []
    for image in source.get('images', []):
        if 'bufferView' not in image:
            raise ValueError('Expected embedded baseline scenery textures')
        original = source['bufferViews'][image['bufferView']]
        while len(payload) % 4:
            payload.append(0)
        offset = len(payload)
        start = original.get('byteOffset', 0)
        payload.extend(source_bin[start:start + original['byteLength']])
        replacement = copy.deepcopy(image)
        replacement['bufferView'] = len(output['bufferViews'])
        output['bufferViews'].append({'buffer': 0, 'byteOffset': offset,
                                      'byteLength': original['byteLength']})
        output['images'].append(replacement)
    output['buffers'] = [{'byteLength': len(payload)}]
    encoded = json.dumps(output, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    payload += b'\x00' * (-len(payload) % 4)
    return (struct.pack('<III', 0x46546c67, 2, 28 + len(encoded) + len(payload)) +
            struct.pack('<II', len(encoded), 0x4e4f534a) + encoded +
            struct.pack('<II', len(payload), 0x004e4942) + payload)
