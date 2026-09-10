import Foundation

/// Pure history bookkeeping: dedupe, cap, delete, clear, search.
/// Deliberately has no dependency on NSPasteboard/AppKit so it can be
/// unit tested without touching the real system clipboard.
public struct ClipboardHistoryManager {
    public private(set) var items: [ClipboardItem]
    public var maxItems: Int
    public var maxItemLength: Int

    public init(items: [ClipboardItem] = [], maxItems: Int = 50, maxItemLength: Int = 200_000) {
        self.items = items
        self.maxItems = maxItems
        self.maxItemLength = maxItemLength
    }

    /// Adds `text` as a new entry unless it's blank, a repeat of the most
    /// recent entry, or larger than `maxItemLength` (guards against a huge
    /// paste — e.g. an entire log file — bloating the persisted history and
    /// re-encoding it to JSON on every clipboard change). Returns whether an
    /// item was actually added.
    @discardableResult
    public mutating func add(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard text.count <= maxItemLength else { return false }
        guard items.first?.text != text else { return false }

        items.insert(ClipboardItem(text: text), at: 0)
        if items.count > maxItems {
            items.removeLast()
        }
        return true
    }

    public mutating func delete(id: UUID) {
        items.removeAll { $0.id == id }
    }

    public mutating func clear() {
        items.removeAll()
    }

    public func filtered(query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.text.localizedCaseInsensitiveContains(query) }
    }
}
