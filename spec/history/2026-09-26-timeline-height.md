# 2026-09-26 (later) — the timeline's ceiling, the browser's header

A dated record. Current rules and state are elsewhere: `spec/windows.md`
("Its height"), `spec/panekit.md` ("What every pane can do"),
`spec/plan.md` ("the browser filter").

Jason asked to work through the open list in order: timeline height,
the browser's header as a switcher, then the windows pass.

## Scoping

`spec/windows.md`'s "Its height" (agreed 2026-09-26, not built) asks for
two things at once: a ceiling (can't be dragged taller than its content,
growing with it up to "the viewer keeps about half the window") and a
floor (dragged smaller than its content, the rows scroll). Building
either meant changing PaneKit's `Split`, which is shared and meant to be
reused in other apps — checked with Jason first, per CLAUDE.md's own rule
to harness-test layout changes rather than guess: build it as a general
PaneKit capability (`ContentTracking`), proven by arithmetic tests, not a
ShowTools-only patch.

Reading `StorylineView` turned up a second fork before any code: it has
no vertical scrolling today, only horizontal (its own doc comment already
said so, under "Scrolling a window that's partly covered" — "vertical
scrolling arrives with extra rows, and so does this"). Without it, a
floor below the pane's full content would just clip a row invisibly.
Asked Jason: build vertical row-scrolling too (bigger, touches the
ruler/drag-reorder/markers/frame-strip), or ship the ceiling half now and
leave the floor at full content until scrolling exists as its own piece.
He chose the ceiling only.

## What was built

`PaneKit/Sources/PaneKit/PaneModel.swift`: `ContentTracking` and
`Split.contentTracking`. `PaneLayout.sizedExtent`: a content-tracking
split's `wanted` is the live `contentExtent[split.id]` (not
`defaultSize`) when nothing's stored, and its ceiling is `available`
minus the main side's own minimum or `mainReserveFraction` of `available`
— whichever reserves more. `PaneController.setContentExtent`: how an app
reports a content-tracking split's live content height, never saved
(same shape as `peek`). Threaded through `PaneContainerView`'s layout
pass and `trackResize`'s starting extent.

Five new arithmetic tests in `PaneLayoutTests` pinned the whole contract
before touching the app: no stored size tracks content exactly; content
taller than the ceiling stops there; a stored size ignores content
growing past it; a stored size above a shrunk ceiling gets clamped down
too; no measurement yet falls back to `defaultSize`. `swift test`: 46 →
51 PaneKit tests, all passing, no regressions.

`AppModel.mainPanes`'s outer `"window"` split took `contentTracking:
ContentTracking()`, its floor and default both set to a new
`EditShowTimelinePane.contentHeight` (the transport bar, its divider, and
`StorylineView.fullHeight` — always the real content, since
`TimelineRow.normalized` keeps every show's `rows` at all four kinds, so
this is a genuine constant today, not yet exercising the "content grows"
half of the mechanism). `EditShowTimelinePane` reports it once, on
appear. The old static range's `+400` of slack above the floor —
draggable, but pointless, since nothing needed the extra room — is gone;
dragging the divider now stops dead at the content's own height.

`swift build` clean (pre-existing Sendable warnings only, untouched),
`swift test`: 336 core tests unchanged. A scratch-library launch
(`tools/make-test-library.sh`) rendered identically to before — timeline,
rows, transport all in their usual places. Not confirmed by a real drag
of the divider itself; the arithmetic and the unchanged render are what's
checked. Closed the test copy cleanly (`kill`, not `-9`) and confirmed
`runningTestLaunches` came back empty (`showtools-testing`).

## "Its height," the floor: vertical row-scrolling (same day, later)

Jason: finish the leftovers from the first two things before starting
the windows pass. Three were named: vertical row-scrolling (the timeline
height floor), scrolling a newly-added row into view, and the wider
browser collection switch. Built the first two together; the third
needs a design answer first (below).

`StorylineView`'s rows (images, transitions, slides, music — one `ZStack`,
absolute-positioned by `rowTop(kind)`) had never scrolled vertically,
only horizontally with the timeline's own clock. Before touching it,
traced every risk by reading the code rather than guessing:
- **Coordinate spaces:** block drag/reorder, trim, markers and scrub all
  use `DragGesture(coordinateSpace: .named("storyline"))`, declared on
  the VStack wrapping both the ruler and the rows. SwiftUI's named spaces
  report position in a view's own *unscrolled* content frame — the same
  reason the existing horizontal scroll never broke these gestures — so
  nesting a second, vertical `ScrollView` around just the rows (not that
  VStack) doesn't change what any gesture measures.
- **`rowHandles`:** pinned outside the horizontal scroll on purpose (so
  it never travels sideways with the timeline). Once rows can scroll
  vertically inside their own nested `ScrollView`, this handle overlay —
  still outside that scroll entirely — needed to start following its
  offset by hand, or the handles would drift out of alignment with their
  rows the moment someone scrolled. Solved with the same preference-key
  pattern the horizontal scroll already used for the frame strip
  (`StorylineScrollKey` → `RowsScrollKey`), then an `.offset` + `.frame`
  + `.clipped()` stack on `rowHandles` itself.
- **The playhead and marker lines:** overlays on the same outer VStack,
  outside the new inner scroll — reasoned that they don't need to track
  vertical scroll at all (a time-marker line just needs to span whatever
  rows are currently visible, which the VStack's own measured height,
  now capped at the viewport, already gives it for free). Left untouched.
- **`ScrollViewReader.scrollTo` across the nest:** the existing horizontal
  `proxy.scrollTo` (playback auto-scroll, Go Back/Forward) targets ids
  that would now sit two scroll levels deep. SwiftUI's anchor-preference
  mechanism for `scrollTo` bubbles through nested containers regardless
  of axis, so this was assessed as safe without a full harness — the
  same reasoning extended to a *new* inner `ScrollViewReader` for the
  rows themselves.

Built: `StorylineView.rowsScrollView` (`ScrollViewReader` +
`ScrollView(.vertical)`, sized to `rowsViewportHeight` — exactly
`rowsHeight` until the pane's given less room) wraps the existing rows
content, extracted unchanged into `rowsZStack`, plus one addition: an
invisible 1×1 anchor per row kind, purely so `scrollTo(kind)` has
somewhere to land. `EditShowTimelinePane.minContentHeight` (transport +
divider + ruler + one row) replaced `contentHeight` as the pane's floor
in `AppModel.mainPanes`. `rowDragGesture`'s `onEnded` now sets
`pendingRowScroll` after a successful move, scrolled into view by a new
`onChange` inside `rowsScrollView` — the same one-shot pattern
`session.pendingScroll` already used for the horizontal scroll. This
also covers "a new row lands... scrolled into view" for whenever a row
can be added, which nothing does today (`TimelineRow.normalized` keeps
every show at all four kinds) — reasoned through, not exercised.

**Checked:** `swift build` clean, `swift test` unchanged (336 core, 51
PaneKit). A scratch-library launch at the default size rendered
identically to before (same screenshot, pixel for pixel by eye). Shrunk
well below full content by writing a 200-pt stored size directly into
the scratch library's shared preferences (`showtools-testing`'s rules
throughout: Jason's real `com.jhg.showtools` domain backed up with
`defaults export` before any of this, restored with `defaults import`
after, diffed to confirm — the diff came back clean except a stale
`runningTestLaunches` entry that predated this session, cleared as a
bonus): the pane showed only the ruler and the rows that fit (images,
slides), cut cleanly at its own edge, no overlap or corruption.

**Not confirmed:** the divider drag itself (see below), a real two-finger
scroll revealing the hidden rows, `rowHandles` visibly tracking that
scroll, and a row-reorder drag's `pendingRowScroll` actually landing.
Coordinate-guessing against the tiny, densely-packed pane (axtool's
`dump` doesn't expose PaneKit's custom divider views by role, so their
screen position had to be inferred rather than read directly) proved too
unreliable to trust this session — several attempts hit nothing, and one
scroll attempt showed an unexpected, larger layout that looked like the
unrelated frame-strip drawer, not reproduced and left no trace in
`PaneKit.main`'s saved state, so nothing was actually changed by it. All
of this is flagged in `spec/status.md`, "Still needs Jason's hands,"
rather than claimed as verified.

## Item C: the wider browser collection switch — built

The third leftover, extending the browser header's switcher (item 38,
already built to the show's own collection and its groups) to every
collection in the library, needed a real decision first: does picking a
different collection there change `show.collectionID` — a real,
undoable edit to which collection the show belongs to — or is it a
transient, view-only filter that doesn't touch the show at all?
`spec/anatomy.md` defines the Browser as "the show's collection, uses
first," which the second reading complicates. Asked Jason rather than
guess: he chose the transient filter, exactly like the existing group
filter.

Built: `ShowEditorState.browserCollectionID` (additive, nil meaning the
show's own collection — same persistence as `browserGroupID`, saved with
the show, no undo step); `CollectionBrowser.browsingCollection` reads it,
falling back to the show's own if the picked collection's gone. Every
place that filtered by `collection` (the show's own — kept as its own
property, since it's still what the browser's *default* and the group
filter's own collection-mismatch guard need) now reads
`browsingCollection` instead: `usedEntries`, `unusedFiles`, `groupFilter`,
and the header's own menu (now listing the browsed collection's groups,
plus every other collection under "Other Collections"). Browsing a
collection other than the show's own narrows "In this show" to the
intersection of the show's real uses and that collection's membership —
usually empty, since a show's slides normally all come from its own
collection; flagged in `spec/status.md` as worth Jason's own read, since
the alternative (always show the real uses regardless of what's browsed)
wasn't asked about specifically.

**Checked** with axtool against the same scratch library, a second
collection seeded (`sqlite3`, two files shared with the show, app quit
first): the header's menu lists "Second Collection" under "Other
Collections"; picking it relabels the header, updates the count, and
narrows "In this show" to exactly the two shared files; picking "Untitled
Collection" back restores the full list. The sidebar's own collection
membership never moved throughout — confirming the transient reading
holds. `swift build` clean, `swift test`: 336 core tests unchanged.
Test copies quit cleanly each time; `com.jhg.showtools` backed up before
and diffed clean after, both sessions (the second run's backup also
caught and cleared a stale `runningTestLaunches` entry from the first).
Not confirmed by a real click.

## Item 38: the browser's header as a switcher

The worklist's own wording ("Collections list column dropdown") pointed
at the Library pane's sidebar; Jason's own later answer (the 2026-09-25
worklist replies, same day) had already narrowed it to "the browser's
header as a dropdown to switch lists" — the Edit Show browser (its
middle column), not the sidebar. Still underspecified on its own (what's
*in* the dropdown), and the browser already had a related, half-built
piece: `groupFilterMenu`, a separate folder-icon control beside the
title that filters to one of the collection's groups (built 2026-09-24,
`spec/plan.md`). Asked Jason directly rather than guess between "every
collection in the library" (a real rebind of what the browser shows) and
"just the show's own collection's groups" (promoting what's already
there into the title). He chose the smaller scope.

`CollectionBrowser.swift`: `groupFilterMenu` (a `Menu` beside a plain
`Text`) became `collectionSwitcher` (the `Menu` itself is the title now,
label showing whichever's current — the collection's name or a group's,
with a folder or stack icon and a chevron); plain text with no menu when
the collection has no groups, same as before. No new state: still
`ShowEditorState.browserGroupID`, unchanged.

Checked with axtool against a scratch library (`sqlite3`-seeded a
"Beach Trip" group with 3 of the test show's files, app quit first, per
`showtools-testing`): the header reads "Untitled Collection ⌄", opening
it lists the collection and the group, clicking "Beach Trip" relabels
the header to "Beach Trip ⌄" with a folder icon and filters both list
sections to its 3 files. `swift build` clean, `swift test`: 336 core
tests unchanged. Test copy quit cleanly (`kill`, not `-9`),
`runningTestLaunches` empty afterward.
