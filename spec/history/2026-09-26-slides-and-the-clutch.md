# 2026-09-26 (evening) — the worklist's answers, slides as mini movies, and the clutch

A dated record. Current rules and state are elsewhere: `spec/status.md`,
`spec/plan.md` ("Slides as mini movies"), `spec/panekit.md` ("The clutch"),
`spec/windows.md` ("The windows pass", "Its height"),
`spec/conventions.md` §1–2. This file keeps the order things happened in,
the wrong turns, and what each measurement actually covered.

## The worklist's last items, answered (`a7103df`)

Jason answered the 2026-09-25 feedback worklist's remaining items in one
reply. Item 24 (BGTools' per-screen stop): build both the green per-monitor
switch and the "Plays Nothing" entry. Item 37: Quick Show and New Show…
keep separate presets. Items 26/27/29 (header restyling, corner radius,
icons) left the list for **ModKit**, a standalone look-auditioning app he
is planning with App Claude; what he mainly wants from it here is the
glass buttons' corners less circular. Item 2's other half grew into a
windows pass (panels hiding is a setting, but drop targets never hide;
Settings comes up frontmost; a settings-vs-preferences split; About
ShowTools). Item 34: light mode "is awful" and wants more translucency,
plus a window-background transparency setting. Item 35: Show Similar
grouped nothing on themed images — Vision's feature prints find bursts,
not themes; he wants it to surface a good next slide. Item 36: large
libraries later, with a big test library. Item 38: the browser's header
as a dropdown to switch lists. New, item 39: a "cantilevered clutch" for
pulling drawers.

For 2(b) he asked how Apple and Adobe behave. Apple's HIG (fetched from
the HIG's JSON, since the page itself is script-rendered): Settings is an
ordinary non-modal window, ⌘,, minimise/zoom dimmed, a fixed toolbar,
the title naming the pane, reopening on the last pane. Adobe's
Preferences are modal dialogs. Recommended Apple's way.

## The grid's half-second (`dc7f620`)

Jason: a tile's selection border drew "like half a second" late. Cause
found by reading and then measured: item 9's double-click (`4bb2dde`,
2026-09-25) had stacked `.onTapGesture(count: 2)` over the single tap, so
SwiftUI held every click in case a second came. A harness measured four
variants: stacked 356 ms, a `simultaneousGesture` double 353 ms (no
better), no double-click 2 ms, and one tap reading
`NSApp.currentEvent.clickCount` 2 ms — the fix. Checked on a test copy:
click selects, double-click Quick Looks, ⌘-click adds. Jason then asked
whether a double-click should ever leave the selection alone: the one
case, a double-click inside a multi-selection (Quick Look only ever gets
one file), was parked with its solution imagined (`524e00f`).

## Item 33 becomes "Slides as mini movies"

First reading of item 33: grey the transport's tools, keep the rows
visible. Step 1 (`279680b`) moved the show's engine up to `ShowView` so it
lives in both modes — measured first in a harness that a `Group` around a
`switch` doesn't fire its own `onDisappear`/`task` on a branch change —
and drew Edit Slides' rows dimmed and inert (scroll and zoom live).
Checked: clicks did nothing, zoom and a horizontal scroll worked (axtool
only sends a vertical wheel; a small pid-guarded horizontal-scroll tool
was written, with Edit Show as the control), Add Marker greyed in Edit
Slides. Then Jason changed course: **Edit Slides' timeline is fully
live**, Edit Slides gets a Slide viewer, and Play there loops the
selection — "the slides are like mini movies". The portrait-montage
idea behind it (several portrait shots filling a frame, each with its own
entrance) was written into the plan as a new feature (`0907f35`).

Steps 1–2 (`e8b5e1d`): live timeline, `ShowTimeline.loopSpans` and the
engine's `selectionLoop`. On the way: **Play never started with no
picture on screen** — the wait for the first slide's media only ended in
`render`, which no view called in Edit Slides; `tick` ends it too now
(diagnosed from a stuck clock, confirmed by a second press working once
the media was ready). And **a click in the slide list never gave it the
keyboard** — true on `dc7f620` too, measured by building that commit in a
worktree. A harness showed every SwiftUI List variant fails, a plain
`NSTableView` doesn't; `ClickTakesKeyboard` fixed it (`66d4982`). Step 3,
the Slide viewer drawer (`795f5ee`).

## The clutch, draft by draft

- **`e94b27d`, the first build:** bite 14, slip 0.35, engage at half the
  drawer's size (48…110 pt), a quick slide; pushed shut it resisted past
  the minimum and shut 48 pt beyond; a drag carried on after engaging
  resized from there. Content keeps its full size while sliding.
  Measured at hand speed with a 25-ms stepping drag tool and the defaults
  bar's position as a gauge (its "Length" label, read through
  Accessibility every ~35 ms).
- **Jason's first look — "a good start":** (a) the Slide viewer's
  picture squashed while resizing. Not reproduced at first — every test
  slide had Pan and Zoom on, so never "motionless" — then reproduced with
  Pan and Zoom off: `render`'s motionless-frame skip ignored a resize, so
  the old frame stayed stretched. Fixed (`3afa4f6`). (b) Once shut, the
  pointer stayed grabbed. The same commit let the drag pull it open
  again; Jason preferred **the bow**: engaging, either way, ends the drag
  (`57ee418`). He also set the rule that a drawer opens to its own size
  (default, then last used).
- **Literal, not a percentage** (`c35b5f9`): 64 pt for every drawer.
- **Flick and swipe** (`a77c49e`): the flick first failed to open in a
  test — three synthetic moves coalesced — which surfaced the real gap: a
  flick ends with the release, so it's judged there too. The swipe
  ignored the first swipe after a swipe shut until its state reset at
  every gesture's end.
- **Slow drags** (`91b1660`, `39fcbd6`): the resist phase "closes way too
  soon" on the timeline (a tall minimum); a close-at-36-pt rule lasted
  under an hour before Jason's "that's reposition, not close drawer"
  replaced it with no slow close at all; then "only partly right" — the
  final rule brakes dead at the minimum and shuts 64 pt past the stopped
  divider. The timeline check first missed its divider three times
  (positions estimated from a screenshot); found at y 612–616 with
  cursor captures, then 40 pt stayed, 70 and 86 shut.
- **The resize cursor** (`91b1660`): some dividers showed the arrow.
  Measured with the pointer in screenshots: nested ones (Edit Slides'
  inspector divider, the grip) were wrong. Tracking areas never fired (a
  probe logged nothing); a per-layout pointer watcher fixed it.

## Tap-to-drag, drag lock, and signing

Jason taps to drag, with drag lock on (read from his trackpad
preferences, `DragLock = 1`): the system holds the button after the
finger lifts, until the next tap. A standalone test app posted a system
mouse-up at the threshold; its log showed the button reading up and the
drag ending, and it was taken as proof — **it stopped watching there**,
and the feel was never confirmed. PaneKit got the post (`a77c49e`),
active only with Accessibility.

Granting Accessibility exposed that ShowTools was **ad-hoc signed**, so
grants die with each build. Jason added his Apple ID in Xcode (and, as a
birthday present to Claude, said "you've got Xcode access now"); the
certificate showed as "0 valid identities" until Apple's WWDR **G3**
intermediate was added (the keychain had only the one that expired in
2023); the first build failed with ad-hoc embedded targets until
`build/xcode/Build` was cleared (`849e121`). The grant still read
`trusted=false`: three stale ShowTools entries in TCC (and an ad-hoc
Xcode Debug build in DerivedData from 2026-09-24, same bundle id) —
deleted, `tccutil reset`, and the app prompting for itself fixed it.
Then, trusted, the post happened and **the stickiness was unchanged**: a
3-second event log after release counted 15–90 drags still arriving. The
driver holds the drag; an app can't end it. The post was removed
(`eb5f37a`) — it had only ended PaneKit's loop early and let those drags
through. A web search found no established solution. Jason's idea of
toggling drag lock off and on around the trigger was logged, not tried.
Lesson kept in `spec/how-we-design.md` ("Watch the whole gesture") and
in Claude's memory (sign Mac apps with a stable identity in the first
wave).

## Mistakes worth remembering

- The drag-lock test declared success from half a gesture (above).
- A test cleanup deleted `PaneKit.Viewer.slides` from Jason's real
  preferences after restoring them — it was his, written by his own copy
  since the install. Restored from the backup; the testing skill now
  says to check the backup before deleting a "new" key.
- A docs commit went in without its doc edits (a failed match in the
  script); fixed in the next commit.
- The first squash tests used a test show whose every slide had Pan and
  Zoom on, which can't show the bug.
