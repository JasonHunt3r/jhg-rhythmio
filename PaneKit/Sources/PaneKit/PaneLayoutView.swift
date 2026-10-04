import AppKit
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
            if let c = ownContext(id) { PaneWindowContext.register(h, c) }
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
        if let c = ownContext(id) { return AnyView(view.environment(\.paneWindow, c)) }
        return outer.map { AnyView(view.environment(\.paneWindow, $0)) } ?? view
    }

    private func ownContext(_ id: String) -> PaneWindowContext? {
        guard let pane = controller.root.pane(id), pane.popOut != .none else { return nil }
        return PaneWindowContext(controller: controller, paneID: id, title: pane.title)
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
    public var menuTitle: String {
        isPoppedOut ? "Put \(title) Back in Main Window" : "Show \(title) in Own Window"
    }

    /// The pane an AppKit view sits in, for a menu built in AppKit (a
    /// list's empty space): the nearest pane-hosting view above it that
    /// can pop out. Nested layouts are walked through.
    public static func of(_ view: NSView) -> PaneWindowContext? {
        var v: NSView? = view
        while let current = v {
            if let box = hosts.object(forKey: current) { return box.context }
            v = current.superview
        }
        return nil
    }

    /// The same item as `PaneWindowMenuItem`, for an `NSMenu`.
    public func menuItem() -> NSMenuItem {
        let target = MenuTarget(self)
        let item = NSMenuItem(title: menuTitle, action: #selector(MenuTarget.run), keyEquivalent: "")
        item.target = target
        item.representedObject = target   // the item keeps its target alive
        return item
    }

    @MainActor private final class Box { let context: PaneWindowContext; init(_ c: PaneWindowContext) { context = c } }
    private static let hosts = NSMapTable<NSView, Box>.weakToStrongObjects()
    static func register(_ view: NSView, _ context: PaneWindowContext) { hosts.setObject(Box(context), forKey: view) }

    @MainActor private final class MenuTarget: NSObject {
        let context: PaneWindowContext
        init(_ c: PaneWindowContext) { context = c }
        @objc func run() { context.toggle() }
    }
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
            Button(pane.menuTitle) { pane.toggle() }
        }
    }
}
