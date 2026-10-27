import Foundation

/// 修炼日以 04:00 为界：23:00–04:00 的夜猫子算"今天"，不因跨零点断签。
public struct CultivationCalendar: Sendable {
    public let boundaryHour: Int

    public init(boundaryHour: Int = 4) {
        self.boundaryHour = boundaryHour
    }

    private func calendar(_ timeZone: TimeZone) -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        return c
    }

    /// 不做字符串格式化（DateFormatter 慢且非线程安全），直接拼 yyyy-MM-dd。
    public func dateKey(for date: Date, timeZone: TimeZone = .current) -> String {
        let shifted = date.addingTimeInterval(-Double(boundaryHour) * 3600)
        let comps = calendar(timeZone).dateComponents([.year, .month, .day], from: shifted)
        let y = comps.year ?? 0, m = comps.month ?? 0, d = comps.day ?? 0
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    public func isSameCultivationDay(_ a: Date, _ b: Date, timeZone: TimeZone = .current) -> Bool {
        dateKey(for: a, timeZone: timeZone) == dateKey(for: b, timeZone: timeZone)
    }

    /// 连续修炼天数：同日不涨、隔日 +1、断签重置为 1。累计经验不在这里，断签不清零。
    public func nextStreak(previous: Int, lastActive: Date?, now: Date,
                           timeZone: TimeZone = .current) -> Int {
        guard let lastActive else { return 1 }
        let today = dateKey(for: now, timeZone: timeZone)
        let last = dateKey(for: lastActive, timeZone: timeZone)
        if last == today { return max(previous, 1) }

        let yesterday = calendar(timeZone).date(byAdding: .day, value: -1, to: now) ?? now
        let yesterdayKey = dateKey(for: yesterday, timeZone: timeZone)
        return last == yesterdayKey ? max(previous, 0) + 1 : 1
    }
}
