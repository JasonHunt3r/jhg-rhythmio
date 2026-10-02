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
**github.com/JasonHunt3r/jhg-rhythmio** (`main`; GitHub redirects the old
`jhg-showtools` URL).

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
  by the permission check; done the next morning with Jason's go-ahead.
- **Measured nowhere yet:** the player's id no longer sits under the
  host's (`com.jhg.rhythmbg`, not `com.jhg.rhythmio.…`). A login item has
  no such rule (only the extension does), but it's unproven until RhythmBG is turned on at login.
- Untouched: Jason's untracked files at the root (`ShowTools-icon 2.svg`,
  the plan, the ModKit design pass); `Resources/AppIcon.svg`, the old
  icon's drawing; the old `build/ShowTools.app` in the ignored `build/`.

## The rename: Jason's morning

B-86, done 2026-10-02 except what needs his hands. **Preferences** were
copied (`com.jhg.rhythmio` is identical to the old `com.jhg.showtools`;
RhythmBG kept its window position under its new key). **A fresh library:**
Jason chose not to move the old one, so RhythmIO made `~/Pictures/RhythmIO
Library.noindex`, empty; `ShowTools Library.noindex` stays where it was,
and so does `Application Support/BGTools` (RhythmBG starts fresh).
**Installed:** `~/Applications/RhythmIO.app`; its tiles' extension is
registered. Merged to `main` and pushed; the repo is `jhg-rhythmio`.

**Still Jason's:** allow the permission prompts under the new ids; press
both Control Center tiles; turn RhythmBG on at login (RhythmBG ▸ Desktop
Show…); glance at the Dock and About. The old `~/Applications/ShowTools.app`
is still installed (moving it to the Trash was refused by the permission
check): trash it by hand, or its tiles and player sit beside the new ones.

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

**Installed:** `~/Applications/RhythmIO.app` from the rename (`rename/rhythmio`),
signed with Jason's team. Every reinstall (`install.sh`) quits the real
RhythmBG and doesn't restart it: start it again from RhythmBG ▸ Desktop Show….

**The real library** is a fresh, empty `~/Pictures/RhythmIO Library.noindex`
(2026-10-02). The ShowTools-era ones are untouched and keep their names:
`ShowTools Library.noindex` (12 files, one collection) and
`ShowTools Library (2026-09-24).noindex`.

**Last shakedown:** 2026-09-28, by Jason; 24 rows still open
(`spec/shakedown.md`).

## What's next

1. **B-86**: what's still Jason's, above.
2. **B-04** (P1): the inspector for a file that isn't in the show.
3. **The range, B-02, B-05, B-06** (P1), then B-11.
4. **RhythmBG, B-14 to B-16** (P1).
5. **B-83, B-84**: two click oddities.

B-01 and B-03 (and the held-arrow fixes) are built and installed; their
shakedown rows wait for Jason. Everything else: `spec/backlog.md`.

## Test things installed on Jason's Mac

`RhythmIO.app` and the old `ShowTools.app` in `~/Applications`, `build/DesktopProbe.app`
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
