"""Prepare spoiler-free 0.13.1 release metadata. Does not publish."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[2]
NATIVE=ROOT/'native'
VERSION='0.13.1'
TITLE='Hollow Harvest: Framed'
ENTRIES=[
 dict(icon='map',category='relic',title='ONE INTEGRATED HUD',body='The illustrated bottom HUD now uses a continuous frame with bounded layout sections. The minimap, portrait, character name, health, abilities, carried items and utility buttons fit together, including at wider resolutions.'),
 dict(icon='compass',category='weapon',title='HEALTH AND EXPERIENCE, REFRAMED',body='Health and experience displays have received a fresh art pass. The level badge is integrated into the portrait section, and the experience bar sits above the abilities within the HUD frame. Item pages keep overflow accessible through the backpack.'),
 dict(icon='tablet',category='weapon',title='MATCHING MENUS AND FIELD PANELS',body='The pause menu, score panel and location timer now match your selected HUD theme. Location and countdown text are centered more clearly. The pause menu has simpler labels and fewer unnecessary actions.'),
 dict(icon='clock',category='relic',title='FIRST ITERATION — KEEP THE FEEDBACK COMING',body='The new UI remains a first iteration and will have issues. Please report clipped text, scaling problems, awkward spacing or hard-to-read markers. Existing saves and progression are retained. The website now has fresh gameplay screenshots and a short spoiler-free trailer.')]
old=(NATIVE/'scripts/patch_notes.gd').read_text(encoding='utf-8-sig')
history_path=NATIVE/'assets/patch-history.json'
history=json.loads(history_path.read_text(encoding='utf-8-sig'))
previous=re.search(r'const VERSION="([^"]+)"',old).group(1)
if previous!=VERSION and not any(e['version']==previous for e in history):
 history.insert(0,dict(version=previous,title=re.search(r'const TITLE="([^"]+)"',old).group(1),entries=json.loads(re.search(r'const ENTRIES=(\[.*?\])\s*static func',old,re.S).group(1))))
history_path.write_text(json.dumps(history,ensure_ascii=False,indent=2),encoding='utf8')
(NATIVE/'scripts/patch_notes.gd').write_text('extends RefCounted\n## Player-facing changes only; unrevealed content stays out of public notes.\nconst VERSION="'+VERSION+'"\nconst TITLE="'+TITLE+'"\nconst ENTRIES='+json.dumps(ENTRIES,ensure_ascii=False,indent=1)+'\nstatic func releases():\n\tvar all=[{"version":VERSION,"title":TITLE,"entries":ENTRIES}]\n\tall.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://assets/patch-history.json")))\n\treturn all\n',encoding='utf8')
notes='# Extinction Protocol '+VERSION+' — '+TITLE+'\n\n'+'\n\n'.join('## '+e['title']+'\n\n'+e['body'] for e in ENTRIES)+'\n\nWindows x64 has been tested. Linux x64 is available as an unverified test build.\n'
assert not re.search(r'nagash|first rite|ritual|route_07|skeleton assembly',notes,re.I)
(NATIVE/f'RELEASE-{VERSION}.md').write_text(notes,encoding='utf8')
for name in ['native/project.godot','native/export_presets.cfg','native/scripts/daily_challenge.gd','native/scripts/expedition.gd','README.md','docs/index.html','docs/site.js']:
 path=ROOT/name
 text=path.read_text(encoding='utf-8-sig').replace('0.13.0',VERSION)
 if name=='README.md':text=text.replace('Hollow Harvest: Fieldwork',TITLE)
 if name=='docs/index.html':
  text=text.replace('Hollow Harvest:<br>Fieldwork','Hollow Harvest:<br>Framed')
  text=text.replace('These preview ongoing HUD polish beyond the downloadable 0.13.1 build.','These show the polished HUD included in 0.13.1.')
  text=text.replace('site.js?v=hud-polish-20261006','site.js?v=0131-framed')
 path.write_text(text,encoding='utf8')
print('Prepared 0.13.1 metadata and spoiler-free notes')
