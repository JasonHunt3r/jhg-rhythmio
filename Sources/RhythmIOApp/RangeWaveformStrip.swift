import SwiftUI
import RhythmIOCore

/// Edit Range's waveform (Jason, 2026-10-03): the audio in and around the
/// range in one strip, as the audio row draws it (each clip where it sits,
/// gaps empty), with what the display popover switches on — beats, bars,
/// sections, the tempo, beat markers and show markers — and In and Out as
/// handles to drag. A drag moves the field and its frame live, snapping to
/// whatever is showing, on the frame grid; nothing is saved until Apply.
///
/// The strip's window reaches a little past the range so there's room to
/// drag outward, and holds still during a drag, so the scale doesn't shift
/// under the pointer.
struct RangeWaveformStrip: View {
    let show: Show
    let rangeIn: Double?
    let rangeOut: Double?
    let setIn: (Double) -> Void
    let setOut: (Double) -> Void
    @Environment(AppModel.self) private var model

    @AppStorage(RangeDisplay.beatsKey) private var showBeats = true
    @AppStorage(RangeDisplay.barsKey) private var showBars = true
    @AppStorage(RangeDisplay.sectionsKey) private var showSections = false
    @AppStorage(RangeDisplay.tempoKey) private var showTempo = true
    @AppStorage(RangeDisplay.beatMarkersKey) private var showBeatMarkers = true
    @AppStorage(RangeDisplay.showMarkersKey) private var showShowMarkers = true
    @AppStorage(RangeDisplay.tempoCorrectionKey) private var tempo: SongRhythm.Tempo = .asDetected
    @State private var displayShown = false
    /// During a drag: which end, and the window as it was when it began.
    @State private var drag: (isIn: Bool, window: ClosedRange<Double>)?

    static let height: CGFloat = 64
    /// Lighter than the audio row's blue, which is drawn on a light clip:
    /// on this strip's dark ground that one barely showed.
    private static let wave = Color(red: 0.45, green: 0.72, blue: 1.0)

    private var grid: FrameGrid { show.frameGrid }

    /// The range and a margin either side: 15 % of its length, half a
    /// second at least.
    private var window: ClosedRange<Double> {
        if let drag { return drag.window }
        let lo = rangeIn ?? 0, hi = max(rangeOut ?? lo + 1, lo + grid.frameLength)
        let margin = max((hi - lo) * 0.15, 0.5)
        return max(lo - margin, 0)...(hi + margin)
    }

    private struct Song {
        let clip: AudioClip
        let item: MediaItem
        let waveform: Waveform?
        let rhythm: SongRhythm?
    }

    private func songs(in w: ClosedRange<Double>) -> [Song] {
        show.music.filter { $0.end > w.lowerBound && $0.start < w.upperBound }.compactMap { c in
            guard let item = model.itemsByID[c.itemID] else { return nil }
            return Song(clip: c, item: item, waveform: Waveforms.shared.cached(item), rhythm: Rhythms.shared.rhythm(item))
        }
    }

    var body: some View {
        let w = window
        let songs = songs(in: w)
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { g in
                canvas(w, songs)
                    .contentShape(Rectangle())
                    .gesture(handleDrag(width: g.size.width, songs: songs))
            }
            .frame(height: Self.height)
            // Solid: the popover's material let the picture behind it show
            // through and muddy the waveform (seen 2026-10-03).
            .background(RoundedRectangle(cornerRadius: 5).fill(Color(white: 0.11)))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(alignment: .topLeading) { tempoLabel(songs) }
            .overlay {
                if songs.isEmpty {
                    Text("No audio here").font(.caption).foregroundStyle(.secondary).allowsHitTesting(false)
                }
            }
            // At the right: from the left it opened half off a screen whose
            // edge the popover was already against (seen 2026-10-03).
            HStack {
                Spacer()
                Button { displayShown = true } label: {
                    Label("Show", systemImage: "waveform.badge.magnifyingglass")
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $displayShown, arrowEdge: .bottom) { displayPopover }
                .help("What the waveform shows")
            }
            .font(.caption)
        }
    }

    // MARK: Drawing

    private func canvas(_ w: ClosedRange<Double>, _ songs: [Song]) -> some View {
        Canvas { ctx, size in
            let span = w.upperBound - w.lowerBound
            guard span > 0, size.width > 0 else { return }
            func x(_ t: Double) -> CGFloat { CGFloat((t - w.lowerBound) / span) * size.width }
            let mid = size.height / 2

            for s in songs {
                let c = s.clip
                let a = max(x(c.start), 0), b = min(x(c.end), size.width)
                ctx.fill(Path(CGRect(x: a, y: 1, width: b - a, height: size.height - 2)),
                         with: .color(Self.wave.opacity(0.12)))
                // Sections: alternating bands along the bottom.
                if showSections, let r = s.rhythm {
                    for (i, sec) in r.sections.enumerated() {
                        let t0 = c.showTime(ofSongTime: max(sec.start, c.inPoint))
                        let t1 = c.showTime(ofSongTime: min(sec.end, c.inPoint + c.length))
                        guard t1 > t0 else { continue }
                        ctx.fill(Path(CGRect(x: x(t0), y: size.height - 6, width: x(t1) - x(t0), height: 6)),
                                 with: .color(i % 2 == 0 ? Color.indigo.opacity(0.6) : Color.teal.opacity(0.6)))
                    }
                }
                // The waveform, as the audio row draws it.
                if let wave = s.waveform {
                    var path = Path()
                    var px = max(a, 0)
                    while px < b {
                        let t0 = c.songTime(ofShowTime: w.lowerBound + span * Double(px / size.width))
                        let t1 = c.songTime(ofShowTime: w.lowerBound + span * Double((px + 2) / size.width))
                        let h = max(0.5, CGFloat(wave.peak(from: t0, to: t1)) * (size.height / 2 - 4))
                        path.addRect(CGRect(x: px, y: mid - h, width: 1.4, height: h * 2))
                        px += 2
                    }
                    ctx.fill(path, with: .color(Self.wave.opacity(0.85)))
                }
                // Beats and bars, with the tempo correction chosen.
                if let r = s.rhythm {
                    func inClip(_ t: Double) -> Bool { t >= c.inPoint - 1e-9 && t <= c.inPoint + c.length + 1e-9 }
                    if showBeats {
                        var beats = Path()
                        for t in r.beats(tempo) where inClip(t) {
                            beats.addRect(CGRect(x: x(c.showTime(ofSongTime: t)), y: size.height - 14, width: 0.75, height: 8))
                        }
                        ctx.fill(beats, with: .color(.white.opacity(0.45)))
                    }
                    if showBars {
                        var bars = Path()
                        for t in r.bars(tempo) where inClip(t) {
                            bars.addRect(CGRect(x: x(c.showTime(ofSongTime: t)), y: 2, width: 1.25, height: size.height - 4))
                        }
                        ctx.fill(bars, with: .color(.white.opacity(0.35)))
                    }
                }
            }

            // Markers, each kind on its own switch, as on the ruler.
            for m in show.rulerMarkers where w.contains(m.time) {
                guard m.isBeat ? showBeatMarkers : showShowMarkers else { continue }
                var p = Path()
                let mx = x(m.time)
                p.move(to: CGPoint(x: mx - 4, y: 0)); p.addLine(to: CGPoint(x: mx + 4, y: 0)); p.addLine(to: CGPoint(x: mx, y: 7))
                ctx.fill(p, with: .color(m.isBeat ? .teal : .orange))
                ctx.fill(Path(CGRect(x: mx - 0.5, y: 7, width: 1, height: size.height - 7)),
                         with: .color((m.isBeat ? Color.teal : .orange).opacity(0.5)))
            }

            // Outside the range, dimmed; In and Out as handles.
            if let lo = rangeIn, let hi = rangeOut {
                ctx.fill(Path(CGRect(x: 0, y: 0, width: max(x(lo), 0), height: size.height)), with: .color(.black.opacity(0.45)))
                ctx.fill(Path(CGRect(x: x(hi), y: 0, width: max(size.width - x(hi), 0), height: size.height)),
                         with: .color(.black.opacity(0.45)))
                for (t, isIn) in [(lo, true), (hi, false)] {
                    let hx = x(t)
                    let active = drag?.isIn == isIn
                    ctx.fill(Path(CGRect(x: hx - 1, y: 0, width: 2, height: size.height)),
                             with: .color(active ? .yellow : .blue))
                    var tab = Path()
                    tab.move(to: CGPoint(x: hx, y: 0))
                    tab.addLine(to: CGPoint(x: hx + (isIn ? 8 : -8), y: 0))
                    tab.addLine(to: CGPoint(x: hx, y: 10))
                    ctx.fill(tab, with: .color(active ? .yellow : .blue))
                }
            }
        }
    }

    @ViewBuilder private func tempoLabel(_ songs: [Song]) -> some View {
        if showTempo, let bpm = songs.compactMap({ $0.rhythm?.beatsPerMinute }).first {
            let factor: Double = switch tempo {
            case .asDetected: 1
            case .double: 2
            case .half: 0.5
            }
            Text("\(Int((bpm * factor).rounded())) BPM")
                .font(.caption2.monospacedDigit())
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Capsule().fill(.black.opacity(0.5)))
                .padding(4)
                .allowsHitTesting(false)
        }
    }

    // MARK: Dragging In and Out

    /// What a dragged handle snaps to: what's showing, within six points.
    private func snapTargets(_ songs: [Song]) -> [Double] {
        var out: [Double] = []
        for s in songs {
            guard let r = s.rhythm else { continue }
            let c = s.clip
            func inClip(_ t: Double) -> Bool { t >= c.inPoint && t <= c.inPoint + c.length }
            if showBeats { out += r.beats(tempo).filter(inClip).map(c.showTime(ofSongTime:)) }
            if showBars { out += r.bars(tempo).filter(inClip).map(c.showTime(ofSongTime:)) }
        }
        out += show.rulerMarkers.filter { $0.isBeat ? showBeatMarkers : showShowMarkers }.map(\.time)
        return out
    }

    private func handleDrag(width: CGFloat, songs: [Song]) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                let w = drag?.window ?? window
                let span = w.upperBound - w.lowerBound
                guard width > 0, span > 0 else { return }
                func t(_ px: CGFloat) -> Double { w.lowerBound + span * Double(px / width) }
                func px(_ t: Double) -> CGFloat { CGFloat((t - w.lowerBound) / span) * width }
                if drag == nil {
                    // The handle nearer the press, within ten points.
                    let dIn = rangeIn.map { abs(px($0) - g.startLocation.x) } ?? .infinity
                    let dOut = rangeOut.map { abs(px($0) - g.startLocation.x) } ?? .infinity
                    guard min(dIn, dOut) <= 10 else { return }
                    drag = (isIn: dIn <= dOut, window: w)
                }
                guard let d = drag else { return }
                var time = t(g.location.x)
                let tolerance = span * 6 / Double(width)
                if let near = snapTargets(songs).min(by: { abs($0 - time) < abs($1 - time) }),
                   abs(near - time) <= tolerance { time = near }
                time = max(grid.snap(time), 0)
                if d.isIn { setIn(time) } else { setOut(time) }
            }
            .onEnded { _ in drag = nil }
    }

    // MARK: The display popover

    private var displayPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Show on the waveform").font(.headline)
            Toggle("Beats", isOn: $showBeats)
            Toggle("Bars", isOn: $showBars)
            Toggle("Sections", isOn: $showSections)
            Toggle("Tempo", isOn: $showTempo)
            Picker("Tempo", selection: $tempo) {
                Text("As detected").tag(SongRhythm.Tempo.asDetected)
                Text("×2").tag(SongRhythm.Tempo.double)
                Text("÷2").tag(SongRhythm.Tempo.half)
            }
            .pickerStyle(.segmented).labelsHidden()
            .help("Detectors are often wrong by a factor of two: this corrects the beats, bars and BPM shown")
            Divider()
            Toggle("Beat markers", isOn: $showBeatMarkers)
            Toggle("Show markers", isOn: $showShowMarkers)
            Text("Dragged In and Out snap to what's showing.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .toggleStyle(.checkbox)
        .padding(14)
        // Wide enough for the tempo choice's three segments: at 230 they
        // pushed everything left and out of the popover (seen 2026-10-03).
        .frame(width: 320)
    }
}

/// The display popover's switches, kept between uses.
enum RangeDisplay {
    static let beatsKey = "editRangeShowBeats"
    static let barsKey = "editRangeShowBars"
    static let sectionsKey = "editRangeShowSections"
    static let tempoKey = "editRangeShowTempo"
    static let beatMarkersKey = "editRangeShowBeatMarkers"
    static let showMarkersKey = "editRangeShowShowMarkers"
    static let tempoCorrectionKey = "editRangeTempo"
}
