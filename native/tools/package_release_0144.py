"""Package the isolated, verified Windows Meteor update."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'native/build/release-0.14.4-artifacts'
OUT.mkdir(parents=True, exist_ok=True)
exe = ROOT / 'native/build/meteor-release-work/native/build/release-0.14.4/Extinction Protocol.exe'
notes = (ROOT / 'native/RELEASE-0.14.4.md').read_text(encoding='utf-8')
archive = OUT / 'Extinction-Protocol-Windows-0.14.4.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    z.write(exe, exe.name)
    z.writestr('README.txt', 'Extinction Protocol 0.14.4\nExtract the ZIP and run Extinction Protocol.exe.\n\n' + notes)
    z.writestr('RELEASE-0.14.4.md', notes)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert len(z.namelist()) == 3
(OUT / 'release-body.md').write_text(notes, encoding='utf-8')
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
(OUT / 'SHA256SUMS.txt').write_text(f'{digest}  {archive.name}\n', encoding='utf-8')
print(f'{archive}\n{archive.stat().st_size} bytes\nSHA256 {digest}')
