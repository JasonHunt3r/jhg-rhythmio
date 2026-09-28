# 2026-09-27 — the windows pass, continued: the transparency rework

From `spec/windows.md` ("Where these windows open", its "Goes in the same
pass" list, item 2), moved here word for word on 2026-09-28 when that
file was sliced. The settled rules are summarised in
`spec/window-behavior.md`, "The Transparency module"; this is how they
were found, bug by bug.

2. ~~Light mode's translucency and a window-background transparency
   setting~~ (item 34, Jason: light mode "is awful"). **Built, then
   reworked, 2026-09-27** — the first cut (three numbered Opacity Channels,
   four assignable regions, a secondary settings box) is kept only as
   dormant, reusable code (below); it's no longer what's wired into the app.

   **Now (2026-09-27, late): the Transparency module** on the Windows tab
   (Jason: "a light dark switch at the top and one slider for the
   currently targeted zones. A slider for the window header bar, and a
   switch for the handles"; titles his: "Panel Transparency, and Title Bar
   Transparency"). An Appearance switch picks Light or Dark — the Mac's own
   to start — and shows that appearance's own **Panel Transparency** (every
   bar content scrolls under), **Title Bar Transparency** (the main
   window's title bar and toolbar, `HeaderBarBackground`, on the OS's
   title-bar material showing the desktop behind — nothing of the window's
   own passes under it) and **Include handles**. The sliders read as
   transparency (100% see-through); the setting stores opacity, so saved
   values kept their look. The header defaults to solid, as it always was;
   the old single handles switch carried over to both appearances.

   **First cut, for the record:** three channels (`TranslucencySetting
   .swift`), each with Opacity, Tint and Blur, kept separately for Dark and
   Light, assignable to four regions (Catalog, Inspector, Panels, Header
   bar) from a secondary "Adjust Transparency…" box (the same `SettingsBox`
   case as Drawer Sensitivity's "Set Up Triggers…"). Confirmed live and
   wired correctly — Channel 1's Tint Amount at 100% turned Catalog and
   Header bar solidly black together. Then Jason reported Opacity doing
   nothing and asked whether PaneKit blocks translucency: two real causes,
   neither one PaneKit — he'd edited Light while macOS was in Dark, and
   separately, `.behindWindow` blending against a plain desktop makes even
   an active-appearance Opacity change nearly invisible (confirmed: 2%
   looked identical to 100%). Fixed with a live preview swatch per channel,
   a colorful gradient behind `.withinWindow` blending instead of
   `.behindWindow` so the effect reads regardless of system appearance or
   desktop content.

   **Reworked the same day, after Jason looked at how native apps actually
   use translucency**: "I've over scoped this feature as an app setting...
   real macOS translucency only shows up noticeably on toolbars or header
   bars that scrolled content passes under — everywhere else it's too
   subtle to matter." Confirmed by the testing above: Opacity on Catalog,
   Inspector and Panels was nearly invisible against a plain desktop — not
   a bug, just the wrong scope. Jason's instructions: kill the
   region-assignment sub-UI; keep one slider, now meaning "the OS's own
   native look" at one end sliding to "fully opaque" at the other, not
   0%-invisible to 100%-opaque; scope it to bars with scrolled content
   passing under them; don't delete the three-channel engine — reserve it
   as the basis for a future Slide Editor tool applying the same kind of
   effect to slide images; and keep the per-pane identification hooks
   (`WindowAccessor`, the region-finding pattern) since they're reusable
   for whatever a pane needs assigned to it next.

   **What changed:** Catalog, Inspector and Panels were reverted to their
   exact original rendering (`TranslucentBackground` removed from
   `MainView.swift`, `SlideInspector.swift`, `InfoPanel.swift`,
   `RhythmPanel.swift`). `TranslucencySettingsBox.swift` (the region-picker
   UI) was deleted. `TranslucencySetting.swift` and `TranslucentBackground
   .swift` (the channel engine and its `ChannelSwatch`/live-preview
   mechanism) are kept, explicitly marked unwired in their own doc comment,
   for the Slide Editor tool. `HeaderBarBackground.swift` is left installed
   but dormant — nothing sets its channel away from the neutral default, so
   it renders as if untouched; the hook (finding `NSTitlebarContainerView`
   from a standard window button) stays for later.

   **The new, simpler model** (`ScrollBarTranslucency.swift`): one Double
   per appearance, 0 (native `.headerView` material, untouched) to 1
   (fully opaque), no blur toggle, no tint, no region picker. Live on the
   Windows tab directly as two labeled sliders (Dark Mode, Light Mode)
   inside a "Filter Bar" section — no secondary window, since there's
   nothing left to assign. Each slider keeps its own live preview swatch
   (`ScrollBarPreview`), for the same reason the first cut needed one: a
   slider is unjudgeable against the wrong system appearance or a plain
   desktop.

   **First target: the Library grid's filter bar**, chosen over the header
   bar (Jason's initial pick) once a scratch test showed the header bar
   doesn't actually have content passing under it — nothing extends behind
   the title bar today (no `fullSizeContentView`), so it was only ever a
   tinted empty strip. Fixing that needs PaneKit's own layout math taught
   about a title-bar inset, itself a harness-tested task (CLAUDE.md: check
   AppKit layout in a standalone harness before changing it), not a quick
   `NSWindow` flag flip — tried and reverted (`window.styleMask.insert
   (.fullSizeContentView)` plus `.ignoresSafeArea`, zero visible effect
   either way, confirmed on a scratch copy). The filter bar needed no such
   surgery: `LibraryGridView`'s grid is a plain SwiftUI `ScrollView`, so its
   bar (`bar`, `sortStatusBar`) now sits in a `ZStack` on top of the grid
   instead of a `VStack` pushing it down, with the grid's own tile content
   padded by the bar's measured height so the first row rests just below it
   at rest and scrolls up underneath as you scroll. Correctly uses
   `.withinWindow` blending (not `.behindWindow`) — the whole point is
   sampling the grid's own scrolled tiles directly behind it in the same
   window, not the desktop, which is also why it doesn't share the first
   cut's "nearly invisible" problem.

   **Confirmed with a scratch library**: real tiles genuinely scroll up
   into view behind the bar, sampled live (a colorful tile's top edge
   visibly bleeds through the bar as it passes). **A known, unresolved
   glitch**: at Opacity 100% (should be fully solid), a thin sliver of the
   row above still shows through right at the seam between the bar and the
   grid, even though `sortStatusBar` has its own separate opaque
   background (`.background(Color(nsColor: .controlBackgroundColor))`,
   unrelated to this feature) that should rule out that exact strip. Not
   resolved this session — worth a fresh look with a screenshot at several
   scroll positions and opacity values before touching the code further,
   rather than more guessing.
   Also found mid-session: `HeaderBarBackground`'s old channel-based tint
   (Jason's own experiment, red at ~89%, from the first cut) was still
   live in his **installed, running app** during this rework, since the
   Inspector's own reverted code hadn't been reinstalled yet — explains a
   red Inspector panel he'd have seen; resolved once the new build
   installs, since Inspector no longer reads that channel at all.

   **The header bar's real scroll-under effect, built after all, the same
   day** — Jason: "what about adding the header opacity logic into PaneKit
   as a feature for an area to be true false about?" `spec/panekit.md`,
   "A pane under the title bar," has the mechanism: `Pane
   .scrollsUnderTitleBar`, confirmed first in the harness (a translucent
   strip genuinely shows a marked pane's own colour through it, its
   sibling untouched), then wired into the real app — `AppModel.mainPanes`'
   `detail` pane carries the flag, and the same `ScrollBarBackground` the
   filter bar uses now covers a `titleBarHeight`-tall spacer at the top of
   it too, so the title bar and the filter bar read as one continuous
   surface over the grid, sharing one slider (Jason: "same slider as the
   filter bar"). `HeaderBarBackground.swift` (the old one-off hack) is
   deleted, fully superseded. Confirmed with a scratch library: scrolling
   moves tiles up through the taller combined region, and the library pane
   (not marked) sits exactly where it always did. The filter bar's own
   100%-opacity seam glitch (above) hasn't been re-checked against this
   taller region specifically — same open item, not investigated twice.

   **The Catalog's own bars, the same day**: a test case (25 seeded
   collections, 50 groups, 51 shows, straight into a scratch library's
   SQLite) forced the sidebar to actually scroll, which Jason then watched
   — "the New+ button [needs] to be a bar with the transparency since
   things will be scrolling under it... the collections header... should
   also be scrolled under, maybe the box containing the Library button as
   well." All three now carry `ScrollBarBackground`: the "+ New" footer
   (already a `.safeAreaInset`, so content already scrolled under it
   unstyled — that's what made it hard to read), the "Collections" section
   header, and the "Library" row itself (`.listRowBackground`, the
   row-level equivalent of `.background` a plain `List` row needs, since
   this is a real `NSTableView`, not a `ScrollView`). Not yet checked
   against a real hand's scroll — only that nothing regressed structurally.

   **A separate, real finding from that same test case**: some
   `DisclosureGroup`s in the Catalog render collapsed on a fresh launch —
   no scrolling needed — despite `folded` (`MainView.swift`) defaulting to
   empty, which should read every collection as expanded. Confirmed twice,
   independently: once as a run of 7 consecutive collections after a
   scroll, once as 2 different ones on a plain fresh launch at rest, both
   times stable across a second screenshot and a further scroll (not a
   single-frame flicker) — pinned by reading the actual accessibility tree
   (no child rows between one collection heading and the next), not by
   eye. Which collections it hits varies between launches; a same-scroll
   retry on a third fresh launch showed none collapsed at all. Not
   diagnosed — the pattern (some subset, varies run to run, present with
   zero interaction) points at a `List`/`DisclosureGroup` rendering race
   with many rows rather than a logic bug in `foldBinding` itself, but
   that's a guess, not a finding. Worth a real look before touching
   `foldBinding` or the Collections `ForEach`.

   **Pinned to the top, and a real bug found doing it**: Jason, watching
   the seeded scroll test — "the library and collections header should
   stay pinned to the top and the list should scroll behind them." The
   Library row moved out of the `List` entirely into `libraryList`'s own
   `.safeAreaInset(edge: .top)`, alongside the "Collections" text, since a
   plain `List` row can't be pinned the way a `Section` header sometimes
   is — it's now a plain tappable view (`libraryRow`) with its own manual
   selection highlight, since `List`'s own selection styling doesn't reach
   outside its rows. Traded away: `List`'s free keyboard nav reaching
   Library by arrowing up past the first collection — nothing asked for
   that specifically, worth knowing if it's missed. Confirmed with a
   scratch library: both stay fixed while the collection list scrolls
   underneath.

   **Then**: "it does scroll behind, it just isn't transparent" — right,
   and a real finding: `.withinWindow` blending (the filter bar's own
   choice, correct for a plain `ScrollView`) renders **completely flat**
   over the Catalog's `List`, a real `NSTableView` — no vibrancy at all,
   confirmed side by side against `.behindWindow`, which showed faint but
   real texture in the exact same spot. `ScrollBarBackground` now takes a
   `blending` parameter (`.withinWindow` by default, for the filter bar and
   the title bar spacer that shares it; `.sidebar`, a `.behindWindow`
   convenience, for the three Catalog bars) — the right semantic split
   anyway: a sidebar's vibrancy has always meant "see-through to the
   desktop," not "scrolled content passing under," which is what the grid
   actually does. The New+ footer already had content scrolling behind it
   unstyled before this — `.safeAreaInset` does that for free — it just
   read as a bug because nothing there was translucent yet.

   **Then Jason, having looked at it running**: "the scroll behind is
   right, but those bars... need the transparency, like we're seeing in
   the toolbar of the grid view" — right that `.behindWindow`'s own faint
   desktop-sampled vibrancy doesn't read as obviously transparent the way
   the grid's `.withinWindow` one does, sampling real, colorful scrolled
   photos instead. Tested the actual cause rather than guess again:
   restructured the Catalog's bars from `.safeAreaInset` to
   `.overlay(alignment:)` plus `.contentMargins` — true siblings of the
   `List` in the view tree, exactly how the grid's own working bar sits
   next to its `ScrollView` — and switched back to `.withinWindow`.
   **Still completely flat**, and the restructuring introduced its own bug
   (the first collection landed hidden behind the bar, a `.contentMargins`
   timing issue never chased down since the real question was blending,
   not layout). Reverted to the working `.safeAreaInset` plus
   `.behindWindow` version — nothing lost.

   **Conclusion, not yet contradicted by any test run**: `.withinWindow`
   blending doesn't render live content over a `List`'s own `NSTableView`
   backing at all, independent of where the effect view sits in the
   SwiftUI view tree — tried nested (`.safeAreaInset`) and sibling
   (`.overlay`), identical flat result both times. This reads as a real
   platform limitation, not a mistake in either structure.

   **Jason: "why can't we just add the transparency characteristic to any
   bar that is in a scroll behind position?"** Explained the real
   distinction (a genuine `NSToolbar`'s privileged window-chrome
   compositing, which Notes' own look actually depends on, versus an
   ordinary content-level effect view, which is all `ScrollBarBackground`
   ever was and all `.withinWindow` can drive) and the two paths: adopt a
   real `NSToolbar` (declined — see above), or replace the Catalog's
   `List` with hand-built scrolling content, matching how the grid already
   solves the identical problem. **Chosen and built the same day**, once
   Jason asked for it to be a genuinely reusable PaneKit piece, not a
   ShowTools-only patch: `PaneKit.PaneListNavigation`
   (`spec/panekit.md`, "Arrow-key navigation for a hand-rolled list") gives
   a plain `ScrollView` the one thing `List(selection:)` provided that
   nothing else does — arrow keys step the selection, and the new
   selection scrolls into view. Proven first in the harness (25 and 35
   consecutive Down presses landed exactly on Row 25 and Row 35), then the
   Catalog itself was rebuilt on it: `libraryList` is a `ScrollView` now,
   every row carries its own `sidebarRowChrome` (manual selection highlight
   and tap-to-select, replacing `List`'s `.tag`/selection binding and
   `.badge()`), and `visibleSidebarOrder` computes the flat, fold-aware
   row order the arrow keys step through. Everything else — the recursive
   `DisclosureGroup`s, context menus, rename-on-option-click, drag and
   drop — is unchanged code, since none of it was ever `List`-specific.
   `.onDeleteCommand` is gone (redundant): the window-wide `SingleKeys`
   fallback (`layout`) already covered every Delete/⌘Delete case
   unconditionally once `NSApp.keyWindow?.firstResponder is NSTableView`
   can never be true for this pane again.

   **Confirmed on a scratch copy, the seeded 25-collection library**: real
   photos… no, real *rows* now genuinely scroll behind a visibly
   translucent Library/Collections bar and New+ footer; arrow keys from a
   fresh launch land on Library first, then step through collections,
   groups and shows exactly in the order they're drawn, auto-scrolling
   correctly; clicking a row selects it and updates the detail pane;
   Delete on a selected group raised the real confirmation dialog (in its
   own window — easy to miss checking for, worth remembering next time
   nothing seems to have happened). **One real, unresolved side effect**:
   `LibraryGridView`'s own keyboard shortcuts (⌘A and others) are guarded
   by `!(NSApp.keyWindow?.firstResponder is NSTableView)`, meaning "only
   fire while the sidebar doesn't have focus" — a `List` made that a real,
   checkable AppKit state; a plain `ScrollView` sidebar has no equivalent,
   so that guard now reads as permanently true. Whether grid shortcuts
   firing while clicking around the Catalog is actually noticeable hasn't
   been checked by hand. **Confirmed live in a later session**: pressing
   an arrow key sometimes moved the *grid's* own selection instead of the
   sidebar's — the two arrow-key monitors (`PaneArrowKeys` and the grid's
   own) both watch the same keys unconditionally, and whichever installed
   first on a given launch wins; not just theoretical, reproduced.

   **A real bug in the fix itself, found right after installing**: Jason —
   "no transparency from the library headers with scrollbehind content."
   The two Catalog bars were still calling the now-deleted
   `ScrollBarBackground.sidebar` convenience (`.behindWindow`) — left over
   from before the migration and never updated to the plain
   `ScrollBarBackground()` default (`.withinWindow`) the whole migration
   was for. Fixed; `.sidebar` itself removed from `ScrollBarTranslucency
   .swift` since nothing needs it any more. Not yet re-confirmed visually
   after the fix — synthetic clicks and arrow keys landed inconsistently
   in the sidebar this same session (sometimes hitting the grid instead,
   the same monitor race above), so this one is reasoned from the code
   (identical mechanism to the grid's own already-proven filter bar and
   the PaneKit harness demo) rather than screenshotted again. Worth Jason's
   own look before calling it done.

   **A second real regression, found the same day from a screenshot**:
   Jason annotated a screenshot of Edit Show with four boxes — red
   (alignment off across the Browser row), yellow (an empty bar that
   "just shouldn't exist"), green (extra space that shouldn't be there),
   blue (the collection picker + item count + Search + "In this show"
   label, which "should all be affected the same by the scroll behind") —
   and asked to leave the thin grip/divider strip solid for now. Root
   cause, confirmed with Jason before fixing ("Yes, that's it"): `detail`
   carries `scrollsUnderTitleBar: true` unconditionally, right for the
   plain Library grid (whose own translucent strip stands in for a title
   bar), but wrong the instant a show is open — `ShowView` has a genuine
   native `.toolbar`/`.navigationTitle` (the Edit Slides/Edit Show
   picker, Play buttons) claiming real window-chrome space of its own, so
   stretching `detail` up into that same strip doubled up: the toolbar's
   own reserved height plus the pane's extra height, producing exactly
   the gap and misalignment in the screenshot.

   **Fixed by making `scrollsUnderTitleBar` runtime-toggleable in
   PaneKit**, not just a static per-pane flag on the tree — the same
   pattern as `contentExtent`/`setContentExtent`
   (`PaneController.swift`): a new `scrollsUnderTitleBarOverride:
   [String: Bool]` dictionary, `nil` for a pane meaning "use the tree's
   own static value," and `setScrollsUnderTitleBar(_:for:)` to set or
   clear it, each one a `container?.needsLayout = true`, never saved.
   `PaneLayout.layout(...)` takes the override as a parameter now and
   consults it (`scrollsUnderTitleBarOverride[pane.id] ?? pane
   .scrollsUnderTitleBar`) in its post-process loop instead of reading
   the tree directly; `PaneContainerView.layout()` passes `controller
   .scrollsUnderTitleBarOverride` through. Two new PaneKit unit tests
   cover both directions (a statically-true pane suppressed, a
   statically-false one extended). `ShowView` calls `model.mainPanes
   .setScrollsUnderTitleBar(false, for: "detail")` in `.onAppear` and
   clears it (`nil`) in `.onDisappear`, so the override applies for
   exactly as long as a show is open in either mode and the plain grid
   gets its title-bar extension back the moment the show closes.

   **Confirmed on a scratch copy**: Edit Show now has no empty gap and no
   misaligned Browser row — the toolbar, the Browser's collection picker/
   Search/"In this show" row and the storyline below all read as one
   flush layout. The plain Library grid's own scroll-behind title bar
   (unaffected by the override, since it's cleared outside a show) still
   works exactly as before. The blue-box translucency treatment itself
   (giving that Browser cluster the same scroll-behind material the
   filter bar and Catalog bars use) and the grip-strip exclusion are
   **not done** — this fix only settles the alignment regression, per
   Jason's "leave the handle bar solid for now." **Done later the same day**: the
   browser left `List` for ListKit and its whole bar stack, headers and
   handle went translucent (`spec/listkit.md`); the handle follows the
   Transparency module's Include handles.
