import XCTest
@testable import RhythmIOCore

/// Fade ▸ and a lane image's Duplicate (menus batch, 2026-10-03).
final class FadesTests: XCTestCase {
    func testEndsReadFromTheClip() {
        XCTAssertEqual(FadeEnds.of(fadeIn: 0.5, fadeOut: 0), .fadeIn)
        XCTAssertEqual(FadeEnds.of(fadeIn: 0, fadeOut: 0), .none)
        XCTAssertEqual(FadeEnds.of(fadeIn: 1, fadeOut: 2), .both)
    }

    func testTurningOnUsesTheSettingAndKeepsAnExistingLength() {
        let r = FadeEnds.both.apply(fadeIn: 0, fadeOut: 2, length: 1, clipLength: 10)
        XCTAssertEqual(r.fadeIn, 1, "newly on: the setting")
        XCTAssertEqual(r.fadeOut, 2, "already on: its own")
        let off = FadeEnds.fadeIn.apply(fadeIn: 0.5, fadeOut: 2, length: 1, clipLength: 10)
        XCTAssertEqual(off.fadeIn, 0.5)
        XCTAssertEqual(off.fadeOut, 0, "Out turned off")
        XCTAssertEqual(FadeEnds.none.apply(fadeIn: 1, fadeOut: 1, length: 1, clipLength: 10).fadeIn, 0)
    }

    func testFadesNeverOutlastTheClip() {
        let r = FadeEnds.both.apply(fadeIn: 0, fadeOut: 3, length: 1, clipLength: 2)
        XCTAssertEqual(r.fadeIn + r.fadeOut, 2, accuracy: 1e-9)
        XCTAssertEqual(r.fadeOut / r.fadeIn, 3, accuracy: 1e-9, "shared in proportion")
    }

    private func clip(_ start: Double, _ length: Double) -> OverlayClip {
        OverlayClip(itemID: 1, start: start, length: length)
    }

    func testDuplicateGoesRightAfter() throws {
        let a = clip(2, 3)
        let d = try XCTUnwrap(OverlayPlacement.duplicate(a, in: [a], duration: .infinity))
        XCTAssertEqual(d.start, 5)
        XCTAssertEqual(d.length, 3)
        XCTAssertNotEqual(d.id, a.id)
    }

    func testDuplicateSkipsToTheNextFreeSpaceAndIsCutShort() throws {
        let a = clip(0, 2), b = clip(2, 3), c = clip(6, 4)
        // Right after a is b; after b, 5…6 is free but only 1 s.
        let d = try XCTUnwrap(OverlayPlacement.duplicate(a, in: [a, b, c], duration: .infinity))
        XCTAssertEqual(d.start, 5)
        XCTAssertEqual(d.length, 1, "cut short by the next image")
        let tooSmall = clip(5, 0.9)
        let e = try XCTUnwrap(OverlayPlacement.duplicate(a, in: [a, b, tooSmall, c], duration: .infinity))
        XCTAssertEqual(e.start, 10, "past every image")
    }

    func testDuplicateWithNoRoomIsNil() {
        let a = clip(0, 2)
        XCTAssertNil(OverlayPlacement.duplicate(a, in: [a], duration: 2))
    }
}
