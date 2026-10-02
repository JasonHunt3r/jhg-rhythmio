# ListKit

Pro-level lists for Mac apps that can't use SwiftUI's `List` — our own
package, `ListKit/` (top level), beside PaneKit and independent of it.
`cd ListKit && swift test` runs its tests; `swift run ListHarness` opens
its test app. Held to the standard of an App Store app, accessibility
included (Jason, 2026-09-27).

**Status: Built 2026-09-27**, in use by the sidebar (one at a time, an
outline) and Edit Show's browser (several at once): keyboard navigation
with focus, outline chevrons and indents, type-to-select, inline rename,
multiple selection, the rows' VoiceOver elements. Later, in the
accessibility pass: the real outline role (`spec/backlog.md`, B-57).

Why it exists: `.withinWindow` vibrancy never composites over a `List`'s
`NSTableView` (measured twice, 2026-09-27), so any list whose bars are
translucent over its rows has to be a plain `ScrollView` — and then
everything `List` gave for free has to be rebuilt. The pieces below were
built in PaneKit first, the same day, and moved here once it was clear
they never touched panes. (Their history below keeps its original
dates; the names are the current ones.)

## Arrow-key navigation (added 2026-09-27)

`ListNavigation` gives a plain `ScrollView` the one thing
`List(selection:)` provides for free that nothing else does: the arrow
keys step the selection, and the newly-selected row scrolls into view.
Built because `.withinWindow` vibrancy — the effect that makes the grid's
own filter bar look genuinely transparent — never composites over a real
`List`'s `NSTableView` backing at all
(`spec/history/2026-09-27-transparency-rework.md`: measured twice, nested and as a true sibling, identical flat
result both times). The fix for a translucent sidebar isn't a different
blending mode; it's not using `List` — but `List` was the only thing
giving RhythmIO's own Catalog its keyboard behaviour, so replacing it
meant rebuilding that one piece. Jason: "as long as we're making something
reusable for future apps using PaneKit. We're basically writing this into
PaneKit, right?" — yes.

Deliberately narrow. It doesn't render rows, know about hierarchy, or
handle Delete/Return/rename/drag — the app keeps building its own content
exactly as it would inside a `List` (recursive `DisclosureGroup`s and
all), and its own key handling for everything but the arrows. All it
needs is `order`: the current, flat, *visible* row order, folded branches
already excluded by the app (only it knows its own fold state), with each
row already carrying a matching `.id(_:)` for `ScrollViewProxy.scrollTo`
to find.

```swift
ScrollView { /* your own rows, each `.id(rowID)` */ }
    .listNavigation(selection: $selection, order: visibleOrder)
```

The AppKit key-catching glue mirrors `PaneContainerView`'s own existing
pointer-monitor pattern: only a `Bool` crosses the `MainActor
.assumeIsolated` boundary, not the `NSEvent` itself, which the newer SDK's
stricter Sendable checking on `NSEvent` doesn't allow (measured: returning
`NSEvent?` from inside `assumeIsolated` failed to build at all).

**Confirmed in the harness** ("A translucent, arrow-key-navigable
sidebar," a new `Shape`): 25 and 35 consecutive Down presses from a fresh
launch landed exactly on Row 25 and Row 35, auto-scrolling correctly both
times.

**Wired into RhythmIO the same day**: the Catalog's `libraryList` is a
`ScrollView` now, not a `List`. Every row (`collectionRow`, `groupRow`,
`showRow`, `libraryRow`) carries its own `sidebarRowChrome` — a shared
helper doing the selection highlight and tap-to-select that `List`'s
`.tag`/selection binding and `.badge()` gave for free — and
`visibleSidebarOrder` computes the fold-aware flat order. Everything else
(the recursive `DisclosureGroup`s, context menus, rename-on-option-click,
drag and drop) is unchanged: none of it was ever `List`-specific.
`.onDeleteCommand` is gone as redundant — the window-wide `SingleKeys`
fallback already covered every case once `firstResponder is NSTableView`
can never be true for this pane again. Confirmed on a scratch copy: rows
genuinely scroll behind a visibly translucent bar; arrow keys from launch
land on Library first, then step through collections/groups/shows in
drawn order; a click selects and updates the detail pane; Delete on a
selected group raised the real confirmation dialog. **One real,
unresolved side effect**: `LibraryGridView`'s own keyboard shortcuts are
guarded by that same `firstResponder is NSTableView` check, meaning
"suppress while the sidebar has focus" — a concept a plain `ScrollView`
sidebar has no equivalent for, so the guard now reads as permanently
true. Not checked by hand whether that's actually noticeable.
**Resolved the same evening** (next section): it was noticeable — a
clicked sidebar's ← → went to the grid — and `ListKeyboard` answers
the question now.

## The rest of `List`'s freebies (added 2026-09-27, evening)

Jason, from a screenshot of the Catalog: the chevrons were "jammed up
against the left" and a show wasn't "within its collection visually" —
"it seems that you need to write our replacement to have the same
functionality that the OS list has." Built as two PaneKit pieces, both
generic:

**`OutlineMetrics`** (`OutlineMetrics.swift`) — the chevrons and indents. Outside
a `List`, macOS's `DisclosureGroup` hangs its chevron in a margin left of
the row that nothing supplies (clipped at the pane's edge), and doesn't
indent its content at all. `.disclosureGroupStyle(.listOutline)` tracks
each row's depth; `OutlineIndent()`, first in every row's own `HStack`,
draws the indent plus the chevron (or an equal gutter on a row with no
children), *inside* the row, so the highlight spans the full width the
way `NSOutlineView` draws it. `indentPerLevel` 14, `disclosureWidth` 16.
⌥-click on a chevron opens or folds everything under it, through the
closure the app gives `.outlineSubtree { open in … }` on each
`DisclosureGroup`. **Trap:** the style isn't inherited into its own
content, so it re-applies itself there (a nested group got the system's
hanging chevron back without it).

**`ListNavigation`, rebuilt on SwiftUI focus** instead of a
window-wide key monitor, so it acts only while the list has the keyboard,
like a `List`: a click in it takes focus (`.focusable()` — a click on any
row does it; an extra list-wide `TapGesture` for the purpose swallowed
every chevron click, measured, so there isn't one). While focused:

- ↑ ↓ step (held, they now repeat), scrolled into view;
- → opens a folded row or steps into an open one's first child; ← folds
  an open row or steps from a child to its parent; ⌥→ ⌥← do the whole
  branch (`outline: ListOutline` — parent, isExpanded, setExpanded);
- typing selects by name (`title:`): a letter jumps to the first match
  from the top, the same letter again steps through the matches, letters
  within a second build one name (`TypeSelect`).

`.listRow(selected:)` on each row draws `List`'s states: the accent
highlight with white text while the list has the keyboard, grey
(`unemphasizedSelectedContentBackgroundColor`) while it doesn't, and the
accent ring around the row a right-click menu is open for (from AppKit's
`NSMenu` tracking notifications — `.contextMenu` reports nothing).
`ListKeyboard.hasKeyboard(in:)` is the replacement for asking
`firstResponder is NSTableView`: the app's own window-wide key handlers
ask it to stand aside.

13 new `ListNavigationTests` (74 PaneKit tests). Checked on a scratch
copy by axtool: every key above; a tile click hands the arrows back to the
grid and greys the sidebar's selection; ⌥-click folds without renaming.

**`InlineRename`** (added the same evening; Jason: "opt click on a
list item turns it into an editable field, all text selected … return on
a selected item often triggers same"). A row's name that becomes a text
field in place, all selected: Return or any click outside keeps it,
Escape restores it, empty or unchanged is no rename. `onReturn:` on
`.listNavigation` starts it from the keyboard; Return and Escape hand
the keyboard back to the list. The Catalog uses it for ⌥-click on a name,
Return, and the right-click Rename (which lost its "…" — no dialog now);
the rename alert is gone. Traps, measured: focusing the field in the
same pass it appears doesn't take while the list holds the keyboard (one
runloop turn later does); a click on something that doesn't take the
keyboard (the grid's empty space) never ends the edit through focus, so a
mouse-down monitor ends it; and the list's key handler sees every key
typed in the field, so it stands aside while an `NSText` is first
responder.

**Known limits.** The app's window-wide `SingleKeys` handlers run before
SwiftUI focus, so a key one of them takes never reaches type-to-select —
with a show open, J K L M I O N are the timeline's (as they beat the
`List` too); the rating and U / Y keys are the grid's. VoiceOver: since 2026-09-27 (evening) `.listRow` makes each row one
element — "Shorty, 5 slides, level 2", selected, with Press (select),
Expand/Collapse and the app's own (Rename) — and the list one named group
("Sidebar"). Checked by performing each action through the Accessibility
API. A row that opens is SwiftUI's own disclosure element, whose value is
its open state and can't be replaced, so its count and level ride in its
label instead. What's still missing is the outline *role* itself, which
SwiftUI gives only to `List`; parked for the accessibility pass
(`spec/backlog.md`, B-57).

## Several at once, and the browser (added 2026-09-27, late)

`ListNavigation`'s `Set` form picks as `NSTableView` does: a plain click
just that row; ⌘-click in or out; ⇧-click the range from the anchor (the
row last clicked); ⇧↑ / ⇧↓ grow or shrink that range from the lead; ⌘A
all; a double-click runs `primaryAction`; a click on the empty space
picks nothing. Rows use the id form, `.listRow(id:label:value:)`, which
takes the row's click itself and reads the modifiers and click count;
`ListSelectionContext` carries the pick and the click to it through the
environment. `ListKeyboard` now keeps a token per list, so two lists in
one window don't clear each other's claim. `focusOnAppear` is opt-in (the
sidebar takes the keyboard at launch; the browser doesn't). The click and
range rules are pure and pinned by 5 more tests (24).

Edit Show's browser (`CollectionBrowser`) is its first user: a
`ScrollView` with pinned section headers, the tools bar, handle and
dividers in a `.safeAreaInset` on the bars' translucent background, rows
scrolling up under them. A right-click on a picked row acts on the whole
pick; on an unpicked row, on that row alone, without changing the pick.
Dragging a picked row drags the pick.

Traps, measured: the keyboard modifier goes *inside* the `.safeAreaInset`,
so typing in the bar's search field never reaches the list's own keys
(E would append); a tap-catcher *behind* a `ScrollView` never sees clicks
on its empty space (the scroll view keeps them) — the tap goes on the
scroll view itself, where a row's own tap still wins.

Which area owns the arrows in Edit Show: the one clicked last
(`KeyboardArea`, built 2026-10-02). The timeline stands aside once a
list is clicked, so the browser and the sidebar get their own arrows.
