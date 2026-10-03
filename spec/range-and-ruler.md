# The range and the ruler

**Status:** Built 2026-09-24 (the range package, W6–W10: dragging and
locking the ends, Go Back / Go Forward, the range button's modifier
clicks, Fill Range with Images). **Open work:** see `spec/backlog.md`
(B-02 the end dragging faster than the mouse, B-05 past the show's end,
B-06 selecting a marker to nudge it, B-11 exact In and Out, B-32 an edge
case to read). Hands-on: `spec/shakedown.md`, "The range package".
**B-05, B-06 and B-11 designed 2026-10-03** (Jason): "Nudging, timecode
and exact In and Out", below, built in steps N1–N8 there. **N1–N4
built 2026-10-03.**

The range itself (I, O, its lines, the editing state it's saved in) was
settled 2026-09-21: `spec/rhythm.md`. Moved out of `spec/plan.md` on
2026-09-28, word for word.

## After the first test (Jason, 2026-09-24)

From Jason's first-test notes (`spec/history/2026-09-24-work-order.md`).
*Decided* is his; *Proposal* is Claude's, for him to settle.

**The range ends (I and O): drag, undo, lock.**
- *Decided:* the ends can be **dragged** on the ruler, **⌘Z** undoes an
  errant drag, and the range can be **locked** so a drag can't move it.
  Locked ends still take the I and O keys and ⌥X, since keys are a
  deliberate act. Today an end only answers a double-click (its line,
  `StorylineView.rangeEnd`).
- *Settled (Jason, 2026-09-24):* **one lock for the whole range**, set
  from the right-click of either end and of the range button. **Locked
  ends simply fade**; no lock icon.

**Getting back after a playhead jump: Go Back, not ⌘Z.**
- *Decided (first):* when a stray click on the ruler moves the playhead
  and the work jumps out of view, a way back to the playhead and the view
  (the timeline's scroll and zoom).
- ***Settled (Jason, 2026-09-24): the playhead stays out of ⌘Z.*** Undo
  stays for edits. When you A/B a change by clicking back to a spot to
  listen again, ⌘Z shouldn't be fighting you with playhead steps.
  Instead, a separate **Go Back** command (⌘[, as in Finder and Safari)
  walks a history of its own: the playhead with its scroll and zoom.
  **The range stays in ⌘Z:** it's a deliberate tool that can be locked,
  so undoing while fiddling with its setup is wanted.
- **Go Back's steps** (settled): with the mouse, one step per click and
  release (a click that jumps, or a scrub drag from press to release);
  with the keyboard, one per nudge. Playback and J, K, L don't register.
  A matching **Go Forward** (⌘]) retraces them.
- *Undo history:* nothing limits it today (`levelsOfUndo` isn't set, so
  it's unlimited within a session). It's cleared on switching libraries
  and doesn't survive quitting.

**The range button.**
- *Decided:* a **plain click** shows or hides the range, as now. **⌥⌘-click**
  sets the range to the part of the timeline in view. **⇧⌥⌘-click** sets
  it to the whole show, even where it's out of view. A locked range
  refuses both modifier clicks, with a beep. Both commands also go in the
  **Show menu** (beside Set Range In/Out) and on the button's
  right-click, since modifier clicks can't be seen (audit F1). The button
  is disabled today when there's no range; it has to be enabled for
  these.
- *Settled (Jason, 2026-09-24):* a **plain click with no range set acts
  like ⌥⌘-click** and makes a range from the view, following the
  conventions already set.

## Fill the range with images

- *Decided:* **right-click the range on the ruler → Fill Range with
  Images…**, a dialog with:
  - an **image picker** (`MultiItemPicker`) with a Library / Collection
    toggle. Picking from the Library also adds the pictures to the show's
    collection;
  - a **transition** drop-down;
  - a **rhythm** setting: the apply sheet's choices (roughly N beats per
    slide, a change every roughly X seconds, a rhythm pattern) plus
    **Even**, an equal split, the default;
  - **Replace / Displace.**
- **Replace:** the slide the range starts inside is trimmed to end at the
  in point. The new slides fill the range. The slide the range ends inside
  is shortened at its front so it starts at the out point, and everything
  after the range **keeps its position** in time. Slides wholly inside the
  range are removed. The show's length doesn't change.
- **Displace:** the slide the range starts inside is trimmed to end at the
  in point, as in Replace. Nothing inside the range is removed: the next
  slide and everything after it **move later**, starting where the
  imported run ends. The show gets longer.
- **Rhythm against image count:** one image per note. A pattern runs for
  **as many notes as there are images**, then stops. With detected beats
  under the range, changes quantize onto them, as the apply sheet does.
- **Nothing is greyed out** (settled, Jason, 2026-09-24; replaces the
  work order's greying rule). He trusts the user to set the range to the
  beat and choose a number of images that suits the pattern. Instead, the
  dialog **shows the details as feedback** before OK: how many slides,
  each one's length, and how they sit on the beats.
- **Rules kept:** slides are never split. These are trims, and a trimmed
  slide keeps its settings. The whole fill is **one undo step**. A locked
  range can still be filled, since its ends don't move.
- *Settled (Jason, 2026-09-24):* **the fill always fits the range
  exactly.** There's never a shorter run: the fill does the maths and sets
  the slides' lengths so they fill the range, following the settings
  chosen.
- *Settled (Jason):* in Displace (and Replace), **the first slide is just
  shortened** to end at the in point. There's no tail to place anywhere.

## Nudging, timecode and exact In and Out (Jason, 2026-10-03)

**Status:** Designed 2026-10-03 (B-05, B-06, B-11; B-02 is measured and
fixed in the same batch). Building: N1–N4 built 2026-10-03. Jason's reply,
recorded as given.

**B-05.** The range is as long as needed, so it can place slides that
would run past the current end of the timeline.

### B-06: keyboard movement

| Keys | Default | Configurable |
|---|---|---|
| ← → | the adjustable step (1 s) | yes |
| ⌥ ← → | exactly 1 frame | no |
| ⇧ ← → | 5 s | yes |
| ⇧⌥⌘ ← → | 15 s | yes |
| ⌘ ← → | jump to the next marker | n/a |
| ⌘⌥ ← → | jump to the next beat, marked or not | n/a |

The playhead becomes a selectable object, and this one ladder drives the
playhead, range ends and markers. A one-frame step is always on one of
two keys, so no setting can remove frame-accurate stepping.

**Settings ▸ Timeline ▸ Nudge:**
- A value and unit (seconds or frames) for the adjustable step, the ⇧
  step and the ⇧⌥⌘ step.
- **Fine-step key**, a two-way choice, default ⌥. *⌥ (default):* ← →
  moves the adjustable step, ⌥ ← → exactly one frame. *Plain arrow:* ← →
  exactly one frame, ⌥ ← → the adjustable step. ⇧ and ⇧⌥⌘ are unaffected.
  The one-frame step is never configurable.
- **Marker merge tolerance**, in frames, default 5, minimum 1 ("Marker
  collisions"). Jason tunes the default while testing: one named constant.
- **Reset "don't show again" alerts**: re-enables the first-occurrence alert.

**Targeting and feedback.** Arrows move the selected object: a range end,
a marker, or the playhead; with nothing selected, the playhead. Clicking
the playhead selects it, with a visible highlight; clicking empty ruler
space deselects. Arrows act only when the timeline has focus (in the
popover's fields they edit text). **Nudge readout:** while a handle or the
playhead is selected and moving, the new timecode and the delta (+1:00,
−0:03), light and fast, no thumbnails.

**⌘ and ⌘⌥ jumps.** ⌘ on the playhead or a range end moves it to the next
marker in the arrow's direction. ⌘ on a selected marker moves the
*selection* to the next marker (the marker stays), so: nudge one, hop,
nudge the next. ⌘⌥ goes to the next detected beat in that direction, even
where no marker is; for a selected marker it skips beats already holding
a same-type marker. No beats detected: ⌘⌥ does nothing and flashes "No
beats detected." From between targets, the next one that way; stop at the
first or last, no wrapping.

**Constraints.** The range is at least one frame long; nudging an end into
the other clamps and never swaps. All edits clamp to 0 and the show's
duration. A locked range can't be nudged. A held arrow is one undo step.

**Marker collisions.** Two markers of the same type can't share a time;
different types may. One tolerance, in frames (default 5, minimum 1; at 1
only the same frame collides), governs both:
- *Placing* a marker within the tolerance of a same-type one: the old one
  collapses into the new, at the newest placement. The same frame always
  merges. One undo step restores both.
- *Dragging or nudging* one within the tolerance of another: on release,
  the system beep, the marker flashes red and animates back to where it
  was (sound may be muted, so the flash matters). A held arrow beeps once
  per hold.
- The first time: an alert explaining it, with "Don't show this again"
  (resettable in Settings).

### B-11: exact In and Out

- **Opening:** double-click the range (either end, or the bar between), or
  **Edit Range…** in its right-click menu. Not on a locked range. The
  double-click's first click selects the end and mustn't make the playhead
  jump in a way that feels broken.
- **Fields:** In, Out and Length in `m:ss:ff` (a colon before the frames,
  as timecode; a dot reads as decimal seconds). Also parsed: `83`,
  `1:23`, or a bare frame count. Editing In keeps Out (Length changes);
  editing Out keeps In; editing Length keeps In and moves Out.
- **Validation:** bad or out-of-range input turns the field red and blocks
  Return; never a silent clamp. Return applies all of it as one undo
  step; Esc cancels.
- **Frame preview:** the actual frames at In and Out, live as you type
  (debounced), through the export renderer. Each overlaid with IN or OUT,
  the `m:ss:ff` timecode and the absolute frame number, over a soft scrim,
  tabular figures. The length once, between or beneath them. If it's too
  slow, fall back to large timecode readouts and tell Jason.

**Timecode as the model.** In and Out are frame-aligned: they snap to the
frame grid on drag, nudge and typed entry. Stored as seconds, frames
derived for display, so changing the rate later doesn't corrupt a range.
The ruler, the popover and the readouts show the same value. The frame
rate is the show's export frame rate (24, 30 or 60); the playhead's
hard-wired 30 fps becomes per show.

### Settled with Jason (2026-10-03, all four as proposed)

1. **B-05 against "clamp to the show's duration".** The range's
   ends are exempt (they may run past the end, per B-05); the playhead and
   markers clamp to the duration.
2. **A show has no export frame rate yet.** The export sheet starts at 30
   every time and kept nothing. Now a per-show **Frame rate** (24, 30,
   60; default 30), saved with the show, which the export sheet starts
   from (a choice there is for that export only). It sits in the defaults
   bar's ⋯ menu (Frame Rate ▸), since both of the bar's rows are full;
   `show.tsv` carries it as `# frame_rate`. Built in N1.
3. **The two marker types are show markers and beat markers.** Beat
   markers belong to an audio clip and move with it. "Same type"
   means show-marker against show-marker and beat-marker against
   beat-marker, across clips.
4. **"Detected beats" for ⌘⌥** come from the per-file analysis cache, in
   song time. They're used as every audio clip's beats, in show time, inside its
   trimmed part.

### Build steps

N1 timecode (frame-aligned seconds ↔ `m:ss:ff`, the loose parser) and the
per-show frame rate — **built 2026-10-03**: `FrameGrid` (`Timecode.swift`;
a frame count is typed with an `f`, `2490f`, since a bare `83` is seconds,
the same as `1:23`), `ShowDefaults.frameRate`, the playhead's one-frame
nudge on it · N2 the nudge settings and the key ladder — **built
2026-10-03**: `NudgeSettings` (`Nudge.swift`), Settings ▸ Timeline ▸ Nudge,
the ladder on the playhead (nothing selected) and on selected markers of
both kinds (moved together, spacing kept, the earliest on the grid; a held
arrow is one undo step: the first press is the edit, repeats save without
steps). A row with a selection keeps its own arrows (B-03). ⌘ and ⌘⌥ wait
for N4; the merge tolerance and the alerts reset come with N5 · N3 the
playhead as a selectable object, range ends selectable, the readout —
**built 2026-10-03**: a click (or a drag) selects a range end, yellow like
a selected marker; a press within 6 pt of the playhead selects it without
moving it (a yellow ring); any other ruler press deselects the ruler's
things (markers, an end, the playhead) and scrubs as before, leaving
slides selected; Esc clears them too. A selected end takes the ladder
(`ShowEditorState.nudgingRange`), a locked range beeps. The readout is a
capsule at the top of the ruler beside the thing, timecode and delta,
presses close together adding up, gone 1.5 s after the last; it also
shows for the playhead with nothing selected. Every way of setting an end
(I/O, the range button's set-to-view and whole show, Set Range to Clip,
a drag) lands on the frame grid, and a drag keeps a frame's length (was
0.1 s). Still open for N7: a double-click on an end toggles its line ·
N4 ⌘ and ⌘⌥ jumps — **built 2026-10-03**: `Jump.next` (the one you're on
doesn't count; no wrapping), `Show.rulerMarkers`, `Show.beatTimes` (every
clip's beats from the per-file cache, in show time, inside the part that
plays; read from memory only, so a jump never starts an analysis — the
audio row starts it when it draws a clip), `movingMarkersToNextBeat`
(skips beats a same-kind marker holds). Markers moved to a beat land on
it exactly; a range end keeps its grid and frame rules, so a jump past the
other end stops short; the playhead goes exactly there · N5 marker collisions · N6 B-05, the range past the
end · N7 the Edit Range popover with its frame previews · N8 B-02's drag.

