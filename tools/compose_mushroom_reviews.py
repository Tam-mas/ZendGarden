"""Label real Godot mushroom portraits; run with Pillow after render_plant_cards.gd."""
from pathlib import Path
import sys
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'art_source'))
from mushroom_data import MUSHROOMS
font_path=Path('/System/Library/Fonts/Supplemental/Arial.ttf')
font=ImageFont.truetype(str(font_path),20) if font_path.exists() else ImageFont.load_default()
folder=ROOT/'captures/mushrooms';folder.mkdir(parents=True,exist_ok=True)
canvas=Image.new('RGB',(1500,660),'#e9e4d7');draw=ImageDraw.Draw(canvas)
for n,(idx,name,*_) in enumerate(MUSHROOMS):
    portrait=Image.open(ROOT/f'captures/botanical-review/{idx}.png').convert('RGBA');portrait.thumbnail((285,285))
    x=(n%5)*300+(300-portrait.width)//2;y=(n//5)*330
    canvas.paste(portrait,(x,y),portrait)
    draw.text(((n%5)*300+150,y+300),name,fill='#342c24',font=font,anchor='mm')
canvas.save(folder/'mushroom-collection.jpg',quality=95)
labels=['Pins emerging','Young mushrooms','Caps forming','Caps opening','Ready to gather']
canvas=Image.new('RGB',(1150,2030),'#e9e4d7');draw=ImageDraw.Draw(canvas)
for col,label in enumerate(labels):draw.text((col*230+115,20),label,fill='#342c24',font=font,anchor='mm')
for row,(idx,name,*_) in enumerate(MUSHROOMS):
    for col in range(5):
        portrait=Image.open(ROOT/f'captures/flower-stages/{idx}-{col}.png').convert('RGBA');portrait.thumbnail((190,170))
        canvas.paste(portrait,(col*230+(230-portrait.width)//2,45+row*198),portrait)
    draw.text((10,45+row*198+174),name,fill='#342c24',font=font)
canvas.save(folder/'mushroom-growth.jpg',quality=94)
print('MUSHROOM_REVIEW: '+str(folder/'mushroom-collection.jpg'))
