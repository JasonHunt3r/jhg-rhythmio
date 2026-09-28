# ShowTools — Docs Hygiene Pass (work order for CC)

Sep 28, 2026. Docs and repo tidy only, including re-slicing `plan.md` and `windows.md` (step 5). **No Swift changes, no app launches.**

## Why

An audit of `spec/` at HEAD (`ade536a`) found four problems. The Sep 25 hygiene note (repo root) flagged two of them; neither was fixed.

1. **`spec/status.md` is 652 lines / 41 KB** and breaks its own header rule ("rewritten, not appended to"). "Still needs Jason's hands" alone is 296 lines (45%) of dated session narrative. About 60 lines carry `2026-09-` stories that belong in `history/`.
2. **"What's left" lives in about 12 places.**
   - status: What's next (items 0–8 plus "Also open"), Parked for later, Still needs Jason's hands, Open questions, Known issues
   - `bgtools.md` Next up · `plan.md` Open questions · `windows.md` Jason's answers
   - `simple-things-fast.md` Open questions · `first-run-brief.md` Open questions
   - `video-export.md` Still open · `video-audio.md` Left for Jason's eye
   - `conventions.md` Proposed/Open · `hig-audit.md` Fix batches
   - the root file `ShowTools Feedback — Worklist for Next CC Session.md`

   Items are referenced as "item 23–25", "item 33/35/36/38", but the numbering scheme is defined in no current doc.
3. **`conventions.md` is stale.** The last audit commit (`c6793e0`) skipped it. At HEAD, line 68 still says ⌥-click on a row handle is "not built", though it's built (`StorylineView.swift` ~718–726). Lines 183/190/214 (and 335–351) still say "greyed out until built" for Open Library Panel and Replace Image, which are wired (`MainView.swift` ~210, `SlideInspector.swift` ~100).
4. **Root clutter.** The Worklist and Hygiene docs are at the repo root, plus a stray `Screenshot 2026-09-21…png`. `spec/handoff.md` is a retired tombstone.

## Ground rules

- **Moves, not deletions.** Nothing with information in it is deleted. Dated narrative goes to `spec/history/` verbatim.
- **Verify claims against source** (grep the code, don't just re-read the docs). That is the method that caught the stale claims.
- Don't touch Jason's untracked files (`ModKit & DefaultsKit — Design Pass.md` etc.). Don't delete the Screenshot png; list it in the report and ask.
- One commit per step below, following the CLAUDE.md commit rules.

## Steps

### 1. `conventions.md` truth pass (do first; it's the only *wrong* doc)
Check every row in the per-target table marked "not built", "greyed out", "deferred", "agreed, not built" or "Settled…; not built" against the code. Fix each row to match reality, keeping its Settled date. Don't reword decisions. Where code and doc disagree and it isn't clear which is right, **don't guess**: add it to the "Needs Jason" list in the final report.

### 2. Create `spec/backlog.md` — the one list
Inventory every open item from the 12 places above. Deduplicate, then write one entry per item in three sections:

- **Build queue**: CC can do it.
- **Needs Jason's hands**: a real-hand check or by-feel tuning. One or two lines each: *what to try* and *where the detail lives*.
- **Needs a decision / parked**: waiting on a talk or a plan.

Each entry: stable ID (`B-01`…), priority `P0–P3` (reuse the Worklist's scale), area tag, one-line description, a pointer to the spec section holding the *design* detail, and **`(was item N)`** wherever an old item number existed, so history refs still resolve.

Known issues move here too, as a fourth section. Items already built or superseded go to history, not into the backlog.

Then **replace each original list in its source doc with a one-line pointer** (`Open work: see spec/backlog.md`). Feature specs keep their status blocks and their design reasoning; they just stop keeping a private to-do list.

### 2b. Create `spec/shakedown.md`: the permanent hands-on checklist
This replaces "Still needs Jason's hands" as a *list*. It is not a to-do list; it's a shakedown checklist that keeps passed items, so a future full shakedown can re-run it.
- One row per checkable feature: `- [ ]` or `- [x]`, a short "what to try", **Last checked by Jason** (date or blank), **Claude's level** (axtool / tests only / smoke only / can't), and a spec pointer.
- Seed it from the 39 items in status.md plus Jason's results in the appendix. His passes get `[x] 2026-09-28`; his notes become backlog IDs, linked from the row.
- Merge "the clutch's feel" into "drawers' sensitivity" (Jason: redundant). Close "Audit G1 and audio naming" as done.
- Rule for `CLAUDE.md`: every shipped user-facing feature adds a shakedown row. Claude never ticks a box; only Jason does.
- Findings from a shakedown go to `backlog.md`, never into shakedown rows.

### 3. Slim `spec/status.md` to ≤150 lines
Keep: header, a pointer to `shakedown.md`, Where it stands (phase table plus test/schema counts), What's next (the chosen order, max ~10 lines, IDs linking to backlog), Test things installed on Jason's Mac, Quick start, and a pointer to backlog. Move everything else:

- Dated narrative from "Still needs Jason's hands" and elsewhere goes verbatim to `spec/history/2026-09-28-status-archive.md`.
- Live checks go to `backlog.md`, condensed per step 2.

Nothing is lost: every line is in the archive or the backlog.

### 4. Root and stray-file cleanup
- Move `ShowTools — Documentation Hygiene.md` and the Sep 25 Worklist to `spec/history/`. Give them dated names and add README rows saying which items were handled, using `2026-09-25-feedback-worklist-batches.md` as the cross-reference.
- Check whether anything references `spec/handoff.md`. If nothing does, remove it and drop the mention. If something does, fix those references first.
- Leave the Screenshot png. Report it.

### 5. Retire and re-slice `plan.md` and `windows.md`
Both have become catch-alls. `plan.md` is where every new feature design landed; `windows.md` is where anything touching a window landed. So each now mixes live decisions, built-work records, superseded sections and private to-do lists.

**5a. Freeze the originals first (its own commit, before any slicing):**
- `mkdir -p spec/history/verbatim`
- **Copy, don't `git mv`.** Copy `spec/plan.md` to `spec/history/verbatim/plan-retired-2026-09-28.md` and `spec/windows.md` to `spec/history/verbatim/windows-retired-2026-09-28.md`, byte-identical (`cmp` to confirm).
- Add rows for both to `spec/history/README.md`, saying they're frozen copies, never edited, and superseded by the files listed in 5d.

Because the full originals are frozen, slicing may move and trim freely. The rules for the live docs still hold: **don't reword a decision or its reasoning**; built-work records may be condensed; superseded text goes to history, not the bin.

**5b. Slice `plan.md`.** Find sections by their headings, not by line number:

| Section in `plan.md` | New home |
|---|---|
| What it is · What it is not · Stack · Core data model · Settled 2026-09-20 | **Stays** in `plan.md` |
| Phases 1, 2, 2a, 2b, 2c, 3, 3b, 4 (all BUILT) · Inspector · Frame strip · Plugin seam | **Stays**, condensed. Each phase keeps its heading, BUILT date, the decisions with their reasoning, and any rule still live in code. Step-by-step build play-by-play is already in the verbatim copy; delete it from the live doc. |
| Phase 5: BGTools | Replace with a 2-line pointer to `bgtools.md`, after merging anything `bgtools.md` lacks |
| Video-export hook | Pointer to `video-export.md`, merging anything missing |
| Design posture: the six essentials | Merge into `how-we-design.md` |
| Pan and Zoom, and simple things fast | Merge into `simple-things-fast.md` |
| The range and the ruler | New `spec/range-and-ruler.md` |
| Groups inside collections | New `spec/groups.md` |
| The viewer drawer | New `spec/viewer-drawer.md` |
| Slides as mini movies | New `spec/slides-as-mini-movies.md` |
| Later · Open questions | `backlog.md` (parked / decision sections), if step 2 hasn't already |

Target: `plan.md` becomes the founding decisions and data model, **about 25 KB or less** (from 100 KB). Add a line at the top: *"New feature designs get their own spec in `spec/`, not a section here."*

**5c. Slice `windows.md`.** Same method:

| Section in `windows.md` | New home |
|---|---|
| Status block · The idea · Two kinds of window (areas that leave, editors for one thing) · Filling a new collection (the library panel) · Scrolling a window that's partly covered | **Stays** in `windows.md`: the pop-out concept and its pieces |
| The timeline pane · Panes that close to an edge · The timeline pane's left edge: the drawers | New `spec/timeline-pane.md`. Anything about how drawers *feel* merges into `panekit.md`'s "The clutch" section instead. |
| The windows pass · A reusable modal box · Where these windows open | New `spec/window-behavior.md` (window layers, Settings and preferences, About, SettingsBox, placement) |
| What it means to leave SwiftUI's split view · What already exists to build on · What stands in the way · the "Superseded by PaneKit" banner and the old ColumnsSplitView approach | `spec/history/` (dated file). Already superseded by PaneKit; the verbatim copy keeps them too. |
| Jason's answers (2026-09-24) | Fold each answer into the section it decided, dated. Answer 7 (double-click's meaning, undecided) goes to `backlog.md`. |
| A possible order (not a plan) | `backlog.md` |

Target: no single resulting file over about 30 KB. If "Where these windows open" (~440 lines) still exceeds that alone, condense its dated back-and-forth into history, keeping the settled rules.

**5d. Account for every heading.** Each new spec opens with the standard status block (Planned / Building / Built <date>, what's left → backlog IDs). Fix every inbound reference: `grep -rn "plan.md\|windows.md" spec CLAUDE.md .claude` and repoint to the new files, except inside `history/`, which is left as written. Then write a **coverage table** in the history README row (or a short `spec/history/verbatim/README.md`): every `##`/`###` heading of each verbatim file → where it now lives (a file, "condensed", or "history/<file>"). No heading may be missing from the table.

One commit per new file or merge, following the CLAUDE.md commit rules.

### 6. Make it stick
- `spec/history/README.md`: sort the table chronologically (currently out of order), and add rows for the new files.
- `CLAUDE.md` docs table: add `backlog.md` and every new spec from step 5; mark `history/verbatim/` as history; state the rule **status ≤150 lines, backlog is the only to-do list**; add a 5-line **end-of-session checklist** (dated story → history; close or add backlog IDs; update the touched spec's status block; run `tools/docs-check.sh`; commit).
- Add `tools/docs-check.sh`. It fails if: `status.md` > 200 lines; a relative `spec/…` link or file reference doesn't resolve; a doc named in the CLAUDE.md table is missing, or a `spec/*.md` isn't in the table; or `status.md` contains more than ~15 lines starting with a date-plus-story pattern. Skip `spec/history/verbatim/` for link checks, because its old relative links are expected to break. Keep it small and dependency-free.

## Done when

- `status.md` ≤150 lines; `grep -n "Still needs\|Parked for later" spec/status.md` finds only pointers.
- `spec/shakedown.md` exists with every item from the old hands list and the appendix results recorded; every appendix finding has a backlog ID.
- Every open item appears exactly once, in `backlog.md`; the other docs only point to it.
- `conventions.md` has no "not built" claim that the code contradicts.
- `tools/docs-check.sh` passes.
- Old "item N" references in `history/` still resolve via `(was item N)`.
- `spec/history/verbatim/` holds byte-identical copies of the original `plan.md` and `windows.md`; the coverage table accounts for every heading; `plan.md` is 25 KB or less and no sliced windows file is over about 30 KB; no live doc links to a section that moved.

## Report back (keep it short)
Line counts before and after (including `plan.md`, `windows.md` and each new spec); number of items consolidated, and how many turned out already built; the "Needs Jason" list of code-vs-doc conflicts and the Screenshot question; commit hashes.

## Not in this pass (flag only)
`panekit.md` (65 KB) and `conventions.md` (44 KB) are also large. Note any obvious split candidates in the report, but don't restructure them now.

## Appendix: Jason's shakedown, 2026-09-28
File each of these in `backlog.md` (step 2), and record the passes in `shakedown.md` (step 2b). Jason's raw notes are at the end; they are the source if this triage and they disagree.

**Passed by hand**, so mark them `[x] 2026-09-28`:
- The relocated Side by Side / Stack switch
- Viewer drawer
- Library grid tools in the bar
- The grid's keyboard: arrows and Return work. Quick Look is untried; its trigger is ⌘Y or double-click.
- Browser header switch
- Timeline keys
- Panels no longer float over other apps
- Windows pass and Settings tabs
- Transparency
- Timeline height
- Drawer sensitivity, merged with the clutch
- ⇧/⌘-click in the grid and the storyline
- Inspector slider live preview
- Edit Show's browser picks
- Rating keys and E/W/Q in the browser
- Dragging a song in
- Look and feel
- The pre-Phase-3 set

**Bugs:**
- **Popping a pane out, then closing its window, loses the content.** It happens for both the inspector (the drawer returns empty) and the timeline (the content never comes back). Likely one PaneKit root cause, so fix both together. P0.
- **The range marker drag runs faster than the mouse**, so the marker zips away. The status doc had called the overshoot "maybe a tool artifact"; it's real. P1.
- **The inspector's stars don't refresh after a rating key in the browser.** P2.
- **The inspector shows nothing for a selected file that isn't in the show.** The stars still work. P1.
- **BGTools double-click to launch.** Jason's suspicion: the first launch may be starting a second copy while one is already running. Investigate. P2.
- **The Rhythm tool detects double tempo.** It reads Fly Me to the Moon as 145, but the true tempo is about 72 BPM, so an octave or half-time check is needed. Jason also says the tool is "still to build," so confirm its state. P2.

**Decision reversals.** Update `conventions.md` in step 1, and add a backlog item:
- **Arrow keys in Show view follow focus: the area last clicked, or the active area.** They are no longer reserved for the timeline. Jason: reserving them was a mistake, and the default behaviour is what's wanted. This supersedes conventions §2's timeline-arrow rule. P1.

**Requests:**
- **Pop-out affordances for the inspector:** a right-click item, a button, or a click action. P2.
- **The range can extend past the show's current end,** so more tiles can be added. P1.
- **Clicking a range marker selects it** so it can be nudged. P1.
- **A numeric field for exact In and Out values.** P2.
- **A Library-view Info drawer on the right,** where the inspector sits elsewhere. A single click on the Info button opens the drawer; a double-click opens the existing Info window. P2.
- **Set Up Triggers:** merge the two submenu items into one control that lets you slide the Responsiveness slider and test the drawer in the same place. P2.

**For discussion**, so put these under "Needs a decision":
- **Viewer drawer with a group selected:** ←/→ moves the highlight within the collection, but ↑/↓ drops the group and returns to a single selection. Decide the intended behaviour.
- **The "Other Collections" switcher:** what belongs in its drop-down.

**Still unchecked**, so leave these `[ ]`:
- The multi-monitor half of BGTools' map and window placement
- Viewer menus and Show in Library
- Menus in Edit Slides, the browser and the inspector
- A real drag out of the library panel
- List view at the slider's minimum
- The Edit Slides list drop
- Groups in the Library pane
- Context menus C1–C3
- Menus batch 5
- Edit Slides playing
- The grid's first click
- Listening
- BGTools Touch ID, click-away and Space pause
- The range's two-modifier clicks, Fill's Library tab, and Displace

<details><summary>Jason's raw notes (verbatim)</summary>

```
Unresolved
- [ ] BGTools naming screens, map view, window placement: single monitor only. The multi-monitor behaviour was reasoned from the code, not seen.
- [ ] Viewer menus, Show in Library, the progress line.
- [ ] Menus in Edit Slides, the browser and the inspector (Copy and Paste Settings, quick settings).
- [ ] The library panel: it opens, but no real drag out of it has been tried.
- [ ] Grid list view at the slider's minimum, and the panel's independent slider.
- [ ] Drops onto slides and Replace Image: partly done. The storyline path was clicked through; the Edit Slides list drop was not exercised.
Built and compiled or smoke-tested only
- [ ] Groups in the Library pane: drag-to-add, nesting, the notices.
- [ ] Context menus C1–C3 (Remove Image, Transition, Marker).
- [ ] Menus batch 5: the Show and View menus. Check that no shortcut doubled up or went silent.
Needs a real hand, eye, ear or hardware; Claude can't do these
- [ ] Edit Slides playing: Slide viewer, looping, the live timeline.
- [ ] The grid's first click (the border should draw at once).
- [ ] Listening: sync, fades, crossfades, Bluetooth latency.
- [ ] BGTools: Touch ID, the panel closing on a click elsewhere, pausing on a Space switch.

Resolved
From before Phase 3: Finder and Photos drags, Touch ID and password, pinch, a second screen, cursors, ⌘Z with Info focused.
Look and feel: row handles, drawers, level-line handles, the transport toggles.
Dragging a song in from Finder or Music.
The Rhythm tool: its look, Listen, and whether Fly Me to the Moon is 145 BPM. me> still to build, but the fly me to the moon question is that that is twice the real speed of that track. It's more like 72bpm
Rating keys and E/W/Q in the browser. These failed synthetically because of focus, so they need a real click and then a keypress.
BGTools under the new signature: the Control Center tile and the login item. me> still logs in fine, still need to find the double click to launch thing. Maybe the first one is actually launching the program when it should already be running?
The clutch's feel: pull, brake, flick, swipe, natural-scrolling direction. Me> this one is redundant to another item on this list
Edit Show's browser: real ⌘/⇧ picks, a group dragged onto the timeline.
Audit G1 and the audio-naming pass. This item points to "the work queue above," which no longer exists, so it's stale. me>yeah, I think we can consider this one done or needed
Inspector sliders' live preview: never watched.
⇧/⌘-click in the grid and the storyline: unit tests only.
The drawers' sensitivity setting: checked mechanically, but tuning it by feel is the whole point.
Timeline pane height, both halves.

Arrow keys in the Show view need to be hot in the area last clicked, or the active area. I was trying to navigate the browser list and the arrow keys didn't work because they were driving the timeline. It was a mistake to reserve the arrow keys for the timeline in show view. It needs to work intuitively, probably the default behavior is what we really want after all.
The inspector's stars don't refresh after a rating key in the browser. This belongs in Known issues. Also the inspector isn't showing the info for selected files that aren't in the show, but the stars seem to work fine.
The range package W6–W10. Two-modifier clicks are unverified, and Fill's Library tab and Displace weren't tried. Mouse drag and IO markers slide speed is mismatched, the marker zips away from the mouse very fast. The range needs to extend beyond the current end of the show's length so I can add more tiles to a range. Clicking on the range marker needs to select it so I can nudge it. Where is a field that I can enter very specific values for in and out?
Timeline keys: arrow navigation, Go Back and Forward.
The grid's keyboard: arrows, Return to rename, Quick Look. Only the default tile size was tried. me> all work as expected, can't remember what quick look is triggered by, so I didn't try that.
Timeline full width, and popping it out (keys, menus, slide Delete). me> same problem as the inspector. Closing the window doesn't return the contents of the pane to the drawer.
Edit Show's inspector popping out, including undo from the popped-out window. me> this has a bug, making the inspector a pop out then closing it put the drawer back, but the inspector content is absent. Also we need to add right click and a button, or a mouse click action to pop the window out.
Viewer drawer: Y, the strip, Side by Side and Stack, arrows. The relocated Side by Side / Stack switch was not checked at all. Me> all checked and work. One thing for discussion is that moving left right with a selected group moved the highlight in the viewer amongst the collection, but up down released the group and went to single selection
Library grid tools in the bar: layout checked, but the buttons were never clicked. me> all checked and work. I'd like to have the info button open a side panel in library view, which needs to be added, on the right side where the inspector usually would be should be the info drawer. Double click info icon opens the window version which already exists.
Set Up Triggers box and Responsiveness slider: opening, bringing forward, floating, and closing Settings without closing the box. Me> we need to integrate the two items in the submenu into a single gizmo where you can slide the slider and test the drawer all in one.
The browser header's wider switch ("Other Collections"). Me> the drop down works fine. We'll have to fine tune what's in the switcher drop down.
Panels no longer float over other apps: checked with one Finder switch only.
Windows pass and the tabbed Settings: tabs, icons, resizing, panels stepping aside. The feel hasn't been judged.
Transparency module (Settings → Windows): the values were measured, never judged by eye.
```
</details>
