from pathlib import Path
import hashlib
import zipfile

native = Path(__file__).resolve().parents[1]
out = native / 'build/release-0.14.3-artifacts'
out.mkdir(parents=True, exist_ok=True)
exe = native / 'build/release-0.14.3/Extinction Protocol.exe'
notes = (native / 'RELEASE-0.14.3.md').read_text(encoding='utf-8')
archive = out / 'Extinction-Protocol-Windows-0.14.3.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    z.write(exe, exe.name)
    z.writestr('README.txt', 'Extract all files and run Extinction Protocol.exe.\n\n'+notes)
    z.writestr('RELEASE-0.14.3.md', notes)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert set(z.namelist()) == {'Extinction Protocol.exe', 'README.txt', 'RELEASE-0.14.3.md'}
(out / 'SHA256SUMS.txt').write_text(hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest()+'  '+archive.name+'\n', encoding='utf-8')
(out / 'release-body.md').write_text(notes, encoding='utf-8')
print(archive)
