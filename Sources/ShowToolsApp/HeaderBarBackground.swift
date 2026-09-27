import SwiftUI
import AppKit

/// Tints the main window's own native title bar — the strip with the
/// traffic lights and the window title (Jason, 2026-09-27: "header bar
/// too," added to the transparency module's assignable surfaces alongside
/// the Catalog, Inspector and Panels). `TranslucencySetting.swift`'s
/// `.headerBar` region.
///
/// AppKit draws the title bar's own background and buttons in a dedicated
/// `NSTitlebarContainerView`, a sibling of the content view inside the
/// window's frame view — not part of the SwiftUI content at all, so this
/// can't be a plain `.background()` modifier the way the other three
/// surfaces are. Instead it inserts a hosted `TranslucentBackground`
/// directly **behind** that container (found from a standard window
/// button, not by subview index, so the traffic lights and title text
/// always stay on top of it) — installed once per window, and left alone
/// after that: the title bar's height never changes with the window, so
/// nothing here needs to track a resize.
@MainActor
enum HeaderBarBackground {
    private static var installed = Set<ObjectIdentifier>()

    static func install(on window: NSWindow) {
        let key = ObjectIdentifier(window)
        guard !installed.contains(key) else { return }

        guard let closeButton = window.standardWindowButton(.closeButton),
              let titlebarView = closeButton.superview,
              let titlebarContainer = titlebarView.superview,
              let frameView = titlebarContainer.superview else { return }

        installed.insert(key)
        window.titlebarAppearsTransparent = true

        let effect = NSHostingView(rootView: TranslucentBackground(region: .headerBar))
        effect.translatesAutoresizingMaskIntoConstraints = false
        frameView.addSubview(effect, positioned: .below, relativeTo: titlebarContainer)
        NSLayoutConstraint.activate([
            effect.leadingAnchor.constraint(equalTo: frameView.leadingAnchor),
            effect.trailingAnchor.constraint(equalTo: frameView.trailingAnchor),
            effect.topAnchor.constraint(equalTo: frameView.topAnchor),
            effect.heightAnchor.constraint(equalToConstant: titlebarContainer.frame.height),
        ])
    }
}
