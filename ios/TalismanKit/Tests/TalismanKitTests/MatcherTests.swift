import XCTest
@testable import TalismanKit

final class MatcherTests: XCTestCase {
    private let config = MatchConfig()

    private func dense(_ pts: [Vec2], steps: Int = 8) -> [Vec2] {
        guard pts.count > 1 else { return pts }
        var out: [Vec2] = []
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            for s in 0..<steps {
                let t = Double(s) / Double(steps)
                out.append(Vec2(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
            }
        }
        out.append(pts[pts.count - 1])
        return out
    }

    private func transform(_ pts: [Vec2], _ f: (Vec2) -> Vec2) -> [Vec2] { pts.map(f) }

    func testResampleCountAndEndpoints() {
        let pts = dense([Vec2(x: 0, y: 0), Vec2(x: 1, y: 1)])
        let r = Resampler.resample(pts, count: 32)
        XCTAssertEqual(r.count, 32)
        XCTAssertEqual(r.first!.x, 0, accuracy: 1e-9)
        XCTAssertEqual(r.last!.y, 1, accuracy: 1e-9)
    }

    func testFrechetIdenticalIsZero() {
        let pts = dense(TalismanLibrary.qingxin.strokes[0])
        XCTAssertEqual(Frechet.distance(pts, pts), 0, accuracy: 1e-9)
    }

    func testPerfectStrokeScoresNearOne() {
        let t = TalismanLibrary.qingxin.strokes[0]
        let s = Matcher.score(user: dense(t), template: t, config: config)
        XCTAssertGreaterThan(s.total, 0.97)
    }

    func testReversedStrokeFails() {
        let t = TalismanLibrary.qingxin.strokes[0]
        let reversed = Array(t.reversed())
        let s = Matcher.score(user: dense(reversed), template: t, config: config)
        XCTAssertLessThan(s.total, config.passThreshold)
        XCTAssertGreaterThan(s.total, config.helpThreshold,
                             "诊断 fr=\(s.frechet) shape=\(s.shape) tan=\(s.tangent) ends=\(s.endpoints) total=\(s.total)")
    }

    func testTranslationFourPercentStillPasses() {
        let t = TalismanLibrary.qingxin.strokes[0]
        let shifted = transform(dense(t)) { Vec2(x: $0.x + 0.04, y: $0.y) }
        let s = Matcher.score(user: shifted, template: t, config: config)
        XCTAssertGreaterThan(s.total, config.passThreshold)
    }

    func testLargeScaleFails() {
        let t = TalismanLibrary.qingxin.strokes[0]
        let scaled = transform(dense(t)) { Vec2(x: 0.5 + ($0.x - 0.5) * 1.8, y: 0.5 + ($0.y - 0.5) * 1.8) }
        let s = Matcher.score(user: scaled, template: t, config: config)
        XCTAssertLessThan(s.total, config.passThreshold)
    }

    func testFarOffsetTriggersHelp() {
        let t = TalismanLibrary.qingxin.strokes[1]
        let shifted = transform(dense(t)) { Vec2(x: $0.x, y: $0.y + 0.16) }
        let s = Matcher.score(user: shifted, template: t, config: config)
        XCTAssertLessThan(s.total, config.helpThreshold)
    }

    func testSmallJitterPasses() {
        let t = TalismanLibrary.qingxin.strokes[0]
        var i = 0
        let jittered = transform(dense(t)) { p in
            i += 1
            let d = (Double(i % 5) - 2) / 500.0   // ±0.4%
            return Vec2(x: p.x + d, y: p.y)
        }
        let s = Matcher.score(user: jittered, template: t, config: config)
        XCTAssertGreaterThan(s.total, config.passThreshold)
    }

    func testStrokeCountMismatch() {
        let outcome = Matcher.evaluate(userStrokes: [dense(TalismanLibrary.qingxin.strokes[0])],
                                       talisman: TalismanLibrary.qingxin, config: config)
        XCTAssertEqual(outcome, .invalidStrokeCount(expected: 3, actual: 1))
    }

    func testSwappedStrokeOrderFails() {
        let tal = TalismanLibrary.qingxin
        let strokes = [dense(tal.strokes[1]), dense(tal.strokes[0]), dense(tal.strokes[2])]
        let outcome = Matcher.evaluate(userStrokes: strokes, talisman: tal, config: config)
        if case .passed = outcome { XCTFail("换序不该通过") }
    }

    func testFullTalismanPasses() {
        let tal = TalismanLibrary.juling
        let strokes = tal.strokes.map { dense($0) }
        let outcome = Matcher.evaluate(userStrokes: strokes, talisman: tal, config: config)
        guard case .passed(let avg) = outcome else { return XCTFail("整符应通过，实际 \(outcome)") }
        XCTAssertGreaterThan(avg, config.averageThreshold)
    }

    func testFrameMappingIsAffine() {
        let frame = TalismanFrame(centerX: 195, centerY: 400, size: 280)
        let center = frame.local(from: Vec2(x: 195, y: 400))
        XCTAssertEqual(center.x, 0.5, accuracy: 1e-9)
        XCTAssertEqual(center.y, 0.5, accuracy: 1e-9)
    }
}
