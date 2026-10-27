# iOS 工程（V1 · 相机链路切片）

> **状态**：代码已写，**尚未在 macOS 上编译过**。Windows 上没有 iOS SDK，这是硬限制。
> Mac 到手的第一件事不是写功能，是按下面步骤把它跑起来、把编译错误清掉。

## 结构

```
ios/
├─ project.yml                      XcodeGen 工程定义（不手写 pbxproj）
├─ TalismanKit/                     纯逻辑包：判定 / 结算 / 日界（Windows 可测）
└─ DailyCultivation/
   ├─ App/
   │  ├─ DailyCultivationApp.swift  @main
   │  ├─ AppModel.swift             状态与生命周期
   │  ├─ RootView.swift             相机 + HUD + 权限分流
   │  ├─ PermissionView.swift       自绘解释页（先讲清楚，再弹系统框）
   │  └─ InkBackground.swift        无相机时的水墨兜底
   ├─ Capture/
   │  ├─ CameraSession.swift        720p@30、丢旧帧、打断恢复、后台停采
   │  ├─ CameraPermission.swift     四态
   │  └─ FrameStore.swift           采集线程 ↔ 渲染线程只交接最新帧
   ├─ Render/
   │  ├─ CameraRenderer.swift       CIContext(mtlDevice:) + MTKView 直渲 drawable
   │  └─ CameraPreview.swift        UIViewRepresentable
   ├─ Core/
   │  ├─ Shichen.swift              四时辰（倍率/文案）
   │  └─ AppLog.swift               OSLog
   └─ Resources/
      ├─ Info.plist                 相机文案、竖屏锁定、无加密申报
      └─ PrivacyInfo.xcprivacy      UserDefaults CA92.1 + 启动时间 35F9.1
```

## 在 Mac 上跑起来（预计 30–60 分钟）

```bash
brew install xcodegen
cd ios
xcodegen generate
open DailyCultivation.xcodeproj
```

1. Xcode → Settings → Accounts 登录 Apple ID
2. 选 Target `DailyCultivation` → Signing & Capabilities → Team 选自己（个人 Team 也能跑真机）
3. 真机连上，iPhone 开「开发者模式」，设备选你的 iPhone，⌘R

> 不要用模拟器验证相机：模拟器没有 AVCaptureDevice，画面会是黑的。布局可以在模拟器看，相机必须真机。

## 先在 Mac 上完成这 5 件事

- [ ] `xcodegen generate` 成功，工程能打开
- [ ] 真机编译通过（预计 3–8 处编译错误，多为 API 细节）
- [ ] `cd TalismanKit && swift test` 21 条全绿
- [ ] 授权后能看到实时滤镜画面；拒绝后能看到水墨兜底 +「以水墨洞府继续」
- [ ] 切后台再回来，相机能恢复；连续 60 秒不掉帧

## 本轮新增（画符闭环）

| 文件 | 职责 |
|---|---|
| `Talisman/StrokeRecorder.swift` | coalescedTouches 采样 → One Euro 平滑（1.0 / 0.007）→ 1.5pt 降采样 |
| `Talisman/TalismanCanvasView.swift` | 虚线引导 + 已完成笔 + 拖尾 + 起笔光点 + 40pt 起笔容差；松手过早只作废该笔 |
| `Talisman/TalismanCanvas.swift` | SwiftUI 桥接（显式传 strokeIndex/phase，触发 updateUIView） |
| `Ritual/RitualSession.swift` | 状态机：等笔 → 判笔 → 结算；调 `TalismanKit` 打分与 `QiCalculator` |
| `Ritual/Haptics.swift` | CHHapticEngine：接受/拒绝/符成三种反馈，无 Taptic 兜底 |
| `Ritual/SettlementView.swift` | 结算面板：基础 / 时辰倍率 / 首符 / 共鸣 / 上衰减 / 合计 |

到这里，**画符 → 判定 → 结算**的闭环在代码层面是完整的（仍未经编译）。

## 本轮新增（持久化）

| 文件 | 职责 |
|---|---|
| `Store/CultivationModel.swift` | 代码定义的 CoreData 模型（3 实体），不依赖 .xcdatamodeld，可在 Windows 上 review |
| `Store/PersistenceController.swift` | 容器与 SQLite 存储；加载失败只记日志，不崩 |
| `Store/CultivationStore.swift` | 今日灵气/连续天数/总经验；04:00 日界；90 天明细 + 400 天聚合清理 |
| `RitualSession` 改动 | 结算前读快照、结算后落库；先算后写，首符加成不会错位 |
| `RootView` 改动 | 顶部显示真实的"连续 N 天 · 称号"，来自本地库 |

## 本轮新增（三同步补全）

| 文件 / 资源 | 职责 |
|---|---|
| `Ritual/AudioPool.swift` | AVAudioPlayer 池（每种音 3 个 voice）；`.ambient` 会话，尊重静音键、不打断用户音乐 |
| `Resources/Audio/tick.wav` / `complete.wav` / `settle.wav` | **程序合成的占位音**（无版权问题）；美术音到位后同名替换 |
| `Render/ParticleTexture.swift` | 程序生成柔光点贴图，避免为占位粒子引入图片 |
| `Talisman/RitualParticlesLayer.swift` | 三组 CAEmitterLayer：环境灵气（常驻）/ 指尖星尘（画符时 90/s）/ 结算爆发（0.12s 内 900/s，随后归零） |
| `TalismanCanvasView` 改动 | 起笔开启星尘、抬手关闭、符成在符盘中心爆发 |

> 三同步现在是：**视觉（拖尾+粒子）+ 震动（CHHaptic）+ 音效（AVAudioPlayer）**。
> 尚未做的是"同一个时间基准"：目前是同一 runloop 顺序调用，真机验收时需要量一次偏差，再决定要不要引入 `play(atTime:)` 的 50ms 提前量。

## 本轮新增（宠物与首次引导）

| 文件 | 职责 |
|---|---|
| `Pet/PetView.swift` | 阿团（矢量占位）：呼吸、瞳孔追指尖（±3pt）、结算时上跳；美术序列帧到位后替换 body |
| `App/OnboardingTip.swift` | 首次引导：总施法 <3 次时出现，按次数换文案，不做永久教学 |
| `RitualSession.gaze` | 指尖归一化偏移，由画布写入、宠物读取 |
| `CultivationStore` | 增加 `totalCasts`（累计施法数），用于引导与后续成长 |

## 本轮新增（四时辰配色）

| 文件 | 职责 |
|---|---|
| `Render/RenderPalette.swift` | 五套调色参数：色温目标 / 饱和 / 对比 / 辉光强度与半径 / 暗角 |
| `CameraRenderer` 改动 | 调色从常量改为读 palette；`setShichen()` 在主线程切换 |
| `AppModel` 改动 | 进前台时重算时辰，HUD 与渲染共用同一个值，避免"文案换了画面没换" |

> 改的是真实画面参数，不是盖一层半透明色块——盖色块会把暗部细节洗掉，真机上像"滤镜坏了"。

## 本轮新增（UI 定稿同步）

| 改动 | 值 |
|---|---|
| 符框尺寸 | 280 → **292**（占屏宽 78% 上限），符几乎贴到盘边 |
| 进度环 | 外移 16pt、线宽 1.5、透明度降至 28%，不再抢笔尖的视线 |
| 朱砂印 | 36pt「敕」印，落印从 2.4 倍压到 1.0（spring 0.46s），放在符的右下角 |
| 墨晕 | `CAGradientLayer` 径向渐变，0.4→1.2 倍扩散 + 三段透明度，1.1s |
| 符名 | 宋体 + 字距 3，位置在盘心下方 132pt |
| 宠物 | 底边距 88 → 150，结算时抬升 190pt（与原型同构） |

## 仍**没有**包含

- 美术序列帧（现在是矢量占位）
- 时辰切换的过渡动画（现在是瞬切，1.2s 交叉淡入留到真机调完再做）
- 四时辰的配色切换（现在只有文案与倍率）

下一刀建议顺序：**持久化 → 粒子 → 宠物 → 音效**。持久化排第一，是因为“连续天数”是留存钩子，没有它，V1 的验证指标根本测不出来。

## 为什么用 XcodeGen

工程文件（`.pbxproj`）是二进制式的共享状态，在 Windows 上写不了、改一次冲突一次。
`project.yml` 是纯文本，可以在 Windows 上改，Mac 上一条命令生成——这是「Windows 写、Mac 跑」唯一不打架的方式。
