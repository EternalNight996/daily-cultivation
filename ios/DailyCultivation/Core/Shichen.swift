import Foundation

/// 四时辰：每个 2 小时窗口各有倍率与配色。V1 只用于展示与结算，不改渲染管线。
enum Shichen: String, CaseIterable {
    case zi, mao, wu, you, chang

    var label: String {
        switch self {
        case .zi: return "子时 · 玄水"
        case .mao: return "卯时 · 青木"
        case .wu: return "午时 · 离火"
        case .you: return "酉时 · 白金"
        case .chang: return "无常 · 平"
        }
    }

    var multiplier: Double {
        switch self {
        case .zi: return 1.6
        case .wu: return 1.5
        case .mao, .you: return 1.3
        case .chang: return 1.0
        }
    }

    static func current(for date: Date = .now, calendar: Calendar = .current) -> Shichen {
        switch calendar.component(.hour, from: date) {
        case 23, 0: return .zi
        case 5, 6: return .mao
        case 11, 12: return .wu
        case 17, 18: return .you
        default: return .chang
        }
    }
}
