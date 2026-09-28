# Verbatim copies

Frozen, byte-identical copies of docs retired on 2026-09-28, made before
they were sliced (`cmp` confirmed). **Never edited, never read for
current state.** Their relative links are expected to break;
`tools/docs-check.sh` skips this folder.

| File | Was | Superseded by |
|---|---|---|
| `plan-retired-2026-09-28.md` | `spec/plan.md` at `1f14bf0` (100 KB) | `spec/plan.md` (the founding decisions and phases), `spec/rhythm.md`, `spec/setlist.md`, `spec/range-and-ruler.md`, `spec/groups.md`, `spec/viewer-drawer.md`, `spec/slides-as-mini-movies.md`, `spec/backlog.md` |
| `windows-retired-2026-09-28.md` | `spec/windows.md` at `1f14bf0` (76 KB) | `spec/windows.md` (the pop-out idea), `spec/timeline-pane.md`, `spec/window-behavior.md`, two history files |

## Coverage: every heading, and where it lives now

"Stays" means it's still in the file of the same name, word for word
unless noted. "Condensed" means built-work play-by-play was cut; the
decisions stayed.

### `plan-retired-2026-09-28.md`

| Heading | Now |
|---|---|
| ## What it is | Stays, `plan.md` |
| ## What it is not (for now) | Stays, `plan.md` |
| ## Stack | Stays, `plan.md` |
| ## Core data model | Stays, `plan.md` |
| ### Library | Stays, `plan.md` |
| ### Show | Stays, `plan.md` |
| ### Video-export hook (built in from day one) — PAID OFF 2026-09-22 | `video-export.md`, "The hook, as planned" (word for word); `plan.md` keeps a pointer and the one-clock rule |
| ## Phases | Stays, `plan.md` |
| ### Phase 1: Library + player — BUILT 2026-09-21 | Condensed, `plan.md` (its "Not yet" list, all done, reduced to a line) |
| ### Phase 2: Composer — two modes — BUILT 2026-09-21 | Stays, `plan.md` |
| ### Phase 2a: Framing, rotation and match cuts … | Stays, `plan.md` (Presets point to backlog B-61) |
| ### Phase 2c: The lane — transitions and image layers … | Stays, `plan.md` (stickiness points to backlog B-41) |
| ### Inspector: the slide, then its effects | Stays, `plan.md` |
| ### Frame strip (built 2026-09-21) | Stays, `plan.md` |
| ### Plugin seam | Stays, `plan.md` |
| ### Phase 2b: Library manager — BUILT 2026-09-21 | Stays, `plan.md` |
| ### Phase 3: Music + timeline — BUILT 2026-09-22 | Condensed, `plan.md` (video sound and stickiness become pointers) |
| #### Beat detection, the range, and rhythm (settled 2026-09-21) | `rhythm.md`, word for word |
| ### Phase 3b: Find Similar, and Delete by context … | Stays, `plan.md` |
| ### Phase 4: Setlist export / import … | `setlist.md`, word for word; `plan.md` keeps a summary and pointer |
| ### Phase 5: BGTools … | `plan.md`, a two-line pointer to `bgtools.md` (which had everything) |
| ### Design posture: the six essentials | `how-we-design.md`, "The six pillars" and "Perceptual efficiency" (already there in full); `plan.md` points |
| ### Pan and Zoom, and simple things fast | `simple-things-fast.md`, "Where this started: Pan and Zoom", word for word |
| ### The range and the ruler, after the first test | `range-and-ruler.md`, word for word |
| ### Groups inside collections … | `groups.md`, word for word (subheadings added: The browser filter, Promotion, Reordering, Nesting by drag) |
| ### The viewer drawer — Planned | `viewer-drawer.md`, word for word (its "Open" line points to backlog B-55) |
| ### Slides as mini movies … — Building | `slides-as-mini-movies.md`, word for word (Smart View given a subheading) |
| ### Later | Split: "Replace a slide's image" (built) stays in `plan.md` as its own section; video export and beat detection were struck through, done; the rest are `backlog.md` items with their wording in its "Design notes" (B-12, B-22, B-43, B-56, B-69, B-70, B-40) |
| ## Settled 2026-09-20 | Stays, `plan.md` |
| ## Open questions | `plan.md`, a pointer to `backlog.md` (image stickiness is B-41) |

### `windows-retired-2026-09-28.md`

| Heading | Now |
|---|---|
| (status block and the "Superseded by PaneKit" banner) | Status rewritten in `windows.md`; the banner is `history/2026-09-24-windows-before-panekit.md` |
| ## The idea | Stays, `windows.md` |
| ## Two kinds of window | Stays, `windows.md` |
| ### 1. Areas that can leave the main window | Stays, `windows.md`, with Jason's answers 2–6 folded in under it |
| ### 2. Editors for one thing | Stays, `windows.md` |
| ## The timeline pane | `timeline-pane.md`, "What it is" and "Its height", word for word |
| ## Panes that close to an edge, inside one window | `timeline-pane.md`, word for word (a note added that PaneKit built it) |
| ### What it means to leave SwiftUI's split view | `history/2026-09-24-windows-before-panekit.md` |
| ### The timeline pane's left edge: the drawers | `timeline-pane.md`, "The drawers: the timeline pane's left edge" |
| ## What already exists to build on | `history/2026-09-24-windows-before-panekit.md` |
| ## What stands in the way | `history/2026-09-24-windows-before-panekit.md` |
| ## Jason's answers (2026-09-24) | Folded: 1 (the build order) into `windows.md`'s status; 2–6 under `windows.md` "1. Areas that can leave the main window"; 7 (double-click) is `backlog.md` B-48 |
| ## The windows pass | `window-behavior.md`, word for word |
| ## A reusable modal box | `window-behavior.md`, word for word |
| ## Where these windows open | `window-behavior.md`: the placement and titles word for word; its "Goes in the same pass" list kept, with item 2 (the transparency rework, 21 KB of dated back-and-forth) moved word for word to `history/2026-09-27-transparency-rework.md` and condensed as "The Transparency module" |
| ## Filling a new collection | Stays, `windows.md` |
| ## Scrolling a window that's partly covered | Stays, `windows.md` (backlog B-66) |
| ## A possible order (not a plan) | `history/2026-09-24-windows-before-panekit.md` (every step built) |
