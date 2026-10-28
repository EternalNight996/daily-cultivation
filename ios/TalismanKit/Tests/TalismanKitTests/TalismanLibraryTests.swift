import XCTest
@testable import TalismanKit

final class TalismanLibraryTests: XCTestCase {
    func testLibraryHasEnoughTalismans() {
        XCTAssertGreaterThanOrEqual(TalismanLibrary.all.count, 7)
    }

    func testIDsAreUnique() {
        let ids = TalismanLibrary.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEveryTalismanHasAtLeastThreeStrokes() {
        for talisman in TalismanLibrary.all {
            XCTAssertGreaterThanOrEqual(talisman.strokes.count, 3, talisman.name)
            for stroke in talisman.strokes {
                XCTAssertGreaterThanOrEqual(stroke.count, 2, talisman.name)
            }
        }
    }

    func testStrokesStayInsideUnitBox() {
        for talisman in TalismanLibrary.all {
            for stroke in talisman.strokes {
                for point in stroke {
                    XCTAssertTrue((0.0...1.0).contains(point.x), "\(talisman.name) x=\(point.x)")
                    XCTAssertTrue((0.0...1.0).contains(point.y), "\(talisman.name) y=\(point.y)")
                }
            }
        }
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        return calendar
    }

    private func date(hour: Int, day: Int = 10) -> Date {
        let calendar = makeCalendar()
        return calendar.date(from: DateComponents(year: 2024, month: 5, day: day, hour: hour))!
    }

    func testDailyIsStableWithinOneDay() {
        let calendar = makeCalendar()
        XCTAssertEqual(TalismanLibrary.daily(for: date(hour: 9), calendar: calendar).id,
                       TalismanLibrary.daily(for: date(hour: 21), calendar: calendar).id)
    }

    func testDailyChangesAcrossTheFourAmBoundary() {
        let calendar = makeCalendar()
        XCTAssertNotEqual(TalismanLibrary.daily(for: date(hour: 3), calendar: calendar).id,
                          TalismanLibrary.daily(for: date(hour: 5), calendar: calendar).id)
    }

    func testDailyRotatesToNextDay() {
        let calendar = makeCalendar()
        XCTAssertNotEqual(TalismanLibrary.daily(for: date(hour: 10, day: 10), calendar: calendar).id,
                          TalismanLibrary.daily(for: date(hour: 10, day: 11), calendar: calendar).id)
    }
}
