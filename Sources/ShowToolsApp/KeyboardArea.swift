import AppKit
import Observation
import SwiftUI

/// Which area of a window the arrow keys belong to: **the area last
/// clicked** (Jason, 2026-09-28, B-03, `spec/conventions.md` §2). Before
/// any click, nothing is recorded and the timeline, the active area, keeps
/// them. A window-wide key handler that wants the arrows (the timeline's)
/// asks `timelineHasArrows` first, so a clicked list or the viewer gets
/// them instead.
///
/// One monitor, installed at launch; each window keeps its own answer, so
/// a popped-out Timeline window and the main window don't overwrite each
/// other. Observable, so a selection can draw grey while its area doesn't
/// have the keyboard (the Mac's way of showing it, Jason, 2026-10-02).
@MainActor @Observable
final class KeyboardArea {
    enum Area: Equatable {
        case sidebar, browser, viewer, inspector, slideList, timeline, detail
    }

    static let shared = KeyboardArea()

    /// By window number. A window not in here hasn't been clicked yet.
    private(set) var areas: [Int: Area] = [:]
    @ObservationIgnored private var monitor: Any?

    /// PaneKit pane id → area; the nearest mapped pane holding the click
    /// wins. Panes nested inside these (the viewer drawer's `grid` and
    /// `viewer`, the preview's `picture` and `frameStrip`) aren't listed,
    /// so they count as the area around them.
    private static let panes: [String: Area] = [
        "library": .sidebar,
        "list": .browser,
        "preview": .viewer,
        "inspector": .inspector,
        "main": .slideList,
        "storyline": .timeline,
        "detail": .detail,
    ]

    static func install() {
        guard shared.monitor == nil else { return }
        shared.monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            MainActor.assumeIsolated { shared.clicked(event) }
            return event
        }
    }

    func area(in window: NSWindow?) -> Area? {
        window.flatMap { areas[$0.windowNumber] }
    }

    /// The timeline's arrows: unless another area that uses the arrows
    /// itself was clicked last in this window.
    func timelineHasArrows(in window: NSWindow?) -> Bool {
        timelineHasArrows(windowNumber: window?.windowNumber)
    }

    func timelineHasArrows(windowNumber: Int?) -> Bool {
        switch windowNumber.flatMap({ areas[$0] }) {
        case .sidebar, .browser, .viewer, .inspector, .slideList: false
        case .timeline, .detail, nil: true
        }
    }

    /// The Library grid's: the detail clicked last, or nothing yet.
    func gridHasArrows(windowNumber: Int?) -> Bool {
        switch windowNumber.flatMap({ areas[$0] }) {
        case .detail, nil: true
        default: false
        }
    }

    private func clicked(_ event: NSEvent) {
        // `hitTest` takes a point in the view's superview's coordinates;
        // the content view's own are flipped, which mirrors the click
        // top to bottom (measured: a timeline click read as the viewer).
        guard let window = event.window, let content = window.contentView,
              let hit = content.hitTest(content.superview?.convert(event.locationInWindow, from: nil)
                                        ?? event.locationInWindow) else { return }
        var view: NSView? = hit
        while let v = view {
            if let id = v.identifier?.rawValue, let area = Self.panes[id] {
                if areas[window.windowNumber] != area { areas[window.windowNumber] = area }
                return
            }
            view = v.superview
        }
        // Outside every pane (the title bar, the toolbar): no change.
    }
}

/// Tells a SwiftUI view which window it's in, again whenever it moves (a
/// pane popping out moves its views to another window).
struct WindowNumberReader: NSViewRepresentable {
    @Binding var windowNumber: Int?

    func makeNSView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.changed = { n in if windowNumber != n { windowNumber = n } }
        return view
    }

    func updateNSView(_ view: ReaderView, context: Context) {
        view.changed = { n in if windowNumber != n { windowNumber = n } }
    }

    final class ReaderView: NSView {
        var changed: ((Int?) -> Void)?
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            let n = window?.windowNumber
            DispatchQueue.main.async { [weak self] in self?.changed?(n) }
        }
    }
}

extension EnvironmentValues {
    /// Whether the selections drawn here belong to the area with the
    /// keyboard: accent colour if so, grey if not (`KeyboardArea`).
    @Entry var selectionHasKeyboard: Bool = true
}

extension Color {
    /// A selection's colour: the accent while its area has the keyboard,
    /// grey while another area does — the Mac's way of showing which.
    static func selection(_ hasKeyboard: Bool) -> Color {
        hasKeyboard ? .accentColor : Color(nsColor: .systemGray)
    }
}
