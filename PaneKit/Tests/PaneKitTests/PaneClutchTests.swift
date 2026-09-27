import XCTest
import CoreGraphics
@testable import PaneKit

/// The clutch (`PaneClutch`, Jason 2026-09-26): bite, slip, engage; and
/// the peek the layout draws while a drawer slides.
@MainActor
final class PaneClutchTests: XCTestCase {
    func testPulledFromClosedItBitesThenSlips() {
        XCTAssertEqual(PaneClutch.opening(pull: -5), 0, "never past closed")
        XCTAssertEqual(PaneClutch.opening(pull: 10), 10, "the bite: one to one")
        XCTAssertEqual(PaneClutch.opening(pull: PaneClutch.bite), PaneClutch.bite)
        let far = PaneClutch.opening(pull: PaneClutch.bite + 40)
        XCTAssertEqual(far, PaneClutch.bite + 40 * PaneClutch.slip, accuracy: 0.001, "the slip lags the pointer")
        XCTAssertLessThan(far, PaneClutch.bite + 40)
    }

    /// A literal distance: every drawer engages at the same pull.
    func testItEngagesAtTheSamePullWhateverItsSize() {
        XCTAssertEqual(PaneClutch.engageDistance(opensTo: 120), PaneClutch.engage)
        XCTAssertEqual(PaneClutch.engageDistance(opensTo: 900), PaneClutch.engage)
    }

    func testPushedPastItsMinimumItResistsThenShuts() {
        XCTAssertEqual(PaneClutch.closing(fromEdge: 200, minimum: 120), 200, "above the minimum: as usual")
        XCTAssertEqual(PaneClutch.closing(fromEdge: 100, minimum: 120), 120 - 20 * PaneClutch.slip, accuracy: 0.001)
        XCTAssertFalse(PaneClutch.shuts(fromEdge: 120 - PaneClutch.closeEngage + 1, minimum: 120))
        XCTAssertTrue(PaneClutch.shuts(fromEdge: 120 - PaneClutch.closeEngage, minimum: 120))
    }

    let drawer: PaneNode = .split("viewer", .vertical, sized: .first, size: 280, range: 120...600,
                                  handle: .external,
                                  .pane("viewer", title: "Viewer"),
                                  .pane("list", title: "List", minSize: 100))
    let rect = CGRect(x: 0, y: 0, width: 400, height: 800)

    /// A closed drawer peeking: drawn at the peek, under its minimum, with
    /// a divider; the rest keeps the remainder.
    func testAPeekDrawsAClosedDrawerPartOpenBelowItsMinimum() {
        var s = PaneKitState()
        s.splits["viewer"] = SplitState(collapsed: true)
        let r = PaneLayout.layout(drawer, in: rect, state: s, peek: ["viewer": 30])
        XCTAssertEqual(r.panes["viewer"], CGRect(x: 0, y: 0, width: 400, height: 30))
        XCTAssertNotNil(r.dividers["viewer"])
        XCTAssertEqual(r.panes["list"], CGRect(x: 0, y: 31, width: 400, height: 769))
    }

    func testAPeekOfZeroIsClosedAndNeverCrowdsTheMainSide() {
        let shut = PaneLayout.layout(drawer, in: rect, state: PaneKitState(), peek: ["viewer": 0])
        XCTAssertNil(shut.panes["viewer"].flatMap { $0.height > 0 ? $0 : nil })
        XCTAssertNil(shut.dividers["viewer"])
        let huge = PaneLayout.layout(drawer, in: rect, state: PaneKitState(), peek: ["viewer": 5000])
        XCTAssertEqual(huge.panes["list"]?.height, 100, "the main side keeps its minimum")
    }
}
