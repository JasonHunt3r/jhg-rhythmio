# 2026-09-25 — the feedback worklist, batches 1–5

Jason's own build feedback, `ShowTools Feedback — Worklist for Next CC
Session.md` (repo root), 37 items. Worked through in five batches, grouped
by shared code rather than the doc's own flat priority order. This is the
dated story — what was fixed, how, and what each fix was checked against.
Current state (what's done, what's left) lives in `spec/status.md`.

## Batch 1 — PaneKit / window-layer P0s

- **Item 9**, Settings panel off the bottom of the screen: the `Form` used
  `.fixedSize(vertical: true)` with no cap. Wrapped in a `ScrollView`,
  capped to the screen's visible height minus a margin. Checked with
  axtool: opens at 520x450, inside the visible frame.
- **Item 2**, a popped-out pane panel floating over other apps' windows:
  `isFloatingPanel` sets `.floating`, a *system-wide* window level, not an
  app-local one. Now drops to `.normal` whenever ShowTools isn't the
  active app, back to `.floating` when it is. Build-clean; not seen by eye
  against a real other-app window.
- **Item 11**, BGTools' window stranded on a monitor that gets unplugged
  while already open: `showWindow()` only recentered on the calling
  monitor when the window was (re)opened, not while already visible. Now
  listens for `NSApplication.didChangeScreenParametersNotification` and
  recenters onto the main screen if its own screen is gone. Reasoned
  through; untestable here with one monitor.
- **Item 1**, the collections column (Edit Show's list pane) growing when
  the inspector closes: `nearIsRigid` (`spec/panekit.md`, "Building a
  row") kept `near` fixed-width on a direct near|far *drag*, but a
  *collapse* skipped the link on purpose — closing the inspector still
  grew the list column. `PaneController.setOpen` now applies the same
  `linkedAncestor` delta a drag would, and `.row`'s comboRange floor
  drops to `near.minSize + handleThickness` under `nearIsRigid` so the
  stored value doesn't get clamped back up before it takes effect. Two
  new `PaneControllerTests` (in `PaneKit/Tests/`, run via `cd PaneKit &&
  swift test` — not part of the root `swift test`'s 306) pin it; both
  fail on the old code first. **Reverses the "divider isolation" trade
  `panekit.md` documented and confirmed by hand on 2026-09-24** — Jason's
  own feedback the next day called it wrong.
- Item 2's other half — a documented window-layer hierarchy and an audit
  of the other pop-outs — was left open; it's a writing task, not a bug.

**A preferences leak, caught and fixed mid-session:** testing item 1's
pop-out interactively wrote a scratch pop-out state into the *shared*
`com.jhg.showtools` preferences domain (`PaneKit.EditShowColumns` changed
from 141 to 140 bytes) — the exact trap `showtools-testing` warns about.
Caught by comparing against the pre-session `defaults export` backup and
restored immediately. Jason's real app was running throughout and
unaffected (its window never reopened mid-session).

## Batch 2 — library/collections interactions

- **Item 6**, clicking a use in Edit Show's list moved the playhead:
  `engine.showSlide(id:)` ran on every plain click. Now only on
  ⌥-click, reading `NSEvent.modifierFlags` live (the same trick
  `StorylineView`/`EditShowView` already use). Checked with axtool:
  selecting a later slide leaves the preview and timeline at 0:00; only
  the list selection changes.
- **Item 3**, clicking the library pane's background switched the detail
  pane to the plain Library grid: a plain `List(selection:)` clears its
  selection to `nil` on a background click, and `detailView`'s `default`
  case for a `nil` sidebar is the plain grid. The selection binding now
  ignores a `nil` write — there's always something selectable (the
  Library row itself). Checked with axtool.
- **Item 4**, no right-click response in the main window's background:
  the Library grid's near-invisible background layer (used for
  tap-to-deselect) had no `.contextMenu`. Added one: Import…/New
  Collection…/Add from Library…. Checked with axtool. The sidebar's own
  background right-click wasn't separately checked.
- **Item 5** turned out to be Jason's own mislabel, cleared up
  2026-09-25 in conversation: what he meant is item 12, not a naming
  bug. Verified anyway before that came up — drove the real menu path
  (right-click ▸ Add to Group ▸ New Group…) with axtool end to end,
  typed a name, confirmed the library's `groups` table held exactly
  that name. No code change.
- **Item 15**, the Library pane's minimum width (180) too wide: lowered
  to 140, both the split's range floor and the pane's own `minSize`.
- **Item 16**, deleting a collection or group always left the files
  behind: both now offer a real "Also delete the files/images from the
  library" checkbox. The collection-delete flow moved off SwiftUI's
  `.confirmationDialog` (can't carry a checkbox) onto an `NSAlert`, the
  same synchronous shape `GroupDeleteNotice` already used for groups —
  new `CollectionDeleteNotice` in `SlideInspector.swift`. Checked with
  axtool: the alert shows the checkbox with its own label, not the
  suppression button's default text.
- **Item 28**, "Change Library…" added to the library header's
  right-click menu (same action as File ▸ Open Library…).
- **Item 32**, ⌥-click a sidebar name (collection/group/show) jumps
  straight into its rename alert: `.simultaneousGesture`, not
  `.onTapGesture` (the latter would steal the List's own selection
  click). Checked with axtool: ⌥-click opened Rename Group directly.
- **Items 17 and 12 not started, on purpose.** Item 17 (reordering)
  needs a real ordering column — `collection_items`/`group_items` today
  only order by `added_at`, so dragging to reorder needs a schema
  migration (13 → 14), not just a UI change. Item 12 (groups don't
  create a library item) is explicitly flagged in the feedback doc's own
  Open Questions as needing a design pass first (the catalog pane's own
  list item per group, and where group selection hangs off the
  collections list column dropdown) — Jason confirmed this reading
  2026-09-25.

## Batch 3 — frames row / transport

- **Item 7**, the range Out marker sitting slightly left of its true
  position: `Path`'s own drawing coordinates for a `.frame()`'d shape
  aren't clipped or rescaled to that frame, so the out-marker's triangle
  (drawn pointing into negative x) bled outside its frame's nominal
  origin while the `.offset()` placement math still only cared about
  that origin. The in-marker's formula was already right; the
  out-marker's had an extra, wrong `- w` (7pt).
- **Item 8**, the frame strip's resize bar tracking the mouse at half
  speed: found with a temporary probe (logged to a file, removed after)
  that the gesture's own final `translation` topped out at half the real
  drag distance, at two different drag lengths (100pt → -50.0, 30pt →
  -15.0). Ruled out the synthetic-drag tool itself first — a control
  drag on a known-good PaneKit divider tracked a 40pt drag perfectly.
  Root cause: the bar sits between two views (the picture, the strip)
  whose sizes the drag itself changes, so the bar's own on-screen
  position moves mid-drag; its plain (`.local`) `DragGesture` was
  anchored to that moving frame — a feedback loop. Anchored to the outer
  column instead (`.coordinateSpace(name: "previewColumn")`), matching
  why `StorylineView`'s own drags are already named coordinate spaces.
  Also stopped writing `frameStripHeight` (`@AppStorage`) on every pixel
  of the drag, matching PaneKit's own "draw live, commit on release"
  dividers (not the root cause, but the same discipline). Checked with
  axtool: a 100pt drag now moves the bar exactly 100pt, both directions.
- **Item 18** (frames-row position marker draggable with live scrub):
  already built — `scrubGesture` on `RulerView` computes an absolute
  seek from `location.x` on every `onChanged`, not a click-only
  affordance. Checked with axtool: dragging from 0:00 toward the 0:20
  tick landed the playhead at 0:20.5, live. No change needed.
- **Item 19** (transport pane greyed-out state) not started, on purpose
  — it's the feedback doc's own Open Question 1, which the doc itself
  says needs a concrete interaction spec before CC can build it.

## Batch 4 — BGTools

- **Item 10**, BGTools couldn't be self-quit during the last rebuild:
  `install.sh` asked BGTools.app to quit only via `pkill` (no graceful
  `osascript` quit, unlike ShowTools right above it) and never touched
  `BGToolsControls.appex` at all — a Control Center extension runs as
  its own process, hosted by the system, not by BGTools.app, so
  reinstalling over it while it's still running is exactly this
  symptom. Now quits BGTools.app gracefully first, and `pkill`s the
  extension by its own path too.
- **Item 21** (launch + install from a ShowTools menu, plus a setting):
  "Desktop Show…" moved out of the View menu's toolbar group into its
  own top-level "BGTools" menu; a new Settings ▸ BGTools toggle,
  "Launch BGTools when ShowTools launches," starts it silently (no
  window) at ShowTools' own launch — separate from the existing "Open
  at Login" switch, which stays in BGTools' own window where it already
  was. Checked with axtool.
- **Item 22**, BGTools' window not staying visible across a Space
  switch: `canJoinAllSpaces`, the same treatment the Control Center
  panel already had.
- **Items 23–25 not started, on purpose.** 23 (Control Center tile
  needing two clicks, and a better icon) needs real hands and real
  Control Center registration to even reproduce — this environment
  can't drive Control Center's own UI, and the repo's own notes call
  that area cache-heavy and fragile; the icon half also needs Jason's
  own direction on what "better" means. 24 (per-screen stop) is a real
  feature — a new per-monitor toggle or a "Plays Nothing" list entry,
  model changes plus a UI decision the feedback doc itself frames as
  "two possible mechanisms, pick one." 25 (BGT pan & zoom, length,
  transition options matching ShowTools' own slides) is a sizable
  feature port, not a fix.

## Batch 5 — P2 polish

Jason chose this scope 2026-09-25 (asked directly): build the two real
code items, leave the rest for design direction.

- **Item 30** (frames row collapses to a stacked handle): the "collapse"
  half was already built — every PaneKit split collapses to its own
  edge handle by default — just not discoverable. Added View ▸ "Show
  Timeline" (⌘⌥T), matching Show Library/Frame Strip/Inspector's own
  toggles right above it. The "stacked" half depends on item 13
  (Collections' own closed-drawer state stacking against the closed
  inspector), which was never built either — a real, open-ended pattern
  to design, not touched here. Checked with axtool: toggling it
  collapses the pane (library/detail grow to fill the full height) and
  restores it correctly.
- **Item 31** (scale-to-fill, as a ShowTools effect and a BGT setting):
  already fully built, both halves, no change needed. `Fit.fill` has
  existed in the core model all along; ShowTools' own `SlideInspector`'s
  Fit picker already iterates every `Fit` case, and BGTools' Random
  Pictures settings (`MainWindow.swift`, `RandomPicturesDetail`) already
  has the identical picker. Same pattern as item 18 — feedback
  describing something the codebase had already caught up to.
- **Items 26, 27, 29 not started, on purpose.** 26 (kill the rounded
  header-bar controls for a tighter "Pro" look) and 27 (app-wide
  corner-radius override) are visual redesigns with no existing token to
  hang off, not fixes — guessing risks producing something that just
  looks wrong. 29 (an icon for each app) needs actual icon artwork, not
  code. All three need Jason's own direction first.

## What's left, going into the next discussion

- **Item 12** and **item 17** (batch 2) — need a design pass and a
  schema migration respectively.
- **Items 23, 24, 25** (batch 4) — need real hands, a mechanism choice,
  and a feature port respectively.
- **Items 26, 27, 29** (batch 5) — need Jason's own design/artwork
  direction.
- **Five Open Questions** from the feedback doc itself (greyed-transport
  drag target, glass/vibrancy in light mode, Show Similar's engine,
  large-library DB/indexing, the collections list column dropdown) —
  none buildable without Jason's call first.
- Item 2's window-layer hierarchy write-up and pop-out audit (batch 1).

Every fix above shipped as its own commit on `main`, pushed after each
batch; `swift test` (306 core + 13 BGTools, plus 23 in `PaneKit/` on its
own) and `./make-app.sh` stayed clean throughout.

## 2026-09-26 — items 26, 27, 29 leave the list for ModKit

Jason's answer to the proposal below: he is planning the value-changer
as **ModKit**, a standalone dev-tool app for auditioning look values,
with App Claude, in a plan doc of its own; its output goes back to Claude
Code or out as a file. So the three look items left this worklist. The
proposal as it stood, for the record:

- **Where the values live:** each look value a preference the views read,
  so a change shows live.
- **Where it sits:** a reusable package like PaneKit, opened from a Debug
  menu.
- **Keeping a value:** a "Bake" button copies the values out; Claude Code
  makes them the defaults in code, so the panel never becomes where the
  app's look lives.
- **First knobs:** control corner radius, header text size, control size
  (mini/small/regular), header spacing, container borders on/off (item
  26's "Pro" look).
- **Caution on item 27:** macOS draws a standard window's corner radius
  itself; changing it may need hacks — test before promising. Jason: what
  he mostly wants is the **glass buttons' corners less circular**, and
  he's curious whether AppKit's plain windows can be hacked too.

## Batches 6–8 (2026-09-25 late – 2026-09-26), moved from `spec/status.md`

Moved here word for word on 2026-09-26 when status was rewritten; the
current state of each item is in `spec/status.md` and the specs.

**Batch 6 — decided/built 2026-09-25** (this discussion):
- **Item 19** (transport greyed-out state) — **built**: the timeline
  pane's split now stays open in both edit modes (`MainView.isShowOpen`,
  was `isEditingShow`, gated on `mode == .show` too); Edit Slides shows
  `TimelinePanePlaceholder` (`EditShowTimelinePane.swift`), the same
  chrome dimmed and inert, instead of the pane closing and the window
  reflowing. Checked with axtool against the scratch library: the
  placeholder's "Switch to Edit Show to use the timeline" reads correctly
  in Edit Slides, and clicking back to Edit Show restores the real,
  interactive transport and storyline, screenshotted both ways. **Not
  what Jason meant** (2026-09-26): the rows should stay visible with only
  the tools greyed — item 33 in "What's next" reworks it.
- **Item 12** (groups → a library item / catalog folder) — Jason's actual
  intent was already built 2026-09-24 (the Library pane's collapsible
  groups-and-shows list); the only missing piece, the icon convention
  (solid folder for a collection, outline for a group), is **built**
  (`collectionRow` now uses `folder.fill`, confirmed by screenshot). The
  bigger idea Jason raised alongside it — **promoting a group to its own
  collection** — is still a design question (`spec/plan.md`, "Groups
  inside collections," "Promotion"): what happens to the original group,
  and whether nested sub-groups come along.
- **Item 17 / 38** (drag-to-reorder) — **built and tried by Jason's
  hand, 2026-09-25**: an empty gap follows the pointer, one drop handler
  for the whole grid, a drop saves what's on screen, Undo Reorder works;
  several files drag as a tidy pile with a count badge, fly in on pickup
  and spring into place on drop; the grid scrolls near its edges, faster
  and with the pile shrinking as it nears them. Design, terms and dials:
  `spec/plan.md`, "Reordering". Story: `spec/history/2026-09-25-drag-reorder-rebuild.md`.
  A drag let go over the plain Library says why (`LibraryOrderNotice`);
  a drag nothing takes, or Escape, puts the files back (no message for
  Escape); the plain Library's sort strip names the sort in use.
  Left: the parked list under "What's next".
- **Item 13** (the Browser's own closed-drawer state, stacking with the
  Inspector's handle) — **step 1 built**: a fix it needed first.
  Dragging the Inspector shut (or open from its handle) changed the
  Browser's width, though a double-click didn't — measured on Jason's own
  copy, 236 → 545 pt. PaneKit's drag now moves the linked split by the
  space the side occupies, the same arithmetic as `setOpen`
  (`dragResize`, `PaneContainerView.swift`; two new `PaneControllerTests`
  that fail on the old code). Checked on a test copy: 236 through open,
  drag shut, drag open, drag shut. **Step 2 built:** the Browser is a
  drawer. Edit Show's columns are two splits nested from the right
  (`EditColumnsLayout`, new split ids `columns.inspector`/
  `columns.browser`), so the Browser closes to its own handle, the two
  handles stack at the right edge when both are closed, and every open,
  close or drag of either goes to the preview. View ▸ Show Browser (⌥⌘B).
  Checked on a test copy: double-click the divider and the handle, drag
  shut and open with the Inspector open (it stayed 320), the menu item and
  ⌥⌘B, and a screenshot of the two stacked handles. **Step 3 built —
  switching sides, for every pane** (a PaneKit feature, `spec/panekit.md`
  "What every pane can do"): drag a pane across main and, once less than
  its starting size is left, it trades places and mounts on the opposite
  edge. Checked on a test copy: the Browser to the left beside the
  Library pane (screenshot), closed there (handle on the left edge),
  dragged back by its handle; the Inspector across to the left
  (Inspector | preview | Browser, screenshot). **Left for Jason's hands:**
  the feel of all three steps, and the panes not tried at all — the
  Library pane, the timeline (it can switch to the top now) and Edit
  Slides' inspector. No menu command or animation yet.
- **Item 14** (the inspector's header at the top when empty) — **built**:
  bar + message were one short stack the pane centred. The inspector is
  now top-aligned (`SlideInspector.body`), and the empty message is an
  overlay centred on the whole pane (Jason: align the header, don't
  stretch the message to push it up — a first try did that). Screenshotted
  empty and with a slide selected on a test copy.
- **Item 30, done properly** (the frame strip as a drawer; batch 5 had
  read it as the timeline) — **built**: Edit Show's picture and frame
  strip are a PaneKit vertical split (`PreviewLayout`,
  `model.previewPanes`), replacing the hand-made 12 pt bar. Dragged below
  10 pt the strip closes to its edge handle; View ▸ Show Frame Strip
  (⌥⌘F) and the strip's Hide item now close it to the handle rather than
  removing it; it can switch to the top; it starts at the old bar's saved
  height (`frameStripHeight`, now unused after that first read). Checked
  on a test copy: drag closed, double-click the handle, drag to 214, the
  menu item and ⌥⌘F, to the top and back (screenshot). **For Jason's
  hands:** PaneKit's divider is a 1 pt line with a 7 pt grab band, where
  the old bar was a 12 pt band (he'd found the system split line too
  fiddly) — if it's fiddly again, that's a PaneKit-wide grab-width change.
  **Resizing live, fixed the same day:** Jason found the frames didn't
  follow a resize. Measured with screenshots mid-drag: the height followed,
  but every frame was blank until the drag stopped (frames are cached at
  one exact size and rendering waits 120 ms for a drag to settle — true of
  the old bar too). `FrameCache.nearest(to:)` now stands in the closest
  cached frame, stretched, until the real one renders.
- **Items 23–25** — queued as their own BGTools work list, to pick up
  once the ShowTools fixes above are done: `spec/bgtools.md`, "Next up —
  queued 2026-09-25, after the ShowTools fixes."
- **Items 26, 27, 29 — moved out of this list 2026-09-26.** The live
  value-changer panel is becoming **ModKit**, a standalone dev-tool app
  Jason is planning with App Claude (a plan doc of its own, not in this
  repo yet): auditioning look values live, then sending the final values
  back to Claude Code or out as a file. The look asks wait for it. What
  Jason most wants from it here: **the glass buttons' corners less
  circular**; he's also curious whether plain AppKit windows' corner
  radius can be hacked. Item 29's remaining half (BGTools' icon and its
  Control Center tile) goes with item 23. The earlier proposal is kept in
  `spec/history/2026-09-25-feedback-worklist-batches.md`.
- **Item 2's other half** — grown into the windows pass in "What's next"
  (item 3 there). Audit facts found 2026-09-26: the Info panel, Rhythm
  panel, library panel and Slide Editor hide when ShowTools isn't
  frontmost (NSPanel's `hidesOnDeactivate`); the PaneKit pop-outs
  (Inspector, Timeline) stay visible and drop to `.normal`
  (`PaneWindows.swift`). And every one of them sits at `.floating` while
  ShowTools is active, above the Settings window (an ordinary window).
- **Item 37** (Quick Show scope) — settled: presets are separate from
  New Show…'s (`spec/simple-things-fast.md`).
- **Simple things fast** — Jason confirmed 2026-09-25 all three answers
  (guided first run, Quick Show, the levels) are to be **built**, not
  chosen among. Its doc's own "Still open" list has shrunk to one real
  question (presets shared or separate between Quick Show and New Show…).
- **Windows of their own** — the built pop-outs (Slide Editor, the
  library panel, the Inspector, the Timeline pane) don't cover the whole
  original list: **the Library pane itself** (the sidebar, not the
  separate floating Library panel) and **the Browser** (Edit Show's file
  column) still can't detach. Answer 7 (double-click's meaning) is also
  still genuinely undecided — not superseded by the pop-out work.
- **The feedback doc's five Open Questions** — all answered 2026-09-26
  (items 33–36 and 38, in "What's next").

**Item 20 — built 2026-09-26** (Aperture's conventions, decided with
Jason by Q&A). A rating belongs to the **file**, so it lives where files
do — the Library grid, the library panel, Edit Show's browser, and the
inspector/Info panel's stars — never the timeline, the viewer, the frame
strip or the player. Keys (`Rating.Key`, `ShowToolsCore/Rating.swift`):
1–5 rate, 0 clears, **9 rejects**, − / = step (− stops at unrated and
leaves a reject alone; = lifts a reject to unrated; Jason: "−= might have
to be contextual, we'll get to that if it arises"). **U** shows/hides the
ratings (View ▸ Show Ratings (U), the `showRatings` default); the Library
grid's tiles now show stars at all, on a fixed-height line so rows stay
level. **Y** (Aperture's Viewer key) is Jason's for the **planned drawer
viewer over the grids** (new asks, below) — build it with that. A reject
is **−1 in the existing `rating` column** (no schema change); the rating
filter is Show All / Unrated or Better (the default, hides rejects, and
what every saved filter's 0 already meant) / ★…★★★★★ / Rejected Only.
**U is window-wide on purpose** (Jason's fix the same night: U jumped
the sidebar to "Untitled Collection" by type-select, since a tile click
leaves it the keyboard): `MainView`'s own `SingleKeys` takes U in every
mode, and the grid's rating digits run ahead of its sidebar check — see
`showtools-gotchas`. Re-checked with the sidebar holding the keyboard: U
both ways, no jump, a digit rates, the search box still types "u".
Checked with axtool on a scratch library: 3, 5 on two files at once, −,
9 (the file leaves the grid), Show All (its red ✕), U both ways (the
default flips), =, ⌘Z/Redo Rate, and a screenshot of level rows.
