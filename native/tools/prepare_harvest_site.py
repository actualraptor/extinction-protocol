"""Prepare an honest next-update preview; live download still resolves latest published release."""
from pathlib import Path
from PIL import Image
import shutil
root=Path(__file__).resolve().parents[2]
assets=root/'docs/assets'
picture=Image.open(root/'native/assets/hollow-harvest-menu-v1.png').convert('RGB')
picture.thumbnail((1400,900));picture.save(assets/'hollow-harvest.webp',quality=88)
shutil.copy2(root/'dist/Extinction-Protocol-0.10.0-Patch-Notes.png',assets/'patch-notes-0.10.0.png')
page=root/'docs/index.html';source=page.read_text(encoding='utf-8')
block='''<section id="hollow-harvest" class="daily section"><div><p class="eyebrow">NEXT UPDATE / 0.10.0 PREVIEW</p><h2>The Hollow Harvest</h2><img src="assets/hollow-harvest.webp" alt="Painted Halloween concept art of a pumpkin-hearted skeletal dinosaur in a haunted prehistoric jungle" style="width:100%;height:auto;margin-top:24px"></div><div><p>Ancient bones. Borrowed souls. One more night.</p><p>A haunted menu, seasonal survivor and monster skins, nine spooky soundtrack loops, and Kael's new voice lines. Halloween is on by default, with an opt-out in Settings.</p><p>Shorter routes lead to guarded reliquaries and weapon forges. Six bosses have distinct attack sequences. Restored weapon tags and one Banish per run help shape your build.</p><p>Prepared for the next playtest. Downloads below always open the latest published GitHub release.</p><a class="button secondary" href="assets/patch-notes-0.10.0.png" target="_blank" rel="noopener">View patch-note image ↗</a></div></section>'''
if 'id="hollow-harvest"' not in source:source=source.replace('<section id="dispatch"',block+'\n<section id="dispatch"')
page.write_text(source,encoding='utf-8')
print('Prepared website preview. Published release links unchanged.')
