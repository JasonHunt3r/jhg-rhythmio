import SwiftUI
import PopoverKit

/// Click a tile to pin its popover; with one pinned, hovering another
/// shows a second that clicks pass through. Esc closes.
@main
struct PopoverHarness: App {
    var body: some Scene {
        WindowGroup("PopoverKit") { Tiles().padding(40) }
    }
}

struct Tiles: View {
    @State private var pinned: Int?
    @State private var hovered: Int?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<6) { i in
                RoundedRectangle(cornerRadius: 6)
                    .fill(pinned == i ? Color.accentColor : Color.gray.opacity(0.4))
                    .frame(width: 90, height: 50)
                    .onTapGesture { pinned = i }
                    .onHover { hovered = $0 ? i : (hovered == i ? nil : hovered) }
                    .pinnedPopover(isPresented: pinned == i) { card(i, pinned: true) }
                    .pinnedPopover(isPresented: pinned != nil && hovered == i && pinned != i,
                                   passesClicksThrough: true, animates: false) { card(i, pinned: false) }
            }
        }
        .onKeyPress(.escape) { pinned = nil; return .handled }
    }

    private func card(_ i: Int, pinned: Bool) -> some View {
        VStack(alignment: .leading) {
            Text("Tile \(i + 1)").font(.headline).foregroundStyle(pinned ? Color.accentColor : .primary)
            Text(pinned ? "pinned" : "hover").font(.caption)
        }
        .padding(10)
    }
}
