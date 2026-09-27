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

## What's left of "Its height"

Vertical row-scrolling in `StorylineView`, as its own piece — then the
floor can come down off full content, and "a new row lands at or near
the bottom, scrolled into view" becomes meaningful. Tracked in
`spec/status.md`'s "What's next," item 1.

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
