import Foundation

/// 一张符：若干笔，每笔是归一化到 0…1 局部坐标系的折线。
/// 坐标固定为"符的框"，不是按用户笔画包围盒缩放——否则一条竖线怎么画都满分。
public struct Talisman: Equatable, Sendable {
    public let id: String
    public let name: String
    public let strokes: [[Vec2]]
    public let weights: [Double]

    public init(id: String, name: String, strokes: [[Vec2]], weights: [Double]? = nil) {
        self.id = id
        self.name = name
        self.strokes = strokes
        self.weights = weights ?? Array(repeating: 1, count: strokes.count)
    }
}

public enum TalismanLibrary {
    public static let qingxin = Talisman(
        id: "qingxin",
        name: "清心符",
        strokes: [
            [p(0.50, 0.10), p(0.50, 0.30), p(0.50, 0.50), p(0.49, 0.68), p(0.46, 0.84)],
            [p(0.26, 0.32), p(0.54, 0.32), p(0.70, 0.34), p(0.76, 0.39)],
            [p(0.28, 0.53), p(0.52, 0.53), p(0.68, 0.56), p(0.72, 0.61)]
        ]
    )

    public static let juling = Talisman(
        id: "juling",
        name: "聚灵符",
        strokes: [
            [p(0.28, 0.07), p(0.72, 0.07), p(0.72, 0.11), p(0.50, 0.11), p(0.50, 0.30)],
            [p(0.34, 0.34), p(0.66, 0.34), p(0.66, 0.56), p(0.34, 0.56), p(0.34, 0.34)],
            [p(0.28, 0.62), p(0.72, 0.62), p(0.72, 0.66), p(0.36, 0.66),
             p(0.36, 0.70), p(0.64, 0.70), p(0.64, 0.78), p(0.38, 0.86)]
        ]
    )

    public static let yufeng = Talisman(
        id: "yufeng",
        name: "御风符",
        strokes: [
            arc(cx: 0.50, cy: 0.28, rx: 0.20, ry: 0.15, from: -Double.pi * 0.9, to: Double.pi * 0.2, steps: 16),
            [p(0.18, 0.56), p(0.34, 0.50), p(0.50, 0.58), p(0.66, 0.50), p(0.82, 0.58)],
            [p(0.50, 0.58), p(0.50, 0.72), p(0.46, 0.82), p(0.36, 0.88)]
        ]
    )

    /// 安神符：一竖到底，两横带勾，适合"静下来"
    public static let anshen = Talisman(
        id: "anshen",
        name: "安神符",
        strokes: [
            [p(0.50, 0.08), p(0.50, 0.30), p(0.52, 0.52), p(0.48, 0.74), p(0.44, 0.90)],
            [p(0.24, 0.34), p(0.44, 0.32), p(0.58, 0.35), p(0.66, 0.42)],
            [p(0.30, 0.60), p(0.46, 0.58), p(0.60, 0.62), p(0.66, 0.70), p(0.62, 0.78)]
        ]
    )

    /// 镇宅符：一个方框压住，像把宅子框起来
    public static let zhenzhai = Talisman(
        id: "zhenzhai",
        name: "镇宅符",
        strokes: [
            [p(0.30, 0.10), p(0.70, 0.10), p(0.70, 0.44), p(0.30, 0.44), p(0.30, 0.10)],
            [p(0.50, 0.10), p(0.50, 0.44)],
            [p(0.24, 0.56), p(0.76, 0.56), p(0.74, 0.60), p(0.26, 0.60), p(0.26, 0.56)],
            [p(0.50, 0.60), p(0.50, 0.82), p(0.40, 0.90)]
        ]
    )

    /// 辟邪符：连续的折笔，像一道一道地挡
    public static let bixie = Talisman(
        id: "bixie",
        name: "辟邪符",
        strokes: [
            [p(0.20, 0.12), p(0.34, 0.26), p(0.46, 0.16), p(0.58, 0.30), p(0.70, 0.18), p(0.82, 0.32)],
            [p(0.50, 0.30), p(0.50, 0.56), p(0.46, 0.74), p(0.36, 0.86)],
            [p(0.28, 0.52), p(0.44, 0.50), p(0.56, 0.54), p(0.62, 0.62)]
        ]
    )

    /// 启明符：一道弧像初升的日头
    public static let qiming = Talisman(
        id: "qiming",
        name: "启明符",
        strokes: [
            arc(cx: 0.50, cy: 0.22, rx: 0.15, ry: 0.13, from: 0.15 * Double.pi, to: 0.85 * Double.pi, steps: 14),
            [p(0.50, 0.34), p(0.50, 0.62), p(0.48, 0.80), p(0.40, 0.90)],
            [p(0.26, 0.50), p(0.42, 0.46), p(0.54, 0.50), p(0.62, 0.58)]
        ]
    )

    public static let all = [qingxin, juling, yufeng, anshen, zhenzhai, bixie, qiming]

    /// 每日一符：按"修炼日"取模轮换。
    /// 修炼日以 04:00 为界（与 QiCalculator 的日界一致），所以先把时间前推 4 小时再取日序，
    /// 这样凌晨 3 点画的仍是"昨天"的符。
    public static func daily(for date: Date = Date(), calendar: Calendar = .current) -> Talisman {
        let shifted = calendar.date(byAdding: .hour, value: -4, to: date) ?? date
        let parts = calendar.dateComponents([.year, .month, .day], from: shifted)
        let index = (parts.year ?? 2000) * 372 + (parts.month ?? 1) * 31 + (parts.day ?? 1)
        guard !all.isEmpty else { return qingxin }
        return all[abs(index) % all.count]
    }

    private static func p(_ x: Double, _ y: Double) -> Vec2 { Vec2(x: x, y: y) }

    private static func arc(cx: Double, cy: Double, rx: Double, ry: Double,
                            from: Double, to: Double, steps: Int) -> [Vec2] {
        (0...steps).map { i in
            let t = from + (to - from) * Double(i) / Double(steps)
            return Vec2(x: cx + cos(t) * rx, y: cy + sin(t) * ry)
        }
    }
}
