import XCTest
@testable import ListKit

/// The pure stepping arithmetic behind `ListNavigation`'s arrow keys.
@MainActor
final class ListNavigationTests: XCTestCase {
    let order = ["a", "b", "c"]

    func testStepsForwardFromCurrent() {
        XCTAssertEqual(ListNavigation<String>.stepped("a", in: order, by: 1), "b")
    }

    func testStepsBackwardFromCurrent() {
        XCTAssertEqual(ListNavigation<String>.stepped("c", in: order, by: -1), "b")
    }

    /// An arrow held at either end stops there — it doesn't wrap around.
    func testClampsAtTheEnds() {
        XCTAssertEqual(ListNavigation<String>.stepped("c", in: order, by: 1), "c")
        XCTAssertEqual(ListNavigation<String>.stepped("a", in: order, by: -1), "a")
    }

    /// No selection yet starts from whichever end matches the direction
    /// pressed, not the middle or a fixed end regardless of direction.
    func testNoSelectionStartsFromTheEndMatchingDirection() {
        XCTAssertEqual(ListNavigation<String>.stepped(nil, in: order, by: 1), "a")
        XCTAssertEqual(ListNavigation<String>.stepped(nil, in: order, by: -1), "c")
    }

    /// A selection a fold just hid (no longer in `order`) is treated the
    /// same as no selection, not left stuck.
    func testSelectionNoLongerInOrderStartsFresh() {
        XCTAssertEqual(ListNavigation<String>.stepped("z", in: order, by: 1), "a")
    }

    func testEmptyOrderReturnsNil() {
        XCTAssertNil(ListNavigation<String>.stepped("a", in: [], by: 1))
    }

    // MARK: ← and →

    /// C (open) holds G (open, holding N) and S; D is folded.
    let tree = ["C", "G", "N", "S", "D"]
    let outline = ListOutline<String>(
        parent: { ["G": "C", "N": "G", "S": "C"][$0] },
        isExpanded: { ["C": true, "G": true, "D": false][$0] },
        setExpanded: { _, _, _ in })
    typealias Nav = ListNavigation<String>

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
        var ts = TypeSelect()
        XCTAssertEqual(ts.next("s", at: t0, selection: "Straw", order: names, title: { $0 }), "Stars")
    }
    func testTheSameLetterAgainStepsThroughMatchesAndWraps() {
        var ts = TypeSelect()
        _ = ts.next("s", at: t0, selection: "Library", order: names, title: { $0 })
        XCTAssertEqual(ts.next("s", at: t0 + 0.3, selection: "Stars", order: names, title: { $0 }), "Shorty")
        XCTAssertEqual(ts.next("s", at: t0 + 0.6, selection: "Shorty", order: names, title: { $0 }), "Straw")
        XCTAssertEqual(ts.next("s", at: t0 + 0.9, selection: "Straw", order: names, title: { $0 }), "Stars")
    }
    func testLettersTypedTogetherBuildOneName() {
        var ts = TypeSelect()
        _ = ts.next("s", at: t0, selection: nil, order: names, title: { $0 })
        _ = ts.next("t", at: t0 + 0.2, selection: "Stars", order: names, title: { $0 })
        XCTAssertEqual(ts.next("r", at: t0 + 0.4, selection: "Stars", order: names, title: { $0 }), "Straw")
    }
    func testAPauseStartsANewName() {
        var ts = TypeSelect()
        _ = ts.next("s", at: t0, selection: nil, order: names, title: { $0 })
        XCTAssertEqual(ts.next("b", at: t0 + 2, selection: "Stars", order: names, title: { $0 }), "Bars")
    }
    func testMatchingIgnoresCase() {
        var ts = TypeSelect()
        XCTAssertEqual(ts.next("L", at: t0, selection: nil, order: ["library"], title: { $0 }), "library")
    }

    // MARK: Several at once

    let rows = ["a", "b", "c", "d", "e"]

    func testAPlainClickPicksJustThatRow() {
        let r = Nav.clicked("c", command: false, shift: false, selection: ["a", "b"], anchor: "a", in: rows)
        XCTAssertEqual(r.selection, ["c"]); XCTAssertEqual(r.anchor, "c"); XCTAssertEqual(r.lead, "c")
    }
    func testACommandClickAddsOrRemovesOneRow() {
        XCTAssertEqual(Nav.clicked("c", command: true, shift: false, selection: ["a"], anchor: "a", in: rows).selection,
                       ["a", "c"])
        XCTAssertEqual(Nav.clicked("a", command: true, shift: false, selection: ["a", "c"], anchor: "c", in: rows).selection,
                       ["c"])
    }
    func testAShiftClickPicksTheRangeFromTheAnchorEitherWay() {
        let down = Nav.clicked("d", command: false, shift: true, selection: ["b"], anchor: "b", in: rows)
        XCTAssertEqual(down.selection, ["b", "c", "d"]); XCTAssertEqual(down.anchor, "b"); XCTAssertEqual(down.lead, "d")
        XCTAssertEqual(Nav.clicked("a", command: false, shift: true, selection: ["c"], anchor: "c", in: rows).selection,
                       ["a", "b", "c"])
    }
    func testAShiftClickWithNoAnchorIsAPlainClick() {
        XCTAssertEqual(Nav.clicked("d", command: false, shift: true, selection: [], anchor: nil, in: rows).selection, ["d"])
    }
    func testARangeIsInListOrder() {
        XCTAssertEqual(Nav.range("e", "c", in: rows), ["c", "d", "e"])
        XCTAssertEqual(Nav.range("x", "c", in: rows), ["c"])
    }
}
