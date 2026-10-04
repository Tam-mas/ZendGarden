"""Explicit WebP conversion: lossless normals/alpha; high-quality colour maps."""
import sys,json
from pathlib import Path
from PIL import Image

source=Path(sys.argv[1]);destination=Path(sys.argv[2]);lossless=sys.argv[3]=='lossless'
im=Image.open(source)
im.save(destination,'WEBP',lossless=lossless,quality=95,method=6,exact=True)
decoded=Image.open(destination)
assert decoded.size==im.size
if lossless:assert decoded.convert('RGBA').tobytes()==im.convert('RGBA').tobytes()
print(json.dumps({'png_bytes':source.stat().st_size,'webp_bytes':destination.stat().st_size,'lossless':lossless}))
