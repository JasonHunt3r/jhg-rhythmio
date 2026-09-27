import AppKit

/// Where a freshly-shown auxiliary window (Settings, or a `SettingsBox`)
/// should appear (Jason, 2026-09-27): centered under the triggering
/// monitor's own bar, pinned near the top rather than the screen's
/// vertical center — "centered top under main window bar," not dead
/// center of the screen. Never restores a saved position across launches
/// or reopens — see `positionUnderTriggeringMonitorBar` for the one-line
/// way back to that, if it turns out to be wanted after all.
enum TriggeringScreen {
    /// Wherever the pointer is right now — since that's where the click
    /// or keyboard shortcut that's opening the window just happened —
    /// falling back to the key window's own screen, then `NSScreen.main`,
    /// rather than whichever screen a window's own current (possibly
    /// stale, possibly off a monitor that's since been unplugged) frame
    /// happens to sit on — the trap in `NSWindow.center()` this exists to
    /// avoid.
    @MainActor
    static var current: NSScreen? {
        NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
            ?? NSApp.keyWindow?.screen
            ?? NSScreen.main
    }

    /// A main window's own title bar plus toolbar, measured from this
    /// app's actual chrome (32 pt title bar, 56 pt toolbar — Settings' own
    /// toolbar, `AXToolbar` in an axtool dump). The vertical offset a
    /// freshly-opened auxiliary window sits under, so it reads as docked
    /// below a bar rather than floating in the screen's middle.
    static let barHeight: CGFloat = 88
}

extension NSWindow {
    /// Horizontally centered on `TriggeringScreen.current`, its top edge
    /// pinned `TriggeringScreen.barHeight` below the screen's own visible
    /// top (under the menu bar) — never restored from a previous launch's
    /// or a previous open's saved position. To make a particular window
    /// remember where it was left instead, give it its own
    /// `setFrameAutosaveName(_:)` and call this only when
    /// `setFrameUsingName(_:)` returns `false` (nothing saved yet) —
    /// deliberately not built that way today.
    @MainActor
    func positionUnderTriggeringMonitorBar() {
        guard let screen = TriggeringScreen.current else { center(); return }
        let vf = screen.visibleFrame
        setFrameOrigin(NSPoint(
            x: vf.midX - frame.width / 2,
            y: vf.maxY - TriggeringScreen.barHeight - frame.height))
    }

    /// The same idea, but anchored to another window's own current frame
    /// instead of a screen — for a secondary window (`SettingsBox`)
    /// opened from inside another one (Settings): Jason, 2026-09-27, "the
    /// launch of the secondary window needs to be relative to the current
    /// position of the settings window," not recentered independently on
    /// the monitor. Follows `referenceWindow` wherever it's currently
    /// sitting, including if it's been dragged.
    @MainActor
    func positionUnderBar(of referenceWindow: NSWindow) {
        let rf = referenceWindow.frame
        setFrameOrigin(NSPoint(
            x: rf.midX - frame.width / 2,
            y: rf.maxY - TriggeringScreen.barHeight - frame.height))
    }
}
