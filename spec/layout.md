# Layout — where everything lives

**Reference.** The file-by-file map of the codebase: which target owns
what, and the few structural rules that go with each. Rules live in
`CLAUDE.md`, current state in `spec/status.md`.

- `Sources/RhythmIOCore/`: no UI. Models, the SQLite library, ingest, the
  timeline (`ShowTimeline.frame(at:)`), the `Compositor`, and setlist
  export (`Setlist`, `MetadataStrip`). Everything
  that draws a show goes through `frame(at:)` → `Compositor.compose`,
  the video exporter included. Keep it that way.
- `Sources/RhythmIOPlayback/`: the player, shared with RhythmBG:
  `PlaybackEngine`, `ShowCanvas`/`ShowCanvasView`, `MediaProvider`,
  `MusicPlayer`. The engine reads shows and files through `ShowSource`
  (AppModel is one; RhythmBG's read-only reader will be another), never the
  app's types. Anything the app uses from here must be `public`.
- `RhythmBG/`: the desktop companion app (spec `spec/rhythmbg.md`) and its
  Control Center tiles (`RhythmBG/Controls`). Both are targets of the root
  `project.yml`, and the built RhythmBG is nested inside RhythmIO at
  `Contents/Library/LoginItems/RhythmBG.app`.
  It opens libraries with `Library(readingOnly:)` only. Its settings and
  the show each mode builds are in `Sources/RhythmBGCore` (tested), which
  RhythmIO also imports, only to read RhythmBG's monitor names for Play on
  Desktop (B-17); it never writes RhythmBG's settings, it sends a URL. How to
  launch and drive it is in the `rhythmio-testing` skill.
- `ListKit/` (top level): our own lists for when `List` can't be used,
  **for any Mac app**, its own Swift package depending on nothing
  (`spec/listkit.md`). `cd ListKit && swift test`; `swift run
  ListHarness`. A local package dependency in both `Package.swift` and
  `project.yml`, like PaneKit; the Catalog (`MainView`) is its first user.
- `PopoverKit/` (top level): our own popovers, **for any Mac app**, its
  own Swift package depending on nothing (`spec/popoverkit.md`). `cd
  PopoverKit && swift test`; `swift run PopoverHarness`. A local package
  dependency in both `Package.swift` and `project.yml`; Slide Info in the
  timeline (`StorylineView`) is its first user.
- `PaneKit/` (top level): our own pane system, **for any Mac app**, as
  its own Swift package, depending on nothing in RhythmIO
  (`spec/panekit.md`). `cd PaneKit && swift test` runs its tests;
  `swift run PaneHarness` runs its test app. **In active use by the app**
  since `spec/panekit.md` steps 2–3 (2026-09-24): a local package
  dependency in both `Package.swift` and `project.yml`. It's the main
  window's own split (library | detail | the timeline pane, full width
  under both), Edit Show's and Edit Slides' columns, and every pane's
  pop-out (the Slide Editor, the library panel, the Inspector, the
  Timeline window). **How a drawer feels** — the clutch, flick, swipe and
  their dials — is `PaneClutch.swift` (with `PaneSlide`, the timed slide,
  and `PaneSwipe`); the drag itself is `trackResize` in
  `PaneContainerView.swift`, which also watches the pointer for the
  resize cursor (`PaneResizeCursorView`, `PaneHandle.swift`).
- `Sources/RhythmIOApp/`: the SwiftUI/AppKit app. `PlaybackEngine` owns a
  show's clock, media and drawing, and any number of `ShowCanvas` views
  show it (the Edit Show preview and its pop-out share one engine). A paused
  engine stops drawing about 0.6s after the last change; call `touch()`
  after anything visible changes. **`ShowView` owns the show's engine**
  while the show is open, in either mode (Edit Slides' timeline and Slide
  viewer draw it too); `EditShowView` no longer makes or ends it. The
  engine's `selectionLoop` (from `ShowTimeline.loopSpans`) is Edit Slides'
  looping Play.
- Video export lives in Core (`MovieExport` settings and codecs,
  `MovieWriter` the one place that builds an `AVAssetWriter`,
  `MoviePictureTrack`, `MovieSoundTrack`/`MovieSoundRenderer`,
  `MovieMedia` the synchronous loader, `MovieVideoFrames`/`MovieVideoSound`
  for video slides) with `MovieExportPanel` in the app.
  `VideoSlideTiming` decides which moment of a file a video slide shows,
  for the player and the exporter both — a slide held longer than its
  video loops it, which is easy to lose when touching either.
  **Write one off the main thread**, and feed a writer whichever input
  will take data rather than waiting on the one that's behind — both
  orderings deadlock, and `spec/video-export.md` says how.
- App files worth knowing: `TransformOverlay` (the handles, arrow keys
  and Rotation mode on the preview), `StorylineView` (the timeline's rows,
  drawn in the show's own `rows` order, with their handles and drawers;
  the blocks and the lane's transitions row), `ImagesRow` (the lane's images row),
  `MusicRow` (songs and their waveforms; move, trim, overlaps),
  `EditShowTimelinePane` (the timeline pane: transport and storyline, live
  in both modes; `active: false` draws them dimmed and inert, for a
  timeline with no show), `SlideViewer` and `EditSlidesView`
  (`ShowView.swift`; the Slide viewer drawer over the slide list),
  `ClickTakesKeyboard` and `SingleKeys` (`EditShowView.swift`: a click
  that gives a SwiftUI List the keyboard, and window-wide single keys),
  `KeyboardArea` (`KeyboardArea.swift`: which pane was clicked last in
  each window, so the arrows go there; with `WindowNumberReader` and
  `Color.selection`, a selection's accent or grey),
  `LevelLine` (the level line on song and lane-image clips: volume or
  opacity, and the fades), `MusicPlayer` (plays the songs on
  AVAudioEngine and is the show's clock while it does; `PlaybackEngine.syncMusic`
  must follow anything that starts, stops or moves the clock), `Waveforms`
  (read once per file, cached in `<library>/Cache/Waveforms` by hash), `CollectionBrowser`
  (Edit Show's right column), `CollectionAdd` (the in-app drag type and the
  "add to collection?" question), `Libraries` (open/new/private),
  `Fingerprints` (Vision feature prints for Find Similar, cached in
  `<library>/Cache/Prints` by hash), `KeepOneSheet` (Keep One on a similar group), `FrameStrip`, `EffectsTimeline`, `EffectControls` (sliders, pads), `RhythmPanel`
  (the Rhythm tool: a floating panel, `RhythmTool.shared` holds its show,
  undo manager and ruler preview), `RhythmNotationView` (a pattern as notation:
  Bravura's glyph outlines in a `Canvas`, placed by `RhythmNotation.layout`), `RhythmGridView`
  (the drum-machine view, through `RhythmGrid`).
- `Resources/RhythmIO.icon`: the app icon, an Icon Composer document,
  Jason's, made for the rename to RhythmIO. Xcode compiles it into
  `Assets.car` and `RhythmIO.icns`; `project.yml` names it as the app's
  icon. `Resources/AppIcon.svg` is the drawing behind the app's first icon,
  before the rename.
- `Resources/Fonts/`: Bravura, the SMuFL music font (SIL OFL 1.1, licence
  alongside). `make-app.sh` copies it into the app and `ATSApplicationFontsPath`
  loads it, so it only exists in the built app, not under `swift run`.
- `Sources/mio/`: dev CLI. `ingest`, `show` (creates a show; it doesn't print one), `render` (writes frames
  through the Compositor to PNG, which is how transitions get checked by eye),
  `movie` (a real movie through the same path — video export,
  `spec/video-export.md`) and `mix` (just the show's music, rendered
  offline).
- `make-app.sh`: builds `build/RhythmIO.app` with Xcode, through the root
  `project.yml` (XcodeGen; `RhythmIO.xcodeproj` is generated and
  gitignored). One app holds everything: the tiles in `Contents/PlugIns`,
  RhythmBG in `Contents/Library/LoginItems`, Bravura in Resources. The
  libraries, `mio` and the tests stay SwiftPM — `swift test` is
  unchanged. View ▸ Desktop Show… launches the nested RhythmBG and
  registers it at login (`SMAppService.loginItem`); deleting RhythmIO
  takes all of it. `install.sh` copies the app to `~/Applications` and
  launches it once, which is the only way the Control Center tiles
  register — testing tiles means installing, not `build/RhythmIO.app`.
  Caches lie about tiles; the `rhythmio-testing` skill says how.
- `tools/`: `make-test-library.sh <dir>` builds a scratch library with
  generated media and a test show. There are also a window lister and a
  contact-sheet tool, for checking screenshots.
- **Signing:** every bundle is signed "Apple Development", team
  `P82S39V2KJ` (`project.yml`'s base settings; `spec/xcode-port.md`), so a
  permission granted to RhythmIO survives rebuilds.

