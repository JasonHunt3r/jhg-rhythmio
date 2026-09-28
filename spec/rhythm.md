# Beat detection, the range, and rhythm patterns

**Status:** Built 2026-09-22 (Phase 3, steps 6 and 7: Detect Beats on
Apple's Music Understanding, the Rhythm tool, saved patterns). **Open
work:** see `spec/backlog.md` (B-09 the double-tempo reading, B-31 what's
left on the Rhythm tool). The range's later additions (drag, lock, Go
Back, Fill Range) are `spec/range-and-ruler.md`.

Moved out of `spec/plan.md`'s Phase 3 on 2026-09-28, word for word; the
decisions are Jason's, 2026-09-21 and 2026-09-22.

## Settled 2026-09-21 and 2026-09-22
- **The detector is Apple's Music Understanding framework** (Jason,
  2026-09-21): on-device beats, bar starts, tempo, and the song's
  sections, segments and phrases. It needs macOS 27, so step 6 waits
  until Jason's Mac is on it. Our own detector was considered and turned
  down. Still to settle when step 6 starts: analysing each song
  automatically on import (cached like the waveform); beat and bar ticks
  and section bands on song clips (double-click a section to set the
  range); where the apply sheet opens, and its preview; detected markers
  in teal, belonging to their song; ×2 / ÷2 and "bar starts here" in
  place of tap tempo.
- **The range:** I and O set in and out points, drawn as two blue markers
  on the ruler with the span between them shaded (Final Cut's convention).
  A toggle extends them as lines down through every row; off, they're
  just the triangles on the ruler.
- **Lines, two kinds (Jason, 2026-09-21):** the markers' lines and the
  range's lines each have their own switch in the transport bar.
  Double-click one marker (or one end of the range) for just its line;
  ⌥-double-click for every one of that kind.
- **The show's editing state is saved with it** (Jason, 2026-09-21), so a
  show opens the way it was left, like its row order: the range and
  whether it's on, loop playback, and the lines. **The range is undoable**
  (Jason, 2026-09-24, overturning "it isn't undoable"): dragging an end,
  I and O, ⌥X. The rest of the editing state (the lines, loop) still
  isn't. *Build note:* undo restores a whole-show snapshot and
  deliberately carries the editing state over (`AppModel.update`,
  showtools-gotchas), so the range has to be taken out of that carry-over
  and given undo steps of its own. Marker edits, a marker's own line
  included, are undoable, as before.
  It's multi-purpose by context: the part detection applies to, and, with
  loop on (⌘L), the region playback loops inside while editing. Option-X
  clears it, and a header button turns it off without losing it.
- **Tempo:** the song's tempo (BPM) and beat grid are detected, with a
  field to override them and a tap-tempo button for when it guesses half
  or double. Slide changes quantize onto the *detected* beats, not a perfect
  grid, so a song that drifts is still followed.
- **The apply sheet**, run on the range: roughly how many beats per slide,
  *or* a change every roughly X seconds, *or* a rhythm pattern (below).
  It always drops markers (detected ones, so they belong to the song). A
  **"Fit slides to markers"** switch also resizes the slides, from the one
  the range starts in, so each ends on the next marker. Slides are never
  split: they're resized, and the ones after follow (Jason, 2026-09-22).
- **Rhythm patterns** (step 7, planned with Jason 2026-09-22). A note's
  value only sets the gap from one slide change to the next. "Staccato" was
  colour, not a literal feature. It did spark an idea for a **strobe
  effect**, which is parked under Later.
  - **Two tools.** The **Rhythm** tool writes a pattern and works on its
    own, with no song and no analysis: it lays the pattern on an even BPM
    grid and drops **orange hand markers** (a re-run adds more; ⌘Z to try
    another). **Detect Beats** gets a fourth marker choice, **Pattern**,
    which opens the Rhythm tool for its pattern and lays it on the song's
    detected beats as teal markers, with the preview, marker count, Fit
    slides and one-step undo it already has.
  - **Writing it: one text field is the input.** Type into it, or click the
    glyph legend (each note glyph with its letter, a "Rosetta stone") to add
    that letter. The pattern is drawn as **notation** and as a **step grid**
    (tabs), both following the text.
  - **The letters:** `w h q e s` (whole, half, quarter, eighth, sixteenth);
    a dot after a note adds half its length (`q.`); `3e` is one note of an
    eighth-note triplet, so `3e 3e 3e` lasts a quarter. **`r` before a
    value is a rest** (`rq`, `rh.`): it takes time but drops no marker, so
    `q rq q` changes on beats 1 and 3. No ties (a note's value is only the
    gap, so `h`+`q` tied is `h.`). An empty grid square is a rest.
  - **Notation:** one rhythm line, no pitches, drawn with Bravura (the
    free SMuFL music font, SIL OFL 1.1: licence checked 2026-09-22 and
    bundled with it in `Resources/Fonts/`; the legend uses it too). Eighths
    and sixteenths beamed within the beat, triplet brackets, bar lines.
  - **The grid** is its own input, like a drum machine: click a square to
    put a change there. In grid mode the text field and the letter legend
    are hidden (Jason, 2026-09-22). It sizes itself: 16 or 12 steps a bar
    (12 for triplets), as many bars as the pattern needs. A pattern it
    can't show leaves it read-only with a note saying why.
    Clicking rewrites the letters: each gap is one note, never running
    past its bar line, then rests, also split at bar lines, so a
    quarter before an empty bar reads `q rw` (Jason, 2026-09-22).
  - **Note length:** "A quarter note = [¼, ½, 1, 2, 4, 8] beats", default
    4 beats (one bar), so `q q q q` is a slide a bar.
  - **Tempo:** a **BPM field**, filled in from the song's analysis when
    there is one, otherwise 120; always editable (see below).
  - **Where it starts:** the start of the range, or of the show with no
    range. It repeats to the end, and the last repeat is cut short. On a
    song it counts the detected beats (between beats, in proportion), so a
    drifting song is still followed; ×2 / ÷2 and "bar starts" apply.
  - **Saved patterns:** the last one used is remembered; a few built-ins
    (steady `q`; long-short `h q q`; build `w h h q q q q e e e e e e e e`;
    a triplet feel); and Jason's own named patterns, saved in the library
    and offered in a menu, each with its note length (Jason, 2026-09-22).
  - **Listen:** loops the range with a click on each pattern note (over
    the song when there is one), before applying.
  - **The Rhythm tool is a floating panel** that stays open while you
    work, applied to the range as often as you like, with its own **Fit
    slides** switch. It opens from the slides row's drawer and the Show
    menu (with a shortcut). From Detect Beats, Pattern shows the pattern's
    text with **Edit…**, which opens the panel; the pattern comes back
    when it closes.
  - **Typing a BPM over a song** drops the detected beats for an even
    grid at that tempo; **"Use the song's beats"** goes back. (The BPM is
    filled in from the song's analysis.)
  - **No "every N beats" without a song:** a steady `q` pattern does it.

