import XCTest
import AppKit
@testable import PaneKit

/// The right-click item for a pane that can pop out (RhythmIO, 2026-10-03):
/// its wording follows the pane, and an AppKit view finds its pane through
/// whatever's nested between.
@MainActor
final class PaneWindowContextTests: XCTestCase {
    private func controller() -> PaneController {
        let suite = UserDefaults(suiteName: "PaneWindowContextTests-\(UUID().uuidString)")!
        return PaneController(id: "t", root: .split("s", .horizontal, sized: .second, size: 200, range: 100...300,
                                                    .pane("main"),
                                                    .pane("side", title: "Inspector", popOut: .panel)),
                              store: suite)
    }

    func testWordingFollowsThePane() {
        let c = controller()
        let ctx = PaneWindowContext(controller: c, paneID: "side", title: "Inspector")
        XCTAssertEqual(ctx.menuTitle, "Show Inspector in Own Window")
        ctx.toggle()
        XCTAssertTrue(c.isPoppedOut("side"))
        XCTAssertEqual(ctx.menuTitle, "Put Inspector Back in Main Window")
        XCTAssertEqual(ctx.menuItem().title, "Put Inspector Back in Main Window")
    }

    func testAViewFindsItsPaneThroughNestedViews() {
        let c = controller()
        let host = NSView(), middle = NSView(), leaf = NSView()
        host.addSubview(middle)
        middle.addSubview(leaf)
        PaneWindowContext.register(host, PaneWindowContext(controller: c, paneID: "side", title: "Inspector"))
        XCTAssertEqual(PaneWindowContext.of(leaf)?.paneID, "side")
        XCTAssertNil(PaneWindowContext.of(NSView()), "outside every pane: no item")
    }
}
