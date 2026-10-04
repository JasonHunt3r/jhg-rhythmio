import SwiftUI
import RhythmIOCore

/// The fade length Fade ▸ gives an end it turns on (Settings ▸ Timeline ▸
/// Fades; Jason, 2026-10-03: user-defined, 0.5 s for images and 1 s for
/// audio to start).
enum FadeDefaults {
    static let imagesKey = "fadeLengthImages"
    static let audioKey = "fadeLengthAudio"
    static let imagesStart = 0.5
    static let audioStart = 1.0

    static var images: Double { length(imagesKey, imagesStart) }
    static var audio: Double { length(audioKey, audioStart) }

    private static func length(_ key: String, _ start: Double) -> Double {
        let v = UserDefaults.standard.double(forKey: key)
        return v > 0 ? v : start
    }
}

/// Fade ▸ In, Out, Both, None, the current one ticked (`spec/conventions.md`
/// §3, a lane image and an audio clip).
struct FadeMenu: View {
    let fadeIn: Double
    let fadeOut: Double
    let set: (FadeEnds) -> Void

    var body: some View {
        let now = FadeEnds.of(fadeIn: fadeIn, fadeOut: fadeOut)
        Menu("Fade") {
            ForEach(FadeEnds.allCases, id: \.self) { ends in
                Toggle(ends.title, isOn: Binding(get: { now == ends }, set: { _ in set(ends) }))
            }
        }
    }
}
