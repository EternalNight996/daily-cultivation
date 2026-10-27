# 美术资产 · 目录与命名规范

> 所有待接入的图/音都放这里。**放进 `01-…07-` 对应目录，文件名严格按规范**，我这边有脚本会自动校验并接入 App。

## 目录

```
assets/art/
├─ 01-backgrounds/   四时辰洞府绘景（P0，最先要）
├─ 02-paper/         符纸底（新纸/旧纸/焦边）
├─ 03-brush/         笔锋图集（起笔/行笔/收笔/折笔）
├─ 04-seals/         朱砂印章（敕/每/成/静）
├─ 05-pet/           阿团序列帧（待机/施法/共鸣）
├─ 06-particles/     粒子贴图
├─ 07-audio/         音效
├─ _inbox/           未整理的原图先扔这（我可以帮你改名归档）
└─ _approved/        验收入库的成品（只放通过校验的）
```

## 命名规范

| 资产 | 文件名 | 规格 | 透明底 |
|---|---|---|---|
| 背景 · 午 | `bg_wu@3x.jpg` | 1170×2532 | 否 |
| 背景 · 子 | `bg_zi@3x.jpg` | 1170×2532 | 否 |
| 背景 · 卯 | `bg_mao@3x.jpg` | 1170×2532 | 否 |
| 背景 · 酉 | `bg_you@3x.jpg` | 1170×2532 | 否 |
| 纸 · 新 | `paper_new@2x.jpg` | 2048×2048 | 否（纹理，形状由代码裁） |
| 纸 · 旧 | `paper_worn@2x.jpg` | 2048×2048 | 否 |
| 纸 · 焦边 | `paper_burnt@2x.jpg` | 2048×2048 | 否 |
| 笔 · 起笔 | `brush_start_01.png` … `_03` | 512×512 | **是** |
| 笔 · 行笔 | `brush_body_01.png` … | 512×512 | **是** |
| 笔 · 收笔 | `brush_end_01.png` … | 512×512 | **是** |
| 笔 · 折笔 | `brush_corner_01.png` … | 512×512 | **是** |
| 印章 | `seal_chi.png` / `seal_he.png` / `seal_cheng.png` / `seal_jing.png` | 512×512 | **是** |
| 宠物 | `pet_idle_00.png` … `pet_idle_11.png`（cast / resonate 同理） | 512×512 | **是** |
| 粒子 | `particle_{glow|ink|ember}_01.png` | 256×256 | **是** |
| 音效 | `sfx_{tick|complete|settle|pet}.m4a` | 44.1k mono | — |

> 一张图一个文件；不要合并图集（我来合）。

## 色彩与画风约束

- 冷灰水墨：主色 青灰 / 墨青 / 艾绿，**朱砂只做点睛**
- 不要金色、不要霓虹、不要高饱和
- 背景不要文字/水印/边框/人物
- 笔触必须是**纯黑墨 + 纯白底**（方便程序染色）

## 交付流程

1. 原图丢 `_inbox/`（名字随意）
2. 或直接按规范命名放进对应目录
3. 我跑 `python tools/validate_assets.py` 校验尺寸/通道/命名
4. 通过后进 App 的 `Assets.xcassets`，并更新本文档的"已接入"表

## 已接入

| 资产 | 文件 | 日期 |
|---|---|---|
| App 图标 | `assets/app-icons/ios/*` | 2026-10-27 |
| 洞府绘景 ×4 | `01-backgrounds/bg_{zi,mao,wu,you}@3x.jpg` | 2026-10-27 |
| 符纸 ×3 | `02-paper/paper_{new,worn,burnt}@2x.jpg` | 2026-10-27 |
| 笔锋 ×4 | `03-brush/brush_{start,body,end,corner}_01.png` | 2026-10-27 |
| 朱砂印 ×2 | `04-seals/seal_he.png`、`seal_chi.png`（符成用） | 2026-10-27 |
| 笔锋补 2 个 | `03-brush/brush_body_02.png`、`brush_end_02.png` | 2026-10-27 |
| 灵兽三态 | `05-pet/pet_{idle,cast,resonate}_00.png`（+idle/cast 各 1 个备选） | 2026-10-27 |
| 备用背景 | `01-backgrounds/bg_chang@3x.jpg`（无常/兜底） | 2026-10-27 |
| 占位音效 | `ios/…/Resources/Audio/*.wav` | 2026-10-26 |

## 合规

AI 生成图需保留生成记录（prompt/模型/日期），并在"关于"页注明"部分美术由 AI 辅助生成"。
