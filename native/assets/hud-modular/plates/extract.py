"""Extract individual authored sprites, retaining alpha and documented apertures.
Run from repository root with the bundled Python/Pillow runtime.
"""
from PIL import Image
from pathlib import Path
import json, shutil

ROOT = Path('native/assets/hud-modular/plates')
HEROES = ['mara-voss', 'kael', 'vesper', 'iona', 'orin', 'nagash']
PARTS = HEROES + ['currency', 'backpack', 'relics', 'reroll']
SPECS = {
 'voss': {'currency': [.255,.13,.40,.74], 'reroll': [.755,.13,.115,.74]},
 'kael': {'currency': [.26,.13,.40,.74], 'reroll': [.755,.13,.15,.74]},
 'vesper': {'currency': [.265,.13,.37,.74], 'reroll': [.705,.13,.16,.74]},
 'covenant': {'currency': [.265,.13,.35,.74], 'reroll': [.665,.13,.15,.74]},
}

def separated_sprites(im):
 w,h = im.size
 mask = bytearray(im.getchannel('A').point(lambda a: 255 if a>12 else 0).tobytes())
 pieces=[]
 for i in range(w*h):
  if not mask[i]: continue
  mask[i]=0;queue=[i];pixels=[];x0=w;y0=h;x1=0;y1=0
  while queue:
   p=queue.pop();pixels.append(p);y,x=divmod(p,w)
   x0=min(x0,x);y0=min(y0,y);x1=max(x1,x);y1=max(y1,y)
   for v in (p-1 if x else -1,p+1 if x<w-1 else -1,p-w if y else -1,p+w if y<h-1 else -1):
    if v>=0 and mask[v]:mask[v]=0;queue.append(v)
  if len(pixels)<2000:continue
  # Neighbouring ornaments overlap bounding boxes, but never alpha components.
  box=(x0,y0,x1+1,y1+1);piece=Image.new('RGBA',(x1-x0+1,y1-y0+1))
  source=im.load();target=piece.load()
  for p in pixels:
   y,x=divmod(p,w);target[x-x0,y-y0]=source[x,y]
  pieces.append((box,piece))
 assert len(pieces)==10,len(pieces)
 columns=[sorted([p for p in pieces if (p[0][0]+p[0][2])/2<w/2],key=lambda p:p[0][1]),sorted([p for p in pieces if (p[0][0]+p[0][2])/2>w/2],key=lambda p:p[0][1])]
 assert all(len(c)==5 for c in columns)
 return [columns[i%2][i//2] for i in range(10)]

if __name__=='__main__':
 prompts=json.loads((ROOT/'prompts.json').read_text(encoding='utf-8'))
 for theme,data in prompts.items():
  folder=ROOT/theme;folder.mkdir(exist_ok=True)
  shutil.copy2(data['source'],folder/'source-sheet.png')
  config={'nameplates':{},'plates':{},'portraits':{'mara-voss':'voss-bust.png','kael':'kael-bust.png','vesper':'vesper-bust.png','iona':'iona-bust.png','orin':'orin-bust.png','nagash':'covenant-bust.png'},'rail_geometry':{'voss':[-24,300],'kael':[-48,353],'vesper':[-48,340],'covenant':[-67,346]}[theme], 'layout':{'edge_padding':70,'inventory_clearance':42,'minimum_width':1600,'left_console_width':570,'right_console_width':570},'extraction':{}}
  for name,(box,piece) in zip(PARTS,separated_sprites(Image.open(data['source']).convert('RGBA'))):
   piece.save(folder/(name+'.png'))
   path='plates/'+theme+'/'+name+'.png'
   config['extraction'][name]={'source_rect':box,'size':list(piece.size)}
   if name in HEROES:config['nameplates'][name]=path
   else:
    config['plates'][name]={'texture':path,'icon_region':[.03,.14,.19,.72],'baked_label_region':([.67,.2,.26,.6] if name=='currency' else [.24,.2,.45,.6]),'value_region':SPECS[theme].get(name,[0,0,0,0]),'font_size':18 if name=='currency' else 18}
  (folder/'theme.json').write_text(json.dumps(config,indent=2)+'\n',encoding='utf-8')
  print('Extracted',theme,'six nameplates and four utility plates')
