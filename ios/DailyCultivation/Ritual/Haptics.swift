import CoreHaptics
import UIKit

/// 触感。真机上用 CHHapticEngine，无 Taptic 的设备退回 UIImpactFeedbackGenerator。
/// 引擎被系统回收后必须能重建——否则用户会遇到"突然没手感了"。
@MainActor
final class Haptics {
    static let shared = Haptics()
    /// 设置里可以关掉；关掉后只保留系统级轻反馈
    static var isEnabled = true

    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() {}

    func prepare() {
        guard supportsHaptics, engine == nil else { return }
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true          // 音频走 AVAudioPlayer，不让引擎再开一路
            engine.isAutoShutdownEnabled = true
            engine.stoppedHandler = { reason in
                Task { @MainActor in
                    Haptics.shared.handleStopped(reason)
                }
            }
            engine.resetHandler = {
                Task { @MainActor in
                    Haptics.shared.restart()
                }
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    private func handleStopped(_ reason: CHHapticEngine.StoppedReason) {
        engine = nil
        if reason == .audioSessionInterrupt {
            // 通话打断：等系统恢复时再重建，不在这里死循环重试
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 600_000_000)
                Haptics.shared.prepare()
            }
        }
    }

    private func restart() {
        do {
            try engine?.start()
        } catch {
            engine = nil
            prepare()
        }
    }

    // MARK: - 三种反馈

    func strokeAccepted() {
        play(events: [
            .init(eventType: .hapticTransient,
                  parameters: [.init(parameterID: .hapticIntensity, value: 0.35),
                               .init(parameterID: .hapticSharpness, value: 0.5)],
                  relativeTime: 0,
                  duration: 0)
        ])
    }

    func reject() {
        play(events: [
            .init(eventType: .hapticTransient,
                  parameters: [.init(parameterID: .hapticIntensity, value: 0.25),
                               .init(parameterID: .hapticSharpness, value: 0.2)],
                  relativeTime: 0,
                  duration: 0)
        ])
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.4)
    }

    /// 符成：两连击 + 一段短连续，这是"点亮"这个动作的触觉锚点。
    func success() {
        play(events: [
            .init(eventType: .hapticTransient,
                  parameters: [.init(parameterID: .hapticIntensity, value: 0.9),
                               .init(parameterID: .hapticSharpness, value: 0.5)],
                  relativeTime: 0,
                  duration: 0),
            .init(eventType: .hapticTransient,
                  parameters: [.init(parameterID: .hapticIntensity, value: 0.5),
                               .init(parameterID: .hapticSharpness, value: 0.25)],
                  relativeTime: 0.09,
                  duration: 0),
            .init(eventType: .hapticContinuous,
                  parameters: [.init(parameterID: .hapticIntensity, value: 0.2),
                               .init(parameterID: .hapticSharpness, value: 0.3)],
                  relativeTime: 0.0, duration: 0.18)
        ])
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func play(events: [CHHapticEvent]) {
        guard Haptics.isEnabled, supportsHaptics else { return }
        guard let engine else {
            prepare()
            return
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // 震动失败不影响结算，静默降级
        }
    }
}
