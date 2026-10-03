import AppKit
import SwiftUI

/// The Mac's own popover (`NSPopover`, so it looks exactly like SwiftUI's
/// `.popover`), with the app deciding when it closes. SwiftUI's closes on
/// any click outside it, can spend that click doing so, and allows one at
/// a time. Measured 2026-10-03 (`spec/popoverkit.md`) with
/// `.applicationDefined`: two show at once, a click outside reaches what
/// was clicked and leaves both open, a click-through popover passes its
/// clicks to the window under it, and swapping the content keeps it open.
@MainActor
public final class PinnedPopover {
    private let popover = NSPopover()
    private var host: NSHostingController<AnyView>?
    private weak var anchor: NSView?

    /// Clicks go to whatever is under the popover, as if it weren't there
    /// (a hover card). Set before the click: the window server takes a
    /// moment to learn of it (measured: a click in the same instant was
    /// still caught).
    public var passesClicksThrough = false {
        didSet { applyClickThrough() }
    }

    /// Fades in and out. Off for a popover that should simply be there.
    public var animates: Bool {
        get { popover.animates }
        set { popover.animates = newValue }
    }

    public init() {
        popover.behavior = .applicationDefined
    }

    public var isShown: Bool { popover.isShown }

    /// Shows `content` beside `anchor`, or moves it there if it's showing
    /// elsewhere. `edge` is the anchor's side it opens on.
    public func show<Content: View>(_ content: Content, anchor: NSView, edge: NSRectEdge = .maxY) {
        update(content)
        if popover.isShown {
            guard self.anchor !== anchor else { return }
            // NSPopover has no "move to another view": close and reopen.
            popover.close()
        }
        self.anchor = anchor
        popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: edge)
        applyClickThrough()
    }

    /// Replaces what's in it, open or not, without closing it.
    public func update<Content: View>(_ content: Content) {
        if let host {
            host.rootView = AnyView(content)
        } else {
            let h = NSHostingController(rootView: AnyView(content))
            h.sizingOptions = [.preferredContentSize]
            host = h
            popover.contentViewController = h
        }
    }

    public func close() {
        if popover.isShown { popover.close() }
    }

    private func applyClickThrough() {
        popover.contentViewController?.view.window?.ignoresMouseEvents = passesClicksThrough
    }
}

// MARK: - SwiftUI

public extension View {
    /// A `PinnedPopover` on this view: open while `isPresented`, closed
    /// only when it turns false (or the view goes). Unlike `.popover`, it
    /// never closes itself, never takes a click to close, and any number
    /// can be open. Keys like Esc are the app's to handle.
    func pinnedPopover<Content: View>(isPresented: Bool, passesClicksThrough: Bool = false,
                                      animates: Bool = true, arrowEdge: Edge = .top,
                                      @ViewBuilder content: @escaping () -> Content) -> some View {
        background(PinnedPopoverAnchor(isPresented: isPresented, passesClicksThrough: passesClicksThrough,
                                       animates: animates, edge: arrowEdge, content: content))
    }
}

/// The plain NSView a popover points at, filling the SwiftUI view.
final class PopoverAnchorView: NSView {
    // Not flipped, so `.maxY` is the top whatever the host's flipping.
    override var isFlipped: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

struct PinnedPopoverAnchor<Content: View>: NSViewRepresentable {
    let isPresented: Bool
    let passesClicksThrough: Bool
    let animates: Bool
    let edge: Edge
    let content: () -> Content

    final class Coordinator {
        let popover = MainActor.assumeIsolated { PinnedPopover() }
        /// What the latest update asked for, read when a deferred show
        /// runs: the view may have been told to close in between.
        var wanted = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeNSView(context: Context) -> PopoverAnchorView { PopoverAnchorView() }

    func updateNSView(_ view: PopoverAnchorView, context: Context) {
        let c = context.coordinator
        let p = c.popover
        p.passesClicksThrough = passesClicksThrough
        p.animates = animates
        c.wanted = isPresented
        guard isPresented else { return p.close() }
        if p.isShown {
            p.update(content())
            return
        }
        // The first update comes before the view is in a window, or sized.
        let made = content()
        let nsEdge = Self.rectEdge(edge)
        DispatchQueue.main.async {
            guard c.wanted, !p.isShown, view.window != nil, view.bounds.width > 0 else { return }
            p.show(made, anchor: view, edge: nsEdge)
        }
    }

    static func dismantleNSView(_ view: PopoverAnchorView, coordinator: Coordinator) {
        coordinator.wanted = false
        coordinator.popover.close()
    }

    static func rectEdge(_ edge: Edge) -> NSRectEdge {
        switch edge {
        case .top: .maxY
        case .bottom: .minY
        case .leading: .minX
        case .trailing: .maxX
        }
    }
}
