# Setlist export and import

**Status:** Built 2026-09-22 (4a–4d). **Open work:** see `spec/backlog.md`
(B-74, a pre-rename export losing Pan and Zoom); the round trip through
Numbers (4e) is a row in `spec/shakedown.md`. The build's own story and
its risks: `spec/history/2026-09-22-phase-4-setlist.md`.

Moved out of `spec/plan.md`'s Phase 4 on 2026-09-28, word for word.

## Phase 4, as planned (replanned with Jason 2026-09-22)

The first version of this section (2026-09-20) was written before slides had
transform, rotation, background or clip start, and before shows had the
images row, songs, markers, rows or editing state. Its flat TSV could no
longer carry a show, so it was replanned against what exists now.

**What it's for (Jason, 2026-09-22): both.** A folder of numbered copies to
use outside ShowTools (a USB stick, a TV, another app, Finder), *and* a way
to move a show to another library or Mac and get it back exactly. So import
must be lossless.

**The folder:**
```
Beach Trip/
  show.json          everything, exactly
  show.tsv           the readable one: open it in Numbers, edit, re-import
  001_beach.jpg      the slides, numbered in show order
  002_sunset.jpg
  ...
  music/             the show's songs
  overlays/          the images row's files
```
- **Slides at the top level, numbered** in show order. The number is padded
  to the slide count (a 1,200-slide show gets `0001_`), so Finder's order
  is the show's order. Songs and images-row files go in `music/` and
  `overlays/`, so they never interleave with the slides
- **The name after the number is the file's current name in the library**
  (after any batch rename), not the name it arrived with
- **One numbered file per slide**, even when the same photo is used several
  times. Unstripped copies are APFS clones, so on the same drive they cost no space; on
  another drive they're ordinary copies
- **Copies have their metadata stripped by default** (see "Settled" below).
  The originals in the library are never renamed, moved or changed

**`show.json`: the whole show.** The defaults, every slide's settings
(length, transition, Pan and Zoom, fit, clip start, transform, background,
rotation), the images row, the songs (start, in point, length, volume,
fades, their markers), the show's markers, its row order and its editing
state. Slides, songs and overlays refer to files by their path in the
folder, and carry the file's library hash so import can match what's already in the
library. It also carries each file's tags and rating, which import applies
only to files it brings in new. Caches (thumbnails, waveforms, similarity
prints) are not exported; they're rebuilt. A `"version": 1` field lets
later formats read old exports.

**`show.tsv`: the readable one, still editable.** Tab-separated, one line
per slide, a header row, show-wide defaults in `#` lines at the top, an
empty cell means "use the default". As built in 4a:
```
# ShowTools setlist v1
# name	Beach Trip
# default_length	5
# default_transition	dissolve 2 lead 1
# default_panzoom	off
# default_fit	fit
# default_background	#000000
# video_clip_length	yes
# loop	yes
# music	music/song.m4a
file	length	transition	panzoom_start	panzoom_end	fit	rotation	background
001_beach.jpg	8		0.5,0.5,1	0.3,0.4,1.4
002_sunset.png		swipe left 0.5
003_beach.jpg						0 to 90
```
Text forms: a length is seconds or `clip`; a transition is its style, its
direction when the style has one, the duration, and `lead N` when the lead
isn't 0; Pan and Zoom is `off`, `auto`, or `x,y,zoom` start and end; rotation
is `off`, `0 to 90` (angles) or `30/s` / `30/s from 10` (speed); a
background is `#rrggbb`. Numbers are written with at most three decimals.
Transform, the images row, songs and markers are in the JSON only; the
`# music` lines name the songs so the file makes sense on its own.

**Import: the JSON supplies everything, the TSV has the last word on what
it shows.**
- Slide order comes from the TSV's rows. Its columns override the JSON for
  that slide, so edits made in Numbers win
- A row deleted from the TSV drops that slide. A file added to the folder
  and given a row becomes a new slide with default settings. Rows are
  matched to the JSON's slides by filename (unique, since they're numbered)
- **A cell still reading what export wrote keeps the JSON's exact value.**
  The TSV rounds (three decimals, `#rrggbb`) and summarises (a rotation's
  pivots, a Pan and Zoom move's easing aren't in it), so only a cell that
  differs from what export would write for the JSON's value replaces it.
  A changed Pan and Zoom or rotation cell keeps the JSON's other details
- A row copied in the spreadsheet is a second use of that slide: same
  settings, its own auto Pan and Zoom move (as Duplicate gives in the app)
- A cell that can't be read keeps the JSON's value and is listed in the
  import's problems, with its line number
- **Auto Pan and Zoom stays the same move.** It's seeded from the slide's id,
  which a new library won't reuse, so `show.json` records each slide's
  original id and import carries it over as the slide's seed (an additive
  field in the slide settings, 4b)
- No TSV: the JSON alone. No JSON: the TSV alone, with everything it
  doesn't carry left at its defaults. Neither: see below

**Where an import goes:** a new show named after the folder, in the open
library and the current collection. Files already in the library (same
hash) are reused, not imported twice.
- **"Make a collection for it"** (Jason, 2026-09-22): a checkbox in the
  import panel that puts the show and its files into a new collection named
  after the folder instead

**A folder with no manifest at all:** a new show from its files in Finder's
name order, every slide on the defaults. In effect, "New Show from Folder".
Songs in such a folder aren't placed; the import lists them to add by hand
(built this way in 4b; say if they should go in the music row instead).

- **The same checkbox on File ▸ Import…** (Jason, 2026-09-22): when a
  folder is imported, "Make a collection for it" puts its files into a new
  collection named after the folder. As built (4d) it reads "Make a
  collection for each folder", since Import… takes several: each chosen
  folder gets its own collection (`.noindex` dropped from the name), and
  files chosen on their own still go where "Import into" says
- A name already taken gets a number, as New Show and New Collection do

**Settled with Jason 2026-09-22 (questions 7 to 11, as suggested, plus 9):**
- Scope: the whole show only. Exporting the range or a selection can come
  later
- **Privacy: metadata is stripped on export by default** (Jason). GPS,
  camera, dates and the rest come off the copies. A Preferences setting,
  "Strip metadata from exported files", turns it off; with it off, copies
  are byte-exact APFS clones. Measured 2026-09-22 (4a): JPEG is
  copied losslessly with its metadata replaced; HEIC, PNG, TIFF and
  animations are written afresh from their frames (pixel-identical in the
  tests; HEIC is lossy in principle, at quality 1.0); video and songs are
  remuxed, samples untouched (a real song decoded sample-for-sample the
  same). Orientation, animation timing and an AAC song's gapless figures
  are kept. **Songs keep their tags** (Jason, 2026-09-22): title, artist,
  album and the rest stay; only a purchased song's Apple ID, owner,
  purchase date, store and account type, and any location or recording
  date, come off. (`.forSharing()` was tried and dropped title and artist
  too.) Jason's two test songs kept all 17 tags, sample-exact. Every copy is read back: anything else left in it and the file
  is copied unstripped instead, listed in the export's result for the panel
  to show. A stripped copy has a new hash, so `show.json` records
  each file's *library* hash as well: import matches on that first, so a
  round trip into the same library reuses its files instead of importing
  near-copies
- The library is hidden from Spotlight; an export folder isn't. A "Hide
  from Spotlight" checkbox in the export panel adds `.noindex` to the
  folder's name, on by default when the library is private
- Exporting over an earlier export of the same show replaces it (the old
  folder goes to the Trash). Any other folder that isn't empty is refused
- Menu names: File ▸ Export Show… (⇧⌘E) and Import Show…. File already has
  "Import…" (files into the collection) and "Add to Library…", so the names
  must not blur with those. Checked 2026-09-22: Apple's guidelines define
  only "Export As…", for document apps writing a format they don't usually
  handle (the exported file isn't opened). Photos, the nearest app to this
  one, names the object: "Export Photos…", ⇧⌘E. So "Export Show…", ⇧⌘E
- Whether Numbers can save the TSV back as TSV (it may only export CSV):
  "we'll find out" (Jason, 2026-09-22), in 4e

**Build steps:** 4a core export, 4b core import, 4c Export Show… panel,
4d Import Show… panel (and the collection checkbox on Import…), 4e a
hands-on round trip on a scratch library, including an edit in Numbers.

