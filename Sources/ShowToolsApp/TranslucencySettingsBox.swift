import SwiftUI

/// The secondary window opened from the Windows tab's "Adjust
/// Transparency…" button (`spec/windows.md`, item 34) — the same
/// `SettingsBox` case built for Drawer Sensitivity's "Set Up Triggers…".
/// Jason, 2026-09-27: three numbered Opacity Channels, each independently
/// tuned per Light/Dark ("a switch inside the secondary window..."), with
/// which region of the app uses which channel itself a setting ("Main
/// window is class 1... panes... could be assigned class 2 or 3" — not a
/// fixed one-region-per-class taxonomy).
struct TranslucencySettingsBox: View {
    @ObservedObject private var settings = TranslucencySettings.shared
    @State private var editing: ColorScheme = .dark
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Editing", selection: $editing) {
                Text("Dark Mode").tag(ColorScheme.dark)
                Text("Light Mode").tag(ColorScheme.light)
            }
            .pickerStyle(.segmented)
            Text("Dark and Light keep their own values — switch here to tune one without changing your system appearance.")
                .font(.callout)
                .foregroundStyle(.secondary)

            ForEach(OpacityChannel.allCases) { channel in
                channelSection(channel)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Which regions use which channel").font(.headline)
                ForEach(TranslucentRegion.allCases) { region in
                    Picker(region.label, selection: Binding(
                        get: { settings.channel(for: region) },
                        set: { settings.setChannel($0, for: region) })) {
                        ForEach(OpacityChannel.allCases) { channel in
                            Text(channel.label).tag(channel)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Done", action: dismiss)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
    }

    @ViewBuilder
    private func channelSection(_ channel: OpacityChannel) -> some View {
        let values = Binding<ChannelValues>(
            get: { settings.values(for: channel, appearance: editing) },
            set: { settings.setValues($0, channel: channel, appearance: editing) })

        VStack(alignment: .leading, spacing: 8) {
            Text(channel.label).font(.headline)

            CommitSlider(title: "Opacity", value: values.wrappedValue.opacity, range: 0...1,
                         display: 100, unit: "%") { v in
                var n = values.wrappedValue; n.opacity = v; values.wrappedValue = n
            }

            Toggle("Use the system's own blur (safe)", isOn: Binding(
                get: { values.wrappedValue.blurMode == .system },
                set: { on in var n = values.wrappedValue; n.blurMode = on ? .system : .custom; values.wrappedValue = n }))

            if values.wrappedValue.blurMode == .custom {
                CommitSlider(title: "Blur", value: values.wrappedValue.blurRadius, range: 0...60, unit: "pt") { v in
                    var n = values.wrappedValue; n.blurRadius = v; values.wrappedValue = n
                }
                Text("Experimental: reaches into a private, undocumented layer property. If a macOS update makes it stop doing anything, turn the switch back on.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ColorPicker("Tint", selection: Binding(
                    get: { values.wrappedValue.tintColor },
                    set: { var n = values.wrappedValue; n.tintColor = $0; values.wrappedValue = n }))
                CommitSlider(title: "Amount", value: values.wrappedValue.tintAmount, range: 0...1,
                             display: 100, unit: "%") { v in
                    var n = values.wrappedValue; n.tintAmount = v; values.wrappedValue = n
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
    }
}
