import XCTest
@testable import TalismanKit

final class CalendarTests: XCTestCase {
    private let tz = TimeZone(identifier: "Asia/Shanghai")!
    private let cal = CultivationCalendar()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = tz
        return c.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    func testBeforeBoundaryBelongsToPreviousDay() {
        XCTAssertEqual(cal.dateKey(for: date(2026, 11, 24, 3, 59), timeZone: tz), "2026-11-23")
    }

    func testAtBoundaryStartsNewDay() {
        XCTAssertEqual(cal.dateKey(for: date(2026, 11, 24, 4, 0), timeZone: tz), "2026-11-24")
    }

    func testSameDayIgnoresTime() {
        let a = date(2026, 11, 24, 4, 1)
        let b = date(2026, 11, 24, 23, 59)
        XCTAssertTrue(cal.isSameCultivationDay(a, b, timeZone: tz))
    }

    func testStreakContinuesOnConsecutiveDays() {
        let s = cal.nextStreak(previous: 6, lastActive: date(2026, 11, 23, 21, 0), now: date(2026, 11, 24, 9, 0), timeZone: tz)
        XCTAssertEqual(s, 7)
    }

    func testStreakUnchangedSameDay() {
        let s = cal.nextStreak(previous: 7, lastActive: date(2026, 11, 24, 9, 0), now: date(2026, 11, 24, 22, 0), timeZone: tz)
        XCTAssertEqual(s, 7)
    }

    func testStreakResetsAfterGap() {
        let s = cal.nextStreak(previous: 30, lastActive: date(2026, 11, 19, 9, 0), now: date(2026, 11, 24, 9, 0), timeZone: tz)
        XCTAssertEqual(s, 1)
    }

    func testFirstEverCast() {
        XCTAssertEqual(cal.nextStreak(previous: 0, lastActive: nil, now: date(2026, 11, 24, 9, 0), timeZone: tz), 1)
    }

    func testMidnightCastStillCountsForSameDay() {
        let late = date(2026, 11, 24, 0, 30)      // 属于 11-23 的修炼日
        let evening = date(2026, 11, 23, 21, 0)   // 也属于 11-23
        XCTAssertTrue(cal.isSameCultivationDay(late, evening, timeZone: tz))
    }
}
