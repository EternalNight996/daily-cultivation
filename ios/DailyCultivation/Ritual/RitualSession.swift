import CoreGraphics
import Foundation
import Observation
import TalismanKit

/// 一局施法的状态机：等笔 → 判笔 → 结算。不碰 UIKit，方便后续单测。
@MainActor
@Observable
final class RitualSession {
    enum Phase: Equatable {
        case drawing
        case settling
    }

    var phase: Phase = .drawing
    var talisman: Talisman = TalismanLibrary.qingxin
    private(set) var strokeIndex = 0
    private(set) var accepted: [[Vec2]] = []
    private(set) var settlement: QiBreakdown?
    var lastScore: Double?
    var hint: String?

    var config = MatchConfig()
    var petResonance = true

    /// 由 AppModel 注入；为 nil 时退化为"本次会话内存数据"，不影响画符
    var store: CultivationStore?
    private(set) var snapshot: CultivationStore.Snapshot = .empty

    /// 指尖相对屏幕中心的归一化偏移（-1…1），宠物用它转眼睛
    var gaze: CGSize = .zero

    var streakDays: Int { snapshot.streak }

    var isComplete: Bool { strokeIndex >= talisman.strokes.count }
    var expectedStroke: [Vec2]? { isComplete ? nil : talisman.strokes[strokeIndex] }
    var strokeCount: Int { talisman.strokes.count }

    /// 返回 true 表示这一笔被接受。
    func judge(_ localStroke: [Vec2]) -> Bool {
        guard let template = expectedStroke else { return false }
        let score = Matcher.score(user: localStroke, template: template, config: config)
        lastScore = score.total

        guard score.total >= config.passThreshold else {
            hint = score.total < config.helpThreshold ? "偏得有点远，再看一眼虚线" : "差一点，重画这一笔"
            Haptics.shared.reject()
            return false
        }

        accepted.append(localStroke)
        strokeIndex += 1
        hint = nil

        if isComplete {
            settle()
        } else {
            Haptics.shared.strokeAccepted()
            AudioPool.shared.play(.tick)
        }
        return true
    }

    private func settle() {
        phase = .settling
        let shichen = Shichen.current()
        let before = snapshot

        let qi = QiCalculator.settle(QiContext(
            shichenMultiplier: shichen.multiplier,
            streakDays: before.streak,
            isFirstOfDay: before.isFirstOfDay,
            petResonance: petResonance,
            dailyEarned: before.earnedToday
        ))
        settlement = qi

        // 先算后写：本次结算用的是"画之前"的连续天数与今日已得，首符加成不会错位
        if let store {
            snapshot = store.record(qi: qi.total,
                                    score: lastScore ?? 0,
                                    strokes: talisman.strokes.count,
                                    shichen: shichen)
        } else {
            snapshot = CultivationStore.Snapshot(
                streak: max(before.streak, 1),
                longestStreak: max(before.longestStreak, before.streak),
                totalXp: before.totalXp + qi.total,
                earnedToday: before.earnedToday + qi.total,
                castsToday: before.castsToday + 1,
                totalCasts: before.totalCasts + 1,
                title: TalismanKit.Title.forStreak(max(before.streak, 1))
            )
        }

        Haptics.shared.success()
        AudioPool.shared.play(.complete)

        // 结算音在"点亮"之后 0.42s 进，形成两段式，不抢主音
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard let self, self.phase == .settling else { return }
            AudioPool.shared.play(.settle)
        }
    }

    func refreshSnapshot() {
        snapshot = store?.snapshot() ?? .empty
    }

    func nextTalisman() {
        let all = TalismanLibrary.all
        guard let index = all.firstIndex(where: { $0.id == talisman.id }) else { return }
        talisman = all[(index + 1) % all.count]
        reset()
    }

    func reset() {
        phase = .drawing
        strokeIndex = 0
        accepted = []
        settlement = nil
        lastScore = nil
        hint = nil
    }
}
