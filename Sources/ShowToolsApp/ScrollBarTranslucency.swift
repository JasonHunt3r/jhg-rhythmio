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

    @Published private var amount: [String: Double] = [:]

    /// Whether a drawer's handle strip in a translucent bar stack (the
    /// grid's sort strip) goes translucent with the bars, or stays solid
    /// as it always has — the default (Jason, 2026-09-27: "Include handles
    /// in transparency? Checkbox"). `HandleBackground` reads it.
    @Published var includeHandles: Bool = UserDefaults.standard.bool(forKey: "scrollBarIncludeHandles") {
        didSet {
            UserDefaults.standard.set(includeHandles, forKey: "scrollBarIncludeHandles")
            syncPaneHandles()
        }
    }

    /// PaneKit draws every drawer's edge handle itself, so it's told
    /// directly (`PaneHandleAppearance`), and told again on every change —
    /// the slider's live preview included.
    private func syncPaneHandles() {
        PaneHandleAppearance.translucency = includeHandles
            ? { [weak self] dark in CGFloat(self?.value(for: dark ? .dark : .light) ?? 1) } : nil
        PaneHandleAppearance.changed()
    }

    private func key(_ scheme: ColorScheme) -> String {
        scheme == .dark ? "scrollBarOpacity.dark" : "scrollBarOpacity.light"
    }

    private init() {
        for scheme: ColorScheme in [ColorScheme.light, .dark] {
            let k = key(scheme)
            if UserDefaults.standard.object(forKey: k) != nil {
                amount[k] = UserDefaults.standard.double(forKey: k)
            }
        }
        syncPaneHandles()
    }

    func value(for scheme: ColorScheme) -> Double {
        amount[key(scheme)] ?? 0
    }

    func setValue(_ v: Double, for scheme: ColorScheme) {
        amount[key(scheme)] = v
        UserDefaults.standard.set(v, forKey: key(scheme))
        PaneHandleAppearance.changed()
    }

    /// While the slider's knob moves: every bar redraws at `v` live
    /// (Jason, 2026-09-27: "the slider adjustment isn't responding live"),
    /// but nothing's saved until `setValue` on release.
    func preview(_ v: Double, for scheme: ColorScheme) {
        amount[key(scheme)] = v
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
    @ObservedObject private var setting = ScrollBarTranslucency.shared

    var body: some View {
        if !setting.includeHandles {
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

    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .orange, .green], startPoint: .topLeading, endPoint: .bottomTrailing)
            NativeBarMaterial(blending: .withinWindow)
            Color(nsColor: .windowBackgroundColor).opacity(amount)
        }
        .frame(width: 84, height: 32)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.separator))
    }
}

private struct NativeBarMaterial: NSViewRepresentable {
    var blending: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .headerView
        v.blendingMode = blending
        v.state = .active
        return v
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}
