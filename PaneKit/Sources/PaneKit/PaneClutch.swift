import AppKit

/// How a drawer feels under the pointer (Jason, 2026-09-26: "a cantilevered
/// clutch"). Pulled from closed, it **bites** — follows the pointer at once,
/// so you know you're onto something — then **slips**, lagging the pointer
/// while it's pulled further, until it's sure: then it **engages** — like a
/// bow loosed at full draw (Jason) — and slides quickly open to its own size
/// (its default, then the last size it was left at), the drag over: the
/// pointer is an arrow again and the rest of the press is ignored until the
/// button comes up. Let go before that and it slides back shut.
/// An open drawer dragged slowly is only **repositioned**, down to its
/// minimum and no further — never shut (Jason: "that's reposition, not
/// close drawer"). It shuts with a **flick** toward its edge, a **swipe** on
/// its handle, or a double-click (and an
/// app's own toggle, `animated: true`) slides rather than jumping.
///
/// The dials, tuned by feel. All distances are points. Main-actor, like
/// everything that draws.
@MainActor
public enum PaneClutch {
    /// How far a closed drawer follows the pointer exactly.
    public static var bite: CGFloat = 14
    /// How much of the pointer's travel past the bite the drawer takes.
    public static var slip: CGFloat = 0.35
    /// How far the pointer must pull a closed drawer before it engages — a
    /// literal distance, the same for every drawer whatever its size or last
    /// size (Jason, 2026-09-26: "so all interactions will be the same").
    /// 64 is a touch quicker than the first build's 48…110 (half the
    /// drawer's size), which Jason found "a little on the slow side".
    public static var engage: CGFloat = 64
    /// A slow drag stops an open drawer dead at its minimum; carried on this
    /// far past the stopped divider, it looses the drawer shut — the same
    /// literal distance as the pull that opens it (Jason, 2026-09-26: "once
    /// the brakes are slammed on, it should stay still until the mouse is X
    /// distance from the stopped divider").
    public static var closePast: CGFloat = 64
    /// Whether a slow drag to `fromEdge` has gone far enough past the
    /// stopped divider (at `minimum`) to shut the drawer.
    public static func shutsPastMinimum(fromEdge: CGFloat, minimum: CGFloat) -> Bool {
        fromEdge <= minimum - closePast
    }
    /// The slide open or shut once engaged, and a double-click's.
    public static var slideDuration: TimeInterval = 0.18
    /// The slide back when let go before engaging.
    public static var settleDuration: TimeInterval = 0.14
    /// **A flick** (Jason, 2026-09-26): a drag this fast — points a second,
    /// over the last `flickWindow` — looses the drawer at once, open or
    /// shut, without the full pull or push; after at least `flickTravel`, so
    /// a twitch on the handle doesn't count.
    public static var flickSpeed: CGFloat = 1000
    public static var flickTravel: CGFloat = 12
    public static var flickWindow: TimeInterval = 0.06
    /// **A swipe** (Jason, 2026-09-26): two fingers this far on a handle —
    /// only where the pointer shows the handle's resize cursor — toward
    /// its edge shuts the drawer, away from it opens it.
    public static var swipeDistance: CGFloat = 24

    /// How far the pointer pulls a closed drawer before it engages: always
    /// `engage`, whatever size it opens to.
    public static func engageDistance(opensTo target: CGFloat) -> CGFloat { engage }

    /// A closed drawer's extent while pulled `pull` from its edge, before it
    /// engages: the bite, then the slip.
    public static func opening(pull: CGFloat) -> CGFloat {
        let p = max(0, pull)
        return p <= bite ? p : bite + (p - bite) * slip
    }

    /// The drag's speed along the drawer's axis, points a second, from its
    /// recent samples (time, distance from the edge): positive is away from
    /// the edge. Over the last `flickWindow`; 0 with too little to go on.
    public static func speed(_ samples: [(t: TimeInterval, at: CGFloat)]) -> CGFloat {
        guard let last = samples.last,
              let first = samples.first(where: { $0.t >= last.t - flickWindow }),
              last.t - first.t > 0.004 else { return 0 }
        return (last.at - first.at) / CGFloat(last.t - first.t)
    }

    /// A flick open: fast enough away from the edge, and far enough.
    public static func flicksOpen(speed: CGFloat, pulled: CGFloat) -> Bool {
        speed >= flickSpeed && pulled >= flickTravel
    }

    /// A flick shut: fast enough toward the edge, and far enough.
    public static func flicksShut(speed: CGFloat, pushed: CGFloat) -> Bool {
        speed <= -flickSpeed && pushed >= flickTravel
    }

    /// Reduce Motion (System Settings ▸ Accessibility): no slides.
    static func duration(_ d: TimeInterval) -> TimeInterval {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? 0 : d
    }
}

/// One drawer sliding from one extent to another, drawn with the
/// controller's `peek`. Its timer runs in the common modes, so it keeps
/// going inside a drag's event-tracking loop.
@MainActor
final class PaneSlide {
    private var timer: Timer?
    private(set) var isDone = false

    init(controller: PaneController, split: String, from: CGFloat, to: CGFloat, target: CGFloat,
         duration: TimeInterval, done: @escaping @MainActor () -> Void) {
        let start = CACurrentMediaTime()
        controller.peekTarget[split] = target
        func step() -> Bool {
            let t = duration > 0 ? min((CACurrentMediaTime() - start) / duration, 1) : 1
            let eased = 1 - pow(1 - t, 3)   // ease out: quick, then settling
            controller.peek[split] = from + (to - from) * CGFloat(eased)
            controller.container?.needsLayout = true
            return t >= 1
        }
        if step() { finish(controller, split, done); return }
        let timer = Timer(timeInterval: 1.0 / 120, repeats: true) { [weak self, weak controller] _ in
            MainActor.assumeIsolated {
                guard let self, let controller, !self.isDone else { return }
                if step() { self.finish(controller, split, done) }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func finish(_ controller: PaneController, _ split: String, _ done: @MainActor () -> Void) {
        isDone = true
        timer?.invalidate()
        timer = nil
        controller.slides[split] = nil
        controller.peek[split] = nil
        controller.peekTarget[split] = nil
        done()
        controller.container?.needsLayout = true
    }

    /// Stops where it is, without its ending (a new drag took over).
    func cancel(_ controller: PaneController, _ split: String) {
        isDone = true
        timer?.invalidate()
        timer = nil
        controller.slides[split] = nil
    }
}

extension PaneController {
    /// What a split's sized side measures now, as drawn.
    func drawnExtent(_ splitID: String) -> CGFloat {
        if let p = peek[splitID] { return p }
        guard let split = root.split(splitID), let rect = container?.lastLayout.splits[splitID] else { return 0 }
        let st = displayState
        if st.isCollapsed(splitID) && split.collapsible { return 0 }
        return PaneLayout.sizedExtent(for: split, available: split.axis == .horizontal ? rect.width : rect.height,
                                      state: st)
    }

    /// The size a split's sized side opens to (its saved size, as it fits).
    func openExtent(_ splitID: String) -> CGFloat {
        guard let split = root.split(splitID), let rect = container?.lastLayout.splits[splitID] else { return 0 }
        var st = state
        st.splits[splitID, default: SplitState()].collapsed = false
        return PaneLayout.sizedExtent(for: split, available: split.axis == .horizontal ? rect.width : rect.height,
                                      state: st)
    }

    /// Slides a split's sized side from where it's drawn to `to`, then
    /// runs `done` (which makes the change the state).
    func slide(_ splitID: String, to: CGFloat, target: CGFloat, duration: TimeInterval,
               done: @escaping @MainActor () -> Void) {
        slides[splitID]?.cancel(self, splitID)
        let from = drawnExtent(splitID)
        slides[splitID] = PaneSlide(controller: self, split: splitID, from: from, to: to, target: target,
                                    duration: PaneClutch.duration(duration), done: done)
    }

    /// A slide or clutch in progress on this split stops where it is.
    func stopSliding(_ splitID: String) {
        slides[splitID]?.cancel(self, splitID)
    }

    /// `setOpen`, sliding open or shut (`PaneClutch.slideDuration`) rather
    /// than jumping. The change becomes the state when the slide ends.
    public func setOpen(_ splitID: String, _ open: Bool, animated: Bool) {
        guard animated, open != isOpen(splitID) || peek[splitID] != nil,
              let split = root.split(splitID), split.collapsible, container?.window != nil,
              !PaneLayout.isEmpty(split.sizedNode, state: state), !PaneLayout.isEmpty(split.mainNode, state: state)
        else { setOpen(splitID, open); return }
        let target = openExtent(splitID)
        slide(splitID, to: open ? target : 0, target: target, duration: PaneClutch.slideDuration) { [weak self] in
            self?.setOpen(splitID, open)
        }
    }

    public func toggle(_ splitID: String, animated: Bool) {
        setOpen(splitID, !isOpen(splitID), animated: animated)
    }
}

/// Two fingers on a handle (`PaneClutch.swipeDistance`): one gesture, one
/// open or shut. Only trackpad gestures (with phases); a mouse wheel and a
/// gesture's momentum after it fired pass through or are swallowed as the
/// comments say. Each handle view keeps one.
@MainActor
final class PaneSwipe {
    private var travel: CGFloat = 0
    private var fired = false
    /// The glide after a gesture that fired is swallowed too.
    private var swallowGlide = false
    private var lastEvent: TimeInterval = 0

    /// True if the event was the handle's (and shouldn't scroll anything).
    func scroll(_ e: NSEvent, split: Split, controller: PaneController) -> Bool {
        guard split.collapsible, e.hasPreciseScrollingDeltas else { return false }
        if e.momentumPhase != [] { return swallowGlide }
        // A new gesture: its start, or anything after a pause — so a gesture
        // whose start went elsewhere isn't blocked by the last one (measured:
        // the first swipe after a swipe shut was ignored).
        if e.phase.contains(.began) || e.phase.contains(.mayBegin) || e.timestamp - lastEvent > 0.25 {
            travel = 0; fired = false; swallowGlide = false
        }
        lastEvent = e.timestamp
        defer {
            if e.phase.contains(.ended) || e.phase.contains(.cancelled) {
                swallowGlide = fired; fired = false; travel = 0
            }
        }
        // The fingers' own direction, whichever way scrolling is set:
        // "natural" reports the content moving with the fingers.
        let sign: CGFloat = e.isDirectionInvertedFromDevice ? 1 : -1
        let down = e.scrollingDeltaY * sign, right = e.scrollingDeltaX * sign
        let towardEdge: CGFloat
        switch split.edge(in: controller.displayState) {
        case .top: towardEdge = -down
        case .bottom: towardEdge = down
        case .leading: towardEdge = -right
        case .trailing: towardEdge = right
        }
        travel += towardEdge
        if !fired {
            let open = controller.isOpen(split.id)
            if open, travel >= PaneClutch.swipeDistance {
                fired = true
                controller.setOpen(split.id, false, animated: true)
            } else if !open, travel <= -PaneClutch.swipeDistance {
                fired = true
                controller.setOpen(split.id, true, animated: true)
            }
        }
        return true
    }
}
