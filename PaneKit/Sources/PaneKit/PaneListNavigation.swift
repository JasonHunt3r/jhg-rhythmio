import SwiftUI
import AppKit

/// What `List(selection:)` gives an app for free that a plain `ScrollView`
/// doesn't. Built for a translucent sidebar that can't be a real `List` —
/// `NSTableView` doesn't compose with `.withinWindow` vibrancy at all
/// (measured, ShowTools' Catalog, 2026-09-27: identical, completely flat
/// result whether the effect view was nested via `.safeAreaInset` or a true
/// sibling via `.overlay`) — but nothing here is ShowTools-specific.
///
/// Like a `List`, it only acts while it has the keyboard: a click anywhere
/// in it takes focus (SwiftUI's own, so Tab and the window's key loop
/// behave), and while it has it —
///
/// - **↑ / ↓** step the selection (held, they repeat) and scroll it into view;
/// - **→** opens a folded row, or on an open one steps to its first child;
///   **←** folds an open row, or steps from a child to its parent;
///   **⌥→ / ⌥←** open or fold the row and everything under it
///   (`outline`; `PaneOutlineIndent`'s ⌥-click does the same);
/// - **typing** a name's first letters selects it; the same letter again
///   steps through every row starting with it (`title`);
/// - **Return** does what the app says (`onReturn`) — rename, in Finder's
///   convention, through `PaneInlineRename`.
///
/// Rows show whether it has the keyboard through `.paneListRow(selected:)`:
/// the accent highlight while it does, grey while it doesn't, and a ring
/// around the row a right-click menu is open for — `List`'s own states.
///
/// The app keeps building its own rows (recursive `DisclosureGroup`s with
/// `.disclosureGroupStyle(.paneOutline)`) and its own keys for everything
/// else (Delete, Return, rename). `order` is the current, flat, *visible*
/// row order — folded branches already left out, since only the app knows
/// its fold state — with each row carrying a matching `.id(_:)` for
/// `ScrollViewProxy.scrollTo`.
public struct PaneListNavigation<ID: Hashable>: ViewModifier {
    @Binding var selection: ID?
    let order: [ID]
    let title: ((ID) -> String)?
    let outline: PaneListOutline<ID>?
    let onReturn: ((ID) -> Void)?
    let accessibilityLabel: String?
    @FocusState private var focused: Bool
    @State private var typed = PaneTypeSelect()

    public init(selection: Binding<ID?>, order: [ID], title: ((ID) -> String)? = nil,
                outline: PaneListOutline<ID>? = nil, onReturn: ((ID) -> Void)? = nil,
                accessibilityLabel: String? = nil) {
        self.accessibilityLabel = accessibilityLabel
        self._selection = selection
        self.order = order
        self.title = title
        self.outline = outline
        self.onReturn = onReturn
    }

    public func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                .environment(\.paneListFocused, focused)
                .environment(\.paneListRefocus, { focused = true })
                .focusable()
                .focusEffectDisabled()
                .focused($focused)
                .onChange(of: focused, initial: true) { _, on in PaneListKeyboard.set(on, in: NSApp.keyWindow) }
                .onAppear { focused = true }
                .onKeyPress(phases: [.down, .repeat]) { press in handle(press, proxy: proxy) }
                // One named group for VoiceOver to enter and leave, as a
                // `List` is ("Sidebar").
                .accessibilityElement(children: .contain)
                .accessibilityLabel(accessibilityLabel ?? "")
        }
    }

    private func handle(_ press: KeyPress, proxy: ScrollViewProxy) -> KeyPress.Result {
        // ⌘ and ⌃ belong to menus and the system, never to the list.
        guard press.modifiers.isDisjoint(with: [.command, .control]) else { return .ignored }
        // A row's name being edited (`PaneInlineRename`) keeps every key:
        // a key pressed in a focused child reaches this handler too.
        guard !(NSApp.keyWindow?.firstResponder is NSText) else { return .ignored }
        let option = press.modifiers.contains(.option)
        switch press.key {
        case .return:
            guard let onReturn, let selection, press.phase == .down, press.modifiers.isEmpty else { return .ignored }
            onReturn(selection)
        case .upArrow: select(Self.stepped(selection, in: order, by: -1), proxy: proxy)
        case .downArrow: select(Self.stepped(selection, in: order, by: 1), proxy: proxy)
        case .leftArrow, .rightArrow:
            guard let outline else { return .ignored }
            switch Self.horizontal(selection, right: press.key == .rightArrow, recursive: option,
                                   in: order, outline: outline) {
            case .select(let id): select(id, proxy: proxy)
            case .setExpanded(let id, let open, let recursive):
                withAnimation(.easeInOut(duration: 0.2)) { outline.setExpanded(id, open, recursive) }
            case .none: break
            }
        default:
            guard let title, press.phase == .down, !option,
                  let typedChar = press.characters.first, typedChar.isLetter || typedChar.isNumber
                    || (typedChar == " " && !typed.buffer.isEmpty) else { return .ignored }
            select(typed.next(String(typedChar), at: .now, selection: selection, order: order, title: title),
                   proxy: proxy)
        }
        return .handled
    }

    private func select(_ id: ID?, proxy: ScrollViewProxy) {
        guard let id, id != selection else { return }
        selection = id
        withAnimation(.default) { proxy.scrollTo(id) }
    }

    /// Pure: pinned by `PaneKitTests`, not by eye. `nil` selection (or one
    /// no longer in `order`, a fold having hidden it) starts from either
    /// end, matching which direction was pressed; otherwise clamps at the
    /// ends rather than wrapping — an arrow held at the top or bottom of
    /// the list should stop, not jump to the other end.
    static func stepped(_ selection: ID?, in order: [ID], by delta: Int) -> ID? {
        guard !order.isEmpty else { return nil }
        guard let current = selection, let i = order.firstIndex(of: current) else {
            return delta > 0 ? order.first : order.last
        }
        return order[min(max(i + delta, 0), order.count - 1)]
    }

    enum Horizontal: Equatable {
        case select(ID)
        case setExpanded(ID, open: Bool, recursive: Bool)
        case none
    }

    /// Pure, pinned by `PaneKitTests`: what ← or → does to the selected row,
    /// the way `NSOutlineView` answers it.
    static func horizontal(_ selection: ID?, right: Bool, recursive: Bool, in order: [ID],
                           outline: PaneListOutline<ID>) -> Horizontal {
        guard let id = selection, let i = order.firstIndex(of: id) else { return .none }
        let expanded = outline.isExpanded(id)
        if right {
            guard let expanded else { return .none }
            if !expanded || recursive { return .setExpanded(id, open: true, recursive: recursive) }
            if i + 1 < order.count, outline.parent(order[i + 1]) == id { return .select(order[i + 1]) }
            return .none
        }
        if let expanded, expanded || recursive { return .setExpanded(id, open: false, recursive: recursive) }
        if let parent = outline.parent(id) { return .select(parent) }
        return .none
    }
}

/// Whether a `PaneListNavigation` list has the keyboard in a window — the
/// question an app used to ask with `firstResponder is NSTableView`, which
/// a hand-rolled list never answers yes to. An app's own window-wide key
/// handlers (a grid's arrows) ask this to stand aside, as they did for a
/// `List` (ShowTools' Library grid took the sidebar's arrows, 2026-09-27).
@MainActor public enum PaneListKeyboard {
    private static let windows = NSHashTable<NSWindow>.weakObjects()

    public static func hasKeyboard(in window: NSWindow?) -> Bool {
        guard let window else { return false }
        return windows.contains(window)
    }

    static func set(_ on: Bool, in window: NSWindow?) {
        guard let window else { return }
        if on { windows.add(window) } else { windows.remove(window) }
    }
}

/// The hierarchy `PaneListNavigation`'s ← and → need, which a flat `order`
/// doesn't carry. Only the app knows it.
public struct PaneListOutline<ID: Hashable> {
    /// The row's parent row, or nil at the top level.
    public var parent: (ID) -> ID?
    /// Whether the row is open: nil for a row that can't open at all.
    public var isExpanded: (ID) -> Bool?
    /// Opens or folds a row; `recursive`, everything under it too.
    public var setExpanded: (ID, _ open: Bool, _ recursive: Bool) -> Void

    public init(parent: @escaping (ID) -> ID?, isExpanded: @escaping (ID) -> Bool?,
                setExpanded: @escaping (ID, Bool, Bool) -> Void) {
        self.parent = parent
        self.isExpanded = isExpanded
        self.setExpanded = setExpanded
    }
}

/// Type-to-select, as `NSTableView` does it: letters typed within a second
/// of each other build one name to find; the same letter again steps
/// through every row that starts with it. Pure but for the clock, which is
/// passed in, so `PaneKitTests` pin it.
struct PaneTypeSelect {
    static let pause: TimeInterval = 1
    private(set) var buffer = ""
    private var last = Date.distantPast

    mutating func next<ID: Hashable>(_ typedChar: String, at now: Date, selection: ID?, order: [ID],
                                     title: (ID) -> String) -> ID? {
        buffer = now.timeIntervalSince(last) > Self.pause ? typedChar : buffer + typedChar
        last = now
        guard !order.isEmpty else { return nil }
        // "s": the first s from the top. "ss", "sss": step on through the
        // s's. "st": find "st", staying put if the selected row matches.
        let repeated = Set(buffer.lowercased()).count == 1
        let prefix = repeated ? String(buffer.prefix(1)) : buffer
        let current = selection.flatMap { order.firstIndex(of: $0) }
        let start = buffer.count == 1 ? 0 : current.map { repeated ? $0 + 1 : $0 } ?? 0
        for offset in 0..<order.count {
            let id = order[(start + offset) % order.count]
            if title(id).range(of: prefix, options: [.anchored, .caseInsensitive, .diacriticInsensitive]) != nil {
                return id
            }
        }
        return nil
    }
}

/// A row's own chrome inside a `PaneListNavigation` list: `List`'s
/// selection highlight (the accent while the list has the keyboard, grey
/// while it doesn't), the text colour that goes with it, and the ring
/// around the row whose right-click menu is open.
///
/// And what `List` tells VoiceOver about a row, since a hand-rolled one
/// otherwise reads as loose pieces (its icon, its name and its count as
/// separate elements; Jason, 2026-09-27: PaneKit is held to an App Store
/// app's standard). The row is one element: `label` is its name, its value
/// is `value` plus, in a `.paneOutline` list, "level N" (a row that opens
/// says those in its label instead, and "expanded"/"collapsed" itself —
/// `spokenLabel`); it carries the selected trait; its default action is
/// `select`, and a row that opens has Expand or Collapse. The app adds its
/// own (Rename…) with `.accessibilityAction(named:)` after this. `editing`:
/// while its name is a text field (`PaneInlineRename`), the row opens up
/// so the field can be reached. Not an outline *role* — SwiftUI only gives
/// that to `List`; see `spec/panekit.md`, "Known limits".
public struct PaneListRow: ViewModifier {
    let selected: Bool
    let label: String
    let value: String?
    let editing: Bool
    let cornerRadius: CGFloat
    let select: () -> Void
    @Environment(\.paneListFocused) private var focused
    @Environment(\.paneOutlineLevel) private var level
    @Environment(\.paneOutlineDisclosure) private var disclosure
    @State private var hovered = false
    @State private var menuOpen = false

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        content
            .foregroundStyle(selected && focused ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .background {
                if selected {
                    shape.fill(focused ? AnyShapeStyle(Color.accentColor)
                                       : AnyShapeStyle(Color(nsColor: .unemphasizedSelectedContentBackgroundColor)))
                }
            }
            .overlay { if menuOpen { shape.strokeBorder(Color.accentColor, lineWidth: 2) } }
            .contentShape(Rectangle())
            .onHover { hovered = $0 }
            // SwiftUI's `.contextMenu` says nothing about opening or
            // closing; AppKit's menu tracking does. The menu is this row's
            // if the pointer's over it and the event that opened it was a
            // right-click (or ⌃-click).
            .onReceive(NotificationCenter.default.publisher(for: NSMenu.didBeginTrackingNotification)) { _ in
                guard hovered, let e = NSApp.currentEvent else { return }
                if e.type == .rightMouseDown || (e.type == .leftMouseDown && e.modifierFlags.contains(.control)) {
                    menuOpen = true
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSMenu.didEndTrackingNotification)) { _ in
                menuOpen = false
            }
            .accessibilityElement(children: editing ? .contain : .ignore)
            .accessibilityLabel(spokenLabel)
            .accessibilityValue(spokenValue)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityAction(.default) { select() }
            .accessibilityActions {
                if let disclosure {
                    Button(disclosure.wrappedValue ? "Collapse" : "Expand") {
                        withAnimation(.easeInOut(duration: 0.2)) { disclosure.wrappedValue.toggle() }
                    }
                }
            }
    }

    /// "14 items, level 2": the level only in an outline, where a row
    /// either opens or sits inside one that does.
    private var details: [String] {
        var parts: [String] = []
        if let value { parts.append(value) }
        if disclosure != nil || level > 0 { parts.append("level \(level + 1)") }
        return parts
    }

    /// A row that opens is SwiftUI's own disclosure element, whose value
    /// is its open state and can't be replaced (measured: it read "1",
    /// the count and level gone). So there the details join the label,
    /// and the disclosure says "expanded" or "collapsed" itself.
    private var spokenLabel: String {
        disclosure == nil ? label : ([label] + details).joined(separator: ", ")
    }

    private var spokenValue: String { disclosure == nil ? details.joined(separator: ", ") : "" }
}

public extension View {
    /// See `PaneListNavigation`.
    func paneListNavigation<ID: Hashable>(selection: Binding<ID?>, order: [ID], title: ((ID) -> String)? = nil,
                                          outline: PaneListOutline<ID>? = nil,
                                          onReturn: ((ID) -> Void)? = nil,
                                          accessibilityLabel: String? = nil) -> some View {
        modifier(PaneListNavigation(selection: selection, order: order, title: title, outline: outline,
                                    onReturn: onReturn, accessibilityLabel: accessibilityLabel))
    }

    /// See `PaneListRow`.
    func paneListRow(selected: Bool, label: String, value: String? = nil, editing: Bool = false,
                     cornerRadius: CGFloat = 6, select: @escaping () -> Void) -> some View {
        modifier(PaneListRow(selected: selected, label: label, value: value, editing: editing,
                             cornerRadius: cornerRadius, select: select))
    }
}

public extension EnvironmentValues {
    /// Whether the enclosing `PaneListNavigation` list has the keyboard.
    @Entry var paneListFocused: Bool = false
}
