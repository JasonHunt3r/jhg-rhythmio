import AppKit
import RhythmIOCore

/// Copy on Library tiles (`spec/conventions.md` §3 and §5; B-19, B-20):
/// the library's own files, as file URLs, so Finder pastes copies and Mail
/// attaches them.
@MainActor
enum TileClipboard {
    static func copy(_ ids: [Int64], model: AppModel) {
        let urls = ids.compactMap { model.itemsByID[$0] }.compactMap { model.url(for: $0) }
        guard !urls.isEmpty else { return NSSound.beep() }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects(urls as [NSURL])
    }
}
