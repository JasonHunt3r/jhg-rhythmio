import AppIntents
import AppKit
import SwiftUI
import WidgetKit

/// RhythmBG's Control Center tiles (spec/rhythmbg.md, B5). A tile's action
/// runs here, in the sandboxed extension, never in the app (measured), so
/// each reaches RhythmBG by a `rhythmbg://` URL opened without activating
/// it; that also launches RhythmBG if it isn't running (measured).
@main
struct RhythmBGControls: WidgetBundle {
    var body: some Widget {
        OpenRhythmBGControl()
        DesktopShowControl()
    }
}

enum RhythmBGURL {
    static func open(_ s: String) async {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        _ = try? await NSWorkspace.shared.open(URL(string: s)!, configuration: config)
    }
}

/// Whether the desktop show is on, as RhythmBG last wrote it for the tiles
/// (`~/Library/Application Support/RhythmBG/control-state.json`). The
/// extension may read that folder only (a read-only sandbox exception).
enum ControlState {
    static var url: URL {
        // In the sandbox the home directory is the container; the real one
        // comes from the user database.
        let home = getpwuid(getuid()).flatMap { $0.pointee.pw_dir.map { String(cString: $0) } } ?? NSHomeDirectory()
        return URL(fileURLWithPath: home).appendingPathComponent("Library/Application Support/RhythmBG/control-state.json")
    }

    static func isOn() -> Bool {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return true }
        return json["on"] as? Bool ?? true
    }
}

struct OpenRhythmBGIntent: AppIntent {
    static let title: LocalizedStringResource = "Open RhythmBG"
    static let description = IntentDescription("Shows RhythmBG's panel.")
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        await RhythmBGURL.open("rhythmbg://open")
        return .result()
    }
}

struct SetDesktopShowIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Desktop Show"
    static let description = IntentDescription("Turns the desktop show on or off on every screen.")
    @Parameter(title: "On") var value: Bool

    func perform() async throws -> some IntentResult {
        await RhythmBGURL.open(value ? "rhythmbg://show/on" : "rhythmbg://show/off")
        return .result()
    }
}

struct OpenRhythmBGControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.jhg.bgtools.open") {
            ControlWidgetButton(action: OpenRhythmBGIntent()) {
                Label("RhythmBG", systemImage: "photo.on.rectangle.angled")
            }
        }
        .displayName("Open RhythmBG")
        .description("Shows RhythmBG's panel.")
    }
}

struct DesktopShowValue: ControlValueProvider {
    var previewValue: Bool { true }
    func currentValue() async throws -> Bool { ControlState.isOn() }
}

struct DesktopShowControl: ControlWidget {
    static let kind = "com.jhg.bgtools.desktopShow"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: DesktopShowValue()) { on in
            ControlWidgetToggle("Desktop Show", isOn: on, action: SetDesktopShowIntent()) { on in
                Label(on ? "Playing" : "Off", systemImage: on ? "play.rectangle.fill" : "rectangle")
            }
        }
        .displayName("Desktop Show")
        .description("Turns the desktop show on or off.")
    }
}
