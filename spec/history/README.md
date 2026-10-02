# History

*RhythmIO (miO) was named ShowTools until 2026-10-02. Every "ShowTools" in
these files means RhythmIO, and every "BGTools" means RhythmBG (the desktop
player); `stcli` is now `mio`. The files keep the old names as written.*

Dated events: what happened, and when. **Never read these for current
rules or current state** — they are kept because they answer "why is it
like this?", and every one of them was true on its date and may not be
now. Current state is `spec/status.md`; rules are `CLAUDE.md`; decisions
are `spec/plan.md`.

| File | What it is | Superseded by |
|---|---|---|
| `2026-09-21-audit.md` | A read-through of the whole codebase, 2026-09-21, with the findings and what was done about them | Its fixes are in the code; nothing here is a live rule |
| `2026-09-21-hands-on.md` | Driving the app by hand against the handoff's "built but not yet tried" list | `spec/status.md` → Still needs Jason's hands |
| `2026-09-21-phase-3.md` | Phase 3 (music and the timeline) as built, step by step | `spec/plan.md` for the decisions |
| `2026-09-22-alpha-test.md` | The alpha test drive: what the demo show is, second by second, and what to look for | The test passed 2026-09-22 (`077568f`) |
| `2026-09-22-day-five.md` | The fifth session: the Xcode port, a video slide's own sound (V1–V5), and video export (E1–E5) with the traps each was found by | `spec/xcode-port.md`, `spec/video-audio.md`, `spec/video-export.md` |
| `2026-09-22-music-steps-6-7.md` | Beat detection (step 6) and rhythm patterns (step 7), planned then built | `spec/plan.md` under "Rhythm patterns" |
| `2026-09-22-phase-3b.md` | Find Similar, Delete by context, Keep One | — |
| `2026-09-22-phase-4-setlist.md` | Setlist export and import, 4a–4d (reordered here into a–d; the handoff had them in the order they were written) | `spec/status.md` for the open risks |
| `2026-09-23-crash-hunt.md` | The intermittent launch crash: 25 reports, the reason string, and why the earlier bisect was worthless | `spec/status.md` carries the short version and points here |
| `2026-09-23-crash-hunt-session2.md` | Same crash, a second session: the methods tried (stack-trace reading, three reverted fix attempts, automated repro counting) and where the repro counting went wrong — read for method, its conclusions are flagged suspect | `spec/status.md`'s Known Issues entry, itself flagged there as unverified against Jason's own hands |
| `2026-09-23-crash-hunt-session3.md` | Same crash, third session: the cause found (SwiftUI's `.inspector()` on Edit Slides), two false leads closed, and the methodology failures named | `spec/edit-slides-inspector-port.md` (the fix) |
| `2026-09-23-docs-restructure-brief.md` | The brief this folder was made from: why the docs had drifted, and the layout Jason approved | Carried out the same day; the result is the current docs |
| `2026-09-23-pan-and-zoom-rename.md` | Ken Burns → Pan and Zoom carried out (168 refs, three shell scripts missed by the first pass), the stale installed app rebuilt, and the confirmed breakage: an export from before this date loses Pan and Zoom silently on re-import | `spec/status.md` carries the short version and points here |
| `2026-09-24-cloud-planning-aar.md` | After-action review of the cloud planning session, in two parts. Part one: the audit, the anatomy, the renames, windows, simple things fast, conventions, the design manual. Part two: the right-click conversation, groups, the work order, PaneKit's first cut. What went well and what didn't | `spec/status.md`'s work queue |
| `2026-09-24-crash-hunt-debrief.md` | The crash hunt looked back on, in Jason's words: volunteered design never crash-tested, a latent bug hunted from the newest change backwards, conjecture built on, what ended it, and whether macOS 27 was part of it | `spec/how-we-design.md` holds the lessons |
| `2026-09-24-windows-before-panekit.md` | From `spec/windows.md`, sliced 2026-09-28: the banner saying PaneKit superseded it, the assessment of leaving SwiftUI's split view, what existed to build on, what stood in the way, and "A possible order" (every step built) | `spec/panekit.md`, `spec/windows.md` |
| `2026-09-24-work-order.md` | Jason's first-test notes as a work order (written with App Claude): the slide progress line, the range, Go Back, Fill Range with Images, and five BGTools items | Folded into `spec/plan.md` ("The range and the ruler"), `spec/bgtools.md` ("Jason's first-test list") and `spec/status.md`'s queue, item 9 |
| `2026-09-25-feedback-worklist.md` | Jason's Sep 25 feedback worklist (was at the repo root): 38 items, P0–P3. **"Item N" everywhere means its number here.** How each was handled: `2026-09-25-feedback-worklist-batches.md`. Still open on 2026-09-28, now backlog items: 23 → B-15, 24 → B-14, 25 → B-16, 26/27/29 → B-62, 33 → B-36, 35 → B-37, 36 → B-30, 37 → B-39, 38's follow-on → B-34, 12's follow-on → B-46 | `spec/backlog.md` |
| `2026-09-25-docs-hygiene-note.md` | Jason's Sep 25 docs-hygiene note (was at the repo root): a stale build (resolved that day), three stale `conventions.md` claims, `status.md` too long. Handled 2026-09-28 by the docs hygiene pass: `conventions.md` checked against the code (the ⌥-click row-handle claim was a misread: that line is about ⌘⌥-clicking a row, not built), status cut to the present tense | `2026-09-28-docs-hygiene-pass.md` |
| `2026-09-25-feedback-worklist-batches.md` | Jason's 37-item build feedback, worked through in batches: what was fixed, how, and what each fix was checked against. Batches 6–8 and item 20 (ratings) were moved in from status on 2026-09-26, word for word, along with the value-changer proposal that became ModKit | `spec/status.md`; the specs each item touched |
| `2026-09-25-drag-reorder-session.md` | Item 17's first attempt: the reorder schema, live reflow, three bugs found by hand, a self-inflicted regression and its correction (the Custom Order notice + header strip), and a drag that didn't work by hand (its diagnosis retracted) | `2026-09-25-drag-reorder-rebuild.md`, then `spec/plan.md`'s "Reordering" |
| `2026-09-25-drag-reorder-rebuild.md` | Item 17 rebuilt: the real defect (a tile-feedback loop, seen only by watching), the gap and grid-wide drop, Undo that never reached the menu, AppKit's tilted stack replaced by our own pile, edge scrolling with the ramp and live shrink; wrong turns and method notes | `spec/plan.md`'s "Reordering" (terms and dials) |
| `2026-09-25-work-queue-narrative.md` | The 2026-09-24 cloud-planning work queue, built out: the audit batches, Groups inside collections, the range package, the grid's keyboard, PaneKit steps 4–5, the popped-out Inspector and Timeline panes | `spec/status.md`'s "Where it stands" table |
| `2026-09-26-viewer-drawer-and-icon.md` | Pinch, ⌘A in the timeline, the app icon twice (how Icon Composer's mask and opaque backing were measured), and the viewer drawer: planned by Q&A, built in four steps, then the tools moved into its bar and the sort strip made a handle; method notes (the pid-guarded axtool, leftover preference keys). Also, moved in from status: the right-click hunt ("No menu yet") and how the final icon was made | `spec/plan.md` ("The viewer drawer"), `spec/conventions.md` §3, `spec/status.md` |
| `2026-09-26-slides-and-the-clutch.md` | The evening of 2026-09-26: the worklist's last answers, the grid's half-second click, item 33 turning into "Slides as mini movies" (live timeline, looping Play, the Slide viewer), the drawers' clutch draft by draft (bite and slip, the bow, literal distances, flick and swipe, the brakes, the resize cursor), and the tap-to-drag saga (drag lock, Apple Development signing, the WWDR G3 certificate, stale TCC entries, the post that couldn't end the hold); mistakes worth remembering | `spec/plan.md` ("Slides as mini movies"), `spec/panekit.md` ("The clutch"), `spec/windows.md`, `spec/conventions.md`, `spec/how-we-design.md` |
| `2026-09-26-timeline-height.md` | Later on 2026-09-26: the timeline's height ceiling (PaneKit's content tracking) and the browser's header as a switcher, scoped then built | `spec/timeline-pane.md` ("Its height"), `spec/groups.md` ("The browser filter"), `spec/panekit.md` |
| `2026-09-27-windows-pass.md` | The windows pass's three settled pieces built (panel hiding as a setting, Settings frontmost with panels stepping aside, About), the rest left for discussion | `spec/window-behavior.md` ("The windows pass") |
| `2026-09-27-settings-box.md` | The Set Up Triggers box through three shapes in one session (app-modal → tied to Settings' lifecycle → a floating panel, each reversed by Jason trying the last one); where these windows open (the triggering monitor, then relative to Settings' own position) and their titles ("ShowTools Settings: Windows," then "Windows: Set Up Triggers," corrected to "Drawer Sensitivity: Set Up Triggers" — the module, not the tab); the viewer drawer's switch let loose from its own reserved bar; method notes (a canary value proving code isn't running, `frame.size` reading `.zero` longer than expected, testing pixel-identical windows alongside Jason's own live copy) | `spec/windows.md` ("A reusable modal box," "Where these windows open"), `spec/panekit.md` ("The clutch"), `spec/plan.md` ("The viewer drawer"), `spec/status.md` |
| `2026-09-27-transparency-rework.md` | From `spec/windows.md`, sliced 2026-09-28: the transparency setting built, reworked into the Transparency module, the header bar's scroll-under, the Catalog's bars, `.withinWindow` never compositing over a `List`, the sidebar leaving `List`, and the regressions found on the way | `spec/window-behavior.md`, "The Transparency module" |
| `2026-09-27-bands-listkit-transparency.md` | The evening of 2026-09-27: the empty bands, the timeline's height (measured), ListKit (sidebar and browser off `List`), the Transparency module, handle rows; commit by commit, what it taught, and two status narratives moved in word for word | `spec/status.md`, `spec/listkit.md`, `spec/panekit.md`, `spec/windows.md` |
| `2026-09-28-status-archive.md` | The whole of `spec/status.md` as it stood before the docs hygiene pass, word for word (652 lines): its built-most-recently narratives, What's next, Parked, Still needs Jason's hands, Open questions, Known issues. Also records "Audit G1 and the audio-naming pass" closed as done by Jason | `spec/status.md`, `spec/backlog.md`, `spec/shakedown.md` |
| `2026-09-28-docs-hygiene-pass.md` | The work order for the 2026-09-28 docs hygiene pass (written with App Claude), with Jason's shakedown of that day in its appendix, raw notes included | `spec/backlog.md`, `spec/shakedown.md`, `spec/history/verbatim/` |
| `2026-10-02-b01-pop-out-close.md` | B-01 fixed: closing a popped-out pane's window left its content in the closed window (`windowClosed` dropped the window's record before `putBack`); checked in the app for the inspector and the timeline | `spec/panekit.md`, "Pane ⇄ panel" |
| `2026-10-02-b03-arrows-follow-click.md` | B-03 built (`KeyboardArea`: the arrows follow the last click, selections grey elsewhere); the grid's ⇧-arrow (held arrows were swallowed; arrows stepped from a stale cursor); the `hitTest` coordinate trap | `spec/conventions.md` §2, `spec/backlog.md` B-83, B-84 |
| `2026-10-02-rename-rhythmio.md` | ShowTools → RhythmIO, BGTools → RhythmBG, overnight (B-85): what a mechanical rename gets wrong (possessives, `stcli` in `SetlistClip`, measured ids in a spec, the tiles' old `kind` prefix) and what was left for Jason's morning | `spec/status.md` (B-86) |
| `2026-10-02-rename-inventory.md` | The rename's hit list (B-85): every mention of ShowTools, BGTools and stcli outside history, taken before anything was renamed | The rename itself (`2026-10-02-rename-rhythmio.md`) |
| `verbatim/` | Byte-identical copies of `spec/plan.md` and `spec/windows.md` as retired 2026-09-28, never edited; its README maps every heading to where it lives now | The files its README lists |

## Where this came from

Everything dated 2026-09-21 or later in this folder except the audit, the
hands-on and the alpha test was one file, `spec/handoff.md`, which had
grown to 773 lines of narrative in the order it was written rather than
the order things happened. It was split up on 2026-09-23 and the parts
moved here **with their wording intact** — the exact phrasing of a
measurement or a trap is the valuable part of them.

Because they were one document, a few of these still say "below" or "see
above" about something that now lives in a different file, and the
2026-09-22 files each describe a state of play that later files change.
That is the nature of the folder: read them as dated notes, not as a
manual.
