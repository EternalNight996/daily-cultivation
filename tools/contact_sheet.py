
import os, glob
from PIL import Image, ImageDraw

root = r"F:\MyApp\eternal\DailyCultivation\assets"
files = [f for f in glob.glob(os.path.join(root, "*.png"))]
files.sort()
cell_w, cell_h = 300, 420
cols = 4
rows = (len(files) + cols - 1) // cols
sheet = Image.new("RGB", (cols*cell_w, rows*cell_h), (18, 20, 22))
draw = ImageDraw.Draw(sheet)
for i, f in enumerate(files):
    im = Image.open(f).convert("RGB")
    w, h = im.size
    im.thumbnail((cell_w-24, cell_h-70))
    x = (i % cols) * cell_w
    y = (i // cols) * cell_h
    sheet.paste(im, (x + (cell_w - im.width)//2, y + 34))
    label = f"{i}: {os.path.basename(f)[:26]}"
    draw.text((x + 10, y + 8), label, fill=(230, 226, 214))
    draw.text((x + 10, y + cell_h - 26), f"{w}x{h}", fill=(150, 156, 150))
out = os.path.join(root, "contact-sheet.png")
sheet.save(out)
print(out, len(files))
