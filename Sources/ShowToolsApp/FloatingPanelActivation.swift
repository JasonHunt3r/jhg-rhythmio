import AppKit

/// Stops a floating panel floating over *other apps'* windows — the same
/// fix PaneKit's own pop-outs already have (`PaneWindowController.init`,
/// `PaneKit/PaneWindows.swift`): `.floating` is a window **level**, and
/// levels rank windows across every app on screen, not just this one, so
/// a panel that's always `.floating` sits above every other app's windows
/// all the time — even with ShowTools in the background, even with
/// `PanelHidingSetting` off (a panel that isn't hiding still shouldn't be
/// floating over someone else's work). Drops to `.normal` whenever
/// ShowTools isn't the active app; back to `.floating` when it is again.
///
/// Found from real feedback, 2026-09-27: "bringing the focus back to the
/// settings should have also brought the other app windows back as a
/// package" — a panel that's always `.floating` never left in the first
/// place, so there was nothing to bring back; this is what actually makes
/// it part of ShowTools' own window group instead of sitting permanently
/// above everyone else's.
///
/// Call once, right after setting a panel's initial `.level = .floating`,
/// and keep the returned tokens alive for the panel's own lifetime (an
/// instance property, removed in `deinit`) — letting them go silently
/// stops the observers.
@MainActor
func floatOnlyWhileActive(_ window: NSPanel) -> [NSObjectProtocol] {
    let nc = NotificationCenter.default
    return [
        nc.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak window] _ in
            MainActor.assumeIsolated { window?.level = .floating }
        },
        nc.addObserver(forName: NSApplication.didResignActiveNotification, object: nil, queue: .main) { [weak window] _ in
            MainActor.assumeIsolated { window?.level = .normal }
        },
    ]
}
