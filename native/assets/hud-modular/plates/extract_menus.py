from PIL import Image
from pathlib import Path
import json,shutil
ROOT=Path('native/assets/hud-modular/plates')
scope={}
# Reuse the documented alpha-component extractor without running shell extraction.
exec((ROOT/'extract_shells.py').read_text().split('for theme,data in')[0],scope)
names=['heading','location','score','resume','backpack_stats','settings','end_expedition']
for theme,data in json.loads((ROOT/'menu-prompts.json').read_text()).items():
 im=Image.open(data['source']).convert('RGBA');w,h=im.size
 pieces=scope['components'](im)
 assert len(pieces)==7,(theme,pieces)
 by_y=sorted(pieces,key=lambda p:(p[1][1]+p[1][3])/2)
 ordered=[by_y[0]]
 for row in range(3):ordered+=sorted(by_y[1+row*2:3+row*2],key=lambda p:p[1][0])
 folder=ROOT/theme
 shutil.copy2(data['source'],folder/'menu-source.png')
 config=json.loads((folder/'theme.json').read_text());config['menu']={}
 for part,(_,box) in zip(names,ordered):
  im.crop(box).save(folder/('menu-'+part+'.png'))
  config['menu'][part]={'texture':'plates/'+theme+'/menu-'+part+'.png','source_rect':box}
 config['menu']['score']['primary']=[.17,.25,.39,.50]
 config['menu']['location']['primary']={'voss':[.79,.30,.12,.50],'vesper':[.805,.29,.13,.50]}.get(theme,[.75,.25,.15,.50])
 config['menu']['location']['secondary']=[.21,.27,.48,.46]
 (folder/'theme.json').write_text(json.dumps(config,indent=2)+'\n')
 print(theme,[p[1] for p in ordered])
