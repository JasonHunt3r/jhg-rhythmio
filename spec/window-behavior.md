# Window behavior: layers, Settings, the modal box, placement

**Status:** Built 2026-09-27 (the windows pass: panel hiding as a setting,
panels floating only while RhythmIO is active, Settings coming up
frontmost and uncovered, About, the tabbed Settings window, the drawers'
sensitivity setting, the Transparency module, `SettingsBox`, where these
windows open). **Open work:** see `spec/backlog.md` (B-13 one combined
Set Up Triggers control, B-35 Smart View, B-67 PaneKit's pop-outs and
Settings, B-71 the filter bar's seam, B-73 collapsed disclosures). Hands-on: `spec/shakedown.md`, "Windows and panes".

Moved out of `spec/windows.md` on 2026-09-28, word for word except "The
Transparency module", which is condensed here with its full story in
`spec/history/2026-09-27-transparency-rework.md`.

## The windows pass (planned 2026-09-26, the settled pieces built 2026-09-27)

Item 2's other half from the 2026-09-25 feedback worklist, grown by
Jason's answers into one pass over every window.

**Make the windows consistent, each defined by its purpose.** What the
code did before this pass (audited 2026-09-26): the Info panel, the Rhythm
panel, the library panel and the Slide Editor are `NSPanel`s that **hid**
when RhythmIO wasn't frontmost (`hidesOnDeactivate`); the PaneKit
pop-outs (the Inspector, the Timeline window) **stayed visible** and
dropped to `.normal` (`PaneWindows.swift`). Every one of them sat at
`.floating` while RhythmIO was active — **above the Settings window**,
an ordinary window.

**Jason's answers, the three settled ones — built 2026-09-27:**
- **Whether panels hide when RhythmIO isn't frontmost is a setting** —
  polite for some kinds of window — but **panels that take drops from
  other apps never hide** (the browser list, popped out, is a
  destination for files dragged from Finder). Built: `PanelHidingSetting`
  (`RhythmIOApp.swift`), an `@AppStorage` toggle in Settings' new
  "Windows" section, default on (matching the old hardcoded behavior).
  The Info panel, the Rhythm tool and the Slide Editor read it fresh each
  time they come to front, so toggling it while one's already open takes
  effect the next time it's raised. The library panel's `hidesOnDeactivate`
  is hardcoded `false` instead — Jason's own exception — where before it
  silently relied on `NSPanel`'s own default of `true`, the bug this whole
  item exists to fix.

  **A second, deeper half of the same bug, found from real feedback the
  same day** ("bringing the focus back to the settings should have also
  brought the other app windows back as a package"): `hidesOnDeactivate`
  only ever controlled *visibility*. All four hand-built panels
  (`InfoPanel`, `RhythmPanel`, `SlideEditorWindow`, the library panel)
  set `window.level = .floating` once, permanently — unlike PaneKit's own
  pop-outs (the Inspector, the Timeline window), which already drop to
  `.normal` when RhythmIO isn't active. A window level ranks *across
  every app on screen*, so with hiding turned off, a panel just sat
  floating above every other app's windows forever, not just RhythmIO's
  own — it never "left" when you switched away, so there was nothing to
  "bring back." Built `floatOnlyWhileActive` (mirroring
  `PaneWindowController`'s own pattern exactly): Info, Rhythm and the
  Slide Editor now drop to `.normal` whenever RhythmIO isn't active, back
  to `.floating` when it is. **The library panel is deliberately left
  out**: it's a drop target for files dragged from Finder, which makes
  *Finder* the active app for the length of the drag — dropping its level
  while inactive would sink it behind Finder's own window exactly when
  it's needed. Checked with a real Finder window dragged to overlap where
  the Info panel sat, `panelsHideWhenInactive` off (to isolate the level
  fix from hiding): before the fix, the Info panel stayed on top of
  Finder even after switching to it; after, it dropped behind, and
  reactivating RhythmIO brought it back in front together with the main
  window, "as a package."
- **Settings, opened from the menu or its key, comes up frontmost, and
  panels stop covering it.** Built as `SettingsWindowCoordinator`: every
  hand-built panel registers itself; whenever the Settings window becomes
  key, every registered panel drops to `.normal` (stepping aside without
  losing `hidesOnDeactivate`'s own state), and returns to `.floating` (if
  the app's still active) once Settings resigns key. Settings itself
  stays an ordinary window, per Apple's own guidance (Claude's
  recommendation, accepted): it can still go behind another window on
  request, unlike a permanently-floating one. **Two wrong versions before
  this one, both found by testing, not assumed correct from a clean
  build:** first, capturing `NSApp.keyWindow` from `SettingsView
  .onAppear` — wrong, the same class of timing gotcha `UndoMenuState`
  documents for `NSApp.keyWindow` (`spec/panekit.md`, "Pane ⇄ panel"): `.onAppear` isn't
  guaranteed to fire after the window's actually become key, so it
  silently captured the *previous* key window instead. Then, matching by
  title (`"<app name> Settings"`, what SwiftUI titled the window before
  it had tabs) — broke the moment Settings became a `TabView`
  (2026-09-27, below): the title now names whichever pane is selected,
  and "Library" collides with the main window's own title. Both found the
  same way: a real Info panel dragged to overlap a reopened Settings
  window, watched with screenshots — it stayed on top both times. Settled
  on `WindowAccessor`, an `NSViewRepresentable` that reads the actual
  `NSWindow` a hosted view sits in directly from AppKit, no guessing from
  timing or title at all; the window is captured once (a stable identity,
  even though its title keeps changing) and compared thereafter. **Scoped
  to this app's own panels** — PaneKit's own pop-outs (the Inspector, the
  Timeline window) aren't covered, since giving PaneKit a dependency on
  RhythmIOApp's Settings window wants a cleaner cross-package hook than
  this pass builds; worth a follow-up if it turns out to matter.
- **About RhythmIO** in the app menu — already there. SwiftUI's own
  default app menu provides it for free (confirmed with axtool: "About
  RhythmIO" sits right above "Settings…," exactly where you'd expect);
  nothing to build. "Install RhythmBG" (this doc's own guess at where it
  might live) doesn't exist as a menu item either — the RhythmBG menu's
  only item today is "Desktop Show…".

**A pro-style, tabbed Settings window — built 2026-09-27.** Jason: the
single scrolling form was "a settings default suitable for a simple app";
wanted a pro one instead, tabs across the top tried first (a left-side
category list is the fallback if a tab row ever gets crowded), grouping
related settings onto each page, and a wider footprint. SwiftUI's
`Settings` scene recognizes a top-level `TabView` and renders it exactly
the way every other Mac app's preferences do — icon tabs in the window's
toolbar, the title naming the selected pane, reopening on the last one
used (`com_apple_SwiftUI_Settings_selectedTabIndex`, its own new
preference key, entirely free) — matching the HIG language already read
out for the layer-fix discussion a day earlier, so no chrome had to be
hand-built.

The old sections became six tabs (`SettingsView`, `RhythmIOApp.swift`):
**Library** (its own section, unchanged), **Editing** (Tags, Collections,
Alerts — everyday behaviors while working in the library), **Playback**,
**Export**, **Windows** (this pass's own new section, and where the rest
of the windows pass will land), **RhythmBG** (its own tab since it's a
whole companion app, not one setting among others). Each page is
`SettingsPage`, a shared scrollable container capped under the screen's
menu bar and dock, at a wider fixed width (640, up from 520). The window
itself is deliberately not user-resizable
(`.windowResizability(.contentSize)` on the `Settings` scene, Jason: "no
case yet where I'm not thinking of it") — every native Mac preferences
window sizes itself to the selected pane instead of being dragged by
hand, and switching tabs now visibly resizes the window on its own,
confirmed with axtool (640×450 for Library, narrower pages shrinking to
fit their own shorter content).

**Broke, then fixed, the Settings-covering fix above.** Tabs mean the
window's title now names the selected pane instead of staying "RhythmIO
Settings" — exactly what defeated the title-matching version of
`SettingsWindowCoordinator`, found immediately by rerunning the same
Info-panel-overlap check after the redesign. `WindowAccessor` (above) is
what replaced it, and is unaffected by the title changing per tab, since
it identifies the window itself, not what it's currently called.

**Settled 2026-09-27, moot: the settings-and-preferences split.** Jason:
now that everything fits logically into the tabbed window, splitting them
apart solves nothing — the tab list already *is* the settings-vs-
preferences distinction, if one turns out to matter later, and today
nothing in it is document-specific (a show's own settings stay in its
inspector, a library's in its Info, same as always).

## A reusable modal box (built 2026-09-27)

Jason, looking at the drawer-sensitivity section on the Windows tab: it
wanted a **button** ("Set Up Triggers…") that opens the fine controls
(the engage-distance line, the Quick ↔ Smooth slider, the practice
drawer) "into a top level box, the kind that must be dismissed before you
can change focus to other windows" — his words for a true app-modal
dialog, not a `.sheet()` (which only blocks the one window it's attached
to). Framed as "kind of a new class of reusable case that will apply to
other items in the tabbed windows," not a one-off for this setting alone.

Built `ModalSettingsBox.present(title:content:)`: a plain `NSWindow`
(`.titled, .closable`), its content an `NSHostingController` wrapping
whatever SwiftUI view the caller hands it, shown with `NSApp.runModal(for:)`
— every RhythmIO window blocked, confirmed with axtool (a click on the
Library window's title bar while the box was open left it un-key;
`focused` still read the box).

**A real bug, found by testing, not assumed fixed on a clean build**: the
first version called `runModal` synchronously inside the same button-tap
that opened the box. It looked right — rendered correctly, did block
every other window — but **no input reached the box's own content**:
Done, the close button and Return all did nothing (dragging its title bar
did move it, but that's the window server's own doing, not proof the app
was receiving anything). Wrapping the `runModal` call in
`DispatchQueue.main.async` — starting the modal session only after the
tap that opened it has fully finished dispatching, not mid-dispatch —
fixed it; retested the identical scenario and both Done and the close
button worked. `spec/panekit.md`, "The clutch," has the fuller story,
including a second, false alarm (`axtool drag` not moving either fine
control after the fix, where a plain click did — `rhythmio-testing`'s
own "synthetic drag isn't proof," not a bug).

**Reversed the same day, once Jason tried it: "I was wrong about making
it demand the window."** Not app-modal after all. Renamed
`ModalSettingsBox` → **`SettingsBox`** (`SettingsBox.swift`) — an ordinary
window, tied to the *Settings* window's own lifecycle instead of blocking
every other one: closing Settings closed the box along with it, unless
the box reported unsaved changes, in which case it came to the front
instead of closing quietly out of sight with them.

**Reversed again, the same day, once Jason actually hit the gap this was
meant to cover.** He closed Settings while the box sat open but hidden
*behind* it — "I was able to close the whole shebang while the secondary
window was still in an unconfirmed state" — and asked for the alert-and-
bring-forward behavior above to catch that. Talking it through, he
proposed something simpler instead: "maybe it should persist above all —
most — windows until you click done. So you could keep it on top while
you try it on the real windows, then click done when you're satisfied."
That sidesteps the whole problem rather than reacting to it: if the box
can never end up hidden behind Settings (or anything else in the app) in
the first place, there's nothing for an alert to catch. Dropped the
Settings-lifecycle tie entirely — `SettingsWindowCoordinator`'s
`willCloseNotification` hook and `SettingsBox.settingsDidClose()`, both
built minutes earlier, came back out unused rather than left as dead
paths for a design that didn't ship.

`SettingsBox` is now an `NSPanel`, `.floating`, exactly the pattern this
app's own hand-built panels already use (Info, Rhythm, the Slide Editor)
— sits above every RhythmIO window including Settings, so it's never
hidden behind anything; closes only on its own Done or close button,
untouched by closing Settings or clicking through to a real drawer behind
it. `floatOnlyWhileActive` (`FloatingPanelActivation.swift`) keeps it
from floating over *other apps'* windows too — the same fix those panels
needed 2026-09-27 earlier the same day, reused rather than re-solved.

**A real bug found by testing, not assumed fixed on a clean build**: the
first cut set `panel.isFloatingPanel = true` and `panel.level = .floating`
*before* assigning `contentViewController` and calling `center()` — built
clean, and looked right (title bar, correct size, correct position), but
`CGWindowListCopyWindowInfo`'s own `kCGWindowLayer` read back `0` (an
ordinary window), not `3` (floating): stacked *behind* the Library window
the moment they overlapped on screen, confirmed by screenshot, not just
inferred from the number. Moving `isFloatingPanel`/`level` to *after*
`contentViewController` and `center()` fixed it — both apparently touch
the window's own attributes while laying it out, and the level has to be
set after whatever they do, not before. Retested the identical overlap
and the layer read back `3`.

The drawer-sensitivity section itself split in two: the Windows tab now
shows one combined **Responsiveness** slider (both dials' normalized
position moved together), and "Set Up Triggers…" opens
`TriggerBoundariesBox` — the line, the Quick ↔ Smooth slider and the
practice drawer, unchanged, just moved off the tab and into the box.

**Checked with axtool against a scratch library, carefully — Jason had
the real app open with an identical Settings window and box on screen at
the same default coordinates while this was being tested**, so every
check first read window positions by pid (`CGWindowListCopyWindowInfo`,
filtered to the scratch copy's own process) and dragged the scratch
copy's windows to a screen region proven not to overlap his, before any
click: reopening the box brings the existing one forward rather than a
second copy; the layer bug and its fix, above; the box stays layer-3
(floating) after clicking the Library window, and visually stays on top
of it, confirmed by screenshot; **closing Settings while the box is open
leaves the box open, untouched** — the whole point of this design; the
box's own Done button still closes it normally. Nothing in Jason's live
session was touched or seen.

## Where these windows open (built 2026-09-27, later still)

Jason: Settings should "always open centered in the triggering monitor
window," not restoring whatever position it was last left at across
launches — the default macOS `Settings` scene autosaves its frame
(`NSWindow Frame com_apple_SwiftUI_Settings_window`) and would otherwise
reopen wherever it was last dragged to, even on a monitor that might not
even be attached anymore. Mid-conversation, refined to "centered top
under main window bar" — horizontally centered, its top pinned just
below a main window's own title-bar-plus-toolbar height, not the screen's
vertical middle. Then, once the secondary box entered the picture: "the
launch of the secondary window needs to be relative to the current
position of the settings window" — it should follow Settings wherever
it's currently sitting, not recenter on the monitor independently.

Built `TriggeringScreen.swift`: `TriggeringScreen.current` (the screen
under the pointer right now, since that's where whatever just triggered
the window happened — falling back to the key window's screen, then
`NSScreen.main`) and `TriggeringScreen.barHeight` (88 pt, this app's own
title-bar-plus-toolbar height, measured from an axtool dump). Two
`NSWindow` methods hang off it: `positionUnderTriggeringMonitorBar()`
(Settings — centered on the triggering screen, top pinned under its bar)
and `positionUnderBar(of:)` (`SettingsBox` — the same idea, anchored to
*Settings' own current frame* instead of a screen, so it follows Settings
if it's been dragged). Neither restores a saved position — the doc
comment spells out the one-line way to add that back (`setFrameAutosaveName`)
if it's ever wanted.

**Two real bugs, both found by testing, not assumed fixed on a clean
build — both the same class of "too early" ordering bug this pass had
already hit once with the layer fix above:**
1. **Positioning Settings from the become-key observer alone did
   nothing** — the window kept opening at its old autosaved spot no
   matter what `barHeight` was set to (tried an absurd `400` as a canary;
   the position didn't move a pixel, proving the code wasn't running at
   all, not just computing wrong). Cause: `WindowAccessor` hands the
   window to `SettingsWindowCoordinator.captured` via `DispatchQueue.main
   .async`, so by the time it runs and installs the become-key observer,
   the window's *own first* `didBecomeKeyNotification` had already fired
   with nothing listening. Fixed by positioning directly inside
   `captured()` for the window's first-ever capture, not only from the
   observer (which still handles every later close-then-reopen, since by
   then it's already installed).
2. **The box centered on the screen's raw midpoint, not its own size** —
   positioning it right after `contentViewController` (or even right
   after `makeKeyAndOrderFront`) read `frame.size` as still `.zero`, the
   panel's own initial `contentRect`: assigning `.contentViewController`
   after creation, rather than through `NSWindow(contentViewController:)`,
   doesn't resize the window to fit it synchronously. Fixed the same way
   `captured()` already needed to be: deferred one run-loop turn with
   `DispatchQueue.main.async`, after `makeKeyAndOrderFront`, giving that
   resize time to actually happen first.

**Checked with axtool against a scratch library** (Jason's own app wasn't
running by this point, so no overlap risk this time): Settings opens at
the screen's horizontal center, top pinned under the monitor's bar,
matching the math exactly; dragging it to an arbitrary spot and then
opening the box from its Windows tab lands the box centered under
*Settings'* new position, not the screen's — also matching the math
exactly (worked through by hand: `rf.midX - width/2`, `rf.maxY - barHeight
- height`, converted between AppKit's bottom-left screen coordinates and
`CGWindowListCopyWindowInfo`'s top-left ones to compare against what
actually showed up on screen); closing Settings still leaves an already-
open box alone; the box's own Done button still closes it. Never opened
by a real hand.

**The header bar's title, same session**: Jason: "the header bar should
say: RhythmIO Settings: XXXX," not just the tab's own name — the HIG's
"title naming the pane" reads as "Library," full stop, indistinguishable
at a glance from the main window's own title (the Settings-covering fix,
above, flagged this exact collision as one reason title-matching
couldn't identify the window — this doesn't change that; the window's
still found by identity, never by title). `SettingsWindowCoordinator
.applyTitleFormat` prefixes it with `"RhythmIO Settings: "` — applied
once immediately on capture, and kept up through every tab switch after
that with a KVO observation on the window's own `title` (there's no
"tab changed" notification to hook instead), a plain prefix check making
the observer's own re-entrant call (setting the title again inside its
own KVO callback) a harmless no-op. Checked with axtool against a scratch
library: opens as "RhythmIO Settings: Windows," reads "RhythmIO
Settings: Library" after clicking that tab, "RhythmIO Settings:
Playback" after that one — the collision is gone too, cosmetically,
though nothing here depends on that.

**`SettingsBox` titles itself after the tab it came from, same
session** — first cut: Jason: "for the secondary windows use the tab
name. eg: Windows: Set Up Triggers." `SettingsWindowCoordinator
.currentTabName` read the tab name back out of Settings' own
already-formatted title; `SettingsBox.present` prefixed whatever title
it's given with `"<tab>: "`. Checked with axtool against a scratch
library, again alongside Jason's own live session — opened the box from
the Windows tab, titled "Windows: Set Up Triggers."

**Corrected minutes later**: "it should be the module it came out of, in
this case Drawer Sensitivity" — the tab (Windows) isn't the same thing as
the section within it the box actually belongs to (Drawer Sensitivity),
and nothing about the window it's launched from can name that
automatically. `currentTabName` came back out; `SettingsBox.present`
takes an explicit `section` parameter instead, supplied by whoever calls
it — the Windows tab's "Set Up Triggers…" button passes `"Drawer
Sensitivity"`. Left open in a scratch test copy (not installed) for
Jason to check directly rather than described back to him: confirmed the
header bar reads "Drawer Sensitivity: Set Up Triggers." "It's good."

**Goes in the same pass, in the order Jason chose to take them
(2026-09-27):**
1. ~~The drawers' sensitivity setting with its practice drawer~~ — **built
   2026-09-27**, in the Windows tab (`spec/panekit.md`, "The clutch," has
   the story; Jason checked its feel by hand 2026-09-28). Its
   fine controls moved into the new modal box the same day (above).
2. **Light mode's translucency and a window-background transparency
   setting** (item 34, Jason: light mode "is awful"): built, then reworked
   the same day into the Transparency module, below.
3. The "Smart View" preference (panes open and close by context — on by
   default — or keep your own choices; `spec/slides-as-mini-movies.md`,
   "Smart View") — **wants fleshing out**: today it's a one-paragraph
   sketch, not a build plan (`spec/backlog.md`, B-35).

## The Transparency module

Condensed 2026-09-28; the dated back-and-forth is
`spec/history/2026-09-27-transparency-rework.md`.

- **What it is** (Jason's titles): on the Windows tab, an Appearance
  switch picks Light or Dark (the Mac's own to start) and shows that
  appearance's own **Panel Transparency** (every bar content scrolls
  under), **Title Bar Transparency** (the main window's title bar and
  toolbar) and **Include handles**. The sliders read as transparency
  (100% see-through); the setting stores opacity.
- **Scope: only bars with content scrolling under them** (Jason: "real
  macOS translucency only shows up noticeably on toolbars or header bars
  that scrolled content passes under — everywhere else it's too subtle to
  matter"). The first cut (three channels, four assignable regions) was
  over-scoped and is unwired.
- **Kept, dormant, on purpose:** the three-channel engine
  (`TranslucencySetting.swift`, `TranslucentBackground.swift`) for a
  future Slide Editor tool applying the same kind of effect to slide
  images; the per-pane identification hooks (`WindowAccessor`).
- **`.withinWindow` blending** samples the scrolled content behind a bar
  in the same window (the grid's filter bar). **It never composites over
  a `List`'s `NSTableView`** (measured, nested and as a sibling), which
  is why the sidebar and the browser left `List` for ListKit
  (`spec/listkit.md`).
- **A pane under the title bar** is PaneKit's `Pane.scrollsUnderTitleBar`
  (`spec/panekit.md`), with a runtime override: `ShowView` turns it off
  for `detail` while a show is open, since a show has a real toolbar of
  its own.
- **Found and still open:** the filter bar's seam at 100% (B-71); some
  collections' disclosures rendering collapsed on a fresh launch (B-73).
  Window-wide arrow-key monitors racing the sidebar's: settled
  2026-10-02 by `KeyboardArea` (the area last clicked owns the arrows).
