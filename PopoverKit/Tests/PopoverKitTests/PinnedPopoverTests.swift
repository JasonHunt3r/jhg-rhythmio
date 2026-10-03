import AppKit
import SwiftUI
import XCTest
@testable import PopoverKit

/// The behaviours `PinnedPopover` exists for (spec/popoverkit.md), in a
/// real window: more than one open, content swapped in place, click-through.
@MainActor
final class PinnedPopoverTests: XCTestCase {
    private var window: NSWindow!
    private var a: NSView!
    private var b: NSView!

    override func setUp() async throws {
        window = NSWindow(contentRect: NSRect(x: 200, y: 200, width: 600, height: 200),
                          styleMask: [.titled], backing: .buffered, defer: false)
        a = NSView(frame: NSRect(x: 40, y: 40, width: 120, height: 40))
        b = NSView(frame: NSRect(x: 400, y: 40, width: 120, height: 40))
        window.contentView!.addSubview(a)
        window.contentView!.addSubview(b)
        window.orderFront(nil)
    }

    override func tearDown() async throws {
        window.orderOut(nil)
        window = nil
    }

    func testTwoStayOpenTogether() {
        let p1 = PinnedPopover(), p2 = PinnedPopover()
        p1.animates = false; p2.animates = false
        p1.show(Text("one"), anchor: a)
        p2.show(Text("two"), anchor: b)
        XCTAssertTrue(p1.isShown)
        XCTAssertTrue(p2.isShown, "a second doesn't close the first")
        p1.close(); p2.close()
        XCTAssertFalse(p1.isShown)
    }

    func testUpdateKeepsItOpenAndShowElsewhereMovesIt() {
        let p = PinnedPopover()
        p.animates = false
        p.show(Text("one"), anchor: a)
        p.update(Text("changed"))
        XCTAssertTrue(p.isShown)
        p.show(Text("on b"), anchor: b)
        XCTAssertTrue(p.isShown, "moved to another view, still open")
        p.close()
    }

    func testClickThroughSetsTheWindowAndFollowsChanges() throws {
        let p = PinnedPopover()
        p.animates = false
        p.passesClicksThrough = true
        p.show(Text("hover"), anchor: a)
        let popWindow = try XCTUnwrap(window.childWindows?.first)
        XCTAssertTrue(popWindow.ignoresMouseEvents)
        p.passesClicksThrough = false
        XCTAssertFalse(popWindow.ignoresMouseEvents)
        p.close()
    }

    func testEdges() {
        XCTAssertEqual(PinnedPopoverAnchor<Text>.rectEdge(.top), .maxY)
        XCTAssertEqual(PinnedPopoverAnchor<Text>.rectEdge(.bottom), .minY)
    }
}
