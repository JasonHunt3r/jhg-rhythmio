import SwiftUI
import RhythmIOCore
import RhythmIOPlayback
import PaneKit

@main
struct RhythmIOApp: App {
    @State private var model = AppModel()
    @State private var undoState = UndoMenuState()

    // Catches the reason string of the crash the app has been having
    // (ExceptionProbe). Remove with the probe.
    init() {
        ExceptionProbe.install(); LayoutLoopProbe.install(); ListEmptySpace.install()
        KeyboardArea.install()
        DrawerSensitivitySetting.apply()
    }

    var body: some Scene {
        Window("RhythmIO", id: "main") {
            MainView()
                .environment(model)
                .frame(minWidth: 1100, minHeight: 700)
                .task { DevHooks.run(model); RhythmBGHelper.launchAtRhythmIOStartupIfEnabled() }
                .modifier(SettingsURL())
        }
        .defaultSize(width: 1320, height: 820)
        .commands { AppCommands(model: model, undoState: undoState) }

        Settings {
            SettingsView()
                .environment(model)
        }
        // Not user-resizable (Jason, 2026-09-27): every native Mac
        // preferences window sizes itself to the selected pane instead —
        // switching tabs changes the window's size on its own.
        .windowResizability(.contentSize)

        // Help ▸ Keyboard Shortcuts (F3): SwiftUI's default Help menu item
        // says help isn't available, which is worse than nothing.
        Window("Keyboard Shortcuts", id: "shortcuts") {
            KeyboardShortcutsView()
        }
        .defaultSize(width: 480, height: 560)
        .windowResizability(.contentSize)
    }
}

/// Records whatever undo steps `body` registers in a group of their own,
/// closed straight away. For changes made outside any event — after an
/// `await`, once a drop's files have loaded: a step registered there sits
/// in AppKit's automatic group, which stays open until the next event, so
/// Edit ▸ Undo stays disabled and the first ⌘Z only closes the group
/// (measured on drag-to-reorder, 2026-09-25). Closing our own group tells
/// `UndoMenuState` at once.
@MainActor
func inOwnUndoGroup(_ undo: UndoManager?, _ body: () -> Void) {
    undo?.beginUndoGrouping()
    body()
    undo?.endUndoGrouping()
}

/// Tracks the key window's own `UndoManager`, so Edit ▸ Undo/Redo work
/// from any window a pane can pop out into. SwiftUI's own automatic
/// Undo/Redo commands are scoped to its `Scene` graph, which a PaneKit
/// pop-out sits outside of — found 2026-09-25 (`spec/panekit.md`, "Pane
/// ⇄ panel"): the popped-out Inspector's own edits weren't undoable from
/// its own window with SwiftUI's automatic commands, even though
/// `PanePanel.undoManager` correctly returned the same shared
/// `UndoManager` (checked by `ObjectIdentifier`). This replaces those
/// commands with ones that ask `NSApp.keyWindow?.undoManager` directly,
/// so it works the same in the main window, the Slide Editor, the
/// library panel and any future pop-out — they already share one
/// `UndoManager` per `spec/windows.md`'s "undo follows."
@MainActor @Observable
final class UndoMenuState {
    private(set) var canUndo = false
    private(set) var canRedo = false
    private(set) var undoName: String?
    private(set) var redoName: String?
    private weak var manager: UndoManager?
    private var tokens: [NSObjectProtocol] = []

    init() {
        // NotificationCenter hands these to a non-isolated closure even
        // though they always land on the main queue (matches the same
        // pattern EditShowView's KeyView uses for NSEvent monitors).
        let nc = NotificationCenter.default
        let onNotify: (Notification) -> Void = { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        tokens = [
            // Reads `NSApp.keyWindow` rather than the notification's own
            // `.object`, which Swift 6 won't let a non-isolated closure
            // send across into `MainActor.assumeIsolated` here.
            nc.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.manager = NSApp.keyWindow?.undoManager
                    self?.refresh()
                }
            },
            // The ObjC constant names, unmangled: Swift's Foundation
            // overlay doesn't vend these as `NSUndoManager` statics.
            nc.addObserver(forName: Notification.Name("NSUndoManagerCheckpointNotification"),
                           object: nil, queue: .main, using: onNotify),
            nc.addObserver(forName: Notification.Name("NSUndoManagerDidUndoChangeNotification"),
                           object: nil, queue: .main, using: onNotify),
            nc.addObserver(forName: Notification.Name("NSUndoManagerDidRedoChangeNotification"),
                           object: nil, queue: .main, using: onNotify),
            // A group closed with its action already in it. Checkpoint
            // alone misses a step registered outside an event: its only
            // checkpoint comes before the action is registered (measured
            // 2026-09-25, the grid's drag-to-reorder).
            nc.addObserver(forName: Notification.Name("NSUndoManagerDidCloseUndoGroupNotification"),
                           object: nil, queue: .main, using: onNotify),
        ]
        manager = NSApp.keyWindow?.undoManager
        refresh()
    }

    private func refresh() {
        canUndo = manager?.canUndo ?? false
        canRedo = manager?.canRedo ?? false
        undoName = canUndo ? manager?.undoActionName : nil
        redoName = canRedo ? manager?.redoActionName : nil
    }

    func undo() { manager?.undo() }
    func redo() { manager?.redo() }

    isolated deinit {
        let nc = NotificationCenter.default
        for t in tokens { nc.removeObserver(t) }
    }
}

struct AppCommands: Commands {
    let model: AppModel
    let undoState: UndoMenuState
    @FocusedValue(\.activeShowID) private var activeShowID
    @FocusedValue(\.librarySelectionCount) private var librarySelectionCount
    @FocusedValue(\.requestLibraryRename) private var requestLibraryRename
    @FocusedValue(\.requestLibraryGetInfo) private var requestLibraryGetInfo
    @FocusedValue(\.requestLibraryQuickLook) private var requestLibraryQuickLook
    @FocusedValue(\.requestNewCollection) private var requestNewCollection
    // Batch 5 (A2, F1–F4, G5): the open show's slide selection and its
    // Duplicate/Get Info, and Edit Show's transport and timeline commands —
    // absent whenever no show, or no Edit Show, has the window.
    @FocusedValue(\.activeSlideSelection) private var activeSlideSelection
    @FocusedValue(\.requestDuplicateSlides) private var requestDuplicateSlides
    @FocusedValue(\.requestSlideGetInfo) private var requestSlideGetInfo
    // Not `@FocusedValue` any more (found 2026-09-25, `spec/panekit.md`,
    // "The order," step 5): that's scoped to SwiftUI's own Scene graph,
    // so it never reached these menus while the Timeline pane's
    // popped-out window was key. `model.editShowCommands` is a plain
    // stored property, reachable regardless of which window is key.
    private var editShowCommands: EditShowCommandsValue? { model.editShowCommands }
    @AppStorage("frameStripShown") private var frameStripShown = true
    @AppStorage("inspectorShown") private var inspectorShown = true
    @AppStorage("editMode") private var mode: EditMode = .slides
    /// The columns whose inspector the View menu pops out: this mode's.
    private var inspectorColumns: PaneController { mode == .show ? model.editShowColumns : model.editSlidesColumns }
    @AppStorage("snapping") private var snapping = true
    @AppStorage("showRatings") private var showRatings = true
    // Read here so the Viewer submenu's checkmarks follow a change made by
    // a key (⇧Y) or the drawer's own switch.
    @AppStorage(ViewerPlace.library.modeKey) private var libraryViewerMode: ViewerMode = .sideBySide
    @AppStorage(ViewerPlace.libraryPanel.modeKey) private var panelViewerMode: ViewerMode = .sideBySide
    @AppStorage(ViewerPlace.browser.modeKey) private var browserViewerMode: ViewerMode = .sideBySide
    @AppStorage("storylineZoom") private var pps: Double = 24
    @Environment(\.openWindow) private var openWindow

    /// The Side by Side / Stack choice of the place the Viewer menu acts on.
    private var viewerModeBinding: Binding<ViewerMode> {
        switch model.activeViewerPlace {
        case .library: $libraryViewerMode
        case .libraryPanel: $panelViewerMode
        case .browser: $browserViewerMode
        // One picture, the show's own: nothing to switch (the items are off).
        case .slides: .constant(.sideBySide)
        }
    }

    var body: some Commands {
        // Replaces SwiftUI's automatic Undo/Redo (`UndoMenuState`, above):
        // theirs is scoped to SwiftUI's own Scene graph, so a PaneKit
        // pop-out's window never registered with it.
        CommandGroup(replacing: .undoRedo) {
            Button(undoState.undoName.map { "Undo \($0)" } ?? "Undo") { undoState.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!undoState.canUndo)
            Button(undoState.redoName.map { "Redo \($0)" } ?? "Redo") { undoState.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!undoState.canRedo)
        }

        CommandGroup(replacing: .newItem) {
            Button("New Show") { model.newShow() }
                .keyboardShortcut("n")
                .disabled(model.collections.isEmpty)
            Button("New Collection…") { requestNewCollection?() }
                .keyboardShortcut("n", modifiers: [.command, .option])
            Divider()
            Button("Import…") { runImportPanel(model) }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            Button("Add to Library…") { runImportPanel(model, intoCollection: false) }
                .keyboardShortcut("i", modifiers: [.command, .shift, .option])
            Button("Import Show…") { runImportShowPanel(model) }
                .disabled(model.library == nil)
            // The show in the window, or the one selected in the sidebar (plan, Phase 4).
            Menu("Export") {
                Button("Show…") { if let id = exportShowID { runExportPanel(model, showID: id) } }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
                    .disabled(exportShowID == nil || model.exportStatus?.finished == false)
                Button("Movie…") { if let id = exportShowID { runMovieExportPanel(model, showID: id) } }
                    .keyboardShortcut("e", modifiers: [.command, .shift, .option])
                    .disabled(exportShowID == nil || model.movieExportStatus?.finished == false)
            }
            Divider()
            // The Library grid publishes these while it has a selection
            // (2b); a show's slide selection publishes Get Info too (F4) —
            // whichever's in view answers, since only one is ever focused
            // at once.
            Button("Get Info") {
                if let requestSlideGetInfo, !(activeSlideSelection ?? []).isEmpty { requestSlideGetInfo() }
                else { requestLibraryGetInfo?() }
            }
            .keyboardShortcut("i")
            .disabled((librarySelectionCount ?? 0) == 0 && (activeSlideSelection ?? []).isEmpty)
            Button("Rename…") { requestLibraryRename?() }
                .disabled((librarySelectionCount ?? 0) == 0)
            Button("Quick Look") { requestLibraryQuickLook?() }
                .keyboardShortcut("y")
                .disabled((librarySelectionCount ?? 0) == 0)
            Divider()
            // Whole-library maintenance, not scoped to a selection (2b).
            Button("Relink Missing Files…") { model.relinkMissingItems() }
                .disabled(model.library == nil)
            Divider()
            // Libraries switch one at a time, as Photos does (plan, 2b).
            Button("Open Library…") { runOpenLibraryPanel(model) }
                .keyboardShortcut("o", modifiers: [.command, .option])
            Menu("Open Recent Library") {
                ForEach(model.recentLibraries, id: \.self) { url in
                    Button(url.deletingPathExtension().lastPathComponent) {
                        Task { await model.openRecent(url) }
                    }
                }
                if !model.recentLibraries.isEmpty { Divider() }
                Button("Clear Menu") { model.clearRecentLibraries() }
                    .disabled(model.recentLibraries.isEmpty)
            }
            Button("New Library…") { runNewLibraryPanel(model) }
            Button("Open Master Library") { Task { await model.openLibrary(at: model.masterURL) } }
                .disabled(model.isOnMaster)
        }

        // A2: Duplicate, for the slides selected in whichever mode has the
        // window (not lane images yet — no Duplicate action exists for one).
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Duplicate") { requestDuplicateSlides?() }
                .keyboardShortcut("d")
                .disabled((activeSlideSelection ?? []).isEmpty)
        }

        // F2: the inspector toggle and the Edit Slides/Edit Show switch,
        // both really global AppStorage already (one window's change is
        // every window's), so they need no focused value.
        CommandGroup(before: .toolbar) {
            Toggle("Show Library", isOn: Binding(get: { model.mainPanes.isOpen("main") },
                                                 set: { model.mainPanes.setOpen("main", $0) }))
                .keyboardShortcut("l", modifiers: [.command, .option])
            Toggle("Show Frame Strip", isOn: $frameStripShown)
                .keyboardShortcut("f", modifiers: [.command, .option])
            Toggle("Show Inspector", isOn: $inspectorShown)
                .keyboardShortcut("i", modifiers: [.command, .option])
                .disabled(activeShowID == nil)
            // Item 20: the stars in the Library grids and the browser.
            // U (Aperture's Browser key) is bare, so it's in the title, as
            // Snapping's N is, not a key equivalent that would fire while
            // typing — the grids' and the browser's own key handlers take it.
            Toggle("Show Ratings  (U)", isOn: $showRatings)
            // The viewer drawer (`spec/plan.md`, "The viewer drawer"), for
            // whichever grid is in front (`AppModel.activeViewerPlace`). Y
            // and ⇧Y are bare, so they're in the titles, like U.
            Menu("Viewer") {
                Toggle("Show Viewer  (Y)", isOn: Binding(
                    get: { model.viewer(model.activeViewerPlace).isOpen(ViewerLayout.split) },
                    set: { model.viewer(model.activeViewerPlace).setOpen(ViewerLayout.split, $0, animated: true) }))
                Divider()
                Picker("Viewer", selection: viewerModeBinding) {
                    Text("Side by Side  (⇧Y)").tag(ViewerMode.sideBySide)
                    Text("Stack  (⇧Y)").tag(ViewerMode.stack)
                }
                .pickerStyle(.inline)
                .disabled(model.activeViewerPlace == .slides)
            }
            // Item 13: Edit Show's Browser is a drawer now, closing to its
            // own edge handle beside the inspector's (`EditColumnsLayout`).
            Toggle("Show Browser", isOn: Binding(
                get: { model.editShowColumns.isOpen(EditColumnsLayout.browserSplit) },
                set: { model.editShowColumns.setOpen(EditColumnsLayout.browserSplit, $0) }))
                .keyboardShortcut("b", modifiers: [.command, .option])
                .disabled(editShowCommands == nil)
            // Item 30, `RhythmIO Feedback — Worklist for Next CC
            // Session.md`: the timeline pane could already collapse to its
            // own edge handle (every PaneKit split is collapsible by
            // default) — dragging its divider past half its floor, or
            // double-clicking it, already did it — but nothing discoverable
            // offered it, unlike Library/Frame Strip/Inspector just above,
            // which all get a View menu toggle. This is that toggle; the
            // handle it collapses to is PaneKit's own standard one, already
            // built (`PaneEdgeHandleView`).
            Toggle("Show Timeline", isOn: Binding(get: { model.mainPanes.isOpen("window") },
                                                  set: { model.mainPanes.setOpen("window", $0) }))
                .keyboardShortcut("t", modifiers: [.command, .option])
                .disabled(activeShowID == nil)
            // Step 4, third piece (`spec/windows.md`): the first detachable
            // area. Edit Slides' inspector pops out too since 2026-10-03;
            // each mode has its own.
            Toggle("Inspector in Its Own Window", isOn: Binding(
                get: { inspectorColumns.isPoppedOut("inspector") },
                set: { _ in inspectorColumns.togglePopOut("inspector") }))
                .disabled(activeShowID == nil)
            // Step 4's last piece: the timeline pane (`spec/windows.md`,
            // "The timeline pane"). Lives in `model.mainPanes` now, full
            // width under the Library pane too, not `model.editShowColumns`
            // (`spec/panekit.md`, "The order," step 5's follow-up,
            // 2026-09-25). Pops out as an ordinary window, so it can go
            // behind — unlike the Inspector's panel, which floats.
            Toggle("Browser in Its Own Window", isOn: Binding(
                get: { model.editShowColumns.isPoppedOut("list") },
                set: { _ in model.editShowColumns.togglePopOut("list") }))
                .disabled(editShowCommands == nil)
            Toggle("Timeline in Its Own Window", isOn: Binding(
                get: { model.mainPanes.isPoppedOut("storyline") },
                set: { _ in model.mainPanes.togglePopOut("storyline") }))
                .disabled(editShowCommands == nil)
            Divider()
            Button("Edit Slides") { mode = .slides }
                .keyboardShortcut("1")
                .disabled(activeShowID == nil)
            Button("Edit Show") { mode = .show }
                .keyboardShortcut("2")
                .disabled(activeShowID == nil)
            Divider()
            // F1: Edit Show's zoom and snapping — `pps` and `snapping` are
            // both plain AppStorage (one storyline's zoom is every
            // storyline's), so, like the toggles above, these need no
            // focused value; `editShowCommands` gates them to Edit Show,
            // where they mean something.
            Button("Zoom In") { pps = min(pps * 1.5, 400) }
                .keyboardShortcut("=", modifiers: .command)
                .disabled(editShowCommands == nil)
            Button("Zoom Out") { pps = max(pps / 1.5, 2) }
                .keyboardShortcut("-", modifiers: .command)
                .disabled(editShowCommands == nil)
            Button("Zoom to Fit") { editShowCommands?.zoomToFit() }
                .keyboardShortcut("z", modifiers: .shift)
                .disabled(editShowCommands == nil)
            Divider()
            // W8, item 7: the playhead's own history — out of ⌘Z on
            // purpose (plan, "Go Back, not undo"). ⌘[ / ⌘], as in Finder
            // and Safari.
            Button("Go Back") { editShowCommands?.goBack() }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(!(editShowCommands?.canGoBack ?? false))
            Button("Go Forward") { editShowCommands?.goForward() }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(!(editShowCommands?.canGoForward ?? false))
            Divider()
            Toggle("Snapping  (N)", isOn: $snapping)
                .disabled(editShowCommands == nil)
            Divider()
            Button("Restore Default Layout") {
                model.mainPanes.restoreDefaults()
                model.editShowColumns.restoreDefaults()
                model.editSlidesColumns.restoreDefaults()
                model.previewPanes.restoreDefaults()
                DefaultLayout.restore()
            }
            .keyboardShortcut("0", modifiers: [.command, .option])
            Divider()
        }

        // Item 21, `RhythmIO Feedback — Worklist for Next CC Session.md`:
        // a dedicated menu for launching RhythmBG, more discoverable than
        // the toolbar group it lived in before. Its startup settings, at
        // login and with RhythmIO, are in Settings ▸ RhythmBG (B-87).
        CommandMenu("RhythmBG") {
            // Phase 5: the desktop is RhythmBG's job, and it lives inside
            // this app (spec/rhythmbg.md, spec/xcode-port.md).
            Button("Desktop Show…") {
                do { try RhythmBGHelper.openDesktop() } catch { NSAlert(error: error).runModal() }
            }
        }

        CommandMenu("Show") {
            // G5: starts at the selected slide, like the toolbar's own
            // Play and Play Full Screen already do.
            Button("Play") { play(fullScreen: false) }
                .keyboardShortcut("p", modifiers: [.command, .option, .shift])
                .disabled(activeShow == nil)
            Button("Play Full Screen") { play(fullScreen: true) }
                .keyboardShortcut("p", modifiers: [.command, .option])
                .disabled(activeShow == nil)
            Divider()
            // F1: Edit Show's transport and range, published as
            // `editShowCommands` — absent (so these disable themselves) in
            // Edit Slides, which has no viewer or timeline to act on.
            // Play/Pause, Add Marker, Set Range In/Out are bare keys
            // (Space, M, I, O) — never `.keyboardShortcut`, which would
            // steal them from a focused text field (audit M4); the key is
            // named in the title instead, as the browser's E/W/Q already
            // are (C8).
            Button("Play/Pause  (Space)") { editShowCommands?.togglePlay() }
                .disabled(editShowCommands == nil)
            Button("Add Marker  (M)") { editShowCommands?.addMarker() }
                .disabled(editShowCommands == nil)
            Button("Set Range In  (I)") { editShowCommands?.setRangeIn() }
                .disabled(editShowCommands == nil)
            Button("Set Range Out  (O)") { editShowCommands?.setRangeOut() }
                .disabled(editShowCommands == nil)
            Button("Clear Range") { editShowCommands?.clearRange() }
                .keyboardShortcut("x", modifiers: .option)
                .disabled(editShowCommands == nil)
            // W7: modifier-clicks on the range button, restated here since a
            // modifier-click can't be seen (F1).
            Button("Set Range to View") { editShowCommands?.setRangeToView() }
                .disabled(editShowCommands == nil)
            Button("Set Range to Whole Show") { editShowCommands?.setRangeToWholeShow() }
                .disabled(editShowCommands == nil)
            Toggle("Lock Range", isOn: Binding(
                get: { editShowCommands?.rangeLocked ?? false },
                set: { _ in editShowCommands?.toggleRangeLock() }))
                .disabled(editShowCommands == nil)
            Toggle("Loop Playback", isOn: Binding(
                get: { editShowCommands?.loopOn ?? false },
                set: { _ in editShowCommands?.toggleLoop() }))
                .keyboardShortcut("l", modifiers: .command)
                .disabled(editShowCommands == nil)
            Divider()
            Button("Rhythm…") { openRhythm() }
                .keyboardShortcut("r")
                .disabled(activeShowID.flatMap { model.show($0) } == nil)
        }

        // F3: replaces SwiftUI's default item, which just says help isn't
        // available, with the single-key commands that have nowhere else
        // to show themselves.
        CommandGroup(replacing: .help) {
            Button("Keyboard Shortcuts") { openWindow(id: "shortcuts") }
        }
    }

    private var exportShowID: Int64? {
        if let id = activeShowID, model.show(id) != nil { return id }
        if case .show(let id) = model.sidebar, model.show(id) != nil { return id }
        return nil
    }

    private var activeShow: Show? {
        activeShowID.flatMap { model.show($0) }.flatMap { $0.slides.isEmpty ? nil : $0 }
    }

    /// The Rhythm tool (plan, Phase 3 step 7), on the show in the window.
    @MainActor private func openRhythm() {
        guard let id = activeShowID else { return }
        RhythmTool.shared.open(showID: id, model: model, undoManager: NSApp.mainWindow?.undoManager)
    }

    /// G5: starts at the selected slide, matching the toolbar's own Play
    /// and Play Full Screen (`ShowView.firstSelectedIndex`) — before this
    /// fix the two ⌥⇧⌘P/⌥⌘P shortcuts always started from the top.
    @MainActor private func play(fullScreen: Bool) {
        guard let show = activeShow else { return }
        let startAt = show.slides.firstIndex { (activeSlideSelection ?? []).contains($0.id) }
        Player.open(show: show, model: model, fullScreen: fullScreen, startAt: startAt)
    }
}

/// Whether the Info panel, the Rhythm tool and the Slide Editor step out of
/// the way when RhythmIO isn't frontmost (`spec/windows.md`, "The windows
/// pass," settled 2026-09-26: "polite for some kinds of window"). Read
/// fresh each time one of those panels comes to front, so toggling this
/// while one's already open takes effect the next time it's raised, not
/// just on a fresh launch. **The library panel never reads this** — it's
/// always a drop target for files dragged from Finder, so it never hides,
/// on or off (Jason's own exception, same discussion).
enum PanelHidingSetting {
    static let key = "panelsHideWhenInactive"
    static var isOn: Bool { (UserDefaults.standard.object(forKey: key) as? Bool) ?? true }
}

/// A tabbed, toolbar-switched window — the "pro" style every other
/// Mac app's preferences use (System Settings, Mail, Xcode) — rather than
/// one long scrolling form. Settled with Jason 2026-09-27: tabs across
/// the top first (a left-side category list is the fallback if a tab row
/// ever gets too crowded), grouping related settings onto each page.
/// SwiftUI's `Settings` scene recognizes a top-level `TabView` and renders
/// it exactly this way natively: icon tabs in the window's toolbar, the
/// title naming the selected pane, reopening on the last one used — all
/// for free, matching the HIG's own description of Settings that Claude
/// read out for the layer-fix discussion a day earlier.
struct SettingsView: View {
    /// The selected tab, kept so a `rhythmio://settings/<tab>` URL can pick
    /// one (B-87); it still reopens on the last one used.
    @AppStorage(SettingsURL.tabKey) private var tab = "library"

    var body: some View {
        TabView(selection: $tab) {
            LibrarySettingsTab()
                .tabItem { Label("Library", systemImage: "internaldrive") }
                .tag("library")
            EditingSettingsTab()
                .tabItem { Label("Editing", systemImage: "pencil") }
                .tag("editing")
            TimelineSettingsTab()
                .tabItem { Label("Timeline", systemImage: "ruler") }
                .tag("timeline")
            PlaybackSettingsTab()
                .tabItem { Label("Playback", systemImage: "play.rectangle") }
                .tag("playback")
            ExportSettingsTab()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                .tag("export")
            WindowsSettingsTab()
                .tabItem { Label("Windows", systemImage: "macwindow") }
                .tag("windows")
            RhythmBGSettingsTab()
                .tabItem { Label("RhythmBG", systemImage: "display") }
                .tag("rhythmbg")
        }
        .background(WindowAccessor { SettingsWindowCoordinator.captured($0) })
    }
}

/// Shared layout for every tab's page: a wider footprint than the old
/// single scrolling form had room for ("a greedier footprint," Jason,
/// 2026-09-27) — each page reads more like a real preferences pane, not a
/// cramped list — still capped under the screen's menu bar and dock
/// (item 9, `RhythmIO Feedback — Worklist for Next CC Session.md`) and
/// still scrollable if a page ever grows past that. The window itself is
/// deliberately not user-resizable (`RhythmIOApp.body`'s
/// `.windowResizability(.contentSize)` on the `Settings` scene): every
/// native Mac preferences window behaves this way, sizing itself to
/// whichever pane is selected rather than being dragged by hand: there's
/// no case yet where a fixed width doesn't fit this content.
private struct SettingsPage<Content: View>: View {
    @ViewBuilder var content: Content
    /// The form's own height: a scroll view has none to offer, so without
    /// it the window opened short and a long page (Timeline, 2026-10-03)
    /// hid its last rows below a scroll nobody would guess at.
    @State private var contentHeight: CGFloat?

    static var width: CGFloat { 640 }

    /// A fixed margin below the visible frame, not the whole screen
    /// height, so a tall page never touches the menu bar or dock even
    /// centered.
    private var maxHeight: CGFloat { (NSScreen.main?.visibleFrame.height ?? 800) - 80 }

    var body: some View {
        ScrollView {
            Form { content }
                .formStyle(.grouped)
                .scrollDisabled(true)
                .padding(.bottom, 8)
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { contentHeight = $0 }
        }
        .frame(width: Self.width)
        .frame(height: contentHeight.map { min($0, maxHeight) })
        .frame(maxHeight: maxHeight)
    }
}

private struct LibrarySettingsTab: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SettingsPage {
            Section("Library") {
                LabeledContent("Name", value: model.libraryName)
                LabeledContent("Location") {
                    HStack {
                        Text(model.library?.root.path(percentEncoded: false) ?? "—")
                            .lineLimit(1).truncationMode(.middle)
                            .textSelection(.enabled)
                        Button("Show in Finder") {
                            if let root = model.library?.root {
                                NSWorkspace.shared.activateFileViewerSelecting([root])
                            }
                        }
                    }
                }
                Toggle("Let Spotlight index the library", isOn: Binding(
                    get: { !model.libraryHiddenFromSpotlight },
                    set: { model.setSpotlightIndexing($0) }))
                Text(model.libraryHiddenFromSpotlight
                     ? "Hidden: the library folder ends in “.noindex”, so Spotlight skips its file names, image details and the text in pictures."
                     : "Searchable: Spotlight can find library files by name, image details and the text in pictures.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Toggle("Private library", isOn: Binding(
                    get: { model.libraryIsPrivate },
                    set: { on in Task { await model.setPrivate(on) } }))
                    .disabled(model.library == nil)
                Text("Opening a private library asks for Touch ID or your Mac's password, and it's never listed in Open Recent. Turning this off asks too. It locks RhythmIO's door only: the photos are still ordinary files to anyone using this Mac account. To lock the files themselves, keep the library in an encrypted disk image (Disk Utility can make one).")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Everyday editing behaviors, grouped together: tags, how a file joins a
/// show's collection, and the removal notice.
private struct EditingSettingsTab: View {
    @AppStorage(FinderTagsSetting.key) private var writeFinderTags = false
    @AppStorage(CollectionAddNotice.autoAddKey) private var autoAddToCollection = false
    @AppStorage(SlideRemovalNotice.suppressKey) private var suppressRemovalNotice = false
    @AppStorage(NumberStepping.axisKey) private var swipeAxis = NumberStepping.Axis.horizontal.rawValue
    @AppStorage(NumberStepping.bigKey) private var bigFactor = 10.0
    @AppStorage(NumberStepping.fineKey) private var fineFactor = 10.0
    @AppStorage(NumberStepping.distanceKey) private var swipeDistance = 10.0

    var body: some View {
        SettingsPage {
            Section("Tags") {
                Toggle("Also write tags as Finder tags", isOn: $writeFinderTags)
                Text("Tags always live in the library's database, whether or not this is on. With it on, they're also set as macOS Finder tags on the library files themselves.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("Collections") {
                Toggle("Add files to the collection automatically", isOn: $autoAddToCollection)
                Text("When a file that isn't in a show's collection goes into the show, add it to the collection without asking. Off: RhythmIO asks first.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("Number Fields") {
                LabeledContent("Swipe to step") {
                    Picker("", selection: $swipeAxis) {
                        ForEach(NumberStepping.Axis.allCases, id: \.self) { Text($0.title).tag($0.rawValue) }
                    }
                    .labelsHidden().pickerStyle(.segmented).fixedSize()
                }
                LabeledContent("⇧ steps") {
                    Stepper("× \(Int(bigFactor))", value: $bigFactor, in: 2...100)
                }
                LabeledContent("⌥ steps") {
                    Stepper("÷ \(Int(fineFactor))", value: $fineFactor, in: 2...100)
                }
                LabeledContent("Swipe per step") {
                    Slider(value: $swipeDistance, in: 3...40) {
                        EmptyView()
                    } minimumValueLabel: {
                        Text("Fast").foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("Slow").foregroundStyle(.secondary)
                    }
                    .frame(width: 220)
                }
                Text("While you're editing a number, ↑ ↓ step it, and so does a two-finger swipe over it — right and up go up. A step is the field's own unit (1 %, 1°, 0.1 s); ⇧ and ⌥ make it bigger or smaller. Edit Range's timecode steps by Settings ▸ Timeline ▸ Nudge instead. The number is saved when you finish editing, so a whole scrub is one undo step.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("Alerts") {
                Toggle("Explain what removing a slide does", isOn: Binding(
                    get: { !suppressRemovalNotice },
                    set: { suppressRemovalNotice = !$0 }))
                Text("The notice that a slide removed from a show isn't moved to the Trash.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Settings ▸ Timeline (`spec/range-and-ruler.md`, "B-06: keyboard
/// movement"): the Nudge steps and which key gives one frame.
private struct TimelineSettingsTab: View {
    @AppStorage(NudgeSettings.defaultsKey) private var data = Data()

    private var nudge: Binding<NudgeSettings> {
        Binding(get: { NudgeSettings.decode(data) }, set: { data = $0.encoded })
    }

    var body: some View {
        let n = nudge.wrappedValue
        let stepKeys = n.fineKey == .option ? "← →" : "⌥ ← →"
        let frameKeys = n.fineKey == .option ? "⌥ ← →" : "← →"
        SettingsPage {
            Section("Nudge") {
                stepRow(stepKeys, nudge.step)
                stepRow("⇧ ← →", nudge.shiftStep)
                stepRow("⇧⌥⌘ ← →", nudge.bigStep)
                LabeledContent("Exactly one frame") {
                    Picker("", selection: nudge.fineKey) {
                        Text("⌥ ← →").tag(NudgeSettings.FineKey.option)
                        Text("← →").tag(NudgeSettings.FineKey.plainArrow)
                    }
                    .labelsHidden().pickerStyle(.segmented).fixedSize()
                }
                Text("The arrows move whatever's selected on the ruler — a marker, a range end — or the playhead when nothing is. \(frameKeys) always moves exactly one frame of the show's frame rate. ⌘ ← → jumps to the next marker (on a selected marker, the selection hops instead), ⌘⌥ ← → to the next detected beat.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                LabeledContent("Markers collide closer than") {
                    Stepper("\(n.mergeTolerance) frame\(n.mergeTolerance == 1 ? "" : "s")",
                            value: nudge.mergeTolerance, in: 1...60)
                }
                Text("Two markers of the same kind can't sit closer than this. Placing one there replaces the one that was there; dragging or nudging one there puts it back. At 1, only the same frame collides.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                LabeledContent("Alerts") {
                    Button("Reset “Don't Show Again” Alerts") {
                        UserDefaults.standard.removeObject(forKey: MarkerCollisionNotice.suppressKey)
                    }
                }
            }
        }
    }

    private func stepRow(_ keys: String, _ step: Binding<NudgeSettings.Step>) -> some View {
        LabeledContent(keys) {
            HStack(spacing: 6) {
                TextField("", value: Binding(get: { step.wrappedValue.value },
                                             set: { v in
                                                 // Frames are whole; nothing is zero or less.
                                                 let unit = step.wrappedValue.unit
                                                 step.wrappedValue.value = unit == .frames ? max(v.rounded(), 1) : max(v, 0.01)
                                             }),
                          format: .number)
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 64)
                    .numberStepping(unit: step.wrappedValue.unit == .frames ? 1 : 0.1,
                                    range: step.wrappedValue.unit == .frames ? 1...9_999 : 0.01...3_600,
                                    decimals: step.wrappedValue.unit == .frames ? 0 : 2,
                                    commit: { v in
                                        step.wrappedValue.value = step.wrappedValue.unit == .frames ? max(v.rounded(), 1) : max(v, 0.01)
                                    })
                Picker("", selection: step.unit) {
                    ForEach(NudgeSettings.Step.Unit.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .labelsHidden().fixedSize()
            }
        }
    }
}

private struct PlaybackSettingsTab: View {
    @AppStorage("showSlideProgress") private var showSlideProgress = true

    var body: some View {
        SettingsPage {
            Section("Playback") {
                Toggle("Show the slide progress line", isOn: $showSlideProgress)
                Text("The thin white line along the bottom of the picture that fills through each slide. Also in the viewer's own right-click menu.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ExportSettingsTab: View {
    @AppStorage(ExportSettings.stripKey) private var stripOnExport = true

    var body: some View {
        SettingsPage {
            Section("Export") {
                Toggle("Strip metadata from exported files", isOn: $stripOnExport)
                Text(stripOnExport
                     ? "File ▸ Export Show… removes location, camera, dates and other details from the copies it makes. Audio files keep their title, artist and album; only the buyer's details come off. The files in the library are never changed."
                     : "Exported copies are exact copies of the library's files, with their location, camera and date still in them.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// `spec/windows.md`, "The windows pass": grows as the rest of that pass
/// lands (the drawers' sensitivity setting, light mode's translucency and
/// a background-transparency setting) — a stable, named home for it
/// rather than a section sharing a page with something unrelated.
private struct WindowsSettingsTab: View {
    @AppStorage(PanelHidingSetting.key) private var panelsHideWhenInactive = true
    @AppStorage(DrawerSensitivitySetting.engageKey) private var engageDistance = DrawerSensitivitySetting.defaultEngage
    @AppStorage(DrawerSensitivitySetting.slideKey) private var slideSpeed = DrawerSensitivitySetting.defaultSlide
    @ObservedObject private var scrollBarSetting = ScrollBarTranslucency.shared
    @Environment(\.colorScheme) private var systemScheme
    @State private var pickedScheme: ColorScheme?

    /// One knob standing in for both of `DrawerSensitivitySetting`'s
    /// dials at once: reads back as their average normalized position (so
    /// a value set from the box, `TriggerBoundariesBox`, still shows up
    /// here as roughly the right spot), and moving it sets both dials to
    /// that same normalized position together. The box itself is where
    /// the two are pulled apart again, for tuning either one on its own.
    private var responsiveness: Binding<Double> {
        Binding(
            get: {
                let er = DrawerSensitivitySetting.engageRange
                let sr = DrawerSensitivitySetting.slideRange
                let te = (engageDistance - er.lowerBound) / (er.upperBound - er.lowerBound)
                let ts = (slideSpeed - sr.lowerBound) / (sr.upperBound - sr.lowerBound)
                return (te + ts) / 2
            },
            set: { t in
                let er = DrawerSensitivitySetting.engageRange
                let sr = DrawerSensitivitySetting.slideRange
                engageDistance = er.lowerBound + t * (er.upperBound - er.lowerBound)
                slideSpeed = sr.lowerBound + t * (sr.upperBound - sr.lowerBound)
                DrawerSensitivitySetting.apply()
            })
    }

    var body: some View {
        SettingsPage {
            Section("Windows") {
                Toggle("Panels hide when RhythmIO isn't frontmost", isOn: $panelsHideWhenInactive)
                Text("The Info panel, the Rhythm tool and the Slide Editor step out of the way when you switch to another app, like an ordinary panel. The library panel never hides, even with this off — it's where files dragged from Finder land.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            // spec/panekit.md, "The clutch," "A sensitivity setting."
            Section("Drawer Sensitivity") {
                Slider(value: responsiveness, in: 0...1) {
                    Text("Responsiveness")
                } minimumValueLabel: {
                    Text("Sensitive").font(.callout).foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Text("Relaxed").font(.callout).foregroundStyle(.secondary)
                }
                Text("How far a drawer must be pulled before it engages, and how quickly it slides once it does.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Set Up Triggers…") {
                    SettingsBox.present(section: "Drawer Sensitivity", title: "Set Up Triggers") { dismiss in
                        TriggerBoundariesBox(dismiss: dismiss)
                    }
                }
            }
            // spec/windows.md, item 34, reworked 2026-09-27: scoped to bars
            // that scrolled content passes under (the Library grid's filter
            // bar) — no sub-window, no region picker, one slider per
            // appearance, right here.
            // One module (Jason, 2026-09-27): pick the appearance, then its
            // two sliders and its handles switch — each kept per appearance.
            Section("Transparency") {
                Picker("Appearance", selection: editingScheme) {
                    Text("Light").tag(ColorScheme.light)
                    Text("Dark").tag(ColorScheme.dark)
                }
                .pickerStyle(.segmented)
                transparencyRow("Panel Transparency", zone: .bars)
                transparencyRow("Title Bar Transparency", zone: .header)
                Toggle("Include handles", isOn: Binding(
                    get: { scrollBarSetting.includesHandles(editingScheme.wrappedValue) },
                    set: { scrollBarSetting.setIncludesHandles($0, for: editingScheme.wrappedValue) }))
                Text("Panel Transparency: the bars content scrolls under — the grid's filter bar, the sidebar's top and bottom, the browser's bar and headers. Title Bar Transparency: the window's own title bar and toolbar, which show the desktop behind the window. At 0%, fully solid; at 100%, the OS's own see-through look. Include handles puts drawers' handle rows on the panel setting instead of solid. Each is kept separately for Light and Dark.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Which appearance the Transparency module is showing: the Mac's own
    /// until you pick the other.
    private var editingScheme: Binding<ColorScheme> {
        Binding(get: { pickedScheme ?? systemScheme }, set: { pickedScheme = $0 })
    }

    @ViewBuilder
    private func transparencyRow(_ label: String, zone: ScrollBarTranslucency.Zone) -> some View {
        let scheme = editingScheme.wrappedValue
        let value = scrollBarSetting.value(for: scheme, zone: zone)
        // The setting stores how *opaque* (0 the OS's material, 1 solid);
        // titled Transparency, the slider shows the other way round, so
        // 100% reads as fully see-through.
        HStack(spacing: 10) {
            CommitSlider(title: label, value: 1 - value, range: 0...1, display: 100, unit: "%",
                         commit: { scrollBarSetting.setValue(1 - $0, for: scheme, zone: zone) },
                         preview: { scrollBarSetting.preview(1 - $0, for: scheme, zone: zone) })
            ScrollBarPreview(amount: value, scheme: scheme, material: zone == .header ? .titlebar : .headerView)
        }
    }
}

/// RhythmBG's two ways of starting on its own. "Open RhythmBG at login"
/// lives here because only RhythmIO, its host, can change that login item
/// (B-87); RhythmBG's "Open at Login…" opens this tab. "Launch RhythmBG
/// when RhythmIO launches" is item 21 of `RhythmIO Feedback — Worklist for
/// Next CC Session.md`. Its own tab since RhythmBG is a whole companion
/// app, not one setting among others.
private struct RhythmBGSettingsTab: View {
    @AppStorage(RhythmBGHelper.launchWithRhythmIOKey) private var launchRhythmBGWithRhythmIO = false
    /// The login item's status isn't observable, so it's read on appear and
    /// again after each change.
    @State private var atLogin = RhythmBGHelper.isRegisteredAtLogin

    var body: some View {
        SettingsPage {
            Section("RhythmBG") {
                Toggle("Open RhythmBG at login", isOn: Binding(get: { atLogin }, set: { on in
                    if on { RhythmBGHelper.registerAtLogin() } else { RhythmBGHelper.unregisterAtLogin() }
                    atLogin = RhythmBGHelper.isRegisteredAtLogin
                }))
                Text("Plays your desktop shows from the moment you log in. Also listed in System Settings ▸ General ▸ Login Items.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Toggle("Launch RhythmBG when RhythmIO launches", isOn: $launchRhythmBGWithRhythmIO)
                Text("Starts the desktop background player in the background, without opening its window.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { atLogin = RhythmBGHelper.isRegisteredAtLogin }
    }
}

/// `rhythmio://settings/<tab>` opens Settings on that tab (B-87: RhythmBG's
/// "Open at Login…" sends `rhythmio://settings/rhythmbg`).
struct SettingsURL: ViewModifier {
    static let tabKey = "settingsTab"
    @Environment(\.openSettings) private var openSettings

    func body(content: Content) -> some View {
        content.onOpenURL { url in
            guard url.scheme == "rhythmio", url.host == "settings" else { return }
            let tab = url.lastPathComponent
            if !tab.isEmpty, tab != "/" { UserDefaults.standard.set(tab, forKey: Self.tabKey) }
            openSettings()
        }
    }
}

/// Developer-only: lets a script open a show and start the player without
/// clicking, so the app can be checked from the command line. Inert unless
/// the environment variable is set.
///
///   RHYTHMIO_DEV_PLAY="<showID>:<slideIndex>[:full]"
///   RHYTHMIO_DEV_SHOW="<showID>[:<slideIndex>]"   select a show (and a slide)
@MainActor
enum DevHooks {
    static func run(_ model: AppModel) {
        if let spec = ProcessInfo.processInfo.environment["RHYTHMIO_DEV_SHOW"] {
            let parts = spec.split(separator: ":")
            if let id = parts.first.flatMap({ Int64($0) }), let show = model.show(id) {
                model.sidebar = .show(id)
                if parts.count > 1, let i = Int(parts[1]), show.slides.indices.contains(i) {
                    model.devSelection = show.slides[i].id
                }
            }
        }
        guard let spec = ProcessInfo.processInfo.environment["RHYTHMIO_DEV_PLAY"] else { return }
        let parts = spec.split(separator: ":")
        guard let id = parts.first.flatMap({ Int64($0) }), let show = model.show(id) else { return }
        model.sidebar = .show(id)
        let index = parts.count > 1 ? Int(parts[1]) : nil
        Player.open(show: show, model: model, fullScreen: parts.contains("full"), startAt: index)
    }
}
