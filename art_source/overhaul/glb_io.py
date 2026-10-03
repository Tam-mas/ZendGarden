"""Small lossless metadata corrections for our exported static landscape."""
import json,re,struct

def canonical_environment_names(path):
    raw=path.read_bytes();length=struct.unpack_from('<I',raw,12)[0]
    doc=json.loads(raw[20:20+length]);tail=raw[20+length:]
    for bank in ['nodes','meshes']:
        for item in doc.get(bank,[]):
            if 'name' in item:item['name']=re.sub(r'(?:\.\d{3})+$','',item['name'])
    blob=json.dumps(doc,separators=(',',':')).encode();blob+=b' '*((-len(blob))%4)
    total=20+len(blob)+len(tail)
    path.write_bytes(struct.pack('<4sII',b'glTF',2,total)+struct.pack('<I4s',len(blob),b'JSON')+blob+tail)
