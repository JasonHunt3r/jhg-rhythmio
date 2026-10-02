import AppKit
import ServiceManagement
import RhythmIOCore

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

    /// RhythmIO owns the decision to start RhythmBG at login; RhythmBG no
    /// longer registers itself on first run. Its "Open at login" switch
    /// flips this same registration.
    static func registerAtLogin() {
        let service = SMAppService.loginItem(identifier: bundleID)
        guard service.status != .enabled else { return }
        do { try service.register() } catch {
            NSLog("RhythmBG login registration failed: \(error)")
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
        registerAtLogin()
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
}

enum RhythmBGError: LocalizedError {
    case notBundled

    var errorDescription: String? {
        "This build of RhythmIO doesn't carry RhythmBG. Build it with make-app.sh."
    }
}
