# 2026-09-27 (evening): empty bands, the timeline's height, ListKit, the browser, transparency

A session that started from an annotated screenshot ("please save my
bacon") and kept going. Current state is `spec/status.md`; the designs are
in `spec/panekit.md`, `spec/listkit.md` and `spec/windows.md`.

## What was built, in order

| Commit | What |
|---|---|
| `68af157` | PaneKit: a container reserves only the title bar it sits under — every container, nested ones too, had been reserving the whole strip (one band per container) |
| `128d07a` | Timeline: fits its content — StorylineView measured itself to size itself (latched at one row); ContentTracking never capped a stored size at the content; the transport was 30 pt, not 56 |
| `646a4b6` | PaneOutline: chevrons and indents for a hand-rolled sidebar (DisclosureGroup hangs its chevron outside the row outside a List) |
| `603ca00` | The rest of List's freebies, on SwiftUI focus: arrows with repeat, ←/→ folding, ⌥ branches, type-select, grey unfocused highlight, right-click ring; the Library grid had been taking the sidebar's arrows |
| `08efa8f` | Inline rename (⌥-click, Return, right-click Rename); the alert removed |
| `e6027ea` | Each row one VoiceOver element |
| `a8fd905`, `a3d8112` | The timeline stays open with no show, greyed, with its default rows |
| `c8a6101` | The translucency slider previews live |
| `19cd57e` | ListKit split out of PaneKit |
| `be050a3`, `8a54443` | Include handles, then reaching every handle row (PaneKit's through `PaneHandleAppearance`) |
| `e125373` | A hover handle row on open drawers' dividers; the pill drawn above the material |
| `a16a11a`, `bfd4d84` | ListKit multi-select; Edit Show's browser off List |
| `a94be7b` | The Transparency module |
| `7358b01`, `fa12ccc`, `eaaeec6`, `8db6536` | The timeline with no show can't be dragged past its content; the breather (12, then 8); the pane's height measured, not added up |
| `ea7c889` | The Library grid's header row, replacing a leftover title-bar spacer |

## What it taught

- **A feature confirmed only in a harness can be inert in the app.**
  PaneKit's scroll-under-the-title-bar passed in the harness, where the
  container is the window's content view; in the app SwiftUI's safe area
  already puts it below the title bar, so it never reached it, and the
  spacer built to go with it was just an empty band.
- **Self-measurement loops.** A view sized from a measurement of itself
  settles at whatever floor it starts from.
- **Test copies**: a failed build plus a relaunch left two copies on one
  scratch library, which silently broke every pid-based check; a drag in
  one landed on a grid tile and left a modal alert that blocked quitting.
  Check the copy count after every launch. After a layout change (the
  inspector toggling), re-find coordinates before every click.
- **SwiftUI gestures**: a list-wide tap gesture swallowed child taps; a
  child's tap beats its parent's (a name's tap had to select too); a tap
  catcher behind a ScrollView never sees its empty space.
- **Focus**: a text field focused in the same pass it appears doesn't take
  while a focusable list holds the keyboard — one runloop later does.

## Moved in from status, word for word

**Built most recently (2026-09-27, later still)** — `spec/windows.md`, "A
reusable modal box"; `spec/panekit.md`, "The clutch": the drawer-sensitivity
section split in two — the Windows tab now shows one combined
**Responsiveness** slider, and a **"Set Up Triggers…" button** opens the
line, the Quick ↔ Smooth slider and the practice drawer in a new
**`SettingsBox`** — a reusable case meant for other settings items too,
not just this one. Went through three shapes the same day: **app-modal**
first (`NSApp.runModal`, every ShowTools window blocked) — found and
fixed a real bug (blocked every other window correctly but took no input
itself, until the modal session started on the next run-loop turn
instead of synchronously inside the button tap that opened it) — then
**tied to Settings' own lifecycle** once Jason said "I was wrong about
making it demand the window" — then, once he found that could hide the
box *behind* Settings unconfirmed, **a floating panel** instead, his own
idea: "persist above all — most — windows until you click done," so
nothing can ever hide it, sidestepping the problem rather than reacting
to it. Found and fixed a second real bug the same way: `isFloatingPanel`/
`level` set *before* `contentViewController` and `center()` silently
didn't stick (`kCGWindowLayer` read back `0`, not `3`) — moving them
*after* fixed it. Checked with axtool against a scratch library,
carefully: Jason had the real app open with an identical Settings window
and box on screen at the same default coordinates, so every check first
read window positions by pid and moved the scratch copy's windows to a
region proven not to overlap his, before any click. Confirmed: the box
stays open and untouched when Settings closes (the point of the whole
redesign); it stays layer-3 after clicking through to another window; its
own Done button still closes it normally; reopening it brings the
existing one forward rather than a second copy. Nothing in Jason's live
session was touched.

**Then, once Jason was done using it and had closed his own copy**:
where these two windows open (`spec/windows.md`, "Where these windows
open"). Settings now always opens centered under the triggering
monitor's own bar (`TriggeringScreen.swift`) rather than restoring its
autosaved position across launches — refined mid-conversation from
"centered in the triggering monitor" to "centered top under main window
bar," then again once the box came up: "the launch of the secondary
window needs to be relative to the current position of the settings
window," not the monitor — so `SettingsBox` now follows wherever Settings
currently sits (`positionUnderBar(of:)`), including if it's been dragged.
Two more real bugs found by testing, the same class as the layer bug
above — something set too early, before the window was actually sized or
shown: Settings' own positioning silently did nothing at all (proven with
an absurd canary value that changed nothing) because the observer that
was meant to apply it wasn't even installed yet when the window's first
`didBecomeKeyNotification` fired — fixed by positioning directly on
first capture instead of only from that observer; the box centered on
the screen's raw midpoint, not its own size, because `frame.size` still
read `.zero` immediately after creation — fixed by deferring a run-loop
turn, the same fix `captured()` already needed. Also: **the header bar
now reads "ShowTools Settings: Windows"** (or whichever tab), not just
the tab's own name — a KVO observation on the window's `title` reapplies
the prefix after every tab switch, since there's no "tab changed"
notification to hook instead. All four confirmed with axtool against a
scratch library, no overlap risk this time (Jason's own app wasn't
running).

**One more, right after**: `SettingsBox` titles itself — first cut, after
the tab it opened from ("Windows: Set Up Triggers"), confirmed with
axtool against a scratch library alongside Jason's own live session
again (both landed at the exact same deterministic spot, confirming the
earlier positioning fix holds for him too). **Corrected minutes later**:
"it should be the module it came out of, in this case Drawer
Sensitivity" — the tab isn't the section. `SettingsBox.present` now takes
an explicit `section` parameter instead of reading the tab name back out
of Settings' own title; the Windows tab's button passes `"Drawer
Sensitivity"`. Left open in a scratch test copy for Jason to check
directly rather than described back to him: "it's good" — header bar
reads "Drawer Sensitivity: Set Up Triggers."

- **The filter bar's translucency slider** (rework, 2026-09-27,
  `spec/windows.md` item 34 has the whole story — the three-channel,
  four-region version it replaced, and why). Now: one slider per
  appearance on the Windows tab directly (no secondary window), 0 (native
  material) to 1 (fully opaque), with a live preview swatch next to each.
  Confirmed with a scratch library: real Library-grid tiles genuinely
  scroll up and pass under the bar, sampled live (`.withinWindow`
  blending) — a colorful tile's top edge visibly bleeds through as it
  scrolls by. **Not yet right**: at 100% opacity, which should be fully
  solid, a thin sliver of the row above still shows through at the exact
  seam between the bar and the grid — not explained by `sortStatusBar`'s
  own separate opaque background (checked, unrelated). Needs a fresh look
  with screenshots at a few scroll positions and opacity values before
  the code is touched again, rather than more guessing. Also unconfirmed:
  the two Dark/Light sliders' values, by feel, once the seam is sorted.
  Reverted cleanly: Catalog, Inspector and Panels are back to their exact
  original rendering (no `TranslucentBackground` anywhere on them);
  `TranslucencySettingsBox.swift` (the old region-picker UI) is deleted;
  `TranslucencySetting.swift`/`TranslucentBackground.swift` (the
  three-channel engine) are kept, explicitly marked unwired, reserved for
  a future Slide Editor tool. `HeaderBarBackground.swift` stays installed
  but dormant. A `fullSizeContentView` + `.ignoresSafeArea` attempt at
  giving the header bar real scrolled content underneath it was tried and
  reverted — zero visible effect on a scratch copy either way; PaneKit's
  own layout math would need to learn about a title-bar inset for that to
  work, which is its own harness-tested task — **built the same day
  anyway**, once Jason proposed doing it properly: `PaneKit.Pane
  .scrollsUnderTitleBar` (`spec/panekit.md`, "A pane under the title bar";
  53 PaneKit tests including two new ones). Confirmed first in the harness
  (a new "A pane under the title bar" shape — a marked pane's colour
  genuinely bleeds through a translucent strip over it, its sibling
  untouched), then wired into the real app: `AppModel.mainPanes`' `detail`
  pane carries the flag, and the same filter-bar `ScrollBarBackground` now
  covers a spacer over the title bar too, one continuous surface, one
  slider. `HeaderBarBackground.swift` (the old one-off hack) is deleted.
  Confirmed with a scratch library: tiles scroll up through the taller
  combined region; the library pane sits exactly where it always did.
  **Also found**: Jason's own real, running app still had the *old* build
  during this whole rework — his earlier tint experiment (red, ~89%) was
  still live on the Inspector panel in his session, since nothing had been
  reinstalled yet. Resolved once the new build installed.

  **The Catalog itself, same day**: Library and Collections are pinned at
  the top (`libraryList`'s own `.safeAreaInset`, not a `List` row any
  more — `libraryRow`, with its own manual selection highlight), the
  three Catalog bars carry `ScrollBarBackground.sidebar`
  (`.behindWindow`). Jason asked for the grid's own dramatic
  `.withinWindow` look on these bars too, matching Notes' toolbar;
  measured that `.withinWindow` never composites over a `List`'s
  `NSTableView` regardless of view-tree position (two real structural
  attempts, `spec/windows.md`), and that Notes' actual look comes from a
  genuine `NSToolbar`'s own privileged window-chrome compositing, not a
  content-level effect view — a real architectural step against PaneKit's
  whole reason for existing. Declined; his own follow-up instead: "why
  can't we just add the transparency characteristic to any bar that is in
  a scroll behind position?"

  **Answer, built the same day**: the Catalog no longer uses `List` at
  all. Jason: "as long as we're making something reusable for future apps
  using PaneKit. We're basically writing this into PaneKit, right?" — yes:
  `PaneKit.PaneListNavigation` (`spec/panekit.md`, "Arrow-key navigation
  for a hand-rolled list") gives a plain `ScrollView` the one thing
  `List(selection:)` gave for free that nothing else does — arrow keys
  step the selection, scrolled into view — proven first in the harness (25
  and 35 consecutive Down presses landed exactly on Row 25 and Row 35),
  6 new PaneKit tests (65 total). `libraryList` is a `ScrollView` now;
  every row carries `sidebarRowChrome` (manual selection highlight and
  tap, replacing `.tag`/`.badge()`); `visibleSidebarOrder` computes the
  fold-aware flat order. Context menus, rename-on-option-click, drag and
  drop, the recursive `DisclosureGroup`s — all unchanged, none of it was
  ever `List`-specific. `.onDeleteCommand` is gone, redundant: the
  window-wide `SingleKeys` Delete/⌘Delete fallback already covered every
  case unconditionally once `firstResponder is NSTableView` can never be
  true here again.

  **Confirmed on a scratch copy** (the seeded 25-collection library): rows
  genuinely scroll behind a visibly translucent bar now; arrow keys from
  launch land on Library first, then step through collections/groups/shows
  in drawn order, auto-scrolling correctly; a click selects and updates
  the detail pane; Delete on a selected group raised the real confirmation
  dialog (in its own separate window — worth remembering to check for
  next time nothing seems to happen). **One real, unresolved side
  effect, confirmed**: `LibraryGridView`'s own keyboard shortcuts are
  guarded by that same `firstResponder is NSTableView` check (meaning
  "suppress while the sidebar has focus"), which a plain `ScrollView`
  sidebar has no equivalent for — an arrow key sometimes moved the
  *grid's* own selection instead of the sidebar's, a real monitor race
  between `PaneArrowKeys` and the grid's own, not just a theoretical gap.

  **A real bug in the fix, found immediately after installing**: Jason —
  "no transparency from the library headers with scrollbehind content."
  Both Catalog bars were still calling the now-deleted
  `ScrollBarBackground.sidebar` (`.behindWindow`) — left over from before
  the migration, never switched to the plain `ScrollBarBackground()`
  default (`.withinWindow`) the whole migration was *for*. Fixed;
  `.sidebar` removed from `ScrollBarTranslucency.swift` entirely, nothing
  needs it any more. **Not yet re-confirmed visually** — synthetic clicks
  and arrow keys landed inconsistently in the sidebar in this same
  session (the monitor race above), so this is reasoned from the code
  (the identical mechanism already proven twice: the grid's own filter
  bar, and the PaneKit harness demo) rather than screenshotted again.
  Worth Jason's own look.
