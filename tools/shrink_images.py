
import os, sys
from PIL import Image

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = r"F:\MyApp\eternal\DailyCultivation"

def convert(path, quality=86):
    im = Image.open(path).convert("RGB")
    out = os.path.splitext(path)[0] + ".jpg"
    im.save(out, "JPEG", quality=quality, optimize=True, progressive=True)
    os.remove(path)
    return out, os.path.getsize(out) // 1024

targets = []
for d in [os.path.join(ROOT, "prototype", "screens")]:
    for f in os.listdir(d):
        if f.lower().endswith(".png"):
            targets.append(os.path.join(d, f))

for p in targets:
    out, kb = convert(p)
    print(f"{os.path.basename(out):20s} {kb}KB")

pv = os.path.join(ROOT, "assets", "art", "preview.png")
if os.path.exists(pv):
    out, kb = convert(pv, 88)
    print(f"{os.path.basename(out):20s} {kb}KB")
