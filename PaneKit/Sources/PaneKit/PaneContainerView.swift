import AppKit

/// The view that lays out a `PaneController`'s tree: one host per pane,
/// one divider per split, and one edge handle per closable split. Frames
/// come from `PaneLayout` in a single pass (`layout()`), never from
/// constraints, so there's no size negotiation between panes to loop.
///
/// Flipped, so y grows downward, as `PaneLayout` assumes.
@MainActor
public final class PaneContainerView: NSView {
    public let controller: PaneController
    private var hosts: [String: PaneHostView] = [:]
    private var dividers: [String: PaneDividerView] = [:]
    private var handles: [String: PaneEdgeHandleView] = [:]
    /// The last layout, for drags to measure against.
    private(set) var lastLayout = PaneLayoutResult()

    /// `content` gives each pane's view, by pane id. Panes without one get
    /// an empty view.
    public init(controller: PaneController, content: [String: NSView]) {
        self.controller = controller
        super.init(frame: .zero)
        for pane in controller.root.panes {
            let host = PaneHostView(content: content[pane.id] ?? NSView())
            // So an app can tell, from any view inside, which pane it's in.
            host.identifier = NSUserInterfaceItemIdentifier(pane.id)
            hosts[pane.id] = host
            addSubview(host)
        }
        // Dividers and handles above the panes, so they get the mouse first.
        for split in controller.root.splits {
            let d = PaneDividerView(split: split, container: self)
            dividers[split.id] = d
            addSubview(d)
            if split.collapsible && split.handle == .edge {
                let h = PaneEdgeHandleView(split: split, container: self)
                handles[split.id] = h
                addSubview(h)
            }
        }
        setAccessibilityRole(.splitGroup)
        controller.container = self
    }

    required init?(coder: NSCoder) { fatalError("PaneContainerView is made in code") }

    public override var isFlipped: Bool { true }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        if controller.undoSource == nil { controller.undoSource = window }
        // Panes saved as popped out go back out, now there's a window to
        // put their windows beside.
        controller.syncWindows()
    }

    /// One pass: every frame from the model. Setting subviews' frames here
    /// is the normal thing to do in `layout()`; nothing here asks for
    /// another layout.
    public override func layout() {
        super.layout()
        let result = PaneLayout.layout(controller.root, in: bounds, state: controller.displayState,
                                       peek: controller.peek)
        lastLayout = result
        // A drawer sliding (`PaneClutch`): its pane's content keeps the
        // size it's heading for and slides, flush with the divider.
        var sliding: [String: PaneHostView.Slide] = [:]
        for (splitID, target) in controller.peekTarget {
            guard let split = controller.root.split(splitID), case .leaf(let pane) = split.sizedNode else { continue }
            sliding[pane.id] = .init(axis: split.axis, extent: target,
                                     flushWithEnd: split.sizedFirst(in: controller.displayState))
        }
        for (id, host) in hosts {
            if host.slide != sliding[id] { host.slide = sliding[id] }
        }
        for (id, host) in hosts where host.superview === self {
            if let frame = result.panes[id] {
                host.frame = frame
                host.isHidden = frame.width < 1 || frame.height < 1
            } else {
                host.isHidden = true
            }
        }
        for (id, divider) in dividers {
            if let line = result.dividers[id] {
                divider.frame = divider.split.axis == .horizontal
                    ? line.insetBy(dx: -PaneDividerView.grab, dy: 0)
                    : line.insetBy(dx: 0, dy: -PaneDividerView.grab)
                divider.isHidden = false
            } else {
                divider.isHidden = true
            }
        }
        for (id, handle) in handles {
            if let frame = result.handles[id] {
                handle.frame = frame
                handle.isHidden = false
            } else {
                handle.isHidden = true
            }
        }
    }

    /// Replaces a pane's content view.
    public func setContent(_ view: NSView, for paneID: String) {
        hosts[paneID]?.setContent(view)
    }

    /// A pane's content view, whether docked or out in a window.
    public func content(of paneID: String) -> NSView? { hosts[paneID]?.content }

    // MARK: Popping out

    /// Hands a pane's host to its window.
    func takeHost(_ paneID: String) -> PaneHostView? {
        guard let host = hosts[paneID] else { return nil }
        host.removeFromSuperview()
        host.isHidden = false
        return host
    }

    /// Takes a pane's host back from its window, below the dividers.
    func returnHost(_ host: PaneHostView, for paneID: String) {
        hosts[paneID] = host
        host.autoresizingMask = []
        if let firstDivider = subviews.first(where: { $0 is PaneDividerView || $0 is PaneEdgeHandleView }) {
            addSubview(host, positioned: .below, relativeTo: firstDivider)
        } else {
            addSubview(host)
        }
        needsLayout = true
    }
}

/// Holds one pane's content, and takes the mouse **only inside its own
/// frame** (ShowTools' `ColumnHost`): a SwiftUI hosting view hit-tests all
/// its content, clipped or not, and would steal a neighbour's clicks.
@MainActor
final class PaneHostView: NSView {
    private(set) var content: NSView

    init(content: NSView) {
        self.content = content
        super.init(frame: .zero)
        clipsToBounds = true
        addSubview(content)
    }

    required init?(coder: NSCoder) { fatalError("PaneHostView is made in code") }

    func setContent(_ view: NSView) {
        content.removeFromSuperview()
        content = view
        addSubview(view)
        needsLayout = true
    }

    /// Set while its drawer slides: the content's full extent along the
    /// axis, and which end it keeps flush with (the divider's side).
    struct Slide: Equatable {
        var axis: PaneAxis
        var extent: CGFloat
        var flushWithEnd: Bool
    }
    var slide: Slide? { didSet { if slide != oldValue { needsLayout = true } } }

    override func layout() {
        super.layout()
        guard let s = slide else { content.frame = bounds; return }
        // Unflipped: y grows upward. A drawer at the top (sized first) has
        // its divider at the bottom, so its content sits on y = 0.
        switch s.axis {
        case .vertical:
            let h = max(s.extent, bounds.height)
            content.frame = CGRect(x: 0, y: s.flushWithEnd ? 0 : bounds.height - h, width: bounds.width, height: h)
        case .horizontal:
            let w = max(s.extent, bounds.width)
            content.frame = CGRect(x: s.flushWithEnd ? bounds.width - w : 0, y: 0, width: w, height: bounds.height)
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard frame.contains(point) else { return nil }
        return super.hitTest(point)
    }
}

/// The line between a split's children, with a wider strip to grab. Drag
/// to resize the sized side; drag past half its minimum to close it
/// against its edge; double-click to close it.
@MainActor
final class PaneDividerView: NSView {
    /// How far the grab strip reaches either side of the line.
    static let grab: CGFloat = 3
    let split: Split
    private weak var container: PaneContainerView?

    init(split: Split, container: PaneContainerView) {
        self.split = split
        self.container = container
        super.init(frame: .zero)
        setAccessibilityRole(.splitter)
        setAccessibilityLabel("\(split.sizedTitle) divider")
    }

    required init?(coder: NSCoder) { fatalError("PaneDividerView is made in code") }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.separatorColor.setFill()
        let line = split.axis == .horizontal
            ? NSRect(x: bounds.midX - PaneLayout.dividerThickness / 2, y: 0,
                     width: PaneLayout.dividerThickness, height: bounds.height)
            : NSRect(x: 0, y: bounds.midY - PaneLayout.dividerThickness / 2,
                     width: bounds.width, height: PaneLayout.dividerThickness)
        line.fill()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: split.axis == .horizontal ? .resizeLeftRight : .resizeUpDown)
    }

    override func mouseDown(with event: NSEvent) {
        guard let container else { return }
        if event.clickCount == 2, split.collapsible {
            container.controller.setOpen(split.id, false, animated: true)
            return
        }
        trackResize(split, in: container, from: event)
    }
}

/// A closed pane's grip on the window edge: always visible, clickable.
/// Drag it to pull the pane out to a size; double-click it to open the
/// pane at its last size.
@MainActor
final class PaneEdgeHandleView: NSView {
    let split: Split
    private weak var container: PaneContainerView?

    init(split: Split, container: PaneContainerView) {
        self.split = split
        self.container = container
        super.init(frame: .zero)
        toolTip = "Drag, or double-click, to show \(split.sizedTitle)"
        setAccessibilityRole(.button)
        setAccessibilityLabel("Show \(split.sizedTitle)")
    }

    required init?(coder: NSCoder) { fatalError("PaneEdgeHandleView is made in code") }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.setFill()
        bounds.fill()
        // A line along the edge, and a capsule to grab: the frame strip's bar.
        NSColor.separatorColor.setFill()
        let horizontal = split.axis == .horizontal
        let edgeLine: NSRect
        switch split.edge(in: container?.controller.displayState ?? PaneKitState()) {
        case .leading: edgeLine = NSRect(x: bounds.maxX - 1, y: 0, width: 1, height: bounds.height)
        case .trailing: edgeLine = NSRect(x: 0, y: 0, width: 1, height: bounds.height)
        case .top: edgeLine = NSRect(x: 0, y: bounds.maxY - 1, width: bounds.width, height: 1)
        case .bottom: edgeLine = NSRect(x: 0, y: 0, width: bounds.width, height: 1)
        }
        edgeLine.fill()
        NSColor.secondaryLabelColor.withAlphaComponent(0.7).setFill()
        let capsule = horizontal
            ? NSRect(x: bounds.midX - 1.5, y: bounds.midY - 20, width: 3, height: 40)
            : NSRect(x: bounds.midX - 20, y: bounds.midY - 1.5, width: 40, height: 3)
        NSBezierPath(roundedRect: capsule, xRadius: 1.5, yRadius: 1.5).fill()
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: split.axis == .horizontal ? .resizeLeftRight : .resizeUpDown)
    }

    override func mouseDown(with event: NSEvent) {
        guard let container else { return }
        if event.clickCount == 2 {
            container.controller.setOpen(split.id, true, animated: true)
            return
        }
        trackResize(split, in: container, from: event)
    }

    override func accessibilityPerformPress() -> Bool {
        container?.controller.setOpen(split.id, true)
        return true
    }
}

/// A drag on a divider or a handle, tracked here until the mouse comes up.
/// An open side's size follows the pointer and is drawn live; on release
/// it's one transaction. A drag that never moves changes nothing.
///
/// **The clutch** (`PaneClutch`, Jason 2026-09-26): pulled from closed, the
/// side bites, slips, then engages and slides open to its size (a drag that
/// carries on resizes it from there); let go first, it slides back shut.
/// Pushed below its minimum it resists, and slides shut once pushed
/// `closeEngage` past it; let go first, it springs back to its minimum.
///
/// `keepGrabOffset`: for an `.external` handle, grabbed anywhere on the
/// app's own view rather than on the edge line — the sized side changes
/// by how far the pointer moves, so it doesn't jump to the pointer on the
/// first step (`handleDragExtent`).
@MainActor
func trackResize(_ split: Split, in container: PaneContainerView, from event: NSEvent,
                 keepGrabOffset: Bool = false) {
    guard let window = container.window, let rect = container.lastLayout.splits[split.id] else { return }
    let controller = container.controller
    // A slide still running (a double-click a moment ago) stops where it is,
    // and the drag carries on from there.
    let drawnAtStart = controller.drawnExtent(split.id)
    controller.stopSliding(split.id)
    let start = container.convert(event.locationInWindow, from: nil)
    var moved = false
    var dragStart = controller.state
    let edge = split.edge(in: dragStart)
    let total = split.axis == .horizontal ? rect.width : rect.height
    func distance(_ p: CGPoint) -> CGFloat {
        switch edge {
        case .leading: p.x - rect.minX
        case .trailing: rect.maxX - p.x
        case .top: p.y - rect.minY
        case .bottom: rect.maxY - p.y
        }
    }
    let startedClosed = dragStart.isCollapsed(split.id) && split.collapsible
    let startExtent = startedClosed ? drawnAtStart : PaneLayout.sizedExtent(for: split, available: total, state: dragStart)
    let minimum = split.range.lowerBound
    let target = controller.openExtent(split.id)

    enum Phase { case pulling, engaging, resizing, resisting, shutting }
    var phase: Phase = startedClosed ? .pulling : .resizing
    /// Added to the pointer's reading once a pulled drawer has engaged, so
    /// the drag carries on from its opened size without a jump.
    var shift: CGFloat = 0
    var lastFromEdge = startExtent

    func fromEdge(_ p: CGPoint) -> CGFloat {
        let raw = keepGrabOffset || startedClosed
            ? handleDragExtent(startExtent: startExtent, grabbedAt: distance(start), pointerAt: distance(p))
            : distance(p)
        return raw + shift
    }

    while let e = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
        if e.type == .leftMouseUp { break }
        let p = container.convert(e.locationInWindow, from: nil)
        if !moved, hypot(p.x - start.x, p.y - start.y) < 3 { continue }
        moved = true
        let at = fromEdge(p)
        lastFromEdge = at
        switch phase {
        case .pulling:
            if at >= PaneClutch.engageDistance(opensTo: target) {
                // Engaged: slide open; the drag resizes from there.
                phase = .engaging
                controller.slide(split.id, to: target, target: target, duration: PaneClutch.slideDuration) {
                    controller.setOpen(split.id, true)
                    dragStart = controller.state
                    shift = target - (lastFromEdge - shift)
                    phase = .resizing
                }
            } else {
                controller.peekTarget[split.id] = target
                controller.peek[split.id] = PaneClutch.opening(pull: at)
                container.needsLayout = true
            }
        case .engaging, .shutting:
            break   // the slide is running; its ending sets what's next
        case .resizing, .resisting:
            if split.collapsible && at < minimum {
                if PaneClutch.shuts(fromEdge: at, minimum: minimum) {
                    phase = .shutting
                    controller.live = nil
                    controller.slide(split.id, to: 0, target: max(target, minimum),
                                     duration: PaneClutch.slideDuration) {
                        controller.setOpen(split.id, false)
                    }
                } else {
                    phase = .resisting
                    controller.peekTarget[split.id] = max(target, minimum)
                    controller.peek[split.id] = PaneClutch.closing(fromEdge: at, minimum: minimum)
                    container.needsLayout = true
                }
            } else {
                phase = .resizing
                controller.peek[split.id] = nil
                controller.peekTarget[split.id] = nil
                controller.liveChange { s in
                    dragResize(split, root: controller.root, fromEdge: at, total: total,
                               start: dragStart, into: &s)
                }
            }
        }
    }

    switch phase {
    case .pulling:
        // Let go before it engaged: back shut, nothing saved.
        guard moved else { return }
        controller.slide(split.id, to: 0, target: target, duration: PaneClutch.settleDuration) {}
    case .resisting:
        // Let go before it shut: back to its minimum, open.
        controller.slide(split.id, to: minimum, target: max(target, minimum),
                         duration: PaneClutch.settleDuration) {
            controller.liveChange { s in
                dragResize(split, root: controller.root, fromEdge: minimum, total: total,
                           start: dragStart, into: &s)
            }
            controller.endLive()
        }
    case .resizing:
        if moved { controller.endLive() }
    case .engaging, .shutting:
        break   // the slide finishes on its own
    }
}

/// Where a drag on an app's own handle puts the sized side: its size when
/// the drag began, plus how far the pointer has moved since (both measured
/// from the edge the side sits on). Pure, so it's tested.
func handleDragExtent(startExtent: CGFloat, grabbedAt: CGFloat, pointerAt: CGFloat) -> CGFloat {
    startExtent + (pointerAt - grabbedAt)
}

/// One step of a drag: the sized side follows the pointer (`fromEdge`,
/// its distance from the edge the side was on when the drag began, in a
/// split `total` long), closing past half its minimum if it can. Worked
/// out from the state the drag **started** with, never the previous step,
/// so it stays right however many steps there are — including dragging
/// back over a switch of sides, which undoes it.
///
/// **Switching sides** (`Split.canSwitchSides`, Jason, 2026-09-25): dragged
/// across the main side until what's left between the pointer and the far
/// edge is less than the side's own size at the start, it trades places
/// with main — mounted on the opposite edge, open, at that starting size.
///
/// `linkedAncestor` (`PaneNode.row`'s `nearIsRigid`): the ancestor's stored
/// size moves by the same amount. The amount is the change in the space
/// the sized side *occupies* — its size plus the divider when open, just
/// the handle when closed — so a drag that crosses into or out of closed
/// moves the ancestor exactly as `PaneController.setOpen` does. Before, a
/// drag shut left the ancestor at the open size and the neighbour grew by
/// the whole closed width (Edit Show's Browser, measured on Jason's own
/// copy, 2026-09-25: 236 → 545 pt), and a drag open from the handle shrank
/// it by the same.
func dragResize(_ split: Split, root: PaneNode, fromEdge: CGFloat, total: CGFloat,
                start: PaneKitState, into s: inout PaneKitState) {
    func occupied(_ st: SplitState?) -> CGFloat {
        (st?.collapsed ?? false) && split.collapsible
            ? PaneLayout.closedThickness(split)
            : (st?.size ?? split.defaultSize) + PaneLayout.dividerThickness
    }
    var st = start.splits[split.id] ?? SplitState()
    let startSize = min(max(st.size ?? split.defaultSize, split.range.lowerBound), split.range.upperBound)
    if split.canSwitchSides && fromEdge > startSize && total - fromEdge < startSize {
        st.onOtherSide.toggle()
        st.collapsed = false
        st.size = startSize
    } else if split.collapsible && fromEdge < split.range.lowerBound / 2 {
        st.collapsed = true
    } else {
        st.collapsed = false
        st.size = min(max(fromEdge, split.range.lowerBound), split.range.upperBound)
    }
    if let id = split.linkedAncestor, let ancestor = root.split(id) {
        var ancestorState = start.splits[id] ?? SplitState()
        let from = ancestorState.size ?? ancestor.defaultSize
        let delta = occupied(st) - occupied(start.splits[split.id])
        ancestorState.size = min(max(from + delta, ancestor.range.lowerBound), ancestor.range.upperBound)
        s.splits[id] = ancestorState
    }
    s.splits[split.id] = st
}
