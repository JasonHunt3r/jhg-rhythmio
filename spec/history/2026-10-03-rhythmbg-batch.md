# 2026-10-03 — RhythmBG batch: B-14, B-87, B-17

Three RhythmBG items from status.md's "What's next", each settled by one
question to Jason first and built as its own commit (311e062, 8d0ed15,
43d6674).

**The three answers.**
- B-87: where the login switch lives. Jason chose **both places, RhythmBG
  handing off** over my recommendation (RhythmIO's Settings only): the
  switch is in RhythmIO ▸ Settings ▸ RhythmBG, and RhythmBG's ⋯ menu keeps
  an "Open at Login…" that opens that tab.
- B-14: **a monitor that's off beats Synchronize**; a Space's Plays
  Nothing doesn't (Synchronize overrides it like any per-Space choice).
- B-17: **a submenu of monitors plus Every Screen**; one monitor, a plain item.

**What turned up.**
- A screen whose setting stops playing kept its desktop window, which is
  black, not transparent: `update()` only re-applied players, and only
  `rebuild` closes windows. Without the fix a monitor switched off would
  have gone black instead of showing the wallpaper. `update()` now
  rebuilds (apply alone when the layout hasn't changed).
- RhythmIO had no URL scheme; `rhythmio://settings/<tab>` is new, and the
  Settings TabView now keeps its tab in `settingsTab` so a URL can pick
  one. Both URLs (to RhythmIO and to RhythmBG) are opened with the exact
  app bundle (`open(_:withApplicationAt:)`) so a test build never catches
  the other app's request.
- From RhythmIO (even the build copy) the login item reads enabled: the
  status that RhythmBG can't see from inside is visible to its host.
- One monitor connected all session, so the submenu and two-monitor
  behaviour are reasoned from code and the unit test only.

**Checks.** Scratch RhythmBG copies (`RHYTHMBG_SETTINGS`): the off state
screenshotted with the desktop show off; the play URL sent and the
settings file and log read (the show played on the desktop for about two
seconds). A test RhythmIO opened Settings on the RhythmBG tab from the
URL; the switch wasn't flipped (it's Jason's real login item), and his
preferences were restored and diffed identical. Not seen: the switches'
green (inactive windows draw switches grey), the RhythmIO menu itself.
All are shakedown rows.
