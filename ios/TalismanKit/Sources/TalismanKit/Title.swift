import Foundation

/// 称号只由连续天数决定，与付费、抽卡无关——这是"不卖进度"在数据结构上的体现。
public enum Title: String, CaseIterable, Sendable {
    case fanren = "凡人"
    case lianqi = "练气"
    case zhuji = "筑基"
    case jindan = "金丹"
    case yuanying = "元婴"
    case huashen = "化神"
    case dujie = "渡劫"
    case dacheng = "大乘"

    public static func forStreak(_ days: Int) -> Title {
        switch days {
        case 365...: return .dacheng
        case 180...: return .dujie
        case 100...: return .huashen
        case 60...: return .yuanying
        case 30...: return .jindan
        case 7...: return .zhuji
        case 3...: return .lianqi
        default: return .fanren
        }
    }
}
