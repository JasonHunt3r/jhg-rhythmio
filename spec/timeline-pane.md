# The timeline pane

**Status:** Built. Full width under the Library pane and popping out as
the Timeline window (2026-09-25, `spec/panekit.md` "The order" step 5);
its height, both halves (2026-09-26), measured rather than added up
(2026-09-27). **Open work:** see `spec/backlog.md` (B-01 the popped-out
Timeline window losing its content, B-28 scrub audio and the drawers'
controls, B-66 scrolling a partly covered Timeline window). Hands-on:
`spec/shakedown.md`, "Timeline height" and "The timeline full width".

How every drawer *feels* under the hand (the clutch) is
`spec/panekit.md`, "The clutch". Moved out of `spec/windows.md` on
2026-09-28, word for word. Names follow `spec/anatomy.md`.

## What it is

**The timeline pane** (Jason first called it the edit zone) is the unit
that holds the rows: the transport, the ruler and the rows under it.
Final Cut, Premiere and Resolve all call this the timeline. It's the
thing that could be a tool window of its own, the Timeline window. The
transport goes with it, since zoom, snapping and the range belong with
the rows wherever they are.

## Its height

**Its height (Jason, 2026-09-26) — built, both halves, 2026-09-26.** Docked or in its own window, the
timeline is **only as tall as its contents** — the transport, the ruler
and the rows — **or smaller**; it can't be dragged taller. **Smaller than
its contents, the rows scroll up and down as normal**, docked or in a
window. **The one exception** is the Timeline window behind another
window, whose padding lets it grow past its contents while covered:
`spec/windows.md`, "Scrolling a window that's partly covered" (Jason restated it
2026-09-26: the padding stays when the window comes to the front, "so as
not to make the tools jump", until it's scrolled back into place).

**Measured, not added up (2026-09-27).** Row heights will be a preference
(Jason), so the pane's content height comes from what's drawn: the play
bar and the storyline each measure themselves (`transportHeight`,
`StorylineView.onNaturalHeight` — the ruler and the rows' unclipped stack,
plus a 12 pt breather clear of the window's rounded corners), and so does
the empty timeline shown with no show open (`TimelinePanePlaceholder`),
which also means the pane can't be dragged past its content there. The
fixed figures (`contentHeight`, `fullHeight`) are only a first guess before
anything's drawn. Proved by making one row 40 pt taller with the fixed sum
pinned at its old value: the pane grew by exactly 40.

**When the contents grow** (a row's drawer opens, a preference makes the
rows taller, a row is added) — Jason: "to a point", never squashing the
viewer. **Agreed 2026-09-26:** while it shows all its contents it grows
with them, up to a ceiling — the viewer keeps about half the window, or
its own minimum, whichever is more — then the rows scroll; dragged
smaller than its contents, it keeps its size and scrolls. **A new row
lands at or near the bottom and is scrolled fully into view** (unless
the window is shorter than the row).

**Built 2026-09-26, the ceiling first, the floor the same day:** the
ceiling as a general PaneKit mechanism, not a RhythmIO-only patch
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
didn't exist (`spec/windows.md`, "Scrolling a window that's partly covered," already
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
library, `rhythmio-testing`'s rules throughout — Jason's real
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

*Built since as PaneKit's edge handles (`spec/panekit.md`); "From the
code" below describes the app before it.*

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
- **With the panels** (`spec/windows.md`), that makes a single-window
  layout and a many-window layout, from the same panes.

## The drawers: the timeline pane's left edge

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
