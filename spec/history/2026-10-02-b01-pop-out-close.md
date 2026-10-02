# 2026-10-02 — B-01: closing a popped-out pane's window lost its content

Jason's 2026-09-28 shakedown: pop the inspector out, close its window, and
the inspector's place comes back empty; do the same with the timeline and
it never comes back at all. One cause for both.

**Cause.** `PaneController.windowClosed` (closing the window by its close
button) removed the window's entry from `windows` *before* calling
`putBack`. `putBack` → `perform` → `syncWindows` returns a pane's host by
taking it out of that same dictionary, found nothing, and so never called
`returnHost`. The host stayed inside the closed window. The menu's put-back
didn't go through `windowClosed`, which is why it always worked.

**Fix** (`ad7adbb`). `windowClosed` now takes the host back itself, then
updates the state. A new PaneKit test
(`testClosingPoppedOutWindowReturnsContent`) failed before the fix and
passes after (56 PaneKit tests).

**Checked in the app** with axtool on a scratch library: the inspector
popped out, its window closed by the title-bar button, and its content
("No slide selected") came back at its old place, 320 pt wide; the timeline
likewise came back full width with its rows. A screenshot confirmed both
were drawn. Jason's preferences were restored after (three keys the test
copy changed: `inspectorShown`, `PaneKit.EditShowColumns`, `PaneKit.main`).

**On the way.** The first close click landed on a "Type to Siri" box that
was open over the panel's title bar; Jason closed it and the check went on.
A screenshot of the target before clicking is what caught it: the click
"did nothing" otherwise looked like a failed fix.
