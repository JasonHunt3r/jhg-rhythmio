# 2026-10-03 — The range batch: nudging, timecode, Edit Range (B-02, B-05, B-06, B-11)

Jason designed B-05, B-06 and B-11 in one reply (recorded word for word in
`spec/range-and-ruler.md`, "Nudging, timecode and exact In and Out"), four
gaps against the code were settled with him, and it was built in steps
N1–N8, each checked with axtool on a scratch library and committed.

## What the checks found

- **B-02 was a double-counted drag.** Checking N6, a fast 104 pt drag of
  the Out end moved it 34 s instead of 6. The drag added the gesture's
  translation — the whole distance since the drag began — to the end's
  *latest* position, so every event added it again: by hand, the end ran
  ahead of the mouse. Measured from where the end started, the same drag
  landed at 77.567 s against 77.58 expected.
- **A modal alert stops the timeline drawing.** The collision alert, shown
  at once, hid the red flash it follows (screenshots during and after:
  orange). It now waits 0.7 s.
- **A popover goes by the layout frame, not `.offset`.** Attached to the
  range ends and bar, Edit Range pointed at the ruler's start. One popover
  on the ruler, with an exact anchor rect, points at what was double-clicked.
- **`ShowTimeline.frame(at:)` wraps a looping show.** A frame past the end
  showed a slide from earlier in the show; past the end now draws the
  background.
- **The frames are the export's.** The frame strip's renderer draws a
  video by its first frame; Jason: "the video slides especially need to
  render the actual frame of the moment." Edit Range uses `MovieMedia`
  (the export's source): the test clip read "2.5" at show time 1.5, which
  is what the player shows (the show's transition has a 1 s lead) — and
  the GIF slide its sixth frame. Jason then asked for the slide's title on
  each frame too.
- **Settings pages opened at 450 pt** whatever their content, so the long
  Timeline and Windows pages scrolled, and Reset sat out of sight; they now
  open at their content's height.
- **The stray click that closed a window**: a click below a Settings
  window's edge landed on the main window, and ⌘W closed that instead.
  Check a target is inside its window, not just on screen.

## Not seen working, for Jason's hands

A real held arrow (one undo step; a release on a marker going back), a
slow real drag of a range end, the range's right-click menu (axtool's
right-click didn't open it there), and the beep.
