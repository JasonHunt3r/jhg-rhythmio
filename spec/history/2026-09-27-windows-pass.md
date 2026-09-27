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

## What's left of the windows pass

Four pieces, each flagged in `spec/windows.md` as needing its own
discussion before any code: the settings-vs-preferences split, the
drawers' sensitivity setting and practice drawer, light mode's
translucency and a background-transparency setting, and the "Smart View"
preference.
