from pathlib import Path
from PIL import Image
import json
from collections import deque
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'build/individual-dinosaur-sources'
paths=sorted(folder.glob('boss/*/*.png'))+sorted(folder.glob('regular/*/*.png'))
report=[]
for p in paths:
 im=Image.open(p).convert('RGBA');alpha=im.getchannel('A')
 corners=[alpha.getpixel((x,y)) for x,y in [(0,0),(im.width-1,0),(0,im.height-1),(im.width-1,im.height-1)]]
 bounds=alpha.point(lambda a:255 if a>32 else 0).getbbox()
 assert bounds and max(corners)<=1,(p,corners,bounds)
 mask=np.asarray(alpha.resize((im.width//4,im.height//4),Image.Resampling.NEAREST))>100
 visited=np.zeros(mask.shape,dtype=bool);pieces=[]
 for y,x in zip(*np.where(mask)):
  if visited[y,x]:continue
  visited[y,x]=True;pending=deque([(int(y),int(x))]);area=0;left=right=int(x);top=bottom=int(y)
  while pending:
   cy,cx=pending.popleft();area+=1
   left=min(left,cx);right=max(right,cx);top=min(top,cy);bottom=max(bottom,cy)
   for dy,dx in [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(-1,1),(1,-1),(1,1)]:
    ny,nx=cy+dy,cx+dx
    if 0<=ny<mask.shape[0] and 0<=nx<mask.shape[1] and mask[ny,nx] and not visited[ny,nx]:
     visited[ny,nx]=True;pending.append((ny,nx))
  if area>=8:pieces.append({'area':area,'bounds':[left*4,top*4,(right+1)*4,(bottom+1)*4]})
 pieces.sort(key=lambda part:part['area'],reverse=True)
 report.append({'pose':p.relative_to(folder).as_posix(),'size':list(im.size),'bounds':list(bounds),'corner_alpha':corners,'components':pieces})
(folder/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(f'{len(paths)}/210 independently generated images present; transparent corners verified')
