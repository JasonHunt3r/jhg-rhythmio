# The range and the ruler

**Status:** Built 2026-09-24 (the range package, W6–W10: dragging and
locking the ends, Go Back / Go Forward, the range button's modifier
clicks, Fill Range with Images). **Open work:** see `spec/backlog.md`
(B-02 the end dragging faster than the mouse, B-05 past the show's end,
B-06 selecting a marker to nudge it, B-11 exact In and Out, B-32 an edge
case to read). Hands-on: `spec/shakedown.md`, "The range package".

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

