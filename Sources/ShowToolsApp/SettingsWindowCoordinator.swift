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
///    (`applyTitleFormat`, below, fixes that same collision cosmetically
///    — "ShowTools Settings: Library" — but this file still identifies
///    the window by object identity, never by title.)
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
    /// Reset on every close, so the next open re-centers — see
    /// `TriggeringScreen.swift`: Settings always opens under the
    /// triggering monitor's own bar, never restoring where it was left,
    /// but shouldn't jump back there just from a tab switch or from
    /// clicking away to another app and back while it's still open.
    private static var hasPositionedSinceOpen = false
    private static var titleObservation: NSKeyValueObservation?

    private static let titlePrefix = "ShowTools Settings: "

    /// The real Settings `NSWindow`, for anything that needs to follow its
    /// current position — `SettingsBox`, whose own launch position is
    /// relative to wherever Settings currently sits, not the monitor.
    static var window: NSWindow? { settingsWindow }

    /// The selected tab's own name ("Windows," "Library"…), read back out
    /// of the window's own formatted title rather than tracked separately
    /// — `SettingsBox` uses it to title itself "Windows: Set Up Triggers"
    /// (Jason, 2026-09-27), so a box always says which tab it came from.
    static var currentTabName: String? {
        guard let title = settingsWindow?.title, title.hasPrefix(titlePrefix) else { return nil }
        return String(title.dropFirst(titlePrefix.count))
    }

    /// "ShowTools Settings: Windows," not just "Windows" (Jason,
    /// 2026-09-27) — the tabbed `Settings` scene titles its window after
    /// whichever pane is selected, on its own, with no modifier to change
    /// that format; this also happens to be the exact "Library" collision
    /// with the main window's own title this file's history already
    /// flagged as a reason title-matching couldn't identify the window.
    /// Kept as a plain prefix check (not a KVO-only formatter) so it's
    /// applied once immediately on capture, not only from the next tab
    /// switch onward.
    private static func applyTitleFormat(to window: NSWindow) {
        guard !window.title.hasPrefix(titlePrefix) else { return }
        window.title = titlePrefix + window.title
    }

    /// Called from `SettingsView`'s own `WindowAccessor`, which reads the
    /// real `NSWindow` a hosted view sits in — correct regardless of
    /// timing, and unaffected by the window's title changing per tab.
    static func captured(_ window: NSWindow) {
        guard settingsWindow !== window else { return }
        settingsWindow = window
        installObserversIfNeeded()
        applyTitleFormat(to: window)
        // SwiftUI resets the title to the plain pane name on every tab
        // switch, so this has to be ongoing, not a one-time fix — KVO on
        // `title` itself rather than another notification, since there's
        // no "tab changed" notification to hook. Setting the title again
        // inside its own KVO callback re-enters once, harmlessly:
        // `applyTitleFormat`'s own prefix check makes the second call a
        // no-op.
        titleObservation = window.observe(\.title, options: [.new]) { window, _ in
            MainActor.assumeIsolated {
                SettingsWindowCoordinator.applyTitleFormat(to: window)
            }
        }
        // `WindowAccessor` hands the window over via `DispatchQueue.main
        // .async`, so this — the very first time this window is ever
        // seen — runs *after* its own first `didBecomeKeyNotification`
        // already fired with no observer installed yet to hear it: found
        // by testing, the become-key-only version below never actually
        // positioned anything on a fresh launch. Position it right here
        // instead, once, for exactly that first open; every later
        // close-then-reopen goes through the become-key observer, which
        // by then is already installed.
        if !hasPositionedSinceOpen {
            hasPositionedSinceOpen = true
            UserDefaults.standard.removeObject(forKey: "NSWindow Frame com_apple_SwiftUI_Settings_window")
            window.positionUnderTriggeringMonitorBar()
        }
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
                    if !hasPositionedSinceOpen {
                        hasPositionedSinceOpen = true
                        // SwiftUI's `Settings` scene keeps its own
                        // autosaved frame under this fixed key and
                        // restores it around this same moment, winning
                        // over a plain reposition here or even one
                        // deferred a run-loop turn — found by testing,
                        // both landed the window right back where the
                        // saved key put it. Clearing the key first, so
                        // there's nothing left for it to restore *from*,
                        // is what actually sticks.
                        UserDefaults.standard.removeObject(forKey: "NSWindow Frame com_apple_SwiftUI_Settings_window")
                        settingsWindow.positionUnderTriggeringMonitorBar()
                    }
                }
            },
            nc.addObserver(forName: NSWindow.didResignKeyNotification, object: nil, queue: .main) { note in
                let id = (note.object as AnyObject as? NSObject).map(ObjectIdentifier.init)
                MainActor.assumeIsolated {
                    guard let id, let settingsWindow, id == ObjectIdentifier(settingsWindow) else { return }
                    for p in panels { p.value?.level = NSApp.isActive ? .floating : .normal }
                }
            },
            // So the *next* open re-centers instead of keeping wherever
            // this one ended up (a tab switch resizes the window without
            // resigning key, so this alone — not resignKey — is "closed").
            nc.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { note in
                let id = (note.object as AnyObject as? NSObject).map(ObjectIdentifier.init)
                MainActor.assumeIsolated {
                    guard let id, let settingsWindow, id == ObjectIdentifier(settingsWindow) else { return }
                    hasPositionedSinceOpen = false
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
