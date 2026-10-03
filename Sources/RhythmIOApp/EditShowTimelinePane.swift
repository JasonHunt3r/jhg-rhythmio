import SwiftUI
import RhythmIOCore
import RhythmIOPlayback
import ListKit

/// The timeline pane: the transport and the storyline, full width under
/// the Library pane, not just the detail column (`spec/windows.md`, "The
/// timeline pane"; `spec/panekit.md`, "The order," step 5's follow-up,
/// 2026-09-25). Built the first time as one of Edit Show's own three
/// columns' siblings, nested inside `model.editShowColumns` — which only
/// ever gave it the detail pane's width, not the window's, missing the
/// original sketch in `spec/panekit.md`, "What it is": `split(top/bottom)
/// { split(left|rest) { library, detail }, timeline }`. Moved to live in
/// `model.mainPanes` instead (`AppModel.swift`), rendered by `MainView`
/// independently of `EditShowView` — both read the same `ShowSession`, so
/// they stay in sync with no explicit synchronization needed, and neither
/// has to mutate `@Observable` state for the other to read mid-render.
///
/// Owns everything about the transport and storyline that isn't the show
/// session or the engine itself (both `EditShowView`'s, still): the range,
/// arrow-key and row-navigation logic, Go Back/Forward, and the Show/View
/// menu commands (`AppModel.editShowCommands`). `EditShowView` keeps the
/// engine's own lifecycle (`.task(id: show.id)`, `.onDisappear`) — this
/// view just reads `session.engine`.
struct EditShowTimelinePane: View {
    /// The pane's own whole natural height: the transport bar (its
    /// padding included), its divider, and every row of the storyline with
    /// nothing scrolled off (`StorylineView.fullHeight` — always the real
    /// content, since `TimelineRow.normalized` keeps every show's `rows`
    /// at all four kinds). `spec/windows.md`, "Its height," 2026-09-26:
    /// what a content-tracking split reports as the pane's content extent,
    /// via `PaneController.setContentExtent` (`AppModel.mainPanes`).
    /// The transport bar's height as drawn (measured 2026-09-27: its
    /// controls plus 7 pt above and below) — only a first guess: the pane's
    /// height comes from measuring what's actually drawn (`transportHeight`,
    /// `storylineHeight`; `TimelinePanePlaceholder` with no show), so it
    /// fits whatever the rows' heights become.
    static let transportEstimate: CGFloat = 30
    /// The first guess, before anything's been measured: the split's
    /// default size.
    static let contentHeight = StorylineView.fullHeight + transportEstimate + 1
    /// The least the pane can shrink to now that the rows scroll
    /// vertically (`StorylineView.rowsScrollView`, `spec/windows.md`,
    /// "Its height," 2026-09-26): the transport, its divider, the ruler,
    /// and room for one row — `StorylineView.roomForRows`'s own floor —
    /// rather than every row at once.
    static let minContentHeight = transportEstimate + 1 + StorylineView.rulerHeight + 4 + StorylineView.blockHeight + 12
        + StorylineView.bottomBreather

    let show: Show
    let timeline: ShowTimeline
    let session: ShowSession
    /// False: the rows show dimmed, the tools greyed, and only scrolling
    /// and zooming live (item 33 step 1). Both edit modes are live now
    /// (plan, "Slides as mini movies"); this is kept for a timeline open
    /// with no show (the "Smart View" preference, off), not built yet.
    let active: Bool
    /// Edit Slides: Play loops the selected slides in order, not the show,
    /// and the slide list keeps its own arrow keys while it has the keyboard.
    var editSlides = false
    let mutate: ShowMutator
    @Environment(AppModel.self) private var model
    @Environment(\.undoManager) private var undoManager
    @AppStorage("snapping") private var snapping = true
    @AppStorage("storylineZoom") private var pps: Double = 24
    @State private var visibleWidth: CGFloat = 800
    /// The transport bar as actually drawn, measured: `contentHeight`'s
    /// 56 was stale (it draws about 30), and the pane tracked that figure,
    /// leaving an empty band under the rows (2026-09-27).
    @State private var transportHeight: CGFloat?
    /// The window this pane is in, for `KeyboardArea` (it changes when the
    /// Timeline pops out).
    @State private var windowNumber: Int?
    /// The storyline's natural height, as it measures itself
    /// (`StorylineView.onNaturalHeight`) — so the pane fits whatever height
    /// the rows are drawn at, a preference one day.
    @State private var storylineHeight: CGFloat?
    private var contentExtent: CGFloat {
        (transportHeight ?? Self.transportEstimate) + 1 + (storylineHeight ?? StorylineView.fullHeight)
    }

    var body: some View {
        @Bindable var session = session
        Group {
            if let engine = session.engine, engine.showID == show.id {
                // Both modes draw the show's real rows (item 33, Jason
                // 2026-09-26). In Edit Slides (`active` false) the tools
                // grey out and the rows dim; only scrolling and zooming
                // still respond, and the keys and menu commands are off.
                VStack(spacing: 0) {
                    TransportRow(engine: engine, show: show, pps: $pps, fit: fitStoryline,
                                 setRangeToView: setRangeToView, setRangeToWholeShow: setRangeToWholeShow,
                                 clearRange: clearRange, toggleRangeLock: { toggleRangeLock(engine) },
                                 inert: !active)
                    .onGeometryChange(for: CGFloat.self, of: \.size.height) { transportHeight = $0 }
                    Divider()
                    StorylineView(show: show, timeline: timeline, engine: engine, session: session,
                                  selection: $session.selection, selectedTransition: $session.selectedTransition,
                                  selectedOverlay: $session.selectedOverlay, selectedSong: $session.selectedSong,
                                  selectedMarkers: $session.selectedMarkers,
                                  pps: $pps, scrollOffset: $session.storylineOffset, mutate: mutate,
                                  openSlideEditor: { id in
                                      SlideEditorWindow.show(slideID: id, show: show, model: model,
                                                             mutate: mutate, undoManager: undoManager)
                                  },
                                  inert: !active,
                                  onNaturalHeight: { h in if storylineHeight != h { storylineHeight = h } })
                    .environment(\.selectionHasKeyboard,
                                 KeyboardArea.shared.timelineHasArrows(windowNumber: windowNumber))
                }
                .background(WindowNumberReader(windowNumber: $windowNumber))
                .background { if active { shortcuts(engine) } }
                // Edit Slides' Play loops the selection (nil, the whole
                // show, with nothing selected or in Edit Show).
                // Recomputed from this view's own timeline, so a trim or a
                // reorder moves the stretches too.
                .onChange(of: editSlides && active ? timeline.loopSpans(for: session.selection) : nil,
                          initial: true) { _, spans in
                    engine.selectionLoop = spans
                }
            } else {
                TimelinePanePlaceholder()
            }
        }
        .onAppear { model.mainPanes.setContentExtent(contentExtent, for: "window") }
        .onChange(of: contentExtent) { model.mainPanes.setContentExtent(contentExtent, for: "window") }
        .onDisappear {
            // Matches the old FocusedValue's own absence outside Edit
            // Show (spec/hig-audit.md, "G"): leaving this view — by
            // switching to Edit Slides or away from the show entirely —
            // disables the Show/View menu's editShowCommands items again.
            model.editShowCommands = nil
        }
    }

    /// M, while listening: a marker at the playhead, on the show's clock.
    /// Not a second one on top of one already there.
    private func addMarker(_ engine: PlaybackEngine) {
        let t = (engine.timeline.wrap(engine.now) * 100).rounded() / 100
        guard !show.markers.contains(where: { abs($0.time - t) < 0.05 }) else { return }
        mutate("Add Marker") { $0.markers.append(Marker(time: t)) }
    }

    private func fitStoryline() {
        guard timeline.duration > 0 else { return }
        pps = min(max(Double(visibleWidth - StorylineView.inset * 2 - 40) / timeline.duration, 2), 400)
    }

    // MARK: Range (W6/W7, work order item 6)

    /// I: the range's start at the playhead. O: its end. Both undoable now
    /// — a deliberate edit, like any other — so they go through `mutate`,
    /// not `engine.updateEditor`. Locked ends still take the keys (a key
    /// is a deliberate act; only a drag or a modifier-click is refused).
    private func setRangeIn(_ engine: PlaybackEngine) {
        let t = engine.roundedNow
        mutate("Set Range In") { s in
            s.editor.rangeIn = t
            if let o = s.editor.rangeOut, o <= t { s.editor.rangeOut = nil }
            s.editor.rangeOn = true
        }
    }

    private func setRangeOut(_ engine: PlaybackEngine) {
        let t = engine.roundedNow
        mutate("Set Range Out") { s in
            s.editor.rangeOut = t
            if let i = s.editor.rangeIn, i >= t { s.editor.rangeIn = nil }
            s.editor.rangeOn = true
        }
    }

    /// ⌥X: also takes a locked range, like I and O.
    private func clearRange() {
        guard show.editor.rangeIn != nil || show.editor.rangeOut != nil else { return }
        mutate("Clear Range") { $0.editor.rangeIn = nil; $0.editor.rangeOut = nil }
    }

    /// A plain click on the range button with no range set, ⌥⌘-click, and
    /// the Show menu's "Set Range to View": the range becomes the stretch
    /// of the timeline in view. Refuses a locked range, with a beep.
    private func setRangeToView() {
        guard !show.editor.rangeLocked else { NSSound.beep(); return }
        guard timeline.duration > 0 else { return }
        let lo = max((Double(session.storylineOffset) - StorylineView.inset) / pps, 0)
        let hi = min(lo + Double(visibleWidth) / pps, timeline.duration)
        guard hi > lo + 0.05 else { return }
        mutate("Set Range") { s in
            s.editor.rangeIn = (lo * 100).rounded() / 100
            s.editor.rangeOut = (hi * 100).rounded() / 100
            s.editor.rangeOn = true
        }
    }

    /// ⇧⌥⌘-click and the Show menu's "Set Range to Whole Show": the range
    /// becomes the whole show, even where it's out of view. Refuses a
    /// locked range, with a beep.
    private func setRangeToWholeShow() {
        guard !show.editor.rangeLocked else { NSSound.beep(); return }
        guard timeline.duration > 0 else { return }
        mutate("Set Range") { s in
            s.editor.rangeIn = 0
            s.editor.rangeOut = (timeline.duration * 100).rounded() / 100
            s.editor.rangeOn = true
        }
    }

    /// The lock itself is a mode, like `rangeOn`, not an edit: not undone.
    private func toggleRangeLock(_ engine: PlaybackEngine) {
        engine.updateEditor { $0.rangeLocked.toggle() }
    }

    // MARK: Arrow keys (item 7, work order; spec/conventions.md §2, settled
    // 2026-09-24): ← → move through the items in the current row, ↑ ↓ move
    // between rows, and with nothing selected, ← → nudge the playhead
    // instead, as in the ruler.

    /// Whichever selection is active names the current row — they're kept
    /// mutually exclusive in `EditShowView`'s own `onChange` handlers.
    /// Nil means nothing's selected: ← → falls back to the playhead, and
    /// ↑ ↓ starts from the slides row.
    private var currentRow: TimelineRow.Kind? {
        if !session.selection.isEmpty { return .slides }
        if session.selectedTransition != nil { return .transitions }
        if session.selectedOverlay != nil { return .images }
        if session.selectedSong != nil { return .music }
        return nil
    }

    /// The time whatever's selected sits at, for ↑ ↓ to land near when it
    /// switches rows; the playhead's, with nothing selected.
    private func currentTime(_ engine: PlaybackEngine) -> Double {
        if let id = session.slideCursor ?? session.selection.first,
           let r = timeline.slides.first(where: { $0.slide.id == id }) { return r.start }
        if let id = session.selectedTransition, let r = timeline.slides.first(where: { $0.slide.id == id }) {
            return r.start
        }
        if let id = session.selectedOverlay, let o = show.overlays.first(where: { $0.id == id }) { return o.start }
        if let id = session.selectedSong, let c = show.music.first(where: { $0.id == id }) { return c.start }
        return engine.timeline.wrap(engine.now)
    }

    /// ← → within the current row (batch 4's `GridSelection`): the slides
    /// row supports ⇧ to extend, like a ⇧-click; the others are
    /// single-selection in this UI, so ⇧ has no effect there. Nothing
    /// selected: nudge the playhead instead.
    private func moveSelection(_ delta: Int, extend: Bool, engine: PlaybackEngine) {
        guard let row = currentRow else { nudgePlayhead(delta, engine: engine); return }
        switch row {
        case .slides:
            let items = timeline.slides.map(\.slide.id)
            let r = GridSelection.step(from: session.slideCursor, by: delta, anchor: session.slideAnchor,
                                       base: session.slideAnchorBase, in: items, extend: extend,
                                       selected: session.selection)
            session.selection = r.selected
            session.slideAnchor = r.anchor
            session.slideAnchorBase = r.base
            session.slideCursor = r.cursor
            if let id = r.cursor { engine.showSlide(id: id) }
        case .transitions:
            let items = timeline.slides.map(\.slide.id)
            session.selectedTransition = GridSelection.step(from: session.selectedTransition, by: delta,
                                                             anchor: nil, base: [], in: items, extend: false).cursor
        case .images:
            let items = show.overlays.sorted { $0.start < $1.start }.map(\.id)
            session.selectedOverlay = GridSelection.step(from: session.selectedOverlay, by: delta,
                                                          anchor: nil, base: [], in: items, extend: false).cursor
        case .music:
            let items = show.music.sorted { $0.start < $1.start }.map(\.id)
            session.selectedSong = GridSelection.step(from: session.selectedSong, by: delta,
                                                       anchor: nil, base: [], in: items, extend: false).cursor
        }
    }

    /// ⌘A: every slide, and nothing of any other kind — the rows are
    /// selected one kind at a time (`currentRow`). A later ⇧-click or
    /// ⇧-arrow extends from the first slide, like the grid's ⌘A.
    private func selectAllSlides() {
        let ids = timeline.slides.map(\.slide.id)
        guard !ids.isEmpty else { return }
        session.selectedTransition = nil; session.selectedOverlay = nil
        session.selectedSong = nil; session.selectedMarkers = []
        session.selection = Set(ids)
        session.slideAnchor = ids.first
        session.slideAnchorBase = Set(ids)
    }

    /// ↑ ↓ between rows, in the show's own row order (a live drag of a
    /// row's handle isn't in play while a key is being pressed, so
    /// `show.rows` — not the storyline's own `displayRows` — is enough).
    /// Lands on whichever item in the new row sits nearest the old
    /// selection's time; nothing selected starts at the slides row,
    /// nearest the playhead.
    private func moveRow(_ delta: Int, engine: PlaybackEngine) {
        let kinds = show.rows.map(\.kind)
        guard !kinds.isEmpty else { return }
        let time = currentTime(engine)
        if let row = currentRow, let i = kinds.firstIndex(of: row) {
            let to = min(max(i + delta, 0), kinds.count - 1)
            guard to != i else { return }
            selectNearest(in: kinds[to], to: time, engine: engine)
        } else {
            selectNearest(in: kinds.contains(.slides) ? .slides : kinds[0], to: time, engine: engine)
        }
    }

    private func selectNearest(in kind: TimelineRow.Kind, to time: Double, engine: PlaybackEngine) {
        session.selection = []; session.selectedTransition = nil
        session.selectedOverlay = nil; session.selectedSong = nil
        switch kind {
        case .slides:
            guard let r = timeline.slides.min(by: { abs($0.start - time) < abs($1.start - time) }) else { return }
            let res = GridSelection.click(r.slide.id)
            session.selection = res.selected; session.slideAnchor = res.anchor
            session.slideAnchorBase = res.base; session.slideCursor = res.cursor
            engine.showSlide(id: r.slide.id)
        case .transitions:
            session.selectedTransition = timeline.slides.min { abs($0.start - time) < abs($1.start - time) }?.slide.id
        case .images:
            session.selectedOverlay = show.overlays.min { abs($0.start - time) < abs($1.start - time) }?.id
        case .music:
            session.selectedSong = show.music.min { abs($0.start - time) < abs($1.start - time) }?.id
        }
    }

    /// One frame of the show's frame rate (item 7, work order: "← → nudge
    /// the playhead"). A deliberate nudge, so it's its own Go Back step (W8).
    private func nudgePlayhead(_ delta: Int, engine: PlaybackEngine) {
        recordPlayheadJump(engine)
        if engine.isPlaying { engine.pause() }
        let t = engine.timeline.wrap(engine.now) + Double(delta) * engine.show.frameGrid.frameLength
        engine.seek(min(max(t, 0), max(engine.duration - 0.001, 0)))
    }

    // MARK: Go Back / Go Forward (W8, item 7; plan, "Go Back, not undo")

    /// Push the position as it is right now, before a jump changes it —
    /// called at a ruler click/drag's start (`StorylineView`) and before
    /// each keyboard nudge. Clears Go Forward: a genuinely new jump isn't
    /// a redo of one just undone by Go Back.
    private func recordPlayheadJump(_ engine: PlaybackEngine) {
        session.goBackHistory.append(.current(engine: engine, timeline: timeline, pps: pps,
                                              scrollOffset: session.storylineOffset))
        session.goForwardHistory = []
    }

    private func goBack(_ engine: PlaybackEngine) {
        guard let step = session.goBackHistory.popLast() else { return }
        session.goForwardHistory.append(.current(engine: engine, timeline: timeline, pps: pps,
                                                  scrollOffset: session.storylineOffset))
        apply(step, engine)
    }

    private func goForward(_ engine: PlaybackEngine) {
        guard let step = session.goForwardHistory.popLast() else { return }
        session.goBackHistory.append(.current(engine: engine, timeline: timeline, pps: pps,
                                              scrollOffset: session.storylineOffset))
        apply(step, engine)
    }

    private func apply(_ step: PlayheadStep, _ engine: PlaybackEngine) {
        if engine.isPlaying { engine.pause() }
        engine.seek(step.time)
        pps = step.pps
        session.pendingScroll = step.leadingSlideID
    }

    /// What the Show/View menu commands need refreshed for
    /// (`editShowCommands`, below): everything else in
    /// `EditShowCommandsValue` is a closure that reads live state when
    /// called (through `mutate`/`engine`, never a captured snapshot), so
    /// only these four plus the show itself need to be watched.
    private struct CommandsTrigger: Equatable {
        var showID: Int64
        var rangeLocked: Bool
        var loopOn: Bool
        var canGoBack: Bool
        var canGoForward: Bool
    }

    /// Keyboard shortcuts: Final Cut's J/K/L, space, and its M (marker), I
    /// and O (range), N (snapping), and the arrow keys — bare keys, so
    /// `SingleKeys` handles them (never `.keyboardShortcut`,
    /// which would become a window key equivalent AppKit offers before
    /// the focused text field, stealing "j" or a space out of Search —
    /// audit M4). ⌘L (loop), ⌘=/⌘− (zoom), ⌥X (clear range) and ⇧Z (fit)
    /// all need a modifier, so they're safe as real menu shortcuts
    /// instead (F1, batch 5) — `editShowCommands`, below, publishes the
    /// actions the Show and View menus call.
    ///
    /// **Not `.focusedSceneValue` any more** (`spec/panekit.md`, "The
    /// order," step 5, found 2026-09-25): that's scoped to SwiftUI's own
    /// `Scene` graph, so it never reached the Show/View menus while the
    /// Timeline pane's popped-out window was key, even though its content
    /// — this view — was still live and on screen. `model.editShowCommands`
    /// is a plain stored property, so it's reachable regardless of which
    /// window is key, the same fix `UndoMenuState` made for Undo/Redo.
    /// Pushed via `onChange` rather than written directly in `body`
    /// (SwiftUI doesn't allow mutating `@Observable` state during a view
    /// update) — **and reading `show`, not `engine.show`**, since
    /// `PlaybackEngine.show` is `@ObservationIgnored` (rhythmio-gotchas):
    /// reading it here would silently stop `CommandsTrigger` from ever
    /// refreshing.
    private func shortcuts(_ engine: PlaybackEngine) -> some View {
        ZStack {
            SingleKeys { event in
                // Edit Slides: the slide list (a table) keeps its own
                // arrow keys while it has the keyboard.
                if editSlides, (123...126).contains(event.keyCode),
                   NSApp.keyWindow?.firstResponder is NSTableView { return false }
                // B-03: the arrows go to the area last clicked; the
                // timeline keeps them until another area that uses them is.
                if (123...126).contains(event.keyCode),
                   !KeyboardArea.shared.timelineHasArrows(in: event.window) { return false }
                switch (event.keyCode, event.charactersIgnoringModifiers?.lowercased(), event.plainModifiers) {
                case (49, _, []): engine.togglePlay()                  // space
                case (_, "j", []): engine.shuttle(-1)
                case (_, "k", []): engine.shuttle(0)
                case (_, "l", []): engine.shuttle(1)
                case (_, "m", []): addMarker(engine)
                case (_, "i", []): setRangeIn(engine)
                case (_, "o", []): setRangeOut(engine)
                case (_, "n", []): snapping.toggle()
                // Delete/⌫ isn't handled here: MainView's own Delete/⌘Delete
                // handler tries the lane's selection first (`SlideActions
                // .removeSelected`), before its sidebar fallback — one
                // handler, so there's no race between two `SingleKeys`
                // instances on the same window over the same keypress
                // (found 2026-09-25, `spec/panekit.md` step 5's follow-up).
                // ⌘A, Select All (audit A1): every slide. Nothing else in
                // the window answers `selectAll:`, so it beeped. A list
                // with the keyboard (the browser) keeps its own ⌘A.
                case (0, _, [.command]):
                    guard !(NSApp.keyWindow?.firstResponder is NSTableView),
                          !ListKeyboard.hasKeyboard(in: NSApp.keyWindow) else { return false }
                    selectAllSlides()
                case (123, _, []): moveSelection(-1, extend: false, engine: engine)     // ←
                case (123, _, [.shift]): moveSelection(-1, extend: true, engine: engine)
                case (124, _, []): moveSelection(1, extend: false, engine: engine)      // →
                case (124, _, [.shift]): moveSelection(1, extend: true, engine: engine)
                case (126, _, []): moveRow(-1, engine: engine)                          // ↑
                case (125, _, []): moveRow(1, engine: engine)                           // ↓
                default: return false
                }
                return true
            }
        }
        .opacity(0)
        .allowsHitTesting(false)
        .background(GeometryReader { g in
            Color.clear.onAppear { visibleWidth = g.size.width }
                .onChange(of: g.size.width) { _, w in visibleWidth = w }
        })
        .onChange(of: CommandsTrigger(showID: show.id, rangeLocked: show.editor.rangeLocked,
                                      loopOn: show.editor.loopPlayback,
                                      canGoBack: !session.goBackHistory.isEmpty,
                                      canGoForward: !session.goForwardHistory.isEmpty),
                 initial: true) { _, t in
            model.editShowCommands = EditShowCommandsValue(
                togglePlay: { engine.togglePlay() },
                addMarker: { addMarker(engine) },
                setRangeIn: { setRangeIn(engine) },
                setRangeOut: { setRangeOut(engine) },
                clearRange: clearRange,
                setRangeToView: setRangeToView,
                setRangeToWholeShow: setRangeToWholeShow,
                toggleRangeLock: { toggleRangeLock(engine) },
                rangeLocked: t.rangeLocked,
                toggleLoop: { engine.updateEditor { $0.loopPlayback.toggle() } },
                loopOn: t.loopOn,
                zoomToFit: fitStoryline,
                goBack: { goBack(engine) },
                goForward: { goForward(engine) },
                canGoBack: t.canGoBack,
                canGoForward: t.canGoForward)
        }
        // Switching to Edit Slides removes this view but not the pane, so
        // the pane's own onDisappear doesn't run: the Show/View menu's
        // Edit Show items go off here too.
        .onDisappear { model.editShowCommands = nil }
    }
}

/// The timeline pane's stand-in for the moment before the show's engine
/// exists (`ShowView` makes it as the show opens). Same chrome as the real
/// transport bar (`TransportRow`), dimmed and inert, so nothing reflows.
/// It was Edit Slides' whole timeline until item 33 (2026-09-26), which
/// draws the real rows there instead — hence no message any more.
/// Since 2026-09-27 it's also the whole pane while the Library, a
/// collection or a group is selected (Jason: "greyed out but visible, an
/// empty toolset"), so it carries every tool `TransportRow` has. What the
/// timeline should do there (making a show from a collection) is a
/// planning talk still to have (`spec/status.md`).
struct TimelinePanePlaceholder: View {
    /// Each empty row's own words, the same as a real empty show's where it
    /// has them ("Drop images here", "Drop songs here").
    static func prompt(_ kind: TimelineRow.Kind) -> String {
        switch kind {
        case .images: "Drop images here"
        case .transitions: "Transitions"
        case .slides: "Slides"
        case .music: "Drop songs here"
        }
    }

    /// Reports the placeholder's natural height, measured — the play bar,
    /// its divider, the rows as drawn, the breather — so the pane fits it
    /// whatever the rows' heights become, as with a show.
    var onNaturalHeight: ((CGFloat) -> Void)? = nil
    @AppStorage("storylineZoom") private var pps: Double = 24
    @State private var transport: CGFloat?
    @State private var rows: CGFloat?

    private func report() {
        guard let transport, let rows else { return }
        onNaturalHeight?(transport + 1 + rows + StorylineView.bottomBreather)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "backward.end.fill")
                Image(systemName: "play.fill").frame(width: 14)
                Image(systemName: "forward.end.fill")
                Slider(value: .constant(0), in: 0...1).disabled(true)
                Text("--:-- / --:--")
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 110, alignment: .trailing)
                Divider().frame(height: 16)
                // The same tools, in the same order, as `TransportRow`.
                ForEach(["arrow.left.and.line.vertical.and.arrow.right", "timeline.selection",
                         "arrow.down.to.line.compact", "flag", "repeat"], id: \.self) { Image(systemName: $0) }
                Divider().frame(height: 16)
                ForEach(["minus.magnifyingglass", "plus.magnifyingglass", "arrow.left.and.right.square"],
                        id: \.self) { Image(systemName: $0) }
            }
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.bar)
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { transport = $0; report() }
            Divider()
            // The default rows, empty and dimmed like an inert timeline
            // (Jason, 2026-09-27: "it's supposed to show that here's a tool
            // and it's waiting for you"): a ruler, then Images, Transitions,
            // Slides and Audio at their real heights, each with its grip.
            VStack(alignment: .leading, spacing: StorylineView.rowGap) {
                // The real ruler, at the timeline's own zoom, to the edge.
                RulerView(duration: 0, pps: pps, inset: StorylineView.inset)
                    .frame(maxWidth: .infinity)
                    .frame(height: StorylineView.rulerHeight)
                ForEach(TimelineRow.Kind.allCases, id: \.self) { kind in
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2).fill(.quaternary).frame(width: 4)
                            .padding(.horizontal, 3)
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.05))
                            Label(Self.prompt(kind), systemImage: kind.symbol)
                                .font(.caption)
                                .padding(.leading, 8)
                        }
                    }
                    .frame(height: StorylineView.height(of: kind))
                }
            }
            // The real rows leave a gap after the last one too; matching it
            // keeps the pane the same height with a show or without.
            .padding(.bottom, StorylineView.rowGap)
            .padding(.vertical, 6)
            // Before it's stretched to the pane: the rows' own height.
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { rows = $0; report() }
            .foregroundStyle(.tertiary)
            .opacity(0.45)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .underPageBackgroundColor))
        }
        .allowsHitTesting(false)
    }
}
