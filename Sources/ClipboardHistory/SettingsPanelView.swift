import SwiftUI

/// Settings, shown in place of the main list inside the same menu bar
/// popover (toggled by `store.isShowingSettings`) rather than as a
/// separate window. Uses native Form/Section/LabeledContent — the same
/// building blocks System Settings.app itself uses — instead of hand-rolled
/// rows, so this reads as a genuine macOS settings screen.
struct SettingsPanelView: View {
    @ObservedObject var store: ClipboardStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button {
                    store.isShowingSettings = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider().opacity(0.25)

            Form {
                Section("History") {
                    LabeledContent("Max items kept") {
                        HStack(spacing: 6) {
                            Text(store.maxItems, format: .number)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            MiniStepper(value: $store.maxItems, range: ClipboardStore.maxItemsRange, step: 10)
                        }
                    }
                    .help("Older entries are dropped once this many are stored. Range: \(ClipboardStore.maxItemsRange.lowerBound)–\(ClipboardStore.maxItemsRange.upperBound).")

                    LabeledContent {
                        HStack(spacing: 6) {
                            Text(store.maxItemLength, format: .number)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            MiniStepper(value: $store.maxItemLength, range: ClipboardStore.maxItemLengthRange, step: 5_000)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Max copied length")
                            Button {
                                // No-op: this button exists to host the tooltip below.
                            } label: {
                                Image(systemName: "info.circle")
                            }
                            .buttonStyle(.plain)
                            .help("Maximum length of a single copied item, in characters. Longer copies are skipped and won't be saved. Range: \(ClipboardStore.maxItemLengthRange.lowerBound)–\(ClipboardStore.maxItemLengthRange.upperBound) characters.")
                        }
                    }
                }

                Section("Startup") {
                    Toggle("Launch at Login", isOn: $store.launchAtLogin)
                        .help("Starts Clipboard History automatically when you log in, via macOS Login Items.")
                }

                Section("Appearance") {
                    // A hand-rolled segmented control instead of
                    // Picker(.segmented): AppKit's segmented control keeps
                    // its intrinsic (content-fitting) size even inside a
                    // `.frame(maxWidth: .infinity)` — only its background
                    // track stretches, leaving the actual buttons
                    // left-aligned with empty space to their right. Equal
                    // `.frame(maxWidth: .infinity)` buttons fill the row.
                    HStack(spacing: 2) {
                        ForEach(AppAppearance.allCases) { mode in
                            let isSelected = store.appearance == mode
                            Button {
                                store.appearance = mode
                            } label: {
                                Text(mode.label)
                                    .font(.system(size: 11))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(isSelected ? Color.accentColor : Color.clear)
                            )
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                        }
                    }
                    .padding(2)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                    )
                    .frame(maxWidth: .infinity)
                    .help("System follows your Mac's Light/Dark setting automatically. Light or Dark pins this app regardless of the system setting.")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
    }
}

/// A native `Stepper` always renders its arrow glyphs in the system's
/// fixed control color — `.tint(_:)` changes the accent but not the arrows
/// themselves. This hand-rolled equivalent (a touch smaller than the
/// native control) draws its own chevrons so they can be colored.
private struct MiniStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        VStack(spacing: 1) {
            Button {
                value = min(value + step, range.upperBound)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 7, weight: .bold))
                    .frame(width: 14, height: 8)
            }
            .disabled(value >= range.upperBound)

            Button {
                value = max(value - step, range.lowerBound)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .frame(width: 14, height: 8)
            }
            .disabled(value <= range.lowerBound)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.primary.opacity(0.1))
        )
    }
}
