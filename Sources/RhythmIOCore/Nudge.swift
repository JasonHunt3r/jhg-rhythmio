import Foundation

/// Moving things on the timeline from the keyboard (`spec/range-and-ruler.md`,
/// "B-06: keyboard movement"): one key ladder for the playhead, range ends
/// and markers, set in Settings ▸ Timeline ▸ Nudge.
public struct NudgeSettings: Codable, Hashable, Sendable {
    /// A step's size: a value in seconds or in frames of the show's rate.
    public struct Step: Codable, Hashable, Sendable {
        public enum Unit: String, Codable, CaseIterable, Sendable {
            case seconds, frames
            public var title: String { self == .seconds ? "seconds" : "frames" }
        }
        public var value: Double
        public var unit: Unit

        public init(_ value: Double, _ unit: Unit) { self.value = value; self.unit = unit }

        public func seconds(in grid: FrameGrid) -> Double {
            unit == .frames ? Double(max(Int(value.rounded()), 1)) * grid.frameLength : max(value, 0)
        }
    }

    /// Which key gives the one-frame step: with `.option`, ← → moves `step`
    /// and ⌥ ← → one frame; with `.plainArrow`, the other way round. ⇧ and
    /// ⇧⌥⌘ are unaffected, and one frame is always on one of the two.
    public enum FineKey: String, Codable, CaseIterable, Sendable {
        case option, plainArrow
    }

    /// ← → (or ⌥ ← →, by `fineKey`).
    public var step = Step(1, .seconds)
    /// ⇧ ← →.
    public var shiftStep = Step(5, .seconds)
    /// ⇧⌥⌘ ← →.
    public var bigStep = Step(15, .seconds)
    public var fineKey: FineKey = .option
    /// Two markers of a type closer than this, in frames, collide ("Marker
    /// collisions"). Jason tunes the default while testing: this constant.
    public static let defaultMergeTolerance = 5
    public var mergeTolerance = NudgeSettings.defaultMergeTolerance {
        didSet { mergeTolerance = max(mergeTolerance, 1) }
    }

    public init() {}

    /// Field by field, like every saved type.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func get<T: Decodable>(_ k: CodingKeys, _ fallback: T) -> T {
            ((try? c.decodeIfPresent(T.self, forKey: k)) ?? nil) ?? fallback
        }
        let d = NudgeSettings()
        step = get(.step, d.step)
        shiftStep = get(.shiftStep, d.shiftStep)
        bigStep = get(.bigStep, d.bigStep)
        fineKey = get(.fineKey, d.fineKey)
        mergeTolerance = max(get(.mergeTolerance, d.mergeTolerance), 1)
    }
}

/// The modifier combinations the ladder answers to with ← →.
public enum NudgeKey: Hashable, Sendable {
    case plain, option, shift, shiftOptionCommand, command, commandOption
}

/// What one press asks for.
public enum NudgeMove: Equatable, Sendable {
    /// Move by this many seconds (signed).
    case by(Double)
    /// ⌘: to the next marker that way.
    case nextMarker
    /// ⌘⌥: to the next detected beat that way.
    case nextBeat
}

extension NudgeSettings {
    /// The move for a key, ← (`direction` −1) or → (+1).
    public func move(_ key: NudgeKey, direction: Int, grid: FrameGrid) -> NudgeMove {
        let sign = Double(direction < 0 ? -1 : 1)
        let oneFrame = grid.frameLength
        switch key {
        case .plain: return .by(sign * (fineKey == .option ? step.seconds(in: grid) : oneFrame))
        case .option: return .by(sign * (fineKey == .option ? oneFrame : step.seconds(in: grid)))
        case .shift: return .by(sign * shiftStep.seconds(in: grid))
        case .shiftOptionCommand: return .by(sign * bigStep.seconds(in: grid))
        case .command: return .nextMarker
        case .commandOption: return .nextBeat
        }
    }

    /// A time moved by `delta`, onto the frame grid, at least one frame
    /// that way (a step smaller than a frame still moves), and inside
    /// `limits`.
    public static func apply(_ delta: Double, to t: Double, grid: FrameGrid,
                             within limits: ClosedRange<Double>) -> Double {
        guard delta != 0 else { return t }
        var f = grid.frame(t + delta)
        let from = grid.frame(t)
        if f == from { f += delta > 0 ? 1 : -1 }
        return min(max(grid.seconds(f), limits.lowerBound), limits.upperBound)
    }

    /// Several times moved together by the same amount: the first one
    /// (the one the selection steps from) sets the move, and the group
    /// stops at `limits` as a whole, so the spacing between them stays.
    public static func apply(_ delta: Double, to times: [Double], grid: FrameGrid,
                             within limits: ClosedRange<Double>) -> [Double] {
        guard let first = times.first, let lo = times.min(), let hi = times.max() else { return times }
        let unclamped = apply(delta, to: first, grid: grid,
                              within: -Double.greatestFiniteMagnitude...Double.greatestFiniteMagnitude) - first
        let move = min(max(unclamped, limits.lowerBound - lo), limits.upperBound - hi)
        return times.map { $0 + move }
    }
}

extension Show {
    /// Markers of either kind by id, at their show times, earliest first.
    public func markerTimes(_ ids: Set<UUID>) -> [(id: UUID, time: Double)] {
        let hand = markers.filter { ids.contains($0.id) }.map { ($0.id, $0.time) }
        let detected = music.flatMap { c in
            c.markers.filter { ids.contains($0.id) }.map { ($0.id, c.showTime(ofSongTime: $0.time)) }
        }
        return (hand + detected).sorted { $0.1 < $1.1 }.map { (id: $0.0, time: $0.1) }
    }

    /// The markers moved together by one press (`NudgeSettings.apply`): the
    /// earliest lands on the frame grid, the rest keep their spacing, and
    /// the group stays inside 0…`duration`. Nil when nothing moved.
    public func nudgingMarkers(_ ids: Set<UUID>, by delta: Double, grid: FrameGrid,
                               duration: Double) -> Show? {
        let now = markerTimes(ids)
        guard !now.isEmpty else { return nil }
        let moved = NudgeSettings.apply(delta, to: now.map(\.time), grid: grid, within: 0...max(duration, 0))
        guard moved != now.map(\.time) else { return nil }
        var s = self
        for (m, t) in zip(now, moved) {
            let change = t - m.time
            s.updateMarker(m.id) { $0.time += change }
        }
        return s
    }
}
