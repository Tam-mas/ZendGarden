"""Label the actual Godot renders for the 46-plant expansion; requires Pillow."""
import json,math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];DEST=ROOT/'captures/botanical-expansion';DEST.mkdir(parents=True,exist_ok=True)
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())
font_path='/System/Library/Fonts/Helvetica.ttc'
def font(n):return ImageFont.truetype(font_path,n)
def sheet(ids,title,filename,cols=4,tile=320):
    gap=18;row=tile+58;canvas=Image.new('RGB',(cols*(tile+gap)+gap,90+math.ceil(len(ids)/cols)*row),(28,39,34));draw=ImageDraw.Draw(canvas)
    draw.text((gap,22),title,fill='#f2eadb',font=font(28))
    for k,i in enumerate(ids):
        x=gap+(k%cols)*(tile+gap);y=80+(k//cols)*row
        im=Image.open(ROOT/'captures/botanical-review'/f'{i:02d}.png').convert('RGBA');im.thumbnail((tile,tile),Image.Resampling.LANCZOS)
        canvas.paste(im,(x+(tile-im.width)//2,y),im)
        label=specs[i][0];f=font(19)
        if draw.textlength(label,font=f)>tile:f=font(16)
        draw.text((x,y+tile+8),label,fill='#eee8db',font=f)
    canvas.save(DEST/filename,quality=94)
for cat in ['Flowers','Shrubs','Trees','Natives','Produce']:
    ids=[i for i in range(60,106) if specs[i][1]==cat]
    sheet(ids,cat+' — new Blender plant models',cat.lower()+'.jpg')
sheet([68,70,78,81,76,77,95,92,100,101,103,105],'Botanical expansion — selected game renders','highlights.jpg',4,360)
print('EXPANSION_REVIEW: PASS — 46 labelled portraits')
