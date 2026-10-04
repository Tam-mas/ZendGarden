"""Package completed Godot render sequences as lightweight comparison GIFs."""
from pathlib import Path
import shutil
from PIL import Image, ImageChops

ROOT=Path(__file__).resolve().parent/'previews'
shutil.copyfile(ROOT/'godot/idle_00.png',ROOT/'comparison.png')
for name,total,count in [('walk',1200,36),('idle',8000,96),('look',5000,60)]:
    files=sorted((ROOT/'godot').glob(name+'_*.png'))
    assert len(files)==count,(name,len(files),count)
    images=[Image.open(p).convert('RGB').resize((960,615),Image.Resampling.LANCZOS) for p in files]
    palette=images[0].quantize(colors=256)
    frames=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in images]
    durations=[round((i+1)*total/count/10)*10-round(i*total/count/10)*10 for i in range(count)]
    frames[0].save(ROOT/(name+'-comparison.gif'),save_all=True,append_images=frames[1:],
                   duration=durations,loop=0,optimize=True,disposal=2)
    diff=ImageChops.difference(images[0].crop((480,140,960,570)),images[count//3].crop((480,140,960,570)))
    assert diff.getbbox() is not None,('static prototype capture',name)
    print(name,count,'animated prototype pixels:',diff.getbbox())
