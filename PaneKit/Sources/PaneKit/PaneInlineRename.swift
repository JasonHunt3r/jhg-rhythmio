import SwiftUI
import AppKit

/// A row's name that turns into a text field in place, as Finder's sidebar
/// and every `NSTableView` rename does: all of it selected, Return or a
/// click elsewhere keeps the new name, Escape puts the old one back, and an
/// empty or unchanged name is no rename at all. What starts it is the
/// app's (⌥-click, a menu item, or Return through `PaneListNavigation`'s
/// `onReturn`); this only draws it and reports the result.
///
/// Return or Escape hands the keyboard back to the enclosing
/// `PaneListNavigation` list, so the arrows carry on from the renamed row.
public struct PaneInlineRename: View {
    let name: String
    @Binding var isEditing: Bool
    let commit: (String) -> Void
    @State private var draft = ""
    @FocusState private var focused: Bool
    @State private var clickWatch = ClickOutside()
    @Environment(\.paneListRefocus) private var refocus

    public init(_ name: String, isEditing: Binding<Bool>, commit: @escaping (String) -> Void) {
        self.name = name
        self._isEditing = isEditing
        self.commit = commit
    }

    public var body: some View {
        if isEditing {
            TextField("Name", text: $draft)
                .textFieldStyle(.plain)
                .labelsHidden()
                // Finder's look: a text field's own background and colour,
                // not the selected row's white-on-accent, and a focus ring.
                .foregroundStyle(Color(nsColor: .textColor))
                .padding(.horizontal, 3)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 2)
                    .padding(-2))
                .focused($focused)
                .onAppear {
                    draft = name
                    // The list has the keyboard, and asking for it in the
                    // same pass the field appears doesn't take (measured:
                    // the list stayed first responder). One turn later, it
                    // does; then select it all, since AppKit only does
                    // that for a field tabbed into.
                    DispatchQueue.main.async {
                        focused = true
                        DispatchQueue.main.async {
                            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                        }
                    }
                }
                // A click on something that doesn't take the keyboard (the
                // grid's empty space) never takes focus from the field, so
                // focus alone can't tell a click elsewhere happened.
                .onAppear { clickWatch.start { finish(keeping: true, refocusList: false) } }
                .onDisappear { clickWatch.stop() }
                .onSubmit { finish(keeping: true, refocusList: true) }
                .onExitCommand { finish(keeping: false, refocusList: true) }
                // A click anywhere else keeps it, as Finder does.
                .onChange(of: focused) { _, now in if !now, isEditing { finish(keeping: true, refocusList: false) } }
        } else {
            Text(name)
        }
    }

    /// `refocusList`: Return and Escape hand the keyboard back to the
    /// list; a click elsewhere leaves it where the click put it.
    private func finish(keeping: Bool, refocusList: Bool) {
        guard isEditing else { return }
        isEditing = false
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if keeping, !trimmed.isEmpty, trimmed != name { commit(trimmed) }
        if refocusList { refocus?() }
    }
}

/// Watches the window's mouse-downs while a name is being edited, and calls
/// `outside` for one that isn't in the field being edited — found through
/// the field editor, the one text view AppKit edits every field with.
@MainActor private final class ClickOutside {
    private var monitor: Any?

    func start(_ outside: @escaping @MainActor () -> Void) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { event in
            let inside = MainActor.assumeIsolated { () -> Bool in
                guard let window = event.window, let editor = window.firstResponder as? NSTextView,
                      editor.isFieldEditor, let field = editor.delegate as? NSView,
                      let hit = window.contentView?.superview?.hitTest(event.locationInWindow) else { return true }
                return hit === field || hit.isDescendant(of: field)
            }
            if !inside { MainActor.assumeIsolated { outside() } }
            return event
        }
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    isolated deinit { stop() }
}

extension EnvironmentValues {
    /// Set by `PaneListNavigation`: gives its list the keyboard back.
    @Entry var paneListRefocus: (() -> Void)? = nil
}
