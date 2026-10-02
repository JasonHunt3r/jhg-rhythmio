import SwiftUI
import AppKit

/// What `List(selection:)` gives an app for free that a plain `ScrollView`
/// doesn't. Built for a translucent sidebar that can't be a real `List` —
/// `NSTableView` doesn't compose with `.withinWindow` vibrancy at all
/// (measured, RhythmIO' Catalog, 2026-09-27: identical, completely flat
/// result whether the effect view was nested via `.safeAreaInset` or a true
/// sibling via `.overlay`) — but nothing here is RhythmIO-specific.
///
/// Like a `List`, it only acts while it has the keyboard: a click anywhere
/// in it takes focus (SwiftUI's own, so Tab and the window's key loop
/// behave), and while it has it —
///
/// - **↑ / ↓** step the selection (held, they repeat) and scroll it into view;
/// - **→** opens a folded row, or on an open one steps to its first child;
///   **←** folds an open row, or steps from a child to its parent;
///   **⌥→ / ⌥←** open or fold the row and everything under it
///   (`outline`; `OutlineIndent`'s ⌥-click does the same);
/// - **typing** a name's first letters selects it; the same letter again
///   steps through every row starting with it (`title`);
/// - **Return** does what the app says (`onReturn`) — rename, in Finder's
///   convention, through `InlineRename`.
///
/// **Several at once** (the `Set` form, `multiple`), as `NSTableView` picks:
/// ⌘-click adds or removes a row, ⇧-click picks the range from the anchor
/// (the row last clicked), ⇧↑ / ⇧↓ grow or shrink that range from the
/// lead (the row the arrows move from), ⌘A picks every row, a
/// double-click runs `primaryAction`, and a click on the empty space below
/// the rows picks nothing. Rows take their clicks through the id form of
/// `.listRow(id:label:)`.
///
/// Rows show whether it has the keyboard through `.listRow`: the accent
/// highlight while it does, grey while it doesn't, and a ring around the
/// row a right-click menu is open for — `List`'s own states.
///
/// The app keeps building its own rows (recursive `DisclosureGroup`s with
/// `.disclosureGroupStyle(.listOutline)`) and its own keys for everything
/// else (Delete, rename). `order` is the current, flat, *visible* row order
/// — folded branches already left out, since only the app knows its fold
/// state — with each row carrying a matching `.id(_:)` for
/// `ScrollViewProxy.scrollTo`.
public struct ListNavigation<ID: Hashable>: ViewModifier {
    @Binding var selection: Set<ID>
    let multiple: Bool
    let order: [ID]
    let title: ((ID) -> String)?
    let outline: ListOutline<ID>?
    let onReturn: ((ID) -> Void)?
    let primaryAction: ((Set<ID>) -> Void)?
    let onFocusChange: ((Bool) -> Void)?
    let focusOnAppear: Bool
    let accessibilityLabel: String?
    @FocusState private var focused: Bool
    @State private var typed = TypeSelect()
    /// Where a ⇧-range starts, and where the arrows move from.
    @State private var anchor: ID?
    @State private var lead: ID?
    /// This list's own mark in `ListKeyboard`, so two lists in one window
    /// don't clear each other's.
    @State private var token = UUID()

    /// One row at a time (a sidebar).
    public init(selection: Binding<ID?>, order: [ID], title: ((ID) -> String)? = nil,
                outline: ListOutline<ID>? = nil, onReturn: ((ID) -> Void)? = nil,
                onFocusChange: ((Bool) -> Void)? = nil, focusOnAppear: Bool = false,
                accessibilityLabel: String? = nil) {
        self._selection = Binding(get: { selection.wrappedValue.map { [$0] } ?? [] },
                                  set: { selection.wrappedValue = $0.first })
        self.multiple = false
        self.order = order
        self.title = title
        self.outline = outline
        self.onReturn = onReturn
        self.primaryAction = nil
        self.onFocusChange = onFocusChange
        self.focusOnAppear = focusOnAppear
        self.accessibilityLabel = accessibilityLabel
    }

    /// Several rows at once (a browser).
    public init(selection: Binding<Set<ID>>, order: [ID], title: ((ID) -> String)? = nil,
                onReturn: ((ID) -> Void)? = nil, primaryAction: ((Set<ID>) -> Void)? = nil,
                onFocusChange: ((Bool) -> Void)? = nil, focusOnAppear: Bool = false,
                accessibilityLabel: String? = nil) {
        self._selection = selection
        self.multiple = true
        self.order = order
        self.title = title
        self.outline = nil
        self.onReturn = onReturn
        self.primaryAction = primaryAction
        self.onFocusChange = onFocusChange
        self.focusOnAppear = focusOnAppear
        self.accessibilityLabel = accessibilityLabel
    }

    public func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            content
                // The empty space below the rows: picks nothing, as a
                // `List` does. On the list itself, not behind it (the
                // scroll view kept those clicks, measured); a row's own tap
                // wins over this one, as a child's always does.
                .contentShape(Rectangle())
                .gesture(TapGesture().onEnded { selection = []; anchor = nil; lead = nil; focused = true },
                         including: multiple ? .all : .subviews)
                .environment(\.listFocused, focused)
                .environment(\.listRefocus, { focused = true })
                .environment(\.listSelection, ListSelectionContext(
                    isSelected: { ($0.base as? ID).map(selection.contains) ?? false },
                    click: { any in
                        guard let id = any.base as? ID else { return }
                        click(id)
                    }))
                .focusable()
                .focusEffectDisabled()
                .focused($focused)
                .onChange(of: focused, initial: true) { _, on in
                    ListKeyboard.set(on, token: token, in: NSApp.keyWindow)
                    onFocusChange?(on)
                }
                .onAppear { if focusOnAppear { focused = true } }
                .onKeyPress(phases: [.down, .repeat]) { press in handle(press, proxy: proxy) }
                // One named group for VoiceOver to enter and leave, as a
                // `List` is ("Sidebar").
                .accessibilityElement(children: .contain)
                .accessibilityLabel(accessibilityLabel ?? "")
        }
    }

    /// A row's click, with the modifiers held and the click count
    /// (`ListSelectionContext.click`).
    private func click(_ id: ID) {
        focused = true
        let event = NSApp.currentEvent
        let flags = event?.modifierFlags ?? []
        let result = Self.clicked(id, command: multiple && flags.contains(.command),
                                  shift: multiple && flags.contains(.shift),
                                  selection: selection, anchor: anchor, in: order)
        if selection != result.selection { selection = result.selection }
        anchor = result.anchor
        lead = result.lead
        if (event?.clickCount ?? 1) >= 2, let primaryAction, selection.contains(id) { primaryAction(selection) }
    }

    /// The row the arrows move from: the lead, if it's still picked;
    /// otherwise the first picked row (the pick changed from outside).
    private var current: ID? {
        if let lead, selection.contains(lead) { return lead }
        return order.first(where: selection.contains)
    }

    private func handle(_ press: KeyPress, proxy: ScrollViewProxy) -> KeyPress.Result {
        // A row's name being edited (`InlineRename`) keeps every key:
        // a key pressed in a focused child reaches this handler too.
        guard !(NSApp.keyWindow?.firstResponder is NSText) else { return .ignored }
        if multiple, press.key == "a", press.modifiers == .command, press.phase == .down {
            selection = Set(order)
            anchor = order.first
            lead = order.last
            return .handled
        }
        // ⌘ and ⌃ belong to menus and the system, never to the list.
        guard press.modifiers.isDisjoint(with: [.command, .control]) else { return .ignored }
        let option = press.modifiers.contains(.option)
        switch press.key {
        case .return:
            guard let onReturn, let current, press.phase == .down, press.modifiers.isEmpty else { return .ignored }
            onReturn(current)
        case .upArrow, .downArrow:
            let delta = press.key == .upArrow ? -1 : 1
            if multiple, press.modifiers.contains(.shift) {
                guard let next = Self.stepped(current, in: order, by: delta) else { return .handled }
                let from = anchor.flatMap { selection.contains($0) ? $0 : nil } ?? current ?? next
                selection = Self.range(from, next, in: order)
                anchor = from
                lead = next
                withAnimation(.default) { proxy.scrollTo(next) }
            } else {
                select(Self.stepped(current, in: order, by: delta), proxy: proxy)
            }
        case .leftArrow, .rightArrow:
            guard let outline else { return .ignored }
            switch Self.horizontal(current, right: press.key == .rightArrow, recursive: option,
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
            select(typed.next(String(typedChar), at: .now, selection: current, order: order, title: title),
                   proxy: proxy)
        }
        return .handled
    }

    private func select(_ id: ID?, proxy: ScrollViewProxy) {
        guard let id else { return }
        anchor = id
        lead = id
        guard selection != [id] else { return }
        selection = [id]
        withAnimation(.default) { proxy.scrollTo(id) }
    }

    /// Pure, pinned by `ListKitTests`: what a click does to the pick, as
    /// `NSTableView` answers it. Plain: just this row. ⌘: this row in or
    /// out, the rest kept. ⇧: the range from the anchor to this row.
    static func clicked(_ id: ID, command: Bool, shift: Bool, selection: Set<ID>, anchor: ID?,
                        in order: [ID]) -> (selection: Set<ID>, anchor: ID?, lead: ID?) {
        if shift, let anchor, order.contains(anchor) {
            return (range(anchor, id, in: order), anchor, id)
        }
        if command {
            var s = selection
            if s.contains(id) { s.remove(id) } else { s.insert(id) }
            return (s, id, id)
        }
        return ([id], id, id)
    }

    /// Every row from `a` to `b`, either way round, in `order`.
    static func range(_ a: ID, _ b: ID, in order: [ID]) -> Set<ID> {
        guard let i = order.firstIndex(of: a), let j = order.firstIndex(of: b) else { return [b] }
        return Set(order[min(i, j)...max(i, j)])
    }

    /// Pure: pinned by `ListKitTests`, not by eye. `nil` selection (or one
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

    /// Pure, pinned by `ListKitTests`: what ← or → does to the selected row,
    /// the way `NSOutlineView` answers it.
    static func horizontal(_ selection: ID?, right: Bool, recursive: Bool, in order: [ID],
                           outline: ListOutline<ID>) -> Horizontal {
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

/// Whether a `ListNavigation` list has the keyboard in a window — the
/// question an app used to ask with `firstResponder is NSTableView`, which
/// a hand-rolled list never answers yes to. An app's own window-wide key
/// handlers (a grid's arrows) ask this to stand aside, as they did for a
/// `List` (RhythmIO' Library grid took the sidebar's arrows, 2026-09-27).
@MainActor public enum ListKeyboard {
    /// Each window's lists that have the keyboard, by their own token —
    /// one list taking it as another lets go mustn't clear the first.
    private static var lists: [ObjectIdentifier: Set<UUID>] = [:]

    public static func hasKeyboard(in window: NSWindow?) -> Bool {
        guard let window else { return false }
        return !(lists[ObjectIdentifier(window)] ?? []).isEmpty
    }

    static func set(_ on: Bool, token: UUID, in window: NSWindow?) {
        guard let window else { return }
        let key = ObjectIdentifier(window)
        if on { lists[key, default: []].insert(token) } else { lists[key]?.remove(token) }
    }
}

/// What `ListNavigation` hands its rows: whether one is picked, and its
/// click (the id form of `.listRow`).
struct ListSelectionContext {
    let isSelected: (AnyHashable) -> Bool
    let click: (AnyHashable) -> Void
}

/// The hierarchy `ListNavigation`'s ← and → need, which a flat `order`
/// doesn't carry. Only the app knows it.
public struct ListOutline<ID: Hashable> {
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
/// passed in, so `ListKitTests` pin it.
struct TypeSelect {
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

/// A row's own chrome inside a `ListNavigation` list: `List`'s
/// selection highlight (the accent while the list has the keyboard, grey
/// while it doesn't), the text colour that goes with it, and the ring
/// around the row whose right-click menu is open.
///
/// And what `List` tells VoiceOver about a row, since a hand-rolled one
/// otherwise reads as loose pieces (its icon, its name and its count as
/// separate elements; Jason, 2026-09-27: these kits are held to an App Store
/// app's standard). The row is one element: `label` is its name, its value
/// is `value` plus, in a `.listOutline` list, "level N" (a row that opens
/// says those in its label instead, and "expanded"/"collapsed" itself —
/// `spokenLabel`); it carries the selected trait; its default action is
/// `select`, and a row that opens has Expand or Collapse. The app adds its
/// own (Rename…) with `.accessibilityAction(named:)` after this. `editing`:
/// while its name is a text field (`InlineRename`), the row opens up
/// so the field can be reached. Not an outline *role* — SwiftUI only gives
/// that to `List`; see `spec/listkit.md`, "Known limits".
public struct ListRow: ViewModifier {
    /// The row's own id, for a list that handles its rows' clicks itself
    /// (`ListNavigation`'s several-at-once form): picked-ness and the click
    /// come from the list, not from `selected` and `select`.
    var id: AnyHashable? = nil
    let selected: Bool
    let label: String
    let value: String?
    let editing: Bool
    let cornerRadius: CGFloat
    let select: () -> Void
    @Environment(\.listFocused) private var focused
    @Environment(\.listSelection) private var list
    @Environment(\.outlineLevel) private var level
    @Environment(\.outlineDisclosure) private var disclosure
    @State private var hovered = false
    @State private var menuOpen = false

    /// Picked: from the list for the id form, else what the app said.
    private var isPicked: Bool {
        if let id, let list { return list.isSelected(id) }
        return selected
    }

    private func activate() {
        if let id, let list { list.click(id) } else { select() }
    }

    public func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)
        let selected = isPicked
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
            // The id form takes its own clicks (modifiers and double-clicks
            // read by the list); off while its name is being edited.
            .gesture(TapGesture().onEnded { activate() }, including: id != nil && !editing ? .all : .subviews)
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
            .accessibilityAction(.default) { activate() }
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
    /// See `ListNavigation`.
    func listNavigation<ID: Hashable>(selection: Binding<ID?>, order: [ID], title: ((ID) -> String)? = nil,
                                      outline: ListOutline<ID>? = nil,
                                      onReturn: ((ID) -> Void)? = nil,
                                      onFocusChange: ((Bool) -> Void)? = nil, focusOnAppear: Bool = false,
                                      accessibilityLabel: String? = nil) -> some View {
        modifier(ListNavigation(selection: selection, order: order, title: title, outline: outline,
                                onReturn: onReturn, onFocusChange: onFocusChange, focusOnAppear: focusOnAppear,
                                accessibilityLabel: accessibilityLabel))
    }

    /// See `ListNavigation`: several rows at once.
    func listNavigation<ID: Hashable>(selection: Binding<Set<ID>>, order: [ID], title: ((ID) -> String)? = nil,
                                      onReturn: ((ID) -> Void)? = nil,
                                      primaryAction: ((Set<ID>) -> Void)? = nil,
                                      onFocusChange: ((Bool) -> Void)? = nil, focusOnAppear: Bool = false,
                                      accessibilityLabel: String? = nil) -> some View {
        modifier(ListNavigation(selection: selection, order: order, title: title, onReturn: onReturn,
                                primaryAction: primaryAction, onFocusChange: onFocusChange,
                                focusOnAppear: focusOnAppear, accessibilityLabel: accessibilityLabel))
    }

    /// See `ListRow`.
    func listRow(selected: Bool, label: String, value: String? = nil, editing: Bool = false,
                     cornerRadius: CGFloat = 6, select: @escaping () -> Void) -> some View {
        modifier(ListRow(selected: selected, label: label, value: value, editing: editing,
                             cornerRadius: cornerRadius, select: select))
    }

    /// See `ListRow`: a row in a list that picks several at once — its
    /// clicks, modifiers and double-clicks are the list's.
    func listRow<ID: Hashable>(id: ID, label: String, value: String? = nil, editing: Bool = false,
                               cornerRadius: CGFloat = 6) -> some View {
        modifier(ListRow(id: AnyHashable(id), selected: false, label: label, value: value, editing: editing,
                         cornerRadius: cornerRadius, select: {}))
    }
}

public extension EnvironmentValues {
    /// Whether the enclosing `ListNavigation` list has the keyboard.
    @Entry var listFocused: Bool = false
}

extension EnvironmentValues {
    /// Set by `ListNavigation` for its rows (the id form of `.listRow`).
    @Entry var listSelection: ListSelectionContext? = nil
}
