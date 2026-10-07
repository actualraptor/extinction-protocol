"""Repackage the public 0.14.0 Windows release using an explicit player-only allowlist."""
from pathlib import Path
import hashlib,zipfile
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'native/build/release-0.14.0-artifacts'
archive=OUT/'Extinction-Protocol-Windows-0.14.0.zip'
replacement=OUT/'public-package.tmp.zip'
allowed=['Extinction Protocol.exe','Release Notes.md','Extinction-Protocol-0.14.0-Patch-Notes.png']
with zipfile.ZipFile(archive) as source,zipfile.ZipFile(replacement,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as target:
 for name in allowed:target.writestr(name,source.read(name))
 target.writestr('READ ME.txt','Extinction Protocol 0.14.0 — A World Reborn\n\nExtract the ZIP, then run Extinction Protocol.exe to play.\nExisting game progress is retained.\n\nUpdates and feedback: https://github.com/actualraptor/extinction-protocol\n')
with zipfile.ZipFile(replacement) as check:
 assert check.testzip() is None
 assert set(check.namelist())==set(allowed+['READ ME.txt'])
 assert not any(n.lower().endswith(('.bat','.cmd')) or 'profile' in n.lower() for n in check.namelist())
 print('Verified public contents:',check.namelist())
replacement.replace(archive)
lines=[]
for p in sorted(OUT.iterdir()):
 if p.name=='SHA256SUMS.txt':continue
 with p.open('rb') as f:digest=hashlib.file_digest(f,'sha256').hexdigest()
 lines.append(digest+'  '+p.name)
(OUT/'SHA256SUMS.txt').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('Updated ZIP and checksums.')
