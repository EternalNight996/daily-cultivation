
import os
from PIL import Image, ImageDraw

ART = r"F:\MyApp\eternal\DailyCultivation\assets\art"
W, H = 1240, 1250
sheet = Image.new("RGB", (W, H), (12, 14, 16))
d = ImageDraw.Draw(sheet)

bgs = ["bg_zi@3x.jpg", "bg_mao@3x.jpg", "bg_wu@3x.jpg", "bg_you@3x.jpg"]
labels = ["ZI", "MAO", "WU", "YOU"]
tw, th = 280, 606
for i, name in enumerate(bgs):
    im = Image.open(os.path.join(ART, "01-backgrounds", name)).convert("RGB")
    im.thumbnail((tw, th))
    x = 16 + i * (tw + 12)
    sheet.paste(im, (x, 40))
    d.text((x + 4, 18), labels[i], fill=(230, 226, 214))

def tile(folder, name, size, xy, bg=(238, 236, 230)):
    im = Image.open(os.path.join(ART, folder, name)).convert("RGBA")
    im.thumbnail((size, size))
    chip = Image.new("RGBA", (size + 10, size + 10), bg + (255,))
    chip.alpha_composite(im, ((size + 10 - im.width)//2, (size + 10 - im.height)//2))
    sheet.paste(chip.convert("RGB"), xy)
    d.text((xy[0], xy[1] + size + 12), name.split("@")[0].replace(".png", ""), fill=(180, 186, 180))

# 纸
for i, n in enumerate(["paper_new@2x.jpg", "paper_worn@2x.jpg", "paper_burnt@2x.jpg"]):
    im = Image.open(os.path.join(ART, "02-paper", n)).convert("RGB").resize((150, 150))
    sheet.paste(im, (16 + i*162, 690))
    d.text((16 + i*162, 846), n.split("@")[0], fill=(180, 186, 180))

# 笔锋
brush = ["brush_start_01.png","brush_body_01.png","brush_end_01.png","brush_corner_01.png","brush_body_02.png","brush_end_02.png"]
for i, n in enumerate(brush):
    tile("03-brush", n, 100, (520 + (i%3)*150, 690 + (i//3)*150))

# 印章
tile("04-seals", "seal_he.png", 120, (520, 1010))
tile("04-seals", "seal_chi.png", 120, (680, 1010))

# 灵兽
pets = ["pet_idle_00.png","pet_cast_00.png","pet_resonate_00.png"]
for i, n in enumerate(pets):
    tile("05-pet", n, 140, (900 + i*110, 990))

sheet.convert("RGB").save(os.path.join(ART, "preview.jpg"), "JPEG", quality=88, optimize=True)
print("ok")
