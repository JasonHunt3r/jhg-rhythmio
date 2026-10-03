import XCTest
@testable import RhythmIOCore

/// The key ladder (`spec/range-and-ruler.md`, "B-06: keyboard movement"; N2).
final class NudgeTests: XCTestCase {
    let g30 = FrameGrid(fps: 30), g24 = FrameGrid(fps: 24)

    private func seconds(_ m: NudgeMove) -> Double? { if case .by(let s) = m { s } else { nil } }

    func testTheDefaultLadder() throws {
        let n = NudgeSettings()
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.plain, direction: 1, grid: g30))), 1, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.option, direction: -1, grid: g30))), -1.0 / 30, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.shift, direction: 1, grid: g30))), 5, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.shiftOptionCommand, direction: -1, grid: g30))), -15, accuracy: 1e-9)
        XCTAssertEqual(n.move(.command, direction: 1, grid: g30), .nextMarker)
        XCTAssertEqual(n.move(.commandOption, direction: -1, grid: g30), .nextBeat)
    }

    /// Swapping the fine-step key swaps plain and ⌥ only; one frame stays
    /// on one of them.
    func testTheFineStepKeySwapsPlainAndOption() throws {
        var n = NudgeSettings()
        n.fineKey = .plainArrow
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.plain, direction: 1, grid: g24))), 1.0 / 24, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.option, direction: 1, grid: g24))), 1, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.shift, direction: 1, grid: g24))), 5, accuracy: 1e-9)
    }

    func testStepsInFramesFollowTheShowsRate() throws {
        var n = NudgeSettings()
        n.step = .init(12, .frames)
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.plain, direction: 1, grid: g24))), 0.5, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(seconds(n.move(.plain, direction: 1, grid: g30))), 0.4, accuracy: 1e-9)
    }

    func testAMoveLandsOnTheGridAndAlwaysMoves() {
        // Off the grid to start: lands on a frame.
        XCTAssertEqual(NudgeSettings.apply(1, to: 2.01, grid: g30, within: 0...100), 3, accuracy: 1e-9)
        // A step under half a frame still moves one frame.
        XCTAssertEqual(NudgeSettings.apply(0.001, to: 2, grid: g30, within: 0...100), 2 + 1.0 / 30, accuracy: 1e-9)
        XCTAssertEqual(NudgeSettings.apply(-0.001, to: 2, grid: g30, within: 0...100), 2 - 1.0 / 30, accuracy: 1e-9)
    }

    func testAMoveStopsAtTheEnds() {
        XCTAssertEqual(NudgeSettings.apply(-5, to: 2, grid: g30, within: 0...100), 0)
        XCTAssertEqual(NudgeSettings.apply(15, to: 95, grid: g30, within: 0...100), 100)
    }

    /// Several markers move together and keep their spacing at an end.
    func testAGroupKeepsItsSpacing() {
        let moved = NudgeSettings.apply(5, to: [10, 12, 98], grid: g30, within: 0...100)
        XCTAssertEqual(moved, [12, 14, 100])
        let back = NudgeSettings.apply(-1, to: [10, 12], grid: g30, within: 0...100)
        XCTAssertEqual(back, [9, 11])
    }

    func testSavedSettingsReadBackAndUnreadableFieldsFallBackAlone() throws {
        var n = NudgeSettings()
        n.step = .init(10, .frames); n.fineKey = .plainArrow; n.mergeTolerance = 3
        let back = try JSONDecoder().decode(NudgeSettings.self, from: JSONEncoder().encode(n))
        XCTAssertEqual(back, n)
        let odd = try JSONDecoder().decode(NudgeSettings.self,
                                           from: Data(#"{"fineKey":"thumb","mergeTolerance":0,"shiftStep":{"value":2,"unit":"seconds"}}"#.utf8))
        XCTAssertEqual(odd.fineKey, .option)
        XCTAssertEqual(odd.mergeTolerance, 1)
        XCTAssertEqual(odd.shiftStep, .init(2, .seconds))
        XCTAssertEqual(NudgeSettings.defaultMergeTolerance, 5)
    }
}

/// Markers of both kinds nudged together (N2).
final class MarkerNudgeTests: XCTestCase {
    func testHandAndBeatMarkersMoveTogetherInShowTime() throws {
        var clip = AudioClip(itemID: 1, start: 10, length: 30)
        clip.inPoint = 4
        let beat = Marker(time: 6)          // song time 6 → show time 12
        clip.markers = [beat]
        let hand = Marker(time: 11)
        let show = Show(id: 1, name: "s", music: [clip], markers: [hand])
        let grid = FrameGrid(fps: 30)
        XCTAssertEqual(show.markerTimes([beat.id, hand.id]).map(\.time), [11, 12])
        let moved = try XCTUnwrap(show.nudgingMarkers([beat.id, hand.id], by: 1, grid: grid, duration: 60))
        XCTAssertEqual(moved.markers[0].time, 12, accuracy: 1e-9)
        XCTAssertEqual(moved.music[0].markers[0].time, 7, accuracy: 1e-9)   // song time
        XCTAssertEqual(moved.markerTimes([beat.id]).first?.time ?? 0, 13, accuracy: 1e-9)
    }

    func testNothingMovesPastTheEndOrWithNothingSelected() {
        let m = Marker(time: 60)
        let show = Show(id: 1, name: "s", markers: [m])
        XCTAssertNil(show.nudgingMarkers([m.id], by: 1, grid: FrameGrid(fps: 30), duration: 60))
        XCTAssertNil(show.nudgingMarkers([], by: 1, grid: FrameGrid(fps: 30), duration: 60))
    }
}
