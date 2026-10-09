"""Build the player-only 0.14.2 archives and illustrated patch notes."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps
import hashlib, tarfile, zipfile, io

ROOT = Path(__file__).resolve().parents[2]
NATIVE = ROOT / "native"
OUT = NATIVE / "build" / "release-0.14.2-artifacts"
OUT.mkdir(parents=True, exist_ok=True)
version = "0.14.2"
notes = (NATIVE / f"RELEASE-{version}.md").read_text(encoding="utf-8")
readme = "Extinction Protocol 0.14.2\n\nExtract and run Extinction Protocol.exe.\n\n" + notes
windows = NATIVE / "build" / f"release-{version}" / "Extinction Protocol.exe"
linux = NATIVE / "build" / f"release-{version}-linux" / "Extinction Protocol.x86_64"
assert windows.is_file() and linux.is_file()

winzip = OUT / f"Extinction-Protocol-Windows-{version}.zip"
with zipfile.ZipFile(winzip, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    z.write(windows, windows.name)
    z.writestr("README.txt", readme)
    z.writestr(f"RELEASE-{version}.md", notes)
with zipfile.ZipFile(winzip) as z:
    assert z.testzip() is None
    assert set(z.namelist()) == {"Extinction Protocol.exe", "README.txt", f"RELEASE-{version}.md"}

linarchive = OUT / f"Extinction-Protocol-Linux-{version}-UNVERIFIED.tar.gz"
with tarfile.open(linarchive, "w:gz") as tar:
    info = tar.gettarinfo(str(linux), linux.name); info.mode = 0o755; info.uid = info.gid = 0; info.uname = info.gname = ""
    with linux.open("rb") as f: tar.addfile(info, f)
    for name, text in [("README.txt", readme), (f"RELEASE-{version}.md", notes)]:
        data = text.encode("utf-8"); item = tarfile.TarInfo(name); item.size = len(data); item.mode = 0o644
        tar.addfile(item, io.BytesIO(data))

# The release page uses the game art, Cinzel headings and Source Sans 3 body text.
W = 1400
heading = ImageFont.truetype(str(NATIVE / "assets/fonts/Cinzel.ttf"), 34)
body = ImageFont.truetype(str(NATIVE / "assets/fonts/SourceSans3.ttf"), 29)
title = ImageFont.truetype(str(NATIVE / "assets/fonts/Cinzel.ttf"), 58)
probe = ImageDraw.Draw(Image.new("RGB", (W, 100)))
def wrap(text, font, width):
    lines = []; line = ""
    for word in text.split():
        candidate = (line + " " + word).strip()
        if line and probe.textlength(candidate, font=font) > width: lines.append(line); line = word
        else: line = candidate
    if line: lines.append(line)
    return lines
entries = [
    ("THE DINOSAUR BOSS REWORK", "T-rex and Triceratops are finished in the public build, with rebuilt models, grounded pursuit, directional attacks, clearer spacing and creature sound."),
    ("METEOR: FIRST PASS", "Meteor has entered its first reconstructed presentation pass. Entrance motion, shell animation, fire pressure and randomized waves will continue to receive updates."),
]
blocks = [(wrap(t, heading, 1190), wrap(b, body, 1190)) for t, b in entries]
H = 610 + sum(110 + len(t) * 46 + len(b) * 39 for t, b in blocks)
canvas = Image.new("RGB", (W, H), "#0b1215")
cover = ImageOps.fit(Image.open(NATIVE / "assets/hollow-harvest-menu-v1.png").convert("RGB"), (W, 500))
canvas.paste(Image.blend(cover, Image.new("RGB", cover.size, "#081017"), .38), (0, 0))
draw = ImageDraw.Draw(canvas)
draw.rectangle((0, 500, W, 610), fill="#101713")
draw.text((62, 516), "0.14.2 — DINOSAUR BOSS REWORK", font=title, fill="#ecd8ad")
draw.text((65, 576), "Public playtest notes · 9 October 2026", font=body, fill="#a6b6a0")
y = 638
for titles, lines in blocks:
    draw.line((60, y, W - 60, y), fill="#81613b", width=2); y += 22
    for line in titles: draw.text((65, y), line, font=heading, fill="#e1c38c"); y += 46
    y += 12
    for line in lines: draw.text((65, y), line, font=body, fill="#bcc7b9"); y += 39
    y += 45
png = OUT / f"Extinction-Protocol-{version}-Patch-Notes.png"
canvas.save(png)

hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in [winzip, linarchive, png]}
(OUT / "SHA256SUMS.txt").write_text("".join(f"{h}  {name}\n" for name, h in hashes.items()), encoding="utf-8")
print({p.name: p.stat().st_size for p in [winzip, linarchive, png]})
