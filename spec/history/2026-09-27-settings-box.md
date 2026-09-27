# 2026-09-27 (later still) — the Set Up Triggers box, three shapes, and where windows open

A dated record. Current rules and state are elsewhere: `spec/windows.md`
("A reusable modal box," "Where these windows open"), `spec/panekit.md`
("The clutch"), `spec/plan.md` ("The viewer drawer"), `spec/status.md`.

Continues the same day's `2026-09-27-windows-pass.md`: the drawers'
sensitivity setting had just shipped inline on the Windows tab. Jason
wanted its fine controls (the engage-distance line, the Quick ↔ Smooth
slider, the practice drawer) moved into a button-launched box instead —
"a new class of reusable case that will apply to other items in the
tabbed windows," not a one-off.

## Three shapes for the same box

**First: app-modal.** Jason's own words for it: "a top level box, the
kind that must be dismissed before you can change focus to other
windows." Built `ModalSettingsBox.present`, `NSApp.runModal(for:)` — every
ShowTools window blocked. A real bug, found by testing: the first cut
called `runModal` synchronously inside the button tap that opened it, and
took no input at all once open (Done, its own close button, even Return
all did nothing, though dragging its title bar worked — the window
server's own doing, proving nothing). Deferring the `runModal` call to
the next run-loop turn, after the tap that opened it had fully finished
dispatching, fixed it.

**Second: tied to Settings' lifecycle.** Jason tried the app-modal
version and reversed it outright: "I was wrong about making it demand the
window." Renamed to `SettingsBox`, an ordinary window that closed
automatically when Settings closed.

**Third: a floating panel.** That, in turn, let Jason close Settings
while the box sat open but hidden *behind* it — "I was able to close the
whole shebang while the secondary window was still in an unconfirmed
state." Rather than build the alert-and-bring-forward fix that gap
seemed to call for, he proposed sidestepping it: "persist above all —
most — windows until you click done. So you could keep it on top while
you try it on the real windows, then click done when you're satisfied."
`SettingsBox` became an `NSPanel`, `.floating`, the same pattern this
app's own hand-built panels (Info, Rhythm, the Slide Editor) already use,
with `floatOnlyWhileActive` reused from them rather than re-solved. A
second real bug, same session: `isFloatingPanel`/`level` set *before*
`contentViewController` and `center()` silently didn't stick
(`kCGWindowLayer` read back `0`, not `3`) — moving them to *after* fixed
it, confirmed by rereading the layer number, not just eyeballing the
window.

Every step here was found by testing, not assumed from a clean
`swift build`. The floating-panel testing had its own wrinkle: Jason had
his own real copy of the app open with an identical Settings window and
box on screen at the same coordinates while a scratch copy was being
driven for these checks. Every click first read window positions by pid
(`CGWindowListCopyWindowInfo`, filtered to the scratch copy's own
process) and moved the scratch copy's windows to a region proven not to
overlap his before touching anything.

## Where these windows open

Jason: Settings should "always open centered in the triggering monitor
window," not restoring wherever it was last dragged to — the default
`Settings` scene autosaves its frame across launches. Refined
mid-conversation twice: first to "centered top under main window bar"
(horizontally centered, pinned near the top under a bar's height, not the
screen's middle), then, once the box existed: "the launch of the
secondary window needs to be relative to the current position of the
settings window" — it should follow Settings, not recenter on the
monitor independently.

Built `TriggeringScreen.swift`: the screen under the pointer right now
(falling back to the key window's screen, then `NSScreen.main`), and 88pt
as "a main window's own bar" (measured from an axtool dump of this app's
own toolbar). Two bugs, both the same shape as the layer bug above —
something read too early, before a window was actually sized or shown:

- **Settings' own positioning did nothing at all**, no matter what the
  bar-height constant was set to (tried an absurd `400` as a canary — the
  window didn't move a pixel, proving the code wasn't running, not just
  computing wrong). `WindowAccessor` hands the window to
  `SettingsWindowCoordinator.captured` via `DispatchQueue.main.async`, so
  by the time it runs and installs the become-key observer meant to
  position the window, that window's own *first* `didBecomeKeyNotification`
  had already fired with nothing listening. Fixed by positioning directly
  inside `captured()` for the window's first-ever capture, leaving the
  observer to handle every later close-then-reopen.
- **The box centered on the screen's raw midpoint**, not its own size —
  `frame.size` still read `.zero` (the panel's own initial `contentRect`)
  immediately after `contentViewController` was assigned, and still after
  `makeKeyAndOrderFront` too: assigning the content controller after
  creation, rather than through `NSWindow(contentViewController:)`,
  doesn't resize the window to fit it synchronously. Fixed the same way
  `captured()` needed: deferred one run-loop turn.

Confirmed with axtool: Settings opens at the screen's horizontal center,
top pinned under the monitor's own bar; dragging it elsewhere and then
opening the box from its Windows tab lands the box centered under
*Settings'* new position, worked out by hand against the real math
(`rf.midX - width/2`, `rf.maxY - barHeight - height`, converting between
AppKit's bottom-left screen coordinates and `CGWindowListCopyWindowInfo`'s
top-left ones) and matching exactly what showed up on screen.

## The header bar's title

Jason: "the header bar should say: ShowTools Settings: XXXX" — the
tabbed `Settings` scene titles its window after just the selected pane
("Library," full stop), which happens to be the exact collision with the
main window's own title this file's earlier history (in
`SettingsWindowCoordinator`'s own doc comment) had already flagged as a
reason title-matching couldn't identify the window. `applyTitleFormat`
prefixes it with `"ShowTools Settings: "`, applied once on capture and
kept up across every tab switch by a KVO observation on the window's own
`title` (there's no "tab changed" notification to hook instead).

Then, right after: "for the secondary windows use the tab name. eg:
Windows: Set Up Triggers." `SettingsWindowCoordinator.currentTabName`
reads the tab name back out of Settings' own already-formatted title
(stripping the prefix, rather than tracking the selected tab a second
time, separately), and `SettingsBox.present` prefixes whatever title it's
given with it. Checked with axtool, again alongside Jason's own live
session — both landed at the exact same deterministic spot, itself a
confirmation the positioning fix above holds for his copy too.

## The viewer drawer's own bar, dropped

A smaller, unrelated ask the same session: the Side by Side / Stack
switch in the selection viewer (Library grid, library panel, Edit Show's
browser) had its own reserved strip since 2026-09-26 — built that way
specifically so the switch would never sit over a picture's corner.
Jason: "it doesn't need to be a hard bar there, those icons can just
float where they are and cover the images if they reach out that far."
`SelectionViewer.body` dropped the outer `VStack` (the reserved strip)
for a `ZStack(alignment: .topTrailing)`; the switch floats over the
content now, and every picture in the drawer gets the drawer's full
height back. Not checked hands-on this session — the real app's own main
window was open at the exact same size and position as any scratch copy
this needed, and opening the drawer risked a stray click landing in
Jason's live session rather than the scratch one. Built and compiles
clean; left for Jason's own look.

## Method notes worth keeping

- **A canary value that changes nothing proves the code isn't running at
  all** — cheaper than re-reading the same three lines for a subtle logic
  bug that isn't there. Used twice this session (the become-key
  positioning, `barHeight: 400`) to tell "wrong math" apart from "didn't
  run."
- **`frame.size` reads `.zero` for longer than it looks like it should** —
  after `contentViewController` is assigned, after `makeKeyAndOrderFront`
  even. Only a deferred run-loop turn reliably has it resolved. Bit the
  Settings window's positioning once and the box's twice, and is now the
  first thing to suspect when a window's own centering math is right on
  paper but wrong on screen.
- **Two live copies of the same app render their default-positioned
  windows at pixel-identical coordinates.** Reading window positions by
  pid before every click, and moving a scratch copy's windows to a region
  proven clear of the real app's, is the only way to test something like
  this without risking the real session — worth remembering for anything
  else this deterministic (a fixed default position, a fixed default
  size) tested while Jason's own copy might also be open.
