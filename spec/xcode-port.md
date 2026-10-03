# Porting RhythmIO's packaging to Xcode

**Status:** Built 2026-09-22 (P1–P7). **Left:** nothing.

**Names since the rename (B-85, 2026-10-02).** This spec uses the new
names throughout, but everything below was measured under the old ones:
`com.jhg.showtools`, `com.jhg.showtools.bgtools` and
`com.jhg.showtools.bgcontrols`. One thing changed shape, not just name:
the player's id, `com.jhg.rhythmbg`, no longer sits under the host's
(the extension's still must, and does). A login item has no such rule,
but it hasn't been measured; Jason's first install checks it (B-86).

**Why.** Jason: RhythmBG shouldn't be orphaned when RhythmIO is deleted —
one app should hold both. Measured the same day: a helper app nested in
`Contents/Library/LoginItems` runs, takes its `rhythmbg://` URLs, launches
from cold and can be registered at login, but **its own Control Center
tiles never register** (macOS registers an app's extensions only when that
app is itself registered at a scanned location — `~/Applications`,
`/Applications` — and has been launched; a nested app never is).

`tools/nest-probe` then proved the way round it, end to end:

- an **Xcode-built host app** carries the tile extension itself,
- the helper app sits nested in `Contents/Library/LoginItems`,
- the tile registers, and **a tile press reached the nested helper**
  (Jason pressed it; the helper had been quit and was launched by the
  system),
- `SMAppService.loginItem(identifier:)` registered the nested helper —
  Background Task Management lists it enabled and allowed.

RhythmIO can't host tiles as it is, because it isn't an Xcode-built app:
it's a SwiftPM binary wrapped in a bundle by hand (`make-app.sh`), so its
embedded extension is never properly built or signed as one. Hence this
port.

## What the finished arrangement looks like

```
RhythmIO.app                            (Xcode target, com.jhg.rhythmio)
  Contents/PlugIns/RhythmBGControls.appex (com.jhg.rhythmio.bgcontrols)
  Contents/Library/LoginItems/RhythmBG.app(com.jhg.rhythmbg)
  Contents/Resources/Fonts/Bravura…
```

- The **package keeps everything real**: `RhythmIOCore`,
  `RhythmIOPlayback`, `RhythmBGCore`, `mio` and all the tests stay
  SwiftPM, built and tested with `swift test` as now. Only the two app
  bundles move to Xcode.
- Tiles open `rhythmbg://` URLs, which reach the nested RhythmBG, launching
  it if it's quit (measured).
- RhythmIO registers RhythmBG at login with
  `SMAppService.loginItem(identifier: "com.jhg.rhythmbg")`.
- Deleting RhythmIO takes RhythmBG, its tiles and its login item with it.

## Steps

- **P1 One project.** Extend `RhythmBG/project.yml` into a project at the
  repo root (`RhythmIO.xcodeproj`, generated; keep it gitignored) with
  three targets: `RhythmIO` (app), `RhythmBG` (app, nested by a copy phase
  into `Contents/Library/LoginItems`), `RhythmBGControls` (extension, in
  RhythmIO's PlugIns). Package products as dependencies, as RhythmBG does
  now. Sources stay where they are.
- **P2 RhythmIO's bundle.** Carry over every Info.plist key `make-app.sh`
  writes: `ATSApplicationFontsPath` (Fonts), the exported drag type
  `com.jhg.rhythmio.items`, `LSMinimumSystemVersion`,
  `NSHighResolutionCapable`, `NSSupportsAutomaticTermination` false. Copy
  `Resources/Fonts` in. Unsandboxed, ad hoc signed, hardened runtime off
  (as now).
- **P3 Identities.** RhythmBG becomes `com.jhg.rhythmbg` and the
  extension `com.jhg.rhythmio.bgcontrols` (an extension's id must sit
  under its host's; the probe's did). Keep the `rhythmbg://` scheme and the
  tiles' `kind` strings, so nothing else changes. Note in the spec that
  RhythmBG's saved window position and login registration start fresh; its
  settings file (`~/Library/Application Support/RhythmBG/settings.json`)
  and the tiles' state file don't move.
- **P4 Installing.** Delete `RhythmBGInstall`'s copying: View ▸ Desktop
  Show… now launches the nested RhythmBG and registers it at login.
  Remove `LoginItem.registerOnceIfInstalled` from RhythmBG (RhythmIO owns
  that decision); keep the "Open at login" switch, which flips the same
  registration.
- **P5 Build scripts.** `make-app.sh` becomes a thin wrapper around
  `xcodebuild` producing `build/RhythmIO.app` (and keeps its name, since
  CLAUDE.md and habits point at it). `RhythmBG/build.sh` goes away.
  `install.sh`: copy `build/RhythmIO.app` to `~/Applications` and launch
  it once — tiles only register from there.
- **P6 Check it.** `swift test` (175 + 12) unchanged; then by hand:
  RhythmIO opens a scratch library, plays a show, the fonts are there
  (Rhythm panel notation), a drag from the Collection Browser still works;
  RhythmBG plays on each Space, its window and panel open, both tiles
  appear and work, and login registration shows in System Settings.
- **P7 Tidy.** Remove `~/Applications/BGTools.app` and the old tiles,
  `tools/nest-probe/remove.sh`, and update CLAUDE.md (build, install and
  test commands) and the handoff.

## Risks, from today's experience

- **Caches lie.** New or renamed tiles need a build-number bump and
  `killall chronod`, and LaunchServices may need `lsregister -f`. Two
  rounds were lost to this today; expect it, don't debug it.
- **Signing order.** Three nested pieces, ad hoc: the extension and the
  nested app must be signed before the outer app. XcodeGen did this in
  the probe, but RhythmIO is bigger.
  **Since 2026-09-26 all three are signed "Apple Development", team
  `P82S39V2KJ`** (Jason's free Personal Team; `project.yml`'s base
  settings), so a permission granted to RhythmIO survives rebuilds.
  Two traps met on the way: the keychain had only the WWDR intermediate
  that expired in 2023, so the new certificate showed as "0 valid
  identities" until Apple's G3 intermediate (apple.com/certificateauthority,
  checked against the system's Apple Root CA) was added to the login
  keychain; and the first build failed "Embedded binary is not signed
  with the same certificate as the parent app" because unchanged
  embedded targets kept their old ad-hoc signatures — `rm -rf
  build/xcode/Build` and build again. The extension re-registered on
  install (`pluginkit -m -v`).
- **Tiles need an installed copy.** Testing them means `install.sh`, not
  `build/RhythmIO.app`. The library rule doesn't change: test launches
  still set `RHYTHMIO_LIBRARY` to a scratch library, and RhythmBG still
  takes `RHYTHMBG_SETTINGS`.
- **Keep the working build.** Don't delete the current
  `~/Applications/BGTools.app` or its tiles until the new arrangement
  plays a show, opens the panel and shows both tiles.

## Not part of this port

Jason's hands-on pass on RhythmBG (private unlock, the panel closing on a
click elsewhere, Space-switch pausing), the Pan and Zoom cost (~40% of a core
while it moves), and telling RhythmBG when a library moves. Video export
was also outside it — that has since been built (`spec/video-export.md`);
the render hook this port left in place is what it uses.

## Done, 2026-09-22 (fourth session)

All of P1–P7, in one pass. The project built on the first try and every
check passed.

- **The project** is `project.yml` at the repo root (`RhythmIO.xcodeproj`
  generated, gitignored), three targets, deployment target 14.0 for
  RhythmIO and 26.0 for RhythmBG and the tiles. XcodeGen signed the three
  nested pieces in the right order without help; nothing had to be done
  about signing order after all.
- **Identities** are as planned: `com.jhg.rhythmio`,
  `com.jhg.rhythmbg`, `com.jhg.rhythmio.bgcontrols`. The tiles'
  `kind` strings are unchanged.
- **P4** `RhythmBGInstall.swift` became `RhythmBGHelper.swift`: no copying,
  no `isInstalled`, so the menu item is plain "Desktop Show…". It
  launches the nested RhythmBG and calls `registerAtLogin`.
  RhythmBG's `LoginItem` lost `registerOnceIfInstalled` and now uses
  `SMAppService.loginItem(identifier:)`, not `.mainApp` — a nested app
  can't register itself as `mainApp`, and its "Open at login" switch must
  flip the registration RhythmIO made. (It couldn't: from inside, the
  status reads not-registered and `register()` fails with error 22. The
  switch moved to RhythmIO ▸ Settings ▸ RhythmBG, 2026-10-03, B-87;
  RhythmBG's ⋯ menu has "Open at Login…", which opens that tab.)
- **P5** `install.sh` passes `RHYTHMIO_LIBRARY` through to the launch
  when it's set, so the script itself can be checked without opening the
  real library.

### Measured

- `swift test`: 175 + 12, unchanged.
- The app opens a scratch library, plays a show, and Bravura renders in
  the Rhythm panel — `ATSApplicationFontsPath` works in an Xcode bundle.
- Installed copy → Desktop Show… → the nested RhythmBG launched, took
  `rhythmbg://window` and opened its window. Background Task Management
  lists `com.jhg.rhythmbg` **enabled, allowed**, with parent
  `com.jhg.rhythmio`.
- `pluginkit` lists `com.jhg.rhythmio.bgcontrols` from
  `~/Applications/RhythmIO.app`; **Jason confirmed both tiles work in
  Control Center**.

### Taken out (P7)

`~/Applications/BGTools.app` (to the Trash) with its tiles, the nest
probe, and the control probe's build products; `RhythmBG/build.sh` and
`RhythmBG/project.yml`. `pluginkit` now lists one tile extension, the new
one. The probes' sources stay in `tools/`, as the record of what was
measured.

Left behind: stale Background Task Management entries for
`com.jhg.bgtools` and the two `com.jhg.nestprobe` ids, whose bundles are
gone. `sfltool resetbtm` would clear them but resets every app's login
items, so they're left for macOS to prune, or for Jason to remove in
System Settings ▸ General ▸ Login Items.
