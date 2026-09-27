import SwiftUI
import AppKit

/// One of three tunable window-background looks (`spec/windows.md`, item
/// 34: "light mode's translucency and a window-background transparency
/// setting"). Jason, 2026-09-27: "Main window is class 1... panes that sit
/// on it can share class 1 values, or be assigned class 2 or 3" — the
/// channels are numbered and reusable rather than named after any one
/// region, so a region (`TranslucentRegion`) can be reassigned to a
/// different channel without the channel itself changing meaning.
enum OpacityChannel: Int, CaseIterable, Identifiable, Codable {
    case one = 1, two = 2, three = 3
    var id: Int { rawValue }
    var label: String { "Opacity Channel \(rawValue)" }
}

/// A part of the app whose background is one of the tunable channels.
/// Which channel drives it is itself a setting (`TranslucencySettings
/// .regionChannel`), defaulting every region to Channel 1 — Jason's own
/// starting point ("Main window is class 1").
enum TranslucentRegion: String, CaseIterable, Identifiable {
    /// The file navigator on the left — Library, Collections, Shows, and
    /// the "+ New" button (Jason, 2026-09-27: "the catalog is the library
    /// bar, the file navigator on the left hand side"). Was `mainWindow`;
    /// renamed to match his own name for it exactly, still the same view.
    case catalog
    case inspector
    case panels
    /// The main window's native title bar — the strip with the traffic
    /// lights and the window title (Jason, 2026-09-27, "header bar too").
    case headerBar

    var id: String { rawValue }

    var label: String {
        switch self {
        case .catalog: return "Catalog (the file navigator)"
        case .inspector: return "Inspector"
        case .panels: return "Panels (Info, Rhythm)"
        case .headerBar: return "Header bar (the window title)"
        }
    }
}

/// How a channel's blur is produced. `.system` leaves `NSVisualEffectView`'s
/// own fixed material blur alone — safe, no private API, no continuous
/// slider. `.custom` reaches into its private backing layer for a
/// continuous radius — undocumented, and could silently stop doing anything
/// on a future macOS update. Jason, 2026-09-27: include the custom slider,
/// but keep this system-only mode as a real escape hatch, not a workaround
/// dressed up as a setting.
enum BlurMode: String, Codable {
    case system, custom
}

/// One channel's values for one appearance (light or dark). Jason,
/// 2026-09-27: "a switch inside the secondary window that allows for fine
/// tuning the look with different slider values depending on the Dark
/// Mode/Light Mode setting" — the whole reason each value is kept twice.
/// Defaults reproduce today's plain, opaque look exactly (no tint, system
/// blur, fully opaque) so nothing changes on screen until Jason actually
/// moves a slider.
struct ChannelValues: Codable, Equatable {
    var opacity: Double = 1.0
    var blurMode: BlurMode = .system
    /// Points; only used while `blurMode == .custom`.
    var blurRadius: Double = 20
    var tintAmount: Double = 0
    private var tintRed: Double = 0
    private var tintGreen: Double = 0
    private var tintBlue: Double = 0

    var tintColor: Color {
        get { Color(red: tintRed, green: tintGreen, blue: tintBlue) }
        set {
            let ns = NSColor(newValue).usingColorSpace(.deviceRGB) ?? .black
            tintRed = ns.redComponent
            tintGreen = ns.greenComponent
            tintBlue = ns.blueComponent
        }
    }
}

/// Live, saved settings for every channel and every region's assignment.
/// One shared instance (`shared`), observed by every `TranslucentBackground`
/// and by the settings box, so a slider moved in the box repaints every
/// window using that channel at once — the same "felt live" pattern
/// `DrawerSensitivitySetting` uses for the practice drawer.
@MainActor
final class TranslucencySettings: ObservableObject {
    static let shared = TranslucencySettings()

    @Published private var channelValues: [OpacityChannel: [String: ChannelValues]] = [:]
    @Published private var regionChannel: [TranslucentRegion: OpacityChannel] = [:]

    private init() { load() }

    private func schemeKey(_ scheme: ColorScheme) -> String { scheme == .dark ? "dark" : "light" }
    private func storageKey(_ channel: OpacityChannel, _ scheme: ColorScheme) -> String {
        "translucencyChannel.\(channel.rawValue).\(schemeKey(scheme))"
    }
    private func regionStorageKey(_ region: TranslucentRegion) -> String {
        "translucencyRegion.\(region.rawValue)"
    }

    private func load() {
        let d = UserDefaults.standard
        for channel in OpacityChannel.allCases {
            for scheme: ColorScheme in [.light, .dark] {
                guard let data = d.data(forKey: storageKey(channel, scheme)),
                      let values = try? JSONDecoder().decode(ChannelValues.self, from: data) else { continue }
                channelValues[channel, default: [:]][schemeKey(scheme)] = values
            }
        }
        for region in TranslucentRegion.allCases {
            let key = regionStorageKey(region)
            guard d.object(forKey: key) != nil else { continue }
            regionChannel[region] = OpacityChannel(rawValue: d.integer(forKey: key))
        }
    }

    func values(for channel: OpacityChannel, appearance: ColorScheme) -> ChannelValues {
        channelValues[channel]?[schemeKey(appearance)] ?? ChannelValues()
    }

    func setValues(_ values: ChannelValues, channel: OpacityChannel, appearance: ColorScheme) {
        channelValues[channel, default: [:]][schemeKey(appearance)] = values
        guard let data = try? JSONEncoder().encode(values) else { return }
        UserDefaults.standard.set(data, forKey: storageKey(channel, appearance))
    }

    func channel(for region: TranslucentRegion) -> OpacityChannel {
        regionChannel[region] ?? .one
    }

    func setChannel(_ channel: OpacityChannel, for region: TranslucentRegion) {
        regionChannel[region] = channel
        UserDefaults.standard.set(channel.rawValue, forKey: regionStorageKey(region))
    }

    func values(for region: TranslucentRegion, appearance: ColorScheme) -> ChannelValues {
        values(for: channel(for: region), appearance: appearance)
    }
}
