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

/// A range end, as the ruler selects it (N3).
public enum RangeEnd: Hashable, Sendable {
    case rangeIn, rangeOut
}

extension ShowEditorState {
    /// One end of the range moved by one press, onto the frame grid
    /// (`spec/range-and-ruler.md`, "Constraints"): the range stays at least
    /// one frame long, an end pushed into the other stops there and never
    /// swaps, and nothing goes below 0 or past `end` (the show's duration;
    /// N6 lets the range run past it). Nil when it can't move: locked, no
    /// such end, or already at the limit.
    public func nudgingRange(_ which: RangeEnd, by delta: Double, grid: FrameGrid,
                             end: Double) -> ShowEditorState? {
        guard !rangeLocked else { return nil }
        let frame = grid.frameLength
        var e = self
        switch which {
        case .rangeIn:
            guard let t = rangeIn else { return nil }
            let hi = (rangeOut.map { $0 - frame } ?? end)
            let moved = NudgeSettings.apply(delta, to: t, grid: grid, within: 0...max(hi, 0))
            guard moved != t else { return nil }
            e.rangeIn = moved
        case .rangeOut:
            guard let t = rangeOut else { return nil }
            let lo = (rangeIn.map { $0 + frame } ?? 0)
            let moved = NudgeSettings.apply(delta, to: t, grid: grid, within: min(lo, end)...end)
            guard moved != t else { return nil }
            e.rangeOut = moved
        }
        return e
    }

    public func time(of which: RangeEnd) -> Double? { which == .rangeIn ? rangeIn : rangeOut }
}

// MARK: ⌘ and ⌘⌥ jumps (N4)

/// "The next one that way" for the jumps (`spec/range-and-ruler.md`, "⌘
/// and ⌘⌥ jumps"): from between targets, the next in the arrow's
/// direction; one already within `within` of `t` doesn't count (it's
/// where you are); nil past the first or last (no wrapping).
public enum Jump {
    public static func next(from t: Double, direction: Int, in targets: [Double],
                            within: Double = 1e-6) -> Double? {
        direction > 0 ? targets.filter { $0 > t + within }.min()
                      : targets.filter { $0 < t - within }.max()
    }
}

extension Show {
    /// Every marker on the ruler, of both kinds (a detected marker only
    /// where its clip shows it), at its show time, with its id, earliest first.
    public var rulerMarkers: [(id: UUID, time: Double, isBeat: Bool)] {
        let hand = markers.map { (id: $0.id, time: $0.time, isBeat: false) }
        let beat = detectedMarkers.map { (id: $0.marker.id, time: $0.time, isBeat: true) }
        return (hand + beat).sorted { $0.time < $1.time }
    }

    /// Every detected beat of every audio clip, in show time, inside the
    /// part of the clip that plays, earliest first. `rhythms` by the clip's
    /// file id; a song not analysed yet has none.
    public func beatTimes(_ rhythms: [Int64: SongRhythm]) -> [Double] {
        music.flatMap { c -> [Double] in
            guard let r = rhythms[c.itemID] else { return [] }
            return r.beats.filter { $0 >= c.inPoint - 1e-9 && $0 <= c.inPoint + c.length + 1e-9 }
                .map { c.showTime(ofSongTime: $0) }
        }
        .sorted()
    }

    /// ⌘⌥ on selected markers: the next beat that way from the earliest of
    /// them, skipping beats a marker of the same kind already holds (one
    /// of these selected ones doesn't count), and the markers moved
    /// together so the earliest lands on it. Nil when there's no such beat.
    /// "Holds" uses the collision rule, so the move never lands in a
    /// collision (`tolerance` in frames; 1 is the same frame only).
    public func movingMarkersToNextBeat(_ ids: Set<UUID>, direction: Int, beats: [Double],
                                        duration: Double, grid: FrameGrid, tolerance: Int = 1) -> Show? {
        let selected = rulerMarkers.filter { ids.contains($0.id) }
        guard let anchor = selected.first else { return nil }
        let half = grid.frameLength / 2
        let others = rulerMarkers.filter { !ids.contains($0.id) && $0.isBeat == anchor.isBeat }.map(\.time)
        let free = beats.filter { b in !others.contains { grid.collide($0, b, tolerance: tolerance) } }
        guard let beat = Jump.next(from: anchor.time, direction: direction, in: free, within: half)
        else { return nil }
        let move = beat - anchor.time
        guard selected.allSatisfy({ $0.time + move >= -1e-9 && $0.time + move <= duration + 1e-9 }) else { return nil }
        var s = self
        for m in selected { s.updateMarker(m.id) { $0.time += move } }
        return s
    }
}

// MARK: Marker collisions (N5)

extension FrameGrid {
    /// Two times collide when they're fewer than `tolerance` frames apart
    /// (`spec/range-and-ruler.md`, "Marker collisions"): at 1, only the same
    /// frame.
    public func collide(_ a: Double, _ b: Double, tolerance: Int) -> Bool {
        abs(frame(a) - frame(b)) < max(tolerance, 1)
    }
}

extension Show {
    /// Markers of one kind (hand-placed, or detected) that collide with a
    /// time, leaving out `excluding`.
    public func markers(colliding t: Double, isBeat: Bool, excluding: Set<UUID> = [],
                        tolerance: Int, grid: FrameGrid) -> [UUID] {
        rulerMarkers.filter { $0.isBeat == isBeat && !excluding.contains($0.id)
            && grid.collide($0.time, t, tolerance: tolerance) }.map(\.id)
    }

    /// True when any of these markers (where they are now) collides with a
    /// marker of its kind outside them. Markers inside the set move
    /// together and keep their spacing, so they're not checked against
    /// each other.
    public func markersCollide(_ ids: Set<UUID>, tolerance: Int, grid: FrameGrid) -> Bool {
        rulerMarkers.filter { ids.contains($0.id) }.contains { m in
            !markers(colliding: m.time, isBeat: m.isBeat, excluding: ids, tolerance: tolerance, grid: grid).isEmpty
        }
    }

    /// A hand-placed marker at `t`: hand-placed ones colliding with it
    /// collapse into it, and it sits at the newest placement. `merged` says
    /// whether any did.
    public func placingMarker(at t: Double, tolerance: Int, grid: FrameGrid) -> (show: Show, merged: Bool) {
        let gone = Set(markers(colliding: t, isBeat: false, tolerance: tolerance, grid: grid))
        var s = self
        s.markers.removeAll { gone.contains($0.id) }
        s.markers.append(Marker(time: t))
        return (s, !gone.isEmpty)
    }
}
