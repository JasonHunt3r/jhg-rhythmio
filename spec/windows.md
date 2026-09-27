# Windows of their own — the edit suite inside the edit suite

**Status:** Mostly built. Six of Jason's seven answers are in (below).
**Left:** answer 7 (double-click's meaning — still genuinely undecided,
confirmed 2026-09-25), and two areas from the original list ("Areas that
can leave the main window," below) that the built pop-outs don't cover:
**the Library pane itself** (the collections/shows sidebar — what's built
is the separate *Library panel*, all files in a floating window, not this
area detaching) and **the Browser** (Edit Show's collection-file column).
Also still open: the "scrolling a window that's partly covered" idea
(designed, not built), the timeline's height ("Its height", agreed
2026-09-26, not built), and **the windows pass** (below, planned
2026-09-26: the window-layer hierarchy — item 2's other half — the
settings-and-preferences split, and About ShowTools).

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

Names follow `spec/anatomy.md`.

## The idea

The main window holds everything, and everything takes space in it. Many
of its areas should also work **in a window of their own**, and leave the
main window when they do:

- the collections list, popped out and dragged next to where files are
  being dropped from;
- the library as a list window, for the same reason;
- the timeline pane as a tool window of its own;
- a single row opened in a window, larger, to edit it more easily;
- a slide opened by double-click in a large editor in front of
  everything, to work on that slide alone.

In Jason's words: "a mini edit suite inside the edit suite". It will
change as it meets real use.

## Two kinds of window

The difference Jason drew: some windows are **the area itself**, moved;
others are **one thing, opened up**.

### 1. Areas that can leave the main window

A whole area, the same one that's docked in the main window, living in a
window instead. There's one of each. It's listed in the **View or Window
menu**, and it can be put back.

| Area | Why in its own window |
|---|---|
| **Library pane** (collections and shows) | Next to Finder or Photos, as a drop target |
| **Library** as a list | The same, and as a source to drag from while Edit Show fills the main window |
| **Browser** | Its files beside the timeline pane on a second screen |
| **Inspector** | Settings where they're wanted, and the columns get its width back |
| **Viewer** | Already done: the pop-out viewer (`Player.popOut`) shares the viewer's playback |
| **Timeline pane** | The rows full width, on their own screen: the **Timeline window** |

### 2. Editors for one thing

Opened *from* the thing, by double-click or a context menu. They aren't
in the View or Window menu, because each one is about a particular slide
or row, not a place in the app. There can be several, and they close
when done.

- **A row, opened up:** one row (say the audio row, or the images row) in
  a window, taller and with more room, for detailed work.
- **The Slide Editor** (working name; Jason's first word for it was
  "deep edit window"):
  - Double-clicking a slide opens it: a large view of **that slide
    alone**, in front of everything, with its settings around it.
  - The viewer shows the sum of every layer at the playhead. The Slide
    Editor shows one slide and nothing over it, so its details can be
    worked on without fighting the rest of the show.
  - **This is where the collage maker lives** (plan, Later: the gradient
    mask between two photos, and multi-panel slides). A collage is one
    slide built from several images, which is exactly what the Slide
    Editor is for.
  - Its relation to the inspector: the inspector is the quick version,
    always there. The Slide Editor is the deep one, opened on purpose.

## The timeline pane

**The timeline pane** (Jason first called it the edit zone) is the unit
that holds the rows: the transport, the ruler and the rows under it.
Final Cut, Premiere and Resolve all call this the timeline. It's the
thing that could be a tool window of its own, the Timeline window. The
transport goes with it, since zoom, snapping and the range belong with
the rows wherever they are.

**Its height (Jason, 2026-09-26) — built, both halves, 2026-09-26.** Docked or in its own window, the
timeline is **only as tall as its contents** — the transport, the ruler
and the rows — **or smaller**; it can't be dragged taller. **Smaller than
its contents, the rows scroll up and down as normal**, docked or in a
window. **The one exception** is the Timeline window behind another
window, whose padding lets it grow past its contents while covered:
"Scrolling a window that's partly covered", below (Jason restated it
2026-09-26: the padding stays when the window comes to the front, "so as
not to make the tools jump", until it's scrolled back into place).

**When the contents grow** (a row's drawer opens, a preference makes the
rows taller, a row is added) — Jason: "to a point", never squashing the
viewer. **Agreed 2026-09-26:** while it shows all its contents it grows
with them, up to a ceiling — the viewer keeps about half the window, or
its own minimum, whichever is more — then the rows scroll; dragged
smaller than its contents, it keeps its size and scrolls. **A new row
lands at or near the bottom and is scrolled fully into view** (unless
the window is shorter than the row).

**Built 2026-09-26, the ceiling first, the floor the same day:** the
ceiling as a general PaneKit mechanism, not a ShowTools-only patch
(`PaneKit/Sources/PaneKit/PaneModel.swift`, `Split.contentTracking`,
`ContentTracking`; `PaneLayout.sizedExtent`; `PaneController
.setContentExtent`, proven in the standalone harness's own arithmetic
tests first — `PaneLayoutTests`, 5 new cases): a split's sized side can
auto-fit a live, unclamped **content extent** the app reports
(`PaneController.setContentExtent(_:for:)`), instead of a fixed
`defaultSize`, with a ceiling that always reserves at least half the
available space (configurable) — or the main side's own minimum,
whichever is more — for the main side. A stored size (a manual drag) is
clamped into that same ceiling, so a drag can shrink into a scroll but
never grow past the content either. `AppModel.mainPanes`'s outer
`"window"` split carries it; `EditShowTimelinePane.contentHeight` reports
the pane's real content height — the transport, its divider, and
`StorylineView.fullHeight` — which is always the pane's true content,
since `TimelineRow.normalized` keeps every show's `rows` at all four
kinds.

The floor needed vertical row-scrolling in `StorylineView` first, which
didn't exist ("Scrolling a window that's partly covered," below, already
said so: "vertical scrolling arrives with extra rows, and so does this")
— built the same day: `StorylineView.rowsScrollView` wraps the existing
rows content (`rowsZStack` — unchanged) in its own
`ScrollViewReader`/`ScrollView(.vertical)`, sized to
`rowsViewportHeight` (exactly `rowsHeight` — no inner scrolling engages
at all — until the pane's given less room than that). The ruler stays
outside this inner scroll, so it never moves; `rowHandles`, pinned
outside the *horizontal* scroll on purpose (so it never travels sideways
with the timeline), now follows the rows' own vertical scroll offset
(`RowsScrollKey`, the same preference-key pattern the horizontal scroll
already used for the frame strip) so it stays aligned with whichever
rows are actually visible. `EditShowTimelinePane.minContentHeight` (the
transport, its divider, the ruler, and one row) replaced
`contentHeight` as the pane's floor in `AppModel.mainPanes`, so there's
now real room to drag into. A row just moved by a drag scrolls into view
(`pendingRowScroll`, mirroring `session.pendingScroll`'s own one-shot
pattern for the horizontal scroll) — the same mechanism also covers "a
new row lands... scrolled into view" whenever a row can be added, which
nothing does yet (`TimelineRow.normalized` keeps every show at all four
kinds), so that half is reasoned through, not exercised against a real
add.

Checked: `swift build` clean, `swift test` (336 core tests, PaneKit's own
46 → 51, both unchanged by this). A scratch-library launch at the default
(full-content) size renders identically to before. Shrunk well below
full content (`defaults write` a 200-pt stored size directly, a scratch
library, `showtools-testing`'s rules throughout — Jason's real
preferences domain backed up first and restored byte-for-byte after):
the ruler and only the rows that fit (images, slides) show, cut cleanly
at the pane's own edge with no clipping artifact or overlap — the
mechanism holds together. **Not confirmed:** a real drag of the divider
down to that size (coordinate-guessing against the tiny, densely-packed
pane proved too fragile this session — one attempt likely toggled the
unrelated frame-strip drawer instead), the vertical scroll gesture itself
revealing the hidden rows, `rowHandles` visibly tracking that scroll, and
a row-reorder drag's `pendingRowScroll` actually landing. Worth a
particular look with real hands.

## Panes that close to an edge, inside one window (Jason, 2026-09-24)

The same flexibility, before any pane leaves the window: every pane can
close against the window's edge, and come back from it.

**The fail state it came from:**
- Jason dragged the **Library pane's** divider (the library and collections,
  on the left) to the window's edge. The Library pane disappeared past the
  edge, and there was nothing left to grab.
- It wasn't the only pane he lost that way. The right side went too, at
  one point. Whether that can still happen isn't known.
- *From the code:* the Library pane is SwiftUI's own `NavigationSplitView`,
  which collapses when dragged past its minimum (180 points) and puts
  nothing on the edge to pull it back. Edit Show's inspector, on the
  right, is the other pane that collapses. It leaves an invisible strip
  at the right edge that reveals it when dragged
  (`ColumnsSplitView.revealByDragging`), so there's no way to know it's
  there either.

**The idea: the bug becomes a feature.**
- **Closing to an edge is allowed, on purpose.** When a pane closes, an
  **edge handle** stays on that window edge: thin, but always visible and
  clickable. It's the same kind of grip as the bar over the frame strip
  (12 points, with a capsule), which replaced a system line that was too
  fiddly to grab.
- **Where things close to:** the Library pane to the left edge; the timeline
  pane to the bottom edge; the browser (the collection's files) and the
  inspector to the right edge.
- *The Library pane is the hard one:* it's SwiftUI's own split view, which
  offers no edge handle. Adding one means either an overlay that asks
  SwiftUI to show the Library pane again, or taking the Library pane onto
  `ColumnsSplitView`, the house pattern (`spec/how-we-design.md`,
  "Volunteered work follows the house pattern"). That's a harness
  question before it's a build. Then the window can be one big viewer, with every section a
  handle away.
- **Gestures** (`spec/conventions.md`):
  - drag a handle to open the pane to a width, or to resize it;
  - **double-click a handle to open or close its pane**;
  - a modified click reopens a closed pane too.
- **With the panels** (the rest of this file), that makes a single-window
  layout and a many-window layout, from the same panes.

### What it means to leave SwiftUI's split view (assessed 2026-09-24)

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

### The timeline pane's left edge: the drawers

The timeline pane is always edge to edge. Along its left side are the
rows' **drawers**: each row's settings, the rows' prefs.

- **A left handle sets where the timeline rows start.** Sliding it right
  exposes more of the drawers; sliding it left gives the rows more room.
- **The drawers are designed for any width.** Each has **icon-style
  buttons at its left-most edge**, so even a narrow strip of drawer is
  usable.
- **Opening a drawer fully** lays it over its row while it's in use. When
  you're done, it goes back to where it was.
- **⌘⌥-click on a row** opens that row's drawer (conventions).

**Two ways to build the left edge. Try the first, and fall back to the
second:**
1. **Try first: the row handles that exist.** Each row already has its
   own handle at its left end (`StorylineView.rowHandles`: drag to move
   the row, click for its drawer, ⌥-click for all of them). They may be
   all that's needed, with no new divider.
2. **If that doesn't work out:** one full-height divider for the whole
   pane (where the rows start), plus each row's own handle.

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

## Jason's answers (2026-09-24)

1. **What comes first: settled 2026-09-24** — the Slide Editor, then the
   library panel, then one detachable area (probably the inspector), then
   the timeline pane last ("A possible order" below, which is now a plan,
   not a guess).
2. **Following the show depends on the window's job.**
   - Windows tied to playback follow the show's state: the timeline pane,
     the transport, the viewer. They show what's playing and where.
   - Windows that are a *source* don't follow playback. The library
     window doesn't jump to whatever image is on screen.
   - The two are joined on request instead: a context-menu item, **Show
     in Library**, on a slide, lane image or audio clip. It opens the
     library window and selects that file.
3. **Floating or ordinary also depends on the job.** Settled so far
   (later the same evening):

   | Window | Kind | Why |
   |---|---|---|
   | **Library** | panel (floats) | It floats over a new, empty collection so files can be dragged into a big target. This is the use that started the idea (see "Filling a new collection" below) |
   | **Inspector** | panel (floats) | Settings stay in reach over whatever is being worked on. It keeps its place over time |
   | **Timeline window** | ordinary window | It must be able to go *behind* the main viewer, especially once a show has extra rows |
   | **Slide Editor** | bold and in front, transient | Like a big popover: you work in it, and when you're done it goes away |

   The rest are found by trial and error.
4. **Launch restores everything:** which windows are open or detached,
   where they are, their sizes and states. The possible exception is the
   playhead.
5. **The main window closes up.** When an area leaves, its neighbours take
   the space. With the inspector out, the viewer widens and the browser
   slides over. With the browser out as well, the viewer takes that space
   too.
6. **The library list is a floating window, a panel** (confirmed: see 3).
   - On the Mac, a *panel* is a window that floats above the app's other
     windows (the Info panel is one). An ordinary window can go behind.
   - It opens from the **Library** item in the Library pane, which stays there.
   - Its size is free, above a minimum. Narrow, it's a list. Wider, the
     thumbnails grow until each is as wide as the window, a stacked list
     of images. That's the resizing the grid already does with its size
     slider, driven by the window's width. So it's probably the grid
     itself, not a second view. **Built this way 2026-09-24:** it is the
     grid, with one addition — at the size slider's own minimum, the grid
     becomes a genuine single-column list (a small icon, the filename, a
     highlighted full-width row on selection) rather than a row of tiny
     tiles, everywhere the grid appears, not just the panel (Jason,
     2026-09-24).
7. **Double-click: not decided, and to be settled by real testing.**
   - Jason's original idea: double-clicking a collection opens its
     disclosure if it's closed.
   - The app has grown since, so double-click may be better as one
     unified meaning across every element.
   - ⌥-click is the likely partner. Either double-click opens the
     disclosure and ⌥-click opens the Slide Editor, or the other way
     round.
   - Worth knowing when this is tried: ⌥-click on a row handle already
     opens or closes every drawer at once.

## The windows pass (planned 2026-09-26, the settled pieces built 2026-09-27)

Item 2's other half from the 2026-09-25 feedback worklist, grown by
Jason's answers into one pass over every window.

**Make the windows consistent, each defined by its purpose.** What the
code did before this pass (audited 2026-09-26): the Info panel, the Rhythm
panel, the library panel and the Slide Editor are `NSPanel`s that **hid**
when ShowTools wasn't frontmost (`hidesOnDeactivate`); the PaneKit
pop-outs (the Inspector, the Timeline window) **stayed visible** and
dropped to `.normal` (`PaneWindows.swift`). Every one of them sat at
`.floating` while ShowTools was active — **above the Settings window**,
an ordinary window.

**Jason's answers, the three settled ones — built 2026-09-27:**
- **Whether panels hide when ShowTools isn't frontmost is a setting** —
  polite for some kinds of window — but **panels that take drops from
  other apps never hide** (the browser list, popped out, is a
  destination for files dragged from Finder). Built: `PanelHidingSetting`
  (`ShowToolsApp.swift`), an `@AppStorage` toggle in Settings' new
  "Windows" section, default on (matching the old hardcoded behavior).
  The Info panel, the Rhythm tool and the Slide Editor read it fresh each
  time they come to front, so toggling it while one's already open takes
  effect the next time it's raised. The library panel's `hidesOnDeactivate`
  is hardcoded `false` instead — Jason's own exception — where before it
  silently relied on `NSPanel`'s own default of `true`, the bug this whole
  item exists to fix.

  **A second, deeper half of the same bug, found from real feedback the
  same day** ("bringing the focus back to the settings should have also
  brought the other app windows back as a package"): `hidesOnDeactivate`
  only ever controlled *visibility*. All four hand-built panels
  (`InfoPanel`, `RhythmPanel`, `SlideEditorWindow`, the library panel)
  set `window.level = .floating` once, permanently — unlike PaneKit's own
  pop-outs (the Inspector, the Timeline window), which already drop to
  `.normal` when ShowTools isn't active. A window level ranks *across
  every app on screen*, so with hiding turned off, a panel just sat
  floating above every other app's windows forever, not just ShowTools'
  own — it never "left" when you switched away, so there was nothing to
  "bring back." Built `floatOnlyWhileActive` (mirroring
  `PaneWindowController`'s own pattern exactly): Info, Rhythm and the
  Slide Editor now drop to `.normal` whenever ShowTools isn't active, back
  to `.floating` when it is. **The library panel is deliberately left
  out**: it's a drop target for files dragged from Finder, which makes
  *Finder* the active app for the length of the drag — dropping its level
  while inactive would sink it behind Finder's own window exactly when
  it's needed. Checked with a real Finder window dragged to overlap where
  the Info panel sat, `panelsHideWhenInactive` off (to isolate the level
  fix from hiding): before the fix, the Info panel stayed on top of
  Finder even after switching to it; after, it dropped behind, and
  reactivating ShowTools brought it back in front together with the main
  window, "as a package."
- **Settings, opened from the menu or its key, comes up frontmost, and
  panels stop covering it.** Built as `SettingsWindowCoordinator`: every
  hand-built panel registers itself; whenever the Settings window becomes
  key, every registered panel drops to `.normal` (stepping aside without
  losing `hidesOnDeactivate`'s own state), and returns to `.floating` (if
  the app's still active) once Settings resigns key. Settings itself
  stays an ordinary window, per Apple's own guidance (Claude's
  recommendation, accepted): it can still go behind another window on
  request, unlike a permanently-floating one. **Two wrong versions before
  this one, both found by testing, not assumed correct from a clean
  build:** first, capturing `NSApp.keyWindow` from `SettingsView
  .onAppear` — wrong, the same class of timing gotcha `UndoMenuState`
  already documents in this file for `NSApp.keyWindow`: `.onAppear` isn't
  guaranteed to fire after the window's actually become key, so it
  silently captured the *previous* key window instead. Then, matching by
  title (`"<app name> Settings"`, what SwiftUI titled the window before
  it had tabs) — broke the moment Settings became a `TabView`
  (2026-09-27, below): the title now names whichever pane is selected,
  and "Library" collides with the main window's own title. Both found the
  same way: a real Info panel dragged to overlap a reopened Settings
  window, watched with screenshots — it stayed on top both times. Settled
  on `WindowAccessor`, an `NSViewRepresentable` that reads the actual
  `NSWindow` a hosted view sits in directly from AppKit, no guessing from
  timing or title at all; the window is captured once (a stable identity,
  even though its title keeps changing) and compared thereafter. **Scoped
  to this app's own panels** — PaneKit's own pop-outs (the Inspector, the
  Timeline window) aren't covered, since giving PaneKit a dependency on
  ShowToolsApp's Settings window wants a cleaner cross-package hook than
  this pass builds; worth a follow-up if it turns out to matter.
- **About ShowTools** in the app menu — already there. SwiftUI's own
  default app menu provides it for free (confirmed with axtool: "About
  ShowTools" sits right above "Settings…," exactly where you'd expect);
  nothing to build. "Install BGTools" (this doc's own guess at where it
  might live) doesn't exist as a menu item either — the BGTools menu's
  only item today is "Desktop Show…".

**A pro-style, tabbed Settings window — built 2026-09-27.** Jason: the
single scrolling form was "a settings default suitable for a simple app";
wanted a pro one instead, tabs across the top tried first (a left-side
category list is the fallback if a tab row ever gets crowded), grouping
related settings onto each page, and a wider footprint. SwiftUI's
`Settings` scene recognizes a top-level `TabView` and renders it exactly
the way every other Mac app's preferences do — icon tabs in the window's
toolbar, the title naming the selected pane, reopening on the last one
used (`com_apple_SwiftUI_Settings_selectedTabIndex`, its own new
preference key, entirely free) — matching the HIG language already read
out for the layer-fix discussion a day earlier, so no chrome had to be
hand-built.

The old sections became six tabs (`SettingsView`, `ShowToolsApp.swift`):
**Library** (its own section, unchanged), **Editing** (Tags, Collections,
Alerts — everyday behaviors while working in the library), **Playback**,
**Export**, **Windows** (this pass's own new section, and where the rest
of the windows pass will land), **BGTools** (its own tab since it's a
whole companion app, not one setting among others). Each page is
`SettingsPage`, a shared scrollable container capped under the screen's
menu bar and dock, at a wider fixed width (640, up from 520). The window
itself is deliberately not user-resizable
(`.windowResizability(.contentSize)` on the `Settings` scene, Jason: "no
case yet where I'm not thinking of it") — every native Mac preferences
window sizes itself to the selected pane instead of being dragged by
hand, and switching tabs now visibly resizes the window on its own,
confirmed with axtool (640×450 for Library, narrower pages shrinking to
fit their own shorter content).

**Broke, then fixed, the Settings-covering fix above.** Tabs mean the
window's title now names the selected pane instead of staying "ShowTools
Settings" — exactly what defeated the title-matching version of
`SettingsWindowCoordinator`, found immediately by rerunning the same
Info-panel-overlap check after the redesign. `WindowAccessor` (above) is
what replaced it, and is unaffected by the title changing per tab, since
it identifies the window itself, not what it's currently called.

**Settled 2026-09-27, moot: the settings-and-preferences split.** Jason:
now that everything fits logically into the tabbed window, splitting them
apart solves nothing — the tab list already *is* the settings-vs-
preferences distinction, if one turns out to matter later, and today
nothing in it is document-specific (a show's own settings stay in its
inspector, a library's in its Info, same as always).

**Goes in the same pass, in the order Jason chose to take them
(2026-09-27):**
1. ~~The drawers' sensitivity setting with its practice drawer~~ — **built
   2026-09-27**, in the Windows tab (`spec/panekit.md`, "The clutch," has
   the story and what's left: Jason's own tuning by feel — next).
2. Light mode's translucency and a window-background transparency setting
   (item 34, Jason: light mode "is awful") — **a discussion, not yet
   had**, on how to build it.
3. The "Smart View" preference (panes open and close by context — on by
   default — or keep your own choices; `spec/plan.md`, "Slides as mini
   movies") — **wants fleshing out**: today it's a one-paragraph sketch,
   not a build plan.

## Filling a new collection: the problem the library panel solves

Today, making a collection and filling it goes like this:

1. File ▸ New Collection makes "Untitled Collection" and selects it.
   There's no naming step (see `spec/hig-audit.md` §H).
2. The collection is empty. Its message says to drag photos in, or to
   use Add to Collection from the Library, but there's no button.
3. So you either hunt for the small Import button in the toolbar (in the
   grid's filter bar since 2026-09-26; an empty collection's own message
   has an Import… button now too), or
   select the Library, pick files, and drag them onto the collection's
   small row in the Library pane.

With the library panel floating over the empty collection, the whole
collection is the drop target. The audit's H1 and H2 fix the rest,
whether or not the panel exists: name it on creation, and put a button
front and centre.

## Scrolling a window that's partly covered (Jason's idea)

The Timeline window can sit behind the main window, with its top
covered. The idea:

- **While covered:** the Timeline window adds padding at the top of its
  content, as tall as the part that's covered. The top rows can then be
  scrolled down into the visible part with a two-finger swipe, without
  bringing the window to the front.
- **Brought to the front:** the padding stays where it is, so nothing
  jumps. It's scrolled away like any content, and once it's scrolled out
  of view it's gone, and the content goes back to its normal size.

**The scene it's for (Jason):** a late stage of a show, played back
large in the main window. The Timeline window sits behind it, tall, with
only a row or two showing below the viewer. Swiping over that strip
scrolls every row past, so each can be seen against the playback without
disturbing it. To edit, click the Timeline window: it comes forward, the
edit is made, and a swipe brings the whole tool into view. Click the main
window, and the Timeline window drops behind again, ready to be swiped
through. It should feel like magic: covered or not, nothing in the
timeline is ever out of reach.

What's known before trying it:
- **Scrolling a window behind is already normal on the Mac.** A swipe
  scrolls whatever window is under the pointer, front or not, without
  activating it. So only the padding is new.
- **Knowing what's covered:** ShowTools knows where its own windows are
  and in what order. Other apps' window frames are readable too
  (`CGWindowListCopyWindowInfo`; bounds need no screen-recording
  permission). The covered height is where the covering windows' bottom
  edges fall across the Timeline window's top.
- **The padding:** `NSScrollView.contentInsets.top`, changed as windows
  move. The front-window behaviour takes the inset away only once the
  scroll position has passed it, adjusting the scroll position in the
  same step so the content doesn't jump.
- **Not standard Mac behaviour.** No app I know of does this, so it will
  want a harness first and a hands-on feel for it. The timeline scrolls
  only sideways today: vertical scrolling arrives with extra rows, and so
  does this.

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
