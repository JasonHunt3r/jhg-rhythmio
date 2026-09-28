import XCTest
@testable import PaneKit

/// The pure stepping arithmetic behind `PaneListNavigation`'s arrow keys.
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
}
