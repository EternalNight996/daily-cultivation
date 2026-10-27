
import os, glob
from PIL import Image, ImageDraw

root = r"F:\MyApp\eternal\DailyCultivation\assets"
files = [f for f in glob.glob(os.path.join(root, "*.png")) if os.path.getmtime(f) > 1759900000]
files.sort(key=os.path.getmtime)
cell_w, cell_h = 330, 460
cols = 3
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols*cell_w, rows*cell_h), (16, 18, 20))
d = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    im = Image.open(f).convert("RGB")
    w, h = im.size
    im.thumbnail((cell_w-24, cell_h-72))
    x = (i % cols) * cell_w
    y = (i // cols) * cell_h
    sheet.paste(im, (x + (cell_w - im.width)//2, y + 36))
    d.text((x + 8, y + 8), f"{i}: {os.path.basename(f)[:30]}", fill=(230, 226, 214))
    d.text((x + 8, y + cell_h - 26), f"{w}x{h}", fill=(150, 156, 150))
out = os.path.join(root, "new-sheet.png")
sheet.save(out)
print(out, len(files))
