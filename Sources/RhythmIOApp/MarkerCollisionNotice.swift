import AppKit
import RhythmIOCore

/// The first-occurrence alert for marker collisions (`spec/range-and-ruler.md`,
/// "Marker collisions"): what happened and why, until "Don't show this again"
/// is ticked. Settings ▸ Timeline brings it back.
@MainActor
enum MarkerCollisionNotice {
    static let suppressKey = "suppressMarkerCollisionNotice"

    /// `merged`: a new marker replaced one nearby; it shows at once.
    /// Otherwise a moved marker went back where it was, and the alert waits
    /// for its red flash: a modal alert stops the timeline drawing, so
    /// shown at once the flash was never seen (measured 2026-10-03).
    static func showSoon(merged: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (merged ? 0 : 0.7)) { show(merged: merged) }
    }

    private static func show(merged: Bool) {
        guard !UserDefaults.standard.bool(forKey: suppressKey) else { return }
        let frames = NudgeSettings.saved.mergeTolerance
        let alert = NSAlert()
        alert.messageText = merged ? "The new marker replaced the one beside it"
                                   : "The marker went back where it was"
        alert.informativeText = "Two markers of the same kind can't sit less than \(frames) frame\(frames == 1 ? "" : "s") apart. "
            + "Placing a marker there replaces the one that was there; dragging or nudging one there puts it back. "
            + "A marker and a beat marker can share a time. How close is too close is in Settings ▸ Timeline."
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Don't show this again"
        alert.runModal()
        if alert.suppressionButton?.state == .on {
            UserDefaults.standard.set(true, forKey: suppressKey)
        }
    }
}
