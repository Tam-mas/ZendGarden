"""Convert approved images, build wrapping micro-relief and measure exact savings.

Run with Pillow and numpy. Originals remain available for rebuilding models;
only compact runtime textures are included in the web export.
"""
from pathlib import Path
import json, shutil
from PIL import Image
import numpy as np
ROOT=Path(__file__).resolve().parents[1]

def prepare():
    source=ROOT/'art_source/bed_surfaces'
    for item in json.loads((source/'prompts.json').read_text()):
        original=source/(item['name']+'.png')
        if not original.exists():shutil.copyfile(item['source'],original)
        image=Image.open(original).convert('RGB').resize((1024,1024),Image.Resampling.LANCZOS)
        image.save(ROOT/'assets/textures/beds'/f"{item['name']}.webp",quality=90,method=6)
        # A faint micro-normal, with periodic derivatives at the repeating edges.
        height=np.asarray(image.convert('L'),dtype=float)/255
        dx=(np.roll(height,-1,1)-np.roll(height,1,1))*.35
        dy=(np.roll(height,-1,0)-np.roll(height,1,0))*.35
        normal=np.stack([-dx,dy,np.ones_like(dx)],axis=-1)
        normal/=np.linalg.norm(normal,axis=-1,keepdims=True)
        Image.fromarray(np.uint8((normal*.5+.5)*255)).save(ROOT/'assets/textures/beds'/f"{item['name']}_normal.webp",lossless=True,method=6)
    # Exact-pixel conversion for all standalone runtime landscape textures.
    report=[]
    for path in (ROOT/'assets/textures').glob('*.png'):
        if path.stem not in ['Garden_loam','Meadow_earth','Mountain_strata','Garden_loam_normal','Meadow_earth_normal','Mountain_strata_normal']:continue
        image=Image.open(path)
        target=path.with_suffix('.webp')
        image.save(target,lossless=True,method=6,exact=True)
        before=path.stat().st_size;after=target.stat().st_size
        if after<before:
            assert np.array_equal(np.asarray(image.convert('RGBA')),np.asarray(Image.open(target).convert('RGBA')))
            report.append({'source':str(path.relative_to(ROOT)),'runtime':str(target.relative_to(ROOT)),'before':before,'after':after,'lossless':True})
        else:target.unlink()
    # The requested photograph is replaced directly, without visual edits.
    image=Image.open(source/'start-original.jpg').convert('RGB')
    image.save(ROOT/'web/art/garden-woodland.webp',quality=92,method=6)
    shutil.copyfile(ROOT/'web/art/garden-woodland.webp',ROOT/'assets/ui/start-garden.webp')
    (source/'compression.json').write_text(json.dumps(report,indent=2)+'\n')
    print('LANDSCAPE_TEXTURE_COMPRESSION',len(report),'images',sum(r['before']-r['after'] for r in report),'bytes saved')
    print('START_BACKGROUND',image.size,(ROOT/'web/art/garden-woodland.webp').stat().st_size)

if __name__=='__main__':prepare()
