
from PIL import Image
import os
d = r"F:\MyApp\eternal\shots-tmp3"
out = r"F:\MyApp\eternal\DailyCultivation\prototype\screens"
for name, target in [("shot-share.png","ios-share.jpg")]:
    im = Image.open(os.path.join(d, name)).convert("RGB")
    im.save(os.path.join(out, target), "JPEG", quality=88, optimize=True)
    print(target, im.size)
