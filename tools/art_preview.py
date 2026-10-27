
import os
from PIL import Image, ImageDraw

ART = r"F:\MyApp\eternal\DailyCultivation\assets\art"
W, H = 1240, 1080
sheet = Image.new("RGB", (W, H), (12, 14, 16))
d = ImageDraw.Draw(sheet)

bgs = ["bg_zi@3x.jpg", "bg_mao@3x.jpg", "bg_wu@3x.jpg", "bg_you@3x.jpg"]
labels = ["ZI (night)", "MAO (dawn)", "WU (noon)", "YOU (dusk)"]
tw, th = 280, 606
for i, name in enumerate(bgs):
    im = Image.open(os.path.join(ART, "01-backgrounds", name)).convert("RGB")
    im.thumbnail((tw, th))
    x = 16 + i * (tw + 12)
    sheet.paste(im, (x, 44))
    d.text((x + 4, 20), labels[i], fill=(230, 226, 214))

# 下排：纸 / 笔 / 印（深底上看透明效果）
y0 = 700
papers = ["paper_new@2x.jpg", "paper_worn@2x.jpg", "paper_burnt@2x.jpg"]
for i, name in enumerate(papers):
    im = Image.open(os.path.join(ART, "02-paper", name)).convert("RGB").resize((150, 150))
    sheet.paste(im, (16 + i * 162, y0))
    d.text((16 + i * 162, y0 + 154), name.split("@")[0], fill=(180, 186, 180))

# 透明素材放到浅灰块上看
brush = ["brush_start_01.png", "brush_body_01.png", "brush_end_01.png", "brush_corner_01.png", "seal_he.png"]
for i, name in enumerate(brush):
    im = Image.open(os.path.join(ART, "03-brush" if name.startswith("brush") else "04-seals", name)).convert("RGBA")
    im.thumbnail((120, 120))
    tile = Image.new("RGBA", (130, 130), (238, 236, 230, 255))
    tile.alpha_composite(im, ((130 - im.width)//2, (130 - im.height)//2))
    sheet.paste(tile.convert("RGB"), (520 + i * 140, y0 + 6))
    d.text((520 + i * 140, y0 + 144), name.split(".")[0], fill=(180, 186, 180))

sheet.save(os.path.join(ART, "preview.png"))
print("ok")
