import json
from pathlib import Path
from PIL import Image
base=Path('native/assets')
walk=json.loads((base/'walk-regions.json').read_text())[:3]
for name in ['iona','orin']:
 im=Image.open(base/(name+'-walk.png')).convert('RGBA');w,h=im.size;frames=[]
 for row in range(3):
  for col in range(4):
   x0=round(col*w/4);y0=round(row*h/3);x1=round((col+1)*w/4);y1=round((row+1)*h/3)
   bounds=im.getchannel('A').crop((x0,y0,x1,y1)).getbbox()
   assert bounds
   l,t,r,b=bounds;frames.append([x0+l,y0+t,r-l,b-t])
 walk.append(frames)
(base/'walk-regions.json').write_text(json.dumps(walk,indent=2))
im=Image.open(base/'frontiers-07.png');w,h=im.size;regions=[]
for col in range(4):
 x0=round(col*w/4);y0=round(h/3);x1=round((col+1)*w/4);y1=round(h*2/3)
 l,t,r,b=im.getchannel('A').crop((x0,y0,x1,y1)).getbbox();regions.append([x0+l,y0+t,r-l,b-t])
(base/'frontier-regions.json').write_text(json.dumps(regions))
print('Indexed',len(walk),'heroes;',len(regions),'new enemy sprites')
