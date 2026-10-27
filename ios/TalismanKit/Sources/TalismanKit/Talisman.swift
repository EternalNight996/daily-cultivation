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

    public static let all = [qingxin, juling, yufeng]

    private static func p(_ x: Double, _ y: Double) -> Vec2 { Vec2(x: x, y: y) }

    private static func arc(cx: Double, cy: Double, rx: Double, ry: Double,
                            from: Double, to: Double, steps: Int) -> [Vec2] {
        (0...steps).map { i in
            let t = from + (to - from) * Double(i) / Double(steps)
            return Vec2(x: cx + cos(t) * rx, y: cy + sin(t) * ry)
        }
    }
}
