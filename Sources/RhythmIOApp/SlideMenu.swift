import SwiftUI
import RhythmIOCore
import PaneKit

/// A slide's right-click menu, the same in Edit Slides' list and the
/// timeline (`spec/conventions.md` §3, "Slide (list or timeline)", settled
/// 2026-09-24; B-18, B-19). `ids` is what it acts on: the selection when
/// the slide clicked is in it, else that slide. The timeline adds Slide
/// Info and Select All After through `timeline`.
struct SlideMenu: View {
    let ids: Set<Int64>
    let show: Show
    let mutate: ShowMutator
    @Binding var selection: Set<Int64>
    let openSlideEditor: (Int64) -> Void
    let replaceImage: (Int64) -> Void
    var timeline: TimelineExtras?

    /// What only the timeline's menu has.
    struct TimelineExtras {
        let slideInfo: () -> Void
        /// This slide and every one after it (Jason, 2026-10-03).
        let selectAllAfter: () -> Void
    }

    @Environment(AppModel.self) private var model
    @Environment(\.undoManager) private var undoManager
    @AppStorage("inspectorShown") private var inspectorShown = true

    var body: some View {
        if let id = ids.first {
            Button("Open in Slide Editor") { openSlideEditor(id) }
            Button("Open Inspector") { openInspector() }
            if let timeline {
                Button("Slide Info") { timeline.slideInfo() }
                    .keyboardShortcut(.space, modifiers: .option)
            }
            Button("Show in Library") {
                guard let itemID = show.slides.first(where: { $0.id == id })?.itemID else { return }
                showInLibrary(itemID, model: model, undoManager: undoManager)
            }
            if ids.count == 1 { Button("Replace Image…") { replaceImage(id) } }
        }
        Divider()
        Button("Play from Here") { Player.open(show: show, model: model, fullScreen: false, startAt: firstIndex) }
        Button("Play Full Screen") { Player.open(show: show, model: model, fullScreen: true, startAt: firstIndex) }
        if let timeline {
            Divider()
            Button("Select All After") { timeline.selectAllAfter() }
        }
        Divider()
        // Copy Settings/Paste Settings are meant to appear only while ⌥
        // is held (settled design) — simplified to always-visible items
        // here; see SlideClipboard's own note on why.
        Button("Copy") { SlideClipboard.copy(ids, from: show) }
        Button("Paste") { SlideClipboard.paste(after: lastByOrder, mutate: mutate) }
            .disabled(!SlideClipboard.canPaste)
        if ids.count == 1, let id = ids.first {
            Button("Copy Settings") { SlideClipboard.copySettings(id, from: show) }
        }
        Button("Paste Settings") { SlideClipboard.pasteSettings(onto: ids, mutate: mutate) }
            .disabled(!SlideClipboard.canPasteSettings)
        Divider()
        QuickSettingsMenu.length(Array(ids), mutate: mutate) { openInspector() }
        QuickSettingsMenu.transition(Array(ids), mutate: mutate)
        QuickSettingsMenu.panAndZoom(Array(ids), mutate: mutate)
        Divider()
        Button("Duplicate") { SlideActions.duplicate(ids, mutate: mutate) }
        Button("Remove from Show") { SlideActions.remove(ids, selection: $selection, mutate: mutate) }
        PaneWindowMenuItem()
    }

    /// Selects the slides and shows the inspector, in whichever mode.
    private func openInspector() {
        selection = ids
        inspectorShown = true
    }

    private var firstIndex: Int? { show.slides.firstIndex { ids.contains($0.id) } }
    /// Paste lands after the last (by show order) of the ids the menu was
    /// opened on, so pasting onto a selection reads as "after what I had
    /// selected," not wherever the id set happens to iterate to.
    private var lastByOrder: Int64? { show.slides.lastIndex { ids.contains($0.id) }.map { show.slides[$0].id } }
}
