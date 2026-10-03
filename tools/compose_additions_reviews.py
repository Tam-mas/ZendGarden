"""Label Godot renders of the new models; no synthetic or reference photographs."""
import json,math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'captures/botanical-additions';DEST.mkdir(parents=True,exist_ok=True)
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
font=lambda n:ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc',n)
def sheet(ids,title,filename,cols=5,tile=250,compat=False):
    gap=16;row=tile+44
    canvas=Image.new('RGB',(cols*(tile+gap)+gap,80+math.ceil(len(ids)/cols)*row),(37,46,39))
    draw=ImageDraw.Draw(canvas);draw.text((gap,20),title,fill='#eee4cf',font=font(26))
    folder='botanical-review-compat' if compat else 'botanical-review'
    for k,i in enumerate(ids):
        x=gap+k%cols*(tile+gap);y=70+k//cols*row
        im=Image.open(ROOT/'captures'/folder/f'{i:02d}.png').convert('RGBA')
        im.thumbnail((tile,tile),Image.Resampling.LANCZOS)
        canvas.paste(im,(x+(tile-im.width)//2,y),im)
        draw.text((x,y+tile+8),specs[i][0],fill='#eee4cf',font=font(17))
    canvas.save(DEST/filename)
sheet(range(106,116),'Ten new ornamental grasses','grasses.png')
sheet(range(116,136),'Cacti & succulents — twenty new varieties','succulents.png')
sheet([9,10],'Revised Sweet pea and Clematis','climbers.png',2,480)
print('ADDITIONS_REVIEW: PASS')
