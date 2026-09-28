import SwiftUI
import AppKit

/// What `List(selection:)` gives an app for free that a plain `ScrollView`
/// doesn't: the arrow keys step the selection, and the newly-selected row
/// scrolls into view. Built for a translucent sidebar that can't be a real
/// `List` — `NSTableView` doesn't compose with `.withinWindow` vibrancy at
/// all (measured, ShowTools' Catalog, 2026-09-27: identical, completely
/// flat result whether the effect view was nested via `.safeAreaInset` or
/// a true sibling via `.overlay`) — but this piece has nothing ShowTools-
/// specific in it, so it lives here for any PaneKit app building the same
/// kind of hand-rolled sidebar.
///
/// Deliberately narrow. It doesn't render rows, know about hierarchy, or
/// handle Delete/Return/rename/drag — the app keeps building its own
/// content exactly as it would inside a `List` (recursive
/// `DisclosureGroup`s and all), and its own key handling for everything
/// but the arrows. All this needs is `order`: the current, flat, *visible*
/// row order — folded branches already excluded by the app, since only it
/// knows its own fold state — and each row already carrying a matching
/// `.id(_:)` for `ScrollViewProxy.scrollTo` to find.
public struct PaneListNavigation<ID: Hashable>: ViewModifier {
    @Binding var selection: ID?
    let order: [ID]

    public init(selection: Binding<ID?>, order: [ID]) {
        self._selection = selection
        self.order = order
    }

    public func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .background(PaneArrowKeys { delta in move(by: delta, proxy: proxy) })
        }
    }

    private func move(by delta: Int, proxy: ScrollViewProxy) {
        guard let next = Self.stepped(selection, in: order, by: delta) else { return }
        selection = next
        withAnimation(.default) { proxy.scrollTo(next) }
    }

    /// Pure: pinned by `PaneKitTests`, not by eye. `nil` selection (or one
    /// no longer in `order`, a fold having hidden it) starts from either
    /// end, matching which direction was pressed; otherwise clamps at the
    /// ends rather than wrapping — an arrow held at the top or bottom of
    /// the list should stop, not jump to the other end.
    static func stepped(_ selection: ID?, in order: [ID], by delta: Int) -> ID? {
        guard !order.isEmpty else { return nil }
        guard let current = selection, let i = order.firstIndex(of: current) else {
            return delta > 0 ? order.first : order.last
        }
        return order[min(max(i + delta, 0), order.count - 1)]
    }
}

public extension View {
    /// See `PaneListNavigation`.
    func paneListNavigation<ID: Hashable>(selection: Binding<ID?>, order: [ID]) -> some View {
        modifier(PaneListNavigation(selection: selection, order: order))
    }
}

/// Watches the Up/Down arrow keys while this view's window is key, the same
/// way ShowToolsApp's own `SingleKeys` watches whatever keys an app gives
/// it — a small, self-contained copy, not a dependency on app code, since
/// PaneKit is its own package. Only steps in outside text editing, so
/// typing in a rename field or a search box is never intercepted.
private struct PaneArrowKeys: NSViewRepresentable {
    /// `-1` (Up) or `1` (Down).
    let handle: (Int) -> Void

    func makeNSView(context: Context) -> KeyView { KeyView() }
    func updateNSView(_ view: KeyView, context: Context) { view.handle = handle }

    final class KeyView: NSView {
        var handle: ((Int) -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                // The `NSEvent?` return crosses back out of `assumeIsolated`
                // itself, which the newer SDK's stricter Sendable checking
                // on `NSEvent` won't allow — so only a plain `Bool` (trivially
                // Sendable) comes out of the isolated call, and the actual
                // event is handed back to AppKit here, outside it. The same
                // shape `PaneContainerView`'s own pointer monitor already
                // uses.
                let swallow = MainActor.assumeIsolated { self?.swallows(event) ?? false }
                return swallow ? nil : event
            }
        }

        /// True for a key this used: AppKit never sees it.
        private func swallows(_ event: NSEvent) -> Bool {
            guard let window, event.window === window, window.attachedSheet == nil,
                  !(window.firstResponder is NSText), !event.isARepeat else { return false }
            switch event.keyCode {
            case 125: handle?(1); return true   // Down
            case 126: handle?(-1); return true  // Up
            default: return false
            }
        }

        isolated deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
        }
    }
}
