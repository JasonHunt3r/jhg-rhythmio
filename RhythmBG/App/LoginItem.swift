import AppKit

/// Starting at login. RhythmBG is nested inside RhythmIO
/// (`Contents/Library/LoginItems`) and registered as that host's login
/// item, which only the host can change: from in here the status reads
/// not-registered and `register()` fails with SMAppService error 22,
/// "Invalid argument" (B-87, 2026-10-02). So the switch lives in RhythmIO ▸
/// Settings ▸ RhythmBG, and RhythmBG's "Open at Login…" opens that tab
/// (Jason, 2026-10-03).
enum LoginItem {
    /// The RhythmIO this copy sits inside, so the request reaches it and
    /// not some other copy that also answers `rhythmio://` (a test build).
    static var host: URL? {
        let url = Bundle.main.bundleURL.deletingLastPathComponent()   // LoginItems
            .deletingLastPathComponent()                               // Library
            .deletingLastPathComponent()                               // Contents
            .deletingLastPathComponent()                               // RhythmIO.app
        return url.pathExtension == "app" ? url : nil
    }

    static func openSettingsInRhythmIO() {
        guard let host else { return Log.write("login item: not nested in RhythmIO") }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open([URL(string: "rhythmio://settings/rhythmbg")!], withApplicationAt: host,
                                configuration: config) { _, error in
            if let error { Log.write("login item: RhythmIO didn't open: \(error)") }
        }
    }
}
