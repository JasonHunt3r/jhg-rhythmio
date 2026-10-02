# RhythmIO — status

**Read this first each session.** The state of play, in the present tense.
Rules are in `CLAUDE.md`, decisions in the specs (`spec/plan.md` for the
founding ones), what's left in **`spec/backlog.md`** (the only to-do
list), what needs Jason's hands in **`spec/shakedown.md`**, and what
happened on which day in `spec/history/` (never read for current rules).
This file is rewritten, not appended to, and stays at 150 lines or fewer:
if a line has a date and a story, it belongs in `history/`.

RhythmIO (short form miO) was **ShowTools**, and RhythmBG was **BGTools**,
until the rename of 2026-10-02 (B-85). History keeps the old names.

Repo: `~/Projects/ShowTools` (the folder keeps its name for now), pushed to
**github.com/JasonHunt3r/jhg-showtools** (`main`), to be renamed
`jhg-rhythmio` (B-86). The rename is on branch **`rename/rhythmio`**, not
merged and not pushed.

## The rename: the overnight report

Built overnight on `rename/rhythmio`, one commit per phase of
`ShowTools → RhythmIO (miO) Rename Plan.md` (Jason's, untracked, at the
repo root):

| Commit | Phase |
|---|---|
| `26294fd` | 1 Inventory (now `spec/history/2026-10-02-rename-inventory.md`) |
| `f939cfb` | 2 Code and build: folders, targets, bundle ids, UTIs, env vars, the CLI `mio`, the new icon |
| `82863ab` | 3 User-facing text: possessives ("RhythmBG's panel"), no miO in the UI |
| `2abc1c8` | 4 Docs: CLAUDE.md, the skills, the live specs, the name bridge |
| (this one) | 5 This report |

**Tests:** 340 core + 13 RhythmBG, PaneKit 56, ListKit 24, all green, the
same counts as before the rename. **Built:** `build/RhythmIO.app`, clean,
with RhythmBG and the tiles inside: `com.jhg.rhythmio`, `com.jhg.rhythmbg`,
`com.jhg.rhythmio.bgcontrols`, all signed with Jason's team; scheme
`rhythmbg://`; UTI `com.jhg.rhythmio.items`; Jason's new icon compiled to
`RhythmIO.icns`. A scratch-library launch (`RHYTHMIO_LIBRARY`) opened its
11 files and test show; the app menu reads About / Hide / Quit RhythmIO.

**The grep** (`showtools|bgtools|stcli` outside `spec/history/`) leaves
only the allowlist: the tiles' `kind` strings `com.jhg.bgtools.open` /
`.desktopShow` (kept, so their state carries over); the name bridge
(CLAUDE.md, the testing skill, `rhythmbg.md`, `xcode-port.md`); and real
things on Jason's Mac (`com.jhg.bgtools`, `~/Applications/BGTools.app`
in xcode-port.md's story, the set-aside library, the repo URL, this file).

**Not done, on purpose:**
- **RhythmBG wasn't launched.** It writes `~/Library/Application
  Support/RhythmBG/`, and creating that folder would block Jason's rename
  of `BGTools` to it. Its bundle is checked; the launch is his.
- **`com.jhg.rhythmio` holds a test copy's leftovers** (window frame and
  five PaneKit layouts, no library paths). Deleting the domain was refused
  by the permission check, so it's step 2 below.
- **Measured nowhere yet:** the player's id no longer sits under the
  host's (`com.jhg.rhythmbg`, not `com.jhg.rhythmio.…`). A login item has
  no such rule (only the extension does), but it's unproven: step 9.
- Untouched: Jason's untracked files at the root (`ShowTools-icon 2.svg`,
  the plan, the ModKit design pass); `Resources/AppIcon.svg`, the old
  icon's drawing; the old `build/ShowTools.app` in the ignored `build/`.

## The rename: Jason's morning

B-86. In order; the old apps must be quit for steps 2–5.

1. Quit ShowTools (⌘Q) and BGTools (its panel ▸ Quit BGTools).
2. Clear the test leftovers: `defaults delete com.jhg.rhythmio`
3. Copy preferences: `defaults export com.jhg.showtools - | defaults import com.jhg.rhythmio -`
   and `defaults export com.jhg.showtools.bgtools - | defaults import com.jhg.rhythmbg -`
   (RhythmBG's window opens at its default place once: its frame key was
   `BGToolsMain`.)
4. Rename `~/Pictures/ShowTools Library.noindex` to `RhythmIO Library.noindex`.
5. Rename `~/Library/Application Support/BGTools` to `RhythmBG`.
6. Delete the old app: `~/Applications/ShowTools.app` (it's in your home
   folder's Applications, not /Applications). Its login item goes with it.
7. `./install.sh` (from the branch), which installs and opens
   `~/Applications/RhythmIO.app`.
8. Re-grant what macOS asks for under the new ids (Photos, folders,
   Music). If the library doesn't open from Open Recent, the saved path
   still says "ShowTools Library": open it by hand once.
9. RhythmBG ▸ Desktop Show… (its own menu in the menu bar), turn RhythmBG on at login; check it
   finds the library, plays, and that both Control Center tiles work.
10. Copy/paste and drag slides, sections and items between windows.
11. Name and icon read right: menu bar, Dock, About, window titles, Finder.
12. Merge `rename/rhythmio`, rename the repo on GitHub to `jhg-rhythmio`,
    then `git remote set-url origin https://github.com/JasonHunt3r/jhg-rhythmio.git`.

## Where it stands

**Everything planned is built**, and more has come from Jason's use of it.
**353 tests** (340 core + 13 RhythmBG); PaneKit has its own 56, ListKit its
own 24. **Library schema 14.**

Every phase is built (`plan.md`; each area's spec is in CLAUDE.md's
table) except **Slides as mini movies** (building, steps 1–3 built) and
**Simple things fast** (planned). Parked: 2a presets (B-61), 2c image
stickiness (B-41); V6 is a listen.

Every schema upgrade is additive and tested by opening a library of the
version before. Before an upgrade the database is copied to
`Library.sqlite.v<N>.bak`.

**Installed (until step 7):** `~/Applications/ShowTools.app` at `4753229`,
signed with Jason's team. Every reinstall (`install.sh`) quits the real
RhythmBG and doesn't restart it: start it again from RhythmBG ▸ Desktop Show….

**The real library** is at `~/Pictures/ShowTools Library.noindex` until
step 4 (12 files and one collection on 2026-09-26); the old one, set aside
2026-09-24, is `~/Pictures/ShowTools Library (2026-09-24).noindex`,
untouched, and keeps that name.

**Last shakedown:** 2026-09-28, by Jason; 24 rows still open
(`spec/shakedown.md`).

## What's next

1. **B-86**, Jason's morning, above.
2. **B-04** (P1): the inspector for a file that isn't in the show.
3. **The range, B-02, B-05, B-06** (P1), then B-11.
4. **RhythmBG, B-14 to B-16** (P1).
5. **B-83, B-84**: two click oddities.

B-01 and B-03 (and the held-arrow fixes) are built and installed; their
shakedown rows wait for Jason. Everything else: `spec/backlog.md`.

## Test things installed on Jason's Mac

`ShowTools.app` in `~/Applications` (until step 6), `build/DesktopProbe.app`
(not running), and XcodeGen (`brew install xcodegen`, required to build).
**Apple's WWDR G3 certificate** is in the login keychain (signing needs
it). ShowTools' unused Accessibility permission goes with the old app. Stale Background Task Management entries for `com.jhg.bgtools` and two
`com.jhg.nestprobe` ids remain — `sfltool resetbtm` would clear them but
resets every app's login items, so they are left alone.

## Quick start

```sh
swift test                                  # 340 core + 13 RhythmBG tests
(cd PaneKit && swift test)                  # 56 PaneKit tests
(cd ListKit && swift test)                  # 24 ListKit tests
./make-app.sh                               # → build/RhythmIO.app (signed, team P82S39V2KJ)
tools/make-test-library.sh <scratch>/STTest # scratch library + generated media
open -n --env RHYTHMIO_LIBRARY=<scratch>/STTest/TestLib.noindex build/RhythmIO.app
tools/docs-check.sh                         # the docs' own rules (end of every session)
```

Before launching any test copy, read the `rhythmio-testing` skill: a test
copy shares Jason's preferences domain, and a crashed one shuts his real
app out.
