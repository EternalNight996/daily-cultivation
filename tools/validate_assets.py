
# -*- coding: utf-8 -*-
"""校验 assets/art 下的美术资产：命名 / 尺寸 / 透明通道 / 体积。

用法：
    python tools/validate_assets.py
只打印报告，不改文件。有任何 FAIL 时退出码为 1。
"""
import os, re, sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "assets", "art")

RULES = [
    # dir, name regex, min width, min height, need alpha, max KB
    ("01-backgrounds", r"^bg_(zi|mao|wu|you|chang)@3x\.(jpg|png)$", 1170, 2532, False, 900),
    ("02-paper",       r"^paper_(new|worn|burnt)@2x\.(jpg|png)$", 2048, 2048, False, 900),
    ("03-brush",       r"^brush_(start|body|end|corner)_\d{2}\.png$", 256, 256, True, 300),
    ("04-seals",       r"^seal_(chi|mei|cheng|jing|he)\.png$", 256, 256, True, 300),
    ("05-pet",         r"^pet_(idle|cast|resonate)_\d{2}\.png$", 256, 256, True, 300),
    ("06-particles",   r"^particle_(glow|ink|ember)_\d{2}\.png$", 128, 128, True, 200),
    ("07-audio",       r"^sfx_(tick|complete|settle|pet)\.(m4a|wav)$", 0, 0, False, 500),
]

def check_image(path, min_w, min_h, need_alpha, max_kb):
    from PIL import Image
    problems = []
    size_kb = os.path.getsize(path) // 1024
    if size_kb > max_kb:
        problems.append(f"体积 {size_kb}KB > {max_kb}KB")
    with Image.open(path) as im:
        w, h = im.size
        if w < min_w or h < min_h:
            problems.append(f"尺寸 {w}x{h} < {min_w}x{min_h}")
        has_alpha = im.mode in ("RGBA", "LA") or "transparency" in im.info
        if need_alpha and not has_alpha:
            problems.append("缺少透明通道")
        if not need_alpha and has_alpha:
            problems.append("不该有透明通道（App Store/裁切会有黑边）")
    return problems

def main():
    print("资产目录:", ROOT)
    total = ok = 0
    failures = []
    for folder, pattern, mw, mh, alpha, maxkb in RULES:
        d = os.path.join(ROOT, folder)
        if not os.path.isdir(d):
            continue
        files = [f for f in sorted(os.listdir(d)) if not f.startswith(".")]
        if not files:
            print(f"\n{folder:16s} —（空）")
            continue
        print(f"\n{folder}")
        for f in files:
            total += 1
            p = os.path.join(d, f)
            problems = []
            if not re.match(pattern, f):
                problems.append("命名不符合规范")
            if not p.lower().endswith((".png", ".jpg", ".m4a", ".wav")):
                problems.append("扩展名不对")
            if p.lower().endswith(".png"):
                try:
                    problems += check_image(p, mw, mh, alpha, maxkb)
                except Exception as e:
                    problems.append(f"无法读取：{e}")
            if problems:
                failures.append((folder, f, problems))
                print(f"  ❌ {f}")
                for pr in problems:
                    print(f"       · {pr}")
            else:
                ok += 1
                print(f"  ✅ {f}")
    print("\n" + "=" * 60)
    print(f"共 {total} 个，通过 {ok}，失败 {len(failures)}")
    if failures:
        print("把上面 ❌ 的条目修好再放进来。")
        return 1
    if total == 0:
        print("目录还是空的——把图放进 assets/art/01-backgrounds 等对应目录即可。")
    return 0

if __name__ == "__main__":
    sys.exit(main())
