
from PIL import Image
import os
d = r"F:\MyApp\eternal\shots-up2"
out = r"F:\MyApp\eternal\DailyCultivation\prototype\screens"
for name, target in [("shot-upgrade.png","ios-upgrade.jpg"), ("shot.png","ios-idle.jpg")]:
    im = Image.open(os.path.join(d, name)).convert("RGB")
    im.save(os.path.join(out, target), "JPEG", quality=88, optimize=True)
    print(target, im.size)
