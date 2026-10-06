from PIL import Image
from pathlib import Path
import json, shutil
ROOT=Path('native/assets/hud-modular/plates')
# Extraction only: isolate two authored sprite components, preserving their pixels.
def components(im):
 w,h=im.size; mask=bytearray(im.getchannel('A').point(lambda a:255 if a>12 else 0).tobytes());pieces=[]
 for i in range(w*h):
  if not mask[i]:continue
  mask[i]=0;queue=[i];count=0;x0=w;y0=h;x1=0;y1=0
  while queue:
   p=queue.pop();y,x=divmod(p,w);count+=1;x0=min(x0,x);y0=min(y0,y);x1=max(x1,x);y1=max(y1,y)
   for v in (p-1 if x else -1,p+1 if x<w-1 else -1,p-w if y else -1,p+w if y<h-1 else -1):
    if v>=0 and mask[v]:mask[v]=0;queue.append(v)
  if count>2000:pieces.append((count,(x0,y0,x1+1,y1+1)))
 return pieces
for theme,data in json.loads((ROOT/'shell-prompts.json').read_text()).items():
 im=Image.open(data['source']).convert('RGBA')
 pieces=components(im)
 assert len(pieces)==2,(theme,pieces)
 folder=ROOT/theme
 shutil.copy2(data['source'],folder/'shell-source.png')
 config=json.loads((folder/'theme.json').read_text())
 config['shells']={}
 for part,(_,box) in zip(['left','right'],sorted(pieces,key=lambda p:p[1][1])):
  sprite=im.crop(box);sprite.save(folder/(part+'-shell.png'))
  config['shells'][part]={'texture':'plates/'+theme+'/'+part+'-shell.png','source_rect':box,'cuts':[0,.20,.80,1],'caps':[78,42] if part=='left' else [42,90]}
 config['layout']['right_console_width']=570
 config['layout']['edge_padding']=70
 (folder/'theme.json').write_text(json.dumps(config,indent=2)+'\n')
 print(theme,[(p[1],p[0]) for p in pieces])
