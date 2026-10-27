# 《每日一道符》开发规则

## 产品
- 代号 `DailyCultivation`，暂定名《每日一道符》，修仙题材 iOS 原生 App。
- 核心闭环：摄像头实时预览 → 沿虚线画符 → 符成三同步（粒子/音效/震动）→ 灵气结算 → 萌宠共鸣 → 次日再来。
- 不可妥协：打开 1.5s 内能画符、单次施法 ≤15s、手感优先于画面、不惩罚离开、只在用户主动时变现。

## 已定决策（2026-10-26，变更需走 ADR）
- 主体：**公司**（Apple Organization 账号）；备案、V4 广告资质、版号均以公司名义。
- 数据：**V1 严格零上传**，隐私标签 Data Not Collected；不接任何统计/崩溃 SDK。
- 区域：**中国区与海外区同版首发**，同一构建；海外先上，中国区等备案；首发不含欧盟。
- 决策记录：`docs/03-决策记录.md`，不删旧条目，只追加修订。

## 技术栈
- iOS 17.0+ / iPhone 竖屏 / SwiftUI + UIKit 混合 / MVVM + @Observable + Swift Concurrency。
- 采集 AVCaptureSession（720p@30）；渲染 CIContext(mtlDevice:) + MTKView + CIColorCube(32³)；粒子 CAEmitterLayer（V1 ≤800）。
- 画符 UIKit touchesMoved + coalescedTouches；匹配离散 Fréchet（32 点，阈值 0.72）。
- 存储 CoreData + UserDefaults；震动 CoreHaptics；音频 AVAudioPlayer 池 + AVAudioSession `.ambient`。
- V1 零第三方依赖、零服务器、零上传、零账号。

## 目录
- 文档：`docs/`（00 路线图 / 01 iOS 技术方案 / 02 风险合规 / 03 决策记录）
- 代码（待建）：`DailyCultivation/App|Capture|Render|Talisman|Ritual|Pet|Store|Core`

## 约定
- 数值以 `docs/00` 的 0.3 全局基线为准，改动走版本评审并记录理由。
- 每个版本必须有「不做清单」与「关停线」。
- 修炼日边界 04:00；日界、时区、跨日必须有单测。
- 提审前跑 `docs/02` 的 30 条 Checklist 与 10 条发布门禁。

## 禁止
- 不做战斗、抽卡、PVP、体力、排行榜奖励（版号与定位风险）。
- 不卖进度、不卖跳过、不做强制插屏、不做第三方支付。
- 不偷偷加第三方统计 SDK 破坏「零上传」承诺。
- 不接受用个人开发者账号提交中国区（主体必须与备案、广告开户一致）。
