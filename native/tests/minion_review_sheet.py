from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
ids = ['thorn', 'basalt', 'hunt', 'aurora', 'warden', 'bloom']
names = ['TRICERATOPS', 'TYRANNOSAURUS REX', 'CRYOLOPHOSAURUS', 'YUTYRANNUS', 'THERIZINOSAURUS', 'SPINOSAURUS']
frames = [0, 1, 2, 4, 5]
sheet = Image.new('RGB', (1500, 1200), '#172323')
draw = ImageDraw.Draw(sheet)
font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 18)
for row, (identity, name) in enumerate(zip(ids, names)):
    draw.text((16, row * 200 + 6), name, fill='#e3d6b3', font=font)
    for col, frame in enumerate(frames):
        path = root / 'assets/minions-individual-runtime' / f'{identity}-{frame}.png'
        if not path.exists():
            continue
        sprite = Image.open(path).convert('RGBA')
        sprite.thumbnail((280, 150), Image.Resampling.LANCZOS)
        sheet.paste(sprite, (col * 300 + (300-sprite.width)//2, row * 200 + 34 + (150-sprite.height)//2), sprite)
        draw.text((col * 300 + 18, row * 200 + 178), ['Idle', 'Walk A', 'Walk B', 'Attack A', 'Attack B'][col], fill='#b6d0c6', font=font)
out = root / 'build/minion-remake-review/Individual-Minions-Review-v5.png'
sheet.save(out)
print(out)
