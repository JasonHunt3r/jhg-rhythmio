# RhythmIO — shakedown

**The permanent hands-on checklist.** One row per feature a person has to
try, so a full shakedown can be run again from the top. It isn't a to-do
list: passed rows stay, with the date. **Anything found goes to
`spec/backlog.md`**, and the row links the item; a row never holds the
finding itself.

**Rules.**
- Only Jason ticks a box. Claude records what Claude could check, in
  **Claude's level**, and never ticks.
- Every shipped user-facing feature adds a row here, in the commit that
  ships it (CLAUDE.md).
- To re-run: clear the ticks and dates into a dated copy in
  `spec/history/`, then work down the list.

**Claude's level** says how far Claude could check it without a person:
**axtool** (driven and its effect measured on a scratch library) ·
**tests only** (unit tests) · **smoke only** (builds, launches, no
crash) · **can't** (needs a real hand, eye, ear or hardware).

Made 2026-09-28 from the old status's "Still needs Jason's hands" and
Jason's shakedown that day (his raw notes:
`spec/history/2026-09-28-docs-hygiene-pass.md`, appendix).

## Library

- [x] **Library grid tools in the bar** — the slider, Import, Add to Show and Get Info under the viewer drawer; the library panel's bar wraps to two rows; the Library view's title bar is the plain one. · Last checked by Jason: 2026-09-28 · Claude: axtool (layout; buttons not clicked) · `spec/viewer-drawer.md`
- [x] **The grid's keyboard** — arrows, Return renames, Quick Look on ⌘Y or a double-click. · Last checked by Jason: 2026-09-28 (Quick Look not tried) · Claude: axtool (default tile size and width only; `columnCount` at odd widths untried) · `spec/conventions.md` §2
- [x] **⇧/⌘-click in the grid and the storyline** · Last checked by Jason: 2026-09-28 · Claude: tests only (`GridSelection`) · `spec/conventions.md` §1
- [ ] **The grid's first click** — the border draws at once. · Last checked by Jason: — · Claude: can't · `spec/history/2026-09-26-slides-and-the-clutch.md`
- [ ] **List view at the slider's minimum, and the library panel's own slider** — a single-column list at the floor; the panel and the main grid keep their own sizes. · Last checked by Jason: — · Claude: axtool (never a real drag of the slider) · `spec/windows.md`, "Two kinds of window"
- [ ] **A real drag out of the library panel** — filling a new collection with the panel floating over it. · Last checked by Jason: — (opens fine) · Claude: axtool (opens; no drag) · `spec/windows.md`, "Filling a new collection"
- [ ] **Groups in the Library pane** — drag-to-add from the grid and Finder, nested folding, New Group naming, the delete notice's wording, the browser's group filter, Keep as Group; a group onto another (nests), onto its own collection (un-nests), onto a different collection (the "images will be added" notice). · Last checked by Jason: — · Claude: smoke only · `spec/groups.md`
- [x] **Rating keys and E/W/Q in the browser** — a real click on a row, then a key. · Last checked by Jason: 2026-09-28 · Claude: can't (synthetic clicks leave the keyboard on the sidebar) · `spec/conventions.md` §2. Found: the inspector's stars don't follow, B-07
- [ ] **A big library** — scroll-scrubbing keeps up with image loading. · Last checked by Jason: — · Claude: can't until B-30 · `spec/backlog.md` B-30

## Viewer drawer

- [x] **Viewer drawer** — Y / ⇧Y, dragging and double-clicking the dark strip (its only handle), Side by Side and Stack, ← / → within the selection, in the Library grid, the library panel and Edit Show's browser. · Last checked by Jason: 2026-09-28 · Claude: axtool · `spec/viewer-drawer.md`. Found: a group's ↑ / ↓, B-33. Untried: 12 videos side by side
- [x] **The relocated Side by Side / Stack switch** — floats over the drawer's top-right corner. · Last checked by Jason: 2026-09-28 · Claude: not checked (Jason's app was open at the same place) · `spec/viewer-drawer.md`

## Edit Slides

- [ ] **Edit Slides playing** — the Slide viewer (Y), looping the selection with Space, ↑ ↓ in the list after a click, the timeline live in both modes. · Last checked by Jason: — · Claude: can't · `spec/slides-as-mini-movies.md`
- [ ] **The Edit Slides list drop** — a row's top or bottom edge inserts, its middle replaces. · Last checked by Jason: — · Claude: can't (a cross-window synthetic drag wasn't practical) · `spec/conventions.md` §4
- [ ] **Drops onto slides and Replace Image…** — Replace Image… from all four menus (the storyline's was clicked through); the storyline's Replace-or-Insert drag; whether the replace-zone box and the 12 pt insert bands feel right. · Last checked by Jason: — (the storyline path, partly) · Claude: axtool (the storyline only) · `spec/conventions.md` §4

## Edit Show

- [x] **Edit Show's browser picks** — real ⌘/⇧ picks, a picked group dragged onto the timeline, the bars' look as the list scrolls under them. · Last checked by Jason: 2026-09-28 · Claude: axtool · `spec/listkit.md`
- [x] **The browser header's switch** ("Other Collections") — opens, switches, filters, switches back. · Last checked by Jason: 2026-09-28 · Claude: axtool · `spec/groups.md`, "The browser filter". Found: what the drop-down holds, B-34
- [x] **Inspector sliders' live preview** · Last checked by Jason: 2026-09-28 · Claude: can't (built `b66b4af`, never watched) · `spec/plan.md`, "Inspector"
- [ ] **Edit Show's inspector popping out** — the window, the main window closing up, following the selection, undo from the popped-out window. · Last checked by Jason: 2026-09-28 (failed) · Claude: axtool · `spec/panekit.md`, "Pane ⇄ panel". Found: closing the window loses the content, B-01; ways to pop out, B-10
- [ ] **The inspector for a file not in the show** — pick one in the browser's "Not in this show": the inspector shows its info (picture, details, rating, tags) under "Not in this show"; a rating key there moves its stars; picking a slide brings the slide inspector back. · Last checked by Jason: — · Claude: axtool (one file, docked and popped out, 2026-10-02) · `spec/anatomy.md` §5; B-04, B-07
- [ ] **A show's frame rate** — the defaults bar's ⋯ ▸ Frame Rate (24, 30, 60); the export sheet starts from it; ← → on the playhead (nothing selected) steps one frame of it. · Last checked by Jason: — · Claude: axtool (the ⋯ ▸ Frame Rate submenu with its check, 24 fps saved with the show, Undo Change Frame Rate; 2026-10-03), tests (`TimecodeTests`) · `spec/range-and-ruler.md`, N1
- [ ] **The nudge ladder** — Settings ▸ Timeline ▸ Nudge; on the playhead (nothing selected) ← → 1 s, ⌥ ← → one frame, ⇧ 5 s, ⇧⌥⌘ 15 s; the same on a selected marker; **a held arrow undoes in one step**; swapping the one-frame key. · Last checked by Jason: — · Claude: axtool (single presses on the playhead and a marker, two presses two undo steps, the tab; a real hold can't be faked) · `spec/range-and-ruler.md`, N2
- [ ] **Selecting on the ruler** — click a range end (yellow) and nudge it; it stops a frame short of the other end; a locked range beeps; click the playhead (a yellow ring, it doesn't move) and nudge it; an empty ruler click deselects; the readout beside what moved. · Last checked by Jason: — · Claude: axtool (In end 1.24 → 2.2333 → stops at Out − 1 frame; locked: no move; the playhead click and ring; empty click deselects; readout `0:02:07 +1:00`; 2026-10-03) · `spec/range-and-ruler.md`, N3
- [ ] **⌘ and ⌘⌥ jumps** — ⌘ → / ← to the next marker (on a selected marker, the selection hops instead); ⌘⌥ to the next beat on a show with detected beats; a marker skips a beat its kind already holds; "No beats detected" without them; nothing wraps. · Last checked by Jason: — · Claude: axtool (a 120 BPM click track: the playhead 1.2 → 1.5 → 2.0 and back; a marker 17.2 → 17.5 → 18.5 past one at 18.0; ⌘← hopped the selection; the flash; ⌘ to a marker and stopping; 2026-10-03) · `spec/range-and-ruler.md`, N4
- [ ] **Marker collisions** — M beside a marker replaces it (Undo brings both back); nudging into one is refused (beep, red flash); **a held arrow released on one goes back where the hold began**; a drag released on one goes back; the alert and its "Don't show this again"; Settings ▸ Timeline's tolerance and Reset. · Last checked by Jason: — · Claude: axtool (M at 18.1 replaced 18.0, one Undo restored both; the 11th one-frame press refused with the flash; a drag back, unsaved; the alert both ways; Reset cleared the suppression; the Settings page's full height; a real hold can't be faked; 2026-10-03) · `spec/range-and-ruler.md`, N5
- [ ] **The range past the end** — nudge or drag Out past the show's end; the ruler carries on; Fill Range with Images on it grows the show to Out. · Last checked by Jason: — · Claude: axtool (Out 54 → 84 on a 54 s show, the ruler to 1:24; the fill by test only; 2026-10-03) · `spec/range-and-ruler.md`, N6
- [ ] **A range end follows the mouse (B-02)** — drag an end slowly, by hand: it stays under the pointer. · Last checked by Jason: — · Claude: axtool (a fast 104 pt drag: 77.567 s against 77.58 expected; a slow hand drag can't be faked; 2026-10-03) · `spec/range-and-ruler.md`, N8
- [ ] **Edit Range** — double-click an end (and the bar: the playhead stays put); the frames (a video slide at its moment, the slide's title, timecode, frame number); typing In, Out or Length; a red field refusing Return; Apply as one undo; Esc; **the range's right-click menu: Edit Range…, Show In Line, Show Out Line**. · Last checked by Jason: — · Claude: axtool (an end and the bar, the anchor, In then Length typed and followed, Apply 1.5–6.0 with "Undo Edit Range", `1:75` red and refused, Esc, the frames; the right-click menu didn't open from axtool; 2026-10-03) · `spec/range-and-ruler.md`, N7
- [ ] **Edit Range's waveform** — the strip under the frames (a show with audio), the Show popover's switches and ×2 / ÷2, dragging In and Out on it (snapping, the frames following), the fields in a row. · Last checked by Jason: — · Claude: axtool (the 120 BPM click track: 120 → 240 BPM with ×2, sections, In dragged onto the 2.5 s beat; 2026-10-03) · `spec/range-and-ruler.md`, "Edit Range's waveform"
- [ ] **Stepping number fields** — click into a number (an inspector value, a seconds field, Edit Range): ↑ ↓, ⇧ and ⌥ step it; **a two-finger swipe over it, and its direction and feel**; Return saves once (one undo); Settings ▸ Editing ▸ Number Fields. · Last checked by Jason: — · Claude: axtool (Position X 14 → 26 saved once and undone in one; Edit Range +1 s, +1 frame, −5 s to 0 with the IN frame redrawn at once; a mouse-wheel notch; the Settings section; a real trackpad swipe can't be faked; 2026-10-03) · `spec/conventions.md` §2
- [ ] **A video slide's volume line** — the outermost points' diamonds, half-clipped by the rounded corners (may want insetting); the undo names ("Add Volume Point" and so on) in the Edit menu. · Last checked by Jason: — · Claude: tests only (undo steps; names not confirmed) · `spec/video-audio.md`

## Timeline

- [x] **Timeline keys** — arrow navigation across all four rows, Go Back and Go Forward. · Last checked by Jason: 2026-09-28 · Claude: axtool · `spec/conventions.md` §2. Found: arrows should follow focus (built 2026-10-02, the row below)
- [ ] **Arrows follow the last click** — in Edit Show, → before any click moves the timeline; click the browser and ↑ ↓ move it, and the timeline's selection turns grey; click the timeline and it takes them back; the viewer and the sidebar likewise. In the Library, a tile click makes the tiles blue and the sidebar grey, and a sidebar click swaps them. Holding an arrow (or ⇧-arrow) keeps going. · Last checked by Jason: never · Claude: axtool, 2026-10-02 · `spec/conventions.md` §2
- [x] **Timeline height** — can't be dragged taller than its content; shorter scrolls the rows; the row handles track the scroll; a moved row scrolls into view. · Last checked by Jason: 2026-09-28 · Claude: axtool (a preference write, not a drag) · `spec/timeline-pane.md`, "Its height"
- [ ] **The timeline full width, and popping it out** — at x=0 under the Library pane; the panes fill the height when it closes; the Timeline window's keys, menus and a slide Delete. · Last checked by Jason: 2026-09-28 (failed) · Claude: axtool · `spec/timeline-pane.md`. Found: closing the window doesn't bring the content back, B-01
- [ ] **The range package, W6–W10** — dragging an end; the lock; I/O/⌥X while locked; the range button's plain, ⌥⌘ and ⇧⌥⌘ clicks and its right-click; the shaded span's menu; double-clicking a song section; the Fill Range dialog's Library tab and a Displace fill. · Last checked by Jason: 2026-09-28 (partly) · Claude: axtool (no real drag; axtool can't hold two modifiers) · `spec/range-and-ruler.md`. Found: B-02, B-05, B-06, B-11; to read, B-32. Untried: two-modifier clicks, Fill's Library tab, Displace
- [ ] **Context menus C1–C3** — Remove Image, Remove Transition, Remove Marker. · Last checked by Jason: — · Claude: tests only (the storyline resisted synthetic clicks) · `spec/conventions.md` §3
- [ ] **The Rhythm tool** — the panel's look (the space round the form; a staff space is 5.5 pt), Listen by ear on real music, Space stopping Listen. · Last checked by Jason: 2026-09-28 (partly) · Claude: can't · `spec/rhythm.md`. Found: double tempo, B-09; what's left, B-31
- [x] **Dragging a song in** from Finder or Music. · Last checked by Jason: 2026-09-28 · Claude: can't · `spec/plan.md`, Phase 3
- [ ] **Listening** — music sync, fades, crossfades; Bluetooth headphones' delay (the output latency is subtracted, untested); a video slide's sound (V6): a clip with its middle dropped, a video against a song (they mix, no ducking), whether the level changes smoothly. · Last checked by Jason: — · Claude: can't · `spec/video-audio.md`, "V6 is Jason's"
- [ ] **Slide Info, ⌥Space** — ⌥Space shows the selected slide's card (the Edit Range look), following the selection by click and arrows; while open, hovering another slide shows a second card that clicks pass through; ⌥Space or Esc closes; nothing on hover while closed; right-click ▸ Slide Info; double-click still the Slide Editor; in the popped-out Timeline window too; scrolling the timeline with cards open. · Last checked by Jason: — · Claude: PopoverKit's behaviours measured in a probe and its tests; the app only built · `spec/popoverkit.md`

## Menus

- [ ] **The viewer's menus, Show in Library, the progress line** — every menu's items, Rotation Handles and Slide Progress, Show in Library opening the panel on the right file, Hide/Show Frame Strip, the progress line filling left to right. · Last checked by Jason: — · Claude: axtool · `spec/conventions.md` §3, route item 4
- [ ] **Edit Slides', the browser's and the inspector's menus** — Copy/Paste and Copy/Paste Settings, the quick-settings submenus, Use Defaults for All Slides, the browser's Select in Timeline / Play from Here / Remove from Show, both inspector section menus. · Last checked by Jason: — · Claude: axtool · `spec/conventions.md` §3, route items 3, 5, 6
- [ ] **Menus batch 5** — the Show and View menus, Get Info from a slide selection, Show ▸ Play starting at the selection, Help ▸ Keyboard Shortcuts; nothing doubled up or went silent. · Last checked by Jason: — · Claude: smoke only · `spec/hig-audit.md` F1–F4

## Windows and panes

- [x] **Windows pass and the tabbed Settings** — tabs, icons, resizing per tab, panels stepping aside from Settings and back, reopening on the last tab; also with the Rhythm tool or the Slide Editor overlapping. · Last checked by Jason: 2026-09-28 · Claude: axtool · `spec/window-behavior.md`, "The windows pass"
- [x] **Panels no longer float over other apps** · Last checked by Jason: 2026-09-28 (one Finder switch) · Claude: axtool · `spec/window-behavior.md`, "The windows pass"
- [x] **Transparency** (Settings → Windows) — Panel and Title Bar values for Light and Dark, Include handles, the hover handle row on an open drawer's divider. · Last checked by Jason: 2026-09-28 · Claude: axtool (measured, not judged) · `spec/window-behavior.md`, "The Transparency module"
- [x] **The drawers' feel and sensitivity** — the clutch (pull, brake, flick, swipe, natural-scrolling direction), 64 pt and the 0.18 s slide; the engage-distance line, Quick ↔ Smooth, the practice drawer. · Last checked by Jason: 2026-09-28 · Claude: axtool (mechanics only) · `spec/panekit.md`, "The clutch"
- [ ] **The Set Up Triggers box** — opening, bringing forward, floating, closing Settings without closing the box. · Last checked by Jason: 2026-09-28 (works; wants one combined control, B-13) · Claude: axtool · `spec/window-behavior.md`, "A reusable modal box"
- [ ] **Panes switching sides** — the Browser, the Inspector, the Library pane, the timeline (to the top) and Edit Slides' inspector; and whether PaneKit's 1 pt divider with its 7 pt grab band is fiddly where the frame strip's old 12 pt bar was. · Last checked by Jason: — · Claude: axtool (the Browser and the Inspector) · `spec/panekit.md`, "What every pane can do"

## Look and feel

- [x] **Look and feel** — the row handles (10 pt wide), the drawers, the level line's handles, whether a line on every clip is too busy in the thin images row, the transport's toggles. · Last checked by Jason: 2026-09-28 · Claude: can't · `spec/timeline-pane.md`

## Export

- [x] **Video export, a listen** — an exported movie against the same show playing. · Last checked by Jason: 2026-09-25 · Claude: tests only · `spec/video-export.md`
- [ ] **Setlist round trip with an edit in Numbers** (4e) — export, edit the TSV in Numbers, re-import; does Numbers save TSV back? · Last checked by Jason: — (no record it was done) · Claude: tests only (no Numbers) · `spec/setlist.md`

## RhythmBG

- [ ] **RhythmBG under the new signature** — the Control Center tile (re-registered on install), the login item. · Last checked by Jason: 2026-09-28 (the login item is fine) · Claude: can't · `spec/rhythmbg.md`. Found: the double launch, B-08; the tile's two clicks, B-15
- [ ] **RhythmBG: naming screens, the map view, the window opening on your screen** — renaming a monitor or a Space, Map | List, the window landing on the calling monitor with its Space selected; with a second monitor, the map to scale, the window following the pointer, ⌥-double-click moving it. · Last checked by Jason: — (one monitor only) · Claude: axtool (one monitor; the multi-monitor half reasoned from the code) · `spec/rhythmbg.md`
- [x] **RhythmBG: per-screen stop (B-14)** — a monitor's switch (green when on) in the window's list and the panel: off shows the wallpaper on all its Spaces, with Synchronize on too; a Space's Plays Nothing (window and panel ▾) shows the wallpaper, and Synchronize overrides it; the map dims a monitor that's off. · Last checked by Jason: 2026-10-03 · Claude: off state screenshotted from a scratch copy (desktop show off, one monitor) · `spec/rhythmbg.md`
- [x] **RhythmBG: Open at Login (B-87)** — RhythmIO ▸ Settings ▸ RhythmBG ▸ Open RhythmBG at login turns it off and on (System Settings ▸ General ▸ Login Items agrees); RhythmBG's ⋯ ▸ Open at Login… brings RhythmIO forward on that tab, launching it if needed. · Last checked by Jason: 2026-10-03 · Claude: the URL opening that tab, screenshotted from a test copy (the switch not flipped: it's your real login item) · `spec/xcode-port.md`
- [x] **Play on Desktop (B-17)** — a show row's right-click ▸ Play on Desktop: with one monitor a plain item, with two a submenu of monitors (RhythmBG's names) and Every Screen; the show starts on that monitor's current Space (or everywhere), RhythmBG starting if it wasn't running, Synchronize going off for one monitor. · Last checked by Jason: 2026-10-03 (two-monitor submenu not confirmed) · Claude: the RhythmBG end, with a scratch copy and the URL (settings file and log checked); the menu itself unseen · `spec/rhythmbg.md`
- [ ] **RhythmBG: Touch ID, click-away and Space pause** — unlocking a private library with Touch ID, the panel closing on a click elsewhere, pausing on a Space switch; not re-done against the nested RhythmBG. · Last checked by Jason: — · Claude: can't · `spec/rhythmbg.md`

## From before Phase 3

- [x] **The pre-Phase-3 set** — cross-app drags from Finder and Photos, Touch ID and the Mac's password, pinch, a second screen, cursors, one real ⌘Z with the Info panel focused. · Last checked by Jason: 2026-09-28 · Claude: can't · `spec/history/2026-09-21-hands-on.md`
