import SwiftUI
import PaneKit

/// The drawers' sensitivity (`spec/panekit.md`, "The clutch," "A
/// sensitivity setting"): how far a closed drawer must be pulled before it
/// engages, and how quick or smooth its slide is once it does. Applies
/// PaneKit's own tunable dials (`PaneClutch`'s static `var`s, already built
/// for exactly this) from what's saved — at launch, and live as the
/// Windows tab's sliders move, so the practice drawer feels the change at
/// once.
@MainActor
enum DrawerSensitivitySetting {
    static let engageKey = "drawerEngageDistance"
    static let slideKey = "drawerSlideSpeed"
    static let defaultEngage: Double = 64
    static let defaultSlide: Double = 0.18

    /// `settleDuration`'s own ratio to `slideDuration` in the original
    /// dials (0.14 / 0.18, both Jason's own feel) — kept constant as
    /// `slideDuration` changes, rather than picked separately: nothing
    /// asked for the settle (a let-go-before-engaging slide back shut) to
    /// move independently of the engage slide's own quickness.
    private static let settleRatio = 0.14 / 0.18

    static func apply() {
        let d = UserDefaults.standard
        let engage = d.object(forKey: engageKey) as? Double ?? defaultEngage
        let slide = d.object(forKey: slideKey) as? Double ?? defaultSlide
        PaneClutch.engage = engage
        // "The same literal distance as the pull that opens it" —
        // PaneClutch's own doc comment on `closePast`. Kept tied here
        // rather than given its own control: nothing asked for these two
        // to differ.
        PaneClutch.closePast = engage
        PaneClutch.slideDuration = slide
        PaneClutch.settleDuration = slide * settleRatio
    }
}

/// Jason's own idea for the control, 2026-09-27: "something visual to
/// drag — a line inside a box marking the trigger distance." The box
/// spans `range` (points); the line sits at the current engage distance
/// and drags freely along it.
struct EngageDistanceControl: View {
    @Binding var engage: Double
    var range: ClosedRange<Double> = 8...120

    var body: some View {
        GeometryReader { geo in
            let width = max(geo.size.width, 1)
            let t = (engage - range.lowerBound) / (range.upperBound - range.lowerBound)
            let x = CGFloat(min(max(t, 0), 1)) * width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.15))
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 3)
                    .offset(x: min(max(x, 0), width - 3))
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let t = min(max(value.location.x / width, 0), 1)
                    engage = range.lowerBound + t * (range.upperBound - range.lowerBound)
                })
        }
        .frame(height: 44)
    }
}

/// A real PaneKit split, embedded live — not a mockup — so pulling its
/// handle exercises the actual `PaneClutch` dials the sliders above just
/// set. `PaneContainerView` is the same view every PaneKit-managed split
/// in the app uses; only the content (two plain colored views) is unique
/// to this practice drawer.
struct PracticeDrawer: NSViewRepresentable {
    let controller: PaneController

    func makeNSView(context: Context) -> PaneContainerView {
        let main = NSView()
        main.wantsLayer = true
        main.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        let drawer = NSView()
        drawer.wantsLayer = true
        drawer.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
        return PaneContainerView(controller: controller, content: ["practiceMain": main, "practiceDrawer": drawer])
    }

    func updateNSView(_ nsView: PaneContainerView, context: Context) {}
}

extension PaneController {
    /// A closed practice drawer, right side, an edge handle to pull —
    /// reset closed each time it's made (a fresh `UserDefaults` key every
    /// launch would work too, but forcing it shut is the more useful
    /// default for something meant to be practiced pulling open).
    static func settingsPracticeDrawer() -> PaneController {
        let c = PaneController(id: "settingsPracticeDrawer", root:
            .split("practice", .horizontal, sized: .second, size: 160, range: 40...260,
                   .pane("practiceMain", title: "Main", minSize: 100),
                   .pane("practiceDrawer", title: "Drawer", minSize: 40)))
        if c.isOpen("practice") { c.setOpen("practice", false) }
        return c
    }
}
