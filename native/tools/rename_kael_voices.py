"""Rename source/runtime clips by identical content; keep an audit manifest."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[2]
BANK=ROOT/'native/assets/voices/kael'
SOURCE=ROOT/'Voicelines/Kael'
COUNTS={'chosen':3,'boss_spawn':3,'boss_killed':2,'death':2,'hurt':3,'level_up':3,'low_hp':2}
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
manifest=BANK/'rename-manifest.json'
if manifest.exists():
 for entry in json.loads(manifest.read_text()):
  for key in ['runtime','source']:
   assert digest(ROOT/entry[key])==entry['sha256']
 print('Verified existing voice rename manifest: 18 clips')
else:
 source_files=list(SOURCE.rglob('*.mp3'))
 records=[];moves=[];imports=[]
 for event,count in COUNTS.items():
  for index in range(count):
   old=BANK/f'{event}_{index}.mp3'
   checksum=digest(old)
   matched=[p for p in source_files if digest(p)==checksum]
   assert len(matched)==1,(event,index,matched)
   name=f'kael_{event}_{index+1}.mp3'
   src=matched[0];dst=BANK/name;src_dst=src.with_name(name)
   for target in [dst,src_dst]:
    assert target.resolve().is_relative_to(ROOT.resolve())
    assert not target.exists(),target
   moves.extend([(old,dst),(src,src_dst)])
   imports.append(Path(str(old)+'.import'))
   records.append(dict(event=event,number=index+1,original_source=str(src.relative_to(ROOT)),original_runtime=str(old.relative_to(ROOT)),source=str(src_dst.relative_to(ROOT)),runtime=str(dst.relative_to(ROOT)),sha256=checksum))
 for old,new in moves:old.rename(new)
 # These metadata files reference old source paths; Godot regenerates them.
 for sidecar in imports:
  if sidecar.exists():sidecar.unlink()
 manifest.write_text(json.dumps(records,indent=2),encoding='utf-8')
 print('Renamed 18 original clips and 18 runtime copies; audio bytes unchanged')
