import AppKit

/// How a drawer feels under the pointer (Jason, 2026-09-26: "a cantilevered
/// clutch"). Pulled from closed, it **bites** — follows the pointer at once,
/// so you know you're onto something — then **slips**, lagging the pointer
/// while it's pulled further, until it's sure: then it **engages** and slides
/// quickly open to its size. Let go before that and it slides back shut.
/// Pushed shut, the same pressure the other way: it resizes as usual down to
/// its minimum, resists past it, and slides shut once pushed far enough;
/// let go before and it springs back to its minimum. A double-click (and an
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
    /// How far the pointer must pull a closed drawer before it engages:
    /// about half the size it opens to, within these bounds.
    public static var engageFraction: CGFloat = 0.5
    public static var engageRange: ClosedRange<CGFloat> = 48...110
    /// How far past its minimum an open drawer must be pushed to go shut.
    public static var closeEngage: CGFloat = 48
    /// The slide open or shut once engaged, and a double-click's.
    public static var slideDuration: TimeInterval = 0.18
    /// The slide back when let go before engaging.
    public static var settleDuration: TimeInterval = 0.14

    /// How far the pointer pulls a closed drawer before it engages.
    public static func engageDistance(opensTo target: CGFloat) -> CGFloat {
        min(max(target * engageFraction, engageRange.lowerBound), engageRange.upperBound)
    }

    /// A closed drawer's extent while pulled `pull` from its edge, before it
    /// engages: the bite, then the slip.
    public static func opening(pull: CGFloat) -> CGFloat {
        let p = max(0, pull)
        return p <= bite ? p : bite + (p - bite) * slip
    }

    /// An open drawer's extent while pushed to `fromEdge`, below its
    /// minimum `minimum`, before it goes shut: it resists.
    public static func closing(fromEdge: CGFloat, minimum: CGFloat) -> CGFloat {
        fromEdge >= minimum ? fromEdge : max(0, minimum - (minimum - fromEdge) * slip)
    }

    /// Whether a push to `fromEdge` has gone far enough to shut it.
    public static func shuts(fromEdge: CGFloat, minimum: CGFloat) -> Bool {
        fromEdge <= minimum - closeEngage
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
