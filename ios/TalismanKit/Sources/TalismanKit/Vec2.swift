import Foundation

/// 跨平台二维点。刻意不用 CGPoint —— CoreGraphics 在 Windows 上不存在，
/// 而判定逻辑必须在没有 Mac 的环境里也能跑单测。
public struct Vec2: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func distance(to other: Vec2) -> Double {
        ((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)).squareRoot()
    }
}

#if canImport(CoreGraphics)
import CoreGraphics

public extension Vec2 {
    init(_ p: CGPoint) { self.init(x: Double(p.x), y: Double(p.y)) }
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}
#endif
