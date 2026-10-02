# The viewer drawer

**Status:** Built 2026-09-26, all four steps; the switch's own strip
reversed 2026-09-27. **Open work:** see `spec/backlog.md` (B-33 a group's
↑ / ↓, B-53 its name, B-55 the cap of 12 and a click in the viewer).
Hands-on: `spec/shakedown.md`, "Viewer drawer".

Moved out of `spec/plan.md` on 2026-09-28, word for word. (Its heading
there still said "Planned".)

## The design (Jason, 2026-09-26)

A viewer of the selected file(s), in a drawer at the top of the grids:
see a picture big without leaving the grid, and compare picks side by
side. Asked 2026-09-25; decided with Jason by Q&A 2026-09-26.

**Where:** the Library grid, the library panel's grid, and Edit Show's
browser (Jason: all three). Each remembers its own open/closed state and
height, the way the two grids keep their own tile sizes.

**The dark strip under the bar is the handle** (Jason). The drawer opens
*above* the bar each place already has (the grid's search/filter/tools
bar, the browser's search/filter bar). Under that bar is a dark strip
with the edge handles' pill in its middle — the grids' sort strip, or in
the browser a slim 12-pt grip strip of its own — and it is the drawer's
**only** handle: drag it down to open the viewer and set its height (the
bar moves with it), drag it up to close it, double-click it to open or
close. The bar itself takes no drags: it's full of controls. **Y**
(Aperture's Viewer key, kept for this) and View ▸ Show Viewer do the same
as a double-click, in whichever of the three has the keyboard. It doesn't
switch sides: the bar and the strip stay on top of the grid.

*How it got here, the same day:* first the bar's empty space was the
handle (Jason's first call), then the sort strip was added as a second
one when he took it for the grip, then the bar was dropped as a handle
("there are elements above it that require mouse clicks").

**What it shows** (Jason):
- **Several selected: all of them, side by side** (Aperture's multi-up,
  Lightroom's Survey), tiled as large as the drawer allows, the one last
  clicked outlined. Proposed cap: 12 at once, with a "+N more" note past
  that — ⌘A on thousands of files shouldn't try to draw them all.
- **Or a stack** (Jason, added the same day): the outlined file big, as
  if one were selected, with the rest as cards stacked behind it and a
  count — keeps the image big while showing it's a group. The two are
  **Side by Side** and **Stack**, switched three ways (Jason): a small
  two-way switch in the drawer's corner, **⇧Y**, and View ▸ Viewer ▸
  Side by Side / Stack. Each place remembers its choice.
- **← / → step within the selection** (Jason, Aperture's multi-up) while
  the viewer is open with several selected: the selection stays, and the
  outlined file — the stack's top card — moves to the next or previous
  selected one, wrapping. With the viewer closed, or one file selected,
  arrows work as today (↑ ↓ too: they still move the grid).
- **Video and animated GIFs play, muted, looping**, as they'll move in a
  show without surprising anyone with sound.
- **Nothing selected: a quiet "No selection" note**, centred, like the
  empty inspector's.
- Audio files: their name and a speaker symbol (they aren't pictures).

**The grid keeps the keyboard** while the viewer is open: rating
keys, ⌘A, Delete, Return all still work on the grid, and the viewer
follows. The viewer takes no clicks of its own in v1 (a click could later
make a tile the outlined one, or double-click to the Slide Editor).

**PaneKit gains "a view as the handle"** — reusable, not RhythmIO's. A
split can say its handle is the app's own view (`handle: .external`):
closed, it takes no room (no 12 pt edge handle, no divider line), and
the app marks a view with `.paneHandle(controller, split:)`, which turns
a drag on it into the same `dragResize` a divider drag makes and a
double-click into open/close. Switching sides is off for such a split.
Tests in `PaneControllerTests` (closed size 0; drag opens and sizes;
double-click toggles); a harness check with a header-bar-shaped view.

**Steps:**
1. PaneKit: `handle: .external` and `.paneHandle` — tests and harness.
   **Built 2026-09-26**, checked by Jason in the harness
   (`spec/panekit.md`, "The app's own view as the handle").
2. The viewer itself, `SelectionViewer`: Side by Side (the multi-up
   layout, pure, tested in Core: N aspect ratios into a W×H box → tile
   frames) and Stack, the corner switch, images decoded at
   the tile's pixel size off the main thread and cached, GIFs and video
   playing muted and looping, the "No selection" note, the cap.
   **Built 2026-09-26** (`Viewer.swift` in Core, 11 `ViewerTests`;
   `SelectionViewer.swift`) — not on screen until step 3 wires it in.
3. The Library grid (main window and panel): the split, the bar as
   handle, Y, ⇧Y and the View menu items, ← / → within the selection.
   **Built 2026-09-26.** `ViewerLayout`/`ViewerPlace` (`ShowColumns.swift`),
   one controller per place on `AppModel` (closed the first time), View ▸
   Viewer (Show Viewer, Side by Side / Stack) acting on the active place.
   Checked with axtool on a scratch library, screenshots each: Y opens it
   over one file; three side by side with the last clicked outlined, the
   video playing and looping; → steps the outline and wraps, all three
   still selected; ⇧Y to Stack (saved); → changes the top card; typing
   "y" in Search types; a 100-pt bar drag moves the bar 100; double-clicks
   close and reopen at the last size; both menu items; the library panel's
   drawer opens on its own, the main one unmoved. Two fixes found on
   screen: the switch sat over the last picture's corner (it has its own
   strip now), and plain grey stack cards were invisible on the dark
   backdrop (they're the next pictures now, dimmed, with a light edge).
4. Edit Show's browser: the same, following its picked files and uses.
   **Built 2026-09-26.** The outlined file is the pick added last. Y and
   ⇧Y work anywhere in Edit Show but a text field (nothing else there
   uses them); ← / → step the outline only while the list has the
   keyboard, since elsewhere they're the timeline's. Checked with axtool:
   Y opens it over one pick; ⌘-click adds a second, side by side, the
   last outlined; with the list given the keyboard (Tab), → steps the
   outline with both still picked, and "4" still rates both — so the
   list's focus, now inside the drawer's own hosting view, still works.
   **The viewer drawer is built, all four steps.**

**The switch's own strip, reversed (Jason, 2026-09-27).** Step 3 above
gave the Side by Side / Stack switch its own reserved row so it would
never sit over a picture's corner — but that row shrinks every picture in
the drawer to keep space clear for it, all the time, for a switch that's
rarely even looked at. Jason: it doesn't need to be a hard bar; the icons
can just float where they are and cover a picture if it reaches that far.
`SelectionViewer.body` dropped the outer `VStack` (the reserved strip)
for a `ZStack(alignment: .topTrailing)`: the switch floats over the
content instead of pushing it down, and `box` (the frame `Viewer.sideBySide`
and the stack lay out into) now gets the drawer's *full* height, not the
height left over after the strip. Covering a picture's corner is accepted
now, not a bug to fix.

**The bar carries the grid's tools** (Jason, 2026-09-26, after the drawer
was built): the tile-size slider, then Import, Add to Show and Get Info,
moved down from the toolbar into the bar under the drawer — the Library
view has no toolbar items now, so its title bar is the plain one. Where
the bar doesn't fit on one row (the library panel), it takes two: search
with Filter, Sort and Similar as icons, then the tools under them
(`ViewThatFits`).

**The strip's text ignores the mouse** ("Date Added, Oldest First"):
SwiftUI's text took the clicks, so a double-click on it did nothing
(measured) while the empty middle worked.

**Open:** the cap of 12 (proposed); whether a click in the viewer should
