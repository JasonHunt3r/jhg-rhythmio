import SwiftUI
import AppKit

/// A region's tunable background (`TranslucencySetting.swift`): a
/// `NSVisualEffectView` for the blur, a tint on top, both driven by
/// whichever channel `region` is currently assigned to and by the live
/// (light/dark) appearance — reapplied at once as the settings box's
/// sliders move, since it observes `TranslucencySettings.shared` directly.
/// Drop it in with `.background(TranslucentBackground(region: .inspector))`,
/// same as any other SwiftUI background.
struct TranslucentBackground: View {
    let region: TranslucentRegion
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var settings = TranslucencySettings.shared

    var body: some View {
        let values = settings.values(for: region, appearance: colorScheme)
        ZStack {
            VisualEffectView(blurMode: values.blurMode, blurRadius: values.blurRadius)
                .opacity(values.opacity)
            if values.tintAmount > 0 {
                values.tintColor.opacity(values.tintAmount)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Wraps `NSVisualEffectView` set to `.sidebar` material, `.behindWindow`
/// blending — the same look `NavigationSplitView`'s sidebar gave for free.
/// `blurMode == .system` leaves the material's own fixed blur exactly
/// alone: no private API touched. `.custom` reaches into the view's private
/// backing `CABackdropLayer` for a continuous radius — undocumented, so
/// this is best-effort: if a future macOS's backdrop layer doesn't answer
/// to the same key, the slider silently does nothing and the system's own
/// fixed blur is what shows, not a crash.
private struct VisualEffectView: NSViewRepresentable {
    var blurMode: BlurMode
    var blurRadius: Double

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        applyBlur(to: view)
    }

    private func applyBlur(to view: NSVisualEffectView) {
        guard blurMode == .custom, let backdrop = backdropLayer(of: view) else { return }
        backdrop.setValue(blurRadius, forKey: "blurRadius")
    }

    /// `NSVisualEffectView`'s blur is drawn by a `CABackdropLayer` among its
    /// layer's sublayers once it's actually in a window — not present at
    /// `makeNSView` time, so this is looked up fresh on every update rather
    /// than cached.
    private func backdropLayer(of view: NSVisualEffectView) -> CALayer? {
        func search(_ layer: CALayer?) -> CALayer? {
            guard let layer else { return nil }
            if NSStringFromClass(type(of: layer)).contains("Backdrop") { return layer }
            for sub in layer.sublayers ?? [] {
                if let found = search(sub) { return found }
            }
            return nil
        }
        return search(view.layer)
    }
}
