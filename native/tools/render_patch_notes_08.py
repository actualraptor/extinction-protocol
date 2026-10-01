from pathlib import Path
from PIL import Image
import re,html,json
root=Path.cwd();out=root/'dist/patch-notes-0.8';assets=root/'native/assets'
notes=(root/'native/RELEASE-0.8.md').read_text(encoding='utf-8-sig')
def sprite(file,col,row,cols,rows,size=96):
 return f'<span class="sprite" style="width:{size}px;height:{size}px;background-image:url(\'{(assets/file).as_uri()}\');background-size:{cols*100}% {rows*100}%;background-position:{col/(cols-1)*100 if cols>1 else 0}% {row/(rows-1)*100 if rows>1 else 0}%"></span>'
def weapon(i,size=96):return sprite('icons-weapons-06.png',i%5,i//5,5,5,size)
def relic(i,size=96):return sprite('icons-relics-06.png',i%6,i//6,6,5,size)
def thorn(i=0,size=96):return sprite('thorns-breakables-08.png',i%2,i//2,2,2,size)
def hero(i):
 n=['mara','kael','vesper','iona','orin'][i];x,y,w,h=json.loads((assets/'walk-regions.json').read_text())[i][0];sc=145/h
 return f'<span class="portrait" style="width:{w*sc}px;height:145px;background-image:url(\'{(assets/(n+"-walk.png")).as_uri()}\');background-size:{1448*sc}px {1086*sc}px;background-position:{-x*sc}px {-y*sc}px"></span>'
icons={'MARA VOSS':hero(0),'KAEL':hero(1),'VESPER':hero(2),'IONA':hero(3),'ORIN':hero(4),'STORMBINDER':weapon(4),'EXTINCTION MORTAR':weapon(7),'IRONBRIAR — NEW WEAPON':thorn(size=130),'HARDENED SPINES — NEW AUGMENT':thorn(),'QUICK RETORT — NEW AUGMENT':thorn(),'IRONBRIAR BUILD':hero(1),'IRONBRIAR KING':thorn(size=125),'POST-BOSS PRESSURE':relic(26),'EXTINCTION ENGINE — TIMED DEFEAT':sprite('characters-v2.png',2,2,3,3,150)}
def inline(t):
 t=html.escape(t)
 t=re.sub(r'\*\*(.+?)\*\*',r'<strong>\1</strong>',t)
 t=re.sub(r'\[([^]]+)\]\(([^)]+)\)',r'<a href="\2">\1</a>',t)
 return t
sections=re.split(r'^## ',notes,flags=re.M)[1:]
sections.append('UI FINISH — 0.8.1\n\n'+(root/'native/RELEASE-0.8.1.md').read_text(encoding='utf-8-sig').split('\n\n',1)[1].split('\n\nValidation:')[0])
content=[]
for si,s in enumerate(sections):
 title,body=s.split('\n',1)
 if title=='DESIGN REFERENCES':continue
 parts=[];ls=body.strip().splitlines();i=0;card=False
 while i<len(ls):
  line=ls[i].strip()
  if not line:i+=1;continue
  if line.startswith('**') and line.endswith('**'):
   if card:parts.append('</div></article>')
   name=line[2:-2];pic=icons.get(name,'')
   parts.append('<article class="change"><div class="art">'+pic+'</div><div class="change-copy"><h3>'+html.escape(name)+'</h3>');card=True;i+=1;continue
  if line.startswith('- '):
   parts.append('<ul>')
   while i<len(ls) and ls[i].strip().startswith('- '):parts.append('<li>'+inline(ls[i].strip()[2:])+'</li>');i+=1
   parts.append('</ul>');continue
  if line.startswith('|'):
   rows=[]
   while i<len(ls) and ls[i].strip().startswith('|'):
    cells=[x.strip() for x in ls[i].strip().strip('|').split('|')]
    if not all(re.fullmatch('[-:]+',x) for x in cells):rows.append(cells)
    i+=1
   parts.append('<table><thead><tr>'+''.join('<th>'+inline(c)+'</th>' for c in rows[0])+'</tr></thead><tbody>')
   for row in rows[1:]:parts.append('<tr>'+''.join('<td>'+inline(c)+'</td>' for c in row)+'</tr>')
   parts.append('</tbody></table>');continue
  parts.append('<p>'+inline(line)+'</p>');i+=1
 if card:parts.append('</div></article>')
 banner=''
 if title=='BREAKABLES':banner='<div class="art-strip">'+''.join(thorn(j,155) for j in [1,2,3])+'<div><small>SCAVENGE THE ECOSYSTEM</small><b>BREAK. COLLECT. SURVIVE.</b></div></div>'
 if title=='EVOLUTIONS':banner='<div class="art-strip union">'+weapon(4,110)+'<span>+</span>'+weapon(2,110)+'<span>→</span>'+weapon(16,140)+'<div><small>MAX ONE WEAPON. FIND ITS PARTNER.</small><b>TWO BECOME ONE.</b></div></div>'
 if title=='UI & AUDIO':banner=f'<div class="screen"><img src="{(root/"native/build/summary-08.png").as_uri()}"><span>THE NEW EXPEDITION SCOREBOARD</span></div>'
 content.append(f'<section><header><span>{len(content)+1:02}</span><h2>{html.escape(title)}</h2><em>0.8</em></header><div class="section-body">{banner}{"".join(parts)}</div></section>')
css='''
*{box-sizing:border-box}html,body{margin:0;background:#0b1118;color:#bfc8d0;font-family:"Segoe UI",Arial,sans-serif}body{width:1800px;font-size:25px;line-height:1.52}main{width:1512px;margin:auto}strong{color:#f0e4ca;font-weight:650}a{color:#b4cbd8}.hero{height:720px;position:relative;overflow:hidden;background:radial-gradient(ellipse at 75% 40%,#522b1b 0%,#15212a 43%,#090e14 85%);border-top:8px solid #a64833;border-bottom:1px solid #b18c50}.hero:after{content:"";position:absolute;inset:0;background:linear-gradient(90deg,#090e14 1%,transparent 80%),linear-gradient(0deg,#090e14,transparent 30%);pointer-events:none}.hero-art{position:absolute;right:100px;top:32px;transform:rotate(-10deg);filter:drop-shadow(0 0 75px #d96f3445)}.hero-copy{position:relative;z-index:1;width:1512px;margin:auto;padding-top:80px}.eyebrow{font-size:22px;letter-spacing:8px;color:#bb9e71}.version{font:700 145px/1 Georgia,serif;color:#ead3a2;letter-spacing:-6px;margin:38px 0 0}.hero h1{font:500 76px/1.15 Georgia,serif;letter-spacing:3px;margin:10px 0 20px;color:#fff0d1}.hero p{font-size:27px;width:720px;color:#aab5c0}.hero .rule{width:115px;height:4px;background:#ba6846;margin:28px 0}.meta{font-size:19px;letter-spacing:4px;color:#798b99}.chips{display:flex;gap:24px;padding:38px 0;border-bottom:1px solid #34414b;margin-bottom:56px}.chip{flex:1;padding:12px 26px;border-left:3px solid #ba6846}.chip b{display:block;color:#e6d3ad;font:42px Georgia,serif}.chip span{font-size:17px;letter-spacing:3px;color:#8594a0}section{margin:0 0 55px;background:linear-gradient(110deg,#151f29,#111a23);box-shadow:0 10px 25px #0003}section>header{display:flex;align-items:center;gap:24px;padding:24px 37px;background:linear-gradient(90deg,#843e2e,#4a2925 48%,#20232b);border-top:1px solid #c27048;border-bottom:1px solid #0008}header>span{color:#c08366;font:28px Georgia}h2{font:500 37px Georgia,serif;letter-spacing:4px;margin:0;color:#eee1c9}header em{margin-left:auto;font:italic 25px Georgia;color:#ae8673}.section-body{padding:32px 48px 40px}.section-body>ul{margin:8px 0}p{margin:0 0 20px}ul{padding:0;margin:14px 0 0;list-style:none}li{position:relative;padding-left:25px;margin:10px 0}li:before{content:"";width:6px;height:6px;background:#bf7b54;position:absolute;left:0;top:16px;transform:rotate(45deg)}.change{display:flex;gap:30px;padding:25px 0;border-bottom:1px solid #ffffff0c}.change:last-child{border:0;padding-bottom:0}.art{width:150px;flex-shrink:0;display:flex;align-items:flex-start;justify-content:center;padding-top:5px}.sprite,.portrait{display:inline-block;background-repeat:no-repeat;flex-shrink:0;filter:drop-shadow(0 6px 8px #0007)}.change-copy{flex:1;min-width:0}h3{font-size:28px;line-height:1.3;letter-spacing:2px;color:#e4e5dd;margin:5px 0 12px;font-weight:600}.change ul{margin:0}table{width:100%;border-collapse:collapse;font-size:23px;margin:26px 0}th{background:#0b141e;color:#b9a785;text-align:left;font-size:18px;text-transform:uppercase;letter-spacing:2px;padding:18px 20px}td{padding:17px 20px;border-bottom:1px solid #ffffff09}tr:nth-child(even){background:#ffffff03}td:first-child{color:#e0d7bf}td:last-child{white-space:nowrap}.art-strip{display:flex;align-items:center;gap:24px;margin:0 0 30px;padding:20px;background:#09121b;border:1px solid #34414b}.art-strip b{display:block;color:#dec394;font:30px Georgia;margin:10px 0}.art-strip small{font-size:16px;color:#7f929e;letter-spacing:2px}.union>span:not(.sprite){font-size:38px;color:#b39667}.screen{margin-bottom:35px;border:1px solid #42515c}.screen img{display:block;width:100%}.screen>span{display:block;padding:15px 22px;font-size:17px;letter-spacing:3px;color:#b4a280;background:#0b131a}.footer{padding:10px 0 60px;text-align:center;color:#647784;font-size:19px}.footer b{display:block;color:#a58b60;letter-spacing:6px;font-size:20px;margin-bottom:20px}.footer p{margin:5px}.end-rule{height:2px;width:160px;background:#95563c;margin:35px auto}
'''
heroart=sprite('characters-v2.png',2,2,3,3,670)
doc=f'''<!doctype html><html lang="en"><meta charset="utf-8"><title>Extinction Protocol 0.8 — Full patch notes</title><style>{css}</style><body><div class="hero"><div class="hero-art">{heroart}</div><div class="hero-copy"><div class="eyebrow">EXTINCTION PROTOCOL</div><div class="version">0.8</div><h1>IRON &amp; THUNDER</h1><div class="rule"></div><p>Armor becomes a weapon.<br>The world stops waiting.</p><div class="meta">GAMEPLAY UPDATE + 0.8.1 UI FINISH · SEPTEMBER 30, 2026</div></div></div><main><div class="chips"><div class="chip"><b>23 + 6</b><span>BASE WEAPONS + UNIONS</span></div><div class="chip"><b>14</b><span>ARCHIVE RESEARCH TRACKS</span></div><div class="chip"><b>29</b><span>NEW ORIGINAL SOUNDS</span></div><div class="chip"><b>5</b><span>SURVIVOR LEVEL TRAITS</span></div></div>{''.join(content)}<div class="footer"><div class="end-rule"></div><b>EXTINCTION PROTOCOL</b><p>0.8 · IRON &amp; THUNDER · FULL UPDATE NOTES</p><p>Original game artwork. Editorial layout inspired by Dota 2 patch pages.</p><p>Gameplay references: Vampire Survivors and Megabonk. No reference-game assets or audio imported.</p></div></main></body></html>'''
(out/'patch-notes.html').write_text(doc,encoding='utf-8')
print('HTML created:',out/'patch-notes.html')

