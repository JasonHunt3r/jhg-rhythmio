# PopoverKit

The Mac's own popover, anchored to a view, that **stays until the app
closes it** — our own package, `PopoverKit/` (top level), beside PaneKit
and ListKit and independent of both. `cd PopoverKit && swift test` runs
its tests; `swift run PopoverHarness` opens its test app (six tiles:
click one to pin its card, hover another for a second, click-through
card).

**Status: Built 2026-10-03.** First user: Slide Info in the timeline.
Open work: what Slide Info's cards hold (B-88).

## Why

SwiftUI's `.popover` (Edit Range's) has the right look and the wrong
behaviour for anything that should stay up while you work: it closes on
any click outside it, that click can be spent closing it (B-83's likely
cause: the slide's old hover info), and one at a time. Jason wanted the
look kept and the behaviour his (2026-10-03): "write our own module that
looks like that, but works as we just imagined". Own package rather than
part of PaneKit (Jason, 2026-10-03): panes split a window, a popover
points at a view; an app may want either alone, as with ListKit.

## Measured (2026-10-03, a throwaway AppKit probe)

`NSPopover` with `behavior = .applicationDefined`:
- two show at once, and both stay open;
- a click outside both reaches what was clicked, and both stay open;
- with its window's `ignoresMouseEvents` set, a click on the popover
  reaches the view under it — **but only once the window server knows**:
  set in the same instant as the click, the popover still caught it;
- replacing its content keeps it open.

So PopoverKit wraps the real `NSPopover`: identical chrome, arrow and
material for free, nothing drawn by us.

## What it is

- `PinnedPopover` (AppKit): `show(content, anchor:, edge:)` (showing it
  at another view closes and reopens it there: NSPopover can't move),
  `update(content)` in place, `close()`, `passesClicksThrough`,
  `animates`.
- `.pinnedPopover(isPresented:passesClicksThrough:animates:arrowEdge:content:)`
  (SwiftUI): open while `isPresented`, closed only when it turns false or
  the view goes. The anchor is a plain non-flipped `NSView` behind the
  view; the first show waits a run-loop turn for it to have a window.
- **Keys are the app's.** It doesn't take Esc or anything else: the
  app's own key handling closes it (Slide Info: `EditShowTimelinePane`).

## Slide Info (its first user)

Settled with Jason, 2026-10-03, after double-click and then ⌥-click were
tried and dropped ("we're making a Quick Look"):
- **⌥Space** opens the **selected slide's card**: the selection's cursor
  (last clicked or arrowed to), else its first slide. It follows the
  selection as you click or arrow. ⌥Space again, or Esc, closes it.
  Space alone stays play/pause. Also on the slide's right-click menu,
  Slide Info.
- **While it's open, hovering another slide shows a second card** for
  it at once, click-through, so the two can be compared and a click
  still selects. Nothing happens on hover while it's closed.
- The selected card's title is in the selection colour; the hover
  card's isn't.
- Double-click a slide stays the Slide Editor.
