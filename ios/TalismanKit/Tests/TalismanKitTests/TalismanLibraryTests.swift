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

    func testDailyIsStableWithinOneDay() {
        let calendar = Calendar(identifier: .gregorian)
        let morning = Date(timeIntervalSince1970: 1_700_000_000)
        let evening = morning.addingTimeInterval(6 * 3600)
        XCTAssertEqual(TalismanLibrary.daily(for: morning, calendar: calendar).id,
                       TalismanLibrary.daily(for: evening, calendar: calendar).id)
    }

    func testDailyRotatesToNextDay() {
        let calendar = Calendar(identifier: .gregorian)
        let today = Date(timeIntervalSince1970: 1_700_000_000)
        let tomorrow = today.addingTimeInterval(24 * 3600)
        XCTAssertNotEqual(TalismanLibrary.daily(for: today, calendar: calendar).id,
                          TalismanLibrary.daily(for: tomorrow, calendar: calendar).id)
    }
}
