"""Arrange exported-model renders and captured animation frames for review."""
import argparse,math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1]
CAPTURES=ROOT/'captures/overhaul'
OUT=ROOT/'art_source/overhaul/previews'
MAMMALS=['rabbit','kangaroo','kangaroo_joey','echidna','wombat','fox']
BIRDS=['songbird','native_bird','fairy_wren','kookaburra','lorikeet','magpie']
SMALL=['frog','fish','bee','butterfly','dragonfly','firefly','lady_beetle','blue_banded_bee','hoverfly','mantis','leaf_insect','emperor_gum_moth']
SHOP=['stone','pot','bench','lantern','arbor','pergola','greenhouse','pond','bath','hive','sign','potting_bench','compost_bays','rain_barrel','raised_bed','trellis_screen','gazebo','arched_bridge','fountain','garden_swing','insect_hotel']
GROUPS={
 'animals':([('companions',k) for k in ['cat','dog']]+[('wildlife',k) for k in MAMMALS+BIRDS+SMALL],6),
 'structures':([('shop',k) for k in SHOP],5),
 'scenery-tools':([('scenery',k) for k in ['garden_shed','footbridge','lakeside_cottage']]+[('tools',k) for k in ['can','shears','trowel','rake','hoe']],4),
}

def sheet(name):
 pairs,columns=GROUPS[name];cell=288;rows=math.ceil(len(pairs)/columns)
 image=Image.new('RGB',(cell*columns,cell*rows),(235,232,225));draw=ImageDraw.Draw(image)
 font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',18)
 for i,(folder,kind) in enumerate(pairs):
  x=i%columns*cell;y=i//columns*cell
  tile=Image.open(CAPTURES/f'{folder}_{kind}.png').convert('RGB').resize((252,252),Image.Resampling.LANCZOS)
  image.paste(tile,(x+18,y+5))
  label='Kangaroo with joey' if kind=='kangaroo_joey' else kind.replace('_',' ').title()
  draw.text((x+cell/2,y+272),label,font=font,fill=(52,46,38),anchor='mm')
 image.save(OUT/(name+'.jpg'),quality=92)

def motion():
 pairs=[('cat','walk'),('dog','walk'),('fox','walk'),('rabbit','hop'),('wombat','walk'),('echidna','walk'),('kangaroo','hop'),('kangaroo_joey','hop'),('kookaburra','flight'),('fairy_wren','perch'),('lorikeet','forage'),('magpie','forage'),('bee','flight'),('emperor_gum_moth','flight'),('fish','swim')]
 for kind,clip in pairs:
  paths=sorted((CAPTURES/'motion').glob(f'{kind}_{clip}_*.png'))
  assert len(paths)==16,(kind,'expected sixteen captured frames')
  frames=[Image.open(p).convert('RGB').resize((384,384),Image.Resampling.LANCZOS) for p in paths]
  frames[0].save(OUT/f'{kind}-{clip}.gif',save_all=True,append_images=frames[1:],duration=85,loop=0)

if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('category',choices=[*GROUPS,'all','motion']);args=parser.parse_args();OUT.mkdir(exist_ok=True)
 if args.category=='motion':motion()
 else:
  for name in GROUPS if args.category=='all' else [args.category]:sheet(name)
 print('OVERHAUL_REVIEW: PASS '+args.category)
