import Foundation

/// 离散 Fréchet 距离：衡量两条折线在"走法"上的最大偏差。
/// 比 Hausdorff 更贴近手感——Hausdorff 不关心顺序，会让倒着画也得高分。
public enum Frechet {
    public static func distance(_ p: [Vec2], _ q: [Vec2]) -> Double {
        guard !p.isEmpty, !q.isEmpty else { return .infinity }
        let n = p.count, m = q.count
        var prev = [Double](repeating: .infinity, count: m)
        var cur = [Double](repeating: .infinity, count: m)

        for i in 0..<n {
            for j in 0..<m {
                let d = p[i].distance(to: q[j])
                if i == 0 && j == 0 {
                    cur[j] = d
                } else if i == 0 {
                    cur[j] = max(cur[j - 1], d)
                } else if j == 0 {
                    cur[j] = max(prev[j], d)
                } else {
                    cur[j] = max(min(prev[j], prev[j - 1], cur[j - 1]), d)
                }
            }
            swap(&prev, &cur)
            for j in 0..<m { cur[j] = .infinity }
        }
        return prev[m - 1]
    }

    /// 对齐路径：(用户点下标, 模板点下标)。打分时用它取对应点的切线。
    public static func alignment(_ p: [Vec2], _ q: [Vec2]) -> [(Int, Int)] {
        let n = p.count, m = q.count
        guard n > 0, m > 0 else { return [] }
        var ca = [[Double]](repeating: [Double](repeating: 0, count: m), count: n)
        for i in 0..<n {
            for j in 0..<m {
                let d = p[i].distance(to: q[j])
                if i == 0 && j == 0 { ca[i][j] = d }
                else if i == 0 { ca[i][j] = max(ca[i][j - 1], d) }
                else if j == 0 { ca[i][j] = max(ca[i - 1][j], d) }
                else { ca[i][j] = max(min(ca[i - 1][j], ca[i - 1][j - 1], ca[i][j - 1]), d) }
            }
        }
        var path: [(Int, Int)] = []
        var i = n - 1, j = m - 1
        while i > 0 || j > 0 {
            path.append((i, j))
            if i == 0 { j -= 1 }
            else if j == 0 { i -= 1 }
            else {
                let diagonal = ca[i - 1][j - 1]
                let up = ca[i - 1][j]
                let left = ca[i][j - 1]
                if diagonal <= up && diagonal <= left { i -= 1; j -= 1 }
                else if up <= left { i -= 1 }
                else { j -= 1 }
            }
        }
        path.append((0, 0))
        return path.reversed()
    }
}
