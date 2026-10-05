"""Generate local player notes and their shareable artwork. Never exports or publishes."""
from pathlib import Path
import json,re
from PIL import Image,ImageDraw,ImageFont,ImageOps
ROOT=Path(__file__).resolve().parents[2]
NATIVE=ROOT/'native'
VERSION='0.11.0'
TITLE='Fortune and Fang'
entries=[
 ('lens','relic','EVERY FIND HAS A FUTURE','Every relic can now roll Common, Uncommon, Rare, Epic, Legendary or Artifact. Its rarity changes its actual power. Eight distinct relics fit in your satchel; collect up to ten copies of each without spending another slot.'),
 ('crown','relic','BUILD A KINGDOM OF EXPERIENCE','Amber Lens grants 5 / 7.5 / 10 / 15 / 20 / 30% more XP by tier. Copies add together. King of Nothing grants the same bonus to score and XP, but increases future horde health by that amount. Existing enemies and bosses keep their health.'),
 ('prism','relic','LUCK THAT YOU CAN FEEL','Base chest odds: Common 40%, Uncommon 30%, Rare 18%, Epic 9%, Legendary 2.7%, Artifact 0.3%. Luck improves the higher tiers. After four Common or Uncommon chests, the next rarity roll is Rare or better. The reel displays your current odds.'),
 ('wrap','relic','BIG ROLLS. REAL REWARDS.','Chest refinements grant 1 / 1 / 2 / 2 / 3 / 4 ranks by tier, stopping at the upgrade cap. A full relic satchel keeps improving your chosen relics. When all eligible improvements are complete, chests pay 25 / 35 / 50 / 75 / 100 / 150 amber by tier.'),
 ('map','relic','LESS WALKING. MORE DISCOVERY.','All three maps have shorter authored routes. First supplies take about 20 seconds to reach with starter Kael; the farthest rewards take roughly a minute. Boss arenas and weapon ranges keep their room to breathe.'),
 ('map','relic','AN ATLAS WORTH OPENING','The overlay opens in a readable local view, with terrain and route context. Press O for the whole stage, F to recenter, drag with the middle mouse button and use the wheel to zoom. Labels avoid each other; map instructions no longer collide with the XP bar.'),
 ('thorn','boss','FACES OF THE ECOSYSTEM','Bosses have their own portraits, including normal and Hollow Harvest versions. Patch notes, map markers and boss windups now show the actual boss. Crown, Lens and the rest of the icon library have clean borders.'),
 ('camp','relic','DRESSED FOR THE HARVEST','Character selection now joins the Halloween event. Kael brings his pumpkin club; Vesper wears her witch hat. All five survivors have seasonal portraits. Turn Hollow Harvest off to restore their original looks. Character buttons now share a baseline.'),
 ('reaper','relic','POWER WITHOUT THE PROC PILEUP','Repeated effect relics strengthen one shared trigger instead of creating duplicate triggers. Status explosions cannot recursively trigger themselves. Critical cooldown reductions retain their cooldown; extra volleys respect the twelve-projectile ceiling.'),
]

def prepare():
 notes=NATIVE/'scripts/patch_notes.gd'
 old=notes.read_text(encoding='utf-8-sig')
 history_path=NATIVE/'assets/patch-history.json'
 history=json.loads(history_path.read_text(encoding='utf-8-sig'))
 previous=re.search(r'const VERSION="([^"]+)"',old).group(1)
 if previous!=VERSION and not any(r['version']==previous for r in history):
  data=json.loads(re.search(r'const ENTRIES=(\[.*?\])\s*static func',old,re.S).group(1))
  history.insert(0,dict(version=previous,title=re.search(r'const TITLE="([^"]+)"',old).group(1),entries=data))
 bosses={'THE THORN CROWN':'thorn','BASALT BEHEMOTH':'basalt','THE PALE HUNT':'hunt','THE AURORA MAW':'aurora','THE MERIDIAN WARDEN':'warden','THE BLOOM BELOW':'bloom'}
 for release in history:
  for item in release['entries']:
   if item['title'] in bosses:item.update(icon=bosses[item['title']],category='boss')
 history_path.write_text(json.dumps(history,ensure_ascii=False,indent=2),encoding='utf-8')
 data=[dict(icon=i,category=c,title=t,body=b) for i,c,t,b in entries]
 notes.write_text('extends RefCounted\n## Player-facing changes only.\nconst VERSION="'+VERSION+'"\nconst TITLE="'+TITLE+'"\nconst ENTRIES='+json.dumps(data,ensure_ascii=False,indent=1)+'\nstatic func releases():\n\tvar all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]\n\tall.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))\n\treturn all\n',encoding='utf-8')
 (NATIVE/f'RELEASE-{VERSION}.md').write_text('# Extinction Protocol '+VERSION+' — '+TITLE+'\n\n'+'\n\n'.join('## '+t+'\n\n'+b for _,_,t,b in entries),encoding='utf-8')
 for name in ['project.godot','export_presets.cfg','scripts/daily_challenge.gd','scripts/expedition.gd']:
  p=NATIVE/name;p.write_text(p.read_text(encoding='utf-8-sig').replace('0.10.0',VERSION),encoding='utf-8')
 render(data)

def render(data):
 width=1400
 fonts=NATIVE/'assets/fonts'
 title=ImageFont.truetype(str(fonts/'Cinzel.ttf'),30)
 heading=ImageFont.truetype(str(fonts/'Cinzel.ttf'),70)
 body=ImageFont.truetype(str(fonts/'SourceSans3.ttf'),27)
 small=ImageFont.truetype(str(fonts/'SourceSans3.ttf'),20)
 body.set_variation_by_axes([500])
 small.set_variation_by_axes([500])
 measure=ImageDraw.Draw(Image.new('RGB',(width,50)))
 def wrap(text,font,limit):
  lines=[];line=''
  for word in text.split():
   next_line=(line+' '+word).strip()
   if line and measure.textlength(next_line,font=font)>limit:lines.append(line);line=word
   else:line=next_line
  if line:lines.append(line)
  return lines
 blocks=[]
 for entry in data:
  lines=wrap(entry['body'],body,1060);titles=wrap(entry['title'],title,1060)
  blocks.append((entry,titles,lines,max(180,65+len(titles)*42+len(lines)*36)))
 height=590+sum(b[3]+20 for b in blocks)+90
 image=Image.new('RGB',(width,height),'#0b1114')
 cover=ImageOps.fit(Image.open(NATIVE/'assets/hollow-harvest-menu-v1.png').convert('RGB'),(width,490))
 cover=Image.blend(cover,Image.new('RGB',cover.size,'#071215'),.40);image.paste(cover,(0,0))
 draw=ImageDraw.Draw(image)
 draw.rectangle((0,0,width,8),fill='#b68943')
 draw.text((65,65),'EXTINCTION PROTOCOL',font=title,fill='#e1c68e')
 draw.text((65,130),'FORTUNE',font=heading,fill='#efdbaf')
 draw.text((65,220),'AND FANG',font=heading,fill='#efdbaf')
 draw.text((68,330),'0.11.0  /  HOLLOW HARVEST CONTINUES',font=title,fill='#eeb16e')
 draw.text((68,409),'One lucky find. A whole new build.',font=body,fill='#d6d7c6')
 draw.line((65,520,width-65,520),fill='#a8854d',width=2)
 y=550
 for index,(entry,titles,lines,h) in enumerate(blocks):
  draw.rectangle((55,y,width-55,y+h),fill='#132023')
  draw.rectangle((55,y,61,y+h),fill='#9d7941')
  draw.text((84,y+23),f'{index+1:02}',font=title,fill='#c99d62')
  filename=('boss-halloween-' if entry['category']=='boss' else 'weapons-' if entry['icon']=='map' else 'relics-')+('compass' if entry['icon']=='map' else entry['icon'])+'.png'
  icon=Image.open(NATIVE/'assets/clean-icons'/filename).convert('RGBA');icon.thumbnail((115,115))
  image.paste(icon,(91+(115-icon.width)//2,y+76),icon)
  cursor=y+23
  for line in titles:draw.text((255,cursor),line,font=title,fill='#e3c68e');cursor+=42
  cursor+=12
  for line in lines:draw.text((255,cursor),line,font=body,fill='#c6d0cd');cursor+=36
  assert cursor<=y+h+1,(entry['title'],cursor,y+h)
  y+=h+20
 draw.text((65,height-55),'FREE HOBBY PLAYTEST / ORIGINAL ART + AI-ASSISTED DEVELOPMENT',font=small,fill='#8b9c92')
 output=ROOT/'dist'/f'Extinction-Protocol-{VERSION}-Patch-Notes.png'
 output.parent.mkdir(exist_ok=True);image.save(output)
 print('Local patch artwork:',output,image.size)
if __name__=='__main__':prepare()
