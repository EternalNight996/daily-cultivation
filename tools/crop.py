
from PIL import Image
for name in ["bg_chang@3x.jpg", "bg_you@3x.jpg"]:
    im = Image.open(r"F:\MyApp\eternal\DailyCultivation\assets\art\01-backgrounds\\" + name).convert("RGB")
    im.thumbnail((380, 820))
    im.save(r"F:\MyApp\eternal\DailyCultivation\prototype\screens\_" + name.split("@")[0] + ".jpg", quality=88)
print("ok")
