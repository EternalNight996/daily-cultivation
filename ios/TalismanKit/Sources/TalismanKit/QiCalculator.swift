import Foundation

public struct QiContext: Equatable, Sendable {
    public var base: Int
    public var shichenMultiplier: Double
    public var streakDays: Int
    public var isFirstOfDay: Bool
    public var petResonance: Bool
    public var dailyEarned: Int

    public init(base: Int = 80, shichenMultiplier: Double = 1.0, streakDays: Int = 0,
                isFirstOfDay: Bool = false, petResonance: Bool = false, dailyEarned: Int = 0) {
        self.base = base
        self.shichenMultiplier = shichenMultiplier
        self.streakDays = streakDays
        self.isFirstOfDay = isFirstOfDay
        self.petResonance = petResonance
        self.dailyEarned = dailyEarned
    }
}

public struct QiBreakdown: Equatable, Sendable {
    public let base: Int
    public let shichenMultiplier: Double
    public let streakBonus: Double
    public let firstOfDayMultiplier: Double
    public let petMultiplier: Double
    public let capFactor: Double
    public let total: Int
    public let uncapped: Int
}

/// 灵气结算。软上限只削减"总量"，不削减"动作本身"——画符永远有收益，
/// 衰减到 10% 也不为零，这是"不惩罚用户"原则在数值上的落地。
public enum QiCalculator {
    public static func streakBonus(days: Int) -> Double {
        switch days {
        case 100...: return 0.15
        case 30...: return 0.10
        case 7...: return 0.05
        default: return 0
        }
    }

    public static func capFactor(dailyEarned: Int) -> Double {
        switch dailyEarned {
        case ..<600: return 1.0
        case ..<800: return 0.60
        case ..<1000: return 0.25
        default: return 0.10
        }
    }

    public static func settle(_ ctx: QiContext) -> QiBreakdown {
        let streak = streakBonus(days: ctx.streakDays)
        let first = ctx.isFirstOfDay ? 1.5 : 1.0
        let pet = ctx.petResonance ? 1.10 : 1.0
        let factor = capFactor(dailyEarned: ctx.dailyEarned)

        let raw = Double(ctx.base) * ctx.shichenMultiplier * (1 + streak) * first * pet
        let total = max(1, Int((raw * factor).rounded()))
        return QiBreakdown(base: ctx.base,
                           shichenMultiplier: ctx.shichenMultiplier,
                           streakBonus: streak,
                           firstOfDayMultiplier: first,
                           petMultiplier: pet,
                           capFactor: factor,
                           total: total,
                           uncapped: max(1, Int(raw.rounded())))
    }
}
