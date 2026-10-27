
import os
from PIL import Image

ART = r"F:\MyApp\eternal\DailyCultivation\assets\art\01-backgrounds"
names = ["bg_zi@3x.jpg", "bg_mao@3x.jpg", "bg_wu@3x.jpg", "bg_you@3x.jpg"]
crops = []
CW, CH = 420, 420
sheet = Image.new("RGB", (CW*4, CH), (0,0,0))
for i, n in enumerate(names):
    im = Image.open(os.path.join(ART, n)).convert("RGB")
    w, h = im.size
    im = im.crop((w-CW, h-CH, w, h)).resize((CW, CH))
    sheet.paste(im, (i*CW, 0))
sheet.save(r"F:\MyApp\eternal\DailyCultivation\assets\art\_corner-check.png")
print("ok")
