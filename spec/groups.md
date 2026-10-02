# Groups inside collections

**Status:** Built 2026-09-24, Core through UI; the icons 2026-09-25;
reordering 2026-09-25 (items 17/38); the browser's switcher 2026-09-26
(item 38). **Open work:** see `spec/backlog.md` (B-46 promotion and the
group's fuller menu, B-34 the "Other Collections" switcher, B-58 the
ReorderKit lift). Hands-on: `spec/shakedown.md`, "Groups in the Library
pane".

Moved out of `spec/plan.md` on 2026-09-28, word for word.

## The design (Jason, 2026-09-24)

A collection gets **groups**: sub-folders of its files, so a big
collection can be organised without splitting it into several
collections. Being designed now, then built by the Mac session.

*What exists today (from the code):*
- Collections are flat: `collections` (id, name, created_at) and
  `collection_items` (collection, item, added_at). A file can be in
  several collections.
- Every show belongs to one collection (`shows.collection_id`) and draws
  its pictures from it.
- The library is at **schema version 12**. Groups need new tables, so
  they're **migration 13**: additive, `Library.schemaVersion` raised to
  13, and tested by opening a version-12 library (CLAUDE.md).
- **A name clash:** the grid's **Group Similar** already calls its
  look-alike sets "groups". One of the two needs another name.

**Decided (Jason, 2026-09-24):**
- **What a group is: a book cart.** Something you load up for now, more
  temporary than a collection. Deleting a group leaves its files in the
  collection, and in every show that uses them.
- **Membership:** a group's files must be in its collection. A file can
  be in several groups.
- **Nesting:** groups hold groups, like folders.
- **In the Library pane:** a collection opens to show its **groups and its
  shows side by side**, as siblings. Shows don't live inside groups, and
  aren't limited by them. Files can be dragged onto a group there.
- **Order:** creation order by default, with a choice of alphabetical and
  others (size, length).
- **Using a group:**
  - **A show can draw from a group:** the browser (the collection's files,
    in Edit Show) gets a **drop-down in its title** to filter by group.
  - **A Quick Show's pool** can be a group.
- **The name clash:** Group Similar becomes **Find Similar Images**
  (Jason's leaning), so "group" means only this.
- **Keep as Group:** a set found by Find Similar Images can be kept as a
  group from its header. Jason's example: the similar pictures are all so
  good he can't choose yet, so they go in a group for later. Once he's
  decided, he keeps one and deletes the group.

**A proposal for the build** (Claude; the Mac session confirms it against
the code):
- **Migration 13:**
  - `groups` (id, collection_id → collections ON DELETE CASCADE,
    parent_id → groups ON DELETE CASCADE, null at the top; name,
    created_at);
  - `group_items` (group_id → groups ON DELETE CASCADE, item_id → items
    ON DELETE CASCADE, added_at; primary key group and item).
  - `Library.schemaVersion` to 13, and a test that opens a version-12
    library.
- **Keeping the membership rule:** taking a file out of a collection also
  takes it out of that collection's groups, in the same transaction.
- **Shows and groups need no schema.** A show still belongs to its
  collection, and the browser's group filter is view state, remembered
  with the show's editing state.
- **Undo** for creating, renaming, deleting and filling groups, like
  collections.
- **Order:** the sort choice is a view setting, not stored per group.

- **Deleting a group that holds groups** (Jason): its sub-groups go with
  it, as in Finder. The confirmation says how many groups will be
  deleted ("This also deletes 3 groups inside it. The files stay in the
  collection."), and has a **Do not show this message again** checkbox,
  as the slide-removal notice does. Files are never deleted with a group.
- **Keep as Group with no collection open** (the Library view; Jason): a
  dialog explains that a group lives in a collection, so saving this one
  needs a collection first. It offers to create one, with **Grouped
  Collection** suggested as its name. After that, the usual naming step
  for the group follows. (In a collection, the group simply goes in the
  collection being viewed.)

**Built 2026-09-24 (Core):** migration 13 (`groups`, `group_items`),
`MediaGroup`, and on `Library`: `allGroups`, `createGroup`, `renameGroup`,
`deleteGroup`, `addItems(_:toGroup:)` (enforces the membership rule at the
SQL level — a file not in the group's collection is silently left out),
`removeItems(_:fromGroup:)` / `restoreItems(_:toGroup:)` for undo,
`snapshotGroupSubtree`/`restoreGroupSubtree` for deleting a group (its
whole nested subtree, root first) and undoing that. `removeItems(_:fromCollection:)`
now also takes a file out of that collection's groups in the same
transaction and returns both (`CollectionRemoval`), so undo puts both
back (`restoreItems(_:toCollection:)` and the new
`restoreGroupMemberships`) — this changed its return type, so
`AppModel.removeFromCollection` and the tests were updated to match.
`CollectionSnapshot`/`restoreCollection` now carry a collection's groups
too, so deleting and undeleting a collection takes them with it. 267 + 12
core tests → **288** (7 new group tests + 2 from the return-type change's
knock-on).

**Built 2026-09-24 (Library pane UI):** a collection's groups and its
shows, side by side as siblings, each `DisclosureGroup` open by default;
nested groups disclose recursively (`groupRow` returns `AnyView` — a
recursive function can't define its own opaque `some View` in terms of
itself). New Group from a collection's or a group's context menu, or
from the grid's selection (`Add to Group ▸`, alongside `Add to
Collection ▸`); named before it's made, like New Collection (H1).
Rename…, and Delete Group… through `GroupDeleteNotice`
(`SlideInspector.swift`) — an `NSAlert` with the subgroup count, "the
files stay in the collection," and the suppression checkbox Jason asked
for, same convention as `SlideRemovalNotice`. A group's row accepts a
drop (adds to the group; the Library enforces the membership rule).
Selecting a group in the pane filters `LibraryGridView` to its files
(`groupID`, alongside `collectionID`); Delete there takes files out of
the group without asking (as Remove from Collection); ⌘Delete still
moves the files themselves to the Trash. **A group's own right-click
menu is deliberately minimal** (New Group in…, Rename…, Delete Group…)
— the fuller one is still "to settle with groups"
(`spec/conventions.md` §3), so nothing beyond what's unambiguous was
added.

*A SwiftUI type-checker trap, hit repeatedly while building this:* once
`MainView`'s body passed a certain size, the compiler failed with "unable
to type-check this expression in reasonable time" — not on the new code
itself, but on whichever nearby line pushed the whole chained-modifier
expression over its budget, meaning the fix (extracting a sub-expression
into its own function, computed property, or `ViewModifier`) had to be
applied five times, each time moving the error to a new line, before the
file compiled again. `GroupCreationAlert` is a `ViewModifier` for exactly
this reason — its own closures type-check separately from the rest of
`LibraryGridView`'s body. Worth remembering before adding much more to
either view's body: extract early rather than inline.

## The browser filter

**Built 2026-09-24 (the browser filter and Find Similar Images), promoted
into the title itself 2026-09-26 (item 38):** the Edit Show browser's
title gets a group filter drop-down (the collection's own name or one of
its groups; hidden when the collection has none), restricting both the
"In this show" and "Not in this show" sections to the group's members.
First built as a separate folder-icon control beside the plain title;
2026-09-26 (status's "What's next" of the day, now
`spec/history/2026-09-28-status-archive.md`, "the browser's header as a
switcher," item 38) folded it into the title itself — a click shows which
list the browser is showing (the collection or a group) and switches
among them, rather than a name and a filter control side by side
(`CollectionBrowser.collectionSwitcher`). First scoped with Jason to the
show's own collection and its groups; the wider collection-to-collection
switch built the same day, once he'd settled the design question it
raised (below). The choice lives in `ShowEditorState.
browserGroupID` — new field, additive decode like every other field in
that struct — ignored if it names a group from a different collection
than the show now has (its own collection changed since it was set,
rather than crashing or showing the wrong group). Set through
`engine.updateEditor`, so — like the range, loop and line toggles it
sits beside — it's saved but never an undo step.

**Built 2026-09-26, the wider switch:** the header's menu now lists every
other collection in the library too, under "Other Collections"
(`CollectionBrowser.collectionSwitcher`). Before building it, asked
Jason the question `spec/windows.md`'s "What's known" left open: does
picking a different collection there **rebind** the show
(`Show.collectionID`, a real undoable edit) or just **change what the
browser lists**, leaving the show's own collection untouched? He chose
the second — a transient view choice, exactly like the group filter, not
an edit to the show at all. `ShowEditorState.browserCollectionID`
(additive, nil meaning the show's own collection) carries it, same
persistence rules as `browserGroupID` (saved with the show, no undo
step); `CollectionBrowser.browsingCollection` is the collection actually
listed (the show's own, or the picked one), and `usedEntries`/
`unusedFiles` and `groupFilter` all read it instead of `collection`
(the show's own, kept as its own property for whatever still needs that
specific meaning). Browsing a collection other than the show's own
narrows "In this show" to whichever of the show's real uses happen to
also sit in that collection — usually none, since a show's slides
normally all come from its own collection; that's the honest
consequence of "In this show" meaning uses, not membership, once the two
collections can differ. Checked with axtool against a scratch library
seeded with a second collection sharing two files with the show: the
switcher lists it under "Other Collections," picking it relabels the
header and narrows "In this show" to exactly those two files, and
switching back to the show's own collection restores the full list —
the sidebar's own collection membership never moved. Not confirmed by a
real click.

The name clash is fully resolved: "Group Similar" is "**Find Similar
Images**" everywhere user-facing (the toolbar button's tooltip; doc
comments updated so "group" means only a `MediaGroup` in this file).
Its set header carries the settled context menu in full — Select Group,
Keep One… (already built), **Keep as Group**, New Show from Group…, Add
Group to Collection — added alongside the existing inline Keep One…
button rather than replacing it. Keep as Group goes straight to naming
the group when a collection is open; with none open (the Library view)
a new `GroupedCollectionAlert` walks through Jason's decided flow —
explain, offer "Grouped Collection" as a name, create it, then the
ordinary New Group naming step. Both new alerts are their own
`ViewModifier`s (`GroupCreationAlert`, `GroupedCollectionAlert`) for the
type-checker reason above.

**Groups inside collections is now fully built**, Core through UI, matching
everything Jason decided 2026-09-24.

**Icons, settled 2026-09-25 (item 12, feedback worklist):** a collection
gets the solid folder (`folder.fill`); a group keeps the outline
(`folder`) it already had. **Built**: `collectionRow` in `MainView.swift`
now uses `folder.fill` (was `rectangle.stack`); `groupRow`'s `folder` was
already right. The collapsible groups-and-shows list in the Library pane
Jason had in mind (above, "The design": "the Library pane: a collection
opens to show its groups and its shows side by side") was already built
2026-09-24 — the icon was the only piece missing.

## Promotion

**Promotion — a group becomes its own collection (Jason, 2026-09-25):**
an idea, not yet designed or built. Needs answers before it's built: does
the original group survive (emptied, or deleted) once promoted; do a
promoted group's own nested sub-groups come along as the new collection's
groups; and where the command lives (the group's context menu, presumably,
alongside New Group in…/Rename…/Delete Group…, which today is
deliberately minimal — "the fuller one is still 'to settle with
groups'"). Worth settling together with that fuller group context menu.

## Reordering

**Reordering — items 17/38 (feedback worklist). Built 2026-09-25**, and
tried by Jason's own hand. How it got here, including a first design that
didn't work by hand: `spec/history/2026-09-25-drag-reorder-session.md`
(the first attempt) and `spec/history/2026-09-25-drag-reorder-rebuild.md`
(the rebuild). Next: lift it into its own package, like PaneKit
(ReorderKit), for use in other apps.

**Where it works.** Inside a collection or a group only: they carry a
drag order (`sort_key`, migration 14, kept apart from `added_at` so Date
Added never changes). The plain Library has no order of its own, and Show
Similar is its own arrangement, so a drag over either shows a note saying
why and changes nothing. Letting go over the plain Library's grid also
shows `LibraryOrderNotice` (Jason's wording: "You cannot set a custom
order in the Library." / "Collections and Groups support custom
ordering.", OK, "Don't show this again"), once the files are put back —
never for Escape, which lets go of nothing. The wording is RhythmIO's; a
package would only report that a drag was refused where it was let go.

**What a drop saves.** Exactly what's on screen. Dragging under another
sort makes Custom Order that sort with the move in it; files a search or
filter hides keep their places (`Reorder.merge`). The drop switches the
sort to Custom Order, explained once by `CustomOrderNotice` (one button,
"Don't show this again"); the strip under the toolbar names the sort in
use. One "Reorder" undo step per drop, in its own undo group
(`commitReorder`) — without it Edit ▸ Undo stayed disabled until the next
event.

**How it's built.** Core: `Reorder` (`RhythmIOCore/Reorder.swift`,
tested) — the slot under a point, the order shown while dragging, the
merge. View side, kept free of RhythmIO's own types for the package:
`ReorderDrag.swift` (`ReorderDrop`, `TileFramesKey`, `StackDragSource`,
`StackDragAnchor`). The grid (`LibraryGridView`) wires them together.
Three rules found the hard way:
- **One drop handler for the whole grid, slot from geometry.** Never ask
  a tile whether the pointer is over it: the tiles move while dragging,
  and asking them was a feedback loop (tiles sliding back and forth, the
  wrong order saved).
- **Nothing that rebuilds the grid inside a drag's own callbacks.** The
  sort switch, the new order and the cleanup apply together just after
  the drop.
- **One drag picture, drawn by us.** AppKit tilts every picture of a
  multi-item drag, whatever the formation (measured in a harness), so
  the pile is one composed image and the fly-in is drawn by the grid.

**Terms for the effect** (use these names):

| Term | What it is |
|---|---|
| **Pile** | The drag picture: the dragged files as a tidy stack under the pointer, no tilt, the pressed file on top |
| **Card** | One file in the pile. A grid tile's thumbnail, or in list mode a short solid row (thumbnail and name) |
| **Badge** | The red count on the pile's top card, when more than one file is dragged; the real count, however many cards show |
| **Fly-in** | On pickup, the other selected files' cards glide from their own tiles into the pile |
| **Gap** | Empty space at the slot the pile would land in, the size of the selection; follows the pointer |
| **Landing** | On drop, the files spring out from where the pile was into the gap, and stay selected |
| **Put-back** | A drag nothing takes (Escape, a refused drop, let go nowhere): the pile comes apart where it was let go and each card flies to its own file's tile while the gap closes — the landing in reverse. No message for Escape |
| **Edge zone** | A band inside the grid's top and bottom edges where holding the drag scrolls the grid |
| **Ramp** | How far into the edge zone the pointer is: 0 where the zone starts, 1 at the edge. Drives the scroll speed and the shrink together |
| **Handful** | The small size the pile shrinks to at the edge — what macOS itself shrinks a drag picture to over the header bar or a closed pane |
| **Overshoot** | How far past the edge the pointer can go and still scroll; beyond it, scrolling stops so drops beyond (the timeline) stay reachable |

**The dials** (all in `ReorderDrag.swift` unless noted; the values Jason
approved 2026-09-25):

| Dial | Value | What it changes |
|---|---|---|
| `StackDragSource.pileDepth` | 5 | Most cards the pile shows ("if more than X, just use a stack of 5") |
| `StackDragSource.pileSpread` / `pileStep(layers:)` | 18pt; step at most 6pt | How far each card sits from the one above; shrinks as the pile grows, so every pile is about the same size |
| `StackDragSource.badgeRoom(count:)` | 11pt | Room above the top card for the badge |
| `StackDragSource.handful` | 200 × 130pt | The box the pile shrinks to fit at the edge (never enlarged). Measured: macOS made a 363pt grid pile ~121pt wide and a 320×34 list card ~199×20 over the header |
| Edge zone depth (`edgeScrollTick`, `zone`) | the pile's overhang past the pointer + 16pt, at least 48pt, at most 30% of the grid's visible height | Where scrolling and shrinking start |
| `StackDragSource.edgeMinSpeed` / `edgeMaxSpeed` | 30 / 2800 pt/s | Scroll speed at the zone's start and at the edge |
| Speed curve (`edgeScrollTick`) | ramp³ | Steepness: a crawl through most of the zone, fast only near the edge ("the speed needs to ramp as you near the edge") |
| Shrink curve (`edgeScrollTick`) | linear in the ramp | Full size at the zone's start to handful at the edge |
| `StackDragSource.edgeOvershoot` | 30pt | See Overshoot |
| Fly-in (`startDrag(from:)`, `MainView.swift`) | 0.2s ease-out | How long cards take to reach the pile |
| Landing (`commitReorder(at:)`, `MainView.swift`) | spring, response 0.35, damping 0.82 | How the files spring into the gap |
| Put-back (`putBack`, `MainView.swift`) | 0.28s ease-in-out | How fast cards fly home after a drag nothing took |
| Gap reflow (`gridContent`, `MainView.swift`) | 0.2s ease-in-out | How fast tiles slide aside for the gap |
| List card (`startDrag(from:)`) | at most 320pt wide, kept 40pt inside the pointer | The list-mode card's size and where it rides |
| Drag start (`tile(_:)`) | 4pt | How far the pointer moves before a press becomes a drag |

**The sort strip names the sort in use** (`effectiveSort`): the sort is
shared by every grid, and in the plain Library, which has no order of its
own, Custom Order reads as Date Added, Oldest First — strip and Sort menu
alike.

## Nesting by drag

**Built 2026-09-24 (nesting by drag, and dragging into another
collection):** `Library.moveGroup(id:toParent:)` — nests a group inside
another, or (nil) back to the top; both stay in the same collection (a
group's `collection_id` never changes). Refuses, by throwing, a move
that would make a group its own descendant (walks up from the wanted
parent checking for the group itself) or that crosses collections.
`AppModel.moveGroup` wraps it with undo, like `renameGroup`; the UI
catches the thrown refusal and does nothing rather than surface it —
the drop shouldn't have been offered in the first place if it wasn't
going to work, so there's nothing to tell the user beyond the drop
simply not doing anything.

A group's row is now draggable (`GroupDrag`, `CollectionAdd.swift`, the
same pattern as `ItemDrag` but carrying one group id) and accepts drops
of both kinds: a file joins the group as before, another group nests
inside it. Dropped on a collection row instead: its own collection,
the drop un-nests it to the top (Finder's "drag a folder out to the
window" move, no confirmation — nothing crosses collections); a
different collection, **the group can't move there, so this adds the
group's own files to that collection instead**, after asking
(`GroupToCollectionNotice`, `CollectionAdd.swift`, the same
suppression convention as `CollectionAddNotice` and
`GroupDeleteNotice` — exactly Jason's ask, 2026-09-24: "if the latter,
dialog with a don't-show-again option saying the images in this group
will be added to the destination collection").

Three new Core tests (nest and un-nest; refuses a cycle at every depth;
refuses a different collection) — 279 core, 291 total (was 288).
`swift test` and `./make-app.sh` clean; smoke-launched again, no crash.
Real dragging (a group onto a group, onto its own collection, onto
another) still wants Jason's hands — this was built and reasoned about,
not clicked.
