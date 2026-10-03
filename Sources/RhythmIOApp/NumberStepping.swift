import AppKit
import SwiftUI

/// Stepping a number field from the keyboard and the trackpad (Jason,
/// 2026-10-03): while a number field is being edited, ↑ ↓ step it, and so
/// does a two-finger swipe with the pointer over it — left/right by
/// default, "since we're basically scrubbing". ⇧ makes a step bigger, ⌥
/// smaller. Set in Settings ▸ Editing ▸ Number Fields. A field that isn't
/// being edited never takes a swipe: it scrolls the page as before.
///
/// Stepping only changes the text being edited (and draws a live preview
/// where the field has one); the field saves when editing ends, as typing
/// does, so a whole scrub is one undo step.
enum NumberStepping {
    enum Axis: String, CaseIterable {
        case horizontal, vertical, both
        var title: String {
            switch self {
            case .horizontal: "Left and right"
            case .vertical: "Up and down"
            case .both: "Either"
            }
        }
    }

    enum Size { case unit, big, fine }

    static let axisKey = "numberFieldSwipeAxis"
    static let bigKey = "numberFieldShiftFactor"
    static let fineKey = "numberFieldOptionFactor"
    static let distanceKey = "numberFieldSwipeDistance"

    static var axis: Axis {
        UserDefaults.standard.string(forKey: axisKey).flatMap(Axis.init(rawValue:)) ?? .horizontal
    }
    /// ⇧: this many steps.
    static var big: Double { positive(bigKey, 10) }
    /// ⌥: a step divided by this.
    static var fine: Double { positive(fineKey, 10) }
    /// Points of swipe per step.
    static var distance: Double { positive(distanceKey, 10) }

    static func factor(_ size: Size) -> Double {
        switch size {
        case .unit: 1
        case .big: big
        case .fine: 1 / fine
        }
    }

    private static func positive(_ key: String, _ fallback: Double) -> Double {
        let v = UserDefaults.standard.double(forKey: key)
        return v > 0 ? v : fallback
    }
}

extension View {
    /// ↑ ↓ and the swipe step this field while it's being edited. `step`
    /// gets the text as typed so far, the direction (+1 up or right, −1
    /// down or left) and the size, and returns the text to show instead,
    /// or nil to leave it. `announce`: tell the field its text changed, as
    /// typing does — a text binding needs it to follow; a number field
    /// mustn't have it, since SwiftUI then saves every step as its own
    /// undo step instead of the whole scrub once (measured 2026-10-03).
    ///
    /// Without `announce`, the field doesn't hear the steps, so `ended` gets
    /// the final text when editing ends (Return, or leaving the field) to
    /// save it once — SwiftUI's own copy of the text would otherwise put
    /// the old value back (measured 2026-10-03).
    func numberStepping(announce: Bool = false, ended: ((String) -> Void)? = nil,
                        _ step: @escaping (_ text: String, _ direction: Int, _ size: NumberStepping.Size) -> String?) -> some View {
        background(NumberStepper(step: step, announce: announce, ended: ended))
    }

    /// The everyday case: a number in steps of `unit`, kept inside
    /// `range`, shown with up to `decimals` places; `live` draws each new
    /// value before it's saved.
    func numberStepping(unit: Double, range: ClosedRange<Double>? = nil, decimals: Int,
                        live: ((Double) -> Void)? = nil, commit: @escaping (Double) -> Void) -> some View {
        let style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...decimals))
        return numberStepping(ended: { text in
            if let v = try? Double(text, format: style) { commit(v) }
        }) { text, direction, size in
            guard let now = try? Double(text, format: style) else { return nil }
            var v = now + Double(direction) * unit * NumberStepping.factor(size)
            if let range { v = min(max(v, range.lowerBound), range.upperBound) }
            let places = pow(10, Double(decimals))
            v = (v * places).rounded() / places
            live?(v)
            return v.formatted(style)
        }
    }
}

/// The stepping itself: a view behind the field that watches the window's
/// keys and swipes, and acts only while the field it sits behind is the
/// one being edited.
struct NumberStepper: NSViewRepresentable {
    let step: (String, Int, NumberStepping.Size) -> String?
    var announce = false
    var ended: ((String) -> Void)? = nil

    func makeNSView(context: Context) -> StepView { StepView() }
    func updateNSView(_ view: StepView, context: Context) {
        view.step = step; view.announce = announce; view.ended = ended
    }

    final class StepView: NSView {
        var step: ((String, Int, NumberStepping.Size) -> String?)?
        var announce = false
        var ended: ((String) -> Void)?
        private var monitor: Any?
        private var endObserver: Any?
        /// The field stepped since its editing began, waiting to be saved.
        private weak var stepped: NSTextField?
        /// Swipe travel not yet turned into a step.
        private var travel: CGFloat = 0

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
            endObserver = nil
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .scrollWheel]) { [weak self] event in
                let used = MainActor.assumeIsolated { self?.handle(event) ?? false }
                return used ? nil : event
            }
            endObserver = NotificationCenter.default.addObserver(forName: NSControl.textDidEndEditingNotification,
                                                                 object: nil, queue: .main) { [weak self] note in
                let field = note.object as? NSTextField
                let text = (note.userInfo?["NSFieldEditor"] as? NSTextView)?.string ?? field?.stringValue
                MainActor.assumeIsolated {
                    guard let self, let field, field === self.stepped, let text else { return }
                    self.stepped = nil
                    self.ended?(text)
                }
            }
        }

        isolated deinit {
            if let monitor { NSEvent.removeMonitor(monitor) }
            if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        }

        /// The field editor, when the field this sits behind is being edited.
        private var editor: NSTextView? {
            guard let window, let editor = window.firstResponder as? NSTextView, editor.isFieldEditor,
                  let field = editor.delegate as? NSTextField, field.window === window else { return nil }
            let mine = convert(bounds, to: nil), theirs = field.convert(field.bounds, to: nil)
            return mine.intersects(theirs) ? editor : nil
        }

        private func size(_ flags: NSEvent.ModifierFlags) -> NumberStepping.Size? {
            switch flags.intersection([.shift, .option, .command, .control]) {
            case []: .unit
            case [.shift]: .big
            case [.option]: .fine
            default: nil
            }
        }

        private func handle(_ event: NSEvent) -> Bool {
            // Not `event.window`: in a popover (Edit Range) a key event comes
            // labelled with the main window, not the popover's own (measured
            // 2026-10-03), so the window is judged here instead.
            guard let window, let editor else { return false }
            switch event.type {
            case .keyDown:
                guard window.isKeyWindow, event.keyCode == 126 || event.keyCode == 125,
                      let size = size(event.modifierFlags) else { return false }
                apply(event.keyCode == 126 ? 1 : -1, size, to: editor)
                return true
            case .scrollWheel:
                // Only with the pointer over the field, found from the screen.
                let pointer = window.convertPoint(fromScreen: NSEvent.mouseLocation)
                guard convert(bounds, to: nil).contains(pointer) else { return false }
                guard let size = size(event.modifierFlags) else { return true }
                // Which way the fingers went, whatever the scroll direction
                // setting: right and up count up.
                let natural: CGFloat = event.isDirectionInvertedFromDevice ? 1 : -1
                let right = natural * event.scrollingDeltaX
                let up = -natural * event.scrollingDeltaY
                let moved: CGFloat = switch NumberStepping.axis {
                case .horizontal: right
                case .vertical: up
                case .both: abs(right) >= abs(up) ? right : up
                }
                if event.phase == .began { travel = 0 }
                if !event.hasPreciseScrollingDeltas {
                    // A mouse wheel: a notch is a step.
                    if moved != 0 { apply(moved > 0 ? 1 : -1, size, to: editor) }
                    return true
                }
                travel += moved
                let distance = CGFloat(NumberStepping.distance)
                while abs(travel) >= distance {
                    let direction = travel > 0 ? 1 : -1
                    travel -= CGFloat(direction) * distance
                    apply(direction, size, to: editor)
                }
                return true
            default:
                return false
            }
        }

        private func apply(_ direction: Int, _ size: NumberStepping.Size, to editor: NSTextView) {
            guard let new = step?(editor.string, direction, size), new != editor.string else { return }
            editor.string = new
            editor.selectedRange = NSRange(location: (new as NSString).length, length: 0)
            if announce { editor.didChangeText() } else { stepped = editor.delegate as? NSTextField }
        }
    }
}
