"""Package already-exported binaries and the spoiler-free website. Never publishes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import hashlib, json, re, tarfile, zipfile

ROOT=Path(__file__).resolve().parents[2]
NATIVE=ROOT/'native'
OUT=NATIVE/'build/release-0.13.1-artifacts'
OUT.mkdir(parents=True,exist_ok=True)
notes=(NATIVE/'RELEASE-0.13.1.md').read_text(encoding='utf-8')
assert not re.search(r'nagash|kael dies|first rite|ritual|non.canon|skeleton assembly',notes,re.I)
readme=(NATIVE/'PRIVATE-TEST-README.md').read_text(encoding='utf-8')
windows=NATIVE/'build/release-0.13.1/Extinction Protocol.exe'
linux=NATIVE/'build/release-0.13.1-linux/Extinction Protocol.x86_64'
assert windows.exists() and linux.exists()
winzip=OUT/'Extinction-Protocol-Windows-0.13.1.zip'
with zipfile.ZipFile(winzip,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    z.write(windows,windows.name)
    z.writestr('README.txt',readme)
    z.writestr('RELEASE-0.13.1.md',notes)
with zipfile.ZipFile(winzip) as z:assert z.testzip() is None
linarchive=OUT/'Extinction-Protocol-Linux-0.13.1-UNVERIFIED.tar.gz'
with tarfile.open(linarchive,'w:gz') as tar:
    info=tar.gettarinfo(str(linux),linux.name);info.mode=0o755;info.uid=info.gid=0;info.uname=info.gname=''
    with linux.open('rb') as f:tar.addfile(info,f)
    import io
    for name,text in [('README.txt',readme),('RELEASE-0.13.1.md',notes)]:
        data=text.encode('utf-8');info=tarfile.TarInfo(name);info.size=len(data);info.mode=0o644
        tar.addfile(info,io.BytesIO(data))
store=OUT/'Extinction-Protocol-Store-Preview-0.13.1.zip'
with zipfile.ZipFile(store,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
    for p in sorted((ROOT/'docs').rglob('*')):
        if p.is_file() and p.suffix.lower() in ['.html','.css','.js','.webp','.png','.ttf','.txt','.mp4'] and not p.name.startswith(('preview-','test-')):
            z.write(p,str(p.relative_to(ROOT/'docs')))
with zipfile.ZipFile(store) as z:assert z.testzip() is None
# Shareable patch-note graphic: current ordinary gameplay only, no hidden content.
entries=json.loads(re.search(r'const ENTRIES=(\[.*?\])\s*static func',(NATIVE/'scripts/patch_notes.gd').read_text(encoding='utf-8'),re.S).group(1))
fontdir=NATIVE/'assets/fonts'
heading=ImageFont.truetype(str(fontdir/'Cinzel.ttf'),35)
body=ImageFont.truetype(str(fontdir/'SourceSans3.ttf'),30)
title=ImageFont.truetype(str(fontdir/'Cinzel.ttf'),54)
probe=ImageDraw.Draw(Image.new('RGB',(1400,100)))
def wrap(text,font,width):
    lines=[];line=''
    for word in text.split():
        proposed=(line+' '+word).strip()
        if line and probe.textlength(proposed,font=font)>width:lines.append(line);line=word
        else:line=proposed
    if line:lines.append(line)
    return lines
blocks=[(e,wrap(e['title'],heading,1210),wrap(e['body'],body,1210)) for e in entries]
height=640+sum(84+len(t)*48+len(b)*41 for e,t,b in blocks)+80
im=Image.new('RGB',(1400,height),'#0c1110')
shot=Image.open(ROOT/'docs/assets/voss-hordes-ui.webp').convert('RGB');shot.thumbnail((1400,500));im.paste(shot,((1400-shot.width)//2,0))
d=ImageDraw.Draw(im)
d.rectangle((0,500,1400,630),fill='#101713')
d.text((60,515),'0.13.1 — FRAMED',font=title,fill='#ecd8ad')
d.text((63,585),'Spoiler-free playtest notes · 6 October 2026',font=body,fill='#a6b6a0')
y=650
for e,titles,lines in blocks:
    d.line((60,y,1340,y),fill='#81613b',width=2);y+=20
    for line in titles:d.text((65,y),line,font=heading,fill='#e1c38c');y+=48
    y+=10
    for line in lines:d.text((65,y),line,font=body,fill='#bcc7b9');y+=41
    y+=54
png=OUT/'Extinction-Protocol-0.13.1-Patch-Notes.png';im.save(png)
hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(OUT.iterdir()) if p.suffix in ['.zip','.gz','.png']}
(OUT/'SHA256SUMS.txt').write_text(''.join(value+'  '+name+'\n' for name,value in hashes.items()),encoding='utf-8')
print(json.dumps({p.name:p.stat().st_size for p in sorted(OUT.iterdir())},indent=2))
