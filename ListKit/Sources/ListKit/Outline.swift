import SwiftUI
import AppKit

/// The indent and disclosure chevron a `List` draws for a nested
/// `DisclosureGroup`, for a hand-rolled sidebar that isn't one
/// (`ListNavigation` has why). Outside a `List`, macOS's own
/// `DisclosureGroup` hangs its chevron in a margin *left* of the row,
/// which nothing supplies, and doesn't indent its content at all: the
/// chevrons were clipped at the pane's edge and a child row sat left of
/// its own parent's name (RhythmIO's Catalog, Jason's screenshot,
/// 2026-09-27).
///
/// Drawn the way `NSOutlineView` draws it: the row itself spans the full
/// width (so its selection highlight does too), and the indent and
/// chevron sit *inside* it, at its leading edge. So it takes two pieces:
///
/// - `.disclosureGroupStyle(.listOutline)` on the list, once. It tracks
///   how deep each row is, and hands a disclosure's label its open/closed
///   state instead of drawing a chevron itself.
/// - `OutlineIndent()` first in every row's own `HStack`, inside the
///   row's highlight. It draws the indent for the row's depth, then the
///   chevron on a disclosure's label or an empty gutter of the same width
///   on any other row, so every icon at one depth lines up.
public enum OutlineMetrics {
    /// How much further in each level sits than its parent.
    public static let indentPerLevel: CGFloat = 14
    /// The chevron's column: also the empty gutter a row with no children
    /// keeps, so its icon lines up with its siblings'.
    public static let disclosureWidth: CGFloat = 16
}

public struct OutlineDisclosureStyle: DisclosureGroupStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        OutlineBody(configuration: configuration)
    }

    /// A view of its own, so it can read the environment's depth.
    private struct OutlineBody: View {
        let configuration: Configuration
        @Environment(\.outlineLevel) private var level

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                configuration.label
                    .environment(\.outlineDisclosure, configuration.$isExpanded)
                if configuration.isExpanded {
                    configuration.content
                        .environment(\.outlineLevel, level + 1)
                        // A child row is never a disclosure's label itself
                        // unless its own `DisclosureGroup` says so.
                        .environment(\.outlineDisclosure, nil)
                        .environment(\.outlineSubtree, nil)
                        // Not inherited into a style's own content
                        // (measured: a nested group got the system's
                        // hanging chevron back), so it's set again.
                        .disclosureGroupStyle(OutlineDisclosureStyle())
                }
            }
        }
    }
}

public extension DisclosureGroupStyle where Self == OutlineDisclosureStyle {
    static var listOutline: OutlineDisclosureStyle { OutlineDisclosureStyle() }
}

/// The leading indent, and the chevron or the gutter in its place: see
/// `OutlineMetrics`. Takes its colour from the row it's in (`foregroundStyle`),
/// so it turns white on a selected row the same as the row's own text.
public struct OutlineIndent: View {
    @Environment(\.outlineLevel) private var level
    @Environment(\.outlineDisclosure) private var disclosure
    @Environment(\.outlineSubtree) private var subtree

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: CGFloat(level) * OutlineMetrics.indentPerLevel, height: 1)
            if let disclosure {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .rotationEffect(.degrees(disclosure.wrappedValue ? 90 : 0))
                    .frame(width: OutlineMetrics.disclosureWidth, alignment: .center)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // ⌥-click: this row and everything under it, as
                        // `List` does — when the app says what's under it.
                        let open = !disclosure.wrappedValue
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if NSEvent.modifierFlags.contains(.option), let subtree { subtree(open) }
                            else { disclosure.wrappedValue = open }
                        }
                    }
                    .accessibilityElement()
                    .accessibilityLabel(disclosure.wrappedValue ? "Collapse" : "Expand")
                    .accessibilityAddTraits(.isButton)
            } else {
                Color.clear.frame(width: OutlineMetrics.disclosureWidth, height: 1)
            }
        }
    }
}

extension EnvironmentValues {
    /// How many disclosures a row sits inside.
    @Entry var outlineLevel: Int = 0
    /// Set only on a disclosure's own label: its open/closed state.
    @Entry var outlineDisclosure: Binding<Bool>? = nil
    /// Set by `.outlineSubtree` on one disclosure: opens or folds it
    /// and everything under it.
    @Entry var outlineSubtree: ((Bool) -> Void)? = nil
}

public extension View {
    /// On a `DisclosureGroup` in a `.listOutline` list: what ⌥-clicking its
    /// chevron does — open or fold this row and everything under it. Only
    /// the app knows what's under it.
    func outlineSubtree(_ setExpanded: @escaping (Bool) -> Void) -> some View {
        environment(\.outlineSubtree, setExpanded)
    }
}
