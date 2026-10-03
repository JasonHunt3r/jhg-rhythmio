import Foundation
import RhythmIOCore

/// The Nudge settings (Settings ▸ Timeline ▸ Nudge), kept in the app's
/// preferences as one saved value.
extension NudgeSettings {
    static let defaultsKey = "nudgeSettings"

    static var saved: NudgeSettings {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let s = try? JSONDecoder().decode(NudgeSettings.self, from: data) else { return NudgeSettings() }
        return s
    }

    static func decode(_ data: Data) -> NudgeSettings {
        (try? JSONDecoder().decode(NudgeSettings.self, from: data)) ?? NudgeSettings()
    }

    var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }
}
