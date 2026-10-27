import XCTest
@testable import TalismanKit

final class QiTests: XCTestCase {
    func testNeutralBaseIsEighty() {
        let b = QiCalculator.settle(QiContext())
        XCTAssertEqual(b.total, 80)
        XCTAssertEqual(b.capFactor, 1.0)
    }

    func testShichenMultiplier() {
        let b = QiCalculator.settle(QiContext(shichenMultiplier: 1.6))
        XCTAssertEqual(b.total, 128)
    }

    func testFirstOfDayMultiplier() {
        let b = QiCalculator.settle(QiContext(isFirstOfDay: true))
        XCTAssertEqual(b.total, 120)
    }

    func testStreakBonusTiers() {
        XCTAssertEqual(QiCalculator.streakBonus(days: 3), 0)
        XCTAssertEqual(QiCalculator.streakBonus(days: 7), 0.05, accuracy: 1e-9)
        XCTAssertEqual(QiCalculator.streakBonus(days: 30), 0.10, accuracy: 1e-9)
        XCTAssertEqual(QiCalculator.streakBonus(days: 365), 0.15, accuracy: 1e-9)
    }

    func testPetResonance() {
        let b = QiCalculator.settle(QiContext(petResonance: true))
        XCTAssertEqual(b.total, 88)
    }

    func testCapTiers() {
        XCTAssertEqual(QiCalculator.capFactor(dailyEarned: 599), 1.0, accuracy: 1e-9)
        XCTAssertEqual(QiCalculator.capFactor(dailyEarned: 600), 0.60, accuracy: 1e-9)
        XCTAssertEqual(QiCalculator.capFactor(dailyEarned: 800), 0.25, accuracy: 1e-9)
        XCTAssertEqual(QiCalculator.capFactor(dailyEarned: 1000), 0.10, accuracy: 1e-9)
    }

    func testCapButNeverZero() {
        let b = QiCalculator.settle(QiContext(dailyEarned: 5000))
        XCTAssertGreaterThan(b.total, 0)
        XCTAssertEqual(b.total, 8)   // 80 * 0.10
    }

    func testFullStackComputation() {
        let b = QiCalculator.settle(QiContext(shichenMultiplier: 1.5, streakDays: 7,
                                              isFirstOfDay: false, petResonance: true, dailyEarned: 0))
        // 80 * 1.5 * 1.05 * 1.10 = 138.6 -> 139
        XCTAssertEqual(b.total, 139)
        XCTAssertEqual(b.uncapped, 139)
    }
}
