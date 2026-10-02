import SwiftUI
import AppKit
import PaneKit

/// The rework of item 34 (`spec/windows.md`), 2026-09-27: the earlier
/// three-channel, four-region system was over-scoped. Jason, after looking
/// at how native apps actually use translucency: it only reads as
/// intentional on a bar that scrolled content passes under — everywhere
/// else (a sidebar, an inspector, a panel) it's too subtle to be worth a
/// setting, which is exactly what testing showed (Opacity on the Catalog
/// was nearly invisible against a plain desktop). Those three regions were
/// reverted to their original rendering.
///
/// Kept instead, unwired: `TranslucencySetting.swift` and
/// `TranslucentBackground.swift` — the three-channel opacity/blur/tint
/// engine that version built is the seed for a future Slide Editor tool
/// that applies the same kind of effect to slide images, not window chrome.
///
/// This is the replacement: one dial per appearance. At 0, a bar looks
/// exactly like the OS's own native material, untouched. At 1, it's fully
/// opaque. No blur toggle, no tint, no region picker — there's only one
/// kind of surface this applies to now (`ScrollBarBackground`, used by the
/// Library grid's filter bar today; the header bar is a candidate too, once
/// PaneKit can give it real scrolled content to pass under it).
@MainActor
final class ScrollBarTranslucency: ObservableObject {
    static let shared = ScrollBarTranslucency()

    /// What a slider sets (Jason, 2026-09-27: "one slider for the currently
    /// targeted zones. A slider for the window header bar"). `bars`: every
    /// bar content scrolls under — the grid's filter bar, the sidebar's top
    /// and bottom, the browser's bars and section headers. `header`: the
    /// window's own title bar and toolbar (`HeaderBarBackground`).
    enum Zone: String {
        case bars = "scrollBarOpacity", header = "headerBarOpacity"
        /// Before a slider's ever moved: the bars at the OS's own look, as
        /// they've always been; the header solid, as it's always been.
        var defaultValue: Double { self == .bars ? 0 : 1 }
    }

    @Published private var amount: [String: Double] = [:]
    @Published private var handles: [String: Bool] = [:]

    private func key(_ zone: Zone, _ scheme: ColorScheme) -> String {
        "\(zone.rawValue).\(scheme == .dark ? "dark" : "light")"
    }

    private func handlesKey(_ scheme: ColorScheme) -> String {
        "scrollBarIncludeHandles.\(scheme == .dark ? "dark" : "light")"
    }

    private init() {
        let d = UserDefaults.standard
        for scheme: ColorScheme in [.light, .dark] {
            for zone: Zone in [.bars, .header] where d.object(forKey: key(zone, scheme)) != nil {
                amount[key(zone, scheme)] = d.double(forKey: key(zone, scheme))
            }
            // One switch for both appearances until 2026-09-27's split:
            // its value carries over to each.
            handles[handlesKey(scheme)] = d.object(forKey: handlesKey(scheme)) != nil
                ? d.bool(forKey: handlesKey(scheme)) : d.bool(forKey: "scrollBarIncludeHandles")
        }
        syncPaneHandles()
    }

    func value(for scheme: ColorScheme, zone: Zone = .bars) -> Double {
        amount[key(zone, scheme)] ?? zone.defaultValue
    }

    func setValue(_ v: Double, for scheme: ColorScheme, zone: Zone = .bars) {
        amount[key(zone, scheme)] = v
        UserDefaults.standard.set(v, forKey: key(zone, scheme))
        PaneHandleAppearance.changed()
    }

    /// While the slider's knob moves: every bar redraws at `v` live
    /// (Jason, 2026-09-27: "the slider adjustment isn't responding live"),
    /// but nothing's saved until `setValue` on release.
    func preview(_ v: Double, for scheme: ColorScheme, zone: Zone = .bars) {
        amount[key(zone, scheme)] = v
        PaneHandleAppearance.changed()
    }

    /// Whether a drawer's handle rows go translucent with the bars, per
    /// appearance (Jason: "the switch is split between whether the OS is
    /// in light or dark mode, like the sliders"). Off: solid, as always.
    func includesHandles(_ scheme: ColorScheme) -> Bool { handles[handlesKey(scheme)] ?? false }

    func setIncludesHandles(_ on: Bool, for scheme: ColorScheme) {
        handles[handlesKey(scheme)] = on
        UserDefaults.standard.set(on, forKey: handlesKey(scheme))
        syncPaneHandles()
    }

    /// PaneKit draws every drawer's edge handle itself, so it's told
    /// directly (`PaneHandleAppearance`), and told again on every change —
    /// the slider's live preview included.
    private func syncPaneHandles() {
        PaneHandleAppearance.translucency = { [weak self] dark in
            guard let self else { return nil }
            let scheme: ColorScheme = dark ? .dark : .light
            return self.includesHandles(scheme) ? CGFloat(self.value(for: scheme)) : nil
        }
        PaneHandleAppearance.changed()
    }
}

/// A bar's own tunable background: the native `.headerView` material at
/// amount 0, crossfading to a flat, fully opaque backing at 1.
///
/// `blending` defaults to `.withinWindow`, which samples real content drawn
/// directly behind it in the *same* window — right for any plain SwiftUI
/// `ScrollView` (the grid's filter bar, the Catalog's own rows since
/// 2026-09-27's migration off `List`). It's kept as a parameter, not
/// hardcoded, only because of what it took to find that out: measured
/// 2026-09-27 that `.withinWindow` renders completely flat, with no
/// vibrancy at all, over a real `NSTableView` (`List`) — the Catalog's
/// short-lived `.sidebar`/`.behindWindow` convenience existed only to work
/// around that, and was removed once the migration made it moot.
struct ScrollBarBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var setting = ScrollBarTranslucency.shared
    var blending: NSVisualEffectView.BlendingMode = .withinWindow

    var body: some View {
        let amount = setting.value(for: colorScheme)
        ZStack {
            NativeBarMaterial(blending: blending)
            Color(nsColor: .windowBackgroundColor).opacity(amount)
        }
        .allowsHitTesting(false)
    }
}

/// A drawer handle row's background: solid, as it always was, unless
/// "Include handles" is on — then the same translucent bar look as the
/// bars, following the slider. `inStack`: the handle sits inside a bar
/// stack that already has one `ScrollBarBackground` (the grid's sort
/// strip), so it goes clear and lets that show, rather than doubling it.
/// PaneKit's own edge handles follow the same setting through
/// `PaneHandleAppearance`.
struct HandleBackground: View {
    var inStack = false
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var setting = ScrollBarTranslucency.shared

    var body: some View {
        if !setting.includesHandles(colorScheme) {
            Color(nsColor: .controlBackgroundColor)
        } else if inStack {
            Color.clear
        } else {
            ScrollBarBackground()
        }
    }
}

/// A small always-visible sample of the bar's own look at a given amount,
/// next to its slider on the Windows tab — the same lesson as the earlier
/// three-channel version's live preview: judging a translucency slider
/// against whatever happens to be behind the real window (or the wrong
/// system appearance) isn't reliable. Here the backdrop is a colorful
/// gradient placed directly behind the bar in the same small view, which
/// `.withinWindow` blending (the real mechanism, not a stand-in) samples
/// exactly the way it would sample real scrolled grid content.
struct ScrollBarPreview: View {
    let amount: Double
    /// Which appearance it's showing — the one being edited, not
    /// necessarily the Mac's own right now.
    var scheme: ColorScheme = .dark
    var material: NSVisualEffectView.Material = .headerView

    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .orange, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
            NativeBarMaterial(blending: .withinWindow, material: material, scheme: scheme)
            Color(nsColor: .windowBackgroundColor).opacity(amount)
        }
        .environment(\.colorScheme, scheme)
        .frame(width: 84, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }
}

/// The window's own title bar and toolbar strip: the OS's title-bar
/// material at 0 — which, with nothing of the window's own under it
/// (content stops below the title bar), shows the desktop through, as a
/// native title bar does — to fully solid at 1, today's look and the
/// default. `MainView` lays it behind the title bar.
struct HeaderBarBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var setting = ScrollBarTranslucency.shared

    var body: some View {
        ZStack {
            NativeBarMaterial(blending: .behindWindow, material: .titlebar)
            Color(nsColor: .windowBackgroundColor).opacity(setting.value(for: colorScheme, zone: .header))
        }
        .allowsHitTesting(false)
    }
}

private struct NativeBarMaterial: NSViewRepresentable {
    var blending: NSVisualEffectView.BlendingMode
    var material: NSVisualEffectView.Material = .headerView
    /// Forces an appearance (the settings' swatch); nil follows the window.
    var scheme: ColorScheme? = nil

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.blendingMode = blending
        v.state = .active
        updateNSView(v, context: context)
        return v
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.appearance = scheme.map { NSAppearance(named: $0 == .dark ? .darkAqua : .aqua) } ?? nil
    }
}
