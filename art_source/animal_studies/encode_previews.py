"""Package actual rendered Godot sequences and Blender portraits for review."""
from pathlib import Path
import json,shutil
from PIL import Image,ImageChops,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parent
for kind in ['fox','dog','echidna','rabbit']:
 folder=ROOT/kind/'previews'
 shutil.copyfile(folder/'godot/idle_00.png',folder/'comparison.png')
 report=json.loads((ROOT/kind/'report.json').read_text())
 for clip in report['clips']:
  files=sorted((folder/'godot').glob(clip+'_*.png'))
  count=36 if clip in ['walk','hop'] else 48 if clip in ['forage','sniff','look'] else 24
  assert len(files)==count,(kind,clip,len(files),count)
  images=[Image.open(p).convert('RGB').resize((960,615),Image.Resampling.LANCZOS) for p in files]
  palette=images[0].quantize(colors=256);frames=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in images]
  total=round(report['clips'][clip]*1000)
  durations=[max(10,round((i+1)*total/count/10)*10-round(i*total/count/10)*10) for i in range(count)]
  frames[0].save(folder/(clip+'-comparison.gif'),save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=True,disposal=2)
  if clip in ['walk','hop','look','sniff','forage']:
   diff=ImageChops.difference(images[0].crop((480,170,960,600)),images[count//3].crop((480,170,960,600)))
   assert diff.getbbox(),('static prototype',kind,clip)
  print('RENDERED_ANIMATION',kind,clip,count)
canvas=Image.new('RGB',(1200,1290),'#eadfce');draw=ImageDraw.Draw(canvas)
try:font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',24)
except OSError:font=ImageFont.load_default()
for i,kind in enumerate(['fox','dog','echidna','rabbit']):
 portrait=Image.open(ROOT/kind/'previews/textured.png').convert('RGB').resize((590,590),Image.Resampling.LANCZOS)
 x=5+(i%2)*600;y=5+(i//2)*645;canvas.paste(portrait,(x,y));draw.text((x+15,y+600),kind.capitalize()+' · supplied STL prototype',fill='#493329',font=font)
canvas.save(ROOT/'portraits.webp',quality=95,method=6)
