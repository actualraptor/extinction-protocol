"""Connected-alpha extraction of real painted hero starter attack poses."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw
from extract_clean_icons import components

ASSETS=Path(__file__).resolve().parents[1]/'assets'
OUT=ASSETS/'hero-attacks-0111'
PHASES=[0,.12,.30,.50,.62,.80]
CONFIG={
 'voss': {'id':'0','height':440,'poses':['reach','draw','aim','brace','fire','recover'],
  'normal':[(288,489),(807,491),(1267,489),(281,973),(858,970),(1312,972)],
  'halloween':[(291,507),(802,508),(1279,508),(280,988),(852,988),(1302,989)]},
 'vesper': {'id':'2','height':430,'poses':['gather','lift','channel','windup','release','recover'],
  'normal':[(275,532),(796,533),(1371,534),(352,982),(805,982),(1343,983)],
  'halloween':[(272,528),(808,527),(1382,528),(342,987),(797,987),(1350,988)]}
}

def main():
 metadata={'release_progress':.62,'standing_body_height':68,'heroes':{}}
 canvas=Image.new('RGB',(840,560),'#111d20');draw=ImageDraw.Draw(canvas)
 row=0
 for hero,config in CONFIG.items():
  variants={};scale=68/config['height']
  for variant in ['normal','halloween']:
   sheet=Image.open(ASSETS/f'{hero}-starter-attack-{variant}-0111.png')
   rgba,ownership,_=components(sheet,3,2)
   assert np.count_nonzero(rgba[:,:,3]==0)>sheet.width*sheet.height*.30, 'Missing transparent alpha'
   output=OUT/hero/variant;output.mkdir(parents=True,exist_ok=True);frames=[]
   for i,pose in enumerate(config['poses']):
    mask=ownership==i;y,x=np.nonzero(mask)
    bounds=(max(0,int(x.min())-8),max(0,int(y.min())-8),min(sheet.width,int(x.max())+9),min(sheet.height,int(y.max())+9))
    pixels=rgba.copy();pixels[~mask]=0
    frame=Image.fromarray(pixels).crop(bounds);filename=f'{i:02d}-{pose}.png';frame.save(output/filename)
    anchor=[config[variant][i][0]-bounds[0],config[variant][i][1]-bounds[1]]
    frames.append({'pose':pose,'file':f'res://assets/hero-attacks-0111/{hero}/{variant}/{filename}','anchor':anchor,'size':list(frame.size),'source_bounds':list(bounds),'phase_from':PHASES[i]})
    small=frame.resize((round(frame.width*scale),round(frame.height*scale)),Image.Resampling.LANCZOS)
    cx=70+i*140;baseline=104+row*140
    canvas.paste(small,(round(cx-anchor[0]*scale),round(baseline-anchor[1]*scale)),small)
    draw.line((cx-35,baseline,cx+35,baseline),fill='#507064')
    draw.text((cx-40,baseline+8),f'{hero}: {pose}',fill='#ebd4a0')
   variants[variant]=frames;row+=1
  metadata['heroes'][config['id']]={'name':hero,'pixel_scale':scale,'source_body_height':config['height'],'variants':variants}
 (OUT/'frames.json').write_text(json.dumps(metadata,indent=2),encoding='utf8')
 canvas.save(ASSETS.parent/'build'/'hero-attacks-68px-contact.png')
 print('Extracted 24 distinct real starter attack poses, anchored at 68px body scale.')

if __name__=='__main__':main()
