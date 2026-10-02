# 2026-10-02 — ShowTools becomes RhythmIO (B-85)

An overnight, unattended run of Jason's `ShowTools → RhythmIO (miO) Rename
Plan.md`, on branch `rename/rhythmio`, while he slept. Five phases, five
commits, each on a green build. The morning half is his (B-86, steps in
`spec/status.md`).

## Before the run

Jason and Claude went over the plan first and settled five edits: the
history bridge line takes the run date; the morning list gained
"re-grant permissions" (macOS keys them to the bundle id), "open the
library by hand once if Recents can't find it", and "both old apps quit
before copying preferences"; and the test-copy rule was to be rewritten
for the new domain, not just search-and-replaced.

## What the run found

- **`stcli` is inside `SetlistClip`.** A case-insensitive grep for the
  CLI's name hit `SetlistClip` and three test names; it's renamed as a
  whole word only.
- **The tiles' `kind` strings are `com.jhg.bgtools.*`**, a prefix older
  than the bundle ids. The plan says keep them, so the rename shields that
  prefix — and with it the real, stale id `com.jhg.bgtools` and the old
  standalone `~/Applications/BGTools.app` that `xcode-port.md`'s story
  names. A blind replace would have written "remove RhythmBG.app" into a
  record of removing BGTools.app.
- **Possessives don't survive.** "BGTools' panel" became "RhythmBG'
  panel", in the tiles' descriptions, a tooltip and the private-library
  note as well as comments. All are now "RhythmBG's" / "RhythmIO's".
- **A spec's measurements would have changed ids.** `xcode-port.md`
  recorded "Background Task Management lists `com.jhg.showtools.bgtools`";
  renamed, it claimed a measurement of `com.jhg.rhythmbg` nobody has made.
  It now says its results were taken under the old ids. The plan's one
  change of shape — the player's id no longer nested under the host's — is
  unmeasured until Jason's first install.
- **The inventory names files the rename removes**, so docs-check failed
  on it once `bgtools.md` became `rhythmbg.md`. As a dated, frozen record
  it moved to `spec/history/2026-10-02-rename-inventory.md`.
- **Preferences that change key:** only `NSWindow Frame BGToolsMain`
  (RhythmBG's window position). Everything else in both domains carries
  over by import. The setlist header now says RhythmIO; import skips `#`
  lines, so older setlists still import.

## Left for the morning, and why

- RhythmBG wasn't launched: it would have created `Application
  Support/RhythmBG/`, which Jason's step 5 renames `BGTools` into.
- The test copy left layout keys in the new `com.jhg.rhythmio` domain
  (which didn't exist before the run). Deleting the domain was refused by
  the permission check, so it's the first preferences step of B-86.

Tests: 340 + 13, PaneKit 56, ListKit 24, the same before and after.
