# Slides as mini movies: Edit Slides' Slide viewer and live timeline

**Status:** Building. Steps 1 (live timeline), 2 (looping Play of the
selection, cut to cut) and 3 (the Slide viewer drawer) built 2026-09-26.
**Open work:** see `spec/backlog.md` (B-44 the Slide Editor as the
drawer's pop-out and its revamp, B-45 reordering in the viewer, B-43 the
framework for slides with more inside, B-42 what one slide's loop covers,
B-35 Smart View, B-36 a show from the timeline). Hands-on:
`spec/shakedown.md`, "Edit Slides playing".

Moved out of `spec/plan.md` on 2026-09-28, word for word (Jason,
2026-09-26).

**Steps 1–2 as built:** the show's engine lives while the show is open,
in either mode (`ShowView` owns it; a mode switch pauses it, and leaving
Edit Show closes its player windows). The timeline pane is live in both
modes. Play in Edit Slides loops the selected slides, each cut to cut
(transitions not included, until the framework below says otherwise), in
show order, neighbours joined into one stretch (`ShowTimeline.loopSpans`,
tested; `PlaybackEngine.selectionLoop`, which overrides the range loop
while set); nothing selected plays the show. Checked on a test copy: one
slide looped 0:14 → 0:19; two neighbours played through as one stretch;
two apart alternated; the list and the timeline kept one selection.

**Step 3 as built:** `ViewerPlace.slides`, its own `PaneController`
(`AppModel.slidesViewer`), the drawer above the defaults bar with a
`DrawerGripStrip` under the bar as its handle; **Y** opens and closes it,
View ▸ Show Viewer acts on it in Edit Slides (Side by Side / Stack are
off there: it's one picture). It draws the show's own engine
(`SlideViewer`, a plain `ShowCanvasView`), so it shows exactly what the
timeline plays; picking a slide while paused puts the playhead on it.
Checked on a test copy: Y opens it over photo_02, Space plays it
(Pan and Zoom moving between two screenshots, the clock inside the
slide's stretch).

Came out of item 33 (the greyed timeline). Jason: a slide is **a length
of time in a show**, and inside it more can happen — so a slide is a mini
movie worth watching on its own, and Edit Slides becomes the place to
watch and work on slides one (or a few) at a time.

**Edit Slides' timeline is fully live** — the same as Edit Show's: play,
scrub, select, reorder, trim, drops, markers, keys. It's the same show, so
an edit on the timeline shows in the slide list too. (Step 1 of item 33,
`279680b`, drew it dimmed and inert; that state now only matters for a
timeline left open with no show — the "Smart View" preference below.)

**Pick a slide from the list or on the timeline** — they already share
one selection.

**The Slide viewer** — a drawer over the slide list, **like the viewer
drawer** over the grids (above): the selected slide(s), playing. **The
Slide Editor window is its pop-out** (Jason: "the pop out version of the
Slide viewer drawer"). The Slide Editor also carries the inspector; in
the main window the drawer does **not** — Edit Slides' own inspector
column is already there, so it isn't shown twice.

**Play in Edit Slides loops the selection, not the show.** One slide
selected: that slide, round and round. Several: **all of them, in order**,
looped. Edit Show's Play still plays the show.

**Maybe (Jason):** drag and drop among the selected slides *in the
viewer*, with the list below following — reordering by eye.

**The bigger idea behind it — slides with more inside (new, not
designed):** Jason shoots many portrait photos, and wants to quickly pick
a group of them to sit side by side and fill a landscape frame. Inside the
slide's length, each image can have its own entrance and timing: reveal
the first in the left third, then the second, then the third; or slide
them across for a "groovy 60's montage"; or simply enough images to fill
the screen. That's a timeline *inside* a slide — a new feature, and the
framework for it doesn't exist yet. It's the "multi-panel slides" idea
under the collage maker (Later, below) grown up; the Slide viewer and the
looping Play are the place it would be watched and worked on.

**Left as it is for now:** the Slide Editor — Jason expects to revamp it,
so whether it gets the looping Play waits for that.

## Smart View

**Also from this conversation — "Smart View" (working name, a
preference):** on (the default), panes open and close by context, as
today (the timeline pane closes when no show is open); off, each place
remembers your own open/closed choices instead. **Superseded in part,
2026-09-27:** Jason wants the timeline open with no show, greyed out and
inert ("an empty toolset") — built — so it no longer closes by context;
what it does there waits on a talk (`spec/backlog.md`, B-36).

**Open:** see `spec/backlog.md` (B-42 what one slide's loop covers — its
own time cut to cut, or its transitions in and out too; Jason: depends on
the framework above, not decided).
