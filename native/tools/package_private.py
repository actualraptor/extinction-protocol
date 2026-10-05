"""Package allowlisted release artifacts, never profiles/logs/build fixtures."""
from pathlib import Path
import argparse,zipfile,tarfile,hashlib,shutil,re
p=argparse.ArgumentParser();p.add_argument('version');a=p.parse_args()
assert re.fullmatch(r'\d+\.\d+\.\d+',a.version)
root=Path(__file__).resolve().parents[2];native=root/'native';dist=root/'dist';v=a.version
common={
 'README.txt':native/'PRIVATE-TEST-README.md',
 'PATCH-NOTES.md':native/f'RELEASE-{v}.md',
 f'Extinction-Protocol-{v}-Patch-Notes.png':dist/f'Extinction-Protocol-{v}-Patch-Notes.png',
 'Cinzel-OFL.txt':native/'assets/fonts/Cinzel-OFL.txt',
 'SourceSans3-OFL.txt':native/'assets/fonts/SourceSans3-OFL.txt',
 'PROVENANCE.md':native/'PROVENANCE-0.8.md',
}
if (native/f'PROVENANCE-{v}.md').exists():
 common['PROVENANCE-THIS-UPDATE.md']=native/f'PROVENANCE-{v}.md'
elif (native/f'PROVENANCE-{v.split(".")[0]}.{v.split(".")[1]}.md').exists():
 common['PROVENANCE-THIS-UPDATE.md']=native/f'PROVENANCE-{v.split(".")[0]}.{v.split(".")[1]}.md'
for platform,exe in [('windows','Extinction Protocol.exe'),('linux','Extinction Protocol.x86_64')]:
 folder=native/'build'/f'release-{v}{"-linux" if platform=="linux" else ""}'
 assert (folder/exe).is_file()
 for name,source in common.items():shutil.copy2(source,folder/name)
 names=[exe]+list(common)
 if platform=='windows':
  output=dist/f'Extinction-Protocol-Windows-{v}.zip'
  with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,6) as z:
   for name in names:z.write(folder/name,'Extinction Protocol/'+name)
  with zipfile.ZipFile(output) as z:assert z.testzip() is None;assert len(z.namelist())==len(names)
 else:
  output=dist/f'Extinction-Protocol-Linux-{v}-UNVERIFIED.tar.gz'
  with tarfile.open(output,'w:gz') as t:
   for name in names:
    info=t.gettarinfo(str(folder/name),'Extinction Protocol/'+name);info.mode=0o755 if name==exe else 0o644
    with (folder/name).open('rb') as f:t.addfile(info,f)
  with tarfile.open(output) as t:assert t.getmember('Extinction Protocol/'+exe).mode==0o755;assert len(t.getmembers())==len(names)
 output.with_suffix(output.suffix+'.sha256').write_text(hashlib.sha256(output.read_bytes()).hexdigest()+'  '+output.name+'\n')
 print('Verified package:',output)
