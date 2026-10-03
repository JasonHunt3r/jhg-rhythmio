import AppKit
import CoreGraphics
import RhythmIOCore
import RhythmIOPlayback

/// A show's editing state, out of the views and into one object
/// (`spec/windows.md`, "What stands in the way"; `spec/panekit.md`, step
/// 4's own prerequisite): the slide selection, the playback engine, and
/// Edit Show's lane selections and storyline scroll — all of it `@State`
/// in `ShowView` and `EditShowView` until now, reachable by nothing
/// outside those views. Owned by `AppModel`, one per open show, so a
/// window other than the main one could reach it later; nothing on
/// screen changes by this move alone.
@MainActor
@Observable
final class ShowSession {
    let showID: Int64
    var selection: Set<Int64> = []
    /// Files picked in Edit Show's browser that aren't in the show, in list
    /// order: the inspector shows their info (B-04). Empty whenever
    /// anything in the show is selected.
    var inspectedFiles: [Int64] = []
    /// The ruler's own selectable things (`spec/range-and-ruler.md`,
    /// "Targeting and feedback"): a range end, or the playhead. Selecting one
    /// clears every other selection, and any other selection clears them.
    var selectedRangeEnd: RangeEnd?
    var playheadSelected = false
    /// The nudge readout: where the last run of presses left the thing it
    /// moved, and how far that run moved it, until it fades (`token` tells
    /// a newer run from the one a fade was scheduled for).
    var nudgeReadout: NudgeReadout?

    struct NudgeReadout: Equatable {
        var time: Double
        var delta: Double
        var target: String
        var token: Int
        /// Shown instead of the timecode: "No beats detected."
        var message: String? = nil
    }

    /// Markers flashing red after a collision (N5): put back where they
    /// were, or refused.
    var collidedMarkers: Set<UUID> = []

    /// An arrow held on selected markers (N5): moving (the first press was
    /// the edit) or refused (the first press would have collided, so the
    /// repeats are ignored and it beeps once).
    enum MarkerHold { case moving, refused }
    var markerHold: MarkerHold?

    /// Flashes markers red for a moment, with the system beep (sound may be
    /// muted, so the flash matters).
    func flashCollision(_ ids: Set<UUID>) {
        NSSound.beep()
        collidedMarkers = ids
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            if self?.collidedMarkers == ids { self?.collidedMarkers = [] }
        }
    }

    /// Lets go of the ruler's own selections (a range end, the playhead).
    func clearRulerSelection() {
        if selectedRangeEnd != nil { selectedRangeEnd = nil }
        if playheadSelected { playheadSelected = false }
    }

    /// Edit Show only: created when that mode is entered, torn down when
    /// it's left or another show opens (`EditShowView`'s own lifecycle,
    /// unchanged by this move).
    var engine: PlaybackEngine?
    /// The transition selected in the storyline's lane, by the slide it
    /// leads into.
    var selectedTransition: Int64?
    /// The image selected in the lane's images row.
    var selectedOverlay: UUID?
    var selectedSong: UUID?
    var selectedMarkers: Set<UUID> = []
    var storylineOffset: CGFloat = 0

    /// The slides row's own anchor/cursor for ⇧-click and ⇧-arrow ranging
    /// (`GridSelection`, batch 4 and item 7): a click in `StorylineView`
    /// and an arrow key in `EditShowView` both touch these, so they share
    /// one place to keep from desyncing.
    var slideAnchor: Int64?
    var slideAnchorBase: Set<Int64> = []
    var slideCursor: Int64?

    /// Go Back's own history (W8, item 7; plan, "Go Back, not undo"): the
    /// playhead stays out of ⌘Z, so a ruler click/drag or an arrow-key
    /// nudge pushes here instead, and ⌘[ / ⌘] walk it like a browser's
    /// history, not the undo stack.
    var goBackHistory: [PlayheadStep] = []
    var goForwardHistory: [PlayheadStep] = []
    /// `StorylineView` watches this and scrolls to it, then clears it —
    /// `ScrollViewReader` only scrolls to a view's id, not a raw offset,
    /// and only the storyline itself holds the `ScrollViewReader` proxy.
    var pendingScroll: Int64?

    init(showID: Int64) { self.showID = showID }
}

/// One position in Go Back's history: the playhead, the zoom, and (in
/// place of a raw scroll offset — see `pendingScroll`) whichever slide
/// sat nearest the left edge when it was recorded.
struct PlayheadStep: Equatable {
    var time: Double
    var pps: Double
    var leadingSlideID: Int64?

    /// The current position, packaged for the history. `StorylineView`'s
    /// own `inset` (12pt before the first slide) matches the ruler's.
    @MainActor
    static func current(engine: PlaybackEngine, timeline: ShowTimeline, pps: Double, scrollOffset: CGFloat) -> PlayheadStep {
        let viewTime = max((Double(scrollOffset) - StorylineView.inset) / pps, 0)
        let leading = timeline.slides.min { abs($0.start - viewTime) < abs($1.start - viewTime) }?.slide.id
        return PlayheadStep(time: engine.timeline.wrap(engine.now), pps: pps, leadingSlideID: leading)
    }
}
