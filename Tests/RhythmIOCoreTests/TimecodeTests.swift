import XCTest
@testable import RhythmIOCore

/// The frame grid and timecode (`spec/range-and-ruler.md`, "Timecode as the
/// model"; N1).
final class TimecodeTests: XCTestCase {
    let g30 = FrameGrid(fps: 30), g24 = FrameGrid(fps: 24), g60 = FrameGrid(fps: 60)

    func testFormatIsMinutesSecondsFrames() {
        XCTAssertEqual(g30.format(0), "0:00:00")
        XCTAssertEqual(g30.format(83.5), "1:23:15")
        XCTAssertEqual(g24.format(83.5), "1:23:12")
        XCTAssertEqual(g60.format(3599.95), "59:59:57")
        XCTAssertEqual(g30.format(-2), "0:00:00")
    }

    func testSnapGoesToTheNearestFrame() {
        XCTAssertEqual(g30.snap(1.01), 1, accuracy: 1e-9)
        XCTAssertEqual(g30.snap(1.02), 31.0 / 30, accuracy: 1e-9)
        XCTAssertEqual(g24.frame(1.0), 24)
    }

    /// Jason's examples: +1:00 is a second, −0:03 three frames.
    func testDeltasAreSignedAndShortUnderAMinute() {
        XCTAssertEqual(g30.formatDelta(1), "+1:00")
        XCTAssertEqual(g30.formatDelta(-0.1), "−0:03")
        XCTAssertEqual(g30.formatDelta(0), "+0:00")
        XCTAssertEqual(g30.formatDelta(65), "+1:05:00")
    }

    /// `83` and `1:23` are the same time; `2490f` is a frame count.
    func testLooseInputParses() throws {
        XCTAssertEqual(try XCTUnwrap(g30.parse("83")), 83, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(g30.parse("1:23")), 83, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(g30.parse("1:23:15")), 83.5, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(g30.parse(" 83.5 ")), 83.5, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(g30.parse("2490f")), 83, accuracy: 1e-9)
        // Off-grid seconds land on a frame.
        XCTAssertEqual(try XCTUnwrap(g30.parse("1.01")), 1, accuracy: 1e-9)
    }

    /// Wrong input is nil, never clamped (the field turns red instead).
    func testBadInputIsNil() {
        for bad in ["", "abc", "-1", "−1", "1:60", "1:00:30", "1:2:3:4", "f", "1:xx", "nan"] {
            XCTAssertNil(g30.parse(bad), bad)
        }
        XCTAssertNotNil(g60.parse("1:00:30"))
    }

    /// Formatting and parsing agree for every frame of a few seconds.
    func testFormatReadsBack() throws {
        for g in [g24, g30, g60] {
            for f in stride(from: 0, through: g.fps * 125, by: 7) {
                let t = g.seconds(f)
                XCTAssertEqual(try XCTUnwrap(g.parse(g.format(t))), t, accuracy: 1e-9)
            }
        }
    }

    /// A show saved before the frame rate existed reads as 30, what the
    /// playhead's nudge always used; an unreadable one falls back alone.
    func testOlderShowsReadAsThirty() throws {
        let old = try JSONDecoder().decode(ShowDefaults.self, from: Data(#"{"length":4}"#.utf8))
        XCTAssertEqual(old.frameRate, .fps30)
        XCTAssertEqual(old.length, 4)
        let odd = try JSONDecoder().decode(ShowDefaults.self, from: Data(#"{"length":4,"frameRate":25}"#.utf8))
        XCTAssertEqual(odd.frameRate, .fps30)
        XCTAssertEqual(odd.length, 4)
        var d = ShowDefaults()
        d.frameRate = .fps24
        let back = try JSONDecoder().decode(ShowDefaults.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(back.frameRate, .fps24)
    }

    /// show.tsv carries it as `# frame_rate`.
    func testTheSetlistTableCarriesTheFrameRate() {
        var problems: [String] = []
        let d = SetlistImport.mergeDefaults(ShowDefaults(), ["frame_rate": "60"], problems: &problems)
        XCTAssertEqual(d.frameRate, .fps60)
        XCTAssertTrue(problems.isEmpty)
        let bad = SetlistImport.mergeDefaults(ShowDefaults(), ["frame_rate": "25"], problems: &problems)
        XCTAssertEqual(bad.frameRate, .fps30)
        XCTAssertEqual(problems.count, 1)
    }
}
