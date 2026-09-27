import AppKit
import SwiftUI

/// Floating panels stop covering Settings while it's key
/// (`spec/windows.md`, "The windows pass," settled 2026-09-26: Settings
/// stays an ordinary, non-modal window — Apple's own guidance, not a
/// permanently-floating one — but panels step aside while it's the one
/// being used). SwiftUI's `Settings` scene gives no way to identify its
/// own window from outside, so `SettingsView` hands it over itself, via
/// `WindowAccessor` — reading the actual `NSWindow` a hosted `NSView` sits
/// in, not guessing from timing or title. The window is captured once and
/// compared by identity from then on.
///
/// **Two wrong versions before this one, both found by testing, not
/// assumed correct:**
/// 1. Captured `NSApp.keyWindow` from `SettingsView.onAppear` — wrong,
///    the same class of timing gotcha `UndoMenuState` (this same target)
///    already documents for `NSApp.keyWindow`: `.onAppear` isn't
///    guaranteed to fire after the window's actually become key, so it
///    silently captured the *previous* key window instead.
/// 2. Matched by title (`"<app name> Settings"`, what SwiftUI titled the
///    window before it had tabs) — broke the moment Settings became a
///    `TabView` (2026-09-27, "a pro style window... with tabs"): the
///    title now names whichever *pane* is selected ("Library," "Editing"…
///    — the HIG's own "title naming the pane"), and "Library" collides
///    with the main window's own title when no collection is selected.
///
/// Both found the same way: a real Info panel dragged to overlap a
/// reopened Settings window, watched with screenshots, not just checked
/// for a compile-clean build.
///
/// Scoped to this app's own hand-built panels (Info, Rhythm, the Slide
/// Editor, the library panel) — not PaneKit's own pop-outs (the Inspector,
/// the Timeline window), which don't know Settings exists and shouldn't be
/// given that dependency without a cleaner cross-package hook. Worth a
/// follow-up if it turns out to matter.
@MainActor
enum SettingsWindowCoordinator {
    private static weak var settingsWindow: NSWindow?
    private static var panels: [Weak] = []
    private static var observers: [NSObjectProtocol] = []

    /// Called from `SettingsView`'s own `WindowAccessor`, which reads the
    /// real `NSWindow` a hosted view sits in — correct regardless of
    /// timing, and unaffected by the window's title changing per tab.
    static func captured(_ window: NSWindow) {
        guard settingsWindow !== window else { return }
        settingsWindow = window
        installObserversIfNeeded()
    }

    /// Called from each panel's `init`, so it steps aside while Settings
    /// is key and comes back once it isn't.
    static func register(_ panel: NSPanel) {
        panels.removeAll { $0.value == nil }
        panels.append(Weak(panel))
    }

    /// Swift 6 won't let a non-isolated notification closure send the
    /// window itself across into `MainActor.assumeIsolated` (the same
    /// gotcha `UndoMenuState.init` already worked around, `ShowToolsApp
    /// .swift`) — `ObjectIdentifier` is a plain, `Sendable` value, so it's
    /// computed out here instead, and only that crosses the boundary.
    private static func installObserversIfNeeded() {
        guard observers.isEmpty else { return }
        let nc = NotificationCenter.default
        observers = [
            nc.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { note in
                let id = (note.object as AnyObject as? NSObject).map(ObjectIdentifier.init)
                MainActor.assumeIsolated {
                    guard let id, let settingsWindow, id == ObjectIdentifier(settingsWindow) else { return }
                    for p in panels { p.value?.level = .normal }
                }
            },
            nc.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { note in
                let id = (note.object as AnyObject as? NSObject).map(ObjectIdentifier.init)
                MainActor.assumeIsolated {
                    guard let id, let settingsWindow, id == ObjectIdentifier(settingsWindow) else { return }
                    for p in panels { p.value?.level = NSApp.isActive ? .floating : .normal }
                }
            },
        ]
    }

    private struct Weak {
        weak var value: NSPanel?
        init(_ v: NSPanel) { value = v }
    }
}

/// Hands back the real `NSWindow` a hosted `NSView` sits in — reliable
/// regardless of SwiftUI view-lifecycle timing, unlike reading
/// `NSApp.keyWindow` from `.onAppear` (see `SettingsWindowCoordinator`'s
/// own history). `updateNSView` runs again whenever SwiftUI re-diffs this
/// view, which is enough to catch the window if it wasn't attached yet on
/// the first pass.
struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { if let w = view.window { onWindow(w) } }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { if let w = nsView.window { onWindow(w) } }
    }
}
