# 2026-09-27 — the windows pass, the settled pieces

A dated record. Current rules and state are elsewhere: `spec/windows.md`
("The windows pass"), `spec/status.md`.

Jason: do the settled pieces of the windows pass first, then flesh out
the rest. `spec/windows.md`'s own "Jason's answers" from 2026-09-26 had
three pieces already decided (panel-hiding as a setting, Settings coming
up frontmost with panels stepping aside, About ShowTools) and several
bundled into "the same pass" that each want their own discussion
(settings-vs-preferences, drawer sensitivity, light-mode translucency,
Smart View) — built the three settled ones, left the rest open.

## Panel-hiding as a setting

Audited first: the Info panel and the Rhythm panel (`InfoPanel.swift`,
`RhythmPanel.swift`) set `hidesOnDeactivate = true` explicitly; the
library panel and the Slide Editor (`Libraries.swift`,
`SlideEditorWindow.swift`) never set it at all, relying on `NSPanel`'s
own default, which is also `true` — meaning the library panel already
had the exact bug Jason's answer exists to fix (a drop target that
vanishes when ShowTools isn't frontmost), just never triggered because
nothing had reason to leave it open while dragging from Finder yet.

Built `PanelHidingSetting` (`ShowToolsApp.swift`): an `@AppStorage`
toggle, default on (matching the old hardcoded behavior, so nothing
changes for anyone who doesn't open Settings), read fresh each time a
panel comes to front rather than only at creation — so toggling it while
one's already open takes effect next time it's raised, not just on a
fresh launch. Info, Rhythm and the Slide Editor all read it now; the
library panel's `hidesOnDeactivate` is hardcoded `false` instead, Jason's
own stated exception, made explicit rather than left as an accident of
the default. A new "Windows" section in Settings holds the toggle.

## Settings stops being covered by a floating panel

The audit also confirmed the other half of the bug: every panel sits at
`.floating` while ShowTools is active, and Settings is an ordinary
window, so a panel left open always drew over it. Jason accepted Claude's
recommendation from the earlier session (Apple's HIG way: Settings stays
an ordinary, non-modal window, not a permanently-floating one) — the fix
is narrower than that: panels step aside *while Settings is key*, not a
change to what kind of window Settings is.

Built `SettingsWindowCoordinator`: every hand-built panel (Info, Rhythm,
the Slide Editor, the library panel) registers itself on creation.
Whenever any window becomes key, if its title matches `"<app name>
Settings"` — exactly what SwiftUI itself titles the window it makes for
the `Settings { }` scene — every registered panel drops to `.normal`;
when Settings resigns key, they return to `.floating` (if the app's still
active) or stay `.normal` (if not, respecting the *other* setting).

**First version was wrong, found by testing rather than assumed
correct.** It captured the Settings window by reading `NSApp.keyWindow`
inside `SettingsView`'s own `.onAppear` — reasoned to be safe at the
time ("it just became key to show this view at all"). Built it, ran
`swift build`/`swift test` clean, then actually tried it: opened Settings,
opened the Info panel, dragged it (via a stepped `axtool drag` on its
title bar, watched with screenshots) to overlap where Settings would
reopen, reopened Settings from the menu — and Info stayed on top,
unchanged. Reread `ShowToolsApp.swift`'s own `UndoMenuState` and found
the answer already documented three lines away: `.onAppear` isn't
guaranteed to fire *after* the window has actually become key, the exact
same class of timing gotcha that file already works around for
`NSApp.keyWindow` elsewhere. The capture had silently grabbed whichever
window was key a moment *before* Settings took over (the Library window,
in the test), so the coordinator was always comparing against the wrong
window and never once matched the real Settings window.

Rewrote to match by title, checked fresh at every key-window change
instead of captured once — removes the `.onAppear` dependency (and the
capture step) entirely. Hit a second, smaller issue on the way: Swift 6
won't let a non-isolated notification closure send the window itself
across into `MainActor.assumeIsolated` (`UndoMenuState`'s own comment
warns of exactly this) — worked around by reading `.title` (a plain,
`Sendable` `String`) *before* crossing into the isolated closure, the
same shape as the fix already used for `ObjectIdentifier` in an earlier
draft of this same file.

Retested the identical scenario after the rewrite: Info panel dragged
over where Settings reopens, Settings brought back via the menu — this
time Settings drew on top, Info's edges peeking out from behind it. Fixed.

**Scoped to this app's own panels.** PaneKit's own pop-outs (the
Inspector, the Timeline window) aren't covered — PaneKit doesn't know
Settings exists, and giving it that dependency wants a cleaner
cross-package hook than this pass builds. Noted in `spec/windows.md` as a
possible follow-up.

## About ShowTools — already there

Before writing anything, checked with axtool rather than assumed: opened
the app menu and read its contents directly. "About ShowTools" was
already sitting right above "Settings…," SwiftUI's own default app-menu
item, working correctly with no code at all. `spec/windows.md`'s own
phrase, "perhaps where 'Install BGTools' lives," turned out to describe
something that doesn't exist either — the BGTools menu's only item today
is "Desktop Show…". Nothing to build; the doc now says so plainly instead
of listing it as an open task.

## Checked

`swift build` clean throughout (one real compile error along the way —
the Sendable diagnostic above — fixed before moving on). `swift test`:
336 core tests unchanged after every round. Both fixes confirmed against
a scratch library with axtool: dragging a window's title bar with a
stepped drag and screenshotting at each stage (per `showtools-testing`),
never trusting a result-only check. `com.jhg.showtools` backed up with
`defaults export` before each test launch and restored with `defaults
import` after; `runningTestLaunches` checked and cleared where a prior
`pkill` had left a stale entry.

## A pro-style, tabbed Settings window (later the same day)

Jason, looking at the result: "we have a settings default suitable for a
simple app, but we need to implement a pro style window instead" — tabs
across the top tried first (a left-side category list is the fallback),
grouping related settings onto pages, a wider footprint, and probably not
user-resizable, "unless there's a case for it that I'm not thinking of
yet." No case came to mind either.

SwiftUI's `Settings` scene recognizes a top-level `TabView` and renders
it exactly the way System Settings, Mail and Xcode all do — icon tabs in
a toolbar, the window's title naming the selected pane, reopening on the
last one used — entirely for free, via a preference key SwiftUI writes
itself (`com_apple_SwiftUI_Settings_selectedTabIndex`). No custom chrome
needed building.

Regrouped the eight old sections into six tabs: Library (unchanged),
Editing (Tags + Collections + Alerts — everyday behaviors), Playback,
Export, Windows (this pass's own section, and where its remaining pieces
will land as they're built), BGTools (its own tab — a whole companion
app, not one setting). Each page shares one container (`SettingsPage`)
for consistent width, scrolling and the screen-height cap. Width went
640 (from 520); `.windowResizability(.contentSize)` on the `Settings`
scene makes it resize itself per tab rather than being dragged by hand.

**This broke the same-day Settings-covering fix, immediately.** The
title-matching version of `SettingsWindowCoordinator` (built a few hours
earlier, in this same file) depended on the window's title always
reading `"ShowTools Settings"` — once tabs exist, the title names
whichever pane is selected instead (`"Library"`, `"Editing"`…), the
exact behavior the HIG asks for and the thing making it useful. Retested
the identical Info-panel-overlap check right after the redesign, out of
habit rather than assuming the earlier fix still held — it didn't:
Settings stayed hidden behind Info again, and "Library" as a title now
also collides with the main window's own title when nothing's selected,
which would have made the old approach actively wrong, not just stale.

Fixed by dropping window identification by title or timing entirely:
`WindowAccessor`, an `NSViewRepresentable` whose `updateNSView` reads the
real `NSWindow` its own hosted `NSView` sits in — a fact about the
current AppKit view hierarchy, not a snapshot of `NSApp.keyWindow` at
some SwiftUI lifecycle moment that may or may not align with the actual
window state. Captured once (the same `NSWindow` persists across tab
switches; only its title changes) and compared by `ObjectIdentifier`
from then on, same as the coordinator's very first draft — the fix that
was actually needed the whole time, once the title turned out to be the
wrong thing to depend on twice over.

Retested again: Info panel dragged to overlap a reopened Settings
window — Settings drew on top, confirmed by screenshot. Also checked:
tab-switching resizes the window (640×450 for Library's longer content,
narrower for Playback's one toggle), the toolbar icons and labels render
correctly, and clicking each tab via axtool actually lands on it (one
practical snag along the way: clicking a coordinate inside the Settings
window's bounds sometimes hit the *Library* window instead, when Library
had more recently been made key/frontmost by a previous test step and
so was topmost there — fixed by reopening Settings from the menu before
each click rather than trusting `axtool front`, which raises the app,
not any particular one of its windows).

## The drawers' sensitivity setting (later still, same day)

Jason: the settings-vs-preferences split is moot now — everything fits
one tabbed window logically — so start the remaining windows-pass items
with drawer sensitivity, since `spec/panekit.md` already described it
"to an extent."

It had, in real detail: Jason's idea for the control ("something visual
to drag — a line inside a box marking the trigger distance"), a working
practice drawer proposed alongside it, a Quick ↔ Smooth slider for the
slide's own speed if that turned out to need tuning separately, and one
open question — which felt slow, the pull's distance, the slide's speed,
or both. Rather than guess at the open question, built the control for
both: Jason can find out which (or both) by feel once he has it.

`PaneClutch`'s dials (`bite`, `slip`, `engage`, `slideDuration`,
`settleDuration`…) were already `public static var`s, not `let`s —
built that way from the start, evidently already anticipating this
exact setting. `DrawerSensitivitySetting.apply()` sets them from two
`@AppStorage` values (`drawerEngageDistance`, `drawerSlideSpeed`),
called at launch and live whenever either control moves.
`EngageDistanceControl` is the line-in-a-box: a `GeometryReader` and a
plain `DragGesture`, no library needed. `PracticeDrawer` is an
`NSViewRepresentable` wrapping a real `PaneContainerView` — the actual
mechanism every drawer in the app uses, not a mockup — so pulling its
handle exercises whatever the sliders just set, immediately.

Checked with axtool: the practice drawer's own edge handle opened it on
a drag, same as any real drawer; dragging the engage line updated
`drawerEngageDistance` in `UserDefaults` mid-drag, confirmed by reading
it back while the drag tool held partway through. Not yet tuned by
Jason's own hand — the whole reason the control exists rather than a
single silently-picked number.

**A screenshot mistake, corrected:** captured one full-screen
screenshot (`screencapture -x`, no window id) to check the practice
drawer's state, which surfaced an unrelated window on the desktop
(clipped and not otherwise used). Every capture after that used
`-l <window id>` or `-R <region>` targeted to exactly the ShowTools
content being checked, never the whole screen again.

## The floating panels never actually left (later still, same day)

Jason, watching the Settings-covering fix work: "bringing the focus back
to the settings should have also brought the other app windows back as
a package." Investigated rather than guessed at the meaning: with
`panelsHideWhenInactive` off, a real Finder window dragged to overlap
the Info panel's own position, then switched to Finder — the Info panel
stayed on top of Finder's window regardless, not just of ShowTools' own.

The cause: `InfoPanel`, `RhythmPanel` and `SlideEditorWindow` each set
`window.level = .floating` once, at creation, permanently — never
adjusted afterward. A window level ranks across *every app on screen*,
not just its own — PaneKit's own pop-outs (the Inspector, the Timeline
window) already account for this (`PaneWindowController.init`, dropping
to `.normal` on `NSApplication.didResignActiveNotification` and back on
`didBecomeActiveNotification`), but these four hand-built panels
predate that pattern and never got it. So with hiding turned off (a
real, supported choice now that `PanelHidingSetting` exists), a panel
floated above every other app's windows forever — it never "left" when
ShowTools went inactive, so there was nothing to "bring back."

Fixed with `floatOnlyWhileActive`, a small free function mirroring
`PaneWindowController`'s own observer pair exactly, applied to Info,
Rhythm and the Slide Editor. **The library panel is deliberately
excluded** — reasoned through before touching it, not assumed: it's the
drop target for files dragged in from Finder, which makes *Finder*
the active app for the whole drag, so dropping its level while
ShowTools is inactive would sink it behind Finder's own window at
exactly the moment it needs to receive the drop. Its permanent
`.floating` is correct, not an oversight — documented in place so the
next reader doesn't "fix" it into the same bug this session just fixed
everywhere else.

Retested the identical Finder-overlap scenario after the fix: the Info
panel dropped behind Finder once inactive, and reactivating ShowTools
(`axtool front`) brought it back in front together with the main
window — the "as a package" behavior asked for. `swift build` clean,
`swift test`: 336 core tests unchanged throughout both fixes.

## Next steps (Jason, closing this session)

In order:

1. **Adjust the new module** — the drawer-sensitivity setting built
   above. His own hands, by feel: drag the engage line, pull the
   practice drawer, try the Quick ↔ Smooth slider, see what needs
   changing (a dial's default, the control's own range, wording). Not a
   discussion — a build follow-up once he's tried it.
2. **Discuss how to implement the transparency settings** — light mode's
   translucency and a window-background transparency setting (item 34,
   "light mode is awful," `spec/windows.md`'s "Goes in the same pass").
   No design exists yet; this is the conversation that produces one,
   before any code.
3. **Flesh out Smart View** — today it's one paragraph
   (`spec/plan.md`, "Slides as mini movies": on by default, panes open
   and close by context; off, each place remembers its own choices).
   Needs turning into an actual plan — which panes, what "by context"
   means precisely, how the per-place remembered choices are stored —
   before it's buildable.

Both 2 and 3 are conversations to have, not scoped work waiting on a
decision already made — unlike everything built this session, which
started from something Jason had already settled (a setting to build, a
control to wire up, a bug to fix once found). Recorded here and in
`spec/status.md`'s "What's next" so the next session picks up in this
order without re-deriving it.
