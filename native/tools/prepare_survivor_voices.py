"""Standardize Voss/Vesper recordings and copy unchanged clips into Godot."""
from pathlib import Path
import hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[2]
BANK=ROOT/'native/assets/voices'
events={'Dead':'death','boss killed':'boss_killed','boss spawn':'boss_spawn','chosen in menu':'chosen','hurt':'hurt','level up':'level_up','low hp':'low_hp'}
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
registry={'kael':{'chosen':3,'boss_spawn':3,'boss_killed':2,'death':2,'hurt':3,'level_up':3,'low_hp':2}}
for hero in ['Voss','Vesper']:
 source=ROOT/'Voicelines'/hero
 target=BANK/hero.lower();target.mkdir(parents=True,exist_ok=True)
 moves=[];records=[];counts={}
 for folder in sorted(source.iterdir()):
  if not folder.is_dir():continue
  label=re.sub(r'^'+hero+r'\s+','',folder.name,flags=re.I)
  assert label in events,folder
  event=events[label]
  def order(p):
   m=re.search(r'(\d+)$',p.stem)
   return (int(m.group(1)) if m else 999999,p.name)
  files=sorted(folder.glob('*.mp3'),key=order);counts[event]=len(files)
  for index,old in enumerate(files,1):
   name=f'{hero.lower()}_{event}_{index}.mp3';new=folder/name;runtime=target/name
   assert new.resolve().is_relative_to(ROOT.resolve())
   assert old==new or not new.exists(),new
   assert not runtime.exists() or digest(runtime)==digest(old),runtime
   moves.append((old,new,runtime,digest(old)))
   records.append(dict(original=str(old.relative_to(ROOT)),source=str(new.relative_to(ROOT)),runtime=str(runtime.relative_to(ROOT)),sha256=digest(old)))
 assert len(counts)==7 and all(counts.values()),(hero,counts)
 for old,new,runtime,checksum in moves:
  if old!=new:old.rename(new)
  if not runtime.exists():shutil.copy2(new,runtime)
  assert digest(new)==checksum and digest(runtime)==checksum
 audit=target/'rename-manifest.json'
 if not audit.exists():audit.write_text(json.dumps(records,indent=2),encoding='utf-8')
 registry[hero.lower()]=counts
 print(hero,sum(counts.values()),'recordings standardized/copied and SHA-256 verified',counts)
(BANK/'manifest.json').write_text(json.dumps(registry,indent=2),encoding='utf-8')
