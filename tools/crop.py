
from PIL import Image
p = r"F:\MyApp\eternal\DailyCultivation\prototype\screens\ios-onboarding.jpg"
im = Image.open(p)
crop = im.crop((840, 2060, 1010, 2230)).resize((680, 680), Image.LANCZOS)
crop.save(r"F:\MyApp\eternal\DailyCultivation\prototype\screens\_zoom.jpg", quality=92)
print(crop.size)
