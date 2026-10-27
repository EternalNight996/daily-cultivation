
# -*- coding: utf-8 -*-
"""把 assets/ 根目录下 AI 生成的原始图，按规范命名并归档到 assets/art/。"""
import os, sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

from PIL import Image

ROOT = r"F:\MyApp\eternal\DailyCultivation"
SRC = os.path.join(ROOT, "assets")
ART = os.path.join(SRC, "art")

MAPPING = {
    # 背景：竖向 2:3 → 裁成 9:16 → 1170x2532 JPEG
    # 按画面判断：07-07-45 暖白天光=午；07-09-13 深蓝月夜=子；
    # 07-09-33 淡青晨雾=卯；07-09-53 赭色黄昏=酉
    "Vertical_9_16_Chinese_ink_wash_2026-10-27T07-07-45.png": ("background", "bg_wu@3x.jpg"),
    "Vertical_9_16_Chinese_ink_wash_2026-10-27T07-09-13.png": ("background", "bg_zi@3x.jpg"),
    "Vertical_9_16_Chinese_ink_wash_2026-10-27T07-09-33.png": ("background", "bg_mao@3x.jpg"),
    "Vertical_9_16_Chinese_ink_wash_2026-10-27T07-09-53.png": ("background", "bg_you@3x.jpg"),
    # 纸：纹理，不带 alpha
    "Top_down_high_detail_macro_pho_2026-10-27T07-10-31.png": ("paper", "paper_new@2x.jpg"),
    "Top_down_high_detail_macro_pho_2026-10-27T07-10-46.png": ("paper", "paper_worn@2x.jpg"),
    "Top_down_high_detail_macro_pho_2026-10-27T07-11-03.png": ("paper", "paper_burnt@2x.jpg"),
    # 笔锋：白底 → alpha
    "A_single_Chinese_calligraphy_b_2026-10-27T07-11-58.png": ("brush", "brush_start_01.png"),
    "A_single_Chinese_calligraphy_b_2026-10-27T07-12-22.png": ("brush", "brush_end_01.png"),
    "A_single_Chinese_calligraphy_b_2026-10-27T07-12-39.png": ("brush", "brush_corner_01.png"),
    "A_single_horizontal_Chinese_ca_2026-10-27T07-12-08.png": ("brush", "brush_body_01.png"),
    # 印章：白底 → alpha
    "A_single_square_traditional_Ch_2026-10-27T07-12-51.png": ("seal", "seal_he.png"),
}

DIRS = {"background": "01-backgrounds", "paper": "02-paper", "brush": "03-brush", "seal": "04-seals"}

def to_rgba_from_white(im, keep_color=True):
    """白底转透明：alpha = 255 - min(R,G,B)；彩色保留原色。"""
    im = im.convert("RGB")
    px = im.load()
    out = Image.new("RGBA", im.size)
    op = out.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            a = 255 - min(r, g, b)
            if keep_color:
                op[x, y] = (r, g, b, a)
            else:
                v = min(r, g, b)
                op[x, y] = (v, v, v, a)
    bbox = out.getbbox()
    if bbox:
        out = out.crop(bbox)
    return out

def pad_square(im, size):
    w, h = im.size
    side = max(w, h)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - w)//2, (side - h)//2), im)
    return canvas.resize((size, size), Image.LANCZOS)

def do_background(path, name):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    target_ratio = 9/16
    if w / h > target_ratio:
        new_w = int(h * target_ratio)
        left = (w - new_w)//2
        im = im.crop((left, 0, left + new_w, h))
    else:
        new_h = int(w / target_ratio)
        top = (h - new_h)//2
        im = im.crop((0, top, w, top + new_h))
    # 去掉右下角的"AI生成"水印：裁掉 6% 宽 + 3% 高后重新拉满画幅
    w2, h2 = im.size
    im = im.crop((0, 0, int(w2 * 0.94), int(h2 * 0.97)))
    im = im.resize((1170, 2532), Image.LANCZOS)
    dst = os.path.join(ART, DIRS["background"], name)
    im.save(dst, "JPEG", quality=88, optimize=True, progressive=True)
    return dst

def do_paper(path, name):
    im = Image.open(path).convert("RGB").resize((2048, 2048), Image.LANCZOS)
    dst = os.path.join(ART, DIRS["paper"], name)
    im.save(dst, "JPEG", quality=90, optimize=True)
    return dst

def do_cutout(path, name, folder):
    im = Image.open(path)
    out = pad_square(to_rgba_from_white(im), 512)
    dst = os.path.join(ART, DIRS[folder], name)
    out.save(dst, "PNG", optimize=True)
    return dst

def main():
    results = []
    for src, (kind, name) in MAPPING.items():
        path = os.path.join(SRC, src)
        if not os.path.exists(path):
            print("跳过（不存在）:", src)
            continue
        if kind == "background":
            dst = do_background(path, name)
        elif kind == "paper":
            dst = do_paper(path, name)
        else:
            dst = do_cutout(path, name, kind)
        kb = os.path.getsize(dst)//1024
        results.append((name, kb))
        print(f"✅ {name:22s} {kb:5d}KB  ← {src[:34]}")
    print(f"\n共处理 {len(results)} 个")

if __name__ == "__main__":
    sys.exit(main())
