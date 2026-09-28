import SwiftUI
import ListKit

/// ListKit's test app: a translucent sidebar over a plain `ScrollView`, not
/// a `List` — proving `ListNavigation` gives back what a `List` would while
/// the bar above genuinely composites `.withinWindow` vibrancy over the
/// scrolled rows, which a real `List`'s `NSTableView` never does
/// (ShowTools' Catalog, 2026-09-27). Moved here from PaneKit's harness when
/// ListKit became its own package.
@main
struct ListHarnessApp: App {
    var body: some Scene {
        WindowGroup("ListKit Harness") {
            SidebarListDemo().frame(minWidth: 260, minHeight: 400)
        }
    }
}

private struct SidebarListDemo: View {
    let rows = (1...40).map { "Row \($0)" }
    @State private var selection: String?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        OutlineIndent()
                        Text(row)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .listRow(selected: selection == row, label: row) { selection = row }
                    .onTapGesture { selection = row }
                    .id(row)
                }
            }
            .padding(.horizontal, 8)
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Text("Pinned Header").font(.headline)
                Spacer()
            }
            .padding(10)
            .background(HarnessVibrantBar())
        }
        .listNavigation(selection: $selection, order: rows, title: { $0 }, accessibilityLabel: "Demo list")
    }
}

private struct HarnessVibrantBar: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .headerView
        v.blendingMode = .withinWindow
        v.state = .active
        return v
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}
