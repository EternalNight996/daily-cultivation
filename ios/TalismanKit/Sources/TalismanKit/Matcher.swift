import Foundation

public struct MatchConfig: Equatable, Sendable {
    public var passThreshold: Double = 0.72
    public var assistedThreshold: Double = 0.65
    public var helpThreshold: Double = 0.55     // 低于此值直接进"手把手"
    public var shapeScale: Double = 0.22        // 归一化坐标下的"完全不像"尺度
    public var endTolerance: Double = 40.0 / 280.0
    public var averageThreshold: Double = 0.75  // 整符加权均值线
    public var shapeWeight = 0.60
    public var tangentWeight = 0.25
    public var endpointWeight = 0.15

    public init() {}
}

public struct StrokeScore: Equatable, Sendable {
    public let total: Double
    public let shape: Double
    public let tangent: Double
    public let endpoints: Double
    public let frechet: Double
    public let pointCount: Int
}

public enum MatchOutcome: Equatable, Sendable {
    case passed(average: Double)
    case strokeRetry(index: Int, score: Double)
    case assisted(index: Int, score: Double)
    case talismanRetry(average: Double)
    case invalidStrokeCount(expected: Int, actual: Int)
}

/// 把屏幕点映射到符的局部坐标系（0…1）。屏幕坐标与符框的关系必须由调用方显式给出，
/// 不能从用户笔画自行推断——否则"画一条竖线"会被缩放成满分。
public struct TalismanFrame: Equatable, Sendable {
    public let centerX: Double
    public let centerY: Double
    public let size: Double

    public init(centerX: Double, centerY: Double, size: Double) {
        self.centerX = centerX
        self.centerY = centerY
        self.size = size
    }

    public func local(from screen: Vec2) -> Vec2 {
        Vec2(x: (screen.x - (centerX - size / 2)) / size,
             y: (screen.y - (centerY - size / 2)) / size)
    }
}

public enum Matcher {
    public static func score(user: [Vec2], template: [Vec2], config: MatchConfig = .init()) -> StrokeScore {
        let u = Resampler.resample(user, count: 32)
        let t = Resampler.resample(template, count: 32)
        let fr = Frechet.distance(u, t)

        let shape = max(0, 1 - fr / config.shapeScale)

        let ut = Resampler.tangents(u)
        let tt = Resampler.tangents(t)
        let pairs = Frechet.alignment(u, t)
        var tangentSum = 0.0
        for (i, j) in pairs {
            let dot = ut[i].x * tt[j].x + ut[i].y * tt[j].y
            tangentSum += max(0, (dot + 1) / 2)
        }
        let tangent = pairs.isEmpty ? 0 : tangentSum / Double(pairs.count)

        let dStart = u[0].distance(to: t[0])
        let dEnd = u[31].distance(to: t[31])
        let ends = (max(0, 1 - dStart / config.endTolerance) + max(0, 1 - dEnd / config.endTolerance)) / 2

        let total = config.shapeWeight * shape + config.tangentWeight * tangent + config.endpointWeight * ends
        return StrokeScore(total: total, shape: shape, tangent: tangent, endpoints: ends,
                           frechet: fr, pointCount: user.count)
    }

    public static func evaluate(userStrokes: [[Vec2]], talisman: Talisman,
                                config: MatchConfig = .init()) -> MatchOutcome {
        guard userStrokes.count == talisman.strokes.count else {
            return .invalidStrokeCount(expected: talisman.strokes.count, actual: userStrokes.count)
        }
        var scores: [Double] = []
        for (index, stroke) in userStrokes.enumerated() {
            let s = score(user: stroke, template: talisman.strokes[index], config: config)
            if s.total < config.helpThreshold { return .assisted(index: index, score: s.total) }
            if s.total < config.passThreshold { return .strokeRetry(index: index, score: s.total) }
            scores.append(s.total)
        }
        let weightSum = talisman.weights.reduce(0, +)
        let average = zip(scores, talisman.weights).map(*).reduce(0, +) / max(weightSum, Double.leastNonzeroMagnitude)
        return average >= config.averageThreshold ? .passed(average: average) : .talismanRetry(average: average)
    }
}
