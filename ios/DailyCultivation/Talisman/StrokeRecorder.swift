import CoreGraphics
import Foundation
import TalismanKit

/// 采样管线：coalescedTouches → One Euro 平滑 → 1.5pt 距离降采样。
/// 只负责"取准"，判定交给 TalismanKit。
struct StrokeRecorder {
    private var smoothed: [Vec2] = []
    private var lastPoint: Vec2?
    private var filter = OneEuroFilter()
    private var startedAt: TimeInterval?

    var points: [Vec2] { smoothed }

    var length: Double {
        guard smoothed.count > 1 else { return 0 }
        return zip(smoothed.dropFirst(), smoothed).reduce(0) { $0 + $1.0.distance(to: $1.1) }
    }

    mutating func begin(_ point: Vec2, timestamp: TimeInterval) {
        smoothed = [point]
        lastPoint = point
        filter.reset()
        startedAt = timestamp
    }

    mutating func append(_ point: Vec2, timestamp: TimeInterval) {
        let f = filter.filter(point, timestamp: timestamp)
        guard let last = lastPoint else {
            smoothed.append(f)
            lastPoint = f
            return
        }
        // 3x 屏上 1.5pt 约 4.5 物理像素，更密的点对形状没有贡献
        if last.distance(to: f) >= 1.5 {
            smoothed.append(f)
            lastPoint = f
        }
    }

    mutating func reset() {
        smoothed = []
        lastPoint = nil
        filter.reset()
    }
}

/// One Euro：慢速时强平滑、快速时低延迟。参数取 1.0 / 0.007，
/// 是"快划不拖影、慢划不抖"的折中，上机后可微调。
struct OneEuroFilter {
    var minCutoff: Double = 1.0
    var beta: Double = 0.007
    var dCutoff: Double = 1.0

    private var xFilter = LowPass()
    private var dxFilter = LowPass()
    private var previous: Vec2?
    private var previousTime: TimeInterval?

    mutating func reset() {
        xFilter.reset()
        dxFilter.reset()
        previous = nil
        previousTime = nil
    }

    mutating func filter(_ point: Vec2, timestamp: TimeInterval) -> Vec2 {
        let dt = max(0.0001, timestamp - (previousTime ?? timestamp - 0.008))
        previousTime = timestamp

        let dx: Vec2
        if let previous {
            dx = Vec2(x: (point.x - previous.x) / dt, y: (point.y - previous.y) / dt)
        } else {
            dx = Vec2(x: 0, y: 0)
        }

        let edx = Vec2(x: dxFilter.apply(dx.x, dt: dt, cutoff: dCutoff),
                       y: dxFilter.apply(dx.y, dt: dt, cutoff: dCutoff))
        let speed = (edx.x * edx.x + edx.y * edx.y).squareRoot()
        let cutoff = minCutoff + beta * speed

        let filtered = Vec2(x: xFilter.apply(point.x, dt: dt, cutoff: cutoff),
                            y: xFilter.apply(point.y, dt: dt, cutoff: cutoff))
        previous = point
        return filtered
    }
}

private struct LowPass {
    private var value: Double?

    mutating func reset() { value = nil }

    mutating func apply(_ input: Double, dt: Double, cutoff: Double) -> Double {
        guard let value else {
            self.value = input
            return input
        }
        let alpha = 1 / (1 + (1 / (2 * Double.pi * cutoff)) / dt)
        let next = value + alpha * (input - value)
        self.value = next
        return next
    }
}
