import AppKit

/// A plain, opaque panel shown beside the app's window with the full text
/// of a row that's truncated in the list. Deliberately a native NSPanel
/// rather than a SwiftUI overlay: SwiftUI's `.glassEffect()` on this OS
/// build composites outside normal view z-ordering, which made an
/// in-window floating preview unreliable. A separate window sidesteps that
/// entirely.
///
/// Styled to match the main popover (`ClipboardMenuView`): same corner
/// radius (26pt) and a subtle edge stroke standing in for the Liquid Glass
/// border. Colors are resolved from the host window's *current* appearance
/// each time the panel is shown (rather than fixed literals), so it tracks
/// the app's Light/Dark/System setting instead of always looking dark.
@MainActor
final class TextPreviewPanel {
    static let shared = TextPreviewPanel()

    private static let cornerRadius: CGFloat = 26

    private let panel: NSPanel
    private let textField: NSTextField
    private let content: NSView

    private init() {
        textField = NSTextField(wrappingLabelWithString: "")
        textField.font = .systemFont(ofSize: 12.5)
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

        content = NSView()
        content.wantsLayer = true
        content.layer?.cornerRadius = Self.cornerRadius
        content.layer?.borderWidth = 1
        content.addSubview(textField)
        panel.contentView = content
    }

    func show(text: String) {
        guard let hostWindow = NSApp.keyWindow else { return }

        // Match the host window's actual current appearance (it may be
        // pinned to Light/Dark or following System) so dynamic system
        // colors below resolve to the same values the popover itself uses.
        let appearance = hostWindow.effectiveAppearance
        panel.appearance = appearance
        appearance.performAsCurrentDrawingAppearance {
            content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            content.layer?.borderColor = NSColor.separatorColor.cgColor
            textField.textColor = .labelColor
        }

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
