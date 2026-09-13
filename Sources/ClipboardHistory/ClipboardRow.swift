import SwiftUI
import ClipboardHistoryCore

// Avoids @State, which needs the SwiftUI macro plugin bundled only with full
// Xcode — this machine builds with the Command Line Tools toolchain.
final class HoverBox: ObservableObject {
    @Published var isHovering = false
}

struct ClipboardRow: View {
    let item: ClipboardItem
    var onSelect: () -> Void
    var onDelete: () -> Void
    @StateObject private var hover = HoverBox()

    var body: some View {
        HStack(spacing: 8) {
            Text(item.preview)
                .font(.system(size: 12.5))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 8)
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(hover.isHovering ? 1 : 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .glassEffect(
            hover.isHovering ? .regular.tint(.primary.opacity(0.16)).interactive() : .regular.interactive(),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hover.isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hover.isHovering)
        .help(item.hoverInfo())
    }
}
