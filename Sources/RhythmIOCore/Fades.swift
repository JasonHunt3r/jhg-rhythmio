import Foundation

/// Fade ▸ on a lane image or an audio clip (`spec/conventions.md` §3,
/// settled 2026-09-24): which ends fade. Turning an end on gives it the
/// fade length from Settings (Jason, 2026-10-03: 0.5 s for images, 1 s for
/// audio by default); an end already fading keeps its own length.
public enum FadeEnds: String, CaseIterable, Sendable {
    case fadeIn, fadeOut, both, none

    public var title: String {
        switch self {
        case .fadeIn: "In"
        case .fadeOut: "Out"
        case .both: "Both"
        case .none: "None"
        }
    }

    /// Which ends a clip fades now.
    public static func of(fadeIn: Double, fadeOut: Double) -> FadeEnds {
        switch (fadeIn > 0, fadeOut > 0) {
        case (true, true): .both
        case (true, false): .fadeIn
        case (false, true): .fadeOut
        case (false, false): .none
        }
    }

    /// The clip's fades after choosing this. Never longer than the clip,
    /// and the two together never more than all of it.
    public func apply(fadeIn: Double, fadeOut: Double, length: Double, clipLength: Double) -> (fadeIn: Double, fadeOut: Double) {
        let wantsIn = self == .fadeIn || self == .both
        let wantsOut = self == .fadeOut || self == .both
        var i = wantsIn ? (fadeIn > 0 ? fadeIn : length) : 0
        var o = wantsOut ? (fadeOut > 0 ? fadeOut : length) : 0
        let room = max(clipLength, 0)
        if i + o > room {
            // Shared out in proportion, so neither swallows the other.
            let scale = room / (i + o)
            i *= scale
            o *= scale
        }
        return (i, o)
    }
}

extension OverlayPlacement {
    /// Duplicate on a lane image (Jason, 2026-10-03): a copy right after it,
    /// or in the first free space after that with room for `shortest`
    /// seconds, as long as the original or cut short by the next image.
    /// Nil if there's no room anywhere after it.
    public static func duplicate(_ clip: OverlayClip, in clips: [OverlayClip], duration: Double,
                                 shortest: Double = 0.2) -> OverlayClip? {
        var t = clip.start + clip.length
        let later = clips.filter { $0.start + $0.length > t }.sorted { $0.start < $1.start }
        for next in later + [nil] {
            if let next, next.start <= t {
                t = max(t, next.start + next.length)   // occupied: step past it
                continue
            }
            let room = min(next?.start ?? duration, duration) - t
            if room >= shortest {
                var copy = clip
                copy.id = UUID()
                copy.start = t
                copy.length = min(clip.length, room)
                return copy
            }
            guard let next else { break }
            t = next.start + next.length
        }
        return nil
    }
}
