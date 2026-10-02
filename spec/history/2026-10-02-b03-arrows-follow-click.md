# 2026-10-02 — B-03: the arrows follow the last click; ⇧-arrow in the grid

Jason asked for B-03 and, alongside, why ⇧-arrow "to select more items"
had stopped working in the grids.

**Asked first** (2026-10-02): before any click in Edit Show the
**timeline** has the arrows (Final Cut's active area); you tell which
area has them **the Mac way**, its selection in the accent colour and
the others grey. The grid problem was ⇧-arrow.

**The grid's ⇧-arrow: two bugs, neither reproducible with single
synthetic presses** (axtool's ⇧→ worked every time).
- `SingleKeys` swallowed every auto-repeat, arrows included, so a held
  Space wouldn't flicker play and pause. A held ⇧→ added one tile; a
  held → moved one. Arrows now repeat (`01e3e59`); checked with a small
  CGEvent tool posting a press plus three repeats: 5 tiles selected.
- `GridSelection.step` started from the caller's cursor. Anything that
  sets the selection without the arrows (⌘A, Show in Library, Show
  Similar, Select Group, the dev hook) left it empty or stale, so →
  jumped to the first item or ⇧-arrow extended from an old tile. Found
  in the timeline: → went from slide 2 to slide 1. It now starts from
  the selection when the cursor isn't in it (`cba86f7`, three tests).

**B-03** (`4753229`). `KeyboardArea`: one click monitor, per window, the
nearest PaneKit pane of library / list / preview / inspector / main /
storyline / detail. The timeline's `SingleKeys` stands aside on the
arrows once a sidebar, browser, viewer, inspector or slide-list click is
recorded. Selections in the timeline and the Library grid take
`Color.selection`, grey while their area doesn't have the arrows.

**A trap found on the way.** `NSView.hitTest` takes a point in the
view's *superview's* coordinates. Converting to the content view's own
(flipped) coordinates mirrored the click top to bottom: a timeline click
read as the viewer's picture. A probe printing the hit view's chain of
pane ids found it in one run. `ListEmptySpace` and `ClickTakesKeyboard`
do the same conversion: B-84.

**Checked in a test copy** (axtool, screenshots): → before any click
moves the timeline; a browser click then ↓ moves the browser; a timeline
click takes them back (blue); a viewer click greys the timeline's
selection and → leaves it; a tile click makes the tiles blue and the
sidebar grey, a sidebar click swaps them; in the popped-out Timeline
window → reaches the timeline (the playhead nudged). There, a click on a
slide didn't select it (B-83, maybe synthetic).

**Interruptions.** Jason was using the Mac part way through ("that was
probably me"); the hands-on paused until he said it was free.
