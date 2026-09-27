import SwiftUI
import AppKit

/// A reusable case in the tabbed Settings window (`spec/windows.md`, "A
/// reusable modal box"): some settings want more room, and more
/// attention, than sharing a page with everything else — a focused
/// window launched by a button on the page, rather than another section
/// on it. First used for "Set Up Triggers…" (the drawers' sensitivity,
/// `DrawerSensitivitySetting`); meant to be reached for again by later
/// items that want the same treatment, not rebuilt each time.
///
/// **Not app-modal** — a first version blocked every other ShowTools
/// window (`NSApp.runModal`) until Jason tried it and said so: "I was
/// wrong about making it demand the window." **Not tied to Settings'
/// lifecycle either** — a second version closed automatically when
/// Settings closed, which Jason then found could hide the box *behind*
/// Settings without him noticing it was still open (and unconfirmed)
/// back there. Settled on a floating panel instead (Jason: "persist above
/// all — most — windows until you click done. So you could keep it on
/// top while you try it on the real windows, then click done when you're
/// satisfied"): it sits above every ShowTools window, Settings included,
/// so it's never hidden behind anything, and closes only when its own
/// Done or close button says so — trying the real drawers behind it, or
/// closing Settings itself, doesn't touch it. `floatOnlyWhileActive`
/// keeps it from floating over *other apps'* windows too, the same fix
/// this app's own hand-built panels already needed. **Always opens
/// centered under the *Settings* window's own current bar**
/// (`TriggeringScreen.swift`, `positionUnderBar(of:)`) — follows Settings
/// if it's been dragged, rather than recentering on the monitor — never
/// restoring a previous position of its own. **Titled after the module
/// it came from** ("Drawer Sensitivity: Set Up Triggers"), passed in by
/// the caller as `section`.
@MainActor
enum SettingsBox {
    private static var open: (panel: NSPanel, delegate: NSWindowDelegate, tokens: [NSObjectProtocol])?

    /// `section` names the module the box came out of ("Drawer
    /// Sensitivity," not the tab it happens to sit on) — the window reads
    /// "Drawer Sensitivity: Set Up Triggers" (Jason, 2026-09-27: "it
    /// should be the module it came out of," correcting an earlier guess
    /// that used the tab's own name instead). `content` is handed a
    /// `dismiss` closure — call it from a Done button, or anywhere else
    /// inside, to close the box the same way its own close button does.
    static func present<Content: View>(
        section: String,
        title: String,
        @ViewBuilder content: @escaping (_ dismiss: @escaping () -> Void) -> Content
    ) {
        if let open {
            open.panel.makeKeyAndOrderFront(nil)
            return
        }

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false)
        panel.title = "\(section): \(title)"
        panel.isReleasedWhenClosed = false

        let dismiss: () -> Void = { panel.close() }
        panel.contentViewController = NSHostingController(rootView: content(dismiss))

        let delegate = ClearOnClose { SettingsBox.open = nil }
        panel.delegate = delegate
        let tokens = floatOnlyWhileActive(panel)
        open = (panel, delegate, tokens)

        // `isFloatingPanel`/`level` set after `contentViewController`:
        // both can touch the window's own attributes while laying it out,
        // and this is the one that has to stick. Confirmed with
        // `CGWindowListCopyWindowInfo` (`kCGWindowLayer`), not assumed
        // from a clean build — setting them earlier, before the content
        // controller was assigned, silently left the panel at layer 0 (an
        // ordinary window), not layer 3 (floating).
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.makeKeyAndOrderFront(nil)
        // Positioned on the next run-loop turn, not right after
        // `makeKeyAndOrderFront` itself: `frame.size` still reads the
        // panel's own initial `.zero` `contentRect` even immediately
        // after ordering it front — assigning `.contentViewController`
        // after creation, rather than through `NSWindow(contentViewController:)`,
        // doesn't resize the window to fit it synchronously; that
        // resize happens later, during layout. Found the same way as the
        // layer-ordering bug above: positioning right after
        // `makeKeyAndOrderFront` still centered off a zero-size frame
        // (the screen's raw midpoint, not the box's real ~420×420).
        // Deferring a turn — the same fix the Settings window itself
        // needed (`SettingsWindowCoordinator.captured`) — gives that
        // resize time to happen first.
        //
        // Anchored to the *Settings* window's own current frame, not the
        // screen (Jason, 2026-09-27: "the launch of the secondary window
        // needs to be relative to the current position of the settings
        // window") — follows Settings if it's been dragged, rather than
        // recentering independently on the monitor. Falls back to the
        // screen-relative position only if Settings' own window somehow
        // isn't tracked (shouldn't happen: this box only ever opens from
        // a button inside Settings).
        DispatchQueue.main.async {
            if let settings = SettingsWindowCoordinator.window {
                panel.positionUnderBar(of: settings)
            } else {
                panel.positionUnderTriggeringMonitorBar()
            }
        }
    }
}

private final class ClearOnClose: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    init(onClose: @escaping () -> Void) { self.onClose = onClose }
    func windowWillClose(_ notification: Notification) { onClose() }
}
