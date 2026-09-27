"""Assemble matched Godot portraits into labelled review sheets (requires Pillow)."""
import json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'captures/plants'
specs=json.loads((ROOT/'art_source/plant_specs.json').read_text())[:60]
font_path=Path('/System/Library/Fonts/Helvetica.ttc')
def font(size):
    return ImageFont.truetype(str(font_path),size) if font_path.exists() else ImageFont.load_default()

def sheet(ids,title,filename,tile=384):
    gap=24;row_h=tile+76;width=tile*4+gap*3
    image=Image.new('RGB',(width,90+((len(ids)+1)//2)*row_h),(22,32,29));draw=ImageDraw.Draw(image)
    draw.text((24,22),title,fill='#eef2e9',font=font(30))
    for i,idx in enumerate(ids):
        x=gap+(i%2)*(tile*2+gap);y=90+(i//2)*row_h
        draw.text((x,y),specs[idx][0],fill='#eef2e9',font=font(25))
        for col,variant in enumerate(['before','after']):
            draw.text((x+col*tile,y+34),variant.upper(),fill='#a8bcb0',font=font(17))
            tile_image=Image.open(DEST/variant/f'{idx:02d}.png').convert('RGB').resize((tile,tile),Image.Resampling.LANCZOS)
            image.paste(tile_image,(x+col*tile,y+60))
    image.save(DEST/filename,quality=94)

for category in dict.fromkeys(row[1] for row in specs):
    ids=[i for i,row in enumerate(specs) if row[1]==category]
    sheet(ids,category+' — matched before / after',category.lower()+'.jpg')
sheet([3,20,30,45,48,47],'Plant detail pass — same camera, scale and lighting','highlights.jpg')
print('PLANT_COMPARISON_SHEETS: PASS — all 60 plants in six category sheets')

# Identical source rectangles and aspect-preserving enlargement for fine detail.
examples=[(3,'Sunflower heads',(275,90,570,420)),(48,'Lettuce leaves',(190,160,590,590))]
w,h=640,680
closeups=Image.new('RGB',(w*2,70+(h+50)*2),(22,32,29));draw=ImageDraw.Draw(closeups)
draw.text((20,18),'Detail views — identical crops from the matched renders',fill='white',font=font(26))
for row,(idx,label,box) in enumerate(examples):
    y=70+row*(h+50)
    for col,variant in enumerate(['before','after']):
        portrait=Image.open(DEST/variant/f'{idx:02d}.png').convert('RGB').crop(box)
        portrait=ImageOps.pad(portrait,(w,h),method=Image.Resampling.LANCZOS,color=(38,51,49))
        closeups.paste(portrait,(col*w,y+50))
        draw.text((col*w+20,y+12),label+' — '+variant.upper(),fill='white',font=font(26))
closeups.save(DEST/'details.jpg',quality=94)
