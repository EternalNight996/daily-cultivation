# TalismanKit · 画符核心逻辑包

纯 Swift、零依赖、**不 import UIKit / AVFoundation / Metal**，因此 macOS、Linux、Windows 都能编译和跑单测。
iOS App 以 SPM 方式依赖它；画符判定、灵气结算、修炼日界这些"算错就毁体验"的部分只有这一份实现。

## 内容

| 文件 | 职责 |
|---|---|
| `Vec2.swift` | 跨平台二维点（刻意不用 CGPoint，Windows 上没有 CoreGraphics）；`canImport(CoreGraphics)` 时提供 CGPoint 互转 |
| `Resampler.swift` | 按弧长等距重采样 32 点、逐点单位切线 |
| `Frechet.swift` | 离散 Fréchet 距离 + 对齐路径（切线打分要用） |
| `Talisman.swift` | 符模板数据结构 + 三张 V1 符（清心 / 聚灵 / 御风） |
| `Matcher.swift` | 打分（形似 0.60 / 切线 0.25 / 端点 0.15）、阈值 0.72 / 0.65 / 0.55、整符加权均值 0.75、屏幕→符框映射 |
| `QiCalculator.swift` | 灵气结算：时辰倍率、首符 1.5、连续加成、宠物共鸣、软上限四段衰减（永不为 0） |
| `CultivationCalendar.swift` | 04:00 修炼日边界、跨时区、连续天数（同日不涨 / 隔日 +1 / 断签重置） |

## 跑测试

macOS（有 Xcode）：

```bash
cd ios/TalismanKit
swift test
```

Windows（需要 Swift 工具链 + Visual Studio 的 MSVC 组件）：

```powershell
winget install --id Swift.Toolchain -e
winget install --id Microsoft.VisualStudio.2022.BuildTools -e
swift --version
cd ios\TalismanKit
swift test
```

> 首次装 Windows 版 Swift 通常要拉几 GB（MSVC 组件占大头），装完一次即可长期用。

## 设计上的三个"为什么"

1. **固定符框坐标系，不按用户笔画包围盒归一化。** 按包围盒缩放会让任何一条竖线都被拉成满分——这是最容易写错、也最难在真机上发现的一处。
2. **Fréchet 而不是 Hausdorff。** Hausdorff 不关心走的方向，倒着画也会高分；Fréchet 会惩罚顺序错误，再叠加切线项，才能挡住"描形不描意"。
3. **软上限只削减总量，不削减动作。** 衰减到 10% 也永远大于 0，用户画了就一定有反馈——数值上的"不惩罚离开"。

## 边界

这个包**只放可测的纯逻辑**。相机、Metal、震动、音效、动画一律不进这里；一旦 import 了 UIKit，Windows 上的单测就废了，等于把唯一的跨平台验证手段丢掉。
