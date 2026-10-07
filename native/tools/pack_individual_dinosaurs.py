"""Pack exclusively independently generated, complete individual poses.
No component masking or splitting of multi-subject source sheets is allowed.
"""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'build/individual-dinosaur-sources'
IDS=['thorn','basalt','hunt','aurora','warden','bloom']
def pose(path):
 image=Image.open(path).convert('RGBA')
 bounds=image.getchannel('A').point(lambda a:255 if a>8 else 0).getbbox()
 assert bounds, f'Empty pose: {path}'
 # Tight bounds of one whole animal, only empty outside margin is omitted.
 return image.crop((max(0,bounds[0]-4),max(0,bounds[1]-4),min(image.width,bounds[2]+4),min(image.height,bounds[3]+4)))
def pack():
 required=[SOURCE/'regular'/str(k)/f'{f:02d}.png' for k in range(19) for f in range(6)]
 required += [SOURCE/'boss'/id/f'{f:02d}.png' for id in IDS for f in range(16)]
 missing=[str(p) for p in required if not p.exists()]
 assert not missing, f'{len(missing)} individual poses still missing: {missing[:3]}'
 atlas=Image.new('RGBA',(1536,19*192))
 for kind in range(19):
  frames=[pose(SOURCE/'regular'/str(kind)/f'{f:02d}.png') for f in range(6)]
  scale=min(238/max(p.width for p in frames),174/max(p.height for p in frames))
  for f,image in enumerate(frames):
   image=image.resize((round(image.width*scale),round(image.height*scale)),Image.Resampling.LANCZOS)
   atlas.alpha_composite(image,(f*256+(256-image.width)//2,kind*192+183-image.height))
 atlas.save(ROOT/'assets/dinosaurs/regular-atlas.png')
 (ROOT/'assets/dinosaurs/regular-layout.json').write_text(json.dumps({str(k):{'source':'individual','frames':6,'source_directory':f'regular/{k}'} for k in range(19)},indent=2),encoding='utf8')
 atlas=Image.new('RGBA',(2048,4608));layouts=[];corpses={}
 for row,id in enumerate(IDS):
  frames=[pose(SOURCE/'boss'/id/f'{f:02d}.png') for f in range(16)]
  scale=min(480/max(p.width for p in frames),350/max(p.height for p in frames))
  bone=Image.new('RGBA',(2048,768));bounds=[]
  for f,image in enumerate(frames):
   image=image.resize((round(image.width*scale),round(image.height*scale)),Image.Resampling.LANCZOS)
   x=(f%4)*512+(512-image.width)//2;y=(f//4%2)*384+374-image.height
   if f<8:
    atlas.alpha_composite(image,(x,row*768+y))
    if f==7:corpses[id]=[x,row*768+y,image.width,image.height]
   else:
    bone.alpha_composite(image,(x,y));bounds.append([x,y,image.width,image.height])
  bone.save(ROOT/'payload/dinosaurs'/f'{row+1:02d}.dat',format='PNG');layouts.append(bounds)
 atlas.save(ROOT/'assets/dinosaurs/boss-atlas.png')
 (ROOT/'payload/dinosaurs/layout.dat').write_text(json.dumps(layouts),encoding='utf8')
 (ROOT/'scripts/dinosaur_layout.gd').write_text('extends RefCounted\nconst CORPSES={'+','.join('"'+id+'":Rect2('+','.join(map(str,b))+')' for id,b in corpses.items())+'}\n',encoding='utf8')
 print('Packed 210 independently generated poses; six painted bloodied corpses; no source-sheet slicing')
if __name__=='__main__':pack()
