# 2026-10-03 — Slide Info on PopoverKit, and Show in Own Window everywhere

The afternoon after the RhythmBG batch (`2026-10-03-rhythmbg-batch.md`).

**B-84 and B-83.** `ListEmptySpace` and `ClickTakesKeyboard` passed
`hitTest` the content view's own flipped coordinates, the mirror bug
`KeyboardArea` had; fixed the same way, not measured first (5257e68).
B-83 (a click in the popped-out Timeline not selecting a slide) worked
by hand: the synthetic click. Jason suspected the slide's hover info, a
SwiftUI popover that opened after a second and could spend a click
closing.

**Slide Info, by steps.** What Jason wanted changed as it was tried,
each step built or weighed before the next:
1. Double-click opens the info, staying like Edit Range's popover;
   ⌥-double-click the Slide Editor. Built and installed (9ca820b).
2. "Maybe ⌥-click shows the info and double-click the Slide Editor" —
   ⌥-click on a slide turned out free (conventions §1 had it open).
3. The `` ` `` key — free, but not a Mac standard.
4. "We're making a Quick Look": tied to the **selection**, not the
   pointer; Space is play/pause, so **⌥Space** (free on his Mac; checked
   by him, since the Claude app's quick entry was a suspect).
5. While it's open, **hovering another slide shows a second card** to
   compare against the selected one.
6. "I like the look of the range popover, so maybe we need to write our
   own module" → **PopoverKit**, its own package (asked: PaneKit or its
   own; own, as ListKit was).

**Measured before building** (a throwaway AppKit probe): `NSPopover` with
`.applicationDefined` shows two at once, lets an outside click through
and stays, swaps content in place, and with `ignoresMouseEvents` passes
clicks to what's under it — but only once the window server knows: set
in the same instant as the click, the popover still caught it (found by
a third run, after a tile placed under the popover got nothing).

**My slip.** Checking PopoverKit's harness, the harness window had opened
behind Jason's VS Code, and a CGEvent click and pointer sweep landed in
his editor's terminal. Harmless by luck; the memory note on driving Mac
apps now says a freshly launched harness isn't frontmost.

**Show in Own Window on every right-click.** Asked as "right-click
options on the panes that pop out"; Jason chose the larger version at
each question: new pop-outs too (Edit Slides' Inspector, the Browser,
the Library pane; B-65 mostly), and the item in **every** menu inside a
pane, not just its background. His rule for the kind of window, given
when I'd proposed the Browser as an ordinary window: what you drag
things out of floats; a work area like the Timeline must go behind. So
all three new ones are panels. Built in PaneKit (`\.paneWindow`,
`PaneWindowMenuItem`, `PaneWindowContext.of` for AppKit menus), four
commits, f02b4ea…ec887db. The environment doesn't cross PaneKit's
hosting views, so nested layouts pass the outer pane's context on.
"Library Pane", not "Library", in the menus: the library panel is
another thing. Jason tried it installed: "looks good and works properly".

**B-08 checked, evening.** Jason turned "Open RhythmBG at login" off in
Settings (which also quit RhythmBG: unregistering a running login item
stops it), then RhythmBG ▸ Desktop Show…: one copy (pid 48650), its log
showing one launch and the window's URL a second later — the wait the
2026-10-02 fix added. Before the fix, two started in the same second.
launchd and `sfltool dumpbtm` kept listing `com.jhg.rhythmbg` as enabled
while it was unregistered; the app's own `SMAppService` status is what
the switch reads, and it was right.
