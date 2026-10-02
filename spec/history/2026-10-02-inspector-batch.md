# 2026-10-02 — The inspector batch: B-04 and B-07, one cause

Jason's shakedown of 2026-09-28 listed two inspector items side by side:
"the inspector's stars don't refresh after a rating key in the browser"
(B-07, P2) and "the inspector isn't showing the info for selected files
that aren't in the show, but the stars seem to work fine" (B-04, P1).

**Reading didn't find B-07.** The rating key reached the model, the model
updated `itemsByID`, the inspector read it, and `StarRating` keeps no copy.
So it was driven in a test copy (Jason away, screen handed over): a slide
picked and rated in the browser refreshed, docked and popped out; Edit
Slides' list takes no rating keys at all (by design, "in the grids").

**Reproduced with a file not in the show.** The scratch show used all its
files, so one more was ingested into the collection only. With clip.mov's
slide selected, picking that file and pressing 4 rated the file — and the
inspector still showed clip.mov, unrated. The browser's pick handler had
`case .file, .song: break`: picking a file left the show's slide selection
as it was. From nothing selected that's B-04 (an empty inspector); from a
slide selected it's B-07 (that slide's stars, which the key never touched).

**The fix.** Picking only files not in the show lets go of the slides and
sets `ShowSession.inspectedFiles`; the inspector then shows the Info
window's own view (`InfoPanelContent`, given the files) under "Not in this
show". Selecting anything in the show clears it. Checked with axtool: the
file's info and stars, a key moving them, a slide bringing the slide
inspector back. Picking an audio clip's row still leaves the slides
selected (`.song` unchanged), which the anatomy says shows nowhere anyway.
