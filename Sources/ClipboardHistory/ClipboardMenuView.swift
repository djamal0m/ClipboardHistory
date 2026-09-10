import SwiftUI
import AppKit
import ClipboardHistoryCore

struct ClipboardMenuView: View {
    @ObservedObject var store: ClipboardStore

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard.fill")
                    .foregroundStyle(.tint)
                Text("Clipboard History")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(store.history.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08), in: Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("Search", text: $store.query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                if !store.query.isEmpty {
                    Button {
                        store.query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassEffect(.regular.interactive(), in: Capsule())
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider().opacity(0.25)

            // List
            if store.filteredHistory.isEmpty {
                VStack(spacing: 6) {
                    Spacer()
                    Image(systemName: store.history.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundStyle(.tertiary)
                    Text(store.history.isEmpty ? "No items yet" : "No matches")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.filteredHistory) { item in
                            ClipboardRow(
                                item: item,
                                onSelect: { store.copyToClipboard(item) },
                                onDelete: { store.delete(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }

            Divider().opacity(0.25)

            // Footer
            HStack(spacing: 8) {
                Toggle("Launch at Login", isOn: $store.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: Capsule())
                Spacer()
                Button("Clear") { store.clear() }
                    .buttonStyle(.glass)
                    .controlSize(.regular)
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.glass)
                    .controlSize(.regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 340, height: 460)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
