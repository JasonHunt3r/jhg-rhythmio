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
    /// An open drawer's handle row, shown only while the pointer is over
    /// its divider or the row itself (`showHoverHandle`).
    private var hoverHandles: [String: PaneEdgeHandleView] = [:]
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
                let hover = PaneEdgeHandleView(split: split, container: self, hover: true)
                hover.isHidden = true
                hover.alphaValue = 0
                hoverHandles[split.id] = hover
                addSubview(hover)
            }
        }
        setAccessibilityRole(.splitGroup)
        controller.container = self
    }

    required init?(coder: NSCoder) { fatalError("PaneContainerView is made in code") }

    public override var isFlipped: Bool { true }

    /// How much of this container's own height, at its top, is really the
    /// window's title bar rather than ordinary content — zero for an
    /// ordinary window, and zero for a container that doesn't reach up
    /// under the title bar at all. That's every nested container, and a
    /// root one SwiftUI has already placed below the bar through its own
    /// safe area. Reserving the window's whole strip regardless, as this
    /// first did, stacked one empty title-bar-high band per container
    /// down the window (Jason's screenshot, 2026-09-27: two above Edit
    /// Show's picture, one above the Library pane). Measured against
    /// `contentLayoutRect`, which already accounts for a toolbar, not
    /// stored, so it's always current.
    private var titleBarHeight: CGFloat {
        guard let window, window.styleMask.contains(.fullSizeContentView) else { return 0 }
        let top = convert(bounds, to: nil).maxY
        return min(max(0, top - window.contentLayoutRect.maxY), Self.titleBarHeight(of: window))
    }

    /// The same figure, for an app's own content to size a matching spacer
    /// or overlay against — a `scrollsUnderTitleBar` pane doesn't otherwise
    /// know how tall the strip it's extending into is.
    public static func titleBarHeight(of window: NSWindow?) -> CGFloat {
        guard let window, window.styleMask.contains(.fullSizeContentView) else { return 0 }
        return window.frame.height - window.contentLayoutRect.height
    }

    /// Sets up a window so a pane marked `scrollsUnderTitleBar` has
    /// somewhere to extend into: `.fullSizeContentView` reserves no space of
    /// its own for the title bar, and `titlebarAppearsTransparent` stops
    /// AppKit painting over whatever that pane draws there. Call once, as
    /// soon as the window exists — this only sets the two window properties;
    /// it doesn't draw anything itself (`spec/windows.md`, item 34's rework,
    /// 2026-09-27).
    public static func enableContentUnderTitleBar(on window: NSWindow) {
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
    }

    // MARK: The resize cursor

    /// The resize cursor over every divider and handle, reliably. Cursor
    /// rects alone weren't: inside a SwiftUI-hosted area the hosting view
    /// sets its own arrow, so a nested divider or an app's handle showed the
    /// arrow while dragging still worked (Jason, 2026-09-26; measured with
    /// the cursor in screenshots — the main window's own divider was fine,
    /// Edit Slides' inspector divider and the Slide viewer's grip weren't —
    /// and tracking areas on the views never fired). So the layout watches
    /// the window's pointer moves itself, and whenever the view under the
    /// pointer is one of its handles, sets the cursor last.
    private var pointerMonitor: Any?

    private func watchPointer() {
        if let pointerMonitor { NSEvent.removeMonitor(pointerMonitor) }
        pointerMonitor = nil
        guard let window else { return }
        window.acceptsMouseMovedEvents = true
        pointerMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .cursorUpdate]) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, let window = self.window, event.window === window,
                      let frame = window.contentView?.superview,
                      let hit = frame.hitTest(frame.convert(event.locationInWindow, from: nil)) as? PaneResizeCursorView,
                      hit.isDescendant(of: self), let axis = hit.cursorAxis else { return }
                showResizeCursor(for: axis)
            }
            return event
        }
    }

    isolated deinit {
        if let pointerMonitor { NSEvent.removeMonitor(pointerMonitor) }
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        watchPointer()
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
                                       peek: controller.peek, contentExtent: controller.contentExtent,
                                       titleBarHeight: titleBarHeight,
                                       scrollsUnderTitleBarOverride: controller.scrollsUnderTitleBarOverride)
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
        for (id, hover) in hoverHandles {
            if let frame = hoverFrame(id, in: result) {
                hover.frame = frame
            } else {
                hover.isHidden = true
                hover.alphaValue = 0
            }
        }
    }

    // MARK: The handle row on hover

    /// Jason, 2026-09-27: "for dividers that hide the handle on open, let's
    /// add show handle row on mouseover." An open `.edge` drawer leaves only
    /// a thin divider; hovering it shows the closed drawer's own handle row
    /// along it, on the drawer's side, for as long as the pointer is on the
    /// divider or the row. The row drags like the divider, and a double-
    /// click closes the drawer, as on the divider.
    private func hoverFrame(_ id: String, in result: PaneLayoutResult) -> NSRect? {
        guard let line = result.dividers[id], let split = controller.root.split(id) else { return nil }
        let t = PaneLayout.handleThickness
        switch split.edge(in: controller.displayState) {
        case .leading: return NSRect(x: line.minX - t, y: line.minY, width: t, height: line.height)
        case .trailing: return NSRect(x: line.maxX, y: line.minY, width: t, height: line.height)
        case .top: return NSRect(x: line.minX, y: line.minY - t, width: line.width, height: t)
        case .bottom: return NSRect(x: line.minX, y: line.maxY, width: line.width, height: t)
        }
    }

    func pointerEntered(split id: String) {
        guard let hover = hoverHandles[id], let frame = hoverFrame(id, in: lastLayout) else { return }
        hover.frame = frame
        if hover.isHidden { hover.alphaValue = 0; hover.isHidden = false }
        NSAnimationContext.runAnimationGroup { $0.duration = 0.12; hover.animator().alphaValue = 1 }
    }

    /// Hides the row once the pointer is on neither the divider nor the
    /// row — asked of where the pointer actually is, a moment later, rather
    /// than by counting enter and exit events between the two views.
    func pointerExited(split id: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, let hover = self.hoverHandles[id], !hover.isHidden, let window else { return }
            let p = self.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            let divider = self.dividers[id]?.frame ?? .zero
            if hover.frame.contains(p) || divider.contains(p) { return }
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.2; hover.animator().alphaValue = 0 },
                                                 completionHandler: { MainActor.assumeIsolated {
                                                     if hover.alphaValue == 0 { hover.isHidden = true } } })
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
/// frame** (RhythmIO' `ColumnHost`): a SwiftUI hosting view hit-tests all
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
final class PaneDividerView: NSView, PaneResizeCursorView {
    var cursorAxis: PaneAxis? { split.axis }
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
        // A drawer that hides its handle row while open shows it again on
        // hover (`PaneContainerView.pointerEntered`).
        if split.collapsible && split.handle == .edge {
            addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                           owner: self))
        }
    }

    required init?(coder: NSCoder) { fatalError("PaneDividerView is made in code") }

    override func mouseEntered(with event: NSEvent) { container?.pointerEntered(split: split.id) }
    override func mouseExited(with event: NSEvent) { container?.pointerExited(split: split.id) }

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
        container.pointerExited(split: split.id)
    }

    private let swipe = PaneSwipe()
    override func scrollWheel(with event: NSEvent) {
        if let container, swipe.scroll(event, split: split, controller: container.controller) { return }
        super.scrollWheel(with: event)
    }
}

/// How every drawer's edge handle (`PaneEdgeHandleView`) fills its
/// background: solid, as always, unless the app says otherwise. An app
/// with its own translucent bars can have the handles match them (RhythmIO'
/// "Include handles", Jason 2026-09-27: "There are many handle rows, on
/// each drawer"). `translucency` gives, for dark or light, how opaque the
/// window's background is laid over the OS's own header material — 0 the
/// bare material, 1 solid; nil (for the whole hook, or for one
/// appearance), solid. Call `changed()` after setting it,
/// or while a slider previews it, and every handle redraws.
@MainActor public enum PaneHandleAppearance {
    public static var translucency: ((_ dark: Bool) -> CGFloat?)?
    static let didChange = Notification.Name("PaneHandleAppearanceDidChange")

    public static func changed() {
        NotificationCenter.default.post(name: didChange, object: nil)
    }
}

/// A closed pane's grip on the window edge: always visible, clickable.
/// Drag it to pull the pane out to a size; double-click it to open the
/// pane at its last size.
@MainActor
final class PaneEdgeHandleView: NSView, PaneResizeCursorView {
    var cursorAxis: PaneAxis? { split.axis }
    let split: Split
    private weak var container: PaneContainerView?
    /// Under the fill, shown only while `PaneHandleAppearance` is
    /// translucent.
    private let material = NSVisualEffectView()
    private var observer: NSObjectProtocol?

    /// The same row shown over an open drawer's divider on hover
    /// (`PaneContainerView.pointerEntered`): it drags like the divider, a
    /// double-click closes the drawer, and it isn't its own accessibility
    /// element — the divider already is.
    let hover: Bool

    init(split: Split, container: PaneContainerView, hover: Bool = false) {
        self.split = split
        self.container = container
        self.hover = hover
        super.init(frame: .zero)
        if hover {
            // Fades in and out (`alphaValue`), which only draws with a layer.
            wantsLayer = true
            setAccessibilityElement(false)
            addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                           owner: self))
        } else {
            toolTip = "Drag, or double-click, to show \(split.sizedTitle)"
            setAccessibilityRole(.button)
            setAccessibilityLabel("Show \(split.sizedTitle)")
        }
        material.material = .headerView
        material.blendingMode = .withinWindow
        material.state = .active
        material.autoresizingMask = [.width, .height]
        material.frame = bounds
        addSubview(material, positioned: .below, relativeTo: nil)
        marks.handle = self
        marks.autoresizingMask = [.width, .height]
        marks.frame = bounds
        addSubview(marks)
        applyAppearance()
        observer = NotificationCenter.default.addObserver(forName: PaneHandleAppearance.didChange, object: nil,
                                                          queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyAppearance() }
        }
    }

    required init?(coder: NSCoder) { fatalError("PaneEdgeHandleView is made in code") }

    isolated deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    override var isFlipped: Bool { true }

    private var opacity: CGFloat? {
        let dark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return PaneHandleAppearance.translucency?(dark) ?? nil
    }

    private func applyAppearance() {
        material.isHidden = opacity == nil
        needsDisplay = true
        marks.needsDisplay = true
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        applyAppearance()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.windowBackgroundColor.withAlphaComponent(opacity ?? 1).setFill()
        bounds.fill()
    }

    /// The line along the edge and the capsule to grab — what makes it read
    /// as a handle. Its own view, above `material`: drawn in the handle's
    /// own `draw`, the translucent material (a subview) covered them
    /// (Jason, 2026-09-27: "you've lost the little pill icon").
    private final class Marks: NSView {
        weak var handle: PaneEdgeHandleView?
        override var isFlipped: Bool { true }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func draw(_ dirtyRect: NSRect) {
            guard let handle else { return }
            NSColor.separatorColor.setFill()
            let edgeLine: NSRect
            switch handle.split.edge(in: handle.container?.controller.displayState ?? PaneKitState()) {
            case .leading: edgeLine = NSRect(x: bounds.maxX - 1, y: 0, width: 1, height: bounds.height)
            case .trailing: edgeLine = NSRect(x: 0, y: 0, width: 1, height: bounds.height)
            case .top: edgeLine = NSRect(x: 0, y: bounds.maxY - 1, width: bounds.width, height: 1)
            case .bottom: edgeLine = NSRect(x: 0, y: 0, width: bounds.width, height: 1)
            }
            edgeLine.fill()
            NSColor.secondaryLabelColor.withAlphaComponent(0.7).setFill()
            let capsule = handle.split.axis == .horizontal
                ? NSRect(x: bounds.midX - 1.5, y: bounds.midY - 20, width: 3, height: 40)
                : NSRect(x: bounds.midX - 20, y: bounds.midY - 1.5, width: 40, height: 3)
            NSBezierPath(roundedRect: capsule, xRadius: 1.5, yRadius: 1.5).fill()
        }
    }
    private let marks = Marks()

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: split.axis == .horizontal ? .resizeLeftRight : .resizeUpDown)
    }

    override func mouseDown(with event: NSEvent) {
        guard let container else { return }
        if event.clickCount == 2 {
            container.controller.setOpen(split.id, !hover, animated: true)
            return
        }
        trackResize(split, in: container, from: event)
        // The drag's own event loop swallowed any exit; ask where the
        // pointer ended up.
        if hover { container.pointerExited(split: split.id) }
    }

    override func mouseEntered(with event: NSEvent) { if hover { container?.pointerEntered(split: split.id) } }
    override func mouseExited(with event: NSEvent) { if hover { container?.pointerExited(split: split.id) } }

    override func accessibilityPerformPress() -> Bool {
        container?.controller.setOpen(split.id, true)
        return true
    }

    private let swipe = PaneSwipe()
    override func scrollWheel(with event: NSEvent) {
        if let container, swipe.scroll(event, split: split, controller: container.controller) { return }
        super.scrollWheel(with: event)
    }
}

/// A drag on a divider or a handle, tracked here until the mouse comes up.
/// An open side's size follows the pointer and is drawn live; on release
/// it's one transaction. A drag that never moves changes nothing.
///
/// **The clutch** (`PaneClutch`, Jason 2026-09-26): pulled from closed, the
/// side bites, slips, then engages — and the drag is over: it slides open
/// to its own size, the pointer let go; let go first, it slides back shut.
/// An open side dragged slowly is only repositioned — down to its minimum,
/// never shut; a flick shuts it (the drag over), as it opens a closed one.
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
    let dragStart = controller.state
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
    let startExtent = startedClosed ? drawnAtStart
        : PaneLayout.sizedExtent(for: split, available: total, state: dragStart, contentExtent: controller.contentExtent)
    let minimum = split.range.lowerBound
    let target = controller.openExtent(split.id)

    /// `released`: it engaged — sliding open or shut on its own, the drag
    /// over (Jason, 2026-09-26: like a bow, it looses at the threshold).
    enum Phase { case pulling, resizing, released }
    var phase: Phase = startedClosed ? .pulling : .resizing

    /// The pointer's distance from the edge, as the sized side would have it.
    func raw(_ p: CGPoint) -> CGFloat {
        keepGrabOffset || startedClosed
            ? handleDragExtent(startExtent: startExtent, grabbedAt: distance(start), pointerAt: distance(p))
            : distance(p)
    }

    /// Engaged: the drawer takes over and the pointer is let go. The rest of
    /// this press is swallowed by the loop below — nothing under the pointer
    /// sees it — until the button comes up.
    func release() {
        phase = .released
        NSCursor.arrow.set()
        // Tap-to-drag with drag lock: the trackpad driver itself keeps the
        // button down until the next tap, and nothing an app does ends it —
        // measured 2026-09-26 in RhythmIO with Accessibility granted: a
        // posted system mouse-up cleared the button state, but 15–90 drags
        // still arrived in the next 3 s. Posting it only ended this loop
        // early and let those drags reach the views underneath, so it isn't
        // done; the loop below swallows the rest of the press until the
        // real mouse-up (the tap).
    }

    /// Recent (time, distance) readings, for a flick's speed.
    var samples: [(t: TimeInterval, at: CGFloat)] = []

    /// When the button came up: a flick usually ends with the release, so
    /// its speed is judged then too, if the pointer was still moving.
    var upTime: TimeInterval?

    while let e = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
        if e.type == .leftMouseUp { upTime = e.timestamp; break }
        if phase == .released { continue }
        let p = container.convert(e.locationInWindow, from: nil)
        if !moved, hypot(p.x - start.x, p.y - start.y) < 3 { continue }
        moved = true
        let at = raw(p)
        samples.append((e.timestamp, at))
        if samples.count > 12 { samples.removeFirst() }
        let speed = PaneClutch.speed(samples)
        switch phase {
        case .pulling:
            if at >= PaneClutch.engageDistance(opensTo: target)
                || PaneClutch.flicksOpen(speed: speed, pulled: at - startExtent) {
                // Loosed: it slides open to its own size.
                release()
                controller.slide(split.id, to: target, target: target, duration: PaneClutch.slideDuration) {
                    controller.setOpen(split.id, true)
                }
            } else {
                controller.peekTarget[split.id] = target
                controller.peek[split.id] = PaneClutch.opening(pull: at)
                container.needsLayout = true
            }
        case .resizing:
            // A slow drag repositions down to the minimum, where the divider
            // stops dead; carried on `closePast` beyond it, it looses the
            // drawer shut (Jason, 2026-09-26). A flick shuts it at once.
            if split.collapsible, PaneClutch.flicksShut(speed: speed, pushed: startExtent - at)
                || PaneClutch.shutsPastMinimum(fromEdge: at, minimum: minimum) {
                release()
                controller.live = nil
                controller.slide(split.id, to: 0, target: max(target, minimum),
                                 duration: PaneClutch.slideDuration) {
                    controller.setOpen(split.id, false)
                }
            } else {
                controller.liveChange { s in
                    dragResize(split, root: controller.root, fromEdge: max(at, minimum), total: total,
                               start: dragStart, into: &s)
                }
            }
        case .released:
            break
        }
    }

    // Let go mid-flick: the flick counts, open or shut.
    if moved, let up = upTime, let last = samples.last, up - last.t < PaneClutch.flickWindow {
        let speed = PaneClutch.speed(samples)
        if phase == .pulling, PaneClutch.flicksOpen(speed: speed, pulled: last.at - startExtent) {
            controller.slide(split.id, to: target, target: target, duration: PaneClutch.slideDuration) {
                controller.setOpen(split.id, true)
            }
            return
        }
        if phase == .resizing, split.collapsible,
           PaneClutch.flicksShut(speed: speed, pushed: startExtent - last.at) {
            controller.live = nil
            controller.slide(split.id, to: 0, target: max(target, minimum), duration: PaneClutch.slideDuration) {
                controller.setOpen(split.id, false)
            }
            return
        }
    }

    switch phase {
    case .pulling:
        // Let go before it engaged: back shut, nothing saved.
        guard moved else { return }
        controller.slide(split.id, to: 0, target: target, duration: PaneClutch.settleDuration) {}
    case .resizing:
        if moved { controller.endLive() }
    case .released:
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

