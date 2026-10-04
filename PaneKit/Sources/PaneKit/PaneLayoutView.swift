import SwiftUI

/// PaneKit for SwiftUI: a `PaneContainerView` with a SwiftUI view in each
/// pane.
///
///     PaneLayoutView(controller: panes, content: [
///         "library": AnyView(LibraryList()),
///         "detail": AnyView(Detail()),
///     ])
///
/// Each pane's hosting view has `sizingOptions = []`: PaneKit decides the
/// sizes, and SwiftUI doesn't negotiate them (the negotiation that looped in
/// `.inspector()`). The views don't inherit the SwiftUI environment across
/// the AppKit boundary, so pass in what they need (`.environment(model)`).
public struct PaneLayoutView: NSViewRepresentable {
    public let controller: PaneController
    public let content: [String: AnyView]

    public init(controller: PaneController, content: [String: AnyView]) {
        self.controller = controller
        self.content = content
    }

    public func makeNSView(context: Context) -> PaneContainerView {
        let views = content.map { id, view -> (String, NSView) in
            let h = NSHostingView(rootView: withWindowContext(id, view, outer: context.environment.paneWindow))
            h.sizingOptions = []
            return (id, h)
        }
        return PaneContainerView(controller: controller, content: Dictionary(uniqueKeysWithValues: views))
    }

    public func updateNSView(_ container: PaneContainerView, context: Context) {
        for (id, view) in content {
            if let hosting = container.content(of: id) as? NSHostingView<AnyView> {
                hosting.rootView = withWindowContext(id, view, outer: context.environment.paneWindow)
            }
        }
    }

    /// A pane that can pop out tells its content so (`\.paneWindow`), in the
    /// main window and out of it alike: the same hosting view moves. Other
    /// panes pass on the one they're inside (`outer`), which the hosting
    /// views would otherwise drop: the environment doesn't cross AppKit.
    private func withWindowContext(_ id: String, _ view: AnyView, outer: PaneWindowContext?) -> AnyView {
        if let pane = controller.root.pane(id), pane.popOut != .none {
            return AnyView(view.environment(\.paneWindow, PaneWindowContext(controller: controller, paneID: id,
                                                                             title: pane.title)))
        }
        return outer.map { AnyView(view.environment(\.paneWindow, $0)) } ?? view
    }
}

/// Which pane a view is in, for panes that can pop out (`PaneLayoutView`
/// sets it). `PaneWindowMenuItem` reads it.
@MainActor
public struct PaneWindowContext {
    public let controller: PaneController
    public let paneID: String
    public let title: String

    public var isPoppedOut: Bool { controller.isPoppedOut(paneID) }
    public func toggle() { controller.togglePopOut(paneID) }
}

public extension EnvironmentValues {
    @Entry var paneWindow: PaneWindowContext? = nil
}

/// The last item of every right-click menu in a pane that can pop out
/// (RhythmIO, Jason 2026-10-03): a divider, then "Show Timeline in Own
/// Window", or "Put Timeline Back in Main Window" once it's out. Nothing
/// outside such a pane.
public struct PaneWindowMenuItem: View {
    @Environment(\.paneWindow) private var pane

    public init() {}

    public var body: some View {
        if let pane {
            Divider()
            Button(pane.isPoppedOut ? "Put \(pane.title) Back in Main Window" : "Show \(pane.title) in Own Window") {
                pane.toggle()
            }
        }
    }
}
