import XCTest
@testable import TalismanKit

final class TitleTests: XCTestCase {
    func testBoundaries() {
        XCTAssertEqual(Title.forStreak(0), .fanren)
        XCTAssertEqual(Title.forStreak(2), .fanren)
        XCTAssertEqual(Title.forStreak(3), .lianqi)
        XCTAssertEqual(Title.forStreak(6), .lianqi)
        XCTAssertEqual(Title.forStreak(7), .zhuji)
        XCTAssertEqual(Title.forStreak(30), .jindan)
        XCTAssertEqual(Title.forStreak(60), .yuanying)
        XCTAssertEqual(Title.forStreak(100), .huashen)
        XCTAssertEqual(Title.forStreak(180), .dujie)
        XCTAssertEqual(Title.forStreak(365), .dacheng)
    }

    func testRawValueIsDisplayText() {
        XCTAssertEqual(Title.zhuji.rawValue, "筑基")
    }
}
