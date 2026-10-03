import Foundation

/// A show's frame grid (`spec/range-and-ruler.md`, "Timecode as the model"):
/// times stay seconds, snapped to whole frames of the show's frame rate,
/// and read as `m:ss:ff` — a colon before the frames, as in timecode, since
/// a dot reads as decimal seconds. Stored as seconds, so changing the rate
/// later moves nothing; the frames are derived for display.
public struct FrameGrid: Hashable, Sendable {
    public let fps: Int

    public init(fps: Int) { self.fps = max(fps, 1) }
    public init(_ rate: MovieFrameRate) { self.init(fps: rate.fps) }

    /// One frame, in seconds.
    public var frameLength: Double { 1 / Double(fps) }

    /// The nearest whole frame to a time.
    public func frame(_ seconds: Double) -> Int { Int((seconds * Double(fps)).rounded()) }

    public func seconds(_ frame: Int) -> Double { Double(frame) / Double(fps) }

    /// A time moved onto the grid.
    public func snap(_ seconds: Double) -> Double { self.seconds(frame(seconds)) }

    /// `m:ss:ff`. Negative times (which nothing on the timeline has) read
    /// as zero.
    public func format(_ seconds: Double) -> String {
        let (m, s, f) = parts(max(frame(seconds), 0))
        return "\(m):\(pad(s)):\(pad(f))"
    }

    /// A move, signed, as the nudge readout shows it: `+1:00` (one second),
    /// `−0:03` (three frames), and `+1:05:00` past a minute. Always a sign,
    /// a true minus.
    public func formatDelta(_ seconds: Double) -> String {
        let total = frame(seconds)
        let sign = total < 0 ? "−" : "+"
        let (m, s, f) = parts(abs(total))
        return m > 0 ? "\(sign)\(m):\(pad(s)):\(pad(f))" : "\(sign)\(s):\(pad(f))"
    }

    /// Typed timecode, frame-aligned, or nil when it can't be read
    /// (`spec/range-and-ruler.md`, B-11): `m:ss:ff`; `m:ss` (`1:23`);
    /// plain seconds (`83`, `83.5`); or a frame count with an `f` (`2490f`).
    /// Out-of-range parts (`1:75`, a frame past the rate) are nil, never
    /// clamped: the field shows it's wrong instead.
    public func parse(_ text: String) -> Double? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !t.hasPrefix("-"), !t.hasPrefix("−") else { return nil }
        if t.hasSuffix("f") || t.hasSuffix("F") {
            guard let n = Int(t.dropLast()), n >= 0 else { return nil }
            return seconds(n)
        }
        let fields = t.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        switch fields.count {
        case 1:
            guard let s = Double(fields[0]), s.isFinite, s >= 0 else { return nil }
            return snap(s)
        case 2:
            guard let m = Int(fields[0]), let s = Double(fields[1]), m >= 0, s >= 0, s < 60 else { return nil }
            return snap(Double(m * 60) + s)
        case 3:
            guard let m = Int(fields[0]), let s = Int(fields[1]), let f = Int(fields[2]),
                  m >= 0, (0..<60).contains(s), (0..<fps).contains(f) else { return nil }
            return seconds((m * 60 + s) * fps + f)
        default:
            return nil
        }
    }

    private func parts(_ frames: Int) -> (Int, Int, Int) {
        let f = frames % fps, totalSeconds = frames / fps
        return (totalSeconds / 60, totalSeconds % 60, f)
    }

    private func pad(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
}

extension Show {
    /// This show's frame grid, from its frame rate.
    public var frameGrid: FrameGrid { FrameGrid(defaults.frameRate) }
}
