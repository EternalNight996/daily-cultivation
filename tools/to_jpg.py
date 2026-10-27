
from PIL import Image
import os
d = r"F:\MyApp\eternal\shots-tmp2"
out = r"F:\MyApp\eternal\DailyCultivation\prototype\screens"
for name, target in [("shot-share.png","ios-share.jpg"), ("shot-resting.png","ios-resting.jpg"), ("shot-history.png","ios-history.jpg")]:
    im = Image.open(os.path.join(d, name)).convert("RGB")
    im.save(os.path.join(out, target), "JPEG", quality=86, optimize=True)
    print(target, im.size)
