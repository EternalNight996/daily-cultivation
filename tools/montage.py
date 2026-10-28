
from PIL import Image
import os
d = r"F:\MyApp\eternal\shots-ui"
names = [("shot.png","idle"), ("shot-onboarding.png","onboarding"), ("shot-settings.png","settings"),
         ("shot-settle.png","settle"), ("shot-resting.png","resting"), ("shot-history.png","history"),
         ("shot-share.png","share")]
cols, cw, ch = 4, 250, 540
rows = (len(names)+cols-1)//cols
sheet = Image.new("RGB", (cols*cw, rows*ch), (16,18,20))
from PIL import ImageDraw
dr = ImageDraw.Draw(sheet)
for i,(n,label) in enumerate(names):
    im = Image.open(os.path.join(d,n)).convert("RGB")
    im.thumbnail((cw-16, ch-40))
    x = (i%cols)*cw; y = (i//cols)*ch
    sheet.paste(im, (x+(cw-im.width)//2, y+30))
    dr.text((x+10, y+8), label, fill=(230,226,214))
out = r"F:\MyApp\eternal\DailyCultivation\prototype\screens\ui-states.jpg"
sheet.save(out, "JPEG", quality=88, optimize=True)
print(out, sheet.size)
