
from PIL import Image
import os
d = r"F:\MyApp\eternal\shots-tmp"
out = r"F:\MyApp\eternal\DailyCultivation\prototype\screens"
for name, target in [("shot-resting.png","ios-resting.jpg"), ("shot-history.png","ios-history.jpg"), ("shot.png","ios-idle.jpg")]:
    im = Image.open(os.path.join(d, name)).convert("RGB")
    im.save(os.path.join(out, target), "JPEG", quality=86, optimize=True)
    print(target, im.size)
