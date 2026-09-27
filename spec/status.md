# ShowTools — status

**Read this first each session.** The state of play, in the present tense.
Rules are in `CLAUDE.md`, decisions in `spec/plan.md`, and what happened on
which day in `spec/history/` (never read for current rules). This file is
rewritten, not appended to: if a line has a date and a story, it belongs in
`history/`.

Repo: `~/Projects/ShowTools`, pushed to **github.com/JasonHunt3r/jhg-showtools**
(public, `main`).

## Where it stands

**Everything planned is built**, and more has come from Jason's use of it.
Phases 1–5, Phase 3b, Phase 4 and video export. **349 tests** (336 core +
13 BGTools; PaneKit has its own 46). **Library schema 14.**

| Phase | State |
|---|---|
| 1 Library + player | Built |
| 2 Composer (Edit Slides / Edit Show) | Built |
| 2a Framing, rotation, match cuts | Built, except presets (Flush), deferred |
| 2b Library manager | Built |
| 2c The lane: transitions row + images row | Built |
| 3 Music + timeline | All 7 steps built. Left: settle image stickiness |
| 3b Find Similar | Built: Delete by context, Find/Show Similar, Keep One, Keep as Group |
| Groups inside collections | Built 2026-09-24, Core through UI (`spec/plan.md`) |
| 4 Setlist export / import | Built, 4a–4d |
| E Video export | Built, E1–E5. Own spec `spec/video-export.md`. Listened to by Jason (2026-09-25) |
| 5 BGTools | Built, B1–B7, plus naming screens/the map view/the window opening on your screen (2026-09-25). Own spec `spec/bgtools.md`. Left: its own "Next up" list (items 23–25, after the ShowTools fixes), Jason's hands-on pass, the Pan and Zoom cost, telling BGTools when a library moves |

Every schema upgrade is additive and tested by opening a library of the
version before (7 rows, 8 music, 9 markers, 10 editing state, 11 rhythm
patterns, 12 their note length, 13 groups, 14 a drag order for a
collection's/group's files). Before an upgrade the database is copied
to `Library.sqlite.v<N>.bak`.

**Built most recently (2026-09-26)** — details in the specs, the story in
`spec/history/2026-09-26-slides-and-the-clutch.md`:
- **Edit Slides plays** (`spec/plan.md`, "Slides as mini movies", steps
  1–3): its timeline is live, Play loops the selected slides cut to cut,
  and the **Slide viewer** drawer (Y) shows the picture. A click in the
  slide list gives it the keyboard.
- **The clutch** — how every PaneKit drawer feels (`spec/panekit.md`):
  bite, slip, loose at 64 pt; a slow drag brakes at the minimum and shuts
  64 pt past it; flick and handle swipe; slides instead of jumps; the
  resize cursor on every handle.
- **The grid selects on the first click** (was ~350 ms late).
- **A still no longer squashes when its view is resized** (Pan and Zoom
  off, in any canvas).
- **Signed "Apple Development"**, team `P82S39V2KJ` (`spec/xcode-port.md`),
  no longer ad hoc.

**Installed:** `~/Applications/ShowTools.app` at `39fcbd6`, 2026-09-26,
signed with Jason's team. Every reinstall (`install.sh`) quits the real
BGTools and doesn't restart it: start it again from View ▸ Desktop Show….

**The real library** is a fresh one at the default path, `~/Pictures/ShowTools
Library.noindex` (12 files and one collection on 2026-09-26); the old one,
set aside 2026-09-24, is `~/Pictures/ShowTools Library (2026-09-24).noindex`,
untouched.

## What's next

No next task is chosen. Open, roughly in the order Jason raised them:

1. **The timeline's height** — agreed, not built (`spec/windows.md`, "Its
   height"): only as tall as its contents or smaller, rows scrolling;
   growing with its contents up to a ceiling (the viewer keeps about half
   the window); a new row scrolled fully into view.
2. **The windows pass** — planned (`spec/windows.md`, "The windows pass"):
   consistent panels, the layer hierarchy (panels cover Settings today),
   the settings-vs-preferences split, About ShowTools; with it the drawers'
   **sensitivity setting and practice drawer** (`spec/panekit.md`, "The
   clutch"), **light mode's translucency and a background-transparency
   setting** (item 34), and the **"Smart View"** preference.
3. **Slides as mini movies, the rest** (`spec/plan.md`): the Slide Editor
   as the Slide viewer's pop-out, maybe reordering in the viewer, and the
   framework for slides with more inside (portrait shots filling a
   frame). Also the drop onto a timeline with no show (item 33, option (b):
   the show creator), which waits on Smart View.
4. **Show Similar, thematic** (item 35): Vision's feature prints find
   bursts and near-copies, not themes ("dogs", "dogs sitting"); Jason
   wants it to surface a good next slide. Needs research and a talk.
5. **Large libraries** (item 36): scroll-scrubbing gets ahead of image
   loading. Measure once Jason sets up a big test library.
6. **The browser's header as a switcher** (item 38): clicked, a dropdown
   of which list to show.
7. **BGTools, items 23–25** (`spec/bgtools.md`, "Next up"): the one-click
   Control Center tile and its icon; per-screen stop — **both** the green
   switch and "Plays Nothing" (decided); Pan and Zoom, length and
   transition options once Quick Show's field list settles.
8. **ModKit** (items 26/27/29 moved out): Jason's standalone look
   auditioning app, planned with App Claude (`ModKit & DefaultsKit —
   Design Pass.md` in the repo root, untracked, his). Here, he mainly wants
   the glass buttons' corners less circular.

**Also open:** telling BGTools when a library moves (B7 left it; Jason not
sure it's needed); promoting a group to its own collection (`spec/plan.md`,
"Groups inside collections"); the Library pane and the browser as windows
of their own (`spec/windows.md`); Simple things fast, all three to be
built (`spec/simple-things-fast.md`, nothing left open).

### Parked for later

Not pressing; each wants a discussion or a plan before any code.

- **Plan the ReorderKit lift.** Drag-to-reorder into its own package,
  like PaneKit (a local package in the repo, its own tests and harness),
  for other apps. **No plan written yet** — only what would move:
  `ShowToolsCore/Reorder.swift` (+ `ReorderTests`) and
  `ShowToolsApp/ReorderDrag.swift`, with the grid's wiring in
  `LibraryGridView` (`startDrag`, `commitReorder`, `slot(at:)`, the
  fly-in and landing) as the part to turn into the package's API. App
  wording (`LibraryOrderNotice`) stays in ShowTools; the package only
  reports that a drag was refused where it was let go. Design, terms and
  dials: `spec/plan.md`, "Reordering".
- **Double-click inside a multi-selection** (Jason, 2026-09-26: "it's
  fine" as is — only if the wish comes up). Today the first click
  collapses the selection, so `quickLook(startingAt:)`, written to page
  through the whole selection, only ever gets one file from a
  double-click (true before the `dc7f620` fix too). The solution already
  imagined: delay the collapse only for a plain click on a tile that's
  already selected among others — a second click Quick Looks the whole
  selection, no second click collapses it once the double-click
  interval passes. Clicks on unselected tiles stay instant; the wait
  only shows as the *other* borders clearing late. (Finder is thought to
  open every selected file on such a double-click — unchecked.)
- **A shared type for "explainer" notices.** Two now: `CustomOrderNotice`
  and `LibraryOrderNotice` (`CollectionAdd.swift`) — after-the-fact
  explanations, one OK button, "Don't show this again". Worth one type
  with the defaults, and a line in `spec/conventions.md` §6. Jason also
  wanted their text centred; macOS 27's `NSAlert` left-aligns by default
  and has no setting for it (centring would mean restyling after
  layout, or our own panel) — parked with this. Also Jason, seeing one:
  macOS 27's alert puts the app icon alone in the top-left with empty
  space beside it — "maybe room for the App name or something". Another
  reason to consider our own panel for this type.
- **Pan and Zoom only zooms** (Jason, 2026-09-24): Auto is mostly a zoom,
  and Custom's pan is two small frames to drag in the inspector. Wanted: a
  direction, and aiming the zoom by clicking the image. In the plan, under
  Later.
- Image stickiness, a guided first run (`spec/first-run-brief.md`), and
  Flush presets from 2a.

## Still needs Jason's hands

- **The clutch's feel and dials** (`spec/panekit.md`): pulling, braking,
  flicking and swiping drawers, on every kind of handle; whether 64 pt and
  the slide's 0.18 s feel right; **a swipe's direction with natural
  scrolling** (synthetic swipes can't carry that flag).
- **Edit Slides playing** (`spec/plan.md`, "Slides as mini movies"): the
  Slide viewer (Y), looping the selection with Space, ↑ ↓ in the list after
  a click, the timeline live in both modes.
- **The grid's first click** — the border should draw at once.
- **BGTools under the new signature:** the Control Center tile (the
  extension re-registered on install) and BGTools' login item, which macOS
  may treat as new.
- **The Library grids' tools in the bar** (2026-09-26, Jason): the
  slider, Import, Add to Show and Get Info moved from the toolbar into the
  bar under the viewer drawer; the library panel's bar wraps to two rows.
  Checked with axtool and screenshots (both windows' layouts, the slider
  dragging with the drawer open and shut) — the buttons' own actions weren't clicked. Worth a look: the
  main window's title bar is now the plain one (no toolbar items in the
  Library view), so the "N items / N selected" subtitle is in the title.
- **The viewer drawer** (built 2026-09-26, `spec/plan.md` "The viewer
  drawer"): Y / ⇧Y, dragging and double-clicking the dark strip under the
  bar (its only handle: the sort strip in the grids, a 12-pt grip strip in
  the browser; the bar itself takes no drags), Side by Side
  and Stack, ← / → within the selection, in the Library grid, the library
  panel and Edit Show's browser — all checked with axtool and
  screenshots, never by a real hand in the app (the harness's handle was).
  Worth a look: whether the stack's cards (the next pictures, dimmed)
  read as a group at a glance; 12 videos side by side at once (not
  tried); and the browser's ← / →, which only work once its list has the
  keyboard — a real click on a row should give it that (a synthetic one
  doesn't; Tab did). The strip was checked in the grid (double-clicks,
  text included, and drags) and in the browser (double-click, drag), and
  the bar in both was checked to do nothing on a double-click or drag.
- **The inspector's stars after a rating key in the browser** (seen
  2026-09-26 while checking the viewer): "4" rated both picked files (the
  library says 4), but the inspector's Rating row for the selected slide's
  file still showed empty stars. Not investigated; may be the inspector
  not refreshing from the item.
- **BGTools: naming screens, the map view, the window opening on your
  screen** (built 2026-09-25, `spec/bgtools.md` items 3–5): renaming a
  monitor or a Space, the Map | List switch, and the window landing on the
  calling monitor with its Space selected — all confirmed by their actual
  effect with axtool against a scratch settings file (live updates, no
  relaunch needed; `settings.json` read back correctly), but this Mac has
  one monitor, so the parts that are *about* more than one — the map
  actually laid out to scale, the window really following the pointer
  from screen to screen, ⌥-double-click actually moving it there — are
  reasoned through from the code, not seen. Worth a particular look with
  a second monitor plugged in.
- **Edit Show's inspector popping out** (built 2026-09-25, View ▸
  "Inspector in Its Own Window," `spec/panekit.md` "The order" step 4):
  the window itself, the main window closing up, the popped-out content
  following the main window's selection, and — after a same-session fix,
  `UndoMenuState` (`spec/panekit.md`, "Pane ⇄ panel") — undo, all
  confirmed with axtool against a scratch library: `Edit ▸ Undo` reads
  the real action name and a real ⌘Z/⇧⌘Z from the popped-out window
  undoes and redoes the edit, checked against the saved show's JSON.
  Never confirmed by a real click, drag or keypress from Jason's own
  hands.
- **The timeline pane, full width under the Library pane, and popping
  out** (built 2026-09-25, `spec/panekit.md` "The order" step 5): sits
  at x=0, under the Library pane, not starting at the detail column's
  left edge; the library and detail panes grow to fill the window's full
  height when Edit Slides or the plain Library view closes it; View ▸
  "Timeline in Its Own Window" still pops it out as an ordinary window,
  now at its own full width; bare-key shortcuts (Space, J/K/L, M, I, O,
  N, arrows), Undo/Redo, and the Show/View menu's Play/Pause, Set Range,
  Zoom, Loop and Go Back/Forward items all still work from the
  popped-out window after the move; a real slide Delete shows the
  slide-removal notice and removes just that slide (not "Delete Show?" —
  a real race between two separate Delete-key handlers, found and fixed
  the same day), with ⌘Z putting it back. All confirmed with axtool
  against a scratch library. Never confirmed by a real click, drag or
  keypress from Jason's own hands.
- **Rating keys in Edit Show's browser** (item 20, 2026-09-26): its
  rows show stars and ✕, but a synthetic click on a row left the keyboard
  on the sidebar, so neither the new rating keys nor the browser's
  **older E/W/Q** fired — both need the browser's list to have focus
  (`listFocused`). Pre-existing, not changed. Worth one real click and a
  keypress: if they fail by hand too, the browser needs the grid's
  window-level `SingleKeys` approach.
- **The grid's keyboard** (built 2026-09-25, audit batch 7): arrow keys,
  Return-renames, and Quick Look on ⌘Y or a double-click — all confirmed
  by their actual effect with axtool (selection counts, the rename sheet,
  a screenshot of the right file in Quick Look, the panel really closing
  on a second ⌘Y even while it was the key window), never by a real
  keypress or click. Worth a particular look: whether `columnCount`'s
  worked-out math ever drifts from `.adaptive`'s own at an odd window
  width or thumbnail size (only the default 250pt tile size, at the
  window's default width, was exercised).
- **Drops onto slides and Replace Image…** (built 2026-09-24, plan.md
  "Replace a slide's image"): Replace Image… from all four menus (only
  the storyline's was actually clicked through), the storyline's drag
  Replace-or-Insert (a real internal drag confirmed both, but never
  watched by eye), and the Edit Slides list's own per-row drop (G2's
  fix) — not exercised at all, a cross-window synthetic drag wasn't
  practical to set up. Worth a particular look: whether the storyline's
  replace-zone highlight (a box around the whole slide) and the list's
  fixed 12pt insert bands feel right, and whether the pixel bands scale
  sensibly if a row's height ever changes.
- **Timeline keys** (built 2026-09-24, `spec/conventions.md` §2): arrow-key
  navigation across all four rows and Go Back/Forward — checked with
  axtool against a scratch library's saved state (times, the enabled/
  disabled menu items, `Edit ▸ Undo` staying off), never by a real
  keypress or a real look at the storyline. Worth a particular look: the
  empty-row deselect gap noted above, and whether Go Back's scroll
  restoration (the nearest slide, not the exact offset) feels right.
- **The whole range package, W6–W10** (built 2026-09-24, `spec/plan.md`
  "The range and the ruler" and "Fill the range with images"): dragging
  an end, the lock (right-click of either end, the shaded span or the
  button), I/O/⌥X still landing while locked, the range button's
  plain-click/⌥⌘-click/⇧⌥⌘-click/right-click, the shaded span's own
  right-click menu, double-clicking a song section to set the range, and
  the Fill Range with Images dialog itself — all reasoned through and
  checked with axtool against a saved show's `editor` and `slides` tables
  and screenshots, never by a real drag or a real modifier-click (axtool's
  `click` can't hold two modifiers at once, so ⌥⌘ and ⇧⌥⌘ themselves are
  unverified beyond their Show-menu equivalents). Worth a particular look:
  whether a real drag feels right — the synthetic one moved further than
  its own on-screen distance implied, which may just be a tool artifact;
  whether scrubbing still feels normal across the whole ruler now that the
  range's shaded span carries its own copy of the seek gesture alongside
  `RulerView`'s; the Fill dialog's Library tab and a Displace fill (only
  Collection and Replace were clicked through); and the one-slide-inside-
  the-range edge case in `RangeFill` (a second use of the same file for
  what continues past the range's end) — reasoned through and tested, but
  not something the plan itself spelled out, so worth Jason's own read.
- **The viewer's menus, Show in Library, and the progress line fix**
  (built 2026-09-24, `spec/conventions.md` §3, item 4): every menu opens
  with the right items and every action was confirmed by its actual
  effect with axtool (Rotation Handles and Slide Progress toggle and
  report back, Show in Library opens the panel and selects the right
  file, Hide/Show Frame Strip round-trips, the progress line fills left
  to right), but none of it has been used by a real click yet. Worth a
  particular look: the known, accepted limitation that the image vs.
  pasteboard menu goes by which image was last clicked, not by the
  right-click's own location.
- **Edit Slides', the browser's and the inspector's menus** (built
  2026-09-24, `spec/conventions.md` §3, items 3/5/6): Copy/Paste and
  Copy/Paste Settings, the quick-settings submenus, Use Defaults for All
  Slides, the browser's Select in Timeline/Play from Here/Remove from
  Show, and both inspector section menus — all confirmed by their actual
  effect with axtool (slide counts and settings genuinely changed, not
  just the menu opening), never by a real click. Worth a particular
  look: Copy/Paste Settings are meant to swap in over Copy/Paste only
  while ⌥ is held, but are built as four always-visible items instead
  (SwiftUI's `.contextMenu` can't declare AppKit's alternate items) — if
  that reads as clutter in practice, the ⌥-swap is its own follow-up.
- **The library panel** (built 2026-09-24, `spec/panekit.md`, "Step 4,
  second piece"): opens and shows the whole library correctly, checked
  with axtool against a scratch library, but a real drag from it (its own
  reason for existing — filling a new collection with the panel floating
  over it) hasn't been tried by hand.
- **The grid's list view at the size slider's minimum, and the panel's
  slider now independent of the main window's** (Jason, 2026-09-24,
  `spec/windows.md` answer 6): checked with axtool — dragging the slider
  to its floor and back switches cleanly between a single-column list
  (small icon, filename, full-width selection highlight) and the tile
  grid, selection carries across the switch; the library panel's slider
  and the main window's grid now keep their own sizes (`gridTileSize` vs
  `gridTileSize.panel`), checked with both windows open at once, one in
  list view and the other mid-size — but never watched by a real drag of
  the actual slider control.
- **Audit G1 and the audio-naming pass** (`7c1613a`, `dcf47c2`): both
  build and the app launches, but the hands-on checks weren't done this
  session — see the work queue above.
- **Context menus C1–C3** (Remove Image/Transition/Marker): build and
  test clean, but not confirmed by a real click — the storyline canvas
  resisted synthetic clicking this session.
- **Groups in the Library pane** (built 2026-09-24): drag-to-add from the
  grid and from Finder, nested folding, New Group naming, the delete
  notice's wording, the browser's group filter, and Keep as Group. Also
  new: **dragging a group onto another to nest it, onto its own
  collection to un-nest it, and onto a different collection**, with the
  "images will be added" notice and its suppression checkbox. All of it
  only smoke-tested (launch, no crash), not clicked by a person.
- **⇧-click in the Library grid and the storyline** (batch 4, built
  2026-09-24): `GridSelection`'s logic is unit-tested against the audit's
  own worked examples, but a real ⇧-click, ⇧-click, ⇧-click hasn't been
  tried by hand in either place.
- **The menus batch 5 built 2026-09-24**: the Show and View menu items,
  Get Info from a slide selection, Show ▸ Play starting at the
  selection, and Help ▸ Keyboard Shortcuts — all reasoned through and
  compiled clean, but a menu can only really be checked by opening it.
  Worth a particular look: the toolbar's Inspector button and ⌘1/⌘2 lost
  or gained their shortcuts moving to the View menu, so it's worth
  confirming nothing doubled up or went silent.
- **The Rhythm tool** (step 7): the panel's look (the space around the
  form, the notation's size: a staff space is 5.5 pt), Listen by ear on
  real music, Space stopping Listen, and whether 145 BPM is right for
  Fly Me to the Moon (or double).
- **Listening:** music sync, fades, crossfades; Bluetooth headphones'
  delay (the output latency is subtracted, but it's untested).
- **Inspector sliders' live preview** — built (`b66b4af`) but never
  watched by eye; the commit says so.
- **Dragging a song in from Finder or Music.**
- **Look and feel:** the row handles (10 pt wide), the drawers, the level
  line's handles, whether a line on every clip is too busy in the thin
  images row, and the transport's new toggles.
- **BGTools:** unlocking a private library with Touch ID, the panel
  closing on a click elsewhere, Space-switch pausing — not yet re-done
  against the nested BGTools.
- **From before Phase 3:** cross-app drags from Finder and Photos, Touch
  ID and the Mac's password, pinch, a second screen, cursors, and one
  real ⌘Z with the Info panel focused.

## Open questions

- **The selection viewer's name** (2026-09-26): the drawer over the grids
  is called the viewer in the menus and "the viewer drawer" in the plan,
  which clash with the anatomy's **Viewer** and **Drawer**; the anatomy
  says **selection viewer** for now. Edit Slides' drawer is the **Slide
  viewer**.
- **Map 1 (`spec/maps/1-library-grid.png`) is stale**: its source,
  `maps.html`, is current, but `render.js` needs Playwright, which isn't
  installed on this Mac.
- **Image stickiness (2c)**: should a lane image stay at its time on the
  clock, or move with the slide it starts over? For now it stays on the
  clock.
- **Settings: always on top, or an ordinary window?** (`spec/windows.md`,
  "The windows pass"; Apple's way recommended.)
- **What one slide's loop covers** — its own time cut to cut (as built) or
  its transitions too; waits on the mini-movies framework.

## Known issues

- **Right-click: places with no menu yet** show a greyed "No menu yet —
  place › area" note (`spec/conventions.md` §3; search `noMenuYet`,
  `ListEmptySpace`). Not covered yet: the timeline, the transport, the
  filter bar and sort strip, the defaults bar. Escape doesn't clear a
  timeline selection (`spec/conventions.md` §2 says it should).
- **A setlist exported before 2026-09-23 loses its Pan and Zoom setting on
  re-import**, silently (the rename, `spec/history/2026-09-23-pan-and-zoom-rename.md`).
- **Edit ▸ Undo was disabled once after a rating key**, on one test copy
  (2026-09-26), though ⌘Z had nothing to undo either; four later tries,
  including the same order of actions on a fresh launch, all showed
  "Undo Rate" enabled and undid correctly, with a probe confirming the
  step was on the key window's own undo manager. Not reproduced, not
  explained — suspect `UndoMenuState`'s tracking of the key window
  rather than the rating code, but that's unproven.

- **`LibraryLocation.isInICloud` loops forever on a path containing
  `..`** (`ShowToolsCore/Library.swift:50`): `deleteLastPathComponent` on
  `..` never shortens the path. Hit with a test launch path
  `…/Library.sqlite/..`: the app hung at 100% CPU before opening a window,
  and needed `kill -9` (and its launch note cleared). Not fixed.
- **Undo registered outside an event stays invisible to Edit ▸ Undo
  until the next event** (AppKit's automatic group stays open). Fixed for
  drag-to-reorder by an explicit undo group; other paths that register
  undo from a `Task` or after an `await` haven't been checked.
- **The layout-loop crash — fixed 2026-09-23, and its 2026-09-24
  recurrence also fixed.** `NSGenericException` from AppKit's layout-loop
  guard; root cause was SwiftUI's `.inspector()` modifier, fixed by
  porting Edit Slides' inspector onto `ColumnsSplitView`
  (`spec/edit-slides-inspector-port.md`). Recurred once more from a
  `SingleKeys` monitor on the sidebar `List`, fixed by moving it to the
  `NavigationSplitView`. **Lesson kept live:** `.background(SingleKeys)`
  is safe on a plain SwiftUI container, not on a `List` or anything else
  AppKit backs with its own constraint-based layout — check before adding
  one to Edit Slides' or the storyline's own Lists. Full story:
  `spec/history/2026-09-23-crash-hunt.md`,
  `spec/history/2026-09-23-crash-hunt-session2.md`,
  `spec/history/2026-09-23-crash-hunt-session3.md`.
- **Pulling the inspector's divider far to the left breaks the layout**
  ("smashes both sides out off the screen"). Seen once in a test copy
  dragging from the right edge to x=300. `revealByDragging` is the obvious
  suspect — it clamps the width it sets, but nothing re-checks the columns
  as a whole. Needs reproducing before anything is changed.
- **⌥⌘0 (Restore Default Layout) raised the layout-loop exception once**,
  and killed the app, on 2026-09-23: *before* the cause was confirmed as
  SwiftUI's `.inspector()` and fixed. Not seen since the fix; probably that
  same crash. The Library pane was a suspect only by coincidence (Jason). Its
  known bugs are display bugs. `DefaultLayout` still skips the Library pane on
  that stale reasoning, which is worth retrying.
- **A song lying wholly inside another** plays over it without crossfading
  (only a partial overlap crossfades). Level tops out at 100%.
- **The last slide cuts to the background** when something runs past the
  slides; a fade could come later.
- **The row drawers hold no controls yet.** Scrub audio isn't built;
  scrubbing is silent.
- **CPU** is about 33–37% while the editor plays; memory about 430 MB.
  BGTools' desktop mode is ~2% since B6, except while Pan and Zoom moves,
  which costs about 40% of a core because it really does redraw every
  frame — worth a look. It's why BGTools' random-mode default was flipped
  to `.off` 2026-09-23 (it's opt-in now, not a cost every random desktop
  show pays).
- **Video:** it can't go in the lane yet. The frame strip shows a video's
  first frame, the onion skin skips video slides, and `stcli render` draws
  a video slide as the background colour — only `stcli movie` and the app
  go through `MovieMedia`. A video slide's sound is decoded whole into
  memory when exporting; fine for slides, worth revisiting if whole films
  ever become slides.
- The zoomed-out work area doesn't draw a lane image's overhang past the
  frame.
- Accordion was dropped, and Page Curl is offered as "Page Turn".

## Test things installed on Jason's Mac

`ShowTools.app` in `~/Applications` (the real one, with BGTools and the
tiles inside), `build/DesktopProbe.app` (not running), and XcodeGen
(`brew install xcodegen`, required to build the app). **Apple's WWDR G3
intermediate certificate** was added to the login keychain 2026-09-26
(signing needs it). **ShowTools has the Accessibility permission**, granted
2026-09-26 for a drag-lock experiment that failed; nothing uses it now, so
Jason can switch it off. Xcode's own DerivedData build of ShowTools
(ad hoc, 2026-09-24) was deleted the same day. Stale Background Task
Management entries for `com.jhg.bgtools` and two `com.jhg.nestprobe` ids
remain — `sfltool resetbtm` would clear them but resets every app's login
items, so they are left alone.

## Quick start

```sh
swift test                                  # 336 core + 13 BGTools tests
(cd PaneKit && swift test)                  # 46 PaneKit tests
./make-app.sh                               # → build/ShowTools.app (signed, team P82S39V2KJ)
tools/make-test-library.sh <scratch>/STTest # scratch library + generated media
open -n --env SHOWTOOLS_LIBRARY=<scratch>/STTest/TestLib.noindex build/ShowTools.app
```

Before launching any test copy, read the `showtools-testing` skill: a test
copy shares Jason's preferences domain, and a crashed one shuts his real
app out.
