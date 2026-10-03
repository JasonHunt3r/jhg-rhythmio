import SwiftUI
import RhythmIOCore

/// Edit Range (`spec/range-and-ruler.md`, "B-11: exact In and Out"): In, Out
/// and Length as timecode on the show's frame grid, and the frames at In and
/// Out. Editing In keeps Out (Length follows); editing Out keeps In; editing
/// Length keeps In and moves Out. A field that can't be read, or would make
/// the range less than a frame long, turns red and Return won't apply;
/// nothing is clamped quietly. Return applies all of it as one undo step;
/// Esc cancels.
struct EditRangePopover: View {
    let show: Show
    let timeline: ShowTimeline
    let mutate: ShowMutator
    let close: () -> Void
    @Environment(AppModel.self) private var model

    private enum Field: Hashable { case rangeIn, rangeOut, length }
    @FocusState private var focus: Field?
    @State private var inText = ""
    @State private var outText = ""
    @State private var lengthText = ""
    @State private var inFrame: CGImage?
    @State private var outFrame: CGImage?
    /// The last change came from ↑ ↓ or a swipe: the frames redraw at once,
    /// following the scrub, rather than after the typing pause.
    @State private var stepped = false
    /// Drawn as the export draws them: a video slide at its exact frame.
    @State private var renderer = RangeFrameRenderer()

    private static let frameSize = CGSize(width: 224, height: 126)

    private var grid: FrameGrid { show.frameGrid }
    private var inValue: Double? { grid.parse(inText) }
    private var outValue: Double? { grid.parse(outText) }
    private var lengthValue: Double? { grid.parse(lengthText) }

    /// A frame's slack for comparing times that are all on the grid.
    private var slack: Double { grid.frameLength / 4 }
    private var inOK: Bool {
        guard let i = inValue else { return false }
        return outValue.map { i <= $0 - grid.frameLength + slack } ?? true
    }
    private var outOK: Bool {
        guard let o = outValue else { return false }
        return inValue.map { o >= $0 + grid.frameLength - slack } ?? true
    }
    private var lengthOK: Bool { lengthValue.map { $0 >= grid.frameLength - slack } ?? false }
    private var valid: Bool { inOK && outOK && lengthOK }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                preview("IN", inFrame, at: inOK ? inValue : nil)
                preview("OUT", outFrame, at: outOK ? outValue : nil)
            }
            Text(lengthOK ? "Length \(grid.format(lengthValue ?? 0))" : "Length —")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
            Grid(alignment: .trailing, horizontalSpacing: 8, verticalSpacing: 6) {
                fieldRow("In", $inText, ok: inOK, field: .rangeIn)
                fieldRow("Out", $outText, ok: outOK, field: .rangeOut)
                fieldRow("Length", $lengthText, ok: lengthOK, field: .length)
            }
            Text("m:ss:ff at \(show.defaults.frameRate.name) · also 83, 1:23 or 2490f")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel", action: close).keyboardShortcut(.cancelAction)
                Button("Apply", action: apply).keyboardShortcut(.defaultAction).disabled(!valid)
            }
        }
        .padding(14)
        .onAppear(perform: load)
        .onChange(of: inText) { _, _ in if focus == .rangeIn { followIn() } }
        .onChange(of: outText) { _, _ in if focus == .rangeOut { followOut() } }
        .onChange(of: lengthText) { _, _ in if focus == .length { followLength() } }
        // The frames, a moment after the typing stops.
        .task(id: PreviewKey(rangeIn: inOK ? inValue : nil, rangeOut: outOK ? outValue : nil)) {
            if !stepped { try? await Task.sleep(for: .milliseconds(250)) }
            stepped = false
            guard !Task.isCancelled else { return }
            await renderFrames()
        }
    }

    // MARK: The fields

    private func fieldRow(_ title: String, _ text: Binding<String>, ok: Bool, field: Field) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            TextField("", text: text)
                .font(.body.monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
                .focused($focus, equals: field)
                .foregroundStyle(ok ? Color.primary : Color.red)
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(ok ? Color.clear : Color.red, lineWidth: 1.5))
                .onSubmit(apply)
                .numberStepping(announce: true) { text, direction, size in stepTimecode(text, direction, size, field: field) }
        }
    }

    /// ↑ ↓ or a swipe on a timecode field: the Nudge ladder (the step, one
    /// frame, the ⇧ step, by Settings ▸ Timeline), on the frame grid. In and
    /// Out stay at 0 or later, Length at a frame or more; the field's own
    /// rules then move the others, as typing does.
    private func stepTimecode(_ text: String, _ direction: Int, _ size: NumberStepping.Size,
                              field: Field) -> String? {
        guard let t = grid.parse(text) else { return nil }
        let key: NudgeKey = switch size {
        case .unit: .plain
        case .fine: .option
        case .big: .shift
        }
        guard case .by(let delta) = NudgeSettings.saved.move(key, direction: direction, grid: grid) else { return nil }
        let lowest = field == .length ? grid.frameLength : 0
        let new = NudgeSettings.apply(delta, to: t, grid: grid, within: lowest...Double.greatestFiniteMagnitude)
        stepped = true
        return grid.format(new)
    }

    private func load() {
        let lo = show.editor.rangeIn ?? 0
        let hi = show.editor.rangeOut ?? timeline.duration
        inText = grid.format(lo)
        outText = grid.format(hi)
        lengthText = grid.format(max(hi - lo, 0))
        focus = .rangeIn
    }

    /// In changed: Out stays, Length follows.
    private func followIn() {
        guard let i = inValue, let o = outValue, o > i else { return }
        lengthText = grid.format(o - i)
    }

    /// Out changed: In stays, Length follows.
    private func followOut() {
        guard let i = inValue, let o = outValue, o > i else { return }
        lengthText = grid.format(o - i)
    }

    /// Length changed: In stays, Out moves.
    private func followLength() {
        guard let i = inValue, let l = lengthValue, l > 0 else { return }
        outText = grid.format(i + l)
    }

    private func apply() {
        guard valid, let i = inValue, let o = outValue else { NSSound.beep(); return }
        guard !show.editor.rangeLocked else { NSSound.beep(); close(); return }
        if i != show.editor.rangeIn || o != show.editor.rangeOut {
            mutate("Edit Range") { s in
                s.editor.rangeIn = i
                s.editor.rangeOut = o
                s.editor.rangeOn = true
            }
        }
        close()
    }

    // MARK: The frames

    private struct PreviewKey: Hashable { let rangeIn: Double?; let rangeOut: Double? }

    private func preview(_ label: String, _ image: CGImage?, at t: Double?) -> some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle().fill(Color.black)
            if let image {
                Image(decorative: image, scale: 1).resizable().aspectRatio(contentMode: .fit)
            }
            // A soft scrim so the text reads over any picture.
            LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2.weight(.bold))
                if let t {
                    Text(title(at: t)).font(.caption.weight(.medium))
                        .lineLimit(1).truncationMode(.middle)
                    Text(grid.format(t)).font(.callout.monospacedDigit().weight(.semibold))
                    Text("frame \(grid.frame(t))").font(.caption2.monospacedDigit())
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.6), radius: 2)
            .padding(6)
        }
        .frame(width: Self.frameSize.width, height: Self.frameSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    /// What's showing at a moment, by name (Jason, 2026-10-03: "needs the
    /// slide's title too"): the slide's file, both across a transition,
    /// or what's there with no slide.
    private func title(at t: Double) -> String {
        if t >= timeline.duration { return "Past the end" }
        return switch timeline.frame(at: t) {
        case .still(let l): l.slide.item.fileName
        case .transition(let a, let b, _, _): "\(a.slide.item.fileName) → \(b.slide.item.fileName)"
        case .background: "Background"
        case .empty: "No slides"
        }
    }

    private func renderFrames() async {
        var urls: [Int64: URL] = [:]
        for s in timeline.slides { if let u = model.url(for: s.item) { urls[s.item.id] = u } }
        for o in show.overlays { if let item = model.itemsByID[o.itemID], let u = model.url(for: item) { urls[item.id] = u } }
        let times = [inOK ? inValue : nil, outOK ? outValue : nil].compactMap { $0 }
        guard !times.isEmpty else { return }
        let done = await renderer.render(timeline, times: times, size: Self.frameSize, urls: urls)
        for (t, image) in done {
            if t == inValue { inFrame = image }
            if t == outValue { outFrame = image }
        }
    }
}

/// The frames at In and Out, drawn the way the export draws a frame
/// (`MovieMedia` through the Compositor): a video slide at its exact frame
/// for that moment, looping as the player does, and an animation at its own
/// frame — not the first frame the frame strip makes do with (Jason,
/// 2026-10-03: "the video slides especially need to render the actual frame
/// of the moment"). Off the main thread; a fresh `MovieMedia` per batch,
/// at twice the preview's size.
actor RangeFrameRenderer {
    private let context = CIContext(options: [.cacheIntermediates: false])

    func render(_ timeline: ShowTimeline, times: [Double], size: CGSize,
                urls: [Int64: URL]) -> [(Double, CGImage)] {
        let media = MovieMedia(maxPixels: Int(max(size.width, size.height) * 2)) { urls[$0.id] }
        var out: [(Double, CGImage)] = []
        for t in times.sorted() {
            // Past the show's end there's nothing yet, only its background.
            // `frame(at:)` wraps a looping show round to its start, which
            // showed a slide from earlier in the show there (seen 2026-10-03).
            let past = t >= timeline.duration
            let state = past ? .background(timeline.background, after: max(timeline.slides.count - 1, 0))
                             : timeline.frame(at: t)
            let image = Compositor.compose(state, size: size, overlay: past ? nil : timeline.overlay(at: t),
                                           overlaySource: { media.image(for: $0) },
                                           source: { media.image(for: $0) })
            if let cg = context.createCGImage(image, from: CGRect(origin: .zero, size: size)) {
                out.append((t, cg))
            }
        }
        return out
    }
}
