import AppKit
import ServiceManagement
import RhythmIOCore
import RhythmBGCore

/// RhythmBG lives inside RhythmIO, at `Contents/Library/LoginItems/RhythmBG.app`
/// (spec/xcode-port.md). Nothing is copied out any more: View ▸ Desktop Show…
/// launches the nested copy and registers it to start at login, and deleting
/// RhythmIO takes RhythmBG, its tiles and its login item with it.
enum RhythmBGHelper {
    static let bundleID = "com.jhg.rhythmbg"

    /// The nested RhythmBG, or nil under `swift run`, which has no bundle.
    static var nestedURL: URL? {
        let url = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/RhythmBG.app")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// RhythmIO owns the decision to start RhythmBG at login; RhythmBG can't
    /// change it from inside (B-87). Settings ▸ RhythmBG flips it.
    ///
    /// True when this call registered it. Registering starts it at once
    /// (launchd), so the caller mustn't open a second copy (B-08).
    @discardableResult
    static func registerAtLogin() -> Bool {
        let service = SMAppService.loginItem(identifier: bundleID)
        guard service.status != .enabled else { return false }
        do {
            try service.register()
            return service.status == .enabled
        } catch {
            NSLog("RhythmBG login registration failed: \(error)")
            return false
        }
    }

    static func unregisterAtLogin() {
        let service = SMAppService.loginItem(identifier: bundleID)
        guard service.status == .enabled else { return }
        do { try service.unregister() } catch {
            NSLog("RhythmBG login unregistration failed: \(error)")
        }
    }

    static var isRegisteredAtLogin: Bool {
        SMAppService.loginItem(identifier: bundleID).status == .enabled
    }

    /// Launches RhythmBG and opens its window.
    static func openDesktop() throws {
        guard let nestedURL else { throw RhythmBGError.notBundled }
        if registerAtLogin() {
            // Registering just started RhythmBG as the login item; opening it
            // too in the same breath started a second copy, the two racing
            // past each other (B-08, measured 2026-10-02: pids 6124 and 6130,
            // the same second). Wait for that copy, then ask it for its window.
            askForWindowOnceRunning(orOpen: nestedURL, triesLeft: 30)
            return
        }
        open(nestedURL)
    }

    /// Polls every 0.1 s for a running RhythmBG; opens it after `triesLeft`
    /// runs out (registered but not started — waiting for approval, say).
    private static func askForWindowOnceRunning(orOpen url: URL, triesLeft: Int) {
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        if running.contains(where: \.isFinishedLaunching) {
            NSWorkspace.shared.open(URL(string: "rhythmbg://window")!)
        } else if triesLeft == 0 {
            open(url)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                askForWindowOnceRunning(orOpen: url, triesLeft: triesLeft - 1)
            }
        }
    }

    private static func open(_ nestedURL: URL) {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: nestedURL, configuration: config) { _, error in
            if let error { return NSLog("RhythmBG didn't open: \(error)") }
            // RhythmBG has no window of its own at launch (it's an agent),
            // so ask it for one.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                NSWorkspace.shared.open(URL(string: "rhythmbg://window")!)
            }
        }
    }

    /// Item 21, `RhythmIO Feedback — Worklist for Next CC Session.md`:
    /// "Launch RhythmBG when launching RhythmIO." No window request — this is
    /// meant to be silent, just getting the desktop background ready, not
    /// popping RhythmBG's own window in front of RhythmIO's every time it
    /// opens. A no-op if it's already running (its own accessory-app
    /// activation policy means a second launch would still just reopen it
    /// quietly, but there's no reason to ask twice).
    static func launchAtRhythmIOStartupIfEnabled() {
        guard UserDefaults.standard.bool(forKey: launchWithRhythmIOKey), let nestedURL else { return }
        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty else { return }
        NSWorkspace.shared.openApplication(at: nestedURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error { NSLog("RhythmBG didn't open at RhythmIO launch: \(error)") }
        }
    }

    static let launchWithRhythmIOKey = "launchRhythmBGWithRhythmIO"

    /// A monitor for Play on Desktop's submenu (B-17).
    struct Monitor: Identifiable {
        let id: String      // the display's uuid, RhythmBG's key for it
        let name: String
    }

    /// The monitors as RhythmBG names them: its own name for one, else
    /// macOS's model name.
    static func monitors() -> [Monitor] {
        let names = DesktopSettingsStore.standard().load().displayNames
        return NSScreen.screens.compactMap { screen in
            guard let n = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32,
                  let u = CGDisplayCreateUUIDFromDisplayID(n)?.takeRetainedValue() else { return nil }
            let id = CFUUIDCreateString(nil, u) as String
            return Monitor(id: id, name: names[id].flatMap { $0.isEmpty ? nil : $0 } ?? screen.localizedName)
        }
    }

    /// Hands a show to RhythmBG, starting it if need be: to one monitor (its
    /// current Space), or with nil to every screen (B-17). Sent to this
    /// RhythmIO's own RhythmBG, not whichever copy answers `rhythmbg://`.
    static func playOnDesktop(show: Int64, library: URL, monitor: String?) {
        guard let nestedURL else { return NSLog("Play on Desktop: no RhythmBG in this build") }
        var c = URLComponents()
        c.scheme = "rhythmbg"
        c.host = "play"
        c.queryItems = [URLQueryItem(name: "show", value: String(show)),
                        URLQueryItem(name: "library", value: library.path)]
            + (monitor.map { [URLQueryItem(name: "display", value: $0)] } ?? [])
        guard let url = c.url else { return }
        NSWorkspace.shared.open([url], withApplicationAt: nestedURL,
                                configuration: NSWorkspace.OpenConfiguration()) { _, error in
            if let error { NSLog("Play on Desktop: RhythmBG didn't open: \(error)") }
        }
    }
}

enum RhythmBGError: LocalizedError {
    case notBundled

    var errorDescription: String? {
        "This build of RhythmIO doesn't carry RhythmBG. Build it with make-app.sh."
    }
}
