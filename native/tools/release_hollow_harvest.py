"""Prepare local player-facing release notes and a shareable PNG. Never publishes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json, re, textwrap
ROOT=Path(__file__).resolve().parents[2]
NATIVE=ROOT/'native'
VERSION='0.10.0'
TITLE='The Hollow Harvest'
entries=[
 ('camp','relic','HALLOWEEN HAS ARRIVED','Hollow Harvest is on by default. A haunted main menu, witch-hatted Vesper, pumpkin-club Kael and 22 painted enemy skins bring the season to every expedition. Turn the theme off in Settings to restore the original look and music.'),
 ('clock','relic','A HAUNTED SOUNDTRACK','Nine original chip-fantasy tracks give each map and biome its own spooky melody. Kael\'s pumpkin club lands with a new crunchy smash.'),
 ('club','weapon','KAEL FINDS HIS VOICE','Kael speaks when selected, when bosses arrive or fall, and when he dies. Hurt, level-up and low-health lines use chances and cooldowns. Voice lines never overlap, and music softens while he speaks.'),
 ('map','relic','LESS TRAVEL. MORE TROUBLE.','Map boundaries shrink by 20%. Authored routes shorten by 25%. Early supplies and discoveries are closer. Guarded Cursed Reliquaries award chests; Ancient Forges improve your strongest unfinished weapon, or award 40 amber to a complete arsenal.'),
 ('thorns','weapon','THE THORN CROWN','Locks a horn charge before rushing through its lane. Step aside during the windup. Alternates charges with a staggered thorn fan; its second phase adds a close-range horn sweep.'),
 ('mortar','weapon','BASALT BEHEMOTH','Stomps out sequential fissures and throws arcing volcanic rocks. Read the cracks and landing markers. Molten armor adds another rock in phase two.'),
 ('frost','weapon','THE PALE HUNT','Locks a landing point, leaps high, then crashes down. Periodically calls a small hunting pack. Summoned hunters are capped so the pack cannot grow forever.'),
 ('stasis','weapon','THE AURORA MAW','Fades away and reforms at a marked position, releasing spectral projectiles. Alternates this with a frost-breath cone. Flank the committed breath to attack safely.'),
 ('orbital','weapon','THE MERIDIAN WARDEN','Creates breakable lenses that aim crossing beams. Destroy a lens to cancel its beam and expose the Warden to 25% more damage for 2.5 seconds.'),
 ('miasma','weapon','THE BLOOM BELOW','Lobs spore pods that hatch if left alive, then releases a ring of slow spores. Destroy pods to deny the brood and expose the boss to 25% more damage for 2.5 seconds. The Extinction Engine keeps its meteor, fire-lane and anchor mechanics.'),
 ('lightning','weapon','READ AND SHAPE YOUR BUILD','Upgrade cards once again show weapon types such as Spell, Projectile, Chain and Melee. One Banish per normal run removes an unwanted upgrade from future offers without spending a reroll. Daily remains pure RNG.'),
 ('chest','relic','DISCOVERIES THAT PAY OFF','Finding a new discovery grants 20 amber and heals up to 12% maximum health, capped at 18. Suggested discoveries appear before a run; click one to track it. Ironbriar, Ballistics and Riftcraft can also unlock through damage dealt with their matching weapons. Existing kill milestones still work.'),
]
def prepare():
 notes=NATIVE/'scripts/patch_notes.gd'
 old=notes.read_text(encoding='utf-8-sig')
 history_path=NATIVE/'assets/patch-history.json'
 history=json.loads(history_path.read_text(encoding='utf-8-sig'))
 previous=re.search(r'const VERSION="([^"]+)"',old).group(1)
 if previous!=VERSION and not any(r['version']==previous for r in history):
  old_entries=json.loads(re.search(r'const ENTRIES=(\[.*?\])\s*static func',old,re.S).group(1))
  history.insert(0,{'version':previous,'title':re.search(r'const TITLE="([^"]+)"',old).group(1),'entries':old_entries})
 history_path.write_text(json.dumps(history,ensure_ascii=False,indent=2),encoding='utf-8')
 data=[dict(icon=i,category=c,title=t,body=b) for i,c,t,b in entries]
 notes.write_text('extends RefCounted\n## Player-facing changes only.\nconst VERSION="'+VERSION+'"\nconst TITLE="'+TITLE+'"\nconst ENTRIES='+json.dumps(data,ensure_ascii=False,indent=1)+'\nstatic func releases():\n\tvar all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]\n\tall.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))\n\treturn all\n',encoding='utf-8')
 (NATIVE/f'RELEASE-{VERSION}.md').write_text('# Extinction Protocol '+VERSION+' — '+TITLE+'\n\n'+'\n\n'.join('## '+t+'\n\n'+b for _,_,t,b in entries),encoding='utf-8')
 for path in [NATIVE/'project.godot',NATIVE/'export_presets.cfg']:
  source=path.read_text(encoding='utf-8-sig')
  source=source.replace('0.9.2',VERSION)
  path.write_text(source,encoding='utf-8')
 p=NATIVE/'scripts/daily_challenge.gd';p.write_text(p.read_text(encoding='utf-8').replace('RULESET="0.9.1"','RULESET="'+VERSION+'"'),encoding='utf-8')
 p=NATIVE/'scripts/expedition.gd';p.write_text(p.read_text(encoding='utf-8').replace('"version":"native-0.9.1"','"version":"native-'+VERSION+'","halloween":halloween'),encoding='utf-8')
 render(data)
def render(data):
 W=1400
 title_font=ImageFont.truetype(str(NATIVE/'assets/fonts/Cinzel.ttf'),32)
 body_font=ImageFont.truetype(str(NATIVE/'assets/fonts/SourceSans3.ttf'),27)
 headline=ImageFont.truetype(str(NATIVE/'assets/fonts/Cinzel.ttf'),72)
 probe=ImageDraw.Draw(Image.new('RGB',(W,100)))
 def wrap(text,font,width):
  lines=[];line=''
  for word in text.split():
   candidate=(line+' '+word).strip()
   if probe.textlength(candidate,font=font)>width and line:lines.append(line);line=word
   else:line=candidate
  if line:lines.append(line)
  return lines
 blocks=[]
 for entry in data:
  titles=wrap(entry['title'],title_font,1070)
  lines=wrap(entry['body'],body_font,1070)
  blocks.append((entry,titles,lines,max(190,70+len(titles)*43+len(lines)*37)))
 H=620+sum(b[3]+20 for b in blocks)+80
 canvas=Image.new('RGB',(W,H),'#0b1215');draw=ImageDraw.Draw(canvas)
 cover=Image.open(NATIVE/'assets/hollow-harvest-menu-v1.png').convert('RGB')
 from PIL import ImageOps
 cover=ImageOps.fit(cover,(W,520))
 cover=Image.blend(cover,Image.new('RGB',cover.size,'#081017'),.35)
 canvas.paste(cover,(0,0));draw=ImageDraw.Draw(canvas)
 draw.rectangle((0,0,W,8),fill='#c07933')
 draw.text((65,65),'EXTINCTION PROTOCOL',font=title_font,fill='#dfc491')
 draw.text((65,128),'THE HOLLOW',font=headline,fill='#f2dfb6',stroke_width=1)
 draw.text((65,212),'HARVEST',font=headline,fill='#f2dfb6',stroke_width=1)
 draw.text((67,330),'0.10.0  /  HALLOWEEN UPDATE',font=title_font,fill='#efa865')
 draw.text((67,413),'Ancient bones. Borrowed souls. One more night.',font=body_font,fill='#ddd1b7')
 draw.line((65,550,W-65,550),fill='#b08950',width=2)
 y=595
 for index,(entry,titles,lines,height) in enumerate(blocks):
  draw.rectangle((55,y,W-55,y+height),fill='#132022')
  draw.rectangle((55,y,61,y+height),fill='#957547')
  draw.text((82,y+24),f'{index+1:02}',font=title_font,fill='#c79251')
  # Existing painted weapon/relic icons remain consistent with in-game notes.
  category=entry['category'];name=entry['icon']
  if category=='weapon':
   weapon_ids=['revolver','club','frost','fire','lightning','shotgun','orbital','mortar','spear','pyre','winter','miasma','dread','aegis','stasis','thunderstorm','whiteout','supernova','lastword','earthshaker','bastion','ricochet','return','compass','tablet']
   if name=='thorns':
    sheet=Image.open(NATIVE/'assets/thorns-breakables-08.png').convert('RGBA');icon=sheet.crop((0,0,sheet.width//2,sheet.height//2));icon.thumbnail((115,115));canvas.paste(icon,(86,y+71),icon)
   if name in weapon_ids:
    k=weapon_ids.index(name);sheet=Image.open(NATIVE/'assets/icons-weapons-06.png').convert('RGBA');cw,ch=sheet.width/5,sheet.height/5
    icon=sheet.crop((int(k%5*cw),int(k//5*ch),int((k%5+1)*cw),int((k//5+1)*ch)));icon.thumbnail((115,115));canvas.paste(icon,(86,y+71),icon)
  else:
   sheet=Image.open(NATIVE/'assets/hollow-harvest-accessories.png').convert('RGBA');icon=sheet.crop((541,440,1139,1024));icon.thumbnail((100,115));canvas.paste(icon,(92,y+75),icon)
  ty=y+23
  for line in titles:draw.text((255,ty),line,font=title_font,fill='#e4c48e');ty+=43
  ty+=13
  for line in lines:draw.text((255,ty),line,font=body_font,fill='#c2d0cc');ty+=37
  y+=height+20
 draw.text((65,H-55),'FREE HOBBY PLAYTEST  /  ORIGINAL ART + AI-ASSISTED DEVELOPMENT',font=ImageFont.truetype(str(NATIVE/'assets/fonts/SourceSans3.ttf'),19),fill='#7f9997')
 output=ROOT/'dist'/f'Extinction-Protocol-{VERSION}-Patch-Notes.png';canvas.save(output)
 print('Prepared release notes:',output,canvas.size)
if __name__=='__main__':prepare()
