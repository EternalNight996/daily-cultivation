
# -*- coding: utf-8 -*-
"""把 assets/art 里的成品图安装进 iOS Assets.xcassets（生成 imageset + Contents.json）。"""
import json, os, shutil, sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = r"F:\MyApp\eternal\DailyCultivation"
ART = os.path.join(ROOT, "assets", "art")
XC = os.path.join(ROOT, "ios", "DailyCultivation", "Resources", "Assets.xcassets")

# name -> (源相对路径, scale)
ITEMS = {
    "bg_zi":    ("01-backgrounds/bg_zi@3x.jpg", "3x"),
    "bg_mao":   ("01-backgrounds/bg_mao@3x.jpg", "3x"),
    "bg_wu":    ("01-backgrounds/bg_wu@3x.jpg", "3x"),
    "bg_you":   ("01-backgrounds/bg_you@3x.jpg", "3x"),
    "bg_chang": ("01-backgrounds/bg_chang@3x.jpg", "3x"),
    "paper_new":   ("02-paper/paper_new@2x.jpg", "1x"),
    "paper_worn":  ("02-paper/paper_worn@2x.jpg", "1x"),
    "paper_burnt": ("02-paper/paper_burnt@2x.jpg", "1x"),
    "seal_chi": ("04-seals/seal_chi.png", "1x"),
    "seal_he":  ("04-seals/seal_he.png", "1x"),
    "pet_idle":     ("05-pet/pet_idle_00.png", "1x"),
    "pet_cast":     ("05-pet/pet_cast_00.png", "1x"),
    "pet_resonate": ("05-pet/pet_resonate_00.png", "1x"),
    "brush_start":  ("03-brush/brush_start_01.png", "1x"),
    "brush_body":   ("03-brush/brush_body_01.png", "1x"),
    "brush_body2":  ("03-brush/brush_body_02.png", "1x"),
    "brush_end":    ("03-brush/brush_end_01.png", "1x"),
    "brush_corner": ("03-brush/brush_corner_01.png", "1x"),
}

def main():
    count = 0
    for name, (rel, scale) in ITEMS.items():
        src = os.path.join(ART, rel.replace("/", os.sep))
        if not os.path.exists(src):
            print(f"跳过（缺文件）: {name} <- {rel}")
            continue
        ext = os.path.splitext(src)[1]
        dst_dir = os.path.join(XC, f"{name}.imageset")
        if os.path.isdir(dst_dir):
            shutil.rmtree(dst_dir)
        os.makedirs(dst_dir)
        fname = f"{name}{ext}"
        shutil.copy2(src, os.path.join(dst_dir, fname))
        contents = {
            "images": [{"filename": fname, "idiom": "universal", "scale": scale}],
            "info": {"author": "xcode", "version": 1},
        }
        with open(os.path.join(dst_dir, "Contents.json"), "w", encoding="utf-8") as f:
            json.dump(contents, f, ensure_ascii=False, indent=2)
        kb = os.path.getsize(os.path.join(dst_dir, fname)) // 1024
        print(f"✅ {name:14s} {scale}  {kb:5d}KB")
        count += 1
    print(f"\n共安装 {count} 个 imageset")

if __name__ == "__main__":
    sys.exit(main())
