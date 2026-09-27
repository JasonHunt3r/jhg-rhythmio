import AppKit

/// Floating panels stop covering Settings while it's key
/// (`spec/windows.md`, "The windows pass," settled 2026-09-26: Settings
/// stays an ordinary, non-modal window — Apple's own guidance, not a
/// permanently-floating one — but panels step aside while it's the one
/// being used). SwiftUI's `Settings` scene gives no way to identify its
/// own window from outside, so it's matched by title — `"<app name>
/// Settings"`, exactly what SwiftUI itself titles it — checked fresh at
/// each key-window change, not captured once. **A first version instead
/// captured `NSApp.keyWindow` from `SettingsView.onAppear`** — measured
/// wrong: `.onAppear` isn't guaranteed to fire after the window has
/// actually become key (the same class of timing gotcha `UndoMenuState`,
/// this same target, already documents for `NSApp.keyWindow`), so it
/// silently captured whatever window was key a moment *before* Settings
/// took over, and panels never stepped aside. Found with a real Info
/// panel dragged to overlap a reopened Settings window — it stayed on
/// top; the by-title rewrite fixed it, checked the same way.
///
/// Scoped to this app's own hand-built panels (Info, Rhythm, the Slide
/// Editor, the library panel) — not PaneKit's own pop-outs (the Inspector,
/// the Timeline window), which don't know Settings exists and shouldn't be
/// given that dependency without a cleaner cross-package hook. Worth a
/// follow-up if it turns out to matter.
@MainActor
enum SettingsWindowCoordinator {
    private static var panels: [Weak] = []
    private static var observers: [NSObjectProtocol] = []
    private static let settingsTitle = "\(ProcessInfo.processInfo.processName) Settings"

    /// Called from each panel's `init`, so it steps aside while Settings
    /// is key and comes back once it isn't.
    static func register(_ panel: NSPanel) {
        panels.removeAll { $0.value == nil }
        panels.append(Weak(panel))
        installObserversIfNeeded()
    }

    /// Swift 6 won't let a non-isolated notification closure send the
    /// window itself across into `MainActor.assumeIsolated` (the same
    /// gotcha `UndoMenuState.init` already worked around, `ShowToolsApp
    /// .swift`) — reading `.title` (a plain, `Sendable` `String`) happens
    /// out here instead, before crossing that boundary.
    private static func installObserversIfNeeded() {
        guard observers.isEmpty else { return }
        let nc = NotificationCenter.default
        observers = [
            nc.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { note in
                let title = (note.object as? NSWindow)?.title
                MainActor.assumeIsolated {
                    guard title == settingsTitle else { return }
                    for p in panels { p.value?.level = .normal }
                }
            },
            nc.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { note in
                let title = (note.object as? NSWindow)?.title
                MainActor.assumeIsolated {
                    guard title == settingsTitle else { return }
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
