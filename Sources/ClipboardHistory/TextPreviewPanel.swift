import AppKit

/// A plain, opaque panel shown beside the app's window with the full text
/// of a row that's truncated in the list. Deliberately a native NSPanel
/// rather than a SwiftUI overlay: SwiftUI's `.glassEffect()` on this OS
/// build composites outside normal view z-ordering, which made an
/// in-window floating preview unreliable. A separate window sidesteps that
/// entirely.
///
/// Styled to match the main popover (`ClipboardMenuView`): same corner
/// radius (26pt) and a subtle light edge stroke standing in for the
/// Liquid Glass border, since this window stays a plain opaque panel
/// rather than using `.glassEffect()` itself.
@MainActor
final class TextPreviewPanel {
    static let shared = TextPreviewPanel()

    private static let cornerRadius: CGFloat = 26
    private static let backgroundColor = NSColor(white: 0.11, alpha: 1)
    private static let borderColor = NSColor.white.withAlphaComponent(0.18)

    private let panel: NSPanel
    private let textField: NSTextField

    private init() {
        textField = NSTextField(wrappingLabelWithString: "")
        textField.font = .systemFont(ofSize: 12.5)
        textField.textColor = .white
        textField.backgroundColor = .clear
        textField.isBezeled = false
        textField.isEditable = false
        textField.isSelectable = false

        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.hidesOnDeactivate = false

        let content = NSView()
        content.wantsLayer = true
        content.layer?.backgroundColor = Self.backgroundColor.cgColor
        content.layer?.cornerRadius = Self.cornerRadius
        content.layer?.borderWidth = 1
        content.layer?.borderColor = Self.borderColor.cgColor
        content.addSubview(textField)
        panel.contentView = content
    }

    func show(text: String) {
        guard let hostWindow = NSApp.keyWindow else { return }

        let maxWidth: CGFloat = 260
        let padding: CGFloat = 12
        textField.stringValue = text
        textField.preferredMaxLayoutWidth = maxWidth
        let fitting = textField.sizeThatFits(NSSize(width: maxWidth, height: .greatestFiniteMagnitude))
        textField.frame = NSRect(x: padding, y: padding, width: maxWidth, height: fitting.height)

        let panelSize = NSSize(width: maxWidth + padding * 2, height: fitting.height + padding * 2)
        let hostFrame = hostWindow.frame
        let origin = NSPoint(x: hostFrame.minX - panelSize.width - 8, y: hostFrame.maxY - panelSize.height)

        panel.setFrame(NSRect(origin: origin, size: panelSize), display: false)
        panel.orderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }
}
