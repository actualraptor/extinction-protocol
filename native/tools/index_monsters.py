"""Read alpha components to index painted walk sheets; does not modify images."""
import json
from pathlib import Path
from PIL import Image

assets = Path(__file__).resolve().parents[1] / "assets"
result = []
for name in ("monsters-04",):
    image = Image.open(assets / f"{name}.png").convert("RGBA")
    width, height = image.size
    alpha = bytearray(image.getchannel("A").tobytes())
    components = []
    for start in range(len(alpha)):
        if alpha[start] < 16:
            continue
        stack = [start]
        alpha[start] = 0
        x0 = x1 = start % width
        y0 = y1 = start // width
        count = 0
        while stack:
            pixel = stack.pop()
            x, y = pixel % width, pixel // width
            x0, x1 = min(x0, x), max(x1, x)
            y0, y1 = min(y0, y), max(y1, y)
            count += 1
            for neighbor in (pixel - width, pixel + width,
                             pixel - 1 if x else -1,
                             pixel + 1 if x < width - 1 else -1):
                if 0 <= neighbor < len(alpha) and alpha[neighbor] >= 16:
                    alpha[neighbor] = 0
                    stack.append(neighbor)
        if count > 10000:
            # Two transparent pixels preserve antialiased contour edges.
            left, top = max(0, x0 - 2), max(0, y0 - 2)
            components.append([left, top, min(width, x1 + 3) - left,
                               min(height, y1 + 3) - top])
    assert len(components) == 9, (name, len(components), components)
    components.sort(key=lambda rect: rect[1] + rect[3] / 2)
    ordered = []
    for row in range(3):
        ordered.extend(sorted(components[row * 3:row * 3 + 3], key=lambda rect: rect[0]))
    result.append(ordered)
    print(name, ordered)
(assets / "monster-regions.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
