# ShowTools — status

**Read this first each session.** The state of play, in the present tense.
Rules are in `CLAUDE.md`, decisions in the specs (`spec/plan.md` for the
founding ones), what's left in **`spec/backlog.md`** (the only to-do
list), what needs Jason's hands in **`spec/shakedown.md`**, and what
happened on which day in `spec/history/` (never read for current rules).
This file is rewritten, not appended to, and stays at 150 lines or fewer:
if a line has a date and a story, it belongs in `history/`.

Repo: `~/Projects/ShowTools`, pushed to **github.com/JasonHunt3r/jhg-showtools**
(public, `main`).

## Where it stands

**Everything planned is built**, and more has come from Jason's use of it.
**350 tests** (337 core + 13 BGTools); PaneKit has its own 56, ListKit its
own 24. **Library schema 14.**

| Phase | State | Spec |
|---|---|---|
| 1 Library + player | Built | `plan.md` |
| 2 Composer (Edit Slides / Edit Show) | Built | `plan.md` |
| 2a Framing, rotation, match cuts | Built; presets (Flush) parked, B-61 | `plan.md` |
| 2b Library manager | Built | `plan.md` |
| 2c The lane: transitions row + images row | Built; image stickiness open, B-41 | `plan.md` |
| 3 Music + timeline | Built, all 7 steps | `plan.md`, `timeline-pane.md` |
| 3b Find Similar | Built: Delete by context, Find/Show Similar, Keep One, Keep as Group | `plan.md` |
| Groups inside collections | Built | `groups.md` |
| The range and the ruler | Built, W6–W10 | `range-and-ruler.md` |
| 4 Setlist export / import | Built, 4a–4d | `plan.md` |
| E Video export | Built, E1–E5; listened to by Jason 2026-09-25 | `video-export.md` |
| V A video slide's own sound | Built, V1–V5; V6 is a listen | `video-audio.md` |
| 5 BGTools | Built, B1–B7, plus naming screens, the map view, the window opening on your screen | `bgtools.md` |
| PaneKit | Built and in use everywhere; the clutch | `panekit.md` |
| ListKit | Built: the sidebar and the browser | `listkit.md` |
| Windows of their own | Built: Slide Editor, library panel, Inspector and Timeline pop-outs; the windows pass | `windows.md`, `window-behavior.md` |
| The viewer drawer | Built, all four steps | `viewer-drawer.md` |
| Slides as mini movies | Building: steps 1–3 built | `slides-as-mini-movies.md` |
| Simple things fast | Planned: three answers, all to be built | `simple-things-fast.md` |

Every schema upgrade is additive and tested by opening a library of the
version before (7 rows, 8 music, 9 markers, 10 editing state, 11 rhythm
patterns, 12 their note length, 13 groups, 14 a drag order for a
collection's/group's files). Before an upgrade the database is copied
to `Library.sqlite.v<N>.bak`.

**Installed:** `~/Applications/ShowTools.app` at `f4e39b2`, 2026-09-28,
signed with Jason's team. Every reinstall (`install.sh`) quits the real
BGTools and doesn't restart it: start it again from View ▸ Desktop Show….

**The real library** is a fresh one at the default path, `~/Pictures/ShowTools
Library.noindex` (12 files and one collection on 2026-09-26); the old one,
set aside 2026-09-24, is `~/Pictures/ShowTools Library (2026-09-24).noindex`,
untouched.

**Last shakedown:** 2026-09-28, by Jason. 18 rows passed that day, 24
still open (`spec/shakedown.md`). What it found is in the backlog, B-01 to B-13 and
B-33, B-34.

## What's next

B-01 (a popped-out pane losing its content when its window closes) is
fixed and checked in a test copy, not yet installed; the two shakedown
rows that found it wait for Jason. By priority, Claude's suggestion next:

1. **B-03** (P1): arrow keys follow focus in Edit Show.
2. **B-04** (P1): the inspector for a file that isn't in the show.
3. **The range, B-02, B-05, B-06** (P1), then B-11.
4. **BGTools, B-14 to B-16** (P1).

Everything else: `spec/backlog.md`.

## Test things installed on Jason's Mac

`ShowTools.app` in `~/Applications` (the real one, with BGTools and the
tiles inside), `build/DesktopProbe.app` (not running), and XcodeGen
(`brew install xcodegen`, required to build the app). **Apple's WWDR G3
intermediate certificate** was added to the login keychain 2026-09-26
(signing needs it). **ShowTools has the Accessibility permission**, granted
2026-09-26 for a drag-lock experiment that failed; nothing uses it now, so
Jason can switch it off. Xcode's own DerivedData build of ShowTools
(ad hoc, 2026-09-24) was deleted the same day. Stale Background Task
Management entries for `com.jhg.bgtools` and two `com.jhg.nestprobe` ids
remain — `sfltool resetbtm` would clear them but resets every app's login
items, so they are left alone.

## Quick start

```sh
swift test                                  # 337 core + 13 BGTools tests
(cd PaneKit && swift test)                  # 56 PaneKit tests
(cd ListKit && swift test)                  # 24 ListKit tests
./make-app.sh                               # → build/ShowTools.app (signed, team P82S39V2KJ)
tools/make-test-library.sh <scratch>/STTest # scratch library + generated media
open -n --env SHOWTOOLS_LIBRARY=<scratch>/STTest/TestLib.noindex build/ShowTools.app
tools/docs-check.sh                         # the docs' own rules (end of every session)
```

Before launching any test copy, read the `showtools-testing` skill: a test
copy shares Jason's preferences domain, and a crashed one shuts his real
app out.
