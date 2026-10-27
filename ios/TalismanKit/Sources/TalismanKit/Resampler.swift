import Foundation

/// 按弧长等距重采样。手速不影响结果——这是"画快画慢都该判一样"的前提。
public enum Resampler {
    public static func resample(_ points: [Vec2], count: Int) -> [Vec2] {
        guard count > 1, points.count > 1 else { return points }
        var cumulative: [Double] = [0]
        cumulative.reserveCapacity(points.count)
        for i in 1..<points.count {
            cumulative.append(cumulative[i - 1] + points[i].distance(to: points[i - 1]))
        }
        let total = cumulative[cumulative.count - 1]
        guard total > 0 else { return Array(repeating: points[0], count: count) }

        var result: [Vec2] = [points[0]]
        result.reserveCapacity(count)
        var seg = 0
        for k in 1..<(count - 1) {
            let target = total * Double(k) / Double(count - 1)
            while seg < points.count - 2 && cumulative[seg + 1] < target { seg += 1 }
            let span = cumulative[seg + 1] - cumulative[seg]
            let t = span > 0 ? (target - cumulative[seg]) / span : 0
            let a = points[seg], b = points[seg + 1]
            result.append(Vec2(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
        }
        result.append(points[points.count - 1])
        return result
    }

    /// 每点切线（单位向量），端点用相邻点差分。
    public static func tangents(_ points: [Vec2]) -> [Vec2] {
        guard points.count > 1 else { return Array(repeating: Vec2(x: 1, y: 0), count: points.count) }
        return points.indices.map { i in
            let a = points[max(0, i - 1)]
            let b = points[min(points.count - 1, i + 1)]
            let dx = b.x - a.x, dy = b.y - a.y
            let len = (dx * dx + dy * dy).squareRoot()
            return len > 0 ? Vec2(x: dx / len, y: dy / len) : Vec2(x: 1, y: 0)
        }
    }
}
