# RhythmIO — backlog

**The one to-do list.** Every open item lives here, once. Specs keep their
design and reasoning, and point here for what's left; `spec/status.md`
says which of these come next. Made 2026-09-28 from twelve separate lists
(`spec/history/2026-09-28-status-archive.md` and the verbatim copies in
`spec/history/verbatim/` hold the originals).

**How to use it.** Close an item by deleting its line and saying so in
the commit (and a dated line in history if there's a story). Add an item
with the next free ID. IDs are never reused. A hands-on finding from a
shakedown (`spec/shakedown.md`) becomes an item here, not a note on the
shakedown row.

**Each entry:** ID · priority · area · what · where the design lives ·
where it came from.
- **Priority** (the Sep 25 Worklist's scale): **P0** broken, blocks
  normal use · **P1** core gap, works but wrong or incomplete · **P2**
  polish or nice-to-have · **P3** needs a decision or more spec first.
- **(was item N)** is its number in the Sep 25 feedback worklist
  (`spec/history/2026-09-25-feedback-worklist.md`), so old "item N"
  references in `history/` still resolve here.

## Build queue

Claude can do these.

- **B-02** · P1 · Range — Dragging a range end (I or O) runs faster than the mouse, so the marker zips away. Real, not the tool artifact the old status suspected. `spec/range-and-ruler.md`. (Shakedown 2026-09-28.)
- **B-05** · P1 · Range — The range can be set past the show's current end, so more tiles can be added into it. `spec/range-and-ruler.md`. (Shakedown 2026-09-28.)
- **B-06** · P1 · Range — Clicking a range marker selects it, so it can be nudged. `spec/range-and-ruler.md`. (Shakedown 2026-09-28.)
- **B-08** · P2 · RhythmBG — A second copy on first launch: **found 2026-10-02.** RhythmBG ▸ Desktop Show… calls `registerAtLogin()`, and registering a login item starts it at once (launchd, pid shown as `com.jhg.rhythmbg`); then `openDesktop()` opens RhythmBG too, in the same second, so two run. Only when the menu item does the registering. `RhythmBGHelper.openDesktop`, `spec/rhythmbg.md`. (Shakedown 2026-09-28.)
- **B-09** · P2 · Rhythm — Tempo detection reads double: Fly Me to the Moon as 145 BPM, where it's about 72. Needs an octave (half-time) check. `spec/rhythm.md`. (Shakedown 2026-09-28.)
- **B-10** · P2 · PaneKit — Ways to pop out the inspector besides the View menu: a right-click item, a button, or a click action. `spec/panekit.md`, "Pane ⇄ panel". (Shakedown 2026-09-28.)
- **B-11** · P2 · Range — A numeric field for exact In and Out values. `spec/range-and-ruler.md`. (Shakedown 2026-09-28.)
- **B-12** · P2 · Library — An Info drawer on the right of the Library view, where the inspector sits elsewhere: one click on the Info button opens the drawer, a double-click opens the Info window that exists. Jason first asked 2026-09-24 ("Design notes", below). (Shakedown 2026-09-28.)
- **B-13** · P2 · Settings — Set Up Triggers: one control where the Responsiveness slider and the practice drawer sit together, instead of two items. `spec/window-behavior.md`, "A reusable modal box"; `spec/panekit.md`, "The clutch". (Shakedown 2026-09-28.)
- **B-14** · P1 · RhythmBG — Per-screen stop: a green on/off switch in each monitor's title bar **and** a "Plays Nothing" entry in the per-Space list (Jason, 2026-09-26: "Simple, do both"). `spec/rhythmbg.md`, "The 2026-09-25 feedback items". (was item 24)
- **B-15** · P2 · RhythmBG — The Control Center tile wants a better icon (with RhythmBG's own icon, item 29's other half). Its other half, opening the panel only on the second press, was fixed 2026-10-02 (a cold launch's URL arrived before the panel existed). `spec/rhythmbg.md`, "The 2026-09-25 feedback items". (was item 23)
- **B-16** · P1 · RhythmBG — Pan and Zoom, length and transition options, matching Quick Show's and New Show's. After Quick Show's field list settles (B-39). `spec/rhythmbg.md`, "The 2026-09-25 feedback items". (was item 25)
- **B-17** · P2 · RhythmBG — Play on Desktop: the show row's menu item (there, greyed out) hands the show to RhythmBG. `spec/conventions.md` §3.
- **B-18** · P2 · Timeline — The timeline's right-click menus as settled 2026-09-24. Today only C1–C3's minimal items exist: a block (Edit Slides' slide menu, plus Select All After), a cut with no transition, a transition (Style ▸, Duration ▸, Use Show Default, Apply to All Cuts), a lane image (Duplicate, Fade ▸, Show in Library), an audio clip (Set Range to Clip, Fade ▸, Show in Library), a marker (Show / Hide Line, Remove All Beat Markers), empty ruler space, a row handle, the transport, empty audio-row space. `spec/conventions.md` §3.
- **B-19** · P2 · Menus — The rest of §3's settled items that aren't on their menus: a tile's Quick Look and Copy; Select All on empty grid space; Open Inspector on a slide; Edit Slides' empty space below a non-empty list; the browser's empty space (Import…, Add from Library…); section menus for the inspector's Length, Transition, Pan and Zoom and Rotation (they need headers first) and Reset to Default on a single control; the viewer's Select ▸. (A tile's and a collection's Play wait on Quick Show, B-39.) `spec/conventions.md` §3.
- **B-20** · P2 · Edit menu — Copy and Paste of slides from the Edit menu (today only from the slide's right-click); copying tiles to Finder or Mail; Duplicate for a selected lane image (A2). `spec/conventions.md` §5.
- **B-21** · P2 · Selection — Rubber-band selection on empty space; ⌘ or ⇧ adds (B4, settled 2026-09-24). `spec/conventions.md` §1.
- **B-22** · P2 · Audio — Audio rows stack (decided 2026-09-24): Add Audio Row, and each clip says which row it's on. To settle while building: how Detect Beats and the Rhythm tool pick a row, several images rows, a row's own volume and mute, a limiter on the mix. "Design notes", below.
- **B-23** · P3 · Selection — ⌘-click adds lane images and audio clips to the selection (E4, settled 2026-09-24). `spec/conventions.md` §1.
- **B-24** · P3 · Keys — Esc clears a timeline selection, and the selection after the Slide Editor closes. `spec/conventions.md` §2.
- **B-25** · P3 · Timeline — ⌘⌥-click a timeline row to open its drawer (settled 2026-09-24). `spec/conventions.md` §1.
- **B-26** · P3 · Menus — Copy Settings and Paste Settings as ⌥-alternates of Copy and Paste (built as four always-visible items; needs a real AppKit menu). Only if the four read as clutter. `spec/conventions.md` §3, route item 3.
- **B-27** · P3 · Menus — E, W and Q as shortcuts at the right edge of the browser's menu, if that can be done without them taking typing from Search (C8). `spec/conventions.md` §3.
- **B-28** · P3 · Timeline — Scrub audio: a button in the audio row's drawer turns it on (plan, Phase 3). Today scrubbing is silent, and the rows' drawers hold no controls. `spec/timeline-pane.md`, "The drawers".
- **B-29** · P3 · Docs — Map 1 (`spec/maps/1-library-grid.png`) is stale. Its source, `maps.html`, is current, but `render.js` needs Playwright, which isn't installed. Ask before installing.

## Needs Jason's hands

The feature-by-feature checks are in `spec/shakedown.md` (every unticked
row). These are the other things only Jason can do.

- **B-30** · P2 · Library — Set up a big test library (4,000+ images), so Claude can measure scroll-scrubbing getting ahead of image loading. (was item 36)
- **B-31** · P2 · Rhythm — List what's still to do on the Rhythm tool (Jason, 2026-09-28: "largely fleshed out", with "some things to do"). `spec/rhythm.md`.
- **B-32** · P3 · Range — Read one edge case in Fill Range: a slide wholly inside the range continues past its end as a second use of the same file. Reasoned through and tested, but the plan never said so. `spec/range-and-ruler.md`, "Fill the range with images".

## Needs a decision, or parked

**Waiting on a talk or a plan (P3):**
- **B-33** · Viewer — With a group selected in the viewer drawer, ← / → move the highlight within the collection, but ↑ / ↓ let go of the group and go back to one selection. Decide what's intended. `spec/viewer-drawer.md`. (Shakedown 2026-09-28.)
- **B-34** · Browser — The "Other Collections" switcher: what belongs in its drop-down. Also whether "In this show" narrowing to the overlap (usually empty, browsing another collection) is useful. `spec/groups.md`, "The browser filter". (Shakedown 2026-09-28; follows item 38.)
- **B-35** · Windows — The "Smart View" preference: panes open and close by context, or keep your own choices. Today a one-paragraph sketch; its "timeline closes with no show" part was overruled 2026-09-27. `spec/slides-as-mini-movies.md`, "Smart View"; `spec/window-behavior.md`.
- **B-36** · Timeline — Making a show from the timeline when no show is open (the show creator; item 33's option (b)). The timeline stays open there, greyed and inert. Ties to B-35. `spec/slides-as-mini-movies.md`. (was item 33)
- **B-37** · Library — Show Similar, by theme: Vision's feature prints find bursts and near-copies, not themes ("dogs", "dogs sitting"); Jason wants it to find a good next slide. Research, then a talk. `spec/plan.md`, Phase 3b. (was item 35)
- **B-38** · Simple things fast — The levels (Basic, Advanced, "Bring it on!"): Jason arranges each level, then a design. `spec/simple-things-fast.md`, "Levels".
- **B-39** · Simple things fast — Quick Show: the dialog's details, then a design with Jason. A tile's and a collection's Play, and RhythmBG's options (B-16), wait on it. `spec/simple-things-fast.md`, "Quick Show". (was item 37, scope settled)
- **B-40** · First run — The guided first run: the brief's five open questions. `spec/first-run-brief.md`, "Open questions to settle".
- **B-41** · Timeline — Image stickiness (2c): does a lane image stay at its time on the clock, or move with the slide it starts over? It stays on the clock for now. Ask once Jason has his own files as a test bed. `spec/plan.md`, Phase 2c.
- **B-42** · Slides — What one slide's loop covers: its own time cut to cut (as built), or its transitions too. Waits on B-43. `spec/slides-as-mini-movies.md`.
- **B-43** · Slides — Slides with more inside: a timeline inside a slide (portrait shots side by side filling a frame, each with its own entrance), the collage maker's multi-panel idea grown up, plus its gradient mask. Not designed. `spec/slides-as-mini-movies.md`; "Design notes", below.
- **B-44** · Slides — The Slide Editor's revamp (Jason expects one): as the Slide viewer's pop-out, its own menus, and whether it gets the looping Play. `spec/slides-as-mini-movies.md`.
- **B-45** · Slides — Maybe: reorder the selected slides by dragging in the Slide viewer, the list following. `spec/slides-as-mini-movies.md`.
- **B-46** · Groups — Promote a group to its own collection: does the group survive, do its sub-groups come along, and where the command lives. Settle it with the group's fuller right-click menu (still minimal). `spec/groups.md`, "Promotion". (Item 12's follow-on.)
- **B-47** · Pointer — What ⌥-click means: "select the thing behind" (Jason's leading idea, §1: Open) or, on a slide, the inspector's quick version (the double-click section). Also whether ⌥-drag duplicates (proposed). `spec/conventions.md` §1.
- **B-48** · Pointer — Double-click, target by target: "go into it" is settled (`spec/conventions.md`, "Double-click"), but several targets list two candidates to try (a Library tile, a lane image, a row's handle). Jason's window answer 7 (2026-09-24) still called double-click undecided on 2026-09-25: his first idea was that double-clicking a collection opens its disclosure; ⌥-click is the likely partner (either double-click opens the disclosure and ⌥-click the Slide Editor, or the other way round). `spec/history/verbatim/windows-retired-2026-09-28.md`, "Jason's answers".
- **B-49** · Edit menu — Paste Settings ⇧⌘V, Final Cut's Paste Attributes (proposed). `spec/conventions.md` §5.
- **B-50** · Edit Slides — Save as Preset… on the defaults bar: where named presets live (per library? global?) and how they're applied. `spec/conventions.md` §3, route item 3.
- **B-51** · Edit Show — Where the show's defaults go in Edit Show: the inspector with nothing selected, or a popover from the transport (G6). `spec/hig-audit.md` G6.
- **B-52** · Timeline — Row order looks like layer order and isn't: say so where rows are reordered, or make it so (G7). `spec/hig-audit.md` G7.
- **B-53** · Naming — "The viewer drawer" over the grids clashes with the anatomy's **Viewer** and **Drawer**; the anatomy says **selection viewer** for now. Edit Slides' drawer is the **Slide viewer**. `spec/anatomy.md`.
- **B-54** · Library — The Library grid's header row, above the filter bar, shows what's in view and its count. What Library-view tools go there. (Jason, 2026-09-27: "a place we'll add functionality".)
- **B-55** · Viewer — The viewer drawer's cap of 12 (proposed), and whether a click in the viewer should do anything. `spec/viewer-drawer.md`.
- **B-56** · Pan and Zoom — A pan with a direction, and aiming the zoom by clicking the image (⌥-click, say) in the viewer or the Slide Editor. Today Auto mostly zooms. "Design notes", below.

**Parked** (not pressing; each wants a talk or a plan before code):
- **B-57** · Accessibility — The pass Jason wants later ("PaneKit should be made to the standards of a pro level App Store candidate", 2026-09-27). First item: ListKit's lists get VoiceOver's real outline role through `.accessibilityRepresentation` (a hidden `List` with `OutlineGroup`); settle first in the harness whether VoiceOver's cursor and axtool's frames still land on the drawn rows. `spec/listkit.md`, "Known limits".
- **B-58** · ReorderKit — Lift drag-to-reorder into its own package, like PaneKit. No plan written yet. What would move: `RhythmIOCore/Reorder.swift` (+ tests), `RhythmIOApp/ReorderDrag.swift`, and the grid's wiring in `LibraryGridView` (`startDrag`, `commitReorder`, `slot(at:)`, the fly-in and landing) as the package's API. `LibraryOrderNotice` stays in RhythmIO. `spec/groups.md`, "Reordering".
- **B-59** · Library — Double-click inside a multi-selection Quick Looks the whole selection (Jason, 2026-09-26: "it's fine" as is). The idea: delay the collapse only for a plain click on a tile already selected among others. Details: `spec/history/2026-09-28-status-archive.md`, "Parked for later".
- **B-60** · Notices — One type for "explainer" notices (`CustomOrderNotice`, `LibraryOrderNotice`) and a line in `spec/conventions.md` §6. Jason wanted their text centred (macOS 27's `NSAlert` can't) and room beside the lone icon, maybe for the app's name: a reason to consider our own panel.
- **B-61** · Framing — Presets (Flush, 2a): accelerating rotation plus zoom and pan, "down the hole". Deferred 2026-09-21. `spec/plan.md`, Phase 2a.
- **B-62** · ModKit — Jason's standalone look-auditioning app, planned with App Claude (`ModKit & DefaultsKit — Design Pass.md`, repo root, untracked, his). Here: the glass buttons' corners less circular; whether AppKit windows' corner radius can be changed. (was items 26, 27, 29)
- **B-63** · RhythmBG — Telling RhythmBG when a library moves (B7 left it; Jason isn't sure it's needed). `spec/rhythmbg.md`.
- **B-64** · RhythmBG — Power, a curiosity: live Core Image drawing against a looping HEVC video, per monitor. `spec/rhythmbg.md`, "Still to test".
- **B-65** · Windows — The areas not yet able to leave the main window: the Library pane itself (not the separate library panel) and the Browser; and a single row opened in a window of its own. `spec/windows.md`, "Two kinds of window".
- **B-66** · Windows — Scrolling a Timeline window that's partly covered (padding while covered). Designed, not built; a harness first. `spec/windows.md`, "Scrolling a window that's partly covered".
- **B-67** · Windows — Settings steps the app's own panels aside, but not PaneKit's pop-outs (the Inspector, the Timeline window); a follow-up if it matters. `spec/window-behavior.md`, "The windows pass".
- **B-68** · PaneKit — Switching sides has no menu command or animation yet. `spec/panekit.md`, "What every pane can do".
- **B-69** · Effects — A strobe effect: a slide flashing on and off against the background colour (Jason, 2026-09-21, from the rhythm talk).
- **B-70** · Library — Browsing the Photos library inside the app. No paid membership needed (checked 2026-09-24); signing is stable now. Drag and drop from Photos works regardless. `spec/conventions.md` §5.

## Known issues

- **B-71** · P2 · Library — At 100% opacity, a thin sliver of the row above shows through at the seam between the grid's filter bar and the grid (maybe the taller title-bar region too). Look with screenshots at several scroll positions before touching code. `spec/window-behavior.md`, "The Transparency module".
- **B-72** · P2 · Menus — Places that don't answer a right-click yet, not even with the "No menu yet" note: the timeline, the transport, the filter bar and sort strip, the defaults bar. `spec/conventions.md` §3.
- **B-73** · P2 · Library — Some collections' disclosures rendered collapsed on a fresh launch (seen 2026-09-27 with 25 seeded collections, while the sidebar was still a `List`; varies run to run). Not re-checked since the sidebar moved to ListKit. `spec/window-behavior.md`, "The Transparency module".
- **B-74** · P3 · Setlist — A setlist exported before 2026-09-23 loses its Pan and Zoom setting on re-import, silently (the rename, `spec/history/2026-09-23-pan-and-zoom-rename.md`).
- **B-75** · P3 · Undo — Edit ▸ Undo was disabled once after a rating key, on one test copy (2026-09-26). Four later tries worked. Not reproduced, not explained; `UndoMenuState`'s tracking of the key window is the suspect, unproven.
- **B-76** · P3 · Audio — A song lying wholly inside another plays over it without crossfading (only a partial overlap crossfades). Level tops out at 100%.
- **B-77** · P3 · Playback — The last slide cuts to the background when something runs past the slides; a fade could come later.
- **B-78** · P3 · Performance — CPU is about 33–37% while the editor plays; memory about 430 MB. RhythmBG's desktop mode is ~2%, except while Pan and Zoom moves (about 40% of a core: it really redraws every frame). Why RhythmBG's random-mode Pan and Zoom default is off.
- **B-79** · P3 · Video — A video can't go in the lane. The frame strip shows a video's first frame, the onion skin skips video slides, and `mio render` draws a video slide as the background colour (only `mio movie` and the app use `MovieMedia`). A video slide's sound is decoded whole into memory on export; fine for slides.
- **B-80** · P3 · Viewer — The zoomed-out work area doesn't draw a lane image's overhang past the frame.
- **B-81** · P3 · Viewer — Its right-click picks the image menu or the pasteboard menu by which image was last *clicked*, not where the right-click landed. Accepted 2026-09-24; real click-location tracking is the fix if it bites. `spec/conventions.md` §3, route item 4.
- **B-83** · P2 · Timeline — In the popped-out Timeline window, clicking a slide didn't select it (two axtool clicks, 2026-10-02; the arrows did reach the timeline there). Not yet tried by hand, so it may be a synthetic-click artifact. `spec/panekit.md`, "Pane ⇄ panel".
- **B-84** · P3 · Keys — `ListEmptySpace` (`NoMenuYet.swift`) and `ClickTakesKeyboard` (`EditShowView.swift`) pass `hitTest` a point in the content view's own (flipped) coordinates, not its superview's, so the view they find can be mirrored top to bottom — the bug `KeyboardArea` had, measured 2026-10-02. Check whether either misfires.
- **B-82** · — · Transitions — Accordion was dropped (it renders as a dissolve on this macOS), and Page Curl is offered as "Page Turn". A limitation, recorded so it isn't rediscovered.

## Design notes

Moved here from `spec/plan.md`'s "Later" (2026-09-28), with their wording
intact, for the backlog items above that have no spec of their own yet.

**B-12, the Library's Info drawer** (Jason, 2026-09-24, while building the
library panel: `spec/panekit.md`, "Step 4, second piece"). Today
`InfoPanel` is a separate floating window (⌘I or Get Info) that follows
`model.infoPanelSelection`. The idea: instead (or as well), a column on
the grid's own right edge — a drawer pane, PaneKit's own primitive
(`spec/panekit.md`) — showing the same metadata and tags inline, without
a second window to manage. `InfoPanelContent`'s view could likely be
reused as-is inside it.

**B-56, Pan and Zoom that pans, with a direction, and a point to aim at**
(Jason, 2026-09-24: "the pan and zoom currently only zooms").
*From the code:*
- **Auto** is mostly a zoom (`ShowTimeline.autoPanAndZoom`): from 1× to
  1.12–1.25×, with a drift of at most 8% of the image, in or out at
  random.
- **Custom** can pan. The inspector's small editor has a green start
  frame and a red end frame to drag, which is easy to miss.
- With **Fit** at 1× there's no room to pan at all; the image already
  fits the frame. A pan needs zoom, or Fill.

*Wanted:*
- a way to pan, with a **direction** (left, right, up, down, or a choice
  for Auto);
- a way to put the **zoom-to point** on the image by clicking, or a
  modified click (⌥-click, say), in the viewer or the Slide Editor,
  rather than dragging a small frame in the inspector.

**B-22, audio rows stack** (decided, Jason, 2026-09-24): a show can have
more than one audio row, for music under a voice, or sound effects over a
song. Added from the timeline (Add Audio Row, on the audio row's
right-click).
*From the code:*
- The rows model already expects it. `TimelineRow.normalized` keeps one
  row per kind "for now", noting that "that rule relaxes when a show can
  have more than one row of a kind".
- An `AudioClip` doesn't say which row it's on, since there's been only
  one. Stacking adds a row reference to each clip. It's a new field in
  the show's JSON, decoded on its own (CLAUDE.md), where no reference
  means the first audio row, so every saved show still reads. No library
  migration.
- Within a row, overlapping clips crossfade, as now. Across rows, they
  mix.
- **What it's for (Jason):** mostly crossfading music, and laying sound
  clips on top of background music. Not stacking several songs.
- **The mix already sums** (checked 2026-09-24). Live, `MusicPlayer` gives
  every clip its own player node, all feeding one mixer, so any number of
  clips play together. Export mixes offline (`MovieSoundTrack`) the same
  way. It's the audio engine that mixes; the database only stores where
  each clip sits.
- *One thing to watch:* two clips at full level can add up past full
  scale and distort. A limiter on the final mix is the usual guard. A
  video slide's sound was decided to "just mix, no ducking"
  (`spec/video-audio.md`); ducking music under a voice could be an option
  later.
- *Row controls:* each clip already has its level line. A row's own
  volume and mute may find their place in the rows' drawers once they're
  rearranged (`spec/timeline-pane.md`, "The drawers"). Not thought out yet
  (Jason).
- *To settle:* how Detect Beats and the Rhythm tool choose a row, and
  whether several *images* rows follow the same way (the plan mentions "a
  second images row").
- *Naming:* Jason said "audio track". The app's word is **row**
  (`spec/anatomy.md`), so the menu item says **Add Audio Row**.

**B-43, a collage maker** (Jason, 2026-09-21b), parked to think through
rather than build straight away. Two ideas so far, which may turn out to
be the same feature seen two ways:
- A gradient mask to blend two photos on one slide: two points pinned to
  the slide frame's edges with a line between them, a handle at the
  line's centre that pulls out at right angles to set how far the
  gradient reaches, and a further handle on that pull-out to set the
  gradient's midpoint weight.
- Multi-panel slides (2 or 3 images arranged "1 2 3" across one slide) —
  grown on 2026-09-26 into slides with a timeline of their own (each
  image its own entrance and timing, portrait shots filling a frame):
  `spec/slides-as-mini-movies.md`.
The Slide Editor is where it would live (`spec/windows.md`, "Editors for
one thing").

**B-70, Photos-library browsing.** Deferred until the app has taken
shape; the permission question gets worked out then. **Checked
2026-09-24:** no paid developer membership is needed. RhythmIO isn't
sandboxed, so it needs a usage line in Info.plist and the user's
permission (`spec/conventions.md` §5).
