# Rename inventory: ShowTools → RhythmIO, BGTools → RhythmBG

Phase 1 of `ShowTools → RhythmIO (miO) Rename Plan.md` (B-85), taken 2026-10-02 on
branch `rename/rhythmio` before anything was renamed. Every tracked file
outside `spec/history/` with a case-insensitive hit for `showtools`,
`bgtools`, `bgcontrols` or the word `stcli`, so nothing is missed silently.
(`stcli` is matched as a whole word: `SetlistClip` contains it.)

**Deliberately kept:** the Control Center tiles' `kind` strings,
`com.jhg.bgtools.open` and `com.jhg.bgtools.desktopShow` (the plan:
keep them, so the tiles' state carries over), and the stale Background
Task Management ids `com.jhg.bgtools` named in `status.md` (real ids on
Jason's Mac).

## Files and hit counts

| File | Hits |
|---|---|
| `spec/bgtools.md` | 80 |
| `spec/xcode-port.md` | 61 |
| `project.yml` | 46 |
| `spec/panekit.md` | 35 |
| `Sources/ShowToolsApp/ShowToolsApp.swift` | 35 |
| `spec/window-behavior.md` | 24 |
| `Sources/ShowToolsApp/BGToolsHelper.swift` | 24 |
| `.claude/skills/showtools-testing/SKILL.md` | 23 |
| `spec/layout.md` | 21 |
| `BGTools/Controls/Controls.swift` | 21 |
| `spec/simple-things-fast.md` | 19 |
| `CLAUDE.md` | 19 |
| `spec/status.md` | 18 |
| `install.sh` | 18 |
| `BGTools/App/BGToolsApp.swift` | 18 |
| `Sources/ShowToolsCore/Library.swift` | 17 |
| `tools/axtool.swift` | 15 |
| `spec/plan.md` | 14 |
| `spec/backlog.md` | 14 |
| `Package.swift` | 14 |
| `BGTools/App/Panel.swift` | 14 |
| `Sources/ShowToolsApp/EditShowView.swift` | 12 |
| `PaneKit/Tests/PaneKitTests/PaneLayoutTests.swift` | 12 |
| `tools/add-demo-show.sh` | 11 |
| `spec/conventions.md` | 10 |
| `Sources/ShowToolsApp/MainView.swift` | 10 |
| `BGTools/App/MainWindow.swift` | 10 |
| `tools/make-demo-show.sh` | 9 |
| `Tests/ShowToolsCoreTests/LibraryTests.swift` | 9 |
| `BGTools/App/Desktop.swift` | 9 |
| `spec/video-export.md` | 8 |
| `Sources/ShowToolsApp/Libraries.swift` | 8 |
| `Sources/BGToolsCore/DesktopSettings.swift` | 8 |
| `PaneKit/Harness/Harness.swift` | 8 |
| `tools/control-probe/Controls/Controls.swift` | 7 |
| `spec/video-audio.md` | 7 |
| `spec/how-we-design.md` | 7 |
| `make-app.sh` | 7 |
| `Sources/stcli/main.swift` | 7 |
| `tools/make-test-library.sh` | 6 |
| `tools/control-probe/project.yml` | 6 |
| `Sources/ShowToolsApp/CollectionAdd.swift` | 6 |
| `Sources/ShowToolsApp/AppModel.swift` | 6 |
| `BGTools/App/Libraries.swift` | 6 |
| `tools/desktop-probe/main.swift` | 5 |
| `tools/control-probe/Shared/Intents.swift` | 5 |
| `spec/shakedown.md` | 5 |
| `spec/hig-audit.md` | 5 |
| `spec/edit-slides-inspector-port.md` | 5 |
| `spec/anatomy.md` | 5 |
| `Sources/ShowToolsApp/StorylineView.swift` | 5 |
| `Sources/ShowToolsApp/ShowView.swift` | 5 |
| `BGTools/App/LibraryReader.swift` | 5 |
| `spec/first-run-brief.md` | 4 |
| `Tests/BGToolsCoreTests/DesktopShowTests.swift` | 4 |
| `Sources/ShowToolsApp/SettingsWindowCoordinator.swift` | 4 |
| `Sources/ShowToolsApp/FillRangeSheet.swift` | 4 |
| `Sources/ShowToolsApp/EffectControls.swift` | 4 |
| `BGTools/App/LoginItem.swift` | 4 |
| `tools/library-probe/probe.swift` | 3 |
| `tools/library-probe/build.sh` | 3 |
| `spec/maps/maps.html` | 3 |
| `spec/groups.md` | 3 |
| `Tests/ShowToolsCoreTests/SetlistTests.swift` | 3 |
| `Tests/ShowToolsCoreTests/ReadOnlyLibraryTests.swift` | 3 |
| `Sources/ShowToolsPlayback/ShowSource.swift` | 3 |
| `Sources/ShowToolsPlayback/MediaProvider.swift` | 3 |
| `Sources/ShowToolsCore/Database.swift` | 3 |
| `Sources/ShowToolsApp/SlideInspector.swift` | 3 |
| `Sources/ShowToolsApp/SlideClipboard.swift` | 3 |
| `Sources/ShowToolsApp/Info.plist` | 3 |
| `Sources/ShowToolsApp/FloatingPanelActivation.swift` | 3 |
| `Sources/ShowToolsApp/EditShowTimelinePane.swift` | 3 |
| `Sources/ShowToolsApp/CollectionBrowser.swift` | 3 |
| `PaneKit/Sources/PaneKit/PaneContainerView.swift` | 3 |
| `ListKit/Sources/ListKit/ListNavigation.swift` | 3 |
| `BGTools/App/Player.swift` | 3 |
| `BGTools/App/Info.plist` | 3 |
| `tools/control-probe/App/BGControlProbeApp.swift` | 2 |
| `spec/timeline-pane.md` | 2 |
| `spec/setlist.md` | 2 |
| `spec/listkit.md` | 2 |
| `Tests/ShowToolsCoreTests/SetlistImportTests.swift` | 2 |
| `Tests/ShowToolsCoreTests/MusicTests.swift` | 2 |
| `Tests/ShowToolsCoreTests/MoviePictureTrackTests.swift` | 2 |
| `Tests/ShowToolsCoreTests/MediaMetadataTests.swift` | 2 |
| `Sources/ShowToolsPlayback/PlaybackEngine.swift` | 2 |
| `Sources/ShowToolsApp/Waveforms.swift` | 2 |
| `Sources/ShowToolsApp/TransformOverlay.swift` | 2 |
| `Sources/ShowToolsApp/Thumbnails.swift` | 2 |
| `Sources/ShowToolsApp/SlideEditorWindow.swift` | 2 |
| `Sources/ShowToolsApp/ShowSession.swift` | 2 |
| `Sources/ShowToolsApp/SettingsBox.swift` | 2 |
| `Sources/ShowToolsApp/Rhythms.swift` | 2 |
| `Sources/ShowToolsApp/RhythmPanel.swift` | 2 |
| `Sources/ShowToolsApp/RhythmNotationView.swift` | 2 |
| `Sources/ShowToolsApp/RhythmGridView.swift` | 2 |
| `Sources/ShowToolsApp/ReorderDrag.swift` | 2 |
| `Sources/ShowToolsApp/QuickSettingsMenu.swift` | 2 |
| `Sources/ShowToolsApp/PlayerWindow.swift` | 2 |
| `Sources/ShowToolsApp/PanAndZoomEditor.swift` | 2 |
| `Sources/ShowToolsApp/MusicRow.swift` | 2 |
| `Sources/ShowToolsApp/MovieExportPanel.swift` | 2 |
| `Sources/ShowToolsApp/KeepOneSheet.swift` | 2 |
| `Sources/ShowToolsApp/InfoPanel.swift` | 2 |
| `Sources/ShowToolsApp/ImportShowPanel.swift` | 2 |
| `Sources/ShowToolsApp/ImagesRow.swift` | 2 |
| `Sources/ShowToolsApp/FrameStrip.swift` | 2 |
| `Sources/ShowToolsApp/Fingerprints.swift` | 2 |
| `Sources/ShowToolsApp/ExportPanel.swift` | 2 |
| `Sources/ShowToolsApp/ExceptionProbe.swift` | 2 |
| `Sources/ShowToolsApp/EffectsTimeline.swift` | 2 |
| `Sources/ShowToolsApp/BeatSheet.swift` | 2 |
| `Sources/ShowToolsApp/BatchRenameSheet.swift` | 2 |
| `PaneKit/Sources/PaneKit/PaneController.swift` | 2 |
| `BGTools/App/Thumbnails.swift` | 2 |
| `BGTools/App/Log.swift` | 2 |
| `.claude/skills/showtools-gotchas/SKILL.md` | 2 |
| `tools/nest-probe/Helper/HelperApp.swift` | 1 |
| `tools/list-windows.swift` | 1 |
| `tools/control-probe/Controls/Info.plist` | 1 |
| `spec/windows.md` | 1 |
| `spec/viewer-drawer.md` | 1 |
| `spec/rhythm.md` | 1 |
| `Tests/ShowToolsCoreTests/ViewerTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/VideoSlideTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/TimelineTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/SimilarTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/RhythmTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/ReorderTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/RatingTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/RangeFillTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/MovieWriterTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/MovieVideoSoundTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/MovieSoundTrackTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/MovieExportTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/LevelsTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/GridSelectionTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/EffectsTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/BeatsTests.swift` | 1 |
| `Tests/ShowToolsCoreTests/BatchRenameTests.swift` | 1 |
| `Sources/ShowToolsPlayback/MusicPlayer.swift` | 1 |
| `Sources/ShowToolsCore/Setlist.swift` | 1 |
| `Sources/ShowToolsCore/MovieSoundTrack.swift` | 1 |
| `Sources/ShowToolsCore/MoviePictureTrack.swift` | 1 |
| `Sources/ShowToolsCore/Models.swift` | 1 |
| `Sources/ShowToolsApp/SelectionViewer.swift` | 1 |
| `Sources/ShowToolsApp/SectionClipboard.swift` | 1 |
| `Sources/ShowToolsApp/ReplaceImagePicker.swift` | 1 |
| `Sources/ShowToolsApp/NoMenuYet.swift` | 1 |
| `Sources/ShowToolsApp/MultiItemPicker.swift` | 1 |
| `Sources/ShowToolsApp/DefaultLayout.swift` | 1 |
| `Sources/ShowToolsApp/CurveLine.swift` | 1 |
| `Sources/BGToolsCore/DesktopShow.swift` | 1 |
| `PaneKit/Tests/PaneKitTests/PaneHandleTests.swift` | 1 |
| `PaneKit/Tests/PaneKitTests/PaneControllerTests.swift` | 1 |
| `PaneKit/Sources/PaneKit/PaneWindows.swift` | 1 |
| `PaneKit/Sources/PaneKit/PaneModel.swift` | 1 |
| `PaneKit/Package.swift` | 1 |
| `ListKit/Sources/ListKit/Outline.swift` | 1 |
| `ListKit/Package.swift` | 1 |
| `ListKit/Harness/Harness.swift` | 1 |
| `BGTools/Controls/Info.plist` | 1 |
| `BGTools/Controls/BGToolsControls.entitlements` | 1 |

## Paths with an old name

- `.claude/skills/showtools-gotchas/SKILL.md`
- `.claude/skills/showtools-testing/SKILL.md`
- `BGTools/App/BGToolsApp.swift`
- `BGTools/App/Desktop.swift`
- `BGTools/App/Info.plist`
- `BGTools/App/Libraries.swift`
- `BGTools/App/LibraryReader.swift`
- `BGTools/App/Log.swift`
- `BGTools/App/LoginItem.swift`
- `BGTools/App/MainWindow.swift`
- `BGTools/App/Panel.swift`
- `BGTools/App/Player.swift`
- `BGTools/App/Spaces.swift`
- `BGTools/App/Thumbnails.swift`
- `BGTools/Controls/BGToolsControls.entitlements`
- `BGTools/Controls/Controls.swift`
- `BGTools/Controls/Info.plist`
- `Sources/BGToolsCore/DesktopSettings.swift`
- `Sources/BGToolsCore/DesktopShow.swift`
- `Sources/ShowToolsApp/AppModel.swift`
- `Sources/ShowToolsApp/BGToolsHelper.swift`
- `Sources/ShowToolsApp/BatchRenameSheet.swift`
- `Sources/ShowToolsApp/BeatSheet.swift`
- `Sources/ShowToolsApp/CollectionAdd.swift`
- `Sources/ShowToolsApp/CollectionBrowser.swift`
- `Sources/ShowToolsApp/CurveLine.swift`
- `Sources/ShowToolsApp/DefaultLayout.swift`
- `Sources/ShowToolsApp/DrawerSensitivitySetting.swift`
- `Sources/ShowToolsApp/EditShowTimelinePane.swift`
- `Sources/ShowToolsApp/EditShowView.swift`
- `Sources/ShowToolsApp/EffectControls.swift`
- `Sources/ShowToolsApp/EffectsTimeline.swift`
- `Sources/ShowToolsApp/ExceptionProbe.swift`
- `Sources/ShowToolsApp/ExportPanel.swift`
- `Sources/ShowToolsApp/FillRangeSheet.swift`
- `Sources/ShowToolsApp/Fingerprints.swift`
- `Sources/ShowToolsApp/FloatingPanelActivation.swift`
- `Sources/ShowToolsApp/FrameStrip.swift`
- `Sources/ShowToolsApp/ImagesRow.swift`
- `Sources/ShowToolsApp/ImportShowPanel.swift`
- `Sources/ShowToolsApp/Info.plist`
- `Sources/ShowToolsApp/InfoPanel.swift`
- `Sources/ShowToolsApp/KeepOneSheet.swift`
- `Sources/ShowToolsApp/KeyboardArea.swift`
- `Sources/ShowToolsApp/KeyboardShortcutsView.swift`
- `Sources/ShowToolsApp/LayoutLoopProbe.swift`
- `Sources/ShowToolsApp/LevelLine.swift`
- `Sources/ShowToolsApp/Libraries.swift`
- `Sources/ShowToolsApp/MainView.swift`
- `Sources/ShowToolsApp/MovieExportPanel.swift`
- `Sources/ShowToolsApp/MultiItemPicker.swift`
- `Sources/ShowToolsApp/MusicRow.swift`
- `Sources/ShowToolsApp/NoMenuYet.swift`
- `Sources/ShowToolsApp/PanAndZoomEditor.swift`
- `Sources/ShowToolsApp/PlayerWindow.swift`
- `Sources/ShowToolsApp/QuickLookController.swift`
- `Sources/ShowToolsApp/QuickSettingsMenu.swift`
- `Sources/ShowToolsApp/ReorderDrag.swift`
- `Sources/ShowToolsApp/ReplaceImagePicker.swift`
- `Sources/ShowToolsApp/RhythmGridView.swift`
- `Sources/ShowToolsApp/RhythmNotationView.swift`
- `Sources/ShowToolsApp/RhythmPanel.swift`
- `Sources/ShowToolsApp/Rhythms.swift`
- `Sources/ShowToolsApp/ScrollBarTranslucency.swift`
- `Sources/ShowToolsApp/SectionClipboard.swift`
- `Sources/ShowToolsApp/SelectionViewer.swift`
- `Sources/ShowToolsApp/SettingsBox.swift`
- `Sources/ShowToolsApp/SettingsWindowCoordinator.swift`
- `Sources/ShowToolsApp/ShowColumns.swift`
- `Sources/ShowToolsApp/ShowSession.swift`
- `Sources/ShowToolsApp/ShowToolsApp.swift`
- `Sources/ShowToolsApp/ShowView.swift`
- `Sources/ShowToolsApp/SlideClipboard.swift`
- `Sources/ShowToolsApp/SlideEditorWindow.swift`
- `Sources/ShowToolsApp/SlideInspector.swift`
- `Sources/ShowToolsApp/StorylineView.swift`
- `Sources/ShowToolsApp/Thumbnails.swift`
- `Sources/ShowToolsApp/TransformOverlay.swift`
- `Sources/ShowToolsApp/TranslucencySetting.swift`
- `Sources/ShowToolsApp/TranslucentBackground.swift`
- `Sources/ShowToolsApp/TriggeringScreen.swift`
- `Sources/ShowToolsApp/Waveforms.swift`
- `Sources/ShowToolsCore/BatchRename.swift`
- `Sources/ShowToolsCore/Beats.swift`
- `Sources/ShowToolsCore/Compositor.swift`
- `Sources/ShowToolsCore/Database.swift`
- `Sources/ShowToolsCore/Effects.swift`
- `Sources/ShowToolsCore/GridSelection.swift`
- `Sources/ShowToolsCore/Ingest.swift`
- `Sources/ShowToolsCore/Levels.swift`
- `Sources/ShowToolsCore/Library.swift`
- `Sources/ShowToolsCore/MediaMetadata.swift`
- `Sources/ShowToolsCore/MetadataStrip.swift`
- `Sources/ShowToolsCore/Models.swift`
- `Sources/ShowToolsCore/MovieExport.swift`
- `Sources/ShowToolsCore/MovieMedia.swift`
- `Sources/ShowToolsCore/MoviePictureTrack.swift`
- `Sources/ShowToolsCore/MovieSoundTrack.swift`
- `Sources/ShowToolsCore/MovieVideoFrames.swift`
- `Sources/ShowToolsCore/MovieVideoSound.swift`
- `Sources/ShowToolsCore/MovieWriter.swift`
- `Sources/ShowToolsCore/Music.swift`
- `Sources/ShowToolsCore/RangeFill.swift`
- `Sources/ShowToolsCore/Rating.swift`
- `Sources/ShowToolsCore/Reorder.swift`
- `Sources/ShowToolsCore/Rhythm.swift`
- `Sources/ShowToolsCore/Setlist.swift`
- `Sources/ShowToolsCore/SetlistImport.swift`
- `Sources/ShowToolsCore/Similar.swift`
- `Sources/ShowToolsCore/Timeline.swift`
- `Sources/ShowToolsCore/VideoSlideTiming.swift`
- `Sources/ShowToolsCore/Viewer.swift`
- `Sources/ShowToolsPlayback/MediaProvider.swift`
- `Sources/ShowToolsPlayback/MusicPlayer.swift`
- `Sources/ShowToolsPlayback/PlaybackEngine.swift`
- `Sources/ShowToolsPlayback/ShowSource.swift`
- `Sources/stcli/main.swift`
- `Tests/BGToolsCoreTests/DesktopShowTests.swift`
- `Tests/ShowToolsCoreTests/BatchRenameTests.swift`
- `Tests/ShowToolsCoreTests/BeatsTests.swift`
- `Tests/ShowToolsCoreTests/EffectsTests.swift`
- `Tests/ShowToolsCoreTests/GridSelectionTests.swift`
- `Tests/ShowToolsCoreTests/LevelsTests.swift`
- `Tests/ShowToolsCoreTests/LibraryTests.swift`
- `Tests/ShowToolsCoreTests/MediaMetadataTests.swift`
- `Tests/ShowToolsCoreTests/MovieExportTests.swift`
- `Tests/ShowToolsCoreTests/MoviePictureTrackTests.swift`
- `Tests/ShowToolsCoreTests/MovieSoundTrackTests.swift`
- `Tests/ShowToolsCoreTests/MovieVideoSoundTests.swift`
- `Tests/ShowToolsCoreTests/MovieWriterTests.swift`
- `Tests/ShowToolsCoreTests/MusicTests.swift`
- `Tests/ShowToolsCoreTests/RangeFillTests.swift`
- `Tests/ShowToolsCoreTests/RatingTests.swift`
- `Tests/ShowToolsCoreTests/ReadOnlyLibraryTests.swift`
- `Tests/ShowToolsCoreTests/ReorderTests.swift`
- `Tests/ShowToolsCoreTests/RhythmTests.swift`
- `Tests/ShowToolsCoreTests/SetlistImportTests.swift`
- `Tests/ShowToolsCoreTests/SetlistTests.swift`
- `Tests/ShowToolsCoreTests/SimilarTests.swift`
- `Tests/ShowToolsCoreTests/TimelineTests.swift`
- `Tests/ShowToolsCoreTests/VideoSlideTests.swift`
- `Tests/ShowToolsCoreTests/ViewerTests.swift`
- `spec/bgtools.md`
- `tools/control-probe/Controls/BGControls.entitlements`

## Distinct forms

```
 243 ShowTools
 236 BGTools
 105 ShowToolsCore
  51 ShowToolsPlayback
  35 stcli
  26 spec/bgtools.md
  26 bgtools
  24 SHOWTOOLS_LIBRARY
  20 build/ShowTools.app
  18 com.jhg.showtools
  15 BGToolsCore
  12 showtools-testing
  12 com.jhg.showtools.bgtools
  11 ShowToolsCore.Transition
  10 showtools-gotchas
  10 bgtools.md
  10 BGTOOLS_SETTINGS
   9 ~/Pictures/ShowTools
   9 ShowToolsApp
   9 .build/debug/stcli
   8 Support/BGTools
   8 Sources/ShowToolsApp
   7 ShowToolsApp.swift
   7 SHOWTOOLS_DEV_IMAGE
   6 com.jhg.showtools.bgcontrols
   6 ShowTools.app
   6 ShowTools.
   6 SHOWTOOLS_DEV_SHOW
   5 requireInsideShowTools
   5 Self.showTools
   5 SHOWTOOLS_
   5 Contents/Library/LoginItems/BGTools.app
   5 BGTools.
   4 com.jhg.showtools.items
   4 Sources/BGToolsCore
   4 ShowTools.xcodeproj
   4 Self.showTools.split
   4 SHOWTOOLS_DEV_TRANSITION
   4 SHOWTOOLS_DEV_PLAY
   4 SHOWTOOLS_DEV_OVERLAY
   4 OpenBGToolsIntent
   4 OpenBGToolsControl
   4 BGToolsControls
   4 BGToolsApp
   4 BGTOOLS_OPEN_WINDOW
   4 .showTools
   3 ~/Applications/ShowTools.app
   3 ~/Applications/BGTools.app
   3 launchBGToolsWithShowTools
   3 Sources/ShowToolsCore
   3 ShowTools-specific
   3 BGTOOLS_OPEN_PANEL
   3 BGControls
   2 ~/ShowTools
   2 ~/Library/Logs/BGTools.log
   2 showtools-tests-
   2 showTools
   2 requireShowToolsInFront
   2 launchWithShowToolsKey
   2 com.jhg.bgtools.desktopShow
   2 com.jhg.bgtools
   2 ShowTools-exception.log
   2 HOME/ShowTools
   2 Contents/PlugIns/BGToolsControls.appex
   2 BGToolsURL.open
   2 BGToolsSettingsTab
   2 BGTools.app
   1 ~/Projects/ShowTools
   1 ~/Library/Logs/ShowTools-exception.log
   1 ~/Library/Logs/DiagnosticReports/ShowTools-2026-09-24-034845.ips
   1 ~/Library/Logs/BGTools.log.
   1 ~/Library/Containers/com.jhg.BGControlProbe.BGControls
   1 testShowToolsShape
   1 spec/bgtools.md.
   1 showtools-setlist-
   1 showtools-ro-
   1 showtools-music-
   1 showtools-metadata-
   1 launchAtShowToolsStartupIfEnabled
   1 github.com/JasonHunt3r/jhg-showtools
   1 com.jhg.showtools.slidesettings
   1 com.jhg.showtools.slides
   1 com.jhg.showtools.section.
   1 com.jhg.showtools.group
   1 com.jhg.bgtools.open
   1 com.jhg.BGControlProbe.BGControls
   1 build/ShowTools.app/Contents/Library/LoginItems/BGTools.app
   1 build/ShowTools.app.
   1 bgtools.controls
   1 Sources/stcli
   1 Sources/ShowToolsPlayback
   1 ShowToolsCoreTests
   1 ShowToolsCore.mix
   1 ShowToolsCore.Reorder
   1 ShowToolsApp.body
   1 ShowTools.app/Contents/PlugIns/BGToolsControls.appex
   1 ShowTools.app/Contents/Library/LoginItems/BGTools.app
   1 ShowTools-specific.
   1 ShowTools-only
   1 SHOWTOOLS_LIBARY
   1 Library/Logs/ShowTools-exception.log
   1 Library/Logs/BGTools.log
   1 HOME/Pictures/ShowTools
   1 HOME/Applications/ShowTools.app
   1 Documents/com~apple~CloudDocs/ShowToolsTest
   1 Controls/BGControls.entitlements
   1 CONFIG/ShowTools.app
   1 BGToolsURL
   1 BGToolsMain
   1 BGToolsInstall.swift
   1 BGToolsInstall
   1 BGToolsHelper.swift
   1 BGToolsHelper.registerAtLogin
   1 BGToolsHelper.openDesktop
   1 BGToolsHelper.launchWithShowToolsKey
   1 BGToolsHelper.launchAtShowToolsStartupIfEnabled
   1 BGToolsHelper
   1 BGToolsError.notBundled
   1 BGToolsError
   1 BGToolsCoreTests
   1 BGToolsControls.appex
   1 BGToolsApp.main
   1 BGTools/Controls/BGToolsControls.entitlements
   1 BGTOOLS_LIBRARY
   1 /tmp/ShowToolsTest
   1 -/tmp/ShowToolsTest
```
