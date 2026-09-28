# 2026-09-24 — windows.md's assessment before PaneKit

From `spec/windows.md`, moved here word for word on 2026-09-28 when that
file was sliced (the whole original: `spec/history/verbatim/
windows-retired-2026-09-28.md`). These sections were written before
PaneKit existed; **PaneKit superseded them** (`spec/panekit.md`), and
every step of "A possible order" below is built. Kept for *why*.

## The banner that sat at the top of windows.md

**Superseded by PaneKit, 2026-09-24** (`spec/panekit.md`): this doc's own
"suggested approach" below — a standalone harness proving `ColumnsSplitView`
plus edge handles hold together before touching the app — is **done**,
generalized rather than ShowTools-specific, and merged into the app
(steps 1–3). Read `panekit.md` for what that harness became. Everywhere
below that says `ColumnsSplitView`, `NavigationSplitView` or "the custom
splits already work," read PaneKit: it's what those sections' outcome
was. PaneKit already does the pane-moving this doc calls for — pop out,
put back, remembered frames, the main window closing up. **The show
session is done too** (2026-09-24, "What stands in the way" below), and
so is the order question: Slide Editor, then the library panel, then
every other area, then the timeline pane, last (`spec/panekit.md`, "The
order"). **All of it is built**, 2026-09-24–25: the Slide Editor, the
library panel, the Inspector popping out, and the timeline pane — both
popping out **and**, found missing and fixed 2026-09-25, actually full
width under the Library pane, which this doc's own "The idea" and "What
it is" always meant. What's left of this doc is the open questions under
"Jason's answers" below, and the areas nothing's specifically asked for
yet (the Library pane, the browser).

## What it means to leave SwiftUI's split view (assessed 2026-09-24)

The main window's left pane (the library, collections and shows) is
SwiftUI's `NavigationSplitView` (`MainView.swift`). It's Apple's
ready-made two-column window. Two of Jason's ideas can't be done inside
it:
- **A timeline pane edge to edge.** `NavigationSplitView`'s left pane
  always runs the full height of the window, so nothing can sit under
  it. The timeline pane, which lives in the right-hand column today,
  can't reach the left edge while this container is in use.
- **An edge handle for the left pane.** It collapses below its minimum
  (180 points) and offers nowhere to attach a handle.

**What `NavigationSplitView` gives for free, and would have to be
rebuilt:**
- the translucent Mac sidebar look under the title bar;
- the toolbar's show/hide button for the left pane, and its animation;
- keyboard focus moving between the list and the content;
- its width being remembered.

**What leaving it gives:**
- full control of the layout: the timeline pane under everything, edge
  handles on every edge, any pane able to close;
- one mechanism for the whole window: `ColumnsSplitView`, the app's own
  hand-built split, which Edit Show's columns already use. It's the
  mechanism the crash fix moved Edit Slides onto
  (`spec/edit-slides-inspector-port.md`), and it has been reliable since.

**The cost and the risk:**
- It's a restructuring of the main window, not a tweak. Everything that
  hangs off `NavigationSplitView` today moves: the navigation title, the
  toolbar placement, the per-library `.id` reset of the detail.
- AppKit layout here has bitten before (CLAUDE.md: check it in a
  standalone harness or a layer-tree dump first).
- The translucent look can be kept with a visual-effect background, but
  that's hand work.

**Leaning: leave it (Jason, 2026-09-24).** Writing the replacement is
cheap for Claude, so losing the free parts costs little in code. The
cost that remains is **checking**, not writing: layout bugs that only
show when run (the inspector crash worked for days before it failed),
the small native behaviours (focus, VoiceOver, the toolbar button,
remembered widths), and the fact that only a Mac can run it. The
harness below is what keeps that cost small.

**And the other built-in split (Jason, 2026-09-24): don't use the
built-ins for panes at all.**
- What `NavigationSplitView` gives is **one divider** (the left pane's),
  plus the extras listed above. The full-width timeline pane removes that
  divider anyway, since it can't coexist with a full-height left pane.
- Edit Show's columns and timeline pane are split by `VSplitView`, the
  thin system line, which is exactly the kind of divider edge handles
  replace.
- The custom splits already work: Edit Show's three columns and Edit
  Slides' two, on `ColumnsSplitView`, since the crash fix.
- So: **every pane edge on the app's own split view, with handles.** The
  built-ins become the reference for what to recreate (focus, the
  toggle, the look, remembered sizes), not parts of the app.

**Built as a reusable library (Jason, 2026-09-24):** the pane system,
edge handles and the pane ⇄ panel pop-out go into **PaneKit**, our own
pane library, reusable in other Mac apps: `spec/panekit.md`.

**Suggested approach, done** (`spec/panekit.md`, steps 1–3): a standalone
harness first, answering "does it hold together" before the app was
touched — then the app's own main window and Edit Show's/Edit Slides'
columns moved onto it. The show session (below) doesn't
depend on this, so they can go in either order.

## What already exists to build on

- **Floating panels that share the main window's undo:** the Info panel
  and the Rhythm tool are AppKit panels hosting SwiftUI, whose
  `undoManager` is overridden to the main window's
  (`InfoPanelWindow.sharedUndoManager`). Every detached area needs this: a
  separate window's undo manager isn't the main one's (showtools-gotchas).
  **The override alone isn't enough for ⌘Z to reach it — found popping
  out Edit Show's inspector, fixed app-wide, 2026-09-25**
  (`spec/panekit.md`, "Pane ⇄ panel"): SwiftUI's own automatic Edit ▸
  Undo/Redo commands are scoped to its `Scene` graph, which a
  `PaneWindowController`'s raw AppKit window sits outside of, so they
  never asked the override at all, regardless of what it returned.
  `ShowToolsApp.swift`'s `UndoMenuState` replaces those commands with
  ones that ask `NSApp.keyWindow?.undoManager` directly — this is what
  "⌘Z in them undoes the same history" actually rests on now, for every
  panel, not just PaneKit's.
- **A view of shared playback in another window:** the pop-out viewer
  shows an engine the main window owns. Closing it leaves playback
  running.
- **Following the show on screen:** the Rhythm tool follows whichever show
  is selected, which is how a detached browser or timeline pane would behave.
- **In-app drags between windows:** `ItemDrag` carries library ids, so a
  drag from a detached library or collection list into the timeline pane
  works as it does now within one window.

## What stands in the way (from the code, before any design)

- ~~**The show's editing state lives inside views.**~~ — **done
  2026-09-24** (`spec/panekit.md`, step 4's own prerequisite): the slide
  selection, the engine, the lane's transition/overlay/song/marker
  selections and the storyline's scroll offset are `ShowSession.swift`
  now, one object per open show, owned by `AppModel`
  (`AppModel.session(for:)`, `.closeShowSession()`) — not `@State` in
  `ShowView` or `EditShowView`. `ShowView` and `EditShowView` still read
  and write it through `Binding`s built from the session (`@Bindable var
  session = session`), so the child views below them (`PreviewStage`,
  `CollectionBrowser`, `StorylineView`, `SlideInspector`) needed no
  changes at all. The screen didn't change: verified against a real demo
  show (`tools/make-demo-show.sh`) — selection survives switching between
  Edit Slides and Edit Show, the engine's lifecycle is unchanged (made
  when Edit Show is entered, shut down when it or the whole show is
  left), and leaving the show and reopening it starts a fresh session,
  same as the old `@State` did. Still true and still ahead: zoom
  (`storylineZoom`/`snapping`) stays app-wide `@AppStorage`, not part of
  the session, since it never was per-show; the audit's menu work
  (`spec/hig-audit.md` batch 5) this was also meant to simplify hasn't
  been revisited yet.
- **Keys are per window.** `SingleKeys` (J/K/L, Space, I/O…) is a monitor
  on one window, and menus read focused values from the key window. A
  detached timeline pane needs its own, so Space still plays when it's the
  key window.
- **The columns assume their members.** `ColumnsSplitView` already hides
  the inspector. Taking the browser or the viewer out as well means it
  must lay out whichever columns remain.
- **Window APIs and the layout-loop crash.** The crash was SwiftUI's
  `.inspector()`. New windows should follow the Info panel's pattern (an
  AppKit window hosting SwiftUI) rather than new SwiftUI scene or
  inspector APIs, until a harness says otherwise (CLAUDE.md: check AppKit
  layout in a harness first).

## A possible order (not a plan)

1. ~~**The show session:** state out of the views.~~ — **done 2026-09-24**
   (`ShowSession.swift`, "What stands in the way" above). Changed nothing
   on screen, as expected; the menu work it was meant to simplify
   (`spec/hig-audit.md` batch 5) hasn't been revisited yet.
2. ~~**The Slide Editor,** as the first new window.~~ — **built 2026-09-24**
   (v1: the image, its handles, the full inspector — no playback controls;
   `spec/panekit.md`, "Step 4, first piece"). The collage maker still waits
   for it, since it isn't built yet either.
3. ~~**The library panel,** the second: it opens from the Library pane and
   moves nothing out of the main window.~~ — **built 2026-09-24**
   (`spec/panekit.md`, "Step 4, second piece"). Show in Library, which
   lands here, still waits on the right-click-menu work — it isn't built
   anywhere yet.
4. ~~**One detachable area,** probably the inspector, to prove the
   pattern: undo, keys, and the main window closing up.~~ — **built
   2026-09-25** (Edit Show's inspector; `spec/panekit.md`, "The order,"
   step 4). Proved: the main window closing up, cross-window state
   sharing (the popped-out window live-follows the main window's slide
   selection), and — after a real, measured gap and a same-session fix —
   undo (`spec/panekit.md`, "Pane ⇄ panel": `Edit ▸ Undo`/⌘Z didn't reach
   the popped-out window at all until `UndoMenuState` replaced SwiftUI's
   own automatic Undo/Redo commands, which turned out to be Scene-scoped
   and never asked a PaneKit pop-out's `undoManager` override in the
   first place). Keys weren't exercised (the Inspector has none of its
   own; a future detach with keys, like the timeline, is the real test).
   Then the others.
5. ~~**The timeline pane, detached,** last: it carries the most keys and
   playback.~~ — **built 2026-09-25** (`spec/panekit.md`, "The order,"
   step 5). It was the real keys test step 4 flagged: bare-key shortcuts
   (Space, J/K/L, M, I, O, N, arrows) needed `shortcuts(engine)` moved
   onto the storyline pane's own content so `SingleKeys` re-attaches when
   PaneKit reparents it — done, and confirmed working from the popped-out
   window. Undo/Redo, already fixed app-wide for the Inspector, needed no
   further work here. **`editShowCommands` — found broken, fixed the same
   day:** the Show/View menu's items (Play/Pause, Add Marker, Set Range,
   Zoom, Go Back/Forward, Loop) went disabled while the Timeline window
   was key — `.focusedSceneValue` turns out to be Scene-scoped the same
   way SwiftUI's automatic Undo/Redo was, so a pop-out never published
   into it. `EditShowCommandsValue` moved onto `AppModel`
   (`spec/panekit.md`, step 5, for the fix and the `@ObservationIgnored`
   trap it had to route around), checked with axtool: Loop Playback and
   Set Range In both work through the menu from the popped-out window,
   and Go Back correctly enables after a real nudge.

   **This first build only ever gave the pane the detail column's width,
   not the window's — the actual "full-width, under the Library pane
   too" idea this section has said since before any of it was built.**
   Found and fixed later the same day (2026-09-25, `spec/panekit.md`,
   step 2's own entry and step 5's own follow-up): the pane moved off
   `model.editShowColumns` (nested inside Edit Show's own three columns)
   onto `AppModel.mainPanes`'s own tree, a new outer split wrapping the
   library|detail split, rendered by `MainView`
   (`EditShowTimelinePane.swift`) rather than by `EditShowView`. Two
   further bugs turned up moving it — a Delete-key race between two
   separate `SingleKeys` instances on the same window (settled by giving
   Delete/⌘Delete one handler, not two: `SlideActions.removeSelected`),
   and a popped-out Timeline window left open and blank after leaving
   Edit Show (settled by putting the pane back before its split closes)
   — both `spec/panekit.md`, step 5, has the detail on.

