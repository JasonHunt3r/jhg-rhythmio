import XCTest
@testable import PaneKit

/// The pure stepping arithmetic behind `PaneListNavigation`'s arrow keys.
@MainActor
final class PaneListNavigationTests: XCTestCase {
    let order = ["a", "b", "c"]

    func testStepsForwardFromCurrent() {
        XCTAssertEqual(PaneListNavigation<String>.stepped("a", in: order, by: 1), "b")
    }

    func testStepsBackwardFromCurrent() {
        XCTAssertEqual(PaneListNavigation<String>.stepped("c", in: order, by: -1), "b")
    }

    /// An arrow held at either end stops there — it doesn't wrap around.
    func testClampsAtTheEnds() {
        XCTAssertEqual(PaneListNavigation<String>.stepped("c", in: order, by: 1), "c")
        XCTAssertEqual(PaneListNavigation<String>.stepped("a", in: order, by: -1), "a")
    }

    /// No selection yet starts from whichever end matches the direction
    /// pressed, not the middle or a fixed end regardless of direction.
    func testNoSelectionStartsFromTheEndMatchingDirection() {
        XCTAssertEqual(PaneListNavigation<String>.stepped(nil, in: order, by: 1), "a")
        XCTAssertEqual(PaneListNavigation<String>.stepped(nil, in: order, by: -1), "c")
    }

    /// A selection a fold just hid (no longer in `order`) is treated the
    /// same as no selection, not left stuck.
    func testSelectionNoLongerInOrderStartsFresh() {
        XCTAssertEqual(PaneListNavigation<String>.stepped("z", in: order, by: 1), "a")
    }

    func testEmptyOrderReturnsNil() {
        XCTAssertNil(PaneListNavigation<String>.stepped("a", in: [], by: 1))
    }

    // MARK: ← and →

    /// C (open) holds G (open, holding N) and S; D is folded.
    let tree = ["C", "G", "N", "S", "D"]
    let outline = PaneListOutline<String>(
        parent: { ["G": "C", "N": "G", "S": "C"][$0] },
        isExpanded: { ["C": true, "G": true, "D": false][$0] },
        setExpanded: { _, _, _ in })
    typealias Nav = PaneListNavigation<String>

    func testRightOpensAFoldedRow() {
        XCTAssertEqual(Nav.horizontal("D", right: true, recursive: false, in: tree, outline: outline),
                       .setExpanded("D", open: true, recursive: false))
    }
    func testRightOnAnOpenRowStepsToItsFirstChild() {
        XCTAssertEqual(Nav.horizontal("C", right: true, recursive: false, in: tree, outline: outline), .select("G"))
    }
    func testRightOnALeafDoesNothing() {
        XCTAssertEqual(Nav.horizontal("S", right: true, recursive: false, in: tree, outline: outline), .none)
    }
    func testOptionRightOpensEverythingUnderAnOpenRow() {
        XCTAssertEqual(Nav.horizontal("C", right: true, recursive: true, in: tree, outline: outline),
                       .setExpanded("C", open: true, recursive: true))
    }
    func testLeftFoldsAnOpenRow() {
        XCTAssertEqual(Nav.horizontal("G", right: false, recursive: false, in: tree, outline: outline),
                       .setExpanded("G", open: false, recursive: false))
    }
    func testLeftOnAChildStepsToItsParent() {
        XCTAssertEqual(Nav.horizontal("N", right: false, recursive: false, in: tree, outline: outline), .select("G"))
        XCTAssertEqual(Nav.horizontal("S", right: false, recursive: false, in: tree, outline: outline), .select("C"))
    }
    func testLeftOnAFoldedTopRowDoesNothing() {
        XCTAssertEqual(Nav.horizontal("D", right: false, recursive: false, in: tree, outline: outline), .none)
    }
    func testOptionLeftFoldsEverythingUnderEvenAFoldedRow() {
        XCTAssertEqual(Nav.horizontal("D", right: false, recursive: true, in: tree, outline: outline),
                       .setExpanded("D", open: false, recursive: true))
    }

    // MARK: Type-to-select

    let names = ["Library", "Stars", "Bars", "Shorty", "Straw"]
    let t0 = Date(timeIntervalSinceReferenceDate: 0)

    func testALetterSelectsTheFirstMatchFromTheTop() {
        var ts = PaneTypeSelect()
        XCTAssertEqual(ts.next("s", at: t0, selection: "Straw", order: names, title: { $0 }), "Stars")
    }
    func testTheSameLetterAgainStepsThroughMatchesAndWraps() {
        var ts = PaneTypeSelect()
        _ = ts.next("s", at: t0, selection: "Library", order: names, title: { $0 })
        XCTAssertEqual(ts.next("s", at: t0 + 0.3, selection: "Stars", order: names, title: { $0 }), "Shorty")
        XCTAssertEqual(ts.next("s", at: t0 + 0.6, selection: "Shorty", order: names, title: { $0 }), "Straw")
        XCTAssertEqual(ts.next("s", at: t0 + 0.9, selection: "Straw", order: names, title: { $0 }), "Stars")
    }
    func testLettersTypedTogetherBuildOneName() {
        var ts = PaneTypeSelect()
        _ = ts.next("s", at: t0, selection: nil, order: names, title: { $0 })
        _ = ts.next("t", at: t0 + 0.2, selection: "Stars", order: names, title: { $0 })
        XCTAssertEqual(ts.next("r", at: t0 + 0.4, selection: "Stars", order: names, title: { $0 }), "Straw")
    }
    func testAPauseStartsANewName() {
        var ts = PaneTypeSelect()
        _ = ts.next("s", at: t0, selection: nil, order: names, title: { $0 })
        XCTAssertEqual(ts.next("b", at: t0 + 2, selection: "Stars", order: names, title: { $0 }), "Bars")
    }
    func testMatchingIgnoresCase() {
        var ts = PaneTypeSelect()
        XCTAssertEqual(ts.next("L", at: t0, selection: nil, order: ["library"], title: { $0 }), "library")
    }
}
